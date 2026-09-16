# --
# Records every ConfigItem event as an immutable asset activity article.
# --
package Kernel::System::ITSMConfigItem::Event::ActivityRecorder;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;

our @ObjectDependencies = ('Kernel::System::ITSMConfigItem::Activity');
sub new { my ( $Type, %Param ) = @_; return bless {}, $Type; }

sub Run {
    my ( $Self, %Param ) = @_;
    return if !$Param{Event} || ref $Param{Data} ne 'HASH' || !$Param{UserID};
    my $Data = $Param{Data};
    my $Field = $Data->{FieldName} // '';
    my $Body = $Data->{Comment} // '';
    if ( !$Body && exists $Data->{ReadableOldValue} ) {
        $Body = ( $Data->{ReadableOldValue} // '' ) . ' -> ' . ( $Data->{ReadableValue} // '' );
    }
    $Body ||= "ConfigItem activity event: $Param{Event}";
    return $Kernel::OM->Get('Kernel::System::ITSMConfigItem::Activity')->ActivityAdd(
        ConfigItemID     => $Data->{ConfigItemID} || $Data->{ObjectID} || undef,
        ConfigItemNumber => $Data->{Number} // $Data->{ConfigItemNumber} // '',
        EventType        => $Param{Event},
        Source           => 'OTOBO Event',
        Subject          => $Param{Event} . ( $Field ? ": $Field" : '' ),
        Body             => $Body,
        Payload          => $Data,
        UserID           => $Param{UserID},
    );
}

1;
