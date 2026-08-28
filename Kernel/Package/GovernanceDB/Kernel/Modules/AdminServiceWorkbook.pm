# --
# TESSERA preview-first Service XLSX import/export.
# --
package Kernel::Modules::AdminServiceWorkbook;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use Digest::SHA qw(sha256_hex);
use Encode qw(encode);
use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData);

our $ObjectManagerDisabled = 1;

sub new { my ( $Type, %Param ) = @_; return bless {%Param}, $Type; }

sub Run {
    my ( $Self, %Param ) = @_;
    my $Request = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $Layout  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $JSON    = $Kernel::OM->Get('Kernel::System::JSON');
    my $Subaction = $Self->{Subaction} || '';
    my $Payload = $Request->GetParam( Param => 'WorkbookPayload' ) || '';
    my ( $Preview, $Message, $MessageClass, $Token );

    if ( $Subaction eq 'Download' ) {
        my $Excel = $Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->Build(
            Model => $Self->_ExportModel,
            Empty => ( $Request->GetParam( Param => 'Empty' ) || 0 ),
            JSON  => $JSON,
        );
        my $Suffix = ( $Request->GetParam( Param => 'Empty' ) || 0 ) ? 'Template' : 'Export';
        return $Layout->Attachment(
            Filename    => "TESSERA-Services-$Suffix.xlsx",
            ContentType => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            Content     => $Excel,
        );
    }

    if ( $Subaction eq 'Preview' ) {
        my $Rows = eval { $JSON->Decode( Data => $Payload ) };
        if ( ref $Rows ne 'ARRAY' ) {
            $Message = Translatable('The Service workbook payload is invalid.');
            $MessageClass = 'Error';
        }
        else {
            $Rows = $Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->ImportRowsNormalize( Rows => $Rows );
            $Preview = $Self->_Preview( Rows => $Rows );
            $Token = sha256_hex( encode( 'UTF-8', $Payload ) );
            $Message = Translatable('Preview complete. Review every Service operation before commit.');
            $MessageClass = 'Notice';
        }
    }
    elsif ( $Subaction eq 'Commit' ) {
        $Layout->ChallengeTokenCheck();
        my $Rows = eval { $JSON->Decode( Data => $Payload ) };
        my $Decisions = eval { $JSON->Decode( Data => ( $Request->GetParam( Param => 'Decisions' ) || '' ) ) };
        my $TokenParam = $Request->GetParam( Param => 'PreviewToken' ) || '';
        if ( ref $Rows ne 'ARRAY' || ref $Decisions ne 'ARRAY' || sha256_hex( encode( 'UTF-8', $Payload ) ) ne $TokenParam ) {
            $Message = Translatable('Commit rejected: preview token or workbook payload is invalid.');
            $MessageClass = 'Error';
        }
        else {
            $Rows = $Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->ImportRowsNormalize( Rows => $Rows );
            my $Check = $Self->_Preview( Rows => $Rows );
            my ( %Services, $Created, $Updated, $Skipped, @Errors );
            ROW: for my $Index ( 0 .. $#{$Rows} ) {
                my $Decision = $Decisions->[$Index] // '';
                if ( $Decision eq 'SKIP' ) { $Skipped++; next ROW; }
                my $ExpectedName = $Check->[$Index]->{Name} // '';
                if ( $Decision eq 'CREATE' && ( $Check->[$Index]->{CandidateCount} || 0 ) == 0 ) { $Created++; }
                elsif ( $Decision =~ m{\AUPDATE(?:_CLEAR)?:} && ( $Check->[$Index]->{CandidateCount} || 0 ) == 1 ) { $Updated++; }
                else { push @Errors, 'Row ' . ( $Index + 1 ) . ': operation does not match the preview.'; next ROW; }
                my $Service = $Self->_RowToService( Row => $Rows->[$Index] );
                if ( !$ExpectedName || !IsHashRefWithData($Service) ) { push @Errors, 'Row ' . ( $Index + 1 ) . ': Service Name is required.'; next ROW; }
                $Services{$ExpectedName} = $Service;
            }
            if (%Services && !@Errors) {
                my $Success = $Kernel::OM->Get('Kernel::System::Service')->ImportServices(
                    Services => \%Services, OverwriteExistingEntities => 1, UserID => $Self->{UserID},
                );
                push @Errors, 'Service import failed. Check the system log for an unresolved named value.' if !$Success;
            }
            $Message = "Created $Created, updated $Updated, skipped $Skipped.";
            $Message .= ' Errors: ' . join( ' ', @Errors ) if @Errors;
            $MessageClass = @Errors ? 'Error' : 'Success';
        }
    }

    $Layout->AddJSData( Key => 'ZTSMServiceWorkbookPreview', Value => $Preview || [] );
    return join '', $Layout->Header( Title => Translatable('Service Excel Import/Export') ),
        $Layout->NavigationBar(),
        $Layout->Output( TemplateFile => 'AdminServiceWorkbook', Data => {
            %Param, Message => $Message // '', MessageClass => $MessageClass // '',
            WorkbookPayload => $Payload, PreviewToken => $Token // '',
        } ), $Layout->Footer();
}

