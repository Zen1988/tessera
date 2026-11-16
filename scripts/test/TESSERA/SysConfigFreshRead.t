use strict;use warnings;use Test::More;use lib '.';
require './Kernel/System/Cache.pm';
require './Kernel/System/SysConfig/DB.pm';
my $Name='Loader::Customer::CommonJS###241-TESSERASearchPaging';
{package FreshReadBackend;
 sub Get {$_[0]{Gets}++;return [{DefaultID=>1,Name=>'ExistingSetting',IsDirty=>0,ExclusiveLockGUID=>0,XMLContentRaw=>'old',XMLFilename=>'Old.xml',IsInvisible=>0}]}
 # Model a backend whose invalidation/write fails while old reads still work.
 sub Set {return}
 sub Delete {$_[0]{Deletes}++;return}
}
{package FreshReadDB;
 sub Prepare {$_[0]{Position}=0;$_[0]{Reads}++;return 1}
 sub FetchrowArray {my($S)=@_;return if $S->{Position}>=@{$S->{Rows}};return @{$S->{Rows}[$S->{Position}++]}}
}
{package FreshReadOM;
 sub Get {$_[1] eq 'Kernel::System::Cache' ? $_[0]{Cache} : $_[0]{DB}}
}
my $Backend=bless {Gets=>0,Deletes=>0},'FreshReadBackend';
my $Cache=bless {CacheInMemory=>0,CacheInBackend=>1,CacheObject=>$Backend,Cache=>{},Debug=>0},'Kernel::System::Cache';
my $DB=bless {Rows=>[[1,'ExistingSetting',0,0,'old','Old.xml',0],[2,$Name,0,0,'new','TESSERASearchDialog.xml',0]],Reads=>0},'FreshReadDB';
local $Kernel::OM=bless {Cache=>$Cache,DB=>$DB},'FreshReadOM';
my $SC=bless {CacheTTL=>60},'Kernel::System::SysConfig::DB';
my @Stale=$SC->DefaultSettingList(IncludeInvisible=>1);
ok(!grep({$_->{Name} eq $Name} @Stale),'native cached list can omit an existing new setting');
is($DB->{Reads},0,'stale backend result avoids database lookup');
is(scalar @{$DB->{Rows}},2,'database already contains the setting: bulk insert would conflict');
my $Before=$Backend->{Gets};
$Cache->Configure(CacheInBackend=>0,CacheInMemory=>0);
# Native Maint::Config::Rebuild intentionally enables only its in-memory cache.
$Cache->Configure(CacheInMemory=>1);
my @Fresh=$SC->DefaultSettingList(IncludeInvisible=>1);
ok(grep({$_->{Name} eq $Name} @Fresh),'native fresh lookup includes the already-existing setting');
is($DB->{Reads},1,'fresh rebuild reads authoritative database');
is($Backend->{Gets},$Before,'fresh rebuild never reads stale external backend');
is(scalar @Fresh,2,'all settings preserved, not deleted or renamed');
my @Again=$SC->DefaultSettingList(IncludeInvisible=>1);
is(scalar @Again,2,'native process-local cache remains coherent');
is($DB->{Reads},1,'native in-memory cache still avoids repeated DB reads');
is($Cache->{CacheInBackend},0,'native in-memory toggle does not re-enable external backend');
done_testing;
