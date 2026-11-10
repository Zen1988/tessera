package Kernel::System::TESSERA::CustomerOnboarding;
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
our @ObjectDependencies=qw(Kernel::System::TESSERA::DirectorySync Kernel::System::CustomerUser Kernel::System::DynamicField Kernel::System::DynamicField::Backend Kernel::System::GovernanceObject);
sub new {bless {},$_[0]}
sub State {
    my ($S,$Login)=@_;my $Sync=$Kernel::OM->Get('Kernel::System::TESSERA::DirectorySync');
    my $External=$Sync->ExternalUser($Login);return {Required=>0} if !$External;
    my $D=$Sync->_Read();my %User=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$Login);
    die "Customer unavailable.\n" if !%User || ($User{ValidID} || 0)!=1;
    my $Text=$D->{Config}{ResponsibilityText} || '';my $Version=sha256_hex($Text);
    my $Consent=$User{TESSERAIdentityConsent} || '';
    my $Defaults=$User{TESSERAIdentityDefaults} || '';
    if ($Defaults) {
        my $DF=$Kernel::OM->Get('Kernel::System::DynamicField');my $B=$Kernel::OM->Get('Kernel::System::DynamicField::Backend');
        my $F=$DF->DynamicFieldGet(Name=>'ZUser-Application');
        my $Value=$F ? $B->ValueGet(DynamicFieldConfig=>$F,ObjectName=>$Login):undef;
        $Value=$Value->[0] if ref $Value eq 'ARRAY' && @$Value==1;
        my $App=defined $Value && !ref $Value && $Value=~/\A[1-9][0-9]*\z/
            ? $Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(GovernanceObjectID=>$Value):undef;
        $Defaults=0 if !$App || ($App->{Class} || '') ne 'Application' || ($App->{ZTSMStatus} || '') ne 'Active';
        require Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults;
        my $Module=Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults->new(UserID=>$Login,ConfigItem=>{});
        my %Teams=$Module->_SupportProfileData(CustomerUserID=>$Login);
        $F=$DF->DynamicFieldGet(Name=>'ZUser-SupportProfile');
        my $Team=$F ? $B->ValueGet(DynamicFieldConfig=>$F,ObjectName=>$Login):undef;
        $Team=$Team->[0] if ref $Team eq 'ARRAY' && @$Team==1;
        $Defaults=0 if (ref $Team) || (%Teams && !$Teams{$Team || ''}) || (!%Teams && $Team);
    }
    return {Required=>1,Step=>!length($Text) ? 'Unavailable':$Consent ne $Version ? 'Consent':$Defaults ? 'Complete':'Defaults',Text=>$Text,Version=>$Version};
}
sub Accept {
    my ($S,%P)=@_;my $State=$S->State($P{Login});
    die "Current responsibility text must be accepted.\n" if !$State->{Required} || $State->{Step} ne 'Consent'
        || !$P{Accepted} || ($P{Version} || '') ne $State->{Version};
    die "Could not record acceptance.\n" if !$Kernel::OM->Get('Kernel::System::CustomerUser')->SetPreferences(UserID=>$P{Login},Key=>'TESSERAIdentityConsent',Value=>$State->{Version});
    # Time/version audit is metadata, never an assignment or authorization.
    $Kernel::OM->Get('Kernel::System::CustomerUser')->SetPreferences(UserID=>$P{Login},Key=>'TESSERAIdentityConsentTime',Value=>time());
    return 1;
}
sub Defaults {
    my ($S,%P)=@_;my $State=$S->State($P{Login});
    die "Accept responsibilities first.\n" if !$State->{Required} || $State->{Step}!~/\A(?:Defaults|Complete)\z/;
    require Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults;
    my $Module=Kernel::Output::HTML::Preferences::ZTSMCustomerDefaults->new(UserID=>$P{Login},ConfigItem=>{});
    my %User=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$P{Login});
    my %Application=$Module->_GovernanceObjectData(Classes=>['Application']);
    my %Team=$Module->_SupportProfileData(CustomerUserID=>$P{Login});
    die "Choose a valid default application.\n" if !$Application{$P{Application} || ''};
    die "Choose an assigned team.\n" if %Team && !$Team{$P{Profile} || ''};
    die "Unassigned team cannot be selected.\n" if !%Team && $P{Profile};
    # Only customer default fields are written. This path has no GO Add/Update.
    my %Values=('ZUser-Application'=>[$P{Application}],'ZUser-SupportProfile'=>[$P{Profile} || '']);
    for my $Name (qw(ZUser-Environment ZUser-Location)) {
        my $F=$Module->_DynamicFieldConfigGet(Name=>$Name);
        my $V=$F ? $Module->_DynamicFieldValueGet(DynamicFieldConfig=>$F,CustomerUserLogin=>$P{Login}):'';
        $Values{$Name}=[$V || ''];
    }
    die "Could not save preferences.\n" if !$Module->Run(UserData=>\%User,GetParam=>\%Values);
    die "Could not finish preferences.\n" if !$Kernel::OM->Get('Kernel::System::CustomerUser')->SetPreferences(UserID=>$P{Login},Key=>'TESSERAIdentityDefaults',Value=>1);
    return 1;
}
1;
