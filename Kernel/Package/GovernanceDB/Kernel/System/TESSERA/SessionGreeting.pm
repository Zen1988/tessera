package Kernel::System::TESSERA::SessionGreeting;
use strict; use warnings;
use Digest::SHA qw(sha256_hex);
our @ObjectDependencies=('Kernel::System::AuthSession','Kernel::System::JSON','Kernel::System::Web::Request');
sub new {bless {},shift}
sub CompletionToken {
 my($S,%P)=@_;return if !$P{SessionID} || !$P{UserLogin};
 return sha256_hex(join("\0",'TESSERA greeting',$P{SessionID},$P{UserLogin}));
}
sub Read {
 my($S,%P)=@_;return {} if !$P{SessionID} || !$P{UserLogin};
 my %Session=$Kernel::OM->Get('Kernel::System::AuthSession')->GetSessionIDData(SessionID=>$P{SessionID});
 return {} if ($Session{UserLogin}||'') ne $P{UserLogin};
 my $D=eval {$Kernel::OM->Get('Kernel::System::JSON')->Decode(Data=>$Session{TESSERASessionGreeting}||'{}')};
 return $D if ref $D eq 'HASH' && $D->{Message};
 # The response cookie reaches the browser before it can navigate away. It
 # contains only a session-bound dismissal marker, never the mood or message.
 my $Cookie=$Kernel::OM->Get('Kernel::System::Web::Request')->GetCookie(Key=>'TESSERAGreeting');
 return {Completed=>1} if defined $Cookie && $Cookie eq $S->CompletionToken(%P);
 return {};
}
sub Select {
 my($S,%P)=@_;return if !defined $P{Mood} || $P{Mood}!~/\A[1-5]\z/;
 return if !$P{SessionID} || !$P{UserLogin};
 my %Session=$Kernel::OM->Get('Kernel::System::AuthSession')->GetSessionIDData(SessionID=>$P{SessionID});
 return if ($Session{UserLogin}||'') ne $P{UserLogin};
 my $Existing=$S->Read(%P);return $Existing if $Existing->{Message};
 my @Messages=$P{Mood}>=4 ? (
 'Great to have you back.', 'Good to see you today.', 'Nice - let\'s make it a good one.',
 'Hope that good feeling stays with you.', 'A little good energy goes a long way.',
 'Here\'s to a good day, one step at a time.', 'Glad you\'re feeling good today.',
 'Bring that good mood along - no need to rush.'
 ) : $P{Mood}==3 ? (
 'No worries. Let\'s do our best today.', 'One thing at a time.', 'Let\'s make today manageable.',
 'Start where you are. Small steps count.', 'You don\'t have to do everything at once.',
 'A steady pace is enough.', 'Let\'s ease into the day.', 'Take a moment, then take the next step.'
 ) : (
 'Rough day? Talk to someone you trust.', 'Maybe check in with a peer, lead, or manager.',
 'Take care of yourself today - you don\'t have to handle everything alone.',
 'It\'s okay to ask for a little support.', 'A short pause might help. Be kind to yourself.',
 'You don\'t have to figure everything out right now.', 'If you can, reach out to someone who listens.',
 'Take today one small step at a time.'
 );
 my $D={Mood=>0+$P{Mood},Message=>$Messages[int(rand(@Messages))]};
 return if !$Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(SessionID=>$P{SessionID},Key=>'TESSERASessionGreeting',Value=>$Kernel::OM->Get('Kernel::System::JSON')->Encode(Data=>$D));
 return $D;
}
1;
