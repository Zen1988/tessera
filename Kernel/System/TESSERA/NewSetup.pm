package Kernel::System::TESSERA::NewSetup;
use strict;
use warnings;
use Digest::SHA qw(sha256_hex);
our @ObjectDependencies = qw(Kernel::System::Group Kernel::System::DB Kernel::System::JSON Kernel::System::GeneralCatalog Kernel::System::GovernanceObject Kernel::System::HTMLUtils);
sub new { bless {}, $_[0] }

sub Authorized {
    my ($Self, %P) = @_;
    return if !$P{UserID};
    return $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
        UserID=>$P{UserID}, GroupName=>'admin', Type=>'rw',
    );
}

sub Progress {
    my ($Self, %P) = @_;
    die "New setup requires administrator access.\n" if !$Self->Authorized(%P);
    return $Self->_Read();
}

sub _Read {
    my ($Self, %P) = @_;
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Cannot read setup progress.\n" if !$DB->Prepare(
        SQL=>'SELECT state_data FROM tessera_setup_state WHERE id = 1' . ($P{Lock} ? ' FOR UPDATE' : ''),
    );
    my @Row=$DB->FetchrowArray();
    die "Setup storage is not initialized.\n" if !@Row;
    my $State=$Kernel::OM->Get('Kernel::System::JSON')->Decode(Data=>$Row[0]);
    die "Setup progress is invalid.\n" if ref $State ne 'HASH' || ref $State->{Organizations} ne 'ARRAY';
    return $State;
}

sub _CatalogID {
    my ($Self, $Class, $Name)=@_;
    my $List=$Kernel::OM->Get('Kernel::System::GeneralCatalog')->ItemList(Class=>$Class);
    my @IDs=grep { $List->{$_} eq $Name } keys %{$List || {}};
    die "Required setup class or status is missing or ambiguous.\n" if @IDs != 1;
    return $IDs[0];
}

sub SaveOrganization {
    my ($Self,%P)=@_;
    die "New setup requires administrator access.\n" if !$Self->Authorized(%P);
    die "Invalid organization details.\n" if grep {ref $P{$_}} qw(Name Description RequestKey);
    my $Name=$P{Name} // '';
    $Name =~ s/\A\s+|\s+\z//g;
    my $Description=$P{Description} // '';
    die "Enter an organization name (up to 200 characters).\n" if $Name eq '' || length($Name)>200 || $Name =~ /[\x00-\x1f]/;
    die "Description must be no more than 20000 characters.\n" if length($Description)>20000 || $Description =~ /\x00/;
    die "Invalid setup submission.\n" if ($P{RequestKey} || '') !~ /\A[A-Za-z0-9]{32}\z/;
    my $Key=sha256_hex($P{UserID}.':'.$P{RequestKey});
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Cannot begin setup operation.\n" if !$DB->BeginWork();
    my ($ID,$Failure);
    eval {
        my $State=$Self->_Read(Lock=>1);
        my ($Saved)=grep {$_->{RequestKey} eq $Key} @{$State->{Organizations}};
        if ($Saved) {
            die "This submission was already used for different details.\n" if $Saved->{Name} ne $Name || $Saved->{Description} ne $Description;
            $ID=$Saved->{ID};
        }
        else {
            die "Organization setup is already complete.\n" if $State->{Completed};
            die "This organization name was already added in setup.\n" if grep {lc($_->{Name}) eq lc($Name)} @{$State->{Organizations}};
            my $ClassID=$Self->_CatalogID('ZTSM::GovernanceObject::Class','Organization');
            my $StatusID=$Self->_CatalogID('ZTSM::GovernanceObject::Status','Active');
            my $Objects=$Kernel::OM->Get('Kernel::System::GovernanceObject');
            my $Existing=$Objects->GovernanceObjectSearch(ClassIDs=>[$ClassID],NameExact=>$Name,Result=>'ARRAY',Limit=>2);
            die "Cannot check existing organizations.\n" if ref $Existing ne 'ARRAY';
            die "An organization with this name already exists.\n" if @{$Existing};
            my $HTMLDescription=$Kernel::OM->Get('Kernel::System::HTMLUtils')->ToHTML(String=>$Description);
            die "Cannot prepare organization description.\n" if !defined $HTMLDescription;
            $ID=$Objects->GovernanceObjectAdd(
                ClassID=>$ClassID, Name=>$Name, Description=>$HTMLDescription, ZTSMStatusID=>$StatusID, UserID=>$P{UserID},
            );
            die "Could not create the organization.\n" if !$ID;
            push @{$State->{Organizations}}, {ID=>$ID, Name=>$Name, Description=>$Description, RequestKey=>$Key, UserID=>$P{UserID}};
            $Self->_Write($State);
        }
        die "Cannot commit setup operation.\n" if !$DB->{dbh}->commit();
        1;
    } or $Failure=$@ || "Setup operation failed.\n";
    if ($Failure) { $DB->Rollback(); die $Failure; }
    return $ID;
}

sub Complete {
    my ($Self,%P)=@_;
    die "New setup requires administrator access.\n" if !$Self->Authorized(%P);
    my $DB=$Kernel::OM->Get('Kernel::System::DB');
    die "Cannot begin setup operation.\n" if !$DB->BeginWork();
    my $Failure;
    eval {
        my $State=$Self->_Read(Lock=>1);
        die "Create at least one organization first.\n" if !@{$State->{Organizations}};
        if (!$State->{Completed}) { $State->{Completed}=1; $State->{CompletedBy}=$P{UserID}; $Self->_Write($State); }
        die "Cannot commit setup operation.\n" if !$DB->{dbh}->commit();
        1;
    } or $Failure=$@ || "Setup operation failed.\n";
    if ($Failure) { $DB->Rollback(); die $Failure; }
    return 1;
}

sub _Write {
    my ($Self,$State)=@_;
    my $Data=$Kernel::OM->Get('Kernel::System::JSON')->Encode(Data=>$State);
    die "Cannot serialize setup progress.\n" if !defined $Data;
    die "Cannot save setup progress.\n" if !$Kernel::OM->Get('Kernel::System::DB')->Do(
        SQL=>'UPDATE tessera_setup_state SET state_data = ? WHERE id = 1', Bind=>[\$Data],
    );
}
1;
