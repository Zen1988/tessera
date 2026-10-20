package Kernel::System::TESSERA::PolicyEvaluation;

use strict;
use warnings;
use Kernel::System::TESSERA::ScriptBlocks qw(ObjectSource);
use DateTime;

sub new { my ( $Type, %Param ) = @_; bless \%Param, $Type }

# VERSION 1 per-target evaluation. All field names and relationships are authored.
sub Evaluate {
    my ( $Self, %Param ) = @_;
    my $Result = eval { $Self->_Evaluate(%Param) };
    return { Success => 0, Status => 'UNKNOWN', Error => $@ || 'Evaluation failed.' } if $@ || !$Result;
    return $Result;
}

sub _Evaluate {
    my ( $Self, %Param ) = @_;
    my $Script = $Param{Script};
    die "Expected VERSION 1 evaluation YAML.\n"
        if ref $Script ne 'HASH' || ( $Script->{VERSION} || 0 ) != 1;
    my $Context = $Param{Context};
    my $This = $Context->{THIS};
    my $Type = $Script->{TARGET} || '';
    die "TARGET does not match the Control target.\n"
        if $Type ne ( $Param{TargetType} || '' ) || ref $This ne 'HASH';
    my $Check = $Script->{CHECK};
    die "CHECK must be a mapping.\n" if ref $Check ne 'HASH';
    my $Zone = $Script->{'TIME ZONE'} || 'UTC';
    my $Today = DateTime->from_epoch( epoch => $Param{Now}, time_zone => $Zone )->truncate( to => 'day' );
    my ( $Field, $Value ) = ('', '');
    if ( exists $Check->{'ON EMPTY'} ) {
        my $Guard = $Check->{'ON EMPTY'};
        die "ON EMPTY requires FIELD and RETURN.\n" if ref $Guard ne 'HASH';
        $Field = $Guard->{FIELD} || '';
        die "ON EMPTY requires an exact field name.\n" if $Field !~ /\A[A-Za-z][A-Za-z0-9_-]*\z/;
        my ($TargetKind) = split /\./, $Type;
        my $Config = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet( Name => $Field );
        die "ON EMPTY field is not defined on the target.\n"
            if ref $Config ne 'HASH' || ( $Config->{ObjectType} || '' ) ne $TargetKind;
        $Value = exists $This->{$Field} ? $This->{$Field} : $This->{"DynamicField_$Field"};
        $Value = $Value->[0] if ref $Value eq 'ARRAY' && @{$Value} == 1;
        die "ON EMPTY value must be scalar.\n" if ref $Value;
        if ( !defined $Value || $Value eq '' ) {
            my $Status = $Guard->{RETURN} || '';
            die "ON EMPTY RETURN must be Pass or N/A.\n" if $Status ne 'Pass' && $Status ne 'N/A';
            return { Success => 1, Status => $Status, Findings => [], Reason => $Guard->{REASON} || 'Empty value.', Field => $Field, Value => $Value };
        }
    }
    die "CHECK requires an EXPECT expression.\n" if !defined $Check->{EXPECT} || ref $Check->{EXPECT} || $Check->{EXPECT} !~ /\S/;
    my $Condition = $Self->{Engine}->Evaluate(
        Source => $Check->{EXPECT},
        Context => { %{$Context}, EVALUATION => { Now => $Param{Now}, TimeZone => $Zone } },
    );
    die (( $Condition->{Reason} || 'Unknown condition.' ) . "\n") if $Condition->{Status} eq 'UNKNOWN';
    my %Evidence = ( Field => $Field, Value => $Value, Condition => $Check->{EXPECT}, Trace => $Condition->{Trace}, EvaluationDate => $Today->ymd, TimeZone => $Zone );
    return { Success => 1, Status => 'Pass', Findings => [],
        (ref $Script->{'ON FAIL'} eq 'HASH' && exists $Script->{'ON FAIL'}{'FOR EACH SELECTED'} ? (Batches => []) : ()),
        %Evidence } if $Condition->{Status} eq 'SATISFIED';

    # No graph reads occur until this object's own check has failed.
    my $Fail = $Script->{'ON FAIL'};
    die "ON FAIL must be a mapping.\n" if ref $Fail ne 'HASH';
    die "ON NO AFFECTED is supported only with DESCENDANTS and AFFECTED.\n"
        if exists $Fail->{'ON NO AFFECTED'}
            && ( exists $Fail->{'FOR EACH SELECTED'} || exists $Fail->{'EMIT FINDING'} );
    if ( exists $Fail->{'FOR EACH SELECTED'} ) {
        my $Rule = $Fail->{'FOR EACH SELECTED'};
        die "FOR EACH SELECTED needs SCRIPT FIELD, AS, LIMIT and EVALUATE.\n"
            if ref $Rule ne 'HASH' || !$Rule->{'SCRIPT FIELD'} || !$Rule->{AS}
                || ref $Rule->{EVALUATE} ne 'HASH' || ($Rule->{LIMIT} || '') !~ /\A[1-9][0-9]*\z/
                || $Rule->{LIMIT} > 1000;
        die "Nested selection evaluation is not allowed.\n" if $Param{SelectedEvaluation};
        my $Field = $Rule->{'SCRIPT FIELD'};
        my $Config = $Kernel::OM->Get('Kernel::System::DynamicField')->DynamicFieldGet(Name => $Field);
        my ($Owner) = split /\./, $Type;
        die "Selection script field is not defined on the target.\n"
            if !$Config || ($Config->{ObjectType} || '') ne $Owner;
        my $Source = ObjectSource(Object => $This, Field => $Field);
        $Source = $Source->[0] if ref $Source eq 'ARRAY' && @{$Source} == 1;
        die "Selection script is empty or malformed.\n" if !defined $Source || ref $Source || $Source !~ /\S/ || length($Source) > 376200;
        my $Selected = $Self->{Engine}->ScriptEvaluate(Source => $Source, Complete => 1,
            UserID => $Param{UserID}, Context => $Context, AllowedSearchType => $Rule->{AS});
        die (($Selected->{Error} || 'Selection script failed.') . "\n") if !$Selected->{Success};
        die "Selection must return the declared typed collection.\n"
            if ($Selected->{ValueType} || '') ne 'Collection<' . $Rule->{AS} . '>'
                || ref $Selected->{Value} ne 'ARRAY' || @{$Selected->{Value}} > $Rule->{LIMIT};
        my ($Kind, $Class) = $Rule->{AS} =~ /\A(ITSMConfigItem|GovernanceObject|MELTObject)\.([A-Za-z][A-Za-z0-9_-]*)\z/;
        die "Unsupported selection type.\n" if !$Kind;
        my $IDKey = $Kind eq 'ITSMConfigItem' ? 'ConfigItemID' : $Kind . 'ID';
        my (@Batches, @Findings, %Seen);
        for my $Object (@{$Selected->{Value}}) {
            die "Selection contains an invalid object.\n" if ref $Object ne 'HASH' || ($Object->{Class} || '') ne $Class
                || ($Object->{$IDKey} || '') !~ /\A[1-9][0-9]*\z/;
            next if $Seen{$Object->{$IDKey}}++;
            my $Result = $Self->_Evaluate(%Param, SelectedEvaluation => 1, Script => $Rule->{EVALUATE},
                TargetType => $Rule->{AS}, Context => {%{$Context}, THIS => $Object});
            for my $Finding (@{$Result->{Findings}}) { $Finding->{Origin} = $This }
            push @Findings, @{$Result->{Findings}};
            push @Batches, { Source => {%{$This}, Selected => $Object}, Evaluation => $Result }
                if @{$Result->{Findings}};
        }
        return { Success => 1, Status => @Findings ? 'Fail' : 'Pass', Findings => \@Findings,
            Batches => \@Batches, %Evidence };
    }
    if ( exists $Fail->{'EMIT FINDING'} ) {
        die "EMIT FINDING requires THIS and cannot be combined with DESCENDANTS or AFFECTED.\n"
            if !defined $Fail->{'EMIT FINDING'} || ref $Fail->{'EMIT FINDING'}
                || $Fail->{'EMIT FINDING'} ne 'THIS' || exists $Fail->{DESCENDANTS} || exists $Fail->{AFFECTED};
        return { Success => 1, Status => 'Fail',
            Findings => [ { Target => $This, TargetType => $Type, Source => $This } ], %Evidence };
    }
    die "ON FAIL must define DESCENDANTS and AFFECTED, or EMIT FINDING: THIS.\n"
        if !exists $Fail->{DESCENDANTS} || !exists $Fail->{AFFECTED};
    my $Walk = $Fail->{DESCENDANTS};
    die "DESCENDANTS must be a mapping.\n" if ref $Walk ne 'HASH';
    my ( $Kind, $Class ) = $Type =~ /\A(ITSMConfigItem|GovernanceObject|MELTObject)\.([A-Za-z][A-Za-z0-9_-]*)\z/;
    die "DESCENDANTS requires a class-based target.\n" if !$Kind;
    die "DESCENDANTS type must match TARGET.\n" if ( $Walk->{FOR} || '' ) ne $Kind || ( $Walk->{CLASS} || '' ) ne $Class;
    my $Parent = $Walk->{'PARENT FIELD'} || '';
    die "Invalid PARENT FIELD.\n" if $Parent !~ /\A[A-Za-z][A-Za-z0-9_-]*\z/;
    $Self->_ValidateReference( $Kind, $Kind, $Parent );
    my $Limit = $Walk->{LIMIT};
    my $DepthLimit = $Walk->{'MAX DEPTH'};
    die "Traversal requires LIMIT 1..1000 and MAX DEPTH 1..100.\n"
        if !defined $Limit || $Limit !~ /\A\d+\z/ || !$Limit || $Limit > 1000
            || !defined $DepthLimit || $DepthLimit !~ /\A\d+\z/ || !$DepthLimit || $DepthLimit > 100;
    my %IDKeys = ( ITSMConfigItem => 'ConfigItemID', GovernanceObject => 'GovernanceObjectID', MELTObject => 'MELTObjectID' );
    my $IDKey = $IDKeys{$Kind};
    my $RootID = $This->{$IDKey} or die "Target identity is missing.\n";
    my %Seen = ( $RootID => 1 );
    my %Selected = $Walk->{'INCLUDE SELF'} ? ( $RootID => $This ) : ();
    my @Queue = ( [ $This, 0 ] );
    while (@Queue) {
        my ( $Object, $Depth ) = @{ shift @Queue };
        my $Children = $Self->_Search( For => $Kind, Class => $Class, Limit => $Limit,
            Where => { $Parent => { EQUALS => $Object->{$IDKey} } }, UserID => $Param{UserID} );
        for my $Child (@{$Children}) {
            my $ID = $Child->{$IDKey} or die "Descendant identity is missing.\n";
            next if $Seen{$ID};
            die "Descendant depth limit exceeded.\n" if $Depth >= $DepthLimit;
            $Seen{$ID} = 1;
            die "Descendant count limit exceeded.\n" if keys(%Seen) > $Limit;
            $Selected{$ID} = $Child;
            push @Queue, [ $Child, $Depth + 1 ];
        }
    }
    die "AFFECTED must be a list.\n" if ref $Fail->{AFFECTED} ne 'ARRAY';
    my $NoAffected = $Fail->{'ON NO AFFECTED'};
    if ( exists $Fail->{'ON NO AFFECTED'} ) {
        die "ON NO AFFECTED requires RETURN Pass or N/A and optional scalar REASON.\n"
            if ref $NoAffected ne 'HASH' || ref $NoAffected->{RETURN}
                || ( $NoAffected->{RETURN} || '' ) !~ /\A(?:Pass|N\/A)\z/
                || ( exists $NoAffected->{REASON} && ( !defined $NoAffected->{REASON} || ref $NoAffected->{REASON} ) )
                || grep { $_ ne 'RETURN' && $_ ne 'REASON' } keys %{$NoAffected};
    }
    my %Findings;
    for my $Match ( @{ $Fail->{AFFECTED} } ) {
        die "AFFECTED entry requires FOR, CLASS and REFERENCES.\n"
            if ref $Match ne 'HASH' || !$IDKeys{ $Match->{FOR} || '' } || !$Match->{CLASS}
                || ref $Match->{REFERENCES} ne 'ARRAY' || !@{ $Match->{REFERENCES} };
        my $MatchLimit = $Match->{LIMIT};
        die "AFFECTED LIMIT must be 1..100000.\n" if !defined $MatchLimit || $MatchLimit !~ /\A\d+\z/ || !$MatchLimit || $MatchLimit > 100000;
        $Self->_ValidateReference( $Match->{FOR}, $Kind, $_ ) for @{ $Match->{REFERENCES} };
        my $Objects = $Self->_Search( For => $Match->{FOR}, Class => $Match->{CLASS}, Limit => $MatchLimit,
            Where => {}, UserID => $Param{UserID} );
        for my $Object (@{$Objects}) {
            my $AssetID = $Object->{ $IDKeys{ $Match->{FOR} } } or die "Affected object identity missing.\n";
            my @Matches;
            for my $Path ( @{ $Match->{REFERENCES} } ) {
                for my $ID ( $Self->_References( $Object, $Path ) ) {
                    next if !$Selected{$ID};
                    push @Matches, { Path => $Path, Object => $Selected{$ID} };
                }
            }
            next if !@Matches;
            my $Key = "$Match->{FOR}:$AssetID";
            $Findings{$Key} ||= { Asset => $Object, AssetType => "$Match->{FOR}.$Match->{CLASS}", Source => $This, Matches => [] };
            push @{ $Findings{$Key}{Matches} }, @Matches;
        }
    }
    return { Success => 1, Status => $NoAffected->{RETURN}, Findings => [], %Evidence,
        Reason => $NoAffected->{REASON} || 'No affected assets found.' }
        if !keys(%Findings) && $NoAffected;
    return { Success => 1, Status => 'Fail', Findings => [ map { $Findings{$_} } sort keys %Findings ], %Evidence };
}

