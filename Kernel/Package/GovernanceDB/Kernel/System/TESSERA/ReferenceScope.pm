package Kernel::System::TESSERA::ReferenceScope;
use strict;
use warnings;

# Read-only, typed reference expansion for authored policy partitions/resolvers.
sub new { bless {}, $_[0] }
sub Field {
    my ($Self,$Object,$Name)=@_;
    die "Invalid reference field.\n" if ref $Object ne 'HASH' || !defined $Name || $Name !~ /\A[A-Za-z][A-Za-z0-9_-]*\z/;
    return exists $Object->{$Name} ? $Object->{$Name} : $Object->{"DynamicField_$Name"};
}
sub IDs {
    my ($Self,$Value,$Label,$Empty)=@_;
    return () if $Empty && (!defined $Value || (!ref $Value && $Value eq ''));
    my @IDs=ref $Value eq 'ARRAY' ? @$Value : ($Value);
    die "$Label is empty.\n" if !@IDs && !$Empty;
    die "$Label contains an invalid reference.\n" if grep { !defined $_ || ref $_ || $_ !~ /\A[1-9][0-9]*\z/ } @IDs;
    my %Seen; return grep {!$Seen{$_}++} @IDs;
}
sub Values {
    my ($Self,$Context,$Path)=@_;
    die "Invalid reference path.\n" if !defined $Path || $Path !~ /\A[A-Z][A-Z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_-]*(?:\[\*\])?)+\z/;
    my ($Root,@Parts)=split /\./,$Path;
    my @Values=($Context->{$Root});
    for my $Part (@Parts) {
        my $Expand=$Part =~ s/\[\*\]\z//;
        my @Next;
        for my $Object (@Values) {
            die "Reference path '$Path' cannot be read.\n" if ref $Object ne 'HASH';
            my $Value=$Self->Field($Object,$Part);
            if ($Expand) { die "Reference path '$Path' requires a list.\n" if ref $Value ne 'ARRAY'; push @Next,@$Value; }
            else { push @Next,$Value; }
        }
        @Values=@Next;
    }
    return @Values;
}
sub Object {
    my ($Self,$ID,$Type,$UserID,$AnyClass)=@_;
    my ($Kind,$Class)=defined $Type ? $Type =~ /\A(ITSMConfigItem|GovernanceObject)\.([A-Za-z][A-Za-z0-9_-]*)\z/ : ();
    die "Invalid reference type.\n" if !$Kind;
    ($ID)=$Self->IDs($ID,'Typed reference');
    my $Object=$Kernel::OM->Get("Kernel::System::$Kind");
    my $Key=$Kind eq 'ITSMConfigItem' ? 'ConfigItemID' : 'GovernanceObjectID';
    if (($UserID||1) != 1) {
        die "Reference permission denied.\n" if !$Object->Permission(Scope=>'Item',Type=>'ro',ItemID=>$ID,UserID=>$UserID);
    }
    my $Get=$Kind eq 'ITSMConfigItem' ? 'ConfigItemGet' : 'GovernanceObjectGet';
    my $Data=$Object->$Get($Key=>$ID,DynamicFields=>1,UserID=>$UserID||1,Silent=>1);
    die "Typed reference cannot be read.\n" if ref $Data ne 'HASH' || !$Data->{$Key} || $Data->{$Key} != $ID;
    return if $AnyClass && ($Data->{Class}||'') ne $Class;
    die "Reference does not match $Type.\n" if ($Data->{Class}||'') ne $Class;
    die "Governance reference is not Active.\n" if $Kind eq 'GovernanceObject' && ($Data->{ZTSMStatus}||'') ne 'Active';
    return $Data;
}
sub FieldValidate {
    my ($Self,$Name,$Owner,$Target)=@_;
    die "Invalid reference field name.\n" if !$Name || $Name !~ /\A[A-Za-z][A-Za-z0-9_-]*\z/;
    my $Field=$Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(Name=>$Name);
    die "Reference field $Name is not a $Owner to $Target reference.\n"
        if ref $Field ne 'HASH' || ($Field->{ObjectType}||'') ne $Owner
        || ($Field->{Config}{ReferencedObjectType}||'') ne $Target;
}
sub Partition {
    my ($Self,%P)=@_; my $Rule=$P{Rule};
    die "PARTITION BY requires entitlement FROM, AS, COVERAGE, RESOLVE and MEMBERS AS.\n"
        if ref $Rule ne 'HASH' || ($Rule->{AS}||'') ne 'ITSMConfigItem.ContractEntitlement'
        || ref $Rule->{COVERAGE} ne 'HASH' || ref $Rule->{RESOLVE} ne 'HASH'
        || ($Rule->{'MEMBERS AS'}||'') !~ /\A[A-Za-z][A-Za-z0-9_-]*\z/;
    my ($Coverage,$Resolve)=@$Rule{qw(COVERAGE RESOLVE)};
    my @EntitlementIDs=map {$Self->IDs($_,'Asset ContractEntitlement',1)} $Self->Values($P{Context},$Rule->{FROM});
    die "Coverage requires TechnologyProfile AS, MATCH paths and bounded ancestry.\n"
        if ($Coverage->{AS}||'') ne 'GovernanceObject.TechnologyProfile' || ref $Coverage->{MATCH} ne 'ARRAY' || !@{$Coverage->{MATCH}}
        || ($Coverage->{'MAX DEPTH'}||'') !~ /\A[1-9][0-9]*\z/ || $Coverage->{'MAX DEPTH'}>100
        || ($Coverage->{LIMIT}||'') !~ /\A[1-9][0-9]*\z/ || $Coverage->{LIMIT}>1000
        || !defined $Coverage->{'INCLUDE CHILDREN'} || $Coverage->{'INCLUDE CHILDREN'} !~ /\A[01]\z/;
    die "Partition resolver must name a SupportProfile alias.\n"
        if ($Resolve->{AS}||'') ne 'GovernanceObject.SupportProfile' || ($Resolve->{ALIAS}||'') !~ /\A[A-Z][A-Z0-9_]*\z/;
    $Self->FieldValidate($Coverage->{FIELD},'ITSMConfigItem','GovernanceObject');
    $Self->FieldValidate($Coverage->{'PARENT FIELD'},'GovernanceObject','GovernanceObject');
    $Self->FieldValidate($Resolve->{FIELD},'ITSMConfigItem','GovernanceObject');
    if (!@EntitlementIDs) {
        my $Profile=$Self->ApplicationDefault(Rule=>$Rule->{'ON MISSING'},Context=>$P{Context},UserID=>$P{UserID});
        return [{ID=>$Profile->{GovernanceObjectID},Object=>$Profile,EntitlementIDs=>[],Fallback=>1}];
    }
    my @Technology;
    for my $Path (@{$Coverage->{MATCH}}) {
        push @Technology,map {$Self->IDs($_,'Product TechnologyProfile',1)} $Self->Values($P{Context},$Path);
    }
    die "Affected Product has no TechnologyProfile.\n" if !@Technology;
    my %Ancestors;
    my (%Visited,%Stack);
    my $Walk;
    $Walk=sub {
        my ($ID,$Depth)=@_;
        die "TechnologyProfile ancestry cycle.\n" if $Stack{$ID};
        die "TechnologyProfile ancestry depth exceeded.\n" if $Depth>$Coverage->{'MAX DEPTH'};
        return if $Visited{$ID};
        die "TechnologyProfile ancestry limit exceeded.\n" if keys(%Visited)>=$Coverage->{LIMIT};
        $Stack{$ID}=1;
        my $Profile=$Self->Object($ID,$Coverage->{AS},$P{UserID});
        $Visited{$ID}=1; $Ancestors{$ID}=1;
        if ($Coverage->{'INCLUDE CHILDREN'}) {
            $Walk->($_,$Depth+1) for $Self->IDs($Self->Field($Profile,$Coverage->{'PARENT FIELD'}),'TechnologyProfile parent',1);
        }
        delete $Stack{$ID};
    };
    $Walk->($_,0) for @Technology;
    die "Entitlement partition limit exceeded.\n" if @EntitlementIDs>1000;
    my (%Partitions,%Seen);
    for my $ID (@EntitlementIDs) {
        next if $Seen{$ID}++;
        my $Entitlement=$Self->Object($ID,$Rule->{AS},$P{UserID});
        my @Coverage=$Self->IDs($Self->Field($Entitlement,$Coverage->{FIELD}),'Contract coverage');
        $Self->Object($_,$Coverage->{AS},$P{UserID}) for @Coverage;
        next if !grep {$Ancestors{$_}} @Coverage;
        my @Support=$Self->IDs($Self->Field($Entitlement,$Resolve->{FIELD}),'Contract SupportProfile');
        die "Contract SupportProfile is ambiguous.\n" if @Support!=1;
        my $Profile=$Self->Object($Support[0],$Resolve->{AS},$P{UserID});
        $Partitions{$Support[0]}{Object}=$Profile;
        $Partitions{$Support[0]}{EntitlementIDs}{$ID}=1;
    }
    die "No linked ContractEntitlement covers the affected Product technology.\n" if !keys %Partitions;
    return [map {{ID=>$_,Object=>$Partitions{$_}{Object},EntitlementIDs=>[sort {$a<=>$b} keys %{$Partitions{$_}{EntitlementIDs}}]}} sort {$a<=>$b} keys %Partitions];
}
sub Resolve {
    my ($Self,%P)=@_; my $Rule=$P{Rule};
    die "RESOLVE REFERENCES requires FROM, THROUGH, FIELD and AS.\n"
        if ref $Rule ne 'HASH' || ($Rule->{THROUGH}||'') ne 'ITSMConfigItem.ContractEntitlement'
        || ($Rule->{AS}||'') ne 'GovernanceObject.SupportProfile';
    $Self->FieldValidate($Rule->{FIELD},'ITSMConfigItem','GovernanceObject');
    my @IDs=map {$Self->IDs($_,'Related reference')} $Self->Values($P{Context},$Rule->{FROM});
    die "Related reference limit exceeded.\n" if @IDs>1000;
    my %Support;
    for my $ID (@IDs) {
        my $Entitlement=$Self->Object($ID,$Rule->{THROUGH},$P{UserID},1);
        next if !$Entitlement;
        my @Profiles=$Self->IDs($Self->Field($Entitlement,$Rule->{FIELD}),'Entitlement SupportProfile');
        die "Entitlement SupportProfile is ambiguous.\n" if @Profiles!=1;
        $Support{$Profiles[0]}=$Self->Object($Profiles[0],$Rule->{AS},$P{UserID});
    }
    return $Self->ApplicationDefault(Rule=>$Rule->{'ON MISSING'},Context=>$P{Context},UserID=>$P{UserID}) if !keys %Support;
    die "Related entitlements must resolve exactly one SupportProfile.\n" if keys(%Support)!=1;
    return (values %Support)[0];
}
sub ApplicationDefault {
    my ($Self,%P)=@_;my $Rule=$P{Rule};
    die "Missing entitlement requires an authored Application default fallback.\n"
        if ref $Rule ne 'HASH' || !$Rule->{APPLICATION} || !$Rule->{ROLE} || ref $Rule->{ROLE};
    die "Reserved capabilities cannot resolve ownership.\n" if $Rule->{ROLE} =~ /\ATESSERA::/i;
    my @Applications=map {$Self->IDs($_,'Fallback Application')} $Self->Values($P{Context},$Rule->{APPLICATION});
    die "Fallback Application is ambiguous.\n" if @Applications!=1;
    $Self->Object($Applications[0],'GovernanceObject.Application',$P{UserID});
    my $GO=$Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @Roles=$GO->GovernanceObjectSearch(Result=>'ARRAY',Classes=>['GovernanceRole'],
        NameExact=>$Rule->{ROLE},Limit=>2,UserID=>$P{UserID}||1,Permission=>'ro');
    die "Fallback GovernanceRole is missing or ambiguous.\n" if @Roles!=1;
    my $Role=$Self->Object($Roles[0],'GovernanceObject.GovernanceRole',$P{UserID});
    my $Result=$Kernel::OM->Get('Kernel::System::TESSERA::GovernanceRoleResolver')->Resolve(
        GovernanceRole=>$Role,UserID=>$P{UserID}||1,Ticket=>{Type=>'ServiceRequest',
        'DynamicField_ZTicket-Application'=>$Applications[0]});
    die "Application default resolution failed for Application $Applications[0] and GovernanceRole $Roles[0]: "
        . (($Result->{Error} || $Result->{Status} || 'unknown resolver error') =~ s/\s+\z//r) . ".\n"
        if !$Result->{Success};
    die "Application default resolver returned an unexpected type.\n"
        if ($Result->{ValueType}||'') ne 'GovernanceObject.SupportProfile';
    my @IDs=$Self->IDs($Result->{Value},'Application default SupportProfile');
    die "Application default SupportProfile is ambiguous.\n" if @IDs!=1;
    return $Self->Object($IDs[0],'GovernanceObject.SupportProfile',$P{UserID});
}
1;
