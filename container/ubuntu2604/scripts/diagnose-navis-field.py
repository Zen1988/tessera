#!/usr/bin/env python3
"""Read bounded Navis field metadata and release state; never repair or rerun hooks."""
import importlib.util
from pathlib import Path

FIELD_METADATA = '    # Direct DB metadata avoids stale external DynamicField caches. No values/config dump.\n    $Stage=\'navis-field-metadata\';\n    my $FieldDB=$Kernel::OM->Get(\'Kernel::System::DB\');\n    die "Navis field metadata unavailable.\\n" if !$FieldDB->Prepare(SQL=>q{SELECT id, name, field_type, object_type, valid_id, config FROM dynamic_field WHERE name = ?},Bind=>[\\(my $FieldName=\'Navis\')]);\n    my @FieldRows;\n    while (my @R=$FieldDB->FetchrowArray()) {push @FieldRows,\\@R}\n    print \'navis_field_rows=\',scalar @FieldRows,"\\n";\n    for my $Row (@FieldRows) {\n        my @Safe=map {defined $_ && !ref $_ && /\\A[A-Za-z0-9_:.-]{1,100}\\z/ ? $_ : \'invalid\'} @$Row[0..4];\n        print \'navis_field=\',join(\',\',@Safe),"\\n";\n        my $Config=eval {$Kernel::OM->Get(\'Kernel::System::YAML\')->Load(Data=>$Row->[5])};\n        print \'navis_field_config_hash=\',ref $Config eq \'HASH\'?\'yes\':\'no\',"\\n";\n        my $Multi=ref $Config eq \'HASH\'?$Config->{MultiValue}:undef;\n        print \'navis_field_multivalue=\',!defined $Multi?\'absent\':ref $Multi?\'reference\':$Multi eq \'\'?\'empty\':$Multi=~/\\A[01]\\z/?$Multi:\'other\',"\\n";\n    }\n'

def load_diagnostic():
    source=Path(__file__).with_name('diagnose-release.py')
    spec=importlib.util.spec_from_file_location('tessera_release_diagnostic',source)
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    marker="    $Stage='package-registry';"
    if module.PERL.count(marker)!=1:raise ValueError('Matching release diagnostic is required')
    module.PERL=module.PERL.replace(marker,FIELD_METADATA+marker)
    return module

if __name__=='__main__':load_diagnostic().main()
