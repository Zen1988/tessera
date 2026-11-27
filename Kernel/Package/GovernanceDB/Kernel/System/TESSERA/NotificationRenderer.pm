package Kernel::System::TESSERA::NotificationRenderer;

use strict;
use warnings;
use HTML::Entities qw(encode_entities);
use HTML::Parser ();
use JSON::PP ();

our @ObjectDependencies = ('Kernel::Config', 'Kernel::System::TESSERA::ScriptEngine');

sub new { return bless {}, shift }

sub Fields { return qw(TicketID TicketNumber Title Created Status RaisedBy Event UpdateMessage) }

sub DefaultLayout {
    return (
        Header => '<h1>TESSERA</h1><p><strong>System notification</strong></p>'
            . '<p>This is an automated TESSERA notification.</p>',
        Footer => '<p>Regards,<br><strong>TESSERA Helpdesk</strong><br>Sent by the TESSERA Notification Engine</p>',
    );
}

sub ThemeDefaults {
    return {
        HeaderColor => '#073853',
        SectionColor => '#d9f2f2',
        ButtonColor => '#006d77',
        ButtonLabel => 'Open in TESSERA',
        SignInHint => 'Sign in to TESSERA if prompted to continue to your request.',
    };
}

sub ThemeValidate {
    my ( $Self, $Input ) = @_;
    die "Invalid email theme.\n" if ref $Input ne 'HASH';
    my $Theme = $Self->ThemeDefaults();
    for my $Key (qw(HeaderColor SectionColor ButtonColor)) {
        next if !exists $Input->{$Key};
        my $Color = $Input->{$Key};
        die "Enter a valid hexadecimal color.\n"
            if !defined $Color || ref $Color || $Color !~ /\A#[0-9A-Fa-f]{6}\z/;
        $Theme->{$Key} = lc $Color;
    }
    for my $Key (qw(ButtonLabel SignInHint)) {
        next if !exists $Input->{$Key};
        my $Text = $Input->{$Key};
        die "The shared action label or hint is invalid.\n"
            if !defined $Text || ref $Text || $Text =~ /[\x00-\x1f\x7f]/
            || length($Text) > ($Key eq 'ButtonLabel' ? 80 : 200)
            || ($Key eq 'ButtonLabel' && $Text !~ /\S/);
        $Theme->{$Key} = $Text;
    }
    return $Theme;
}

sub _Contrast {
    my ($Color) = @_;
    my @RGB = map {
        my $Value = hex($_) / 255;
        $Value <= 0.04045 ? $Value / 12.92 : (($Value + 0.055) / 1.055)**2.4;
    } $Color =~ /([0-9a-f]{2})/g;
    my $Luminance = 0.2126 * $RGB[0] + 0.7152 * $RGB[1] + 0.0722 * $RGB[2];
    return $Luminance > 0.179 ? '#000000' : '#ffffff';
}

sub DefaultTemplate {
    my ( $Self, $Mode ) = @_;
    return if !$Mode || $Mode !~ /\A(?:Completion|Update|ActivityCreated|ActivityClosed|ActivityEscalation)\z/;
    if ($Mode =~ /\AActivity/) {
        my %Titles = (
            ActivityCreated => 'Activity created',
            ActivityClosed => 'Activity closed',
            ActivityEscalation => 'Unassigned activity escalation',
        );
        my $Title = $Titles{$Mode};
        return (
            Name => "TESSERA $Title",
            Subject => "TESSERA | $Title {{TicketNumber}}",
            Body => "<h2>$Title</h2><p><strong>Activity</strong> {{TicketNumber}} · {{Title}}</p>"
                . '<p><strong>Status</strong> {{Status}}</p><p>{{OpenInTessera}}</p>',
        );
    }
    my $IsUpdate = $Mode eq 'Update';
    my $Body = <<'HTML';
<h2>TESSERA ticket notification</h2>
<table>
<tr><th scope="row">Request number</th><td>{{TicketNumber}}</td></tr>
<tr><th scope="row">Parent ticket ID</th><td>{{TicketID}}</td></tr>
<tr><th scope="row">Summary</th><td>{{Title}}</td></tr>
<tr><th scope="row">Created (system time)</th><td>{{Created}}</td></tr>
<tr><th scope="row">Current status</th><td>{{Status}}</td></tr>
<tr><th scope="row">Raised by</th><td>{{RaisedBy}}</td></tr>
</table>
<h2>Smart action</h2>
<p>{{OpenInTessera}}</p>
HTML
    $Body .= $IsUpdate
        ? '<h2>Activity / context</h2><p>{{UpdateMessage}}</p>'
        : '<h2>Activity / context</h2><p>Your request is complete. Open it in TESSERA to review the outcome.</p>';
    return (
        Name => $IsUpdate ? 'TESSERA detailed request update' : 'TESSERA request completion',
        Subject => $IsUpdate ? 'TESSERA | Update for {{TicketNumber}}' : 'TESSERA | Request {{TicketNumber}} completed',
        Body => $Body,
    );
}

