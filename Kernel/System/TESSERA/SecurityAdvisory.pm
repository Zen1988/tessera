package Kernel::System::TESSERA::SecurityAdvisory;
use strict;
use warnings;
use Kernel::System::TESSERA::ScriptBlocks qw(Assemble SplitSource);
use Time::Local qw(timegm);
our @ObjectDependencies = qw(Kernel::Config Kernel::System::ITSMConfigItem Kernel::System::ITSMConfigItem::Document Kernel::System::ITSMConfigItem::CustomerEntitlement Kernel::System::CustomerUser Kernel::System::DynamicField Kernel::System::DynamicField::Backend Kernel::System::GeneralCatalog Kernel::System::GovernanceObject Kernel::System::YAML Kernel::System::TESSERA::ScriptEngine Kernel::System::ITSMConfigItem::Activity Kernel::System::HTMLUtils);
sub new { bless {},shift }
sub AccessCheck {
    my ($Self,%P)=@_;
    return $Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->CustomerHasRole(
        CustomerUserID=>$P{CustomerUserID},Role=>'TESSERA::CMDB::SECOPS');
}
sub Model {
    my ($Self,%P)=@_;
    die "Security operations access required" if !$Self->AccessCheck(%P);
    my $CI=$Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $Catalog=$Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my %Classes=reverse %{$Catalog->ItemList(Class=>'ITSM::ConfigItem::Class')||{}};
    die "SecurityAdvisory class is unavailable" if !$Classes{SecurityAdvisory};
    my $Def=$CI->DefinitionGet(ClassID=>$Classes{SecurityAdvisory});
    my @Order=qw(ZTAM-Annex ZTAM-AdvisoryType ZTAM-Source ZTAM-CVE ZTAM-EventSeverity ZTAM-Status ZTAM-IssuedDate ZTAM-DueDate ZTAM-closure AdvancedCondition ZTAM-ImpactText ZTAM-Recommendation ZRM-PrivilegeRequired ZRM-AttackVector ZRM-Complexity ZRM-InteractionRequirement ZRM-Discoverability ZRM-Reproducibility ZRM-Confidentiality ZRM-Integrity ZRM-Availability ZRM-CodeExecution ZRM-PrivilegeEscalation ZRM-AdditionalDamage ZTAM-Application ZTAM-ContractEntitlement);
    my @Fields;
    for my $Name (@Order) {
        my $F=$Def->{DynamicFieldRef}{$Name} || $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(Name=>$Name);
        die "Advisory field $Name is unavailable" if ref $F ne 'HASH';
        push @Fields,{%$F,Choices=>[]};
    }
    my $PanelID=$Kernel::OM->Get('Kernel::Config')->Get('CustomerPanelUserID')||1;
    # This narrow portal exposes shared Product names only, never asset detail.
    my @IDs=$CI->ConfigItemSearch(Result=>'ARRAY',Classes=>['Product'],Limit=>10001,UserID=>$PanelID);
    die "Product catalog is too large; narrow catalog required" if @IDs>=10001;
    my @Products;
    for my $ID (@IDs) {my $O=$CI->ConfigItemGet(ConfigItemID=>$ID,DynamicFields=>0);push @Products,{ID=>$ID,Name=>$O->{Name}} if $O && $O->{Class} eq 'Product';}
    my %User=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$P{CustomerUserID});
    my $Default=$User{'DynamicField_ZUser-Application'}//$User{'UserDynamicField_ZUser-Application'};
    if (!$Default) {my $F=$Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(Name=>'ZUser-Application');$Default=$Kernel::OM->Get('Kernel::System::DynamicField::Backend')->ValueGet(DynamicFieldConfig=>$F,ObjectName=>$P{CustomerUserID}) if $F;}
    $Default=$Default->[0] if ref $Default eq 'ARRAY';
    $Default='' if ref $Default;
    my $GO=$Kernel::OM->Get('Kernel::System::GovernanceObject');
    for my $F (@Fields) {
        my @Choices;
        if ($F->{FieldType} eq 'Dropdown') {@Choices=map {{ID=>$_,Name=>$F->{Config}{PossibleValues}{$_}}} sort keys %{$F->{Config}{PossibleValues}||{}};}
        elsif ($F->{Name} eq 'ZTAM-Application') {
            my $O=$Default ? $GO->GovernanceObjectGet(GovernanceObjectID=>$Default,DynamicFields=>0) : undef;
            if ($O && $O->{Class} eq 'Application') {push @Choices,{ID=>$Default,Name=>'Application: '.$O->{Name}};} else {$Default='';}
        }
        elsif ($F->{Name} eq 'ZTAM-EventSeverity') {
            my @IDs=$GO->GovernanceObjectSearch(Result=>'ARRAY',Classes=>['EventSeverity'],Limit=>1001,UserID=>$PanelID);
            die "Severity catalog is too large" if @IDs>=1001;
            for my $ID (@IDs) {my $O=$GO->GovernanceObjectGet(GovernanceObjectID=>$ID,DynamicFields=>0);push @Choices,{ID=>$ID,Name=>'EventSeverity: '.$O->{Name}} if $O && $O->{ZTSMStatus} eq 'Active';}
        }
        elsif ($F->{Name} eq 'ZTAM-ContractEntitlement') {
            my @IDs=$CI->ConfigItemSearch(Result=>'ARRAY',Classes=>['ContractEntitlement'],Limit=>1001,UserID=>$PanelID);
            die "Entitlement catalog is too large" if @IDs>=1001;
            for my $ID (@IDs) {next if !$Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->ContractEntitlementAccessCheck(CustomerUserID=>$P{CustomerUserID},ContractEntitlementID=>$ID,RequireRole=>'TESSERA::CMDB::SECOPS');my $O=$CI->ConfigItemGet(ConfigItemID=>$ID,DynamicFields=>0);push @Choices,{ID=>$ID,Name=>'ContractEntitlement: '.$O->{Name}};}
        }
        $F->{Choices}=\@Choices;
        $F->{Value}=$F->{Name} eq 'ZTAM-Application' ? $Default : $F->{Config}{DefaultValue}//'';
    }
    return {Fields=>\@Fields,Products=>[sort {$a->{Name} cmp $b->{Name}} @Products],ClassID=>$Classes{SecurityAdvisory},PanelID=>$PanelID};
}
# All overview and export consumers share the same fail-closed SECOPS scope.
sub Overview {
    my ($Self,%P)=@_;
    die "Security operations access required" if !$Self->AccessCheck(%P);
    my $M=$P{Model};
    my $CI=$Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $Def=$CI->DefinitionGet(ClassID=>$M->{ClassID});
    my (@Names,%Seen);
    my $Walk; $Walk=sub {
        my ($Node)=@_;
        if (ref $Node eq 'ARRAY') {$Walk->($_) for @$Node;}
        elsif (ref $Node eq 'HASH') {
            push @Names,$Node->{DF} if $Node->{DF} && !$Seen{$Node->{DF}}++;
            $Walk->($Node->{$_}) for sort grep {$_ ne 'DF'} keys %$Node;
        }
    };
    $Walk->($Def->{DefinitionRef});
    my %Excluded=map {$_=>1} qw(ZTAM-Application ZTAM-ContractEntitlement);
    my %First=map {$_=>1} qw(ZTAM-Annex ZTAM-EventSeverity ZTAM-Source);
    @Names=(qw(ZTAM-Annex ZTAM-EventSeverity ZTAM-Source),grep {!$First{$_} && !$Excluded{$_}} @Names);
    # Keep the questionnaire after Recommendation in every table/export surface.
    my @Questions=qw(ZRM-PrivilegeRequired ZRM-AttackVector ZRM-Complexity ZRM-InteractionRequirement ZRM-Discoverability ZRM-Reproducibility ZRM-Confidentiality ZRM-Integrity ZRM-Availability ZRM-CodeExecution ZRM-PrivilegeEscalation ZRM-AdditionalDamage);
    my %Question=map {$_=>1} @Questions;
    @Names=grep {!$Question{$_}} @Names;
    my @Ordered;
    for my $Name (@Names) {push @Ordered,$Name;push @Ordered,@Questions if $Name eq 'ZTAM-Recommendation';}
    @Names=@Ordered;
    my @Columns=map {my $F=$Def->{DynamicFieldRef}{$_} || $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(Name=>$_);die "Configured advisory field $_ is unavailable" if !$F;+{%$F}} @Names;
    my $Count=$CI->ConfigItemSearch(Result=>'COUNT',Classes=>['SecurityAdvisory'],UserID=>$M->{PanelID});
    my @IDs=$Count ? $CI->ConfigItemSearch(Result=>'ARRAY',Classes=>['SecurityAdvisory'],Limit=>$Count,UserID=>$M->{PanelID}) : ();
    my @Rows;
    for my $ID (@IDs) {
        next if !$Kernel::OM->Get('Kernel::System::ITSMConfigItem::CustomerEntitlement')->ConfigItemDiscoveryCheck(CustomerUserID=>$P{CustomerUserID},ConfigItemID=>$ID,RequireRole=>'TESSERA::CMDB::SECOPS',LogNo=>1);
        my $O=$CI->ConfigItemGet(ConfigItemID=>$ID,DynamicFields=>1);
        next if !$O || $O->{Class} ne 'SecurityAdvisory';
        my @Cells=map {$Self->DisplayValue(Field=>$_,Value=>$O->{'DynamicField_'.$_->{Name}})} @Columns;
        push @Rows,{Cells=>\@Cells,Object=>$O};
    }
    my $Report=$Self->Metrics(Rows=>\@Rows,Today=>$P{Today});
    return {Columns=>\@Columns,Rows=>\@Rows,%$Report};
}
sub DisplayValue {
    my ($Self,%P)=@_;
    my $F=$P{Field};my $V=$P{Value};
    return Assemble(Field => 'AdvancedCondition', Rows => $V) if ($F->{Name} || '') eq 'AdvancedCondition';
    return join('; ',map {$Self->DisplayValue(Field=>$F,Value=>$_)} @$V) if ref $V eq 'ARRAY';
    return '' if !defined $V || ref $V;
    if ($F->{FieldType} eq 'GovernanceObject' && $V =~ /\A[0-9]+\z/) {
        my $O=$Kernel::OM->Get('Kernel::System::GovernanceObject')->GovernanceObjectGet(GovernanceObjectID=>$V,DynamicFields=>0);
        return $O ? $O->{Name} : '';
    }
    if ($F->{FieldType} eq 'Dropdown') {return $F->{Config}{PossibleValues}{$V}//$V;}
    if ($F->{FieldType} eq 'RichText') {
        return $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii(String=>$V);
    }
    return $V;
}
sub Metrics {
    my ($Self,%P)=@_;
    my @Now=gmtime();
    my $Today=$P{Today}||sprintf('%04d-%02d-%02d',$Now[5]+1900,$Now[4]+1,$Now[3]);
    my ($Y,$M,$D)=split /-/,$Today;
    my $Start=sprintf('%04d-%02d-01',$Y,$M);my $End=$Today;
    if ($D==1) {$End=$Start; $M--;if (!$M) {$M=12;$Y--;} $Start=sprintf('%04d-%02d-01',$Y,$M);}
    my $Epoch=timegm(0,0,0,(split /-/,$Today)[2],(split /-/,$Today)[1]-1,(split /-/,$Today)[0]);
    my @Next=gmtime($Epoch+7*86400);my $Next=sprintf('%04d-%02d-%02d',$Next[5]+1900,$Next[4]+1,$Next[3]);
    my %Groups=map {$_=>[]} qw(New Open Overdue DueSoon Critical High Medium);
    for my $R (@{$P{Rows}}) {
        my $O=$R->{Object};my $Created=substr($O->{CreateTime}//'',0,10);
        push @{$Groups{New}},$R if $Created ge $Start && ($D==1 ? $Created lt $End : $Created le $End);
        my $Status=$O->{'DynamicField_ZTAM-Status'}//'';
        my $Open=lc($Status) ne 'closed';push @{$Groups{Open}},$R if $Open;
        my $Due=substr($O->{'DynamicField_ZTAM-DueDate'}//'',0,10);
        if ($Open && $Due =~ /\A\d{4}-\d{2}-\d{2}\z/) {
            push @{$Groups{Overdue}},$R if $Due lt $Today;
            push @{$Groups{DueSoon}},$R if $Due ge $Today && $Due le $Next;
        }
        my $Severity=$Self->DisplayValue(Field=>{FieldType=>'GovernanceObject'},Value=>$O->{'DynamicField_ZTAM-EventSeverity'});
        $Severity =~ s/^EventSeverity:\s*//;
        for my $Key (qw(Critical High Medium)) {push @{$Groups{$Key}},$R if lc($Severity) eq lc($Key);}
    }
    return {Metrics=>[map {{Label=>$_->[0],Key=>$_->[1],Count=>scalar @{$Groups{$_->[1]}}}} ([$D==1?'New last month':'New month to date','New'],['Open advisories','Open'],['Overdue','Overdue'],['Due in 7 days','DueSoon'],['Critical','Critical'],['High','High'],['Medium','Medium'])],Groups=>\%Groups,Period=>"$Start to $End (UTC)",Total=>scalar @{$P{Rows}}};
}
sub ProductCondition {
    my ($Self,%P)=@_;my %Names=map {$_->{ID}=>$_->{Name}} @{$P{Model}{Products}};
    my %Seen;my @Names;
    for my $ID (@{$P{ProductIDs}||[]}) {die "Invalid Product selection" if !exists $Names{$ID};push @Names,$Names{$ID} if !$Seen{$ID}++;}
    die "Select at least one Product" if !@Names;
    return $Kernel::OM->Get('Kernel::System::YAML')->Dump(Data=>{VERSION=>1,SEARCH=>{FOR=>'ITSMConfigItem',CLASS=>'Product',AS=>'Products',LIMIT=>1000,WHERE=>{Name=>{EQUALS=>\@Names}}},RETURN=>{FROM=>'ALL Products',AS=>'Collection<ITSMConfigItem.Product>'}});
}
sub Create {
    my ($Self,%P)=@_;die "Security operations access required" if !$Self->AccessCheck(%P);my $Model=$P{Model}||$Self->Model(CustomerUserID=>$P{CustomerUserID});
    my $Attachments=$P{Attachments}||[];
    die "Only one attachment is allowed" if ref $Attachments ne 'ARRAY' || @$Attachments>1;
    for my $A (@$Attachments) {
        die "Invalid attachment" if ref $A ne 'HASH' || !$A->{Filename} || !defined $A->{Content};
        die "Attachment exceeds 5MB" if length($A->{Content})>5*1024*1024;
    }
    my $Row=$P{Row};die "Advisory must be an object" if ref $Row ne 'HASH';
    die "Only new SecurityAdvisory records are allowed" if ($Row->{Class}||'SecurityAdvisory') ne 'SecurityAdvisory' || $Row->{Number} || $Row->{ConfigItemID};
    die "Name is required" if ref $Row->{Name} || ($Row->{Name}//'') !~ /\S/;
    my %Allowed=map {$_->{Name}=>$_} @{$Model->{Fields}};
    for my $K (keys %$Row) {die "Unsupported advisory field $K" if !$Allowed{$K} && $K !~ /\A(?:Class|Name|Description|__ExcelDate1904)\z/;}
    my %Fields;
    for my $Name (keys %Allowed) {
        my $F=$Allowed{$Name};my $V=exists $Row->{$Name} ? $Row->{$Name} : ($F->{FieldType} eq 'Dropdown' ? $F->{Config}{DefaultValue} : '');
        if ($F->{FieldType} =~ /\A(?:ConfigItem|GovernanceObject|Dropdown)\z/) {
            my %Choice=map {($_->{ID}=>$_->{Name},$_->{Name}=>$_->{Name})} @{$F->{Choices}};
            my @Values=ref $V eq 'ARRAY'?@$V:($V);
            die "Multiple values not allowed for $Name" if !$F->{Config}{MultiValue} && @Values>1;
            my @Resolved;
            for my $Val (@Values) {next if !defined $Val || $Val eq '';die "Invalid selection for $Name" if ref $Val || !exists $Choice{$Val};push @Resolved,$F->{FieldType} eq 'Dropdown'?$Val:$Choice{$Val};}
            $V=$F->{Config}{MultiValue}?\@Resolved:($Resolved[0]//'');
        }
        die "Selection required for $Name" if $F->{FieldType} eq 'Dropdown' && !$F->{Config}{PossibleNone} && !length($V//'');
        die "Field $Name must be scalar" if ref $V && !$F->{Config}{MultiValue};
        $Fields{$Name}=$V;
    }
    my $RawCondition = $Fields{AdvancedCondition};
    if (!ref $RawCondition && defined $RawCondition && $RawCondition =~ /^\s*\[/) {
        $RawCondition = $Kernel::OM->Get('Kernel::System::JSON')->Decode(Data => $RawCondition);
    }
    my $Blocks = ref $RawCondition ? $RawCondition : SplitSource(Field => 'AdvancedCondition', Source => $RawCondition);
    my $Condition = Assemble(Field => 'AdvancedCondition', Rows => $Blocks);
    $Fields{AdvancedCondition} = $Blocks;

    if ($Condition =~ /\S/) {
        die "Condition exceeds the script limit" if length($Condition)>376200;
        # Store authoring data only; never evaluate customer-authored YAML here.
        my $Parsed=$Kernel::OM->Get('Kernel::System::TESSERA::ScriptEngine')->ScriptParse(Source=>$Condition);
        die $Parsed->{Error} if !$Parsed->{Success};
    }
    my $Catalog=$Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my %Depl=reverse %{$Catalog->ItemList(Class=>'ITSM::ConfigItem::DeploymentState')||{}};
    my %Inci=reverse %{$Catalog->ItemList(Class=>'ITSM::Core::IncidentState')||{}};
    die "Production/Operational states unavailable" if !$Depl{Production} || !$Inci{Operational};
    my $Result=$Kernel::OM->Get('Kernel::System::ITSMConfigItem::Document')->Import(Data=>{object_type=>'ITSMConfigItem',class=>'SecurityAdvisory',name=>$Row->{Name},description=>$Row->{Description}//'',deployment_state=>'Production',incident_state=>'Operational',fields=>\%Fields},UserID=>$Model->{PanelID},Source=>'Excel Import',ExcelDate1904=>$Row->{__ExcelDate1904}?1:0);
    die $Result->{Message} if !$Result->{Success};
    $Kernel::OM->Get('Kernel::System::ITSMConfigItem::Activity')->ActivityAdd(ConfigItemID=>$Result->{ConfigItemID},EventType=>'CustomerAdvisoryCreate',Source=>'Customer portal',Subject=>'Security advisory submitted',Body=>'Submitted by '.$P{CustomerUserID},Payload=>{CustomerUserID=>$P{CustomerUserID}},UserID=>$Model->{PanelID});
    my @Failed;
    for my $A (@$Attachments) {
        my $Added=eval {$Kernel::OM->Get('Kernel::System::ITSMConfigItem')->ConfigItemAttachmentAdd(%$A,ConfigItemID=>$Result->{ConfigItemID},UserID=>$Model->{PanelID})};
        push @Failed,$A->{Filename} if !$Added;
    }
    $Result->{AttachmentWarning}='Attachment upload failed: '.join(', ',@Failed) if @Failed;
    return $Result;
}
1;
