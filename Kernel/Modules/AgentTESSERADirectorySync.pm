package Kernel::Modules::AgentTESSERADirectorySync;
use strict;
use warnings;
our $ObjectManagerDisabled=1;
sub new {my ($T,%P)=@_;bless \%P,$T}
sub Run {
    my ($S)=@_;my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');my $R=$Kernel::OM->Get('Kernel::System::Web::Request');
    my $Sync=$Kernel::OM->Get('Kernel::System::TESSERA::DirectorySync');
    return $L->NoPermission(WithHeader=>1) if !$Sync->Authorized($S->{UserID});
    my $Message='';
    if ($S->{Subaction}) {
        return $L->ErrorScreen(Message=>'Use a protected POST request.') if $R->RequestMethod() ne 'POST'
            || ($R->GetParam(Param=>'ChallengeToken') || '') ne ($L->{UserChallengeToken} || '') || !$L->{UserChallengeToken};
        return $L->ErrorScreen(Message=>'Invalid request token.') if !$L->ChallengeTokenCheck();
        my $OK=eval {
            if ($S->{Subaction} eq 'Save') {
                my %C=map {$_=>$R->GetParam(Param=>$_)} qw(Host BindUser GroupBase UserBase GroupFilter CAFile CustomerID LoginAttribute Provider RoleID IntervalHours Enabled AutoCreateProfiles Nested SyncAssignments ResponsibilityText);
                $Sync->Save(UserID=>$S->{UserID},Config=>\%C,Password=>$R->GetParam(Param=>'Password'),Script=>$R->GetParam(Param=>'Script'));
            } elsif ($S->{Subaction} eq 'Discover') {$Sync->Discover(UserID=>$S->{UserID})}
            elsif ($S->{Subaction} eq 'Sync') {$Sync->Queue(UserID=>$S->{UserID})}
            elsif ($S->{Subaction} eq 'Map') {$Sync->Map(UserID=>$S->{UserID},map {$_=>$R->GetParam(Param=>$_)} qw(GUID ProfileID RoleID Mode Create))}
            else {die 'Unknown action'}
            1;
        };
        # Directory/vendor errors can contain DNs, bind credentials or raw data.
        # Never reflect/log raw exception strings from this boundary.
        return $L->Redirect(OP=>'Action=AgentTESSERADirectorySync') if $OK;
        $Message='Operation could not complete. Check configuration, authentication router, mapping conflicts and directory completeness. Existing data is preserved on failed sync.';
    }
    my $D=$Sync->View(UserID=>$S->{UserID});
    my @Inputs=map {{Name=>$_->[0],Label=>$_->[1],Value=>$D->{Config}{$_->[0]} // $_->[2] // ''}} (
        ['Host','AD DNS hostname'],['BindUser','Bind username / DN'],['GroupBase','Group search base DN'],['UserBase','User search base DN'],
        ['GroupFilter','Group LDAP filter','(cn=*)'],['CAFile','CA PEM file','/etc/ssl/certs/ca-certificates.crt'],['CustomerID','Customer company ID'],
        ['IntervalHours','Sync interval in hours',24]);
    my @Profiles;my @Roles;my $GO=$Kernel::OM->Get('Kernel::System::GovernanceObject');
    for my $Class ('SupportProfile','GovernanceRole') {
        my @IDs=$GO->GovernanceObjectSearch(Classes=>[$Class],ZTSMStatuss=>['Active'],Result=>'ARRAY',Limit=>1001);
        return $L->ErrorScreen(Message=>'Too many governance choices; narrow the catalog first.') if @IDs>1000;
        for my $ID (@IDs) {my $O=$GO->GovernanceObjectGet(GovernanceObjectID=>$ID);next if !$O;
            if ($Class eq 'SupportProfile') {push @Profiles,{ID=>$ID,Name=>$O->{Name}}}
            elsif ($O->{Name}=~/\ASUPPORT::/) {push @Roles,{ID=>$ID,Name=>$O->{Name}}}
        }
    }
    return $L->Header(Title=>'Directory self service').$L->NavigationBar().$L->Output(TemplateFile=>'AgentTESSERADirectorySync',Data=>{
        State=>$D,Inputs=>\@Inputs,Profiles=>\@Profiles,Roles=>\@Roles,Message=>$Message,RoutingReady=>$Sync->RoutingReady(),
    }).$L->Footer();
}
1;