sub _ExportModel {
    my ($Self) = @_;
    my $ServiceObject = $Kernel::OM->Get('Kernel::System::Service');
    my %Names = $ServiceObject->ServiceList( Valid => 0, UserID => $Self->{UserID} );
    my $Services = $ServiceObject->ExportServices( Services => [ values %Names ], UserID => $Self->{UserID} ) || {};
    my $DynamicFields = $Self->_DynamicFields;
    my @Core = qw(Name Parent Type Criticality Valid DestQueue TicketTypes Comment ShortDescription LongDescription);
    my %Headers = map { $_ => 1 } @Core;
    my @Rows;
    for my $Name ( sort keys %{$Services} ) {
        my $Service = $Services->{$Name};
        next if !IsHashRefWithData($Service);
        my %Row = map { $_ => $Service->{$_} } grep { exists $Service->{$_} } @Core;
        for my $Key ( keys %{$Service} ) {
            next if $Key =~ m{\A(?:Service|DynamicFields|Descriptions|NameShort|State|TicketDestinationQueue|ZService-Field)\z};
            $Headers{$Key} = 1;
            $Row{$Key} = $Service->{$Key};
        }
        for my $FieldName ( keys %{ $Service->{DynamicFields} || {} } ) {
            $Headers{$FieldName} = 1;
            $Row{$FieldName} = $Service->{DynamicFields}->{$FieldName};
        }
        push @Rows, \%Row;
    }
    $Headers{$_} = 1 for keys %{$DynamicFields};
    my %Core = map { $_ => 1 } @Core;
    my @Headers = ( @Core, sort grep { !$Core{$_} } keys %Headers );
    my %Metadata = map { $_ => { Type => 'Text' } } @Headers;
    $Metadata{Name} = { Type => 'Fixed', Fixed => 1 };
    $Metadata{Parent} = { Type => 'Service', Reference => 1 };
    $Metadata{DestQueue} = { Type => 'Queue', Reference => 1 };
    $Metadata{TicketTypes} = { Type => 'Type', Structured => 1 };
    $Metadata{$_} = $Kernel::OM->Get('Kernel::System::ZTSMWorkbookXLSX')->FieldMetadata( Name => $_ ) for keys %{$DynamicFields};
    return { Services => { Headers => \@Headers, Rows => \@Rows, Fields => \%Metadata } };
}

sub _DynamicFields {
    my ($Self) = @_;
    my $List = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldListGet(
        Valid => 1, ObjectType => ['Service'],
    ) || [];
    return { map { $_->{Name} => $_ } grep { IsHashRefWithData($_) && $_->{Name} } @{$List} };
}

sub _RowToService {
    my ( $Self, %Param ) = @_;
    my %Row = %{ $Param{Row} || {} };
    delete $Row{Class};
    my $Name = delete $Row{Name};
    return if !defined $Name || $Name eq '';
    my $DynamicFields = $Self->_DynamicFields;
    my %Dynamic;
    for my $FieldName ( keys %{$DynamicFields} ) {
        $Dynamic{$FieldName} = delete $Row{$FieldName} if exists $Row{$FieldName};
    }
    $Row{Name} = $Name;
    $Row{DynamicFields} = \%Dynamic if %Dynamic;
    return \%Row;
}

sub _Preview {
    my ( $Self, %Param ) = @_;
    my $Model = $Self->_ExportModel->{Services};
    my %Existing = map { ( $_->{Name} // '' ) => $_ } @{ $Model->{Rows} || [] };
    my @Preview;
    for my $Row ( @{ $Param{Rows} || [] } ) {
        my $Name = $Row->{Name} // '';
        my $Candidate = $Existing{$Name};
        my @Clear;
        if ($Candidate) {
            @Clear = grep { $Self->_HasValue( $Candidate->{$_} ) && !$Self->_HasValue( $Row->{$_} ) }
                grep { $_ ne 'Name' } @{ $Model->{Headers} || [] };
        }
        push @Preview, {
            Name => $Name, Status => $Candidate ? 'MATCH_NAME' : 'CREATE_CANDIDATE',
            CandidateName => $Candidate ? $Name : '', CandidateCount => $Candidate ? 1 : 0,
            ClearFields => \@Clear,
        };
    }
    return \@Preview;
}

sub _HasValue {
    my ( $Self, $Value ) = @_;
    return 0 if !defined $Value;
    return @{$Value} ? 1 : 0 if ref $Value eq 'ARRAY';
    return keys %{$Value} ? 1 : 0 if ref $Value eq 'HASH';
    return $Value ne '' ? 1 : 0;
}

1;
