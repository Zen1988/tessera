package Kernel::Modules::AgentGovernanceOSCALImport;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

use Kernel::System::VariableCheck qw(IsHashRefWithData IsStringWithData);

our $ObjectManagerDisabled = 1;

sub new { my ( $Type, %Param ) = @_; return bless {%Param}, $Type }

sub Run {
    my ( $Self, %Param ) = @_;
    my $Request = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $Layout  = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $Cache   = $Kernel::OM->Get('Kernel::System::Cache');
    my $Importer = $Kernel::OM->Get('Kernel::System::GovernanceObject::OSCALImport');
    my $Subaction = $Self->{Subaction} || '';
    my $CacheKey = 'AgentGovernanceOSCALImport::' . $Self->{UserID};
    my ( $Plan, $Message, $MessageClass );

    if ( $Subaction eq 'Preview' ) {
        my %Upload = $Request->GetUploadAll( Param => 'OSCALFile' );
        my $Content = $Upload{Content} || $Request->GetParam( Param => 'OSCALDocument' ) || '';
        $Plan = $Importer->Plan( Content => $Content );
        if ( IsHashRefWithData($Plan) && $Plan->{Success} ) {
            $Cache->Set( Type => 'AgentGovernanceOSCALImport', Key => $CacheKey, Value => $Plan, TTL => 60 * 60 );
            $MessageClass = 'Success';
        }
        else { $MessageClass = 'Error' }
        $Message = IsHashRefWithData($Plan) ? $Plan->{Message} : 'Could not parse OSCAL catalog.';
    }
    elsif ( $Subaction eq 'Import' ) {
        $Layout->ChallengeTokenCheck();
        $Plan = $Cache->Get( Type => 'AgentGovernanceOSCALImport', Key => $CacheKey );
        if ( !IsHashRefWithData($Plan) ) {
            $Message = 'The OSCAL preview expired. Upload and preview the catalog again.';
            $MessageClass = 'Error';
        }
        else {
            my $Result = $Importer->Import( Plan => $Plan, UserID => $Self->{UserID} );
            $Message = $Result->{Message};
            $MessageClass = $Result->{Success} ? 'Success' : 'Error';
            $Param{ImportErrors} = $Result->{Errors};
            $Cache->Delete( Type => 'AgentGovernanceOSCALImport', Key => $CacheKey ) if $Result->{Success};
        }
    }

    return join '', $Layout->Header( Type => 'Small', Title => 'OSCAL Policy Import' ),
        $Layout->Output( TemplateFile => 'AgentGovernanceOSCALImport', Data => {
            %Param, Plan => $Plan, Message => $Message, MessageClass => $MessageClass,
        }), $Layout->Footer( Type => 'Small' );
}

1;
