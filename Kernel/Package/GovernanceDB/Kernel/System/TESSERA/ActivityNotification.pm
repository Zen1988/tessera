package Kernel::System::TESSERA::ActivityNotification;

use strict;
use warnings;
use JSON::PP ();

our @ObjectDependencies = ();

sub new { return bless {}, shift }

sub RulesParse {
    my ( $Self, $Source ) = @_;
    return if !defined $Source || ref $Source || length($Source) > 3800;
    my $Rules = eval { JSON::PP->new->decode($Source) };
    return if ref $Rules ne 'HASH'
        || keys(%{$Rules}) != 2
        || grep { !defined $Rules->{$_} || ref $Rules->{$_} || $Rules->{$_} !~ /\A[1-9][0-9]{0,2}\z/ }
            qw(SecondaryAfterDays EscalationAfterDays);
    return if $Rules->{EscalationAfterDays} <= $Rules->{SecondaryAfterDays};
    return $Rules;
}

sub ActiveSeconds {
    my ( $Self, %Param ) = @_;
    my $States = $Param{Timeline};
    my $Now = $Param{Now};
    return if !$States || !@{$States} || !defined $Now;
    my $Total = 0;
    for my $Index ( 0 .. $#{$States} ) {
        my ( $Start, $Paused ) = @{ $States->[$Index] };
        my $End = $Index == $#{$States} ? $Now : $States->[ $Index + 1 ]->[0];
        return if !defined $Start || !defined $End || $End < $Start;
        $Total += $End - $Start if !$Paused;
    }
    return $Total;
}

sub Evaluate {
    my ( $Self, %Activity ) = @_;
    my $Event = $Activity{Event} // '';
    if ( $Event eq 'ChildCreated' ) {
        return { Stage => 'Pre', Template => $Activity{PreNotificationTemplate} } if $Activity{PreNotificationTemplate};
    }
    elsif ( $Event eq 'OutcomeRecorded' ) {
        return { Stage => 'Post', Template => $Activity{PostNotificationTemplate} }
            if $Activity{PostNotificationTemplate} && defined $Activity{Outcome} && $Activity{Outcome} ne '';
    }
    elsif ( $Event eq 'Timer' ) {
        my $Rules = $Self->RulesParse( $Activity{Rules} );
        my $Days = $Activity{AgeDays};
        return {} if !$Rules || $Activity{Closed} || $Activity{OnHold} || !defined $Activity{Owner} || $Activity{Owner} ne ''
            || !$Activity{SupportProfile} || !defined $Days || $Days !~ /\A[0-9]+(?:\.[0-9]+)?\z/;
        my $Role = $Days >= $Rules->{EscalationAfterDays} ? 'SUPPORT::ESCALATION'
            : $Days >= $Rules->{SecondaryAfterDays} ? 'SUPPORT::SECONDARY' : '';
        return { Stage => 'Escalation policy', Role => $Role, SupportProfile => $Activity{SupportProfile} } if $Role;
    }
    return {};
}

1;
