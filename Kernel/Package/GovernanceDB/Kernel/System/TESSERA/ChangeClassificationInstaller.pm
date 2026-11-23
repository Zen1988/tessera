package Kernel::System::TESSERA::ChangeClassificationInstaller;
use strict;
use warnings;
use JSON::PP ();
our @ObjectDependencies=qw(Kernel::System::DynamicField Kernel::System::SysConfig Kernel::System::Type Kernel::System::Valid);
sub new {bless {},shift}
sub Ensure {
    my ($S)=@_;my $SC=$Kernel::OM->Get('Kernel::System::SysConfig');my $Name='DynamicFields::Driver###Dropdown';
    my %Setting=$SC->SettingGet(Name=>$Name);my $Value=$Setting{EffectiveValue};
    die "Native Dropdown registration is unavailable.\n" if ref $Value ne 'HASH';
    my $Module='Kernel::System::DynamicField::Driver::TESSERAChangeDropdown';
    die "Existing Dropdown customization requires compatibility review.\n" if ($Value->{Module} || '') ne 'Kernel::System::DynamicField::Driver::Dropdown' && ($Value->{Module} || '') ne $Module;
    my $DF=$Kernel::OM->Get('Kernel::System::DynamicField');
    my @Create;
    # Preflight both names before changing shared registration or creating fields.
    for my $Spec (['ChangeType','Change Type','Normal',[qw(Normal Standard Emergency)],10310],['ChangeClassification','Change Classification','Not-Assessed',['Normal','Not-Assessed','Major'],10311]) {
        my ($Field,$Label,$Default,$Options,$Order)=@$Spec;my $Existing=$DF->DynamicFieldGet(Name=>$Field);my %Values=map {$_=>$_} @$Options;
        if (ref $Existing eq 'HASH' && $Existing->{ID}) {
            die "Existing $Field is incompatible; no values were overwritten.\n" if ($Existing->{Name} || '') ne $Field || ($Existing->{ObjectType} || '') ne 'Ticket' || ($Existing->{FieldType} || '') ne 'Dropdown'
                || $Existing->{Config}{MultiValue} || ($Existing->{Config}{DefaultValue} || '') ne $Default
                || JSON::PP->new->canonical->encode($Existing->{Config}{PossibleValues} || {}) ne JSON::PP->new->canonical->encode(\%Values);
            next;
        }
        push @Create,$Spec;
    }
    if (($Value->{Module} || '') ne $Module || !$Setting{IsValid}) {
        my %New=(%$Value,Module=>$Module);
        die "Cannot register protected change dropdown.\n" if !$SC->SettingsSet(UserID=>1,Comments=>'Protect change decisions across dynamic field writers',Settings=>[{Name=>$Name,IsValid=>1,EffectiveValue=>\%New}]);
    }
    my $Loaded=$SC->GlobalEffectiveValueGet(SettingName=>$Name);
    die "Dropdown registration is overridden or not deployed.\n" if ref $Loaded ne 'HASH' || ($Loaded->{Module} || '') ne $Module;
    for my $Spec (@Create) {
        my ($Field,$Label,$Default,$Options,$Order)=@$Spec;my %Values=map {$_=>$_} @$Options;
        die "Cannot create $Field.\n" if !$DF->DynamicFieldAdd(Name=>$Field,Label=>$Label,FieldOrder=>$Order,FieldType=>'Dropdown',ObjectType=>'Ticket',InternalField=>0,
            Config=>{DefaultValue=>$Default,PossibleValues=>\%Values,PossibleNone=>0,MultiValue=>0,TreeView=>0,TranslatableValues=>0,Link=>'',LinkPreview=>'',Tooltip=>$Label},ValidID=>1,UserID=>1,Reorder=>0);
    }
    $DF->EventHandlerTransaction();
    # Retain the legacy ID and its historical tickets, but never offer this type.
    my $Types=$Kernel::OM->Get('Kernel::System::Type');my %Legacy=$Types->TypeGet(Name=>'Change::Major');
    if ($Legacy{ID}) {
        my $Invalid=$Kernel::OM->Get('Kernel::System::Valid')->ValidLookup(Valid=>'invalid');
        die "Cannot resolve legacy type invalidity.\n" if !$Invalid;
        die "Cannot retire legacy major change type.\n" if ($Legacy{ValidID} || 0)!=$Invalid && !$Types->TypeUpdate(ID=>$Legacy{ID},Name=>'Change::Major',ValidID=>$Invalid,UserID=>1);
    }
    return 1;
}
1;
