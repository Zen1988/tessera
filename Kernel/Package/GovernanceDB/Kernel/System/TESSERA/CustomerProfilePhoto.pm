package Kernel::System::TESSERA::CustomerProfilePhoto;
use strict;use warnings;use Digest::SHA qw(sha256_hex);
our @ObjectDependencies=('Kernel::System::CustomerUser','Kernel::System::VirtualFS');
sub new {bless {},shift}
sub _PathValid {my($S,$User,$Path)=@_;return $Path && $Path =~ m{\A/TESSERA/ProfilePhoto/\Q@{[sha256_hex($User)]}\E/[a-f0-9]{64}\.png\z};}
sub Read {
 my($S,%P)=@_;return if !$P{User};my %Pref=$Kernel::OM->Get('Kernel::System::CustomerUser')->GetPreferences(UserID=>$P{User});my $Path=$Pref{TESSERAProfilePhoto};return if !$S->_PathValid($P{User},$Path);
 my %F=$Kernel::OM->Get('Kernel::System::VirtualFS')->Read(Filename=>$Path,Mode=>'binary',DisableWarnings=>1);return $F{Content}?${$F{Content}}:undef;
}
sub _Dimensions {
 my($S,$B)=@_;return (unpack('NN',substr($B,16,8)),'PNG') if length($B)>=24 && substr($B,0,8) eq "\x89PNG\r\n\x1a\n" && substr($B,12,4) eq 'IHDR';
 return if substr($B,0,2) ne "\xff\xd8";my $I=2;
 while($I+4<=length($B)) {return if ord(substr($B,$I++,1))!=255; $I++ while $I<length($B) && ord(substr($B,$I,1))==255;my $M=ord(substr($B,$I++,1));return if $M==0xda||$M==0xd9;next if $M==0x01||($M>=0xd0&&$M<=0xd7);my $N=unpack('n',substr($B,$I,2));return if $N<2||$I+$N>length($B);if($M==0xc0||$M==0xc1||$M==0xc2){return if $N<8;my($H,$W)=unpack('nn',substr($B,$I+3,4));return($W,$H,'JPEG');}$I+=$N;}
 return;
}
sub Save {
 my($S,%P)=@_;$S->{Error}='';return if !$P{User};my $B=$P{Content}||'';
 if(length($B)>10*1024*1024){$S->{Error}='Choose an image smaller than 10 MB.';return;}
 my($W,$H,$Type)=$S->_Dimensions($B);if(!$W||!$H||$W>8192||$H>8192||$W*$H>32000000){$S->{Error}='Choose a valid JPEG or PNG image up to 32 megapixels.';return;}
 if(!eval {require GD;1}){$S->{Error}='Profile photo resizing requires the GD image module on the server.';return;}
 my $Source=eval {$Type eq 'PNG'?GD::Image->newFromPngData($B,1):GD::Image->newFromJpegData($B,1)};
 if(!$Source){$S->{Error}='The image could not be decoded. Choose another JPEG or PNG.';return;}
 my $Out=GD::Image->newTrueColor(128,128);$Out->alphaBlending(0);$Out->saveAlpha(1);my $Clear=$Out->colorAllocateAlpha(255,255,255,127);$Out->filledRectangle(0,0,127,127,$Clear);
 my $Side=$W<$H?$W:$H;$Out->copyResampled($Source,0,0,int(($W-$Side)/2),int(($H-$Side)/2),128,128,$Side,$Side);my $PNG=$Out->png;
 my $User=$Kernel::OM->Get('Kernel::System::CustomerUser');my %Pref=$User->GetPreferences(UserID=>$P{User});my $Old=$Pref{TESSERAProfilePhoto};my $Path='/TESSERA/ProfilePhoto/'.sha256_hex($P{User}).'/'.sha256_hex($PNG).'.png';my $FS=$Kernel::OM->Get('Kernel::System::VirtualFS');my %Existing=$FS->Read(Filename=>$Path,Mode=>'binary',DisableWarnings=>1);
 if(!$Existing{Content}&&!$FS->Write(Filename=>$Path,Mode=>'binary',Content=>\$PNG,Preferences=>{ContentType=>'image/png'})){$S->{Error}='The profile photo could not be stored.';return;}
 if(!$User->SetPreferences(UserID=>$P{User},Key=>'TESSERAProfilePhoto',Value=>$Path)){$FS->Delete(Filename=>$Path) if !$Existing{Content};$S->{Error}='The profile photo could not be saved to your account.';return;}
 $FS->Delete(Filename=>$Old) if $Old && $Old ne $Path && $S->_PathValid($P{User},$Old);return 1;
}
sub Remove {my($S,%P)=@_;return if !$P{User};my $U=$Kernel::OM->Get('Kernel::System::CustomerUser');my %Pref=$U->GetPreferences(UserID=>$P{User});return if !$U->SetPreferences(UserID=>$P{User},Key=>'TESSERAProfilePhoto',Value=>'');$Kernel::OM->Get('Kernel::System::VirtualFS')->Delete(Filename=>$Pref{TESSERAProfilePhoto}) if $S->_PathValid($P{User},$Pref{TESSERAProfilePhoto});return 1;}
sub Error {$_[0]{Error}||'The profile photo could not be updated.'}
1;
