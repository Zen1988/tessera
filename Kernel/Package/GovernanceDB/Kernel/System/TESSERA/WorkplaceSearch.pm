package Kernel::System::TESSERA::WorkplaceSearch;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Elasticsearch', 'Kernel::System::GenericInterface::Requester',
    'Kernel::System::ITSMConfigItem', 'Kernel::System::ITSMConfigItem::CustomerEntitlement',
    'Kernel::System::CustomerUser', 'Kernel::System::Valid',
    'Kernel::System::TESSERA::FAQAccess',
);

sub new { return bless {}, $_[0] }

# Index matches never authorize access. Intersect with current source objects
# first, in bounded terms batches, so ES's result window cannot truncate scope.
sub _Matches {
    my ($Self, %P) = @_;
    return [] if !@{$P{IDs} || []};
    my $ES = $Kernel::OM->Get('Kernel::System::Elasticsearch');
    return if !$ES->{WebserviceID};
    my @IDs = @{$P{IDs}};
    my %Found;
    while (@IDs) {
        my @Batch = splice @IDs, 0, 250;
        my $Result = $Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(
            WebserviceID => $ES->{WebserviceID}, Invoker => 'Search', Asynchronous => 0,
            Data => {
                IndexName => $P{Index}, Limit => scalar @Batch, From => 0,
                Return => [$P{Key}],
                Filter => [{ids => {values => \@Batch}}],
                Must => [{multi_match => {
                    query => $P{Query}, fields => $P{Fields}, type => 'bool_prefix', operator => 'and',
                }}],
            },
        );
        return if !$Result || !$Result->{Success}
            || ref $Result->{Data}{Records} ne 'ARRAY';
        my %Batch = map {$_ => 1} @Batch;
        for my $Record (@{$Result->{Data}{Records}}) {
            my $ID = $Record->{$P{Key}};
            $Found{$ID} = 1 if defined $ID && $Batch{$ID};
        }
    }
    return [sort keys %Found];
}

sub Search {
    my ($Self, %P) = @_;
    return {Rows => [], Total => 0} if !$P{CustomerUserID} || !$P{Query};
    my @Rows;
    if ($P{Scope} eq 'Asset') {
        my $CI = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
        my $Permission = $Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement');
        return {Rows => [], Total => 0} if !$Permission->CustomerHasCMDBReadRole(CustomerUserID => $P{CustomerUserID});
        my $Count = $CI->ConfigItemSearch(Result => 'COUNT', CacheTTL => 0);
        return {Rows => [], Total => 0} if !$Count;
        my @IDs = $CI->ConfigItemSearch(Result => 'ARRAY', Limit => $Count, CacheTTL => 0);
        my $Matches = $Self->_Matches(IDs => \@IDs, Index => 'configitem', Key => 'ConfigItemID',
            Query => $P{Query}, Fields => ['Name', 'Number']);
        return {Rows => [], Total => 0, Unavailable => 1} if !defined $Matches;
        for my $ID (@$Matches) {
            next if !$Permission->ConfigItemDetailAccessCheck(CustomerUserID => $P{CustomerUserID}, ConfigItemID => $ID, LogNo => 1);
            my $Data = $CI->ConfigItemGet(ConfigItemID => $ID);
            next if !$Data || !$Data->{ConfigItemID};
            push @Rows, {Type => 'Asset', ID => $ID, Name => $Data->{Name}, Description => $Data->{Number}, Action => 'CustomerITSMConfigItemZoom', Parameter => 'ConfigItemID'};
        }
    }
    elsif ($P{Scope} eq 'People') {
        my $CU = $Kernel::OM->Get('Kernel::System::CustomerUser');
        my $IDs = $CU->CustomerSearchDetail(Valid => 1, Result => 'ARRAY');
        my $Matches = $Self->_Matches(IDs => $IDs || [], Index => 'customeruser', Key => 'CustomerKey',
            Query => $P{Query}, Fields => [qw(UserLogin UserFirstname UserLastname UserFullname UserEmail)]);
        return {Rows => [], Total => 0, Unavailable => 1} if !defined $Matches;
        my %Valid = map {$_ => 1} $Kernel::OM->Get('Kernel::System::Valid')->ValidIDsGet();
        for my $ID (@$Matches) {
            my %User = $CU->CustomerUserDataGet(User => $ID);
            next if !$Valid{$User{ValidID} || 0};
            # Explicit directory projection: never return full user records,
            # preferences, passwords, tokens, groups or dynamic fields.
            push @Rows, {Type => 'People', Name => $User{UserFullname} || join(' ', grep {defined && length} @User{qw(UserFirstname UserLastname)}) || $ID,
                Description => $User{UserEmail} || '', Contact => $User{UserPhone} || ''};
        }
    }
    elsif ($P{Scope} eq 'FAQ') {
        my $Access = $Kernel::OM->Get('Kernel::System::TESSERA::FAQAccess');
        my $IDs = $Access->CustomerIDs(CustomerUserID => $P{CustomerUserID});
        my @Fields = qw(Title Number Keywords);
        for my $N (1..6) {
            my $Field = $Kernel::OM->Get('Kernel::Config')->Get('FAQ::Item::Field' . $N) || {};
            push @Fields, 'Field' . $N if ($Field->{Show} || '') =~ /\A(?:external|public)\z/;
        }
        my $Matches = $Self->_Matches(IDs => $IDs, Index => 'faq', Key => 'ItemID',
            Query => $P{Query}, Fields => \@Fields);
        return {Rows => [], Total => 0, Unavailable => 1} if !defined $Matches;
        for my $ID (@$Matches) {
            my $FAQ = $Access->Get(CustomerUserID => $P{CustomerUserID}, ItemID => $ID);
            next if !$FAQ;
            push @Rows, {Type => 'FAQ', ID => $ID, Name => $FAQ->{Title}, Description => $FAQ->{Number}, Action => 'CustomerFAQZoom', Parameter => 'ItemID'};
        }
    }
    @Rows = sort {lc($a->{Name} || '') cmp lc($b->{Name} || '') || ($a->{ID} || '') cmp ($b->{ID} || '')} @Rows;
    return {Rows => \@Rows, Total => scalar @Rows};
}

1;
