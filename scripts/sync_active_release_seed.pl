use strict;
use warnings;
use JSON::PP ();
use YAML::XS ();
my ($Manifest, $Directory) = @ARGV;
die "Usage: $0 VALIDATED_MANIFEST.json SEED_DIRECTORY\n" if @ARGV != 2;
sub ReadJSON {
    open my $F, '<:raw', $_[0] or die "$!: $_[0]";
    local $/; my $D = JSON::PP::decode_json(<$F>); close $F; return $D;
}
sub WriteFile {
    open my $F, '>:raw', $_[0] or die "$!: $_[0]";
    print {$F} $_[1]; close $F or die $!;
}
my $Seed = ReadJSON($Manifest);
die "Not a validated release manifest\n" if $Seed->{FormatVersion} != 1 || !$Seed->{Sources};
my $Defaults = ReadJSON("$Directory/default_classes.json");
my (@Classes, @Roles);
for my $Item (@{$Seed->{Governance}}) {
    if ($Item->{Class}) {
        push @Classes, {%{$Item->{Class}}, Definition=>$Item->{Definition}, DynamicFields=>$Item->{DynamicFields} || {}};
    }
    else { push @Roles, {Name=>$Item->{RoleName}, Definition=>$Item->{Definition}}; }
}
$Defaults->{Classes}=\@Classes;
$Defaults->{Roles}=\@Roles;
my ($Categories) = grep {$_->{class} eq 'ZTSM::GovernanceObject::Class::Category'} @{$Seed->{GeneralCatalog}};
$Defaults->{Categories} = [map {$_->{name}} @{$Categories->{items} || []}];
my $JSON=JSON::PP->new->canonical->pretty->utf8;
WriteFile("$Directory/default_classes.json",$JSON->encode($Defaults));
WriteFile("$Directory/default_configitem.json",$JSON->encode($Seed->{CMDB}));
# Class and role catalog preferences include source-local permission IDs. Their
# backend importers resolve exported group names and create their own catalog rows.
my @Catalog = grep {$_->{class} !~ /\A(?:ITSM::ConfigItem|ZTSM::GovernanceObject)::(?:Class|Role)\z/} @{$Seed->{GeneralCatalog}};
for my $Group (@Catalog) {
    for my $Item (@{$Group->{items}}) {
        # Never copy source-local access group IDs into a different installation.
        delete $Item->{preferences}{Permission};
        delete $Item->{preferences}{ConfigItemGroup};
    }
}
WriteFile("$Directory/default_general_catalog.yml", YAML::XS::Dump({classes=>\@Catalog}));
WriteFile("$Directory/active_ticket_types.json",$JSON->encode({TicketTypes=>$Seed->{TicketTypes},Sources=>$Seed->{Sources}{Types}}));
print 'Synchronized ',scalar(@Classes),' governance classes, ',scalar(@Roles),' roles and ',scalar(@{$Seed->{CMDB}})," CMDB definitions.\n";
