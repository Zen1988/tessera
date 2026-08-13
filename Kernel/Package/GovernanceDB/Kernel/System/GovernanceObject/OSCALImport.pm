package Kernel::System::GovernanceObject::OSCALImport;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData IsStringWithData);

our @ObjectDependencies = (
    'Kernel::System::GovernanceObject::Document',
    'Kernel::System::JSON',
);

sub new { return bless {}, $_[0] }

sub Plan {
    my ( $Self, %Param ) = @_;

    my $Data = $Param{Data};
    if ( !ref $Data ) {
        return { Success => 0, Message => 'No OSCAL JSON was supplied.' } if !IsStringWithData( $Param{Content} );
        $Data = eval { $Kernel::OM->Get('Kernel::System::JSON')->Decode( Data => $Param{Content} ) };
        return { Success => 0, Message => 'The uploaded file is not valid JSON.' } if $@ || !IsHashRefWithData($Data);
    }

    my $Catalog = $Data->{catalog};
    return { Success => 0, Message => 'The JSON document is not an OSCAL catalog.' }
        if !IsHashRefWithData($Catalog) || !IsHashRefWithData( $Catalog->{metadata} );

    my $Metadata   = $Catalog->{metadata};
    my $CatalogName = _Text( $Metadata->{title} );
    return { Success => 0, Message => 'The OSCAL catalog metadata has no title.' } if !$CatalogName;

    my $Version      = _Text( $Metadata->{version} ) || '1';
    my $LastModified = _DateTime( $Metadata->{'last-modified'} );
    my @CatalogDescription = grep {$_} (
        _Text( $Metadata->{remarks} ),
        _Text( _Property( $Metadata->{props}, 'keywords' ) ),
    );
    my @Documents = ({
        object_type => 'GovernanceObject', class => 'Policy', name => $CatalogName,
        version => $Version, ztsm_status => 'Draft', description => join( "\n\n", @CatalogDescription ),
        fields => {
            'ZRM-Annex'           => _Text( $Catalog->{uuid} ),
            'ZRM-PolicySource'    => 'GovTech Singapore OSCAL',
            'ZRM-PolicyReference' => 'https://github.com/GovTechSG/tech-standards',
            'ZRM-Version'         => $Version,
            ( $LastModified ? ( 'ZRM-LastReviewed' => $LastModified ) : () ),
        },
    });

    my @Preview;
    my @Warnings;
    my %AnnexSeen;
    for my $Group ( @{ $Catalog->{groups} || [] } ) {
        next if !IsHashRefWithData($Group);
        my $Category = _Text( $Group->{title} ) || uc( _Text( $Group->{id} ) );
        my $DomainID = uc( _Text( $Group->{id} ) );
        my $Overview = _Part( $Group->{parts}, 'overview' );

        # The catalog is the parent Policy and each OSCAL group is a child
        # Policy domain. This preserves the native TESSERA policy hierarchy.
        push @Documents, {
            object_type => 'GovernanceObject', class => 'Policy', name => $Category,
            version => $Version, ztsm_status => 'Draft', description => $Overview,
            fields => {
                'ZRM-Annex'           => $DomainID,
                'ZRM-Parent'          => "Policy: $CatalogName",
                'ZRM-PolicySource'    => "GovTech Singapore OSCAL: $CatalogName",
                'ZRM-PolicyReference' => 'https://github.com/GovTechSG/tech-standards',
                'ZRM-Version'         => $Version,
                ( $LastModified ? ( 'ZRM-LastReviewed' => $LastModified ) : () ),
            },
        };

        for my $Control ( @{ $Group->{controls} || [] } ) {
            next if !IsHashRefWithData($Control);
            my $Annex = uc( _Text( $Control->{id} ) );
            my $Name  = _Text( $Control->{title} );
            if ( !$Annex || !$Name ) {
                push @Warnings, 'Skipped a control without both id and title.';
                next;
            }
            if ( $AnnexSeen{$Annex}++ ) {
                push @Warnings, "Skipped duplicate OSCAL control id $Annex.";
                next;
            }

            my $Statement = _Part( $Control->{parts}, 'statement' );
            my $Guidance  = _Part( $Control->{parts}, 'guidance' );
            my $Risk      = _Text( _Property( $Control->{props}, 'risk-statement' ) );
            my $Published = _DateTime( _Property( $Control->{props}, 'published' ) );
            my $Modified  = _DateTime( _Property( $Control->{props}, 'last-modified' ) );
            my @References = map { _Text( $_->{text} ) } grep { IsHashRefWithData($_) } @{ $Control->{links} || [] };
            @References = grep {$_} @References;

            my $RiskName = $Name;
            if ($Risk) {
                push @Documents, {
                    object_type => 'GovernanceObject', class => 'RiskStatement', name => $RiskName,
                    version => $Version, ztsm_status => 'Draft', description => $Risk,
                    fields => {
                        'ZRM-Annex'          => $Annex,
                        'ZRM-Policy'         => "Policy: $Category",
                        'ZRM-AdvisoryStatus' => 'Current',
                        'ZRM-Version'        => $Version,
                    },
                };
            }
            else {
                push @Warnings, "$Annex has no risk-statement; no RiskStatement will be created.";
            }

            my @Description;
            push @Description, "Control Statement\n$Statement" if $Statement;
            push @Description, "Control Recommendation\n$Guidance" if $Guidance;
            push @Description, "References\n" . join( "\n", map { "- $_" } @References ) if @References;
            push @Documents, {
                object_type => 'GovernanceObject', class => 'ControlObjective', name => $Name,
                version => $Version, ztsm_status => 'Draft', description => join( "\n\n", @Description ),
                fields => {
                    'ZRM-Annex'           => $Annex,
                    # OSCAL group titles are control domains, not TESSERA's
                    # People/Process/Technology/Data classification. Preserve
                    # the source domain without inventing a category mapping.
                    'ZRM-ControlClass'    => $Category,
                    'ZRM-Policy'          => "Policy: $Category",
                    ( $Risk ? ( 'ZRM-RiskStmt' => "RiskStatement: $RiskName" ) : () ),
                    'ZRM-Version'         => $Version,
                    ( $Statement ? ( 'ZRM-PolicyFilter' => $Statement ) : () ),
                    ( $Guidance ? ( 'ZRM-PolicyEvaluation' => $Guidance ) : () ),
                },
            };

            push @Preview, {
                Annex => $Annex, Name => $Name, Category => $Category, Policy => $Category,
                HasRisk => $Risk ? 1 : 0, Published => $Published, Modified => $Modified,
            };
        }
    }

    my %Counts;
    $Counts{ $_->{class} }++ for @Documents;
    return {
        Success   => 1,
        Message   => 'OSCAL catalog parsed successfully.',
        Catalog   => $CatalogName,
        Version   => $Version,
        Documents => \@Documents,
        Preview   => \@Preview,
        Warnings  => \@Warnings,
        Counts    => \%Counts,
    };
}

