package Kernel::GenericInterface::Operation::TESSERA::ExecutionCallback;
use strict;
use warnings;
use parent qw(Kernel::GenericInterface::Operation::TESSERA::Common);
our @ObjectDependencies=('Kernel::System::TESSERA::AsyncExecution','Kernel::System::Web::Request');
sub Run {
    my ($Self,%P)=@_;
    my $D=$P{Data}||{};
    return $Self->Error(Code=>'TESSERA.InvalidCallback',Message=>'Callback body must be an object.') if ref $D ne 'HASH';
    my $Header=$Kernel::OM->Get('Kernel::System::Web::Request')->Header('Authorization')||'';
    return $Self->Error(Code=>'TESSERA.AuthFail',Message=>'Invalid callback authorization.')
        if $Header !~ /\ABearer ([A-Za-z0-9]{64})\z/;
    my $Token=$1;
    my $Result=$Kernel::OM->Get('Kernel::System::TESSERA::AsyncExecution')->Callback(
        ExecutionUID=>$D->{ExecutionUID},CallbackToken=>$Token,ExitCode=>$D->{ExitCode},Response=>$D->{Response});
    return $Self->Error(Code=>'TESSERA.CallbackRejected',Message=>$Result->{Error}) if !$Result->{Success};
    return {Success=>1,Data=>{ExecutionUID=>$D->{ExecutionUID},Status=>$Result->{Status},Duplicate=>$Result->{Duplicate}?1:0}};
}
1;
