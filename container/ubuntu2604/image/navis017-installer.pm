package Kernel::System::TESSERA::ApplicationNavisInstaller;
use strict;
use warnings;
use Scalar::Util qw(refaddr);
our @ObjectDependencies=qw(Kernel::System::DynamicField Kernel::System::GovernanceObject Kernel::System::GeneralCatalog Kernel::System::YAML);
sub new {bless {},shift}
sub Ensure {
    my ($S)=@_;my $DF=$Kernel::OM->Get('Kernel::System::DynamicField');
    my $Existing=$DF->DynamicFieldGet(Name=>'Navis');
    # Native DynamicFieldGet returns {} when the name does not exist.
    $Existing=undef if ref $Existing eq 'HASH' && !keys %$Existing;
    die "Existing Navis field is incompatible.\n" if $Existing && (($Existing->{Name} || '') ne 'Navis'
        || ($Existing->{ObjectType} || '') ne 'GovernanceObject' || ($Existing->{FieldType} || '') ne 'Text'
        || $Existing->{Config}{MultiValue} || ($Existing->{ValidID} || 0)!=1);
    my $Classes=$Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(Class=>'ZTSM::GovernanceObject::Class') || {};
    my @IDs=grep {$Classes->{$_} eq 'Application'} keys %$Classes;
    die "Unique Application class required for Navis field.\n" if @IDs!=1;
    my $GO=$Kernel::OM->Get('Kernel::System::GovernanceObject');my $Definition=$GO->DefinitionGet(ClassID=>$IDs[0]);
    die "Application definition unavailable.\n" if ref $Definition ne 'HASH' || !$Definition->{Definition};
    my $YAML=$Kernel::OM->Get('Kernel::System::YAML');my $Data=$YAML->Load(Data=>$Definition->{Definition});
    die "Application layout requires compatibility review.\n" if ref $Data ne 'HASH' || ref $Data->{Pages} ne 'ARRAY' || !@{$Data->{Pages}}
        || (exists $Data->{Sections} && ref $Data->{Sections} ne 'HASH');
    my $Present=ref $Definition->{DynamicFieldRef} eq 'HASH' && exists $Definition->{DynamicFieldRef}{Navis};
    my ($Find,$Count);my %Active;$Find=sub {
        my ($V,$Depth)=@_;$Depth ||= 0;
        die "Application layout exceeds safe traversal limits.\n" if ++$Count>10000 || $Depth>32;
        my $Address=ref $V?refaddr($V):undef;
        die "Application layout is recursive.\n" if defined $Address && $Active{$Address};
        local $Active{$Address}=1 if defined $Address;
        if (ref $V eq 'HASH') {return 1 if !ref $V->{DF} && ($V->{DF} || '') eq 'Navis';for my $Value (values %$V) {return 1 if $Find->($Value,$Depth+1)}}
        elsif (ref $V eq 'ARRAY') {for my $Value (@$V) {return 1 if $Find->($Value,$Depth+1)}}
        return 0;
    };
    $Present ||= $Find->($Data);undef $Find;
    if (!$Present) {
        die "Application Navis page/section is administrator-owned; review before adding the field.\n"
            if exists $Data->{Sections}{Navis} || grep {ref $_ ne 'HASH' || ($_->{Name} || '') eq 'Navis'} @{$Data->{Pages}};
        # Add an independent optional Agent page; preserve every existing page,
        # role binding, section and field instead of merging/replacing layouts.
        $Data->{Sections}{Navis}={Content=>[{DF=>'Navis'}]};
        push @{$Data->{Pages}},{Name=>'Navis',Interfaces=>['Agent'],Layout=>{Columns=>1,ColumnWidth=>'1fr'},
            Content=>[{Section=>'Navis',RowStart=>1,ColumnStart=>1}]};
    }
    if (!$Existing) {
        die "Cannot create Application Navis label field.\n" if !$DF->DynamicFieldAdd(Name=>'Navis',Label=>'Navis topology name',FieldOrder=>10312,
            FieldType=>'Text',ObjectType=>'GovernanceObject',InternalField=>0,ValidID=>1,UserID=>1,Reorder=>0,
            Config=>{DefaultValue=>'',MultiValue=>0,Link=>'',LinkPreview=>'',RegExList=>[{Value=>'\A(?:[^\s\x00-\x1f\x7f](?:[^\x00-\x1f\x7f]{0,253}[^\s\x00-\x1f\x7f])?)?\z',ErrorMessage=>'Use a topology name of at most255 characters without control characters or surrounding whitespace.'}],
                Tooltip=>'Optional stable Navis application topology name. Leave empty until the named topology exists; do not enter a build UUID.'});
        $DF->EventHandlerTransaction();
    }
    if (!$Present) {
        my $Result=$GO->DefinitionAdd(ClassID=>$IDs[0],Definition=>$YAML->Dump(Data=>$Data),UserID=>1);
        die "Cannot add optional Application Navis page.\n" if ref $Result ne 'HASH' || !$Result->{Success};
    }
    return 1;
}
1;
