package Kernel::System::GovernanceObject::OSCALImport;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

use Archive::Zip qw(:ERROR_CODES);
use File::Temp qw(tempfile);
use Kernel::System::VariableCheck qw(IsHashRefWithData IsStringWithData);

our @ObjectDependencies = (
    'Kernel::System::GovernanceObject',
    'Kernel::System::GovernanceObject::Document',
    'Kernel::System::JSON',
);

sub new { return bless {}, $_[0] }

sub PlanBundle {
    my ( $Self, %Param ) = @_;
    return { Success => 0, Message => 'No OSCAL ZIP bundle was supplied.' }
        if !IsStringWithData( $Param{Content} );

    my $Zip = Archive::Zip->new();
    my ( $ZipHandle, $ZipPath ) = tempfile( SUFFIX => '.zip', UNLINK => 1 );
    binmode $ZipHandle;
    print {$ZipHandle} $Param{Content};
    close $ZipHandle;
    return { Success => 0, Message => 'The uploaded file is not a valid ZIP archive.' }
        if $Zip->read($ZipPath) != AZ_OK;

    my ( %Documents, $TotalSize );
    for my $Member ( $Zip->members() ) {
        next if $Member->isDirectory();
        my $Path = $Member->fileName() || '';
        $Path =~ s{\\}{/}g;
        return { Success => 0, Message => 'The ZIP contains an unsafe path.' }
            if $Path =~ m{(?:\A|/)\.\.(?:/|\z)};
        next if $Path !~ m{\.json\z}i;
        $TotalSize += $Member->uncompressedSize() || 0;
        return { Success => 0, Message => 'The OSCAL ZIP is too large.' }
            if $TotalSize > 50 * 1024 * 1024;
        return { Success => 0, Message => 'The OSCAL ZIP contains too many JSON files.' }
            if keys(%Documents) >= 500;
        my $Content = $Member->contents();
        return { Success => 0, Message => "Could not read $Path from the OSCAL ZIP." }
            if !defined $Content;
        $Path =~ s{\A.*?/(?=(?:catalogs|profiles)/)}{};
        $Documents{$Path} = $Content;
    }

    my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');
    my ( @Catalogs, %Profiles );
    for my $Path ( sort keys %Documents ) {
        my $Data = eval { $JSONObject->Decode( Data => $Documents{$Path} ) };
        return { Success => 0, Message => "$Path is not valid JSON." }
            if $@ || !IsHashRefWithData($Data);
        push @Catalogs, $Data if IsHashRefWithData( $Data->{catalog} );
        $Profiles{$Path} = $Data if IsHashRefWithData( $Data->{profile} );
    }
    return { Success => 0, Message => 'The ZIP must contain exactly one OSCAL catalog.' }
        if @Catalogs != 1;

    return $Self->Plan( Data => $Catalogs[0], Profiles => \%Profiles );
}

