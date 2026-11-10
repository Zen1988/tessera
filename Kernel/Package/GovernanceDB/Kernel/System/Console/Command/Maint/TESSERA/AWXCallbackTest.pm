package Kernel::System::Console::Command::Maint::TESSERA::AWXCallbackTest;
use strict;
use warnings;
use parent qw(Kernel::System::Console::BaseCommand);
use JSON::PP ();
use Fcntl qw(O_WRONLY O_CREAT O_EXCL);
use Time::HiRes qw(time sleep);
our @ObjectDependencies = ('Kernel::System::TESSERA::AsyncExecution','Kernel::System::TESSERA::AWXExecution','Kernel::System::GenericInterface::Webservice');
sub Configure {
    my ($Self) = @_;
    $Self->Description('Launch a harmless AWX callback integration test or read its durable execution record.');
    for my $Name (qw(webservice-id actor-id wait-seconds timeout-seconds data-file execution-uid output-file)) {
        $Self->AddOption(Name=>$Name,Description=>$Name,Required=>0,HasValue=>1,
            ValueRegex=>$Name =~ /(?:-id|-seconds)$/ ? qr/\A[1-9][0-9]*\z/ : $Name eq 'execution-uid' ? qr/\A[A-Za-z0-9]{40}\z/ : qr/./);
    }
    return;
}
sub Run {
    my ($Self) = @_;
    my $Actor = $Self->GetOption('actor-id') || 1; # trusted OS console identity; no customer HTTP caller
    my $UID = $Self->GetOption('execution-uid');
    my $File = $Self->GetOption('data-file');
    my $WSID = $Self->GetOption('webservice-id');
    my $Wait = $Self->GetOption('wait-seconds') || ($UID ? 1 : 300);
    if (!!$UID == !!$File || $Wait > 3600 || (!$UID && !$WSID)) {
        $Self->PrintError('Use --execution-uid to read, or --webservice-id with --data-file to launch; wait at most 3600 seconds.');
        return $Self->ExitCodeError();
    }
    if (!$UID) {
        my $WS = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(ID=>$WSID);
        if (ref $WS ne 'HASH' || ($WS->{Config}{Requester}{Invoker}{JobLaunchCallback}{Type} || '') ne 'AWX::JobLaunchCallback') {
            $Self->PrintError('Configure JobLaunchCallback with type AWX::JobLaunchCallback first.'); return $Self->ExitCodeError();
        }
        my $Input = eval {
            die if !-f $File || -s $File > 1048576;
            open my $FH,'<:raw',$File or die; local $/; my $D=JSON::PP->new->utf8->decode(<$FH>); close $FH;
            die if ref $D ne 'HASH'; $D;
        };
        if (!$Input) { $Self->PrintError('Invalid non-secret JSON input file.'); return $Self->ExitCodeError() }
        my $R = $Kernel::OM->Get('Kernel::System::TESSERA::AsyncExecution')->Start(
            HandlerKey=>'AWXTest',TargetType=>'IntegrationTest',TargetID=>1,ActorID=>$Actor,Continuation=>{},Payload=>$Input,
            WebserviceID=>$WSID,Invoker=>'JobLaunchCallback',TimeoutSeconds=>$Self->GetOption('timeout-seconds') || 3600);
        if (!$R->{Success}) { $Self->PrintError($R->{Error} || 'Could not save execution.'); return $Self->ExitCodeError() }
        $UID=$R->{ExecutionUID};
        $Self->Print("ExecutionUID: $UID\nSaved and queued; the TESSERA daemon must be running.\n");
    }
    my $Deadline = time() + $Wait;
    my $Row;
    while (1) {
        $Row=$Kernel::OM->Get('Kernel::System::TESSERA::AWXExecution')->Get(ExecutionUID=>$UID,ActorID=>$Actor);
        if (!$Row) { $Self->PrintError('Execution unavailable for this actor.'); return $Self->ExitCodeError() }
        $Self->Print("$UID: $Row->{State}\n");
        last if $Row->{State} =~ /\A(?:DONE|ERROR|DISPATCH_ERROR)\z/ || time() >= $Deadline;
        sleep(2);
    }
    if (my $Output=$Self->GetOption('output-file')) {
        my $OK=eval { sysopen my $FH,$Output,O_WRONLY|O_CREAT|O_EXCL,0600 or die;
            binmode $FH; print {$FH} JSON::PP->new->utf8->canonical->encode($Row) or die; close $FH or die; 1 };
        if (!$OK) { $Self->PrintError('Could not save a new private result file.'); return $Self->ExitCodeError() }
    }
    return $Row->{State} eq 'DONE' && defined $Row->{ExitCode} && $Row->{ExitCode} == 0 ? $Self->ExitCodeOk() : $Self->ExitCodeError();
}
1;
