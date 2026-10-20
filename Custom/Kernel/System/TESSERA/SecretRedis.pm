package Kernel::System::TESSERA::SecretRedis;

use strict;
use warnings;
use Encode qw(encode);
use Kernel::System::TESSERA::Secrets ();

our @ObjectDependencies = qw(Kernel::Config Kernel::System::Main Kernel::System::Storable);

sub new {
    my ($Type) = @_;
    my $Config = $Kernel::OM->Get('Kernel::Config')->Get('Cache::Redis') || {};
    die "TESSERA Redis: PasswordSecret is required\n" if !$Config->{PasswordSecret};
    return bless { Config => { %{$Config} } }, $Type;
}

sub _Client {
    my ($Self) = @_;
    my $Password = Kernel::System::TESSERA::Secrets::Read( $Self->{Config}{PasswordSecret} );
    # Keep credentials only as required by the active authenticated connection.
    # Read the file on every backend operation; replace only between operations.
    return $Self->{Redis} if $Self->{Redis} && $Self->{Password} eq $Password;
    delete $Self->{Redis};
    delete $Self->{Password};
    my $Class = $Self->{Config}{RedisFast} ? 'Redis::Fast' : 'Redis';
    die "TESSERA Redis: client unavailable\n"
        if !$Kernel::OM->Get('Kernel::System::Main')->Require($Class);
    my $Client;
    my $OK = eval {
        $Client = $Class->new(
            server   => $Self->{Config}{Server} || '127.0.0.1:6379',
            password => $Password,
        );
        $Client->ping(); # force authentication now, including lazy clients
        $Client->select( $Self->{Config}{DatabaseNumber} || 0 );
        1;
    };
    die "TESSERA Redis: connection or authentication failed\n" if !$OK;
    $Self->{Password} = $Password;
    return $Self->{Redis} = $Client;
}

sub _Run {
    my ( $Self, $Code ) = @_;
    my $Result;
    my $OK = eval { $Result = $Code->( $Self->_Client() ); 1 };
    if (!$OK) {
        delete $Self->{Redis};
        delete $Self->{Password};
        # Do not expose client exceptions (AUTH arguments may be present).
        # Do not replay writes after an ambiguous network failure.
        die "TESSERA Redis: secret or cache operation failed\n";
    }
    return $Result;
}

sub Set {
    my ( $Self, %P ) = @_;
    return if grep { !defined $P{$_} } qw(Type Key Value TTL);
    my $Data = $Kernel::OM->Get('Kernel::System::Storable')->Serialize( Data => { _Data => $P{Value} } );
    return $Self->_Run(sub {
        my ($R) = @_;
        $R->sadd( 'namespaces', $P{Type} );
        $R->set( encode( 'UTF-8', "$P{Type}:$P{Key}" ), $Data, 'EX', $P{TTL} );
        return 1;
    });
}

sub Get {
    my ( $Self, %P ) = @_;
    return if grep { !defined $P{$_} } qw(Type Key);
    my $Value = $Self->_Run(sub { $_[0]->get( encode( 'UTF-8', "$P{Type}:$P{Key}" ) ) });
    return if !$Value;
    my $Data = $Kernel::OM->Get('Kernel::System::Storable')->Deserialize( Data => $Value );
    return $Data->{_Data};
}

sub Delete {
    my ( $Self, %P ) = @_;
    return if grep { !defined $P{$_} } qw(Type Key);
    return !!$Self->_Run(sub { $_[0]->del( encode( 'UTF-8', "$P{Type}:$P{Key}" ) ) });
}

sub CleanUp {
    my ( $Self, %P ) = @_;
    return 1 if $P{Expired};
    my %Keep = ref $P{KeepTypes} eq 'ARRAY' ? map { $_ => 1 } @{ $P{KeepTypes} } : ();
    return $Self->_Run(sub {
        my ($R) = @_;
        if ( !$P{Type} && !%Keep ) { $R->flushdb(); return 1 }
        my @Types = $P{Type} ? ( $P{Type} ) : grep { !$Keep{$_} } $R->smembers('namespaces');
        for my $Type (@Types) {
            # Escape Redis glob metacharacters in an exact namespace.
            ( my $Pattern = $Type ) =~ s/([\\*?\[\]])/\\$1/g;
            my $Cursor = 0;
            do {
                my $Keys;
                ( $Cursor, $Keys ) = $R->scan( $Cursor, MATCH => "$Pattern:*" );
                $R->del( @{$Keys} ) if @{$Keys};
            } while ($Cursor);
        }
        return 1;
    });
}

1;
