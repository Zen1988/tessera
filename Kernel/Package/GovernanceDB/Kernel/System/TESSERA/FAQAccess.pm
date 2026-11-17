package Kernel::System::TESSERA::FAQAccess;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config', 'Kernel::System::Package', 'Kernel::System::FAQ',
    'Kernel::System::DynamicField', 'Kernel::System::DB', 'Kernel::System::Valid',
    'Kernel::System::ITSMConfigItem::CustomerEntitlement',
);

sub new { return bless {}, $_[0] }

sub Get {
    my ($Self, %P) = @_;
    return if (!$P{CustomerUserID} && !$P{Public}) || !$P{ItemID} || $P{ItemID} !~ /\A[1-9][0-9]*\z/;
    my $Field = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(Name => 'FAQApplication');
    return if !$Field || ($Field->{ObjectType} || '') ne 'FAQ'
        || ($Field->{FieldType} || '') ne 'GovernanceObject' || ($Field->{ValidID} || 0) != 1;
    my $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');
    my %FAQ = $FAQObject->FAQGet(ItemID => $P{ItemID}, DynamicFields => 1, UserID => $P{CustomerUserID} || 1);
    return if !$FAQ{ItemID} || !$FAQ{Approved};
    my %Valid = map {$_ => 1} $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();
    return if !$Valid{$FAQ{ValidID} || 0};
    my $Configured = $Kernel::OM->Get('Kernel::Config')->Get($P{Public} ? 'FAQ::Public::StateTypes' : 'FAQ::Customer::StateTypes');
    return if ref $Configured ne 'ARRAY';
    my @Types = grep {$_ eq 'public' || (!$P{Public} && $_ eq 'external')} @$Configured;
    return if !@Types;
    my $States = $FAQObject->StateTypeList(Types => \@Types, UserID => $P{CustomerUserID} || 1) || {};
    return if !$States->{$FAQ{StateTypeID} || 0};
    return if !$Self->ApplicationCheck(CustomerUserID => $P{CustomerUserID}, Public => $P{Public}, Value => $FAQ{'DynamicField_FAQApplication'});
    return \%FAQ;
}

sub ApplicationCheck {
    my ($Self, %P) = @_;
    return if !$P{CustomerUserID} && !$P{Public};
    my $Permission = $Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement');
    # Empty means all portal users. Malformed/nonempty references fail closed.
    return 1 if $Self->_Empty($P{Value});
    return if $P{Public};
    my @Values = $Permission->_ScalarValues($P{Value});
    return if !@Values;
    my %Application;
    for my $Value (@Values) {
        my @Objects = $Permission->_ReferenceObjects(Value => $Value, Class => 'Application');
        return if @Objects != 1;
        $Application{$Objects[0]{GovernanceObjectID}} = 1;
    }
    my $Assignments = $Permission->_AssignmentsGet(CustomerUserID => $P{CustomerUserID});
    for my $Assignment (@$Assignments) {
        for my $Value ($Permission->_ScalarValues($Assignment->{'DynamicField_ZTSMSupportAssignment-Application'})) {
            my @Objects = $Permission->_ReferenceObjects(Value => $Value, Class => 'Application');
            next if @Objects != 1;
            return 1 if $Application{$Objects[0]{GovernanceObjectID}};
        }
    }
    return;
}

sub _Empty {
    my ($Self, $Value) = @_;
    return 1 if !defined $Value || (!ref $Value && $Value eq '');
    return !grep {!$Self->_Empty($_)} @$Value if ref $Value eq 'ARRAY';
    return 0;
}

sub CategoryCount {
    my ($Self, %P) = @_;
    my $DB = $Kernel::OM->Get('Kernel::System::DB');
    return 0 if !$P{CategoryID};
    return 0 if !$DB->Prepare(SQL => 'SELECT id FROM faq_item WHERE category_id = ?', Bind => [\$P{CategoryID}]);
    my @IDs;
    while (my @Row = $DB->FetchrowArray()) {push @IDs, $Row[0]}
    return scalar grep {$Self->Get(%P, ItemID => $_)} @IDs;
}

sub CustomerIDs {
    my ($Self, %P) = @_;
    return [] if !$P{CustomerUserID};
    return [] if !$Kernel::OM->Get('Kernel::System::Package')->PackageIsInstalled(Name => 'FAQ');
    my $DB = $Kernel::OM->Get('Kernel::System::DB');
    return [] if !$DB->Prepare(SQL => 'SELECT id FROM faq_item ORDER BY id');
    my @IDs;
    while (my @Row = $DB->FetchrowArray()) { push @IDs, $Row[0] }
    return [grep {$Self->Get(%P, ItemID => $_)} @IDs];
}

1;
