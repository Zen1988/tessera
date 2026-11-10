package Kernel::System::TESSERA::DirectoryLDAP;
use strict;
use warnings;
our $ObjectManagerDisabled=1;
sub new { my ($T,%P)=@_; bless \%P,$T }
sub Connect {
    my ($S,$C,$Password)=@_;
    require Net::LDAP;
    my $L=Net::LDAP->new($C->{Host},timeout=>15,version=>3) or die "Directory connection failed.\n";
    my $TLS=$L->start_tls(verify=>'require',cafile=>$C->{CAFile},sslserver=>$C->{Host});
    die "Directory TLS failed.\n" if $TLS->code;
    my $B=$L->bind($C->{BindUser},password=>$Password);
    die "Directory authentication failed.\n" if $B->code;
    return $L;
}
sub _Search {
    my ($S,$L,%P)=@_;
    require Net::LDAP::Control::Paged;
    my $Page=Net::LDAP::Control::Paged->new(size=>200,critical=>1);
    my (@Entries,%Cookies);
    for (1..51) {
        my $R=$L->search(%P,control=>[$Page],timelimit=>30);
        die "Directory search incomplete.\n" if $R->code || $R->references;
        push @Entries,$R->entries;
        die "Directory search limit exceeded.\n" if @Entries>10000;
        my ($Control)=$R->control('1.2.840.113556.1.4.319');
        die "Directory pagination not confirmed.\n" if !$Control;
        my $Cookie=$Control->cookie;
        return \@Entries if !length($Cookie || '');
        die "Directory pagination stalled.\n" if $Cookies{$Cookie}++;
        $Page->cookie($Cookie);
    }
    die "Directory pagination limit exceeded.\n";
}
sub Groups {
    my ($S,$C,$Password)=@_;
    my $L=$S->Connect($C,$Password);
    my $Entries=eval {$S->_Search($L,base=>$C->{GroupBase},scope=>'sub',filter=>'(&(objectClass=group)'.$C->{GroupFilter}.')',attrs=>[qw(objectGUID cn distinguishedName)])};
    my $E=$@; $L->unbind; die $E if $E;
    my (@Groups,%Seen);
    for my $G (@$Entries) {
        my $Raw=$G->get_value('objectGUID');
        die "Group identity missing.\n" if !defined $Raw || length($Raw)!=16;
        my $ID=unpack('H*',$Raw);
        die "Duplicate group identity.\n" if $Seen{$ID}++;
        my $Name=$G->get_value('cn');
        die "Group name unavailable or too long.\n" if !defined $Name || !length($Name) || length($Name)>200;
        push @Groups,{GUID=>$ID,Name=>$Name,DN=>$G->dn};
    }
    return \@Groups;
}
sub Members {
    my ($S,$C,$Password,$G)=@_;
    require Net::LDAP::Util;
    my $DN=Net::LDAP::Util::escape_filter_value($G->{DN});
    my $Member=$C->{Nested} ? '(memberOf:1.2.840.113556.1.4.1941:='.$DN.')' : '(memberOf='.$DN.')';
    my $Filter='(&(objectCategory=person)(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2))'.$Member.')';
    my $L=$S->Connect($C,$Password);
    my $Entries=eval {$S->_Search($L,base=>$C->{UserBase},scope=>'sub',filter=>$Filter,attrs=>[$C->{LoginAttribute},qw(objectGUID givenName sn mail)])};
    my $E=$@; $L->unbind; die $E if $E;
    my (@Users,%Logins);
    for my $U (@$Entries) {
        my $Login=$U->get_value($C->{LoginAttribute});
        my $GUID=$U->get_value('objectGUID');
        die "Directory account incomplete or ambiguous.\n" if !defined $Login || !length($Login) || length($Login)>200
            || !defined $GUID || length($GUID)!=16 || $Logins{lc $Login}++;
        push @Users,{GUID=>unpack('H*',$GUID),Login=>$Login,Firstname=>$U->get_value('givenName'),Lastname=>$U->get_value('sn'),Email=>$U->get_value('mail')};
    }
    return \@Users;
}
sub Authenticate {
    my ($S,$C,$Password,$Login,$PW)=@_;
    return if !defined $PW || !length($PW);
    require Net::LDAP::Util;
    my $L=$S->Connect($C,$Password);
    my $R=$L->search(base=>$C->{UserBase},scope=>'sub',filter=>'(&(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2))('.$C->{LoginAttribute}.'='.Net::LDAP::Util::escape_filter_value($Login).'))',attrs=>[$C->{LoginAttribute}],sizelimit=>2,timelimit=>15);
    my $OK;
    if (!$R->code && !$R->references && $R->count==1) {
        my ($U)=$R->entries;
        my $B=$L->bind($U->dn,password=>$PW);
        $OK=1 if !$B->code;
    }
    $L->unbind;
    return $OK;
}
1;