sub Plan {
    my ( $Self, %Param ) = @_;
    my $Data = $Param{Data};
    if ( !ref $Data ) {
        return { Success => 0, Message => 'No OSCAL JSON was supplied.' }
            if !IsStringWithData( $Param{Content} );
        $Data = eval { $Kernel::OM->Get('Kernel::System::JSON')->Decode( Data => $Param{Content} ) };
        return { Success => 0, Message => 'The uploaded file is not valid JSON.' }
            if $@ || !IsHashRefWithData($Data);
    }

    my $Catalog = $Data->{catalog};
    return { Success => 0, Message => 'The JSON document is not an OSCAL catalog.' }
        if !IsHashRefWithData($Catalog) || !IsHashRefWithData( $Catalog->{metadata} );

    my $Metadata = $Catalog->{metadata};
    my $CatalogName = _Text( $Metadata->{title} );
    return { Success => 0, Message => 'The OSCAL catalog metadata has no title.' } if !$CatalogName;
    my $Version = _Text( $Metadata->{version} ) || '1';
    # Annex and Version are the portable external identity. Policy membership
    # is containment/applicability and Source is descriptive metadata only.
    my $CatalogAnnex = _Text( $Catalog->{uuid} );
    my $CatalogRelease = $CatalogName;
    my $LastModified = _DateTime( $Metadata->{'last-modified'} );
    my @CatalogDescription = grep {$_} ( _Text( $Metadata->{remarks} ), _Text( _Property( $Metadata->{props}, 'keywords' ) ) );

    my @Documents = ({
        object_type => 'GovernanceObject', class => 'Policy', name => $CatalogRelease,
        version => $Version, ztsm_status => 'Draft', description => join( "\n\n", @CatalogDescription ),
        fields => {
            'ZRM-Annex' => $CatalogAnnex, 'ZRM-PolicySource' => 'GovTech Singapore OSCAL',
            'ZRM-PolicyReference' => 'https://github.com/GovTechSG/tech-standards', 'ZRM-Version' => $Version,
            ( $LastModified ? ( 'ZRM-LastReviewed' => $LastModified ) : () ),
        },
        oscal_identity => { class => 'Policy', annex => $CatalogAnnex, version => $Version },
    });

    my ( $ProfileDocuments, $Membership, $ProfileNames, $ProfileWarnings ) = $Self->_ProfilesPlan(
        Profiles => $Param{Profiles}, Parent => $CatalogRelease, CatalogName => $CatalogName,
        ParentAnnex => $CatalogAnnex, CatalogVersion => $Version,
    );
    push @Documents, @{$ProfileDocuments};
    my @Warnings = @{$ProfileWarnings};
    my ( @Preview, %AnnexSeen );

    for my $Group ( @{ $Catalog->{groups} || [] } ) {
        next if !IsHashRefWithData($Group);
        my $Category = _Text( $Group->{title} ) || uc( _Text( $Group->{id} ) );
        my $DomainID = uc( _Text( $Group->{id} ) );
        my $CategoryRelease = $Category;
        push @Documents, {
            object_type => 'GovernanceObject', class => 'Policy', name => $CategoryRelease,
            version => $Version, ztsm_status => 'Draft', description => _Part( $Group->{parts}, 'overview' ),
            fields => {
                'ZRM-Annex' => $DomainID, 'ZRM-Parent' => "Policy: $CatalogRelease",
                'ZRM-PolicySource' => "GovTech Singapore OSCAL: $CatalogName",
                'ZRM-PolicyReference' => 'https://github.com/GovTechSG/tech-standards', 'ZRM-Version' => $Version,
                ( $LastModified ? ( 'ZRM-LastReviewed' => $LastModified ) : () ),
            },
            oscal_identity => { class => 'Policy', annex => $DomainID, version => $Version },
            oscal_refs => { 'ZRM-Parent' => [ { class => 'Policy', annex => $CatalogAnnex, version => $Version } ] },
        };

        for my $Control ( @{ $Group->{controls} || [] } ) {
            next if !IsHashRefWithData($Control);
            my $Annex = uc( _Text( $Control->{id} ) );
            my $BaseName = _Text( $Control->{title} );
            if ( !$Annex || !$BaseName ) { push @Warnings, 'Skipped a control without both id and title.'; next }
            if ( $AnnexSeen{$Annex}++ ) { push @Warnings, "Skipped duplicate OSCAL control id $Annex."; next }
            my $Name = $BaseName;
            my $Statement = _Part( $Control->{parts}, 'statement' );
            my $Guidance = _Part( $Control->{parts}, 'guidance' );
            my $Risk = _Text( _Property( $Control->{props}, 'risk-statement' ) );
            my $References = join '; ', grep {$_} map { _Text( $_->{text} ) }
                grep { IsHashRefWithData($_) } @{ $Control->{links} || [] };
            my @Policies = ( "Policy: $CategoryRelease", map { "Policy: $_->{name}" } @{ $Membership->{$Annex} || [] } );
            my @PolicyRefs = ( { class => 'Policy', annex => $DomainID, version => $Version },
                map { { class => 'Policy', annex => $_->{annex}, version => $_->{version} } } @{ $Membership->{$Annex} || [] } );

            if ($Risk) {
                push @Documents, {
                    object_type => 'GovernanceObject', class => 'RiskStatement', name => $Name,
                    version => $Version, ztsm_status => 'Draft', description => $Risk,
                    fields => { 'ZRM-Annex' => $Annex, 'ZRM-Policy' => \@Policies,
                        ( $References ? ( 'ZRM-PolicyReference' => $References ) : () ),
                        'ZRM-AdvisoryStatus' => 'Current', 'ZRM-Version' => $Version },
                    oscal_identity => { class => 'RiskStatement', annex => $Annex, version => $Version },
                    oscal_refs => { 'ZRM-Policy' => \@PolicyRefs },
                };
            }
            else { push @Warnings, "$Annex has no risk-statement; no RiskStatement will be created." }

            my @Description;
            push @Description, "Control Statement: $Statement" if $Statement;
            push @Description, "Control Recommendation: $Guidance" if $Guidance;
            push @Documents, {
                object_type => 'GovernanceObject', class => 'ControlObjective', name => $Name,
                version => $Version, ztsm_status => 'Draft', description => join( "\n\n", @Description ),
                fields => {
                    'ZRM-Annex' => $Annex, 'ZRM-Policy' => \@Policies,
                    ( $References ? ( 'ZRM-PolicyReference' => $References ) : () ),
                    ( $Risk ? ( 'ZRM-RiskStmt' => "RiskStatement: $Name" ) : () ), 'ZRM-Version' => $Version,
                },
                oscal_identity => { class => 'ControlObjective', annex => $Annex, version => $Version },
                oscal_refs => {
                    'ZRM-Policy' => \@PolicyRefs,
                    ( $Risk ? ( 'ZRM-RiskStmt' => [ { class => 'RiskStatement', annex => $Annex, version => $Version } ] ) : () ),
                },
            };
            push @Preview, { Annex => $Annex, Name => $BaseName, Category => $Category,
                Policy => join( ', ', @Policies ), HasRisk => $Risk ? 1 : 0 };
        }
    }

    my %Counts;
    $Counts{ $_->{class} }++ for @Documents;
    return { Success => 1, Message => 'OSCAL catalog and profiles parsed successfully.', Catalog => $CatalogName,
        Version => $Version, Documents => \@Documents, Preview => \@Preview, Warnings => \@Warnings,
        Counts => \%Counts, Profiles => $ProfileNames };
}

