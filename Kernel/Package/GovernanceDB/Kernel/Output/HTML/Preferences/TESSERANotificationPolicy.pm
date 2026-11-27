package Kernel::Output::HTML::Preferences::TESSERANotificationPolicy;

use strict;
use warnings;
use parent qw(Kernel::Output::HTML::Preferences::Generic);
use Kernel::Language qw(Translatable);

sub Param {
    my ( $Self, %Param ) = @_;
    my $Login = $Self->{UserLogin} || $Self->{UserID};
    my %Stored = $Self->{UserObject}->GetPreferences( UserID => $Login );
    my $Policy = $Kernel::OM->Get('Kernel::System::TESSERA::NotificationPolicy')->Normalize(
        $Stored{ZTSMNotificationPolicy},
    ) // 'Detailed';
    return ( { %Param, Name => 'ZTSMNotificationPolicy', SelectedID => $Policy } );
}

sub Run {
    my ( $Self, %Param ) = @_;
    my $Login = $Self->{UserLogin} || $Self->{UserID};
    my $Values = $Param{GetParam}->{ZTSMNotificationPolicy};
    my $Policy = ref $Values eq 'ARRAY' && @{$Values} == 1
        ? $Kernel::OM->Get('Kernel::System::TESSERA::NotificationPolicy')->Normalize($Values->[0])
        : undef;
    if ( !defined $Policy ) {
        $Self->{Error} = Translatable('Select a valid email update option.');
        return;
    }
    if ( $Kernel::OM->Get('Kernel::Config')->Get('DemoSystem') ) {
        $Self->{Error} = Translatable('The email update preference could not be saved.');
        return;
    }
    my $Saved = $Self->{UserObject}->SetPreferences(
        UserID => $Login, Key => 'ZTSMNotificationPolicy', Value => $Policy,
    );
    my %Stored = $Self->{UserObject}->GetPreferences( UserID => $Login );
    if ( !$Saved || ($Stored{ZTSMNotificationPolicy} // '') ne $Policy ) {
        $Self->{Error} = Translatable('The email update preference could not be saved.');
        return;
    }
    $Self->{Message} = Translatable('Email update preference saved.');
    return 1;
}

1;
