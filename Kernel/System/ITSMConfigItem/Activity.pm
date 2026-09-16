# --
# TESSERA asset-owned activity articles.
# --
package Kernel::System::ITSMConfigItem::Activity;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;

our @ObjectDependencies = (
    'Kernel::System::DB',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::JSON',
);

sub new { my ( $Type, %Param ) = @_; return bless {}, $Type; }

sub ActivityAdd {
    my ( $Self, %Param ) = @_;
    for my $Needed (qw(EventType Source Subject Body UserID)) {
        return if !defined $Param{$Needed} || $Param{$Needed} eq '';
    }
    my $Number = $Param{ConfigItemNumber} // '';
    if ( !$Number && $Param{ConfigItemID} ) {
        $Number = $Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemLookup(
            ConfigItemID => $Param{ConfigItemID},
        ) // '';
    }
    my $Payload = ref $Param{Payload}
        ? $Kernel::OM->Get('Kernel::System::JSON')->Encode( Data => $Param{Payload}, SortKeys => 1, Pretty => 1 )
        : ( $Param{Payload} // '' );
    return $Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL => 'INSERT INTO ztsm_configitem_activity '
            . '(configitem_id, configitem_number, event_type, source, subject, body, payload, create_time, create_by) '
            . 'VALUES (?, ?, ?, ?, ?, ?, ?, current_timestamp, ?)',
        Bind => [
            \$Param{ConfigItemID}, \$Number, \$Param{EventType}, \$Param{Source},
            \$Param{Subject}, \$Param{Body}, \$Payload, \$Param{UserID},
        ],
    );
}

sub ActivityList {
    my ( $Self, %Param ) = @_;
    return [] if !$Param{ConfigItemID};
    my $Rows = $Kernel::OM->Get('Kernel::System::DB')->SelectAll(
        SQL => 'SELECT id, configitem_number, event_type, source, subject, body, payload, create_time, create_by '
            . 'FROM ztsm_configitem_activity WHERE configitem_id = ? ORDER BY id DESC',
        Bind  => [ \$Param{ConfigItemID} ],
        Limit => $Param{Limit} || 500,
    ) || [];
    return [ map {
        { ActivityID => $_->[0], ConfigItemNumber => $_->[1], EventType => $_->[2], Source => $_->[3],
            Subject => $_->[4], Body => $_->[5], Payload => $_->[6], CreateTime => $_->[7], CreateBy => $_->[8] }
    } @{$Rows} ];
}

1;
