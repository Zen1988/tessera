package Kernel::Modules::AgentITSMConfigItemActivity;
use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use Kernel::Language qw(Translatable);
our $ObjectManagerDisabled = 1;
sub new { my ( $Type, %Param ) = @_; return bless {%Param}, $Type; }
sub Run {
    my ( $Self, %Param ) = @_;
    my $Request = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $Layout = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ID = $Request->GetParam( Param => 'ConfigItemID' ) || 0;
    my $CI = $ID ? $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet( ConfigItemID => $ID ) : undef;
    return $Layout->ErrorScreen( Message => Translatable('No ConfigItem found!') ) if !$CI;
    my $Rows = $Kernel::OM->Get('Kernel::System::ITSMConfigItem::Activity')->ActivityList( ConfigItemID => $ID );
    for my $Row ( @{$Rows} ) {
        next if !$Row->{CreateTime};
        my $Date = $Kernel::OM->Create('Kernel::System::DateTime', ObjectParams => { String => $Row->{CreateTime} });
        my $Zone = $Self->{UserTimeZone} || $Date->UserDefaultTimeZoneGet();
        $Row->{DisplayTime} = $Date->ToTimeZone( TimeZone => $Zone )
            ? $Date->ToString() . " ($Zone)" : $Row->{CreateTime};
    }
    return join '', $Layout->Header( Type => 'Small', Title => Translatable('Asset Activity Articles') ),
        $Layout->Output( TemplateFile => 'AgentITSMConfigItemActivity', Data => {
            %Param, ConfigItemID => $ID, Number => $CI->{Number}, Name => $CI->{Name}, Activities => $Rows,
        } ), $Layout->Footer( Type => 'Small' );
}
1;
