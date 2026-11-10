use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use lib '.';
use Kernel::System::TESSERA::ReleaseUpgrade;
BEGIN {eval {require DBI;require DBD::SQLite;1} or plan skip_all=>'SQLite DBI fixture unavailable'}
{package ReleaseSQL;
 our @ISA=('Kernel::System::TESSERA::ReleaseUpgrade');
 sub _DB {$_[0]{DB}}
 package SQLAdapter;sub Connect {$_[0]{Handle}}
}
my($FH,$File)=tempfile('release-cas-XXXXXXXX',DIR=>'.',UNLINK=>1);close $FH;
my $A=DBI->connect("dbi:SQLite:dbname=$File",'','',{RaiseError=>0,PrintError=>0,AutoCommit=>1});
my $B=DBI->connect("dbi:SQLite:dbname=$File",'','',{RaiseError=>0,PrintError=>0,AutoCommit=>1});
$A->do('CREATE TABLE system_data (data_key VARCHAR(160) PRIMARY KEY, data_value BLOB, create_time TEXT,create_by INTEGER,change_time TEXT,change_by INTEGER)');
my $One=bless {DB=>bless({Handle=>$A},'SQLAdapter')},'ReleaseSQL';
my $Two=bless {DB=>bless({Handle=>$B},'SQLAdapter')},'ReleaseSQL';
is($One->_Write(undef,'first'),'first','first connection acquires unique durable key');
ok(!eval {$Two->_Write(undef,'second');1},'second connection cannot insert another owner');
is($One->_Write('first','upgrading'),'upgrading','CAS winner advances state');
ok(!eval {$Two->_Write('first','stale');1},'stale CAS gets zero affected rows and fails');
is($B->selectrow_array('SELECT data_value FROM system_data'),'upgrading','failed CAS does not change winner');
$A->disconnect;
is($B->selectrow_array('SELECT data_value FROM system_data'),'upgrading','durable claim survives owner disconnection');
$B->disconnect;
done_testing();
