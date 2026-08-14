use strict;
use warnings;
use Test::More;

BEGIN {
    package Local::ForbiddenOM;
    sub Get { die 'Object manager must not be used for GovernanceObjectDelete' }
}

use lib 'Kernel/Package/GovernanceDB', '.';
use Kernel::System::GovernanceObject::Event::EvaluateScriptFields;

$Kernel::OM = bless {}, 'Local::ForbiddenOM';
my $Handler = Kernel::System::GovernanceObject::Event::EvaluateScriptFields->new();

is(
    $Handler->Run(
        Data  => { GovernanceObjectID => 248 },
        Event => 'GovernanceObjectDelete',
    ),
    1,
    'deleted GovernanceObject exits before reload, evaluation, or ValueSet',
);

done_testing;
