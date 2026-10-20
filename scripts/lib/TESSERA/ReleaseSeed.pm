package TESSERA::ReleaseSeed;
use strict;
use warnings;
use YAML::XS ();

# Build configuration only. Object instances and numeric source IDs are not seeds.
sub Build {
    my ( $Class, %P ) = @_;
    my (@Errors, @Excluded, @Pending);
    my %Catalog;
    my @Catalogs;
    for my $Group ( @{ $P{Catalog}{classes} || [] } ) {
        my $Namespace = $Group->{class};
        die "Catalog namespace missing\n" if !defined $Namespace || $Namespace eq '';
        my @Active;
        for my $Item ( @{ $Group->{items} || [] } ) {
            my $Name = $Item->{name};
            die "Catalog item name missing in $Namespace\n" if !defined $Name || $Name eq '';
            die "Duplicate catalog item $Namespace/$Name\n" if exists $Catalog{$Namespace}{$Name};
            $Catalog{$Namespace}{$Name} = $Item;
            if ( !defined $Item->{valid} || $Item->{valid} !~ /\A(?:valid|invalid|invalid-temporarily)\z/ ) {
                push @Errors, "Unknown validity: $Namespace/$Name";
            }
            elsif ( $Item->{valid} eq 'valid' ) {
                push @Active, $Item;
            }
            else { push @Excluded, "$Namespace/$Name"; }
        }
        push @Catalogs, { class => $Namespace, items => \@Active } if @Active;
    }
    my %Definitions;
    for my $Kind (qw(CMDB Governance)) {
        my $Prefix = $Kind eq 'CMDB' ? 'ITSM::ConfigItem' : 'ZTSM::GovernanceObject';
        my %Seen;
        my %RequiredRoles;
        my @Selected;
        for my $Item ( @{ $P{$Kind} || [] } ) {
            if (!defined $Item->{RoleName} && !defined $Item->{Definition} && !exists $Item->{Class}) {
                push @Excluded, "$Kind/empty export placeholder";
                next;
            }
            my $Type = ref $Item->{Class} eq 'HASH' ? 'Class' : 'Role';
            my $Name = $Type eq 'Class' ? $Item->{Class}{Name} : $Item->{RoleName};
            if ( !defined $Name || $Name eq '' ) { push @Errors, "Unrecognized $Kind definition"; next; }
            die "Duplicate $Kind $Type $Name\n" if $Seen{"$Type/$Name"}++;
            my $Entry = $Catalog{"${Prefix}::$Type"}{$Name};
            if (!$Entry) { push @Errors, "Missing validity evidence: $Kind $Type $Name"; next; }
            next if ($Entry->{valid} || '') ne 'valid';
            if (!defined $Item->{Definition}) { push @Errors, "Missing definition: $Kind $Type $Name"; next; }
            my $Definition = eval { YAML::XS::Load($Item->{Definition}) };
            if ($@ || ref $Definition ne 'HASH') { push @Errors, "Invalid definition YAML: $Kind $Type $Name"; next; }
            for my $Role (values %{ $Definition->{Roles} || {} }) {
                my $RoleName = ref $Role eq 'HASH' ? $Role->{Name} : undef;
                next if !defined $RoleName;
                $RequiredRoles{$RoleName} = 1;
                my $Target = $Catalog{"${Prefix}::Role"}{$RoleName};
                push @Errors, "Inactive or missing role dependency: $Kind $Name -> $RoleName"
                    if !$Target || ($Target->{valid} || '') ne 'valid';
            }
            for my $Category ( @{ $Type eq 'Class' ? ($Item->{Class}{Categories} || []) : [] } ) {
                my $Target = $Catalog{"${Prefix}::Class::Category"}{$Category};
                push @Errors, "Inactive or missing category dependency: $Kind $Name -> $Category"
                    if !$Target || ($Target->{valid} || '') ne 'valid';
            }
            push @Selected, $Item;
        }
        # An active catalog label without its definition is not a usable seed.
        for my $Type (qw(Class Role)) {
            for my $Name (sort keys %{ $Catalog{"${Prefix}::$Type"} || {} }) {
                push @Pending, "$Kind $Type $Name"
                    if ($Catalog{"${Prefix}::$Type"}{$Name}{valid} || '') eq 'valid' && !$Seen{"$Type/$Name"};
            }
        }
        for my $Name (sort keys %RequiredRoles) {
            push @Errors, "Referenced role definition is missing: $Kind $Name" if !$Seen{"Role/$Name"};
        }
        $Definitions{$Kind} = \@Selected;
    }
    my @Types;
    for my $Key (sort keys %{ $P{Types}{Types} || {} }) {
        my $Type = $P{Types}{Types}{$Key};
        if (!defined $Type->{Valid} || $Type->{Valid} !~ /\A(?:valid|invalid|invalid-temporarily)\z/) {
            push @Errors, "Unknown ticket type validity: $Key"; next;
        }
        if ($Type->{Valid} eq 'valid') {
            push @Errors, "Ticket type name mismatch: $Key" if ($Type->{Name} || '') ne $Key;
            push @Types, $Key;
        }
        else { push @Excluded, "TicketType/$Key"; }
    }
    push @Errors, 'No active ticket types' if !@Types;
    return {
        FormatVersion => 1, Errors => [sort @Errors], Excluded => [sort @Excluded], Pending => [sort @Pending],
        Seed => { TicketTypes => \@Types, GeneralCatalog => \@Catalogs, %Definitions },
    };
}
1;

