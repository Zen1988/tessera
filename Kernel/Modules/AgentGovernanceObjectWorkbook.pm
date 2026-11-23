# --
# TESSERA preview-first GovernanceObject XLSX import/export.
# --
package Kernel::Modules::AgentGovernanceObjectWorkbook;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use Digest::SHA qw(sha256_hex);
use Encode qw(encode);
use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our $ObjectManagerDisabled = 1;

sub new { my ( $Type, %Param ) = @_; return bless {%Param}, $Type; }

sub Run {
    my ( $Self, %Param ) = @_;
    my $Request = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $Layout  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $JSON    = $Kernel::OM->Get('Kernel::System::JSON');
    my $Subaction = $Self->{Subaction} || '';
    my $Payload = $Request->GetParam( Param => 'WorkbookPayload' ) || '';
    my $ClassID = $Request->GetParam( Param => 'ClassID' ) || '';
    my ( $Preview, $Message, $MessageClass, $Token );

    if ( $Subaction eq 'Model' ) {
        return $Layout->Attachment(
            ContentType => 'application/json; charset=' . $Layout->{Charset},
            Content     => $Layout->JSONEncode( Data => $Self->_ExportModel( ClassID => $ClassID ) ),
            Type => 'inline', NoCache => 1,
        );
    }
    if ( $Subaction eq 'Download' ) {
        my $Model = $Self->_ExportModel( ClassID => $ClassID );
        return $Layout->ErrorScreen( Message => Translatable('Select a valid GovernanceObject class first.') ) if !keys %{$Model};
        my $ClassName = $Self->_Classes->{$ClassID};
        my $Excel = $Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->Build(
            Model => $Model, Empty => ( $Request->GetParam( Param => 'Empty' ) || 0 ), JSON => $JSON,
        );
        $ClassName =~ s{[^A-Za-z0-9_-]+}{-}g;
        my $Suffix = ( $Request->GetParam( Param => 'Empty' ) || 0 ) ? '-Template.xlsx' : '-Export.xlsx';
        return $Layout->Attachment( Filename => 'TESSERA-GovernanceObject-' . $ClassName . $Suffix,
            ContentType => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', Content => $Excel );
    }

    if ( $Subaction eq 'Preview' ) {
        my $Rows = eval { $JSON->Decode( Data => $Payload ) };
        if ( ref $Rows ne 'ARRAY' ) { $Message = Translatable('The workbook payload is invalid.'); $MessageClass = 'Error'; }
        else {
            $Rows = $Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->ImportRowsNormalize( Rows => $Rows );
            $Preview = $Self->_Preview( Rows => $Rows );
            $Token = sha256_hex( encode( 'UTF-8', $Payload ) );
            $Message = Translatable('Preview complete. New rows default to create; number or unique name matches default to update. Review ambiguous rows, then commit.');
            $MessageClass = 'Notice';
        }
    }
    elsif ( $Subaction eq 'Commit' ) {
        my $Rows = eval { $JSON->Decode( Data => $Payload ) };
        my $Decisions = eval { $JSON->Decode( Data => ( $Request->GetParam( Param => 'Decisions' ) || '' ) ) };
        my $TokenParam = $Request->GetParam( Param => 'PreviewToken' ) || '';
        if ( ref $Rows ne 'ARRAY' || ref $Decisions ne 'ARRAY' || sha256_hex( encode( 'UTF-8', $Payload ) ) ne $TokenParam ) {
            $Message = Translatable('Commit rejected: preview token or workbook payload is invalid.'); $MessageClass = 'Error';
        }
        else {
            $Rows = $Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->ImportRowsNormalize( Rows => $Rows );
            my ( $Created, $Updated, $Skipped, @Errors ) = ( 0, 0, 0 );
            my $Check = $Self->_Preview( Rows => $Rows );
            ROW: for my $Index ( 0 .. $#{$Rows} ) {
                my $Row = $Rows->[$Index];
                my $Operation = $Decisions->[$Index] // '';
                if ( $Operation eq 'SKIP' ) { $Skipped++; next ROW; }
                my $Clears = @{ $Check->[$Index]->{ClearFields} || [] } ? 1 : 0;
                if ( $Operation =~ m{\AUPDATE_CLEAR:(.+)\z} ) {
                    if ( !$Clears ) { push @Errors, 'Row ' . ( $Index + 1 ) . ': destructive confirmation is not applicable.'; next ROW; }
                    $Row->{Number} = $1;
                }
                elsif ( $Operation =~ m{\AUPDATE:(.+)\z} ) {
                    if ($Clears) { push @Errors, 'Row ' . ( $Index + 1 ) . ': explicit destructive confirmation is required.'; next ROW; }
                    $Row->{Number} = $1;
                }
                elsif ( $Operation eq 'CREATE' ) {
                    delete $Row->{Number};
                    $Row->{Name} = $Self->_UniqueCreateName(
                        Class => $Row->{Class},
                        Name  => $Row->{Name},
                    );
                }
                else { push @Errors, 'Row ' . ( $Index + 1 ) . ': explicit CREATE, UPDATE, UPDATE_CLEAR, or SKIP is required.'; next ROW; }
                my %Fields = map { $_ => $Row->{$_} }
                    grep { $_ !~ m{\A(?:Class|Number|Name|Version|ZTSMStatus|Description)\z} } keys %{$Row};
                my $Result = eval { $Kernel::OM->Get('Kernel::System::GovernanceObject::Document')->Import(
                    Data => { object_type => 'GovernanceObject', class => $Row->{Class}, number => $Row->{Number},
                        name => $Row->{Name}, version => $Row->{Version} || '1', ztsm_status => $Row->{ZTSMStatus},
                        description => $Row->{Description} // '', fields => \%Fields },
                    UserID => $Self->{UserID}, Source => 'Excel Import',
                ) };
                my $Failure = $@ || '';
                $Failure =~ s{\s+}{ }g;
                if ( IsHashRefWithData($Result) && $Result->{Success} ) { $Operation eq 'CREATE' ? $Created++ : $Updated++; }
                else { push @Errors, 'Row ' . ( $Index + 1 ) . ': ' . ( IsHashRefWithData($Result) ? ( $Result->{Message} // 'import failed' ) : ( $Failure || 'import failed' ) ); }
            }
            $Message = "Created $Created, updated $Updated, skipped $Skipped.";
            $Message .= ' Errors: ' . join( ' ', @Errors ) if @Errors;
            $MessageClass = @Errors ? 'Error' : 'Success';
        }
    }

    my $Classes = $Self->_Classes;
    $ClassID = '' if $ClassID && !$Classes->{$ClassID};
    $Layout->AddJSData( Key => 'ZTSMObjectWorkbookModel', Value => $Self->_ExportModel( ClassID => $ClassID ) );
    $Layout->AddJSData( Key => 'ZTSMObjectWorkbookPreview', Value => $Preview || [] );
    $Layout->AddJSData( Key => 'ZTSMObjectWorkbookAction', Value => 'AgentGovernanceObjectWorkbook' );
    $Layout->AddJSData( Key => 'ZTSMObjectWorkbookLabel', Value => 'GovernanceObject' );
    return join '', $Layout->Header( Type => 'Small', Title => Translatable('GovernanceObject Excel Import/Export') ),
        $Layout->Output( TemplateFile => 'AgentGovernanceObjectWorkbook', Data => {
            %Param, Message => $Message // '', MessageClass => $MessageClass // '', WorkbookPayload => $Payload,
            PreviewToken => $Token // '', ClassID => $ClassID,
            ClassSelection => $Layout->BuildSelection( Data => $Classes, Name => 'ClassID', ID => 'ZTSMWorkbookClassID',
                SelectedID => $ClassID, PossibleNone => 1, Sort => 'AlphanumericValue', Class => 'Modernize' ),
        } ), $Layout->Footer( Type => 'Small' );
}

sub _Classes {
    return $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList( Class => 'ZTSM::GovernanceObject::Class' ) || {};
}

sub _ExportModel {
    my ( $Self, %Param ) = @_;
    return {} if !$Param{ClassID} || !$Self->_Classes->{ $Param{ClassID} };
    my $Object = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $Document = $Kernel::OM->Get('Kernel::System::GovernanceObject::Document');
    my $ClassName = $Self->_Classes->{ $Param{ClassID} };
    my $Definition = $Object->DefinitionGet( ClassID => $Param{ClassID} ) || {};
    my %Fields;
    $Self->_DefinitionFieldNames( Node => $Definition->{DefinitionRef}, Fields => \%Fields );
    my %Metadata = map { $_ => $Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->FieldMetadata( Name => $_ ) } keys %Fields;
    $Metadata{Class} = { Type => 'Fixed', Fixed => 1, Options => [$ClassName] };
    $Metadata{Number} = { Type => 'Fixed', Fixed => 1 };
    $Metadata{Version} = { Type => 'Fixed', Fixed => 1 };
    $Metadata{ZTSMStatus} = { Type => 'GeneralCatalog', Options => $Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->CatalogOptions( Class => 'ZTSM::GovernanceObject::Status' ) };
    my $Sheet = { Headers => [ qw(Class Number Name Version ZTSMStatus Description), sort keys %Fields ], Rows => [], Fields => \%Metadata };
    my @IDs = $Object->GovernanceObjectSearch( Result => 'ARRAY', UserID => $Self->{UserID}, Permission => 'ro', ClassIDs => [ $Param{ClassID} ] );
    for my $ID (@IDs) {
        my $Data = $Document->Export( GovernanceObjectID => $ID, UserID => $Self->{UserID} );
        next if !IsHashRefWithData($Data) || lc( $Data->{class} // '' ) ne lc($ClassName);
        my %Row = ( Class => $Data->{class}, Number => $Data->{number}, Name => $Data->{name}, Version => $Data->{version},
            ZTSMStatus => $Data->{ztsm_status}, Description => $Data->{description} );
        @Row{ keys %{ $Data->{fields} || {} } } = values %{ $Data->{fields} || {} };
        push @{ $Sheet->{Rows} }, \%Row;
    }
    return { $ClassName => $Sheet };
}

sub _DefinitionFieldNames {
    my ( $Self, %Param ) = @_;
    return if !ref $Param{Node};
    if ( ref $Param{Node} eq 'ARRAY' ) { $Self->_DefinitionFieldNames( Node => $_, Fields => $Param{Fields} ) for @{ $Param{Node} }; return; }
    return if ref $Param{Node} ne 'HASH';
    $Param{Fields}->{ $Param{Node}->{DF} } = 1 if $Param{Node}->{DF};
    $Self->_DefinitionFieldNames( Node => $Param{Node}->{$_}, Fields => $Param{Fields} ) for keys %{ $Param{Node} };
}

sub _Preview {
    my ( $Self, %Param ) = @_;
    my $Object = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $Document = $Kernel::OM->Get('Kernel::System::GovernanceObject::Document');
    my @Existing;
    for my $ID ( $Object->GovernanceObjectSearch( Result => 'ARRAY', UserID => $Self->{UserID}, Permission => 'rw' ) ) {
        my $Data = $Document->Export( GovernanceObjectID => $ID, UserID => $Self->{UserID} );
        push @Existing, $Data if IsHashRefWithData($Data);
    }
    my @Preview;
    for my $Row ( @{ $Param{Rows} } ) {
        my $Number = $Row->{Number} // '';
        my ($NumberMatch) = grep { $Number ne '' && ( $_->{number} // '' ) eq $Number } @Existing;
        my @Matches = grep { lc( $_->{class} // '' ) eq lc( $Row->{Class} // '' ) && lc( $_->{name} // '' ) eq lc( $Row->{Name} // '' ) } @Existing;
        my $Candidate = $NumberMatch || ( @Matches == 1 ? $Matches[0] : undef );
        my @Clear = $Candidate ? $Self->_ClearFields( Existing => $Candidate, Incoming => $Row ) : ();
        push @Preview, { Status => $NumberMatch ? 'MATCH_NUMBER' : !$Number && @Matches ? 'REVIEW_SAME_OBJECT' : 'CREATE_CANDIDATE',
            Class => $Row->{Class} // '', Number => $Number, Name => $Row->{Name} // '',
            CandidateNumber => @Matches == 1 ? $Matches[0]->{number} : '', CandidateCount => scalar @Matches, ClearFields => \@Clear };
    }
    return \@Preview;
}

sub _ClearFields {
    my ( $Self, %Param ) = @_;
    my %Existing = ( Name => $Param{Existing}->{name}, Version => $Param{Existing}->{version}, ZTSMStatus => $Param{Existing}->{ztsm_status},
        Description => $Param{Existing}->{description}, %{ $Param{Existing}->{fields} || {} } );
    return grep { !$Self->_IsEmpty( $Existing{$_} ) && $Self->_IsEmpty( $Param{Incoming}->{$_} ) } sort keys %Existing;
}

sub _UniqueCreateName {
    my ( $Self, %Param ) = @_;
    my $Name = $Param{Name} // '';
    return $Name if $Name eq '';

    my $Object   = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $Document = $Kernel::OM->Get('Kernel::System::GovernanceObject::Document');
    my %Used;
    for my $ID ( $Object->GovernanceObjectSearch( Result => 'ARRAY', UserID => $Self->{UserID}, Permission => 'rw' ) ) {
        my $Data = $Document->Export( GovernanceObjectID => $ID, UserID => $Self->{UserID} );
        next if !IsHashRefWithData($Data);
        next if lc( $Data->{class} // '' ) ne lc( $Param{Class} // '' );
        $Used{ lc( $Data->{name} // '' ) } = 1;
    }
    return $Name if !$Used{lc $Name};

    my $Running = 2;
    $Running++ while $Used{ lc( $Name . ' - ' . $Running ) };
    return $Name . ' - ' . $Running;
}

sub _IsEmpty { my ( $Self, $Value ) = @_; return 1 if !defined $Value; return !@{$Value} if ref $Value eq 'ARRAY'; return !keys %{$Value} if ref $Value eq 'HASH'; return $Value eq '' ? 1 : 0; }

1;
