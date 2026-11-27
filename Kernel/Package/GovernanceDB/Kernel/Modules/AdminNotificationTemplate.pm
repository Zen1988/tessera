package Kernel::Modules::AdminNotificationTemplate;

use strict;
use warnings;
use utf8;
use JSON::PP ();
use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;
    return bless \%Param, $Type;
}

sub Run {
    my ($Self) = @_;
    my $Layout = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $Group = $Kernel::OM->Get('Kernel::System::Group');
    return $Layout->NoPermission( WithHeader => 'yes' )
        if !$Group->PermissionCheck( UserID => $Self->{UserID}, GroupName => 'admin', Type => 'rw' );

    my $Request = $Kernel::OM->Get('Kernel::System::Web::Request');
    if ( ($Request->GetParam( Param => 'Mode' ) // '') eq 'PolicyTest' ) {
        return $Self->_PolicyTest( Layout => $Layout, Request => $Request );
    }
    my $GO = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my $Catalog = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $Renderer = $Kernel::OM->Get('Kernel::System::TESSERA::NotificationRenderer');
    my $ClassList = $Catalog->ItemList( Class => 'ZTSM::GovernanceObject::Class', Valid => 1 ) || {};
    my %Classes = reverse %{$ClassList};
    my $StatusList = $Catalog->ItemList( Class => 'ZTSM::GovernanceObject::Status', Valid => 1 ) || {};
    my %Statuses = reverse %{$StatusList};
    my $TemplateClass = $Classes{NotificationTemplate};
    my $LayoutClass = $Classes{NotificationLayout};
    my @Missing;
    push @Missing, 'NotificationTemplate' if !$TemplateClass;
    push @Missing, 'NotificationLayout' if !$LayoutClass;
    push @Missing, 'Active' if !$Statuses{Active};
    if (@Missing) {
        return $Layout->ErrorScreen(
            Message => Translatable('Email template configuration is unavailable.'),
            Comment => join( ', ', @Missing ),
        );
    }

    my $IsLayout = ( $Request->GetParam( Param => 'Mode' ) || '' ) eq 'Layout';
    my $TemplateID = $Request->GetParam( Param => 'TemplateID' );
    my @Layouts = $GO->GovernanceObjectSearch( ClassIDs => [$LayoutClass], Result => 'ARRAY', Limit => 2, CacheTTL => 0 );
    return $Layout->ErrorScreen( Message => Translatable('Resolve duplicate shared email layouts before continuing.') )
        if @Layouts > 1;
    my $Shared = @Layouts ? $GO->GovernanceObjectGet(
        GovernanceObjectID => $Layouts[0], DynamicFields => 1,
    ) : {};
    return $Layout->NoPermission( WithHeader => 'yes' ) if @Layouts && (
        !$Shared || !$GO->Permission(
            Type => $IsLayout ? 'rw' : 'ro', Scope => 'Item', ItemID => $Layouts[0], UserID => $Self->{UserID},
        )
    );
    my $Object = $IsLayout ? $Shared : {};
    if ( !$IsLayout && defined $TemplateID && $TemplateID ne '' ) {
        return $Layout->NoPermission( WithHeader => 'yes' ) if $TemplateID !~ /\A[1-9][0-9]*\z/;
        $Object = $GO->GovernanceObjectGet( GovernanceObjectID => $TemplateID, DynamicFields => 1 );
        return $Layout->NoPermission( WithHeader => 'yes' ) if !$Object || $Object->{ClassID} != $TemplateClass
            || !$GO->Permission( Type => 'rw', Scope => 'Item', ItemID => $TemplateID, UserID => $Self->{UserID} );
    }

    my $Preset = $Request->GetParam( Param => 'Preset' ) // '';
    my %Default = !$IsLayout && !$Object->{GovernanceObjectID} ? $Renderer->DefaultTemplate($Preset) : ();
    my %Appearance = $Renderer->DefaultLayout();
    my $SavedTheme = $Shared->{'DynamicField_ZNotify-Theme'};
    my $Theme = eval {
        $Renderer->ThemeValidate( JSON::PP->new->decode($SavedTheme || '{}') );
    };
    my %Data = (
        IsLayout => $IsLayout,
        Theme => $Theme || $Renderer->ThemeDefaults(),
        ThemeError => $Theme ? '' : Translatable('The saved email theme cannot be read. Open Shared helpdesk layout and save it again.'),
        Name => $Object->{Name} // '',
        ObjectID => $Object->{GovernanceObjectID} // '',
        Revision => $Object->{VersionID} // '',
        Subject => $Object->{'DynamicField_ZNotify-Subject'} // '',
        Body => $Object->{'DynamicField_ZNotify-Body'} // '',
        Header => @Layouts ? ($Shared->{'DynamicField_ZNotify-Header'} // '') : $Appearance{Header},
        Footer => @Layouts ? ($Shared->{'DynamicField_ZNotify-Footer'} // '') : $Appearance{Footer},
        Fields => [$Renderer->Fields()],
        Event => $Preset eq 'Update' ? 'Updated' : 'Completed',
        %Default,
    );
    my $Scriptlets = $Object->{'DynamicField_ZNotify-Scriptlets'} // '{}';
    my $Subaction = $Self->{Subaction} // '';
    my $Insert = !$IsLayout && $Subaction =~ /\AInsert(?:Subject|Body)\z/;
    if ( $Subaction eq 'Save' || $Subaction eq 'Preview' || $Insert ) {
        $Layout->ChallengeTokenCheck();
        for my $Key ( $IsLayout ? qw(Header Footer) : qw(Name Subject Body) ) {
            $Data{$Key} = $Request->GetParam( Param => $Key ) // '';
        }
        $Data{TicketNumber} = $Request->GetParam( Param => 'TicketNumber' ) // '';
        $Data{Event} = $Request->GetParam( Param => 'Event' ) // '';
        $Data{ArticleID} = $Request->GetParam( Param => 'ArticleID' ) // '';
        my $Success = eval {
            if ($IsLayout) {
                my %Posted;
                for my $Key ( keys %{ $Renderer->ThemeDefaults() } ) {
                    my $Value = $Request->GetParam( Param => $Key );
                    die "The shared layout form is incomplete. Reopen it and try again.\n" if !defined $Value;
                    $Posted{$Key} = $Value;
                }
                $Data{Theme} = $Renderer->ThemeValidate(\%Posted);
            }
            die "Select a valid notification event.\n" if $Data{Event} !~ /\A(?:Created|Updated|Completed|Rejected|Cancelled)\z/;
            if (!$IsLayout) {
                $Scriptlets = $Self->_Scriptlets( $Request, $Renderer, \%Data );
                $Renderer->ScriptletsValidate($Scriptlets) if !$Insert;
            }
            for my $Key ( $IsLayout ? qw(Header Footer) : qw(Body) ) {
                die "$Key exceeds 3800 characters.\n" if length($Data{$Key}) > 3800;
                $Data{$Key} = $Renderer->HTMLClean( $Data{$Key} );
                die "$Key exceeds 3800 characters after HTML cleanup.\n" if length($Data{$Key}) > 3800;
            }
            if ($Insert) {
                $Data{Revision} = $Request->GetParam( Param => 'Revision' ) // '';
                my $Name = $Request->GetParam( Param => 'InsertVariable' ) // '';
                my %Allowed = map { $_ => 1 } ( $Renderer->Fields(), map { $_->{Variable} } @{ $Data{Rows} } );
                $Allowed{OpenInTessera} = 1 if $Subaction eq 'InsertBody';
                die "Select a valid template variable.\n"
                    if $Name !~ /\A[A-Za-z][A-Za-z0-9_]{0,39}\z/ || !$Allowed{$Name};
                my $Token = '{{' . $Name . '}}';
                if ( $Subaction eq 'InsertBody' ) {
                    die "Body exceeds 3800 characters.\n" if length($Data{Body}) + length($Token) + 7 > 3800;
                    $Data{Body} .= '<p>' . $Token . '</p>';
                }
                else {
                    die "Subject exceeds 200 characters.\n" if length($Data{Subject}) + length($Token) > 200;
                    $Data{Subject} .= $Token;
                }
            }
            elsif ( !$IsLayout ) {
                die "Enter a template name and subject of up to 200 characters.\n"
                    if $Data{Name} !~ /\S/ || $Data{Subject} !~ /\S/
                    || length($Data{Name}) > 200 || length($Data{Subject}) > 200
                    || $Data{Subject} =~ /[\x00-\x1f\x7f]/;
            }
            if ( $Subaction eq 'Preview' ) {
                my $IncludeUpdate = $Data{Event} eq 'Updated' && !$IsLayout;
                my %Ticket = (
                    TicketID => 4582, TicketNumber => 'TESSERA-2026-004582',
                    Title => 'Firewall access request for APP-A to APP-B',
                    Created => '2026-11-27 10:32:00',
                    Status => $Data{Event} eq 'Completed' ? 'Completed' : 'Pending approval',
                    RaisedBy => 'Sample requester', Event => $Data{Event},
                    UpdateMessage => 'The application owner is reviewing the requested firewall access.',
                );
                if ( $Data{TicketNumber} ne '' ) {
                    %Ticket = $Self->_PreviewTicket( \%Data, $IncludeUpdate );
                }
                my %PreviewDefault = $IsLayout ? $Renderer->DefaultTemplate('Completion') : ();
                $Data{Preview} = $Renderer->Render(
                    %Data, %PreviewDefault, Ticket => \%Ticket, Scriptlets => $Scriptlets,
                    Preview => 1, IncludeUpdate => $IncludeUpdate,
                );
            }
            elsif ( $Subaction eq 'Save' ) {
                my $Revision = $Request->GetParam( Param => 'Revision' ) // '';
                die "This record changed. Reopen it before saving.\n" if $Revision ne $Data{Revision};
                my %Fields = $IsLayout ? (
                    'DynamicField_ZNotify-Header' => $Data{Header},
                    'DynamicField_ZNotify-Footer' => $Data{Footer},
                    'DynamicField_ZNotify-Theme' => JSON::PP->new->canonical->encode($Data{Theme}),
                ) : (
                    'DynamicField_ZNotify-Subject' => $Data{Subject},
                    'DynamicField_ZNotify-Body' => $Data{Body},
                    'DynamicField_ZNotify-Scriptlets' => $Scriptlets,
                );
                my %Save = (
                    %Fields, UserID => $Self->{UserID},
                    Name => $IsLayout ? 'Shared helpdesk email layout' : $Data{Name},
                );
                my $ClassID = $IsLayout ? $LayoutClass : $TemplateClass;
                die "You do not have permission to save this record.\n"
                    if !$GO->Permission( Scope => 'Class', ClassID => $ClassID, Type => 'rw', UserID => $Self->{UserID} );
                my $Definition = $GO->DefinitionGet( ClassID => $ClassID );
                for my $Key ( keys %Fields ) {
                    my $Field = $Key =~ s/\ADynamicField_//r;
                    die "The email configuration schema is missing $Field.\n"
                        if !$Definition || !$Definition->{DynamicFieldRef}->{$Field};
                }
                my $ID = $Data{ObjectID};
                if ($ID) {
                    die "The email configuration could not be saved.\n"
                        if !$GO->GovernanceObjectUpdate( %Save, GovernanceObjectID => $ID );
                }
                else {
                    $ID = $GO->GovernanceObjectAdd(
                        %Save, ClassID => $ClassID,
                        ($IsLayout ? ( Number => 'TESSERA-NOTIFICATION-LAYOUT' ) : ()),
                        ZTSMStatusID => $Statuses{Active},
                    );
                    die "The email configuration could not be saved.\n" if !$ID;
                }
                if ($IsLayout) {
                    my $Saved = $GO->GovernanceObjectGet( GovernanceObjectID => $ID, DynamicFields => 1 );
                    die "The shared email layout could not be read back. No save was confirmed.\n"
                        if !$Saved || !$Saved->{VersionID} || grep {
                            ($Saved->{$_} // '') ne $Fields{$_}
                        } keys %Fields;
                    $Data{ObjectID} = $ID;
                    $Data{Revision} = $Saved->{VersionID};
                    $Data{LayoutSaved} = 1;
                    $Data{ThemeError} = '';
                }
                else {
                    $Data{SavedID} = $ID;
                }
            }
            1;
        };
        if ( !$Success ) {
            $Data{Error} = $@ || 'The email configuration could not be processed.';
            $Data{Error} =~ s/\s+\z//;
        }
        if ( $Data{SavedID} ) {
            return $Layout->Redirect( OP => 'Action=AdminNotificationTemplate;'
                . ( $IsLayout ? 'Mode=Layout' : "TemplateID=$Data{SavedID}" ) );
        }
    }

    if ( !$IsLayout && !$Data{Rows} ) {
        my $Rows = eval { JSON::PP->new->decode($Scriptlets) };
        $Rows = {} if ref $Rows ne 'HASH';
        $Data{Rows} = [map { { %{ $Rows->{$_} }, Variable => $_ } } grep { ref $Rows->{$_} eq 'HASH' } sort keys %{$Rows}];
    }
    push @{ $Data{Rows} }, {} if !$IsLayout && @{ $Data{Rows} } < 24;
    my @Templates = $GO->GovernanceObjectSearch(
        ClassIDs => [$TemplateClass], Result => 'ARRAY', UserID => $Self->{UserID},
    );
    $Data{Templates} = [ sort { lc($a->{Name}) cmp lc($b->{Name}) } grep { $_ } map {
        $GO->GovernanceObjectGet( GovernanceObjectID => $_ )
    } @Templates ];
    $Layout->SetRichTextParameters( Data => { RichTextType => 'None' } ) if $Layout->{BrowserRichText};
    return $Layout->Header( Title => Translatable('Email templates') )
        . $Layout->NavigationBar()
        . $Layout->Output( TemplateFile => 'AdminNotificationTemplate', Data => \%Data )
        . $Layout->Footer();
}

sub _PolicyTest {
    my ( $Self, %Param ) = @_;
    my $Layout = $Param{Layout};
    my $Request = $Param{Request};
    my %Events = (
        Raised  => { Kind => 'Created' },
        Status  => { Kind => 'StateChanged', StateChanged => 1 },
        Closed  => { Kind => 'StateChanged', StateChanged => 1, StateType => 'closed' },
        Message => { Kind => 'ArticleCreated', CustomerVisible => 1 },
        Private => { Kind => 'ArticleCreated', CustomerVisible => 0 },
        Child   => { Kind => 'ArticleCreated', CustomerVisible => 1, Master => 0 },
    );
    my %Data = ( PolicyTest => 1, Policy => 'Detailed', Scenario => 'Raised' );
    if ( ($Self->{Subaction} // '') eq 'EvaluatePolicy' ) {
        return $Layout->NoPermission( WithHeader => 'yes' ) if $Request->RequestMethod() ne 'POST';
        $Layout->ChallengeTokenCheck();
        my $Policy = $Request->GetParam( Param => 'TestPolicy' ) // '';
        my $Scenario = $Request->GetParam( Param => 'TestScenario' ) // '';
        if ( $Policy =~ /\A(?:Completion|Detailed|Exclusive|None)\z/ && $Events{$Scenario} ) {
            @Data{qw(Policy Scenario)} = ($Policy, $Scenario);
            $Data{Decision} = $Kernel::OM->Get('Kernel::System::TESSERA::NotificationPolicy')->Evaluate(
                Master => 1, Policy => $Policy, %{ $Events{$Scenario} },
            );
        }
        else {
            $Data{Error} = Translatable('Select a valid policy and scenario.');
        }
    }
    return $Layout->Header( Title => Translatable('Test notification policies') )
        . $Layout->NavigationBar()
        . $Layout->Output( TemplateFile => 'AdminNotificationTemplate', Data => \%Data )
        . $Layout->Footer();
}

sub _PreviewTicket {
    my ( $Self, $Data, $IncludeUpdate ) = @_;
    my $Tickets = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ID = $Tickets->TicketIDLookup( TicketNumber => $Data->{TicketNumber} );
    die "The ticket or its requester preview is unavailable.\n"
        if !$ID || !$Tickets->TicketPermission( Type => 'ro', TicketID => $ID, UserID => $Self->{UserID} );
    my %Ticket = $Tickets->TicketGet( TicketID => $ID, UserID => $Self->{UserID}, DynamicFields => 1 );
    die "The ticket or its requester preview is unavailable.\n"
        if !$Ticket{CustomerUserID} || !$Tickets->TicketCustomerPermission(
            Type => 'ro', TicketID => $ID, UserID => $Ticket{CustomerUserID},
        );
    die "Enter the parent request number for this preview.\n" if $Ticket{'DynamicField_ZTicket-Parent'};

    my $RaisedBy = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
        UserLogin => $Ticket{CustomerUserID},
    );
    my $UpdateMessage;
    if ($IncludeUpdate && $Data->{ArticleID} ne '') {
        my $Policy = $Ticket{'DynamicField_ZTicket-NotificationPolicy'} // '';
        die "This request does not have Standard or Exclusive updates enabled.\n" if $Policy ne 'Detailed' && $Policy ne 'Exclusive';
        die "Enter a valid public article ID.\n" if $Data->{ArticleID} !~ /\A[1-9][0-9]*\z/;
        my $Articles = $Kernel::OM->Get('Kernel::System::Ticket::Article');
        my ($Selected) = grep { $_->{ArticleID} eq $Data->{ArticleID} } $Articles->ArticleList(
            TicketID => $ID, IsVisibleForCustomer => 1,
        );
        die "The requested article is not available to the requester.\n" if !$Selected;
        my $Backend = $Articles->BackendForArticle(%{$Selected});
        my %Article = $Backend->ArticleGet( TicketID => $ID, ArticleID => $Selected->{ArticleID} );
        $UpdateMessage = $Article{Body} // '';
        if ( ($Article{ContentType} // $Article{MimeType} // '') =~ m{\Atext/html\b}i ) {
            $UpdateMessage = $Kernel::OM->Get('Kernel::System::HTMLUtils')->ToAscii( String => $UpdateMessage );
        }
        $UpdateMessage = substr($UpdateMessage, 0, 1000) . '…' if length($UpdateMessage) > 1000;
    }
    return (
        TicketID => $ID, TicketNumber => $Ticket{TicketNumber}, Title => $Ticket{Title},
        Created => $Ticket{Created}, Status => $Ticket{State}, RaisedBy => $RaisedBy,
        Event => $Data->{Event}, UpdateMessage => $UpdateMessage,
    );
}

sub _Scriptlets {
    my ( $Self, $Request, $Renderer, $Data ) = @_;
    my @Names = $Request->GetArray( Param => 'Variable' );
    my @Sources = $Request->GetArray( Param => 'Source' );
    my @Fallbacks = $Request->GetArray( Param => 'Fallback' );
    my @Fields = $Request->GetArray( Param => 'BuildField' );
    die "Invalid scriptlet rows.\n" if @Names > 24 || @Sources != @Names || @Fallbacks != @Names || @Fields != @Names;
    my %Allowed = map { $_ => 1 } $Renderer->Fields();
    my %Results;
    $Data->{Rows} = [];
    for my $Index ( 0 .. $#Names ) {
        my ($Name, $Source, $Fallback, $Field) = ( $Names[$Index], $Sources[$Index], $Fallbacks[$Index], $Fields[$Index] );
        next if $Name eq '' && $Source eq '' && $Fallback eq '' && $Field eq '';
        $Source = "LET THIS: TICKET\nRETURN:\n  VALUE: THIS.$Field\n" if $Allowed{$Field};
        push @{ $Data->{Rows} }, { Variable => $Name, Source => $Source, Fallback => $Fallback };
    }
    for my $Row ( @{ $Data->{Rows} } ) {
        my $Name = $Row->{Variable};
        die "Every scriptlet needs a unique variable name.\n" if $Name eq '' || exists $Results{$Name};
        $Results{$Name} = { Source => $Row->{Source}, Fallback => $Row->{Fallback} };
    }
    return JSON::PP->new->canonical->encode(\%Results);
}

1;
