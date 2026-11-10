package Kernel::System::TESSERA::AWXExecution;
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
our @ObjectDependencies = ('Kernel::System::DB', 'Kernel::System::JSON', 'Kernel::System::TESSERA::AsyncExecution', 'Kernel::GenericInterface::Requester', 'Kernel::System::Time');
sub new { return bless {}, $_[0] }
sub RecordTestCompletion { return 1 } # the saved execution row is the test evidence
sub Get {
    my ($Self, %P) = @_;
    return if ($P{ExecutionUID} || '') !~ /\A[A-Za-z0-9]{40}\z/ || ($P{ActorID} || '') !~ /\A[1-9][0-9]*\z/;
    my $Row = $Kernel::OM->Get('Kernel::System::TESSERA::AsyncExecution')->_Get($P{ExecutionUID});
    return if !$Row || $Row->{ActorID} != $P{ActorID};
    delete @{$Row}{qw(TokenHash Continuation)};
    return $Row;
}
sub Dispatch {
    my ($Self, %P) = @_;
    return 1 if ($P{ExecutionUID} || '') !~ /\A[A-Za-z0-9]{40}\z/ || ($P{CallbackToken} || '') !~ /\A[A-Za-z0-9]{64}\z/;
    my $DB = $Kernel::OM->Get('Kernel::System::DB');
    my $Hash = sha256_hex($P{CallbackToken});
    # Persist intent before the network call. A repeated/crashed worker never
    # sends a second launch. A callback may still resolve an uncertain launch.
    my $Handle = $DB->Connect();
    return if !$Handle;
    my $Now=$Kernel::OM->Get('Kernel::System::Time')->SystemTime2TimeStamp(SystemTime=>time);
    my $Rows = $Handle->do("UPDATE ztsm_async_execution SET state = 'DISPATCHING', change_time = ? WHERE execution_uid = ? AND token_hash = ? AND state = 'PENDING' AND deadline_time >= ?", undef, $Now, $P{ExecutionUID}, $Hash, $Now);
    return if !defined $Rows;
    return 1 if $Rows != 1;
    my $Result = eval { $Kernel::OM->Get('Kernel::GenericInterface::Requester')->Run(
        WebserviceID=>$P{WebserviceID},Invoker=>$P{Invoker},Data=>{%{$P{Payload}},ExecutionUID=>$P{ExecutionUID},CallbackToken=>$P{CallbackToken}}) };
    # JSON includes any JSON-string extra_vars. Redact the known token before
    # saving, irrespective of nesting or AWX response representation.
    my $JSON = $Kernel::OM->Get('Kernel::System::JSON');
    my $Saved = $JSON->Encode(Data=>$Result || {Success=>0,Outcome=>'UNKNOWN'},SortKeys=>1);
    return if !defined $Saved || length($Saved)>1048576;
    $Saved =~ s/\Q$P{CallbackToken}\E/[REDACTED]/g;
    my $State = $Result && $Result->{Success} && $Result->{Data}{InputAccepted} ? 'WAITING' : 'DISPATCH_UNKNOWN';
    $DB->Do(SQL=>"UPDATE ztsm_async_execution SET dispatch_data = ?, change_time = current_timestamp WHERE execution_uid = ?", Bind=>[\$Saved,\$P{ExecutionUID}]) or return;
    $DB->Do(SQL=>"UPDATE ztsm_async_execution SET state = ?, change_time = current_timestamp WHERE execution_uid = ? AND state = 'DISPATCHING'",Bind=>[\$State,\$P{ExecutionUID}]) or return;
    return 1;
}
1;
