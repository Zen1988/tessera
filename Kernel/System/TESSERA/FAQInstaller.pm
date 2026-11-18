package Kernel::System::TESSERA::FAQInstaller;

use v5.24;
use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::DB',
    'Kernel::System::FAQ',
    'Kernel::System::Group',
    'Kernel::System::Log',
    'Kernel::System::Main',
);

sub new {
    my ( $Type, %Param ) = @_;
    return bless {}, $Type;
}

sub Ensure {
    my ($Self) = @_;

    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');
    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my %Table = map { lc($_) => 1 } $DBObject->ListTables();
    return $Self->_Fail('FAQ database tables are unavailable.')
        if !$Table{faq_item} || !$Table{faq_category} || !$Table{faq_category_group};

    my $Home = $Kernel::OM->Get('Kernel::Config')->Get('Home') || '.';
    my ( $ContentRef, $ContentFile );
    FILE:
    for my $File (
        "$Home/var/governancedb/faq/tessera_external_api.md",
        "$Home/Custom/var/governancedb/faq/tessera_external_api.md",
    ) {
        next FILE if !-f $File;
        $ContentRef = $Kernel::OM->Get('Kernel::System::Main')->FileRead(
            Location => $File,
            Mode     => 'utf8',
        );
        if ($ContentRef) {
            $ContentFile = $File;
            last FILE;
        }
    }
    return $Self->_Fail('managed FAQ source was not found below Custom/var or var.') if !$ContentRef;

    # These are the supported FAQ object APIs used by the standard FAQ import
    # workflow. TESSERA does not insert or update faq_item content directly.
    my $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');

    my $CategoryID;
    $DBObject->Prepare(
        SQL  => 'SELECT id FROM faq_category WHERE name = ? AND parent_id = 0',
        Bind => [ \('TESSERA') ],
        Limit => 1,
    );
    ($CategoryID) = $DBObject->FetchrowArray();
    $CategoryID ||= $FAQObject->CategoryAdd(
        Name     => 'TESSERA',
        ParentID => 0,
        Comment  => 'Authoritative TESSERA reference documentation.',
        ValidID  => 1,
        UserID   => 1,
    );
    return $Self->_Fail('managed FAQ category could not be created.') if !$CategoryID;

    # FAQ group naming is installation-specific. Reuse the permission boundary
    # of the existing visible Misc root category instead of inventing a group.
    my @RequiredGroupIDs;
    $DBObject->Prepare(
        SQL => <<~'END_SQL',
            SELECT fcg.group_id
              FROM faq_category fc
              JOIN faq_category_group fcg ON fcg.category_id = fc.id
             WHERE fc.name = ?
               AND fc.parent_id = 0
               AND fc.valid_id = 1
            END_SQL
        Bind => [ \('Misc') ],
    );
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @RequiredGroupIDs, $Row[0];
    }

    if ( !@RequiredGroupIDs ) {
        for my $GroupName (
            'faq',
            $Kernel::OM->Get('Kernel::Config')->Get('FAQ::ApprovalGroup') || (),
            'users',
        ) {
            my $GroupID = $Kernel::OM->Get('Kernel::System::Group')->GroupLookup( Group => $GroupName );
            if ($GroupID) {
                @RequiredGroupIDs = ($GroupID);
                last;
            }
        }
    }

    my @CurrentGroupIDs;
    $DBObject->Prepare(
        SQL  => 'SELECT group_id FROM faq_category_group WHERE category_id = ?',
        Bind => [ \$CategoryID ],
    );
    while ( my @Row = $DBObject->FetchrowArray() ) {
        push @CurrentGroupIDs, $Row[0];
    }
    my $CurrentKey  = join ',', sort { $a <=> $b } @CurrentGroupIDs;
    my $RequiredKey = join ',', sort { $a <=> $b } @RequiredGroupIDs;
    if ( @RequiredGroupIDs && $CurrentKey ne $RequiredKey ) {
        return $Self->_Fail('managed FAQ category permission could not be set.')
            if !$FAQObject->SetCategoryGroup(
                CategoryID => $CategoryID,
                GroupIDs   => \@RequiredGroupIDs,
                UserID     => 1,
            );
    }
    elsif ( !@RequiredGroupIDs ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => 'TESSERA managed FAQ found no existing FAQ category permission mapping; article creation will continue.',
        );
    }

    my %Languages = reverse $FAQObject->LanguageList( UserID => 1 );
    my $LanguageID = $Languages{en};
    return $Self->_Fail("FAQ language 'en' does not exist.") if !$LanguageID;

    my %States = reverse $FAQObject->StateList( UserID => 1 );
    my ($StateID) = map { $States{$_} } grep { /\Apublic\b/i } sort keys %States;
    ($StateID) = map { $States{$_} } grep { /\Aexternal\b/i } sort keys %States if !$StateID;
    return $Self->_Fail('no public or external FAQ state exists.') if !$StateID;

    my $ItemID;
    $DBObject->Prepare(
        SQL  => 'SELECT id FROM faq_item WHERE f_name = ?',
        Bind => [ \('tessera-external-api-reference') ],
        Limit => 1,
    );
    ($ItemID) = $DBObject->FetchrowArray();

    my %Managed = (
        Name        => 'tessera-external-api-reference',
        Title       => 'TESSERA External API, Ansible, and Script Engine Reference',
        CategoryID  => $CategoryID,
        StateID     => $StateID,
        LanguageID  => $LanguageID,
        Field1      => ${$ContentRef},
        Field2      => '',
        Field3      => '',
        Field4      => '',
        Field5      => '',
        Field6      => '',
        Keywords    => 'TESSERA API Ansible Script Engine key renewal staging entitlement',
        ContentType => 'text/plain',
        ValidID     => 1,
        Approved    => 1,
        UserID      => 1,
    );

    if ($ItemID) {
        my %Current = $FAQObject->FAQGet(
            ItemID     => $ItemID,
            ItemFields => 1,
            UserID     => 1,
        );
        my $Unchanged = 1;
        for my $Key (qw(Name Title CategoryID StateID LanguageID Field1 Field2 Field3 Field4 Field5 Field6 Keywords ContentType ValidID Approved)) {
            my $Existing = defined $Current{$Key} ? "$Current{$Key}" : '';
            my $Required = defined $Managed{$Key} ? "$Managed{$Key}" : '';
            if ( $Existing ne $Required ) {
                $Unchanged = 0;
                last;
            }
        }
        return $ItemID if $Unchanged;

        my $Updated = $FAQObject->FAQUpdate(
            %Managed,
            ItemID      => $ItemID,
            ApprovalOff => 1,
        );
        return $Self->_Fail("managed FAQ item $ItemID could not be updated.") if !$Updated;
    }
    else {
        $ItemID = $FAQObject->FAQAdd(
            %Managed,
            Number => 'TESSERA-API-REFERENCE',
        );
        return $Self->_Fail("managed FAQ item could not be created from $ContentFile.") if !$ItemID;
    }

    $LogObject->Log(
        Priority => 'notice',
        Message  => "TESSERA managed FAQ ItemID $ItemID installed from $ContentFile.",
    );
    return $ItemID;
}

sub _Fail {
    my ( $Self, $Message ) = @_;
    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'error',
        Message  => "TESSERA managed FAQ installation failed: $Message",
    );
    return;
}

1;
