use v5.24;
use strict;
use warnings;
use Test::More;
use File::Slurp qw(read_file);

my %Package = (
    ConfigItem => {
        SOPM  => 'Kernel/Package/GovernanceDB/TESSERA-Base.sopm',
        XML   => 'Kernel/Package/GovernanceDB/Kernel/Config/Files/XML/GovernanceDB.xml',
        Table => 'ztsm_configitem_activity',
        Event => 'ITSMConfigItem::EventModulePost###110-TESSERAActivityArticles',
    },
    GovernanceObject => {
        SOPM  => 'Kernel/Package/GovernanceDB/TESSERA-Base.sopm',
        XML   => 'Kernel/Package/GovernanceDB/Kernel/Config/Files/XML/GovernanceDB.xml',
        Table => 'governance_object_activity',
        Event => 'GovernanceObject::EventModulePost###110-TESSERAActivityArticles',
    },
    MELTObject => {
        SOPM  => 'Kernel/Package/MELT/MELT.sopm',
        XML   => 'Kernel/Package/MELT/Kernel/Config/Files/XML/MELT.xml',
        Table => 'melt_object_activity_article',
        Event => 'MELTObject::EventModulePost###110-TESSERAActivityArticles',
    },
);

for my $Type ( sort keys %Package ) {
    my $SOPM = read_file( $Package{$Type}->{SOPM} );
    my $XML  = read_file( $Package{$Type}->{XML} );
    like( $SOPM, qr/\Q$Package{$Type}->{Table}\E/, "$Type owns a separate activity table" );
    like( $XML,  qr/\Q$Package{$Type}->{Event}\E/, "$Type has a separate activity recorder" );
    like( $XML,  qr/Activity Articles/, "$Type exposes Activity Articles" );
}

my $MELTXML = read_file('Kernel/Package/MELT/Kernel/Config/Files/XML/MELT.xml');
like( $MELTXML, qr/MELTObject::EventModulePost###100-History" Required="0" Valid="1"/, 'existing MELT history remains enabled' );
unlike( $MELTXML, qr/History-CONTINUED/, 'MELT history registration was not replaced' );
my $MELTDocument = read_file('Kernel/Package/MELT/Kernel/System/MELTObject/Document.pm');
like( $MELTDocument, qr/_RichTextValueForDocument/, 'MELT document export normalizes RichText' );

done_testing();
