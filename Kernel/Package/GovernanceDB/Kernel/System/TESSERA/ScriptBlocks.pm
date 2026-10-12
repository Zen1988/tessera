package Kernel::System::TESSERA::ScriptBlocks;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(BlockSpec Assemble ObjectSource SplitSource NormalizeImportFields);

# Exact names from the 2026-10-12 Dynamic Field export.
my %Spec = (
    AdvancedCondition     => ['ZTAM-ConditionIndex', 'ZTAM-AdvancedCondition'],
    FieldAsssignment      => ['ZTemplate-ScriptIndex', 'ZRM-FieldAssignment'],
    MasterTicket          => ['ZTemplate-ScriptIndex', 'ZRM-MasterTicket'],
    PolicyEvaluation      => ['ZTemplate-ScriptIndex', 'ZRM-PolicyEvaluation'],
    PolicyFilter          => ['ZTemplate-ScriptIndex', 'ZRM-PolicyFilter'],
    RiskAggregationEngine => ['ZTemplate-ScriptIndex', 'ZRM-RiskAggregationEngine'],
    RiskScoringEngine     => ['ZTemplate-ScriptIndex', 'ZRM-RiskScoringEngine'],
    ScriptEngine          => ['ZTemplate-ScriptIndex', 'ZTSM-ScriptEngine'],
    'ZTemplate-AutomationScript' => ['ZTemplate-ScriptIndex', 'ZTemplate-ScriptBlock'],
);

sub BlockSpec { return $Spec{$_[0]} }

sub _Scalar {
    my ($Value) = @_;
    return undef if ref $Value eq 'ARRAY' && !@{$Value};
    $Value = $Value->[0] if ref $Value eq 'ARRAY' && @{$Value} == 1;
    die "Script block members must be single scalar values.\n" if ref $Value;
    return $Value;
}

sub Assemble {
    my (%Param) = @_;
    my $Spec = BlockSpec($Param{Field});
    die "Unknown script block field.\n" if !$Spec;
    my $Rows = $Param{Rows};
    return '' if !defined $Rows;
    die "Script blocks must be a list.\n" if ref $Rows ne 'ARRAY';
    die "Too many script blocks.\n" if @{$Rows} > 99;
    my ($IndexField, $TextField) = @{$Spec};
    my (%Blocks, $Length);
    for my $Row (@{$Rows}) {
        die "Script block must be a mapping.\n" if ref $Row ne 'HASH';
        my $Index = _Scalar($Row->{$IndexField});
        my $Text = _Scalar($Row->{$TextField});
        # An entirely empty optional widget is not an executable block.
        next if (!defined $Index || $Index eq '') && (!defined $Text || $Text eq '');
        die "Script block index must be a positive integer.\n"
            if !defined $Index || $Index !~ /\A[1-9][0-9]*\z/ || length($Index) > 2;
        die "Duplicate script block index $Index.\n" if exists $Blocks{$Index};
        die "Script block $Index requires content.\n" if !defined $Text || $Text eq '';
        die "Script block $Index exceeds 3800 characters.\n" if length($Text) > 3800;
        $Length += length($Text);
        die "Combined script exceeds 376200 characters.\n" if $Length > 376200;
        $Blocks{$Index} = $Text;
    }
    my @Order = sort { $a <=> $b } keys %Blocks;
    for my $Position (0 .. $#Order) {
        die "Script block indices must be consecutive from 1.\n" if $Order[$Position] != $Position + 1;
    }
    # Exact concatenation: whitespace, multiline scalars and anchors may cross
    # storage boundaries. Parse the entire document once, never each fragment.
    return join '', @Blocks{@Order};
}

sub ObjectSource {
    my (%Param) = @_;
    die "Script owner must be a mapping.\n" if ref $Param{Object} ne 'HASH';
    my $Field = $Param{Field};
    # Authored policies may still name the member field; its owning Set is truth.
    if (!BlockSpec($Field)) {
        ($Field) = grep { $Spec{$_}[1] eq $Param{Field} } keys %Spec;
    }
    die "Unknown script block field.\n" if !$Field;
    my $Object = $Param{Object};
    my $Rows = exists $Object->{'DynamicField_' . $Field}
        ? $Object->{'DynamicField_' . $Field} : $Object->{$Field};
    return Assemble(Field => $Field, Rows => $Rows);
}

sub SplitSource {
    my (%Param) = @_;
    my $Spec = BlockSpec($Param{Field});
    die "Unknown script block field.\n" if !$Spec;
    my $Source = $Param{Source};
    die "Script source must be a bounded scalar.\n"
        if ref $Source || (defined $Source && length($Source) > 376200);
    return [] if !defined $Source || $Source eq '';
    my @Rows;
    while (length $Source) {
        my $Size = length($Source) > 3800 ? 3800 : length($Source);
        if ($Size < length($Source)) {
            my $Newline = rindex($Source, "\n", $Size - 1);
            $Size = $Newline + 1 if $Newline >= 0
                && length($Source) - $Newline - 1 <= 3800 * (98 - @Rows);
        }
        push @Rows, {$Spec->[0] => 1 + @Rows, $Spec->[1] => substr($Source, 0, $Size, '')};
    }
    return \@Rows;
}

# A Set and its top-level members share native DynamicFieldValue storage.
# Never forward empty legacy workbook columns alongside their owning Set.
sub NormalizeImportFields {
    my (%Param) = @_;
    die "Import fields must be a mapping.\n" if ref $Param{Fields} ne 'HASH';
    my %Fields = %{$Param{Fields}};
    for my $Field (sort keys %Fields) {
        my $Spec = BlockSpec($Field);
        next if !$Spec;
        my $Config = $Param{Definition}{$Field};
        die "Script Set '$Field' is unavailable in the class definition.\n"
            if ref $Config ne 'HASH' || ($Config->{FieldType} || '') ne 'Set';
        # Workbook blank cells represent an empty Set, not a malformed program.
        # Keep populated scalars/mappings invalid; omitted columns stay omitted.
        $Fields{$Field} = [] if !defined $Fields{$Field}
            || (!ref $Fields{$Field} && $Fields{$Field} eq '');
        Assemble(Field => $Field, Rows => $Fields{$Field});
        for my $Member (@{$Spec}) {
            next if !exists $Fields{$Member};
            my $Value = _Scalar($Fields{$Member});
            die "Import cannot supply both '$Field' and standalone '$Member'.\n"
                if defined $Value && $Value ne '';
            delete $Fields{$Member};
        }
    }
    return \%Fields;
}

1;
