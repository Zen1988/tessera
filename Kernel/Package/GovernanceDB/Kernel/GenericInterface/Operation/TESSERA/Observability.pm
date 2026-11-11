package Kernel::GenericInterface::Operation::TESSERA::Observability;
use strict;
use warnings;
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;return bless \%P,$T}
sub Run {
    my ($S,%P)=@_;
    my $R=$Kernel::OM->Get('Kernel::System::Web::Request');
    my $B=$Kernel::OM->Get('Kernel::System::TESSERA::Observability');
    my $D=$P{Data};
    return _error(400,'Invalid request') if ref $D ne 'HASH';
    my $Resource=$D->{Resource}||'';
    my $Ingest=$Resource eq 'alertmanager';
    return _error(404,'Unknown endpoint') if $Resource!~/\A(?:tickets|risks|alerts|alertmanager)\z/;
    return _error(405,'Method not allowed') if ($R->RequestMethod()||'') ne ($Ingest?'POST':'GET');
    my $Grant=$Ingest?'ingest:alertmanager':'report:'.$Resource;
    my $C=$B->Authorize(Header=>$R->Header('Authorization'),Grant=>$Grant);
    return _error(403,'API identity or capability denied') if !$C;
    return _error(400,'Invalid Alertmanager v4 payload') if $Ingest && !eval {$B->Normalize($D);1};
    my $Data;my $OK=eval {
        if ($Ingest) {
            # Validate the complete batch before acquiring locks or writing evidence.
            $B->Normalize($D);
            $Data=$B->Ingest(Client=>$C,Data=>$D);
        }
        else {my %Query=%$D;delete $Query{RequestMethod};$Data=$B->Report(Client=>$C,Data=>\%Query)}
        1;
    };
    return _error(503,'Request could not be completed; check API scope, payload and provider configuration') if !$OK;
    return {Success=>1,Data=>{HTTPStatus=>200,Body=>$Data}};
}
sub _error {return {Success=>1,Data=>{HTTPStatus=>$_[0],Body=>{Error=>$_[1]}}}}
1;
