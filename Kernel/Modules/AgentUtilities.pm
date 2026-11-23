package Kernel::Modules::AgentUtilities;
use strict;
use warnings;
use JSON::PP ();
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;bless \%P,$T}
sub Run {
    my ($S)=@_;my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');my $R=$Kernel::OM->Get('Kernel::System::Web::Request');my $B=$Kernel::OM->Get('Kernel::System::TESSERA::Utilities');
    return $L->NoPermission(WithHeader=>1) if !$B->Authorized($S->{UserID});
    my $V=eval {$B->AdminView(UserID=>$S->{UserID})};return $L->ErrorScreen(Message=>'Utilities storage is unavailable.') if !$V;
    my $ID=$R->GetParam(Param=>'ID') || '';my ($Tool)=grep {$_->{ID} eq $ID} @{$V->{Tools}};
    return $L->ErrorScreen(Message=>'Utility no longer exists.') if $ID && !$Tool;
    $Tool ||= {Name=>'',Description=>'',Type=>'External',Audience=>'none',Users=>[],Enabled=>0,Workplace=>0,Order=>100,Parameters=>{}};
    my ($Error,$Preview,$Saved);my $Sub=$R->GetParam(Param=>'Subaction') || '';
    if ($Sub) {
        return $L->ErrorScreen(Message=>'Use a protected POST request.') if $R->RequestMethod() ne 'POST' || !$L->{UserChallengeToken}
            || ($R->GetParam(Param=>'ChallengeToken') || '') ne $L->{UserChallengeToken} || !$L->ChallengeTokenCheck();
        if ($Sub eq 'Save') {
            my $OK=eval {
                my %New=map {$_=>$R->GetParam(Param=>$_) || ''} qw(Name Description Type URL Handler Audience Order Enabled Workplace);
                $New{ID}=$ID;my $Users=$R->GetParam(Param=>'Users') || '';die "Too many customer logins.\n" if length($Users)>100000;
                $New{Users}=[grep {length} map {s/^\s+|\s+$//gr} split /\r?\n/,$Users];
                my $Raw=$R->GetParam(Param=>'Parameters') || '{}';die "Parameter mapping is too large.\n" if length($Raw)>20000;
                $New{Parameters}=JSON::PP->new->decode($Raw);
                my %Upload=$R->GetUploadAll(Param=>'Icon');my %Icon;
                $Icon{IconContent}=$Upload{Content} if defined $Upload{Content} && length($Upload{Content});
                $Saved=$B->Save(UserID=>$S->{UserID},Revision=>$R->GetParam(Param=>'Revision'),Tool=>\%New,RemoveIcon=>$R->GetParam(Param=>'RemoveIcon'),%Icon);1;
            };
            return $L->Redirect(OP=>'Action=AgentUtilities;ID='.$Saved) if $OK;
            # Validation exceptions are static application messages; do not expose unexpected backend errors.
            $Error=$@ =~ /\A(Enter |Invalid |Choose |Select |Credentials |Built-in |Utility no longer|Catalogue changed|Catalogue is |Utilities are busy|Parameter mapping is |Too many |The image )/?$@:'Utility could not be saved. Check configuration and server logs, then reload.';
        } elsif ($Sub eq 'Preview') {
            my $Login=$R->GetParam(Param=>'CustomerLogin') || '';
            my $Rows=eval {$B->List(CustomerUserID=>$Login)};
            $Preview={Tools=>$Rows || [],CustomerLogin=>$Login};
            if ($ID) {
                my $Dest=eval {$B->Launch(CustomerUserID=>$Login,ID=>$ID,map {$_=>$R->GetParam(Param=>$_) || ''} qw(TicketID ConfigItemID))};
                $Preview->{Destination}=$Dest?($Dest->{URL} || $Dest->{OP}):'';
                $Preview->{LaunchDenied}=$Dest?0:1;
            }
        } else {return $L->ErrorScreen(Message=>'Unknown utility action.')}
    }
    my @Handlers=map {{ID=>$_,Name=>$V->{Handlers}{$_}{Name}}} sort keys %{$V->{Handlers}};
    return $L->Header(Title=>'Utilities').$L->NavigationBar().$L->Output(TemplateFile=>'AgentUtilities',Data=>{
        %$V,Tool=>$Tool,UsersText=>join("\n",@{$Tool->{Users}}),ParametersText=>JSON::PP->new->canonical->pretty->encode($Tool->{Parameters}),Handlers=>\@Handlers,Error=>$Error,Preview=>$Preview,
    }).$L->Footer();
}
1;
