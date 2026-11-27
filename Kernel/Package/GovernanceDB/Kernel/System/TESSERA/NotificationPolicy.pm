package Kernel::System::TESSERA::NotificationPolicy;

use strict;
use warnings;

our @ObjectDependencies = ();

sub new { return bless {}, shift }

# Completion/Detailed are the persisted keys on previously deployed tickets.
sub Normalize {
    my ( $Self, $Value ) = @_;
    return if !defined $Value || ref $Value;
    my %Keys = (
        Completion => 'Completion', Minimal => 'Completion',
        Detailed => 'Detailed', Standard => 'Detailed',
        Exclusive => 'Exclusive', None => 'None',
    );
    return $Keys{$Value};
}

sub Evaluate {
    my ( $Self, %Event ) = @_;
    my $Policy = $Self->Normalize($Event{Policy}) // '';
    my $Kind   = $Event{Kind} // '';
    return { Eligible => 0, Reason => 'No notification policy' }
        if $Policy !~ /\A(?:Completion|Detailed|Exclusive)\z/;
    return { Eligible => 0, Reason => 'Only master ticket events qualify' }
        if !$Event{Master};

    return { Eligible => 1, Reason => 'Master ticket raised' } if $Kind eq 'Created';
    if ( $Kind eq 'StateChanged' && $Event{StateChanged} ) {
        return { Eligible => 1, Reason => 'Master ticket closed', Article => $Policy ne 'Completion' ? 'LatestPublic' : undef }
            if ($Event{PreviousStateType} // '') ne 'closed' && ($Event{StateType} // '') eq 'closed';
        return { Eligible => 1, Reason => 'Master ticket status changed', Article => 'LatestPublic' }
            if $Policy ne 'Completion';
    }
    if ( $Kind eq 'ArticleCreated' && $Policy eq 'Exclusive' && $Event{CustomerVisible} ) {
        return { Eligible => 1, Reason => 'Customer-visible master article', Article => 'TriggeringPublic' };
    }
    return { Eligible => 0, Reason => 'Event is outside this policy' };
}

1;
