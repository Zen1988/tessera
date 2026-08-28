# --
# Kernel/System/TESSERA/PolicyEngine.pm
# --
# Compatibility facade. New TESSERA English YAML scripts should use
# Kernel::System::TESSERA::ScriptEngine directly.

package Kernel::System::TESSERA::PolicyEngine;

use strict;
use warnings;

use parent qw(Kernel::System::TESSERA::ScriptEngine);

# ObjectManager validates dependencies on the concrete requested class rather
# than inheriting this declaration from ScriptEngine.
our @ObjectDependencies = (
    'Kernel::System::DateTime',
    'Kernel::System::GovernanceObject',
    'Kernel::System::ITSMConfigItem',
    'Kernel::System::Ticket',
    'Kernel::System::YAML',
);

1;
