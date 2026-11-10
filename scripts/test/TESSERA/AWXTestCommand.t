use strict;
use warnings;
use Test::More;
use JSON::PP ();
use File::Temp qw(tempdir);
use lib '.';
use Kernel::System::Console::Command::Maint::TESSERA::AWXTest;

{ package TestCommand;
  use parent qw(Kernel::System::Console::Command::Maint::TESSERA::AWXTest);
  sub GetOption { return $_[0]{Options}{$_[1]} }
  sub Print { $_[0]{Printed} .= $_[1] }
  sub PrintError { $_[0]{Errors} .= $_[1] }
  sub ExitCodeOk { return 0 }
  sub ExitCodeError { return 1 }
  package TestRequester;
  sub Get { return $_[0] }
  sub WebserviceGet { return $_[0]{WS} }
  sub Run {
      my ($Self, %P) = @_;
      push @{$Self->{Calls}}, \%P;
      die 'Unexpected extra request' if !@{$Self->{Responses}};
      return shift @{$Self->{Responses}};
  }
}
open my $FH, '<', 'var/webservices/examples/TESSERAAWX.yml' or die $!;
my $Config = JSON::PP->new->decode(do {local $/; <$FH>}); close $FH;
my $Dir = tempdir('awx-test-XXXXXXXX', DIR => '.', CLEANUP => 1);
open $FH, '>', "$Dir/launch.json" or die $!; print {$FH} '{"TemplateID":42,"inventory":7,"extra_vars":{"hello":"world"}}'; close $FH;
sub Harness {
    my ($Options, @Responses) = @_;
    my $OM = bless {WS => {ValidID => 1, Config => $Config}, Responses => \@Responses, Calls => []}, 'TestRequester';
    my $Command = bless {Options => {'webservice-id' => 1, %{$Options}}}, 'TestCommand';
    local $Kernel::OM = $OM;
    my $Code = $Command->Run();
    return ($Code, $OM, $Command);
}
my $Accepted = {Success => 1, Data => {JobID => 8, InputAccepted => 1}};
my $Done = {Success => 1, Data => {JobID => 8, Status => 'successful', Terminal => 1, ExecutionSuccess => 1}};
my $Events = sub {return {Success => 1, Data => {Response => {count => 2, results => [{event => 'verbose_event'}], next => $_[0]}}}};
my $Stdout = sub {return {Success => 1, Data => {Response => {content => 'complete stdout', range => {start => $_[0], end => $_[1], absolute_end => 300}}}}};
my ($Code, $OM, $Command) = Harness({'data-file' => "$Dir/launch.json", 'output-directory' => "$Dir/output"},
    $Accepted, $Done, $Events->('https://never-follow/'), $Events->(undef), $Stdout->(0,200), $Stdout->(200,300));
is($Code, 0, 'successful live-command simulation');
is_deeply([map {$_->{Invoker}} @{$OM->{Calls}}], [qw(JobLaunch JobGet JobEvents JobEvents JobStdout JobStdout)], 'launch once then collect complete events and stdout');
is($OM->{Calls}[3]{Data}{page}, 2, 'pagination increments page instead of following remote URL');
is($OM->{Calls}[5]{Data}{start_line}, 200, 'stdout uses returned line cursor');
is_deeply($OM->{Calls}[0]{Data}{extra_vars}, {hello => 'world'}, 'script data passed intact');
ok(-f "$Dir/output/launch.json" && -f "$Dir/output/job.json" && -f "$Dir/output/JobEvents-2.json" && -f "$Dir/output/stdout-2.json", 'all output pages saved');
($Code, $OM) = Harness({'data-file' => "$Dir/launch.json"}, {Success => 0, ErrorMessage => 'timeout'});
is($Code, 1, 'uncertain launch fails');
is(scalar @{$OM->{Calls}}, 1, 'uncertain launch never retried');
($Code, $OM) = Harness({'data-file' => "$Dir/launch.json"}, {Success => 1, Data => {JobID => 8, InputAccepted => 0}});
is($Code, 1, 'ignored inputs fail acceptance');
is(scalar @{$OM->{Calls}}, 1, 'ignored inputs never relaunched');
($Code, $OM) = Harness({'job-id' => 8, workflow => 1}, $Done, $Events->(undef));
is($Code, 0, 'workflow status and nodes accepted');
is_deeply([map {$_->{Invoker}} @{$OM->{Calls}}], [qw(WorkflowGet WorkflowNodes)], 'resume workflow without launch');
($Code, $OM) = Harness({'job-id' => 8}, {Success => 1, Data => {JobID => 8, Status => 'failed', Terminal => 1, ExecutionSuccess => 0}}, $Events->(undef), $Stdout->(0,300));
is($Code, 1, 'failed execution fails acceptance after collecting output');
is(scalar @{$OM->{Calls}}, 3, 'failed execution output still collected');
($Code, $OM) = Harness({'job-id' => 8}, $Done, {Success => 0});
is($Code, 1, 'incomplete output fails acceptance');
($Code, $OM) = Harness({'data-file' => "$Dir/launch.json", 'job-id' => 8});
is($Code, 1, 'ambiguous launch/resume rejected');
is(scalar @{$OM->{Calls}}, 0, 'no request for ambiguous launch/resume');
done_testing();
