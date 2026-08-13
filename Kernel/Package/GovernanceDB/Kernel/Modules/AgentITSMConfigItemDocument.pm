# --
# TESSERA ConfigItem YAML/JSON frontend.
# --
package Kernel::Modules::AgentITSMConfigItemDocument;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use Kernel::Language qw(Translatable);
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our $ObjectManagerDisabled = 1;

sub new { my ( $Type, %Param ) = @_; return bless {%Param}, $Type; }

sub Run {
    my ( $Self, %Param ) = @_;
    my $Request  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $Layout   = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $Document = $Kernel::OM->Get('Kernel::System::ITSMConfigItem::Document');
    my $CIObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');

    my $ConfigItemID = $Request->GetParam( Param => 'ConfigItemID' ) || 0;
    my $Format = lc( $Request->GetParam( Param => 'Format' ) || 'yaml' );
    $Format = $Format eq 'json' ? 'json' : 'yaml';
    my ( $Text, $Message, $MessageClass ) = ('', '', '');

    if ( ( $Self->{Subaction} || '' ) eq 'Import' ) {
        $Text = $Request->GetParam( Param => 'Document' ) || '';
        my $Result = $Document->Import(
            Content => $Text,
            Format  => $Format,
            UserID  => $Self->{UserID},
            Source  => 'YAML/JSON Import',
        );
        $Message = IsHashRefWithData($Result) ? $Result->{Message} : Translatable('Import failed.');
        $MessageClass = IsHashRefWithData($Result) && $Result->{Success} ? 'Success' : 'Error';
        if ( IsHashRefWithData($Result) && $Result->{Success} ) {
            $ConfigItemID = $Result->{ConfigItemID};
            $Text = $Document->Export(
                ConfigItemID => $ConfigItemID,
                Format       => $Format,
                UserID       => $Self->{UserID},
            );
        }
    }
    elsif ($ConfigItemID) {
        $Text = $Document->Export(
            ConfigItemID => $ConfigItemID,
            Format       => $Format,
            UserID       => $Self->{UserID},
        );
    }

    my $CI = $ConfigItemID ? $CIObject->ConfigItemGet( ConfigItemID => $ConfigItemID ) : {};
    return join '',
        $Layout->Header( Type => 'Small', Title => Translatable('CMDB as Code') ),
        $Layout->Output(
            TemplateFile => 'AgentITSMConfigItemDocument',
            Data => {
                %Param,
                ConfigItemID => $ConfigItemID,
                Number       => $CI->{Number} // '',
                Name         => $CI->{Name} // '',
                Format       => $Format,
                Document     => $Text,
                Message      => $Message,
                MessageClass => $MessageClass,
            },
        ),
        $Layout->Footer( Type => 'Small' );
}

1;
