use strict;
use warnings;
use Test::More;
use lib 'scripts/lib';
use TESSERA::ReleaseSeed;
use Storable qw(dclone);

my $Input = {
    Catalog => { classes => [
        {class => 'ITSM::ConfigItem::Class', items => [{name=>'Asset', valid=>'valid'}, {name=>'Old',valid=>'invalid'}]},
        {class => 'ITSM::ConfigItem::Role', items => [{name=>'Details',valid=>'valid'}]},
        {class => 'ITSM::ConfigItem::Class::Category', items => [{name=>'Technical',valid=>'valid'}]},
        {class => 'ZTSM::GovernanceObject::Class', items => [{name=>'Organization',valid=>'valid'}]},
    ] },
    CMDB => [
        {Class=>{Name=>'Asset', Categories=>['Technical']}, Definition=>"Roles:\n  Main:\n    Name: Details\n"},
        {Class=>{Name=>'Old'}, Definition=>'{}'},
        {RoleName=>'Details',Definition=>'{}'},
        {RoleName=>undef,Definition=>undef},
    ],
    Governance => [{Class=>{Name=>'Organization'},Definition=>'{}'}],
    Types => {Types=>{Task=>{Name=>'Task',Valid=>'valid'}, Legacy=>{Name=>'Legacy',Valid=>'invalid'}}},
};
my $R = TESSERA::ReleaseSeed->Build(%$Input);
is_deeply($R->{Errors}, [], 'complete active configuration accepted');
is_deeply($R->{Seed}{TicketTypes}, ['Task'], 'inactive ticket types excluded');
is(scalar @{$R->{Seed}{CMDB}}, 2, 'inactive class and null placeholders excluded');
is($R->{Seed}{CMDB}[0]{Definition}, $Input->{CMDB}[0]{Definition}, 'definition preserved');
is_deeply(TESSERA::ReleaseSeed->Build(%$Input), $R, 'repeat is deterministic');

my $Bad = dclone($Input);
$Bad->{Catalog}{classes}[1]{items}[0]{valid} = 'invalid';
like(join('\n', @{TESSERA::ReleaseSeed->Build(%$Bad)->{Errors}}), qr/role dependency/, 'inactive role dependency blocks release');
$Bad = dclone($Input);
delete $Bad->{Catalog}{classes}[0]{items}[0]{valid};
like(join('\n', @{TESSERA::ReleaseSeed->Build(%$Bad)->{Errors}}), qr/Unknown validity/, 'missing validity never assumes active');
$Bad = dclone($Input);
push @{$Bad->{CMDB}}, {Class=>{Name=>'Unknown'},Definition=>'{}'};
like(join('\n', @{TESSERA::ReleaseSeed->Build(%$Bad)->{Errors}}), qr/Missing validity evidence/, 'unmapped export blocks release');
$Bad = dclone($Input);
$Bad->{CMDB} = [];
ok(@{TESSERA::ReleaseSeed->Build(%$Bad)->{Pending}} > 0, 'planned active catalog entries recorded as pending');
$Bad = dclone($Input);
push @{$Bad->{Catalog}{classes}[0]{items}}, {name=>'Asset',valid=>'valid'};
eval { TESSERA::ReleaseSeed->Build(%$Bad) };
like($@, qr/Duplicate catalog/, 'duplicate names rejected');
done_testing;