sub RequestURL {
    my ( $Self, %Param ) = @_;
    return if ($Param{TicketID} // '') !~ /\A[1-9][0-9]*\z/;
    my $Config = $Kernel::OM->Get('Kernel::Config');
    my $Host = $Config->Get('FQDN') // '';
    my $Path = $Config->Get('ScriptAlias') // '';
    return if ($Config->Get('HttpType') // '') ne 'https'
        || $Host !~ /\A[A-Za-z0-9][A-Za-z0-9.-]*(?::[0-9]{1,5})?\z/
        || $Path !~ m{\A/?(?:[A-Za-z0-9_-]+/)*\z};
    $Path =~ s{\A/}{};
    my $URL = "https://$Host/${Path}customer.pl?Action=CustomerTicketZoom;TicketID=$Param{TicketID}";
    $URL .= ";ArticleID=$Param{ArticleID}" if ($Param{ArticleID} // '') =~ /\A[1-9][0-9]*\z/;
    return $URL;
}

sub ScriptletsValidate {
    my ( $Self, $Source ) = @_;
    my $Rows = eval { JSON::PP->new->decode($Source || '{}') };
    die "Invalid scriptlet storage.\n" if ref $Rows ne 'HASH' || length($Source || '') > 3800;
    my %Fields = map { $_ => 1 } $Self->Fields();
    my $Engine = $Kernel::OM->Get('Kernel::System::TESSERA::ScriptEngine');
    my %Parsed;
    for my $Name ( sort keys %{$Rows} ) {
        my $Row = $Rows->{$Name};
        die "Invalid or reserved variable name.\n"
            if $Name !~ /\A[A-Za-z][A-Za-z0-9_]{0,39}\z/ || $Fields{$Name} || $Name eq 'OpenInTessera';
        die "Invalid scriptlet $Name.\n"
            if ref $Row ne 'HASH' || !defined $Row->{Source} || ref $Row->{Source}
            || ref $Row->{Fallback};
        my $Result = $Engine->ScriptParse( Source => $Row->{Source} );
        die "$Name: $Result->{Error}\n" if !$Result->{Success};
        my $Script = $Result->{Script};
        die "$Name: Only read-only ticket value resolution is available.\n"
            if grep { !/\A(?:SCRIPT|VERSION|LET THIS|RETURN)\z/ } keys %{$Script};
        my $Return = $Script->{RETURN};
        die "$Name: RETURN must specify VALUE from an approved ticket field.\n"
            if ref $Return ne 'HASH' || keys(%{$Return}) != 1 || ref $Return->{VALUE}
            || ($Return->{VALUE} || '') !~ /\A(?:THIS|TICKET)\.([A-Za-z]+)\z/ || !$Fields{$1};
        $Parsed{$Name} = $Result;
    }
    return ( $Rows, \%Parsed );
}

sub Render {
    my ( $Self, %Param ) = @_;
    my ( $Rows, $Parsed ) = $Self->ScriptletsValidate( $Param{Scriptlets} );
    my $Theme = $Self->ThemeValidate( $Param{Theme} // {} );
    if ( ($Param{Body} // '') =~ /\{\{OpenInTessera\}\}/ ) {
        $Param{Body} =~ s{<p>Sign in to TESSERA if prompted to continue to your request\.</p>}{}g;
    }
    my %Values = map { $_ => $Param{Ticket}->{$_} } $Self->Fields();
    if (!$Param{IncludeUpdate}) {
        delete $Values{UpdateMessage};
    }
    my @Diagnostics;
    my $Engine = $Kernel::OM->Get('Kernel::System::TESSERA::ScriptEngine');
    for my $Name ( sort keys %{$Rows} ) {
        my $Result = $Engine->ScriptEvaluate( Parsed => $Parsed->{$Name}, Context => { TICKET => \%Values } );
        my $Value = $Result->{Success} ? $Result->{Value} : undef;
        my $Status = 'Resolved';
        if ( !defined $Value || $Value eq '' ) {
            $Value = $Rows->{$Name}->{Fallback};
            $Status = defined $Value && $Value ne '' ? 'Fallback' : 'Missing';
        }
        $Values{$Name} = $Value;
        push @Diagnostics, { Name => $Name, Value => $Value, Status => $Status };
    }
    my %Used;
    my $Replace = sub {
        my ( $Text, $HTML ) = @_;
        $Text = encode_entities($Text, q{<>&"'}) if $HTML;
        $Text =~ s/\{\{([A-Za-z][A-Za-z0-9_]{0,39})\}\}/
            my $Name = $1;
            $Used{$Name} = 1;
            my $Value = $Values{$Name} \/\/ '';
            if ($HTML) {
                $Value = encode_entities($Value, q{<>&"'});
                $Value =~ s{\r?\n}{<br>}g;
            }
            $Value;
        /gex;
        return $Text;
    };
    my $Subject = $Replace->($Param{Subject} // '');
    $Subject =~ s/[\x00-\x1f\x7f]+/ /g;
    my $URL = $Param{Preview} ? undef : $Self->RequestURL(
        TicketID => $Values{TicketID},
        ArticleID => $Param{IncludeUpdate} ? $Param{ArticleID} : undef,
    );
    my $HTML = join '', map {
        $Self->HTMLClean( $_, Replace => $Replace, Preview => $Param{Preview}, ActionURL => $URL, Theme => $Theme )
    } @Param{qw(Header Body Footer)};
    push @Diagnostics, map {
        { Name => $_, Value => $Values{$_}, Status => defined $Values{$_} && $Values{$_} ne '' ? 'Resolved' : 'Missing' }
    } grep { !exists $Rows->{$_} } sort keys %Used;
    return { Subject => $Subject, HTML => $HTML, Diagnostics => \@Diagnostics };
}

sub HTMLClean {
    my ( $Self, $Input, %Param ) = @_;
    my %Allowed = map { $_ => 1 } qw(p div span br strong b em i u s h1 h2 h3 h4 ul ol li blockquote pre code hr table thead tbody tr th td a);
    my $Theme = $Param{Theme} || $Self->ThemeDefaults();
    my $HeaderText = _Contrast( $Theme->{HeaderColor} );
    my $SectionText = _Contrast( $Theme->{SectionColor} );
    my %Style = (
        h1 => "margin:0;padding:18px 20px;background:$Theme->{HeaderColor};color:$HeaderText;font:700 26px Arial,sans-serif",
        h2 => "margin:18px 0 0;padding:10px 12px;background:$Theme->{SectionColor};color:$SectionText;font:700 18px Arial,sans-serif",
        table => 'width:100%;border-collapse:collapse;font:15px Arial,sans-serif',
        th => 'padding:9px;text-align:left;background:#edf8f9;color:#073853;border-bottom:1px solid #cde5e7',
        td => 'padding:9px;color:#12334a;border-bottom:1px solid #cde5e7',
        p => 'margin:10px 0;color:#12334a;font:15px Arial,sans-serif',
    );
    my %Void = map { $_ => 1 } qw(br hr);
    my $HTML = '';
    my $Parser = HTML::Parser->new( api_version => 3 );
    $Parser->ignore_elements(qw(script style iframe object template svg math noscript));
    $Parser->handler( start => sub {
        my ($Tag, $Attr) = @_;
        return if !$Allowed{$Tag};
        my $Href = $Attr->{href} // '';
        if ( $Tag eq 'a' && !$Param{Preview} && $Href =~ m{\A(?:https://|mailto:)[^\s\x00-\x1f{}]+\z}i ) {
            $HTML .= '<a href="' . encode_entities($Href, q{<>&"'}) . '">';
            return;
        }
        my $Style = $Param{Replace} && $Style{$Tag} ? ' style="' . $Style{$Tag} . '"' : '';
        my $Scope = $Tag eq 'th' && ($Attr->{scope} // '') eq 'row' ? ' scope="row"' : '';
        $HTML .= "<$Tag$Scope$Style>";
    }, 'tagname, attr' );
    $Parser->handler( end => sub {
        my ($Tag) = @_;
        $HTML .= "</$Tag>" if $Allowed{$Tag} && !$Void{$Tag};
    }, 'tagname' );
    $Parser->handler( text => sub {
        my ($Text) = @_;
        if (!$Param{Replace}) {
            $HTML .= encode_entities($Text, q{<>&"'});
            return;
        }
        for my $Part ( split /(\{\{OpenInTessera\}\})/, $Text ) {
            if ($Part ne '{{OpenInTessera}}') {
                $HTML .= $Param{Replace}->($Part, 1);
                next;
            }
            next if !$Param{ActionURL} && !$Param{Preview};
            my $TextColor = _Contrast( $Theme->{ButtonColor} );
            my $Style = "display:inline-block;padding:12px 18px;background:$Theme->{ButtonColor};color:$TextColor;font:bold 15px Arial,sans-serif;text-decoration:none";
            my $Label = encode_entities($Theme->{ButtonLabel}, q{<>&"'});
            if ($Param{ActionURL}) {
                $HTML .= '<a style="' . $Style . '" href="' . encode_entities($Param{ActionURL}, q{<>&"'})
                    . '">' . $Label . '</a>';
            }
            else {
                $HTML .= '<span style="' . $Style . '">' . $Label . '</span>';
            }
            if (length $Theme->{SignInHint}) {
                $HTML .= '<span style="display:block;margin-top:8px;font-size:13px">'
                    . encode_entities($Theme->{SignInHint}, q{<>&"'}) . '</span>';
            }
        }
    }, 'dtext' );
    $Parser->parse($Input // '');
    $Parser->eof();
    return $HTML;
}

1;