sub _ProfilesPlan {
    my ( $Self, %Param ) = @_;
    my $Profiles = IsHashRefWithData( $Param{Profiles} ) ? $Param{Profiles} : {};
    return ( [], {}, [], [] ) if !keys %{$Profiles};
    my ( %ByPath, %Title, %Direct, %Parents, @Warnings );
    for my $Path ( sort keys %{$Profiles} ) {
        my $Profile = $Profiles->{$Path}{profile};
        next if !IsHashRefWithData($Profile);
        $Path =~ s{\A.*?/(?=profiles/)}{};
        $ByPath{$Path} = $Profile;
        $Title{$Path} = _Text( $Profile->{metadata}{title} ) || $Path;
        for my $Import ( @{ $Profile->{imports} || [] } ) {
            next if !IsHashRefWithData($Import);
            my $Href = _Text( $Import->{href} );
            $Href =~ s{\Atrestle://}{};
            push @{ $Parents{$Path} }, $Href if $Href =~ m{\Aprofiles/};
            for my $Include ( @{ $Import->{'include-controls'} || [] } ) {
                push @{ $Direct{$Path} }, map { uc _Text($_) } @{ $Include->{'with-ids'} || [] };
            }
        }
    }
    my ( %Effective, %Visiting );
    my $Resolve;
    $Resolve = sub {
        my ($Path) = @_;
        return $Effective{$Path} if $Effective{$Path};
        if ( $Visiting{$Path}++ ) { push @Warnings, "Profile import cycle at $Path."; return {} }
        my %IDs = map { $_ => 1 } grep {$_} @{ $Direct{$Path} || [] };
        for my $Parent ( @{ $Parents{$Path} || [] } ) {
            if ( !$ByPath{$Parent} ) { push @Warnings, "Profile $Path imports missing $Parent."; next }
            my $Inherited = $Resolve->($Parent);
            @IDs{ keys %{$Inherited} } = (1) x keys %{$Inherited};
        }
        delete $Visiting{$Path};
        return $Effective{$Path} = \%IDs;
    };
    my ( @Documents, %Membership, @Names );
    for my $Path ( sort keys %ByPath ) {
        my $Profile = $ByPath{$Path};
        my $Metadata = $Profile->{metadata} || {};
        my $Version = _Text( $Metadata->{version} ) || $Param{CatalogVersion};
        my $Label = _Text( _Property( $Metadata->{props}, 'label' ) );
        $Label ||= $Path;
        my $Name = $Title{$Path};
        push @Names, $Name;
        push @Documents, {
            object_type => 'GovernanceObject', class => 'Policy', name => $Name, version => $Version,
            ztsm_status => 'Draft', description => _Text( $Metadata->{remarks} ), fields => {
                'ZRM-Annex' => $Label, 'ZRM-Parent' => "Policy: $Param{Parent}",
                'ZRM-PolicySource' => 'GovTech Singapore OSCAL profile',
                'ZRM-PolicyReference' => 'https://github.com/GovTechSG/tech-standards', 'ZRM-Version' => $Version,
            },
            oscal_identity => { class => 'Policy', annex => $Label, version => $Version },
            oscal_refs => { 'ZRM-Parent' => [ { class => 'Policy', annex => $Param{ParentAnnex}, version => $Param{CatalogVersion} } ] },
        };
        push @{ $Membership{$_} }, { name => $Name, annex => $Label, version => $Version }
            for sort keys %{ $Resolve->($Path) };
    }
    return ( \@Documents, \%Membership, \@Names, \@Warnings );
}

sub Import {
    my ( $Self, %Param ) = @_;
    return { Success => 0, Message => 'Need UserID.' } if !$Param{UserID};
    my $Plan = $Param{Plan} || $Self->Plan(%Param);
    return $Plan if !IsHashRefWithData($Plan) || !$Plan->{Success};
    my %Result = ( Created => 0, Updated => 0, Failed => 0, Errors => [] );
    my $DocumentObject = $Kernel::OM->Get('Kernel::System::GovernanceObject::Document');
    my $GovernanceObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my %Reference;
    my @Ordered = sort {
        _ImportOrder($a) <=> _ImportOrder($b)
    } @{ $Plan->{Documents} || [] };
    for my $Document (@Ordered) {
        my %ImportDocument = %{$Document};
        $ImportDocument{fields} = { %{ $Document->{fields} || {} } };
        for my $Field ( keys %{ $Document->{oscal_refs} || {} } ) {
            my @Values;
            for my $Identity ( @{ $Document->{oscal_refs}{$Field} || [] } ) {
                my $Key = _IdentityKey($Identity);
                my $Number = $Reference{$Key} || $Self->_ExistingNumberByIdentity(
                    %{$Identity}, UserID => $Param{UserID},
                );
                if (!$Number) {
                    $Result{Failed}++;
                    push @{ $Result{Errors} }, "$Document->{class}: $Document->{name}: unresolved OSCAL reference $Key";
                    next;
                }
                push @Values, "$Identity->{class}: $Number";
            }
            $ImportDocument{fields}{$Field} = @Values > 1 ? \@Values : $Values[0] if @Values;
        }

        my $Identity = $Document->{oscal_identity} || {};
        my $ExistingItem = $Self->_ExistingItemByIdentity( %{$Identity}, UserID => $Param{UserID} );
        my $ExistingNumber = IsHashRefWithData($ExistingItem) ? $ExistingItem->{Number} : undef;
        $ImportDocument{number} = $ExistingNumber if $ExistingNumber;
        if ( ( $Identity->{class} || '' ) eq 'ControlObjective' ) {
            my $Inherited = $ExistingNumber
                ? _ControlProgrammingFromItem($ExistingItem)
                : $Self->_PreviousControlProgrammingByAnnex(
                    %{$Identity}, UserID => $Param{UserID},
                );
            for my $Field (qw(ZRM-ControlClass PolicyFilter PolicyEvaluation)) {
                $ImportDocument{fields}{$Field} = $Inherited->{$Field}
                    if exists $Inherited->{$Field};
            }
        }
        delete @ImportDocument{qw(oscal_identity oscal_refs)};

        my $Imported = $DocumentObject->Import(
            Data => \%ImportDocument, UserID => $Param{UserID}, MatchByName => 0,
        );
        if ( IsHashRefWithData($Imported) && $Imported->{Success} ) { $Result{ $Imported->{Action} || 'Updated' }++ }
        else { $Result{Failed}++; push @{ $Result{Errors} }, join ': ', $Document->{class}, $Document->{name},
            ( IsHashRefWithData($Imported) ? $Imported->{Message} : 'unknown import failure' ) }
        if ( IsHashRefWithData($Imported) && $Imported->{Success} && IsHashRefWithData($Identity) ) {
            my $Object = $GovernanceObject->GovernanceObjectGet(
                GovernanceObjectID => $Imported->{GovernanceObjectID}, DynamicFields => 0,
            );
            $Reference{ _IdentityKey($Identity) } = $Object->{Number} if IsHashRefWithData($Object);
        }
    }
    $Result{Success} = $Result{Failed} ? 0 : 1;
    $Result{Message} = sprintf 'OSCAL import completed: %d created, %d updated, %d failed.',
        $Result{Created}, $Result{Updated}, $Result{Failed};
    return \%Result;
}

sub _ExistingNumberByIdentity {
    my ( $Self, %Param ) = @_;
    my $Item = $Self->_ExistingItemByIdentity(%Param);
    return IsHashRefWithData($Item) ? $Item->{Number} : undef;
}

sub _ExistingItemByIdentity {
    my ( $Self, %Param ) = @_;
    return if !_Text( $Param{class} ) || !_Text( $Param{annex} ) || !_Text( $Param{version} );
    my $Object = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @IDs = $Object->GovernanceObjectSearch(
        Result => 'ARRAY', Permission => 'ro', UserID => $Param{UserID} || 1,
        'DynamicField_ZRM-Annex' => { Equals => $Param{annex} },
        'DynamicField_ZRM-Version' => { Equals => $Param{version} },
    );
    my @Matches;
    for my $ID (@IDs) {
        my $Item = $Object->GovernanceObjectGet(
            GovernanceObjectID => $ID, DynamicFields => 1, Silent => 1,
        );
        push @Matches, $Item if IsHashRefWithData($Item) && ( $Item->{Class} || '' ) eq $Param{class};
    }
    return @Matches == 1 ? $Matches[0] : undef;
}

sub _PreviousControlProgrammingByAnnex {
    my ( $Self, %Param ) = @_;
    return {} if ( $Param{class} || '' ) ne 'ControlObjective' || !_Text( $Param{annex} );

    my $Object = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my @IDs = $Object->GovernanceObjectSearch(
        Result => 'ARRAY', Permission => 'ro', UserID => $Param{UserID} || 1,
        Classes => ['ControlObjective'],
        'DynamicField_ZRM-Annex' => { Equals => $Param{annex} },
        SortBy => 'GovernanceObjectID', OrderBy => 'Down',
    );
    for my $ID (@IDs) {
        my $Item = $Object->GovernanceObjectGet(
            GovernanceObjectID => $ID, DynamicFields => 1, Silent => 1,
        );
        next if !IsHashRefWithData($Item) || ( $Item->{Class} || '' ) ne 'ControlObjective';
        next if _Text( $Item->{'DynamicField_ZRM-Version'} ) eq _Text( $Param{version} );

        return _ControlProgrammingFromItem($Item);
    }
    return {};
}

sub _ControlProgrammingFromItem {
    my ($Item) = @_;
    my %Programming;
    for my $Field (qw(ZRM-ControlClass PolicyFilter PolicyEvaluation)) {
        my $Key = "DynamicField_$Field";
        $Programming{$Field} = $Item->{$Key} if IsHashRefWithData($Item) && exists $Item->{$Key};
    }
    return \%Programming;
}

sub _IdentityKey { my ($Identity) = @_; return join '|', map { _Text( $Identity->{$_} ) } qw(class annex version) }
sub _ImportOrder {
    my ($Document) = @_;
    return 10 if $Document->{class} eq 'Policy' && !keys %{ $Document->{oscal_refs} || {} };
    return 20 if $Document->{class} eq 'Policy';
    return 30 if $Document->{class} eq 'RiskStatement';
    return 40;
}

sub _Text { my $Value = shift; return '' if !defined $Value || ref $Value; $Value =~ s{\A\s+|\s+\z}{}g; return $Value }
sub _Property { my ( $Items, $Name ) = @_; for my $Item ( @{ $Items || [] } ) { return $Item->{value} if IsHashRefWithData($Item) && ( $Item->{name} || '' ) eq $Name } return }
sub _Part { my ( $Items, $Name ) = @_; for my $Item ( @{ $Items || [] } ) { return _Text( $Item->{prose} ) if IsHashRefWithData($Item) && ( $Item->{name} || '' ) eq $Name } return '' }
sub _DateTime { my $Value = _Text(shift); return '' if !$Value; $Value =~ s{T}{ }; $Value =~ s{(?:Z|[+-]\d\d:?\d\d)\z}{}; $Value =~ s{\.\d+}{}; return $Value }

1;