sub _Search {
    my ( $Self, %Param ) = @_;
    my $Result = $Self->{Engine}->_ScriptNativeSearch( %Param, Complete => 1 );
    die (( $Result->{Error} || 'Reference search failed.' ) . "\n") if !$Result->{Success};
    return $Result->{Value};
}

sub _References {
    my ( $Self, $Object, $Path ) = @_;
    die "Invalid reference path.\n" if !defined $Path || $Path !~ /\A[A-Za-z][A-Za-z0-9_-]*(?:\[\*\]\.[A-Za-z][A-Za-z0-9_-]*)?\z/;
    my ( $Field, $Child ) = split /\[\*\]\./, $Path;
    my $Value = $Object->{"DynamicField_$Field"};
    return () if !defined $Value;
    my @Values;
    if ($Child) {
        die "Reference Set $Field is malformed.\n" if ref $Value ne 'ARRAY';
        for my $Row (@{$Value}) {
            die "Reference Set row is malformed.\n" if ref $Row ne 'HASH';
            my $V = $Row->{$Child};
            push @Values, ref $V eq 'ARRAY' ? @{$V} : $V;
        }
    }
    else { @Values = ref $Value eq 'ARRAY' ? @{$Value} : ($Value); }
    my %Seen;
    return grep { defined $_ && !ref $_ && $_ ne '' && !$Seen{$_}++ } @Values;
}

