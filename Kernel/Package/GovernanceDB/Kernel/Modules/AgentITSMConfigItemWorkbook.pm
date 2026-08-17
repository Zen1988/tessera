# --
# TESSERA preview-first CMDB XLSX import/export.
# --
package Kernel::Modules::AgentITSMConfigItemWorkbook;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use Digest::SHA qw(sha256_hex);
use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our $ObjectManagerDisabled = 1;

sub new { my ( $Type, %Param ) = @_; return bless {%Param}, $Type; }

sub Run {
    my ( $Self, %Param ) = @_;
    my $Request  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $Layout   = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $JSON     = $Kernel::OM->Get('Kernel::System::JSON');
    my $Document = $Kernel::OM->Get('Kernel::System::ITSMConfigItem::Document');
    my $Subaction = $Self->{Subaction} || '';
    my $Payload = $Request->GetParam( Param => 'WorkbookPayload' ) || '';
    my $ClassID = $Request->GetParam( Param => 'ClassID' ) || '';
    my ( $Preview, $Message, $MessageClass, $Token );

    if ( $Subaction eq 'Model' ) {
        my $Model = $Self->_ExportModel( ClassID => $ClassID );
        return $Layout->Attachment(
            ContentType => 'application/json; charset=' . $Layout->{Charset},
            Content     => $Layout->JSONEncode( Data => $Model ),
            Type        => 'inline',
            NoCache     => 1,
        );
    }
    if ( $Subaction eq 'Download' ) {
        my $Model = $Self->_ExportModel( ClassID => $ClassID );
        return $Layout->ErrorScreen( Message => Translatable('Select a valid ConfigItem class first.') ) if !keys %{$Model};
        my $ClassName = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList( Class => 'ITSM::ConfigItem::Class' )->{$ClassID};
        my $Excel = $Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->Build(
            Model => $Model, Empty => ( $Request->GetParam( Param => 'Empty' ) || 0 ), JSON => $JSON,
        );
        $ClassName =~ s{[^A-Za-z0-9_-]+}{-}g;
        my $Suffix = ( $Request->GetParam( Param => 'Empty' ) || 0 ) ? '-Template.xlsx' : '-Export.xlsx';
        return $Layout->Attachment( Filename => 'TESSERA-' . $ClassName . $Suffix,
            ContentType => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', Content => $Excel );
    }

    if ( $Subaction eq 'Preview' ) {
        my $Rows = eval { $JSON->Decode( Data => $Payload ) };
        if ( ref $Rows ne 'ARRAY' ) {
            $Message = Translatable('The workbook payload is invalid.');
            $MessageClass = 'Error';
        }
        else {
            $Preview = $Self->_Preview( Rows => $Rows );
            $Token = sha256_hex($Payload);
            $Message = Translatable('Preview complete. Select an explicit operation for every row, then commit.');
            $MessageClass = 'Notice';
        }
    }
    elsif ( $Subaction eq 'Commit' ) {
        my $TokenParam = $Request->GetParam( Param => 'PreviewToken' ) || '';
        my $DecisionsText = $Request->GetParam( Param => 'Decisions' ) || '';
        my $Rows = eval { $JSON->Decode( Data => $Payload ) };
        my $Decisions = eval { $JSON->Decode( Data => $DecisionsText ) };
        if ( ref $Rows ne 'ARRAY' || ref $Decisions ne 'ARRAY' || sha256_hex($Payload) ne $TokenParam ) {
            $Message = Translatable('Commit rejected: preview token or workbook payload is invalid.');
            $MessageClass = 'Error';
        }
        else {
            my ( $Created, $Updated, $Skipped, @Errors ) = ( 0, 0, 0 );
            my $CommitPreview = $Self->_Preview( Rows => $Rows );
            ROW:
            for my $Index ( 0 .. $#{$Rows} ) {
                my $Row = $Rows->[$Index];
                my $Operation = $Decisions->[$Index] // '';
                if ( $Operation eq 'SKIP' ) { $Skipped++; next ROW; }
                my $ClearsExisting = @{ $CommitPreview->[$Index]->{ClearFields} || [] } ? 1 : 0;
                if ( $Operation =~ m{\AUPDATE_CLEAR:(.+)\z} ) {
                    if ( !$ClearsExisting ) {
                        push @Errors, 'Row ' . ( $Index + 1 ) . ': destructive update confirmation was not applicable.';
                        next ROW;
                    }
                    $Row->{Number} = $1;
                }
                elsif ( $Operation =~ m{\AUPDATE:(.+)\z} ) {
                    if ($ClearsExisting) {
                        push @Errors, 'Row ' . ( $Index + 1 ) . ': existing values would be cleared; explicit destructive confirmation is required.';
                        next ROW;
                    }
                    $Row->{Number} = $1;
                }
                elsif ( $Operation eq 'CREATE' ) { delete $Row->{Number}; }
                else { push @Errors, 'Row ' . ( $Index + 1 ) . ': explicit CREATE, UPDATE, UPDATE_CLEAR, or SKIP is required.'; next ROW; }

                my %Fields = map { $_ => $Row->{$_} }
                    grep { $_ !~ m{\A(?:Class|Number|Name|Version|DeploymentState|IncidentState|Description)\z} } keys %{$Row};
                my $Result = $Document->Import(
                    Data => {
                        object_type      => 'ITSMConfigItem',
                        class            => $Row->{Class},
                        number           => $Row->{Number},
                        name             => $Row->{Name},
                        version          => $Row->{Version} || '1',
                        deployment_state => $Row->{DeploymentState},
                        incident_state   => $Row->{IncidentState},
                        description      => $Row->{Description} // '',
                        fields           => \%Fields,
                    },
                    UserID => $Self->{UserID},
                    Source => 'Excel Import',
                );
                if ( IsHashRefWithData($Result) && $Result->{Success} ) {
                    $Operation eq 'CREATE' ? $Created++ : $Updated++;
                }
                else {
                    push @Errors, 'Row ' . ( $Index + 1 ) . ': '
                        . ( IsHashRefWithData($Result) ? ( $Result->{Message} // 'import failed' ) : 'import failed' );
                }
            }
            $Message = "Created $Created, updated $Updated, skipped $Skipped.";
            $Message .= ' Errors: ' . join( ' ', @Errors ) if @Errors;
            $MessageClass = @Errors ? 'Error' : 'Success';
        }
    }

    my $Classes = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    ) || {};
    $ClassID = '' if $ClassID && !$Classes->{$ClassID};
    $Layout->AddJSData( Key => 'ZTSMConfigItemWorkbookModel', Value => $Self->_ExportModel( ClassID => $ClassID ) );
    $Layout->AddJSData( Key => 'ZTSMConfigItemWorkbookPreview', Value => $Preview || [] );

    return join '',
        $Layout->Header( Type => 'Small', Title => Translatable('CMDB Excel Import/Export') ),
        $Layout->Output(
            TemplateFile => 'AgentITSMConfigItemWorkbook',
            Data => {
                %Param,
                Message        => $Message // '',
                MessageClass   => $MessageClass // '',
                WorkbookPayload => $Payload,
                PreviewToken   => $Token // '',
                ClassID        => $ClassID,
                ClassSelection => $Layout->BuildSelection(
                    Data         => $Classes,
                    Name         => 'ClassID',
                    ID           => 'ZTSMWorkbookClassID',
                    SelectedID   => $ClassID,
                    PossibleNone => 1,
                    Sort         => 'AlphanumericValue',
                    Class        => 'Modernize',
                ),
            },
        ),
        $Layout->Footer( Type => 'Small' );
}

sub _ExportModel {
    my ( $Self, %Param ) = @_;
    return {} if !$Param{ClassID};
    my $CIObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $Document = $Kernel::OM->Get('Kernel::System::ITSMConfigItem::Document');
    my $Classes = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    ) || {};
    return {} if !$Classes->{ $Param{ClassID} };
    my %Sheets;
    for my $ClassID ( keys %{$Classes} ) {
        next if $Param{ClassID} && $ClassID ne $Param{ClassID};
        my $Definition = $CIObject->DefinitionGet( ClassID => $ClassID ) || {};
        my %EffectiveFields;
        $Self->_DefinitionFieldNames( Node => $Definition->{DefinitionRef}, Fields => \%EffectiveFields );
        my %Metadata = map { $_ => $Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->FieldMetadata( Name => $_ ) } keys %EffectiveFields;
        $Metadata{Class} = { Type => 'Fixed', Fixed => 1, Options => [ $Classes->{$ClassID} ] };
        $Metadata{Number} = { Type => 'Fixed', Fixed => 1 };
        $Metadata{Version} = { Type => 'Fixed', Fixed => 1 };
        $Metadata{DeploymentState} = { Type => 'GeneralCatalog', Options => $Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->CatalogOptions( Class => 'ITSM::ConfigItem::DeploymentState' ) };
        $Metadata{IncidentState} = { Type => 'GeneralCatalog', Options => $Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->CatalogOptions( Class => 'ITSM::ConfigItem::IncidentState' ) };
        $Sheets{ $Classes->{$ClassID} } = {
            Headers => [
                qw(Class Number Name Version DeploymentState IncidentState Description),
                sort keys %EffectiveFields,
            ],
            Rows => [],
            Fields => \%Metadata,
        };
    }
    my @IDs = $CIObject->ConfigItemSearch( Result => 'ARRAY', UserID => $Self->{UserID}, Permission => 'ro' );
    for my $ID (@IDs) {
        my $Data = $Document->Export( ConfigItemID => $ID, UserID => $Self->{UserID} );
        next if !IsHashRefWithData($Data);
        next if $Param{ClassID} && lc( $Data->{class} // '' ) ne lc( $Classes->{ $Param{ClassID} } // '' );
        my %Row = (
            Class           => $Data->{class}, Number => $Data->{number}, Name => $Data->{name},
            Version         => $Data->{version}, DeploymentState => $Data->{deployment_state},
            IncidentState   => $Data->{incident_state}, Description => $Data->{description},
        );
        @Row{ keys %{ $Data->{fields} || {} } } = values %{ $Data->{fields} || {} };
        $Sheets{ $Data->{class} } ||= { Headers => [ sort keys %Row ], Rows => [] };
        push @{ $Sheets{ $Data->{class} }->{Rows} }, \%Row;
    }
    return \%Sheets;
}

# DefinitionGet() expands referenced role definitions into DefinitionRef. Walk
# the effective class-page structure so template columns match the actual form.
sub _DefinitionFieldNames {
    my ( $Self, %Param ) = @_;
    my $Node = $Param{Node};
    return if !ref $Node;
    if ( ref $Node eq 'ARRAY' ) {
        $Self->_DefinitionFieldNames( Node => $_, Fields => $Param{Fields} ) for @{$Node};
        return;
    }
    return if ref $Node ne 'HASH';
    $Param{Fields}->{ $Node->{DF} } = 1 if $Node->{DF};
    $Self->_DefinitionFieldNames( Node => $Node->{$_}, Fields => $Param{Fields} ) for keys %{$Node};
    return;
}

sub _Preview {
    my ( $Self, %Param ) = @_;
    my $CIObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $Document = $Kernel::OM->Get('Kernel::System::ITSMConfigItem::Document');
    my $Classes = $Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    ) || {};
    my %ClassIDByName = map { lc( $Classes->{$_} // '' ) => $_ } keys %{$Classes};
    my %IdentityFieldsByClass;
    my @IDs = $CIObject->ConfigItemSearch( Result => 'ARRAY', UserID => $Self->{UserID}, Permission => 'rw' );
    my @Existing;
    for my $ID (@IDs) {
        my $Data = $Document->Export( ConfigItemID => $ID, UserID => $Self->{UserID} );
        push @Existing, $Data if IsHashRefWithData($Data);
    }
    my @Preview;
    for my $Row ( @{ $Param{Rows} } ) {
        my $Number = $Row->{Number} // '';
        my ($NumberMatch) = grep { $Number ne '' && ( $_->{number} // '' ) eq $Number } @Existing;
        my $ClassKey = lc( $Row->{Class} // '' );
        if ( !exists $IdentityFieldsByClass{$ClassKey} ) {
            my %DefinedFields;
            my $ClassID = $ClassIDByName{$ClassKey};
            if ($ClassID) {
                my $Definition = $CIObject->DefinitionGet( ClassID => $ClassID ) || {};
                $Self->_DefinitionFieldNames( Node => $Definition->{DefinitionRef}, Fields => \%DefinedFields );
            }
            $IdentityFieldsByClass{$ClassKey} = [
                grep { $DefinedFields{$_} }
                    qw(ZTAM-Application ZTAM-Environment ZTAM-Location)
            ];
        }
        my $IdentityFields = $IdentityFieldsByClass{$ClassKey};
        my @AvailableIdentityFields = grep {
            !$Self->_IsEmpty( $Row->{$_} )
        } @{$IdentityFields};
        my @TupleMatches = grep {
            my $Existing = $_;
            lc( $Existing->{class} // '' ) eq lc( $Row->{Class} // '' )
                && lc( $Existing->{name} // '' ) eq lc( $Row->{Name} // '' )
                && !(
                    !$Self->_IsEmpty( $Existing->{fields}->{'ZTAM-AssetTag'} )
                        && !$Self->_IsEmpty( $Row->{'ZTAM-AssetTag'} )
                        && !$Self->_FieldEqual(
                            $Existing->{fields}->{'ZTAM-AssetTag'},
                            $Row->{'ZTAM-AssetTag'},
                        )
                )
                && !grep {
                    !$Self->_FieldEqual( $Existing->{fields}->{$_}, $Row->{$_} )
                } @AvailableIdentityFields
        } @Existing;
        my $Status = $NumberMatch ? 'MATCH_NUMBER'
            : !$Number && @TupleMatches ? 'REVIEW_SAME_ASSET'
            : 'CREATE_CANDIDATE';
        my $Candidate = $NumberMatch || ( @TupleMatches == 1 ? $TupleMatches[0] : undef );
        my @ClearFields = $Candidate ? $Self->_ClearFields(
            Existing => $Candidate,
            Incoming => $Row,
        ) : ();
        push @Preview, {
            Status          => $Status,
            Class           => $Row->{Class} // '',
            Number          => $Number,
            Name            => $Row->{Name} // '',
            CandidateNumber => @TupleMatches == 1 ? $TupleMatches[0]->{number} : '',
            CandidateCount  => scalar @TupleMatches,
            ClearFields     => \@ClearFields,
        };
    }
    return \@Preview;
}

sub _ClearFields {
    my ( $Self, %Param ) = @_;
    my %Existing = (
        Name            => $Param{Existing}->{name},
        Version         => $Param{Existing}->{version},
        DeploymentState => $Param{Existing}->{deployment_state},
        IncidentState   => $Param{Existing}->{incident_state},
        Description     => $Param{Existing}->{description},
        %{ $Param{Existing}->{fields} || {} },
    );
    my @Clear;
    for my $Field ( sort keys %Existing ) {
        next if $Self->_IsEmpty( $Existing{$Field} );
        next if !$Self->_IsEmpty( $Param{Incoming}->{$Field} );
        push @Clear, $Field;
    }
    return @Clear;
}

sub _IsEmpty {
    my ( $Self, $Value ) = @_;
    return 1 if !defined $Value;
    return !@{$Value} if ref $Value eq 'ARRAY';
    return !keys %{$Value} if ref $Value eq 'HASH';
    return $Value eq '' ? 1 : 0;
}

sub _FieldEqual {
    my ( $Self, $Left, $Right ) = @_;
    my $JSON = $Kernel::OM->Get('Kernel::System::JSON');
    return $JSON->Encode( Data => $Self->_CaseFold($Left), SortKeys => 1 )
        eq $JSON->Encode( Data => $Self->_CaseFold($Right), SortKeys => 1 );
}

sub _CaseFold {
    my ( $Self, $Value ) = @_;
    return [ map { $Self->_CaseFold($_) } @{$Value} ] if ref $Value eq 'ARRAY';
    return { map { lc($_) => $Self->_CaseFold( $Value->{$_} ) } keys %{$Value} } if ref $Value eq 'HASH';
    return defined $Value && !ref $Value ? lc($Value) : $Value;
}

1;
