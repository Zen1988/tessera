use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

my $Root = File::Spec->catdir( $FindBin::Bin, '..', '..', '..' );
my $Module = File::Spec->catfile(
    $Root, qw(Kernel Package GovernanceDB var governancedb runtime_overlay Kernel Modules CustomerTicketZoom.pm)
);
open my $FH, '<', $Module or die "Cannot read $Module: $!";
local $/;
my $Source = <$FH>;
close $FH;
$Source =~ s{^use Kernel::[^;]+;\r?\n}{}mg;
eval $Source;
die $@ if $@;

{
    no strict 'refs';
    *{'Kernel::Modules::CustomerTicketZoom::IsHashRefWithData'} = sub {
        my ($Value) = @_;
        return ref $Value eq 'HASH' && scalar keys %{$Value};
    };
}

{
    package ParentArticleTestOM;
    sub new { bless {}, shift }
    sub Get { return $_[0] }
    sub TicketCustomerPermission { return 0 }
    sub Run { return $_[0]->{Allow} }
    sub ArticleList { return ( { ArticleID => 12 } ) }
    sub BackendForArticle { return $_[0] }
    sub ArticleGet { return ( Subject => 'Assessment', CreateTime => 'now' ) }
    sub HTMLBodyAttachmentIDGet { return 1 }
    sub ArticlePreview { return '<b title="proof">3 x 4 = 12</b>' }
    sub Ascii2Html { return $_[1] eq 'Text' ? $_[2] : '' }
}

$Kernel::OM = ParentArticleTestOM->new();
my $Zoom = bless { UserID => 'approver' }, 'Kernel::Modules::CustomerTicketZoom';
my $Child = { TicketID => 306, 'DynamicField_ZTicket-Parent' => 305 };

$Kernel::OM->{Allow} = 0;
is( $Zoom->_ZTSMRequestParentArticlesHTML( TicketID => 305, AccessTicket => $Child ), '',
    'parent articles are withheld without current child read permission' );
$Kernel::OM->{Allow} = 1;
my $HTML = $Zoom->_ZTSMRequestParentArticlesHTML( TicketID => 305, AccessTicket => $Child );
like( $HTML, qr/srcdoc="&lt;b title=&quot;proof&quot;&gt;3 x 4 = 12&lt;\/b&gt;"/,
    'authorized child displays sandboxed parent HTML without a second parent-ticket request' );
unlike( $HTML, qr/CustomerTicketArticleContent/, 'parent article does not depend on direct parent URL access' );
is( $Zoom->_ZTSMRequestParentArticlesHTML(
        TicketID => 400, AccessTicket => $Child,
    ), '', 'unlinked parent article is withheld' );

done_testing();
