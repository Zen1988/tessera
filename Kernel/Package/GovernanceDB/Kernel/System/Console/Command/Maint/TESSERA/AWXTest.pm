package Kernel::System::Console::Command::Maint::TESSERA::AWXTest;
use strict;
use warnings;
use Time::HiRes qw(sleep time);
use JSON::PP ();
use File::Path qw(make_path);
use File::Spec ();
use Kernel::GenericInterface::Invoker::AWX::Base;
use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = ('Kernel::GenericInterface::Requester', 'Kernel::System::GenericInterface::Webservice');

sub Configure {
    my ($Self) = @_;
    $Self->Description('Launch one AWX integration test and poll its final result. Never automatically relaunch.');
    for my $Name (qw(webservice-id data-file wait-seconds job-id)) {
        $Self->AddOption(Name => $Name, Description => $Name eq 'data-file' ? 'JSON launch payload file; non-secret inputs only.' : $Name,
            Required => $Name eq 'webservice-id' ? 1 : 0, HasValue => 1,
            ValueRegex => $Name eq 'data-file' ? qr/./ : qr/\A[1-9][0-9]*\z/);
    }
    $Self->AddOption(Name => 'workflow', Description => 'Use a workflow template/job.', Required => 0, HasValue => 0);
    $Self->AddOption(Name => 'output-directory', Description => 'New private directory for full JSON responses; may contain sensitive job output.', Required => 0, HasValue => 1, ValueRegex => qr/./);
    return;
}

sub Run {
    my ($Self) = @_;
    my $WSID = $Self->GetOption('webservice-id');
    my $JobID = $Self->GetOption('job-id');
    my $File = $Self->GetOption('data-file');
    my $Wait = $Self->GetOption('wait-seconds') || 300;
    my $Directory = $Self->GetOption('output-directory');
    if ($Directory) {
        if (-e $Directory || !eval { make_path($Directory, {mode => 0700}); -d $Directory }) {
            $Self->PrintError('Output directory must be new and writable.'); return $Self->ExitCodeError();
        }
        $Self->{AWXOutputDirectory} = $Directory;
    }
    if ($Wait > 3600 || (!!$JobID == !!$File)) {
        $Self->PrintError('Supply either --data-file to launch once or --job-id to resume polling; wait must be at most 3600 seconds.');
        return $Self->ExitCodeError();
    }
    my $LaunchName = $Self->GetOption('workflow') ? 'WorkflowLaunch' : 'JobLaunch';
    my $GetName = $Self->GetOption('workflow') ? 'WorkflowGet' : 'JobGet';
    my $WS = $Kernel::OM->Get('Kernel::System::GenericInterface::Webservice')->WebserviceGet(ID => $WSID);
    for my $Name ($LaunchName, $GetName, $Self->GetOption('workflow') ? 'WorkflowNodes' : qw(JobStdout JobEvents)) {
        if (ref $WS ne 'HASH' || ($WS->{ValidID} || 0) != 1 || ($WS->{Config}{Requester}{Invoker}{$Name}{Type} || '') ne "AWX::$Name") {
            $Self->PrintError('Configure the documented AWX invoker names and types first.');
            return $Self->ExitCodeError();
        }
    }
    my $Requester = $Kernel::OM->Get('Kernel::GenericInterface::Requester');
    if ($File) {
        my $Data = eval {
            die if !-f $File || -s $File > 1048576;
            open my $FH, '<:raw', $File or die;
            local $/; my $Text = <$FH>; close $FH;
            my $Value = JSON::PP->new->utf8->decode($Text);
            die if ref $Value ne 'HASH';
            $Value;
        };
        if (!$Data) { $Self->PrintError('Could not read a JSON launch object of at most 1 MiB.'); return $Self->ExitCodeError() }
        # Exactly one launch call. A timeout or input-rejection response is not retried.
        my $Launch = $Requester->Run(WebserviceID => $WSID, Invoker => $LaunchName, Data => $Data);
        if (!$Launch->{Success}) {
            my $Known = $Launch->{Data}{JobID};
            $Self->PrintError('Launch not confirmed. Inspect AWX before retrying.' . (defined $Known ? " Existing JobID: $Known" : ''));
            return $Self->ExitCodeError();
        }
        $JobID = $Launch->{Data}{JobID};
        if (!Kernel::GenericInterface::Invoker::AWX::Base::_ID($JobID)) {
            $Self->PrintError('Launch returned no valid JobID. Inspect AWX before retrying.'); return $Self->ExitCodeError();
        }
        $Self->Print("AWX accepted JobID: $JobID\n");
        return $Self->ExitCodeError() if !$Self->_Save('launch', $Launch->{Data});
        if (!$Launch->{Data}{InputAccepted}) {
            $Self->PrintError("AWX ignored launch inputs for existing JobID $JobID. Inspect that job; do not relaunch.");
            return $Self->ExitCodeError();
        }
    }
    my $Deadline = time() + $Wait;
    while (time() < $Deadline) {
        my $Result = $Requester->Run(WebserviceID => $WSID, Invoker => $GetName, Data => {JobID => $JobID});
        if (!$Result->{Success}) { $Self->PrintError("Status request failed for JobID $JobID; resume with --job-id."); return $Self->ExitCodeError() }
        my $D = $Result->{Data};
        $Self->Print("JobID $JobID: $D->{Status}\n");
        if ($D->{Terminal}) {
            return $Self->ExitCodeError() if !$Self->_Save('job', $D)
                || !$Self->_Output($Requester, $WSID, $JobID, $Self->GetOption('workflow'));
            # Do not print arbitrary artifact content or payload variables.
            return $D->{ExecutionSuccess} ? $Self->ExitCodeOk() : $Self->ExitCodeError();
        }
        sleep(5);
    }
    $Self->PrintError("Wait expired for JobID $JobID. Execution may continue; resume polling with --job-id. No cancellation or relaunch performed.");
    return $Self->ExitCodeError();
}

