use strict;
use warnings;
use Test::More;
use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::GenericInterface::Operation::TESSERA::Observability;
{
 package ORRequest;sub RequestMethod {return $main::method}sub Header {return 'Bearer mock'}
 package ORBackend;
 sub Authorize {return $main::authorized ? {Identity=>{CustomerUserID=>'x'}} : undef}
 sub Normalize {die 'invalid' if $main::invalid;return []}
 sub Ingest {$main::ingests++;return {Changed=>1}}
 sub Report {my ($s,%p)=@_;die 'RequestMethod leaked' if exists $p{Data}{RequestMethod};return {Rows=>[]}}
 package OROM;sub Get {return bless {},$_[1] eq 'Kernel::System::Web::Request'?'ORRequest':'ORBackend'}
 package Kernel;our $OM=bless {},'OROM';
}
our ($method,$authorized,$invalid,$ingests)=('GET',1,0,0);
my $s=Kernel::GenericInterface::Operation::TESSERA::Observability->new();
my $r=$s->Run(Data=>{Resource=>'tickets',RequestMethod=>'GET'});is($r->{Data}{HTTPStatus},200,'native REST GET metadata handled');
$authorized=0;$r=$s->Run(Data=>{Resource=>'tickets'});is($r->{Data}{HTTPStatus},403,'unauthorized reporting denied');$authorized=1;
$r=$s->Run(Data=>{Resource=>'alertmanager'});is($r->{Data}{HTTPStatus},405,'GET cannot ingest');is($ingests,0,'wrong method caused no writes');
$method='POST';$r=$s->Run(Data=>{Resource=>'tickets'});is($r->{Data}{HTTPStatus},405,'POST cannot use reporting route');
$invalid=1;$r=$s->Run(Data=>{Resource=>'alertmanager'});is($r->{Data}{HTTPStatus},400,'invalid webhook rejected before ingestion');is($ingests,0,'invalid webhook caused no writes');$invalid=0;
$r=$s->Run(Data=>{Resource=>'alertmanager'});is($r->{Data}{HTTPStatus},200,'valid notification acknowledged');is($ingests,1,'accepted notification dispatched once');
$r=$s->Run(Data=>{Resource=>'arbitrary-code'});is($r->{Data}{HTTPStatus},404,'arbitrary resource rejected');
done_testing;