sub _ValidateReference {
    my ( $Self, $Owner, $Target, $Path ) = @_;
    die "Invalid reference path.\n" if !defined $Path || $Path !~ /\A[A-Za-z][A-Za-z0-9_-]*(?:\[\*\]\.[A-Za-z][A-Za-z0-9_-]*)?\z/;
    my ( $Field, $Child ) = split /\[\*\]\./, $Path;
    my $DF = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $Config = $DF->DynamicFieldGet( Name => $Field );
    die "Reference field $Field is unavailable on $Owner.\n"
        if ref $Config ne 'HASH' || ( $Config->{ObjectType} || '' ) ne $Owner;
    if ($Child) {
        die "Reference parent must be a Set.\n" if ( $Config->{FieldType} || '' ) ne 'Set';
        my $Include = $Config->{Config}{Include};
        die "Reference child is not in Set definition.\n"
            if ref $Include ne 'ARRAY' || !grep { ref $_ eq 'HASH' && ( $_->{DF} || '' ) eq $Child } @{$Include};
        $Config = $DF->DynamicFieldGet( Name => $Child );
    }
    die "Reference path $Path does not target $Target.\n"
        if ref $Config ne 'HASH' || ( $Config->{Config}{ReferencedObjectType} || '' ) ne $Target;
}

1;
