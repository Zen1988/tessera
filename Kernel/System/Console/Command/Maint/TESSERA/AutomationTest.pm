package Kernel::System::Console::Command::Maint::TESSERA::AutomationTest;
use strict;
use warnings;
use parent qw(Kernel::System::Console::BaseCommand);
use JSON::PP ();
use Kernel::System::TESSERA::ScriptEngine;
use Kernel::System::TESSERA::AutomationWebService;
our @ObjectDependencies=();
sub Configure {
    my ($Self)=@_;
    $Self->Description('Execute an explicitly allowed configured Web Service test script from the trusted OS console.');
    for my $Name (qw(script-file bindings-file actor-id)) {
        $Self->AddOption(Name=>$Name,Description=>$Name,Required=>$Name eq 'actor-id'?0:1,HasValue=>1,ValueRegex=>$Name eq 'actor-id'?qr/\A[1-9][0-9]*\z/:qr/./);
    }
    $Self->AddOption(Name=>'network-context-file',Description=>'Trusted backend CMDB/domain mapping JSON for network discovery or assessment.',Required=>0,HasValue=>1,ValueRegex=>qr/./);
    return;
}
sub Run {
    my ($Self)=@_;
    my $Actor=$Self->GetOption('actor-id') || 1;
    my $Loaded=eval {
        my @Values;
        for my $Name (qw(script-file bindings-file)) {
            my $File=$Self->GetOption($Name); die if !-f $File || -s $File>376200;
            open my $FH,'<:raw',$File or die; local $/; push @Values,<$FH>; close $FH;
        }
        [ $Values[0], JSON::PP->new->utf8->decode($Values[1]) ];
    };
    if (!$Loaded || ref $Loaded->[1] ne 'HASH') { $Self->PrintError('Invalid bounded script or binding file.');return $Self->ExitCodeError() }
    my $NetworkContext;
    if (my $File=$Self->GetOption('network-context-file')) {
        $NetworkContext=eval {
            die if !-f $File || -s $File>376200;
            open my $FH,'<:raw',$File or die;local $/;
            my $C=JSON::PP->new->utf8->decode(<$FH>);close $FH;
            die if ref $C ne 'HASH' || ($C->{ActorID} || 0)!=$Actor;$C;
        };
        if (!$NetworkContext) {$Self->PrintError('Invalid network context or actor mismatch.');return $Self->ExitCodeError()}
    }
    my $Provider=Kernel::System::TESSERA::AutomationWebService->new(AllowedCalls=>$Loaded->[1],NetworkContext=>$NetworkContext,ExecutionContext=>{
        HandlerKey=>'AWXTest',TargetType=>'IntegrationTest',TargetID=>1,ActorID=>$Actor});
    my $Engine=Kernel::System::TESSERA::ScriptEngine->new(WebServiceProvider=>sub {$Provider->Call(@_)});
    my $Result=$Engine->ScriptEvaluate(Source=>$Loaded->[0],UserID=>$Actor);
    if (!$Result->{Success}) { $Self->PrintError('Script failed. Inspect saved execution history before rerunning any launch.'); return $Self->ExitCodeError() }
    # Return the explicit scalar chosen by the script; examples return only UID.
    $Self->Print(JSON::PP->new->canonical->encode({Status=>$Result->{Status},Value=>$Result->{Value}})."\n");
    return $Self->ExitCodeOk();
}
1;
