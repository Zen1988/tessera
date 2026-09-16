# --
# Watches the Control execution ledger and delegates failed results to the
# parent ControlObjective instruction runtime.
# --
package Kernel::System::ITSMConfigItem::Event::ControlFailureWatcher;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;

our @ObjectDependencies = (
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Log',
    'Kernel::System::TESSERA::ControlRuntime',
);

sub new { my ( $Type, %Param ) = @_; return bless {}, $Type; }

sub Run {
    my ( $Self, %Param ) = @_;

    return 1 if !$Param{Event} || ref $Param{Data} ne 'HASH';
    return 1 if $Param{Event} !~ m{\AConfigItemDynamicFieldUpdate(?:_ZRM-Result)?\z};

    my $Data = $Param{Data};
    return 1 if ( $Data->{FieldName} || 'ZRM-Result' ) ne 'ZRM-Result';
    my $ConfigItemID = $Data->{ConfigItemID} || $Data->{ObjectID};
    return 1 if !$ConfigItemID;

    my $Control = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemGet(
        ConfigItemID  => $ConfigItemID,
        DynamicFields => 1,
        Silent        => 1,
    );
    return 1 if ref $Control ne 'HASH' || ( $Control->{Class} || '' ) ne 'Control';
    my $Result = $Control->{'DynamicField_ZRM-Result'};
    $Result = $Result->[0] if ref $Result eq 'ARRAY' && @{$Result} == 1;
    return 1 if ref $Result || lc( $Result || '' ) ne 'fail';

    my $Handled = $Kernel::OM->Get('Kernel::System::TESSERA::ControlRuntime')->ProcessFailedControl(
        ConfigItemID => $ConfigItemID,
        Control      => $Control,
        Result       => $Result,
        UserID       => $Param{UserID} || 1,
    );
    if ( !$Handled->{Success} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'ControlFailureWatcher failed for ConfigItemID=' . $ConfigItemID . ': '
                . ( $Handled->{Reason} || $Handled->{RiskError} || 'UNKNOWN' ),
        );
    }
    return 1;
}

1;