sub Import {
    my ( $Self, %Param ) = @_;
    return { Success => 0, Message => 'Need UserID.' } if !$Param{UserID};
    my $Plan = $Param{Plan} || $Self->Plan(%Param);
    return $Plan if !IsHashRefWithData($Plan) || !$Plan->{Success};

    my %Result = ( Created => 0, Updated => 0, Failed => 0, Errors => [] );
    my $DocumentObject = $Kernel::OM->Get('Kernel::System::GovernanceObject::Document');
    for my $Document ( @{ $Plan->{Documents} || [] } ) {
        my $Imported = $DocumentObject->Import( Data => $Document, UserID => $Param{UserID} );
        if ( IsHashRefWithData($Imported) && $Imported->{Success} ) {
            $Result{ $Imported->{Action} || 'Updated' }++;
        }
        else {
            $Result{Failed}++;
            push @{ $Result{Errors} }, join ': ', $Document->{class}, $Document->{name},
                ( IsHashRefWithData($Imported) ? $Imported->{Message} : 'unknown import failure' );
        }
    }
    $Result{Success} = $Result{Failed} ? 0 : 1;
    $Result{Message} = sprintf 'OSCAL import completed: %d created, %d updated, %d failed.',
        $Result{Created}, $Result{Updated}, $Result{Failed};
    return \%Result;
}

sub _Text { my $Value = shift; return '' if !defined $Value || ref $Value; $Value =~ s{\A\s+|\s+\z}{}g; return $Value }
sub _Property { my ( $Items, $Name ) = @_; for my $Item ( @{ $Items || [] } ) { return $Item->{value} if IsHashRefWithData($Item) && ( $Item->{name} || '' ) eq $Name } return }
sub _Part { my ( $Items, $Name ) = @_; for my $Item ( @{ $Items || [] } ) { return _Text( $Item->{prose} ) if IsHashRefWithData($Item) && ( $Item->{name} || '' ) eq $Name } return '' }
sub _DateTime { my $Value = _Text(shift); return '' if !$Value; $Value =~ s{T}{ }xms; $Value =~ s{(?:Z|[+-]\d\d:?\d\d)\z}{}xms; $Value =~ s{\.\d+}{}xms; return $Value }

1;