sub _Save {
    my ($Self, $Name, $Value) = @_;
    return 1 if !$Self->{AWXOutputDirectory};
    my $OK = eval {
        my $Path = File::Spec->catfile($Self->{AWXOutputDirectory}, "$Name.json");
        open my $FH, '>:raw', $Path or die;
        chmod 0600, $Path or die;
        print {$FH} JSON::PP->new->utf8->canonical->encode($Value) or die;
        close $FH or die;
        1;
    };
    $Self->PrintError('Could not save AWX output.') if !$OK;
    return $OK;
}

sub _Output {
    my ($Self, $Requester, $WSID, $JobID, $Workflow) = @_;
    my $Name = $Workflow ? 'WorkflowNodes' : 'JobEvents';
    for my $Page (1..1000) {
        my $R = $Requester->Run(WebserviceID => $WSID, Invoker => $Name, Data => {JobID => $JobID, page => $Page, page_size => 100});
        if (!$R->{Success} || !$Self->_Save("$Name-$Page", $R->{Data})) {
            $Self->PrintError('AWX output collection failed; output is incomplete.'); return 0;
        }
        last if !$R->{Data}{Response}{next};
        if ($Page == 1000) { $Self->PrintError('AWX output exceeded 1000 pages; output is incomplete.'); return 0 }
    }
    return 1 if $Workflow;
    my $Start = 0;
    for my $Page (1..1000) {
        my $R = $Requester->Run(WebserviceID => $WSID, Invoker => 'JobStdout', Data => {JobID => $JobID, start_line => $Start, end_line => $Start + 200});
        if (!$R->{Success} || !$Self->_Save("stdout-$Page", $R->{Data})) {
            $Self->PrintError('AWX stdout collection failed; output is incomplete.'); return 0;
        }
        my $Range = $R->{Data}{Response}{range};
        return 1 if $Range->{end} >= $Range->{absolute_end};
        if ($Range->{end} <= $Start) { $Self->PrintError('AWX stdout did not advance; output is incomplete.'); return 0 }
        $Start = $Range->{end};
    }
    $Self->PrintError('AWX stdout exceeded 1000 pages; output is incomplete.');
    return 0;
}
1;
