package TESSERA::Navis017Recovery;
use strict;use warnings;use JSON::PP ();use Storable qw(dclone);
our $Hash='cf6c345ef2b4f6a7638964b2fdd068e8625e6e83954e1c57176c0108393425c6';
sub Validate {
 my ($P)=@_;my $S=$P->{State};my $M=$P->{Meta};
 die "Exact0.1.7 image required.\n" if ref $M ne 'HASH' || ($M->{version} || '') ne '0.1.7' || ($M->{package_sha256} || '') ne $Hash;
 die "Exact reviewed UPGRADING receipt required.\n" if ref $S ne 'HASH' || ($S->{phase} || '') ne 'UPGRADING' || ($S->{version} || '') ne '0.1.7'
  || ($S->{from} || '') ne '0.1.3' || ($S->{hash} || '') ne $Hash || exists $S->{recovery};
 die "Installed artifact differs.\n" if ($P->{Version} || '') ne '0.1.7' || ($P->{Hash} || '') ne $Hash;
 my $J=$P->{Journals};die "One exact Base journal required.\n" if ref $J ne 'ARRAY' || @$J!=1 || $J->[0][0] ne 'TESSERA::PackageUpgrade::TESSERA-Base';
 my $D=eval {JSON::PP->new->decode($J->[0][1])};
 die "Package journal differs.\n" if ref $D ne 'HASH' || keys(%$D)!=3 || ($D->{phase} || '') ne 'UPGRADING' || ($D->{version} || '') ne '0.1.7' || ($D->{hash} || '') ne $Hash;
 die "Expected missing Navis field.\n" if !defined $P->{FieldCount} || $P->{FieldCount}!=0;
 return 1;
}
sub Run {
 my ($Class,%P)=@_;my $G=$P{Gate};my $Raw=$G->_Read();my $State=$G->_Decode($Raw);my $J=dclone($P{Journals}->());
 Validate({Meta=>$P{Meta},State=>$State,Version=>$G->_Version(),Hash=>$G->_InstalledHash('0.1.7'),Journals=>$J,FieldCount=>$P{FieldCount}->()});
 die "Inventory preflight failed.\n" if !$P{Verify}->();die "Cache preflight failed.\n" if !$P{Probe}->(); # No release/journal mutation before complete preflight.
 $State->{owner}=$P{Owner};$State->{recovery}='navis017-bootstrap';
 my $Owned=$G->_Write($Raw,$G->_Encode($State));
 my $Check=sub {die "Recovery ownership changed.\n" if $G->_Read() ne $Owned; die "Inventory changed.\n" if !$P{Verify}->()};
 $Check->();die "Post hook failed.\n" if !$P{Hook}->();$Check->();
 my $Now=$P{Journals}->();die "Package journals changed during recovery.\n" if JSON::PP->new->canonical->encode($Now) ne JSON::PP->new->canonical->encode($J);
 die "Journal CAS failed.\n" if !$P{DropJournal}->(@{$J->[0]}); # Exact raw-value CAS only after verified post-hook completion.
 die "Journal removal verification failed.\n" if @{$P{Journals}->()};
 $Check->();$State->{phase}='CONFIGURING';$Owned=$G->_Write($Owned,$G->_Encode($State));
 $G->Run(Version=>'0.1.7',Hash=>$Hash,FromVersions=>['0.1.3'],ResumeConfig=>1,
  Upgrade=>sub {die "Native package replay prohibited.\n"},Configure=>sub {die "Final inventory failed.\n" if !$P{VerifyReady}->();$P{Configure}->()});
 $G->Check(Version=>'0.1.7',Hash=>$Hash);return 1;
}
sub Journals {my ($DB)=@_;die "Journal unavailable.\n" if !$DB->Prepare(SQL=>q{SELECT data_key,data_value FROM system_data WHERE data_key LIKE 'TESSERA::PackageUpgrade::%' ORDER BY data_key});my @R;while(my @A=$DB->FetchrowArray()){push @R,[@A]}return \@R}
sub VerifyInventory {my ($Inventory,$DB,$HashRead)=@_;
  die "Invalid package inventory.\n" if ($Inventory->{schema} || 0)!=1 || ref $Inventory->{packages} ne 'ARRAY';
  my %Expected;for my $P (@{$Inventory->{packages}}){die "Ambiguous package inventory.\n" if $Expected{$P->{name}}++;}
  die "Registry unavailable.\n" if !$DB->Prepare(SQL=>q{SELECT name,version FROM package_repository WHERE install_status = ? ORDER BY name,version},Bind=>[\(my $Status='installed')]);
  my (%Rows,@Rows);while(my @R=$DB->FetchrowArray()){die "Duplicate package.\n" if $Rows{$R[0]}++;push @Rows,[@R]}
  die "Package inventory differs.\n" if @Rows!=@{$Inventory->{packages}} || grep {!$Expected{$_->[0]}} @Rows;
  my %Version=map {@$_} @Rows;
  for my $P (@{$Inventory->{packages}}){die "Package artifact differs.\n" if ($Version{$P->{name}} || '') ne $P->{version} || $HashRead->($DB,$P->{name},$P->{version}) ne $P->{package_sha256}}
  return 1;
}
sub CompleteHook {my ($Package,$Structure,$OM)=@_;
   $Package->_Code(Code=>$Structure->{CodeUpgrade},Type=>'post',Structure=>$Structure) or die "Post hook failed.\n";
   my $F=$OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(Name=>'Navis');
   die "Navis field verification failed.\n" if ref $F ne 'HASH' || ($F->{Name} || '') ne 'Navis' || ($F->{ObjectType} || '') ne 'GovernanceObject' || ($F->{FieldType} || '') ne 'Text' || ($F->{ValidID} || 0)!=1 || $F->{Config}{MultiValue};
   $OM->Get('Kernel::System::Cache')->CleanUp(KeepTypes=>[qw(XMLParse SysConfigDefaultListGet SysConfigDefaultList SysConfigDefault SysConfigPersistent SysConfigModifiedList)]);
   $OM->Get('Kernel::System::Loader')->CacheDelete();
   $Package->EventHandler(Event=>'PackageUpgrade',Data=>{Name=>'TESSERA-Base',Vendor=>$Structure->{Vendor}{Content},Version=>'0.1.7'},UserID=>1);
 return 1;
}
sub FieldCount {my ($DB)=@_;die if !$DB->Prepare(SQL=>q{SELECT COUNT(*) FROM dynamic_field WHERE name = ?},Bind=>[\(my $Name='Navis')]);my @R=$DB->FetchrowArray();return $R[0]}
1;
