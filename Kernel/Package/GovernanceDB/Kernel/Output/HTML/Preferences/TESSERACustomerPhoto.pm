package Kernel::Output::HTML::Preferences::TESSERACustomerPhoto;
use strict;use warnings;
our $ObjectManagerDisabled=1;
sub new {my($T,%P)=@_;return bless \%P,$T;}
sub Param {
 my($S,%P)=@_;return if !$P{UserData}{UserLogin};my $Base=$Kernel::OM->Get('Kernel::Output::HTML::Layout')->{Baselink};$Base=$Kernel::OM->Get('Kernel::Output::HTML::Layout')->Ascii2Html(Text=>$Base);
 return ({Name=>'ProfilePhotoPreview',Key=>'Current photo',Block=>'Option',Option=>'<img class="TESSERAProfilePhotoPreview" width="64" height="64" alt="Current profile photo" src="'.$Base.'Action=CustomerProfilePhoto"/><p>JPEG or PNG, up to 10 MB / 32 megapixels. Saved as a 128 x 128 square.</p>'},{Name=>'ProfilePhotoUpload',Key=>'Upload photo',Block=>'Option',Option=>'<input type="file" id="ProfilePhotoUpload" name="ProfilePhotoUpload" accept="image/jpeg,image/png"/>'},{Name=>'ProfilePhotoRemove',Key=>'Use initials',Block=>'Option',Option=>'<label class="TESSERAProfilePhotoRemove"><input type="checkbox" id="ProfilePhotoRemove" name="ProfilePhotoRemove" value="1"/> Remove my profile photo</label>'});
}
sub Run {my($S,%P)=@_;my $User=$S->{UserLogin}||$S->{UserID};my $Request=$Kernel::OM->Get('Kernel::System::Web::Request');my $Photo=$Kernel::OM->Get('Kernel::System::TESSERA::CustomerProfilePhoto');my $OK;
 if(($Request->GetParam(Param=>'ProfilePhotoRemove')||'') eq '1'){$OK=$Photo->Remove(User=>$User);}else{my %Upload=$Request->GetUploadAll(Param=>'ProfilePhotoUpload');return 1 if !$Upload{Content};$OK=$Photo->Save(User=>$User,Content=>$Upload{Content});}
 if(!$OK){$S->{Error}=$Photo->Error;return;}$S->{Message}='Profile photo updated.';return 1;}
sub Message {$_[0]{Message}||''}sub Error {$_[0]{Error}||''}
1;
