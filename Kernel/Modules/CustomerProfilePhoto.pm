package Kernel::Modules::CustomerProfilePhoto;
use strict;use warnings;
our $ObjectManagerDisabled=1;
sub new {my($T,%P)=@_;bless \%P,$T}
sub Run {my($S,%P)=@_;my $L=$Kernel::OM->Get('Kernel::Output::HTML::Layout');my $User=$S->{UserLogin}||$S->{UserID};return $L->CustomerNoPermission(WithHeader=>'yes') if !$User;
 my $PNG=$Kernel::OM->Get('Kernel::System::TESSERA::CustomerProfilePhoto')->Read(User=>$User);
 return $L->Attachment(Content=>$PNG,ContentType=>'image/png',Type=>'inline',NoCache=>1,Filename=>'profile.png') if $PNG;
 my %U=$Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerUserDataGet(User=>$User);my $Initials=uc(substr($U{UserFirstname}||'',0,1).substr($U{UserLastname}||'',0,1));$Initials='?' if !$Initials;$Initials=~s/&/&amp;/g;$Initials=~s/</&lt;/g;$Initials=~s/>/&gt;/g;
 my $SVG='<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><circle cx="64" cy="64" r="64" fill="#f7f7f9"/><text x="64" y="66" text-anchor="middle" dominant-baseline="middle" font-family="Arial,sans-serif" font-size="48" fill="#8584ad">'.$Initials.'</text></svg>';
 return $L->Attachment(Content=>$SVG,ContentType=>'image/svg+xml',Type=>'inline',NoCache=>1,Filename=>'initials.svg');}
1;
