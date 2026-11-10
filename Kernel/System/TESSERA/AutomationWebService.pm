package Kernel::System::TESSERA::AutomationWebService;
use strict;
use warnings;
our @ObjectDependencies = ('Kernel::System::GenericInterface::Webservice','Kernel::GenericInterface::Requester','Kernel::System::TESSERA::AsyncExecution','Kernel::System::TESSERA::AWXInventory');
# Trusted backend callers inject exact service/invoker bindings after their
# independent publication/actor/target authorization. Stored YAML cannot create
# this provider or choose network destinations/authentication.
sub new { my ($Type,%P)=@_; return bless {AllowedCalls=>$P{AllowedCalls} || {},ExecutionContext=>$P{ExecutionContext},NetworkContext=>$P{NetworkContext},NavisContext=>$P{NavisContext}},$Type }
sub Call {
    my ($Self,%P)=@_;
    my $ID=$Self->{AllowedCalls}{$P{Service}}{$P{Invoker}};
    return {Success=>0} if !defined $ID || ref $ID || $ID !~ /\A[1-9][0-9]*\z/;
    my $WS=$Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(ID=>$ID);
    return {Success=>0} if ref $WS ne 'HASH' || ($WS->{ValidID} || 0)!=1;
    if ($P{Invoker}=~/\ANavis(?:Analyze|Recommendations|Get|Execute)\z/) {
        my $C=$Self->{NavisContext};
        return {Success=>0} if ref $C ne 'HASH' || ($C->{ActorID} || 0)!=$P{UserID} || ($C->{NavisWebserviceID} || 0)!=$ID;
        require Kernel::System::TESSERA::NavisControl;
        my $Engine=Kernel::System::TESSERA::NavisControl->new();
        my %Method=(NavisAnalyze=>'Analyze',NavisRecommendations=>'Recommendations',NavisGet=>'Get',NavisExecute=>'Execute');
        return {Success=>0} if ref $P{Data} ne 'HASH';
        return $Engine->Analyze(Context=>$C,ActorID=>$P{UserID},Data=>$P{Data}) if $P{Invoker} eq 'NavisAnalyze';
        return {Success=>0} if grep {$_ ne 'AnalysisID'} keys %{$P{Data}};
        my $Method=$Method{$P{Invoker}};
        return $Engine->$Method(Context=>$C,ActorID=>$P{UserID},AnalysisID=>$P{Data}{AnalysisID});
    }
    if ($P{Invoker} eq 'NetworkResult') {
        return {Success=>0} if ref $P{Data} ne 'HASH' || grep {$_ ne 'ExecutionUID'} keys %{$P{Data}};
        require Kernel::System::TESSERA::NetworkIntelligence;
        my $D=Kernel::System::TESSERA::NetworkIntelligence->new()->Get(ExecutionUID=>$P{Data}{ExecutionUID},ActorID=>$P{UserID});
        return {Success=>$D ? 1:0,Data=>$D || {}};
    }
    if ($P{Invoker} eq 'NetworkDiscover' || $P{Invoker} eq 'NetworkAssess') {
        my $C=$Self->{NetworkContext};
        return {Success=>0} if ref $C ne 'HASH' || ($C->{ActorID} || 0)!=$P{UserID}
            || ($C->{NetXMSWebserviceID} || 0)!=$ID;
        require Kernel::System::TESSERA::NetworkIntelligence;
        my $Engine=Kernel::System::TESSERA::NetworkIntelligence->new();
        my $Method=$P{Invoker} eq 'NetworkDiscover' ? 'Discover' : 'Start';
        my $R=$Engine->$Method(Context=>$C,Data=>$P{Data},ActorID=>$P{UserID});
        return {Success=>$R->{Success},Data=>$R->{Data} || {ExecutionUID=>$R->{ExecutionUID},Status=>$R->{Status}}};
    }
    if ($P{Invoker} eq 'InventorySync') {
        my $R=$Kernel::OM->Get('Kernel::System::TESSERA::AWXInventory')->Sync(%{$P{Data}},WebserviceID=>$ID);
        return {Success=>$R->{Success},Data=>$R};
    }
    my $Type=$WS->{Config}{Requester}{Invoker}{$P{Invoker}}{Type} || '';
    if ($Type eq 'AWX::JobLaunchCallback') {
        my $Binding=$Self->{ExecutionContext};
        return {Success=>0} if ref $Binding ne 'HASH' || ($Binding->{ActorID} || 0)!=$P{UserID};
        my $R=$Kernel::OM->Get('Kernel::System::TESSERA::AsyncExecution')->Start(
            %{$Binding},Continuation=>$Binding->{Continuation} || {},
            Payload=>$P{Data},WebserviceID=>$ID,Invoker=>$P{Invoker});
        return {Success=>$R->{Success},Data=>{ExecutionUID=>$R->{ExecutionUID},Status=>$R->{Status}}};
    }
    return $Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(WebserviceID=>$ID,Invoker=>$P{Invoker},Data=>$P{Data});
}
1;
