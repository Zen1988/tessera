# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2026 Rother OSS GmbH, https://ncs.com.sg
# --
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
# --

package Kernel::Modules::CustomerTicketOverview;
## nofilter(TidyAll::Plugin::OTOBO::Perl::DBObject)

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

use Kernel::System::VariableCheck qw(:all);
use Kernel::Language              qw(Translatable);

my @ZTSMReportHead = (
    'Ticket Number',
    'Ticket Type',
    'Service',
    'Title',
    'Description',
    'Location',
    'Application',
    'Environment',
    'State',
    'Created By',
    'Created Date',
    'Customer User',
    'ZTicket-OwnerGroup',
    'ZTicket-Owner',
    'ServicePayload',
    'ArticlesJSON',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub _ZTSMNormalizeValue {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return _ZTSMNormalizeValue( $Value->[0] );
    }

    if ( ref $Value eq 'HASH' ) {
        return $Value->{Key}     if defined $Value->{Key};
        return $Value->{Value}   if defined $Value->{Value};
        return $Value->{Content} if defined $Value->{Content};
    }

    return $Value;
}

sub _ZTSMNormalizeReferenceValue {
    my ($Value) = @_;

    return if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return _ZTSMNormalizeReferenceValue( $Value->[0] );
    }

    if ( ref $Value eq 'HASH' ) {
        return $Value->{Value}   if defined $Value->{Value};
        return $Value->{Key}     if defined $Value->{Key};
        return $Value->{Content} if defined $Value->{Content};
    }

    return $Value;
}

sub _ZTSMIsIPCAgent {
    my (%Param) = @_;

    return if !$Param{CustomerUserID};

    return 1
        if $Kernel::OM->Get('Kernel::System::CustomerGroup')->PermissionCheck(
        UserID    => $Param{CustomerUserID},
        GroupName => 'IPC',
        Type      => 'rw',
        );

    my $UserID = $Kernel::OM->Get('Kernel::System::User')->UserLookup(
        UserLogin => $Param{CustomerUserID},
        Silent    => 1,
    );

    return if !$UserID;

    return $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
        UserID    => $UserID,
        GroupName => 'IPC',
        Type      => 'rw',
    );
}

sub _ZTSMDebugValue {
    my ($Value) = @_;

    return '<undef>' if !defined $Value;

    if ( ref $Value eq 'ARRAY' ) {
        return '[' . join( ', ', map { _ZTSMDebugValue($_) } @{$Value} ) . ']';
    }

    if ( ref $Value eq 'HASH' ) {
        return '{'
            . join(
            ', ',
            map {
                $_ . '=' . _ZTSMDebugValue( $Value->{$_} )
            } sort keys %{$Value}
            )
            . '}';
    }

    return $Value;
}

sub _ZTSMCustomerUserMatches {
    my (%Param) = @_;

    my $AssignmentUser = _ZTSMNormalizeReferenceValue( $Param{AssignmentUser} );
    return if !defined $AssignmentUser || $AssignmentUser eq '';

    my $CustomerUserID = _ZTSMNormalizeValue( $Param{CustomerUserID} ) || '<undef>';
    my %CustomerUserID = map { lc $_ => 1 } _ZTSMCustomerUserReferenceIDs(%Param);

    my $Match = $CustomerUserID{ lc $AssignmentUser };

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'debug',
        Message  => 'ZTSM Overview support assignment user match: CustomerUserID='
            . $CustomerUserID
            . ' CandidateIDs='
            . join( '|', sort keys %CustomerUserID )
            . ' AssignmentRaw='
            . _ZTSMDebugValue( $Param{AssignmentUser} )
            . ' AssignmentValue='
            . $AssignmentUser
            . ' Match='
            . ( $Match ? 1 : 0 ),
    );

    return $Match;
}

sub _ZTSMCustomerUserReferenceIDs {
    my (%Param) = @_;

    my $CustomerUserID = _ZTSMNormalizeValue( $Param{CustomerUserID} );

    return if !defined $CustomerUserID || $CustomerUserID eq '';

    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my %CustomerUserID = ( $CustomerUserID => 1 );

    for my $CustomerID (
        $CustomerUserObject->CustomerIDs(
            User => $CustomerUserID,
        )
        )
    {
        my $Value = _ZTSMNormalizeValue($CustomerID);
        $CustomerUserID{$Value} = 1 if defined $Value && $Value ne '';
    }

    return sort keys %CustomerUserID;
}

sub _ZTSMSupportProfileVariants {
    my (%Param) = @_;

    my $Value = _ZTSMNormalizeValue( $Param{Value} );

    return if !defined $Value;
    return if $Value eq '';

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    my %Value;

    my @SupportProfiles;
    if ( $Value =~ m{\A\d+\z} ) {
        for my $GetParam (
            { GovernanceObjectID => $Value },
            { VersionID    => $Value },
            )
        {
            my $SupportProfile = $GovernanceObjectObject->GovernanceObjectGet(
                %{$GetParam},
                DynamicFields => 1,
                Silent        => 1,
            );

            push @SupportProfiles, $SupportProfile
                if $SupportProfile
                && ( $SupportProfile->{Class} || '' ) eq 'SupportProfile';
        }
    }
    else {
        my @SupportProfileIDs = $GovernanceObjectObject->GovernanceObjectSearch(
            Result  => 'ARRAY',
            Classes => ['SupportProfile'],
            Name    => $Value,
            Limit   => 10,
        );

        for my $SupportProfileID (@SupportProfileIDs) {
            my $SupportProfile = $GovernanceObjectObject->GovernanceObjectGet(
                GovernanceObjectID => $SupportProfileID,
                DynamicFields => 1,
                Silent        => 1,
            );

            push @SupportProfiles, $SupportProfile
                if $SupportProfile;
        }
    }

    for my $SupportProfile (@SupportProfiles) {
        $Value{ $SupportProfile->{GovernanceObjectID} } = 1 if $SupportProfile->{GovernanceObjectID};
        $Value{ $SupportProfile->{LastVersionID} } = 1 if $SupportProfile->{LastVersionID};
        $Value{ $SupportProfile->{Name} }          = 1 if !$Param{ReferenceOnly} && $SupportProfile->{Name};
    }

    $Value{$Value} = 1
        if !$Param{ReferenceOnly}
        || $Value =~ m{\A\d+\z};

    return sort keys %Value;
}

sub _ZTSMSupportProfileList {
    my (%Param) = @_;

    return if !$Param{CustomerUserID};

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'debug',
        Message  => 'ZTSM Overview support profile list enter: CustomerUserID='
            . $Param{CustomerUserID},
    );

    my @CustomerUserIDs = _ZTSMCustomerUserReferenceIDs( CustomerUserID => $Param{CustomerUserID} );
    my %AssignmentID;

    my @FoundAssignmentIDs = $GovernanceObjectObject->GovernanceObjectSearch(
        Classes => ['SupportAssignment'],
        Result  => 'ARRAY',
        Limit   => 1000,
    );

    $AssignmentID{$_} = 1 for @FoundAssignmentIDs;

    my @AssignmentIDs = sort { $a <=> $b } keys %AssignmentID;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'debug',
        Message  => 'ZTSM Overview support assignment search: CustomerUserID='
            . $Param{CustomerUserID}
            . ' CandidateIDs='
            . join( '|', @CustomerUserIDs )
            . ' Count='
            . scalar @AssignmentIDs,
    );

    return if !@AssignmentIDs;

    my %SupportProfile;

    ASSIGNMENT:
    for my $AssignmentID (@AssignmentIDs) {
        my $Assignment = $GovernanceObjectObject->GovernanceObjectGet(
            GovernanceObjectID => $AssignmentID,
            DynamicFields => 1,
        );

        next ASSIGNMENT if !$Assignment || ref $Assignment ne 'HASH';

        my $AssignmentUser = $Assignment->{'DynamicField_ZTSMSupportAssignment-UserAccount'};

        my $CustomerMatch;
        CUSTOMERUSERID:
        for my $CustomerUserID (@CustomerUserIDs) {
            if (
                _ZTSMCustomerUserMatches(
                    AssignmentUser => $AssignmentUser,
                    CustomerUserID => $CustomerUserID,
                )
                )
            {
                $CustomerMatch = 1;
                last CUSTOMERUSERID;
            }
        }

        next ASSIGNMENT if !$CustomerMatch;

        my $AssignmentSupportProfile = $Assignment->{'DynamicField_ZTSMSupportAssignment-SupportProfile'};
        $AssignmentSupportProfile ||= $Assignment->{XMLData}
            && $Assignment->{XMLData}->{'ZTSMSupportAssignment-SupportProfile'};

        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'info',
            Message  => 'ZTSM Overview assignment accepted user: AssignmentID='
                . $AssignmentID
                . ' SupportProfileRaw='
                . _ZTSMDebugValue($AssignmentSupportProfile),
        );

        for my $SupportProfile (
            _ZTSMSupportProfileVariants(
                Value => $AssignmentSupportProfile,
                ReferenceOnly => 1,
            )
            )
        {
            next ASSIGNMENT if !defined $SupportProfile;
            next ASSIGNMENT if $SupportProfile eq '';

            $SupportProfile{$SupportProfile} = 1;
        }
    }

    return sort keys %SupportProfile;
}

sub _ZTSMPermissionFilter {
    my (%Param) = @_;

    return if !$Param{CustomerUserID};

    my $PermissionObject = $Kernel::OM->Get(
        'Kernel::System::Ticket::CustomerPermission::ZTSMUserIDCheck'
    );

    my @TicketIDs;
    my %Seen;

    TICKETID:
    for my $TicketID ( @{ $Param{TicketIDs} || [] } ) {
        next TICKETID if !$TicketID;
        next TICKETID if $Seen{$TicketID}++;

        next TICKETID if !$PermissionObject->Run(
            TicketID       => $TicketID,
            CustomerUserID => $Param{CustomerUserID},
            Type           => 'ro',
        );

        push @TicketIDs, $TicketID;
    }

    return @TicketIDs;
}

sub _ZTSMExecutionTicketProtected {
    my (%Param) = @_;

    my $Ticket = $Param{Ticket};
    return if !IsHashRefWithData($Ticket);

    my $Parent = _ZTSMNormalizeValue( $Ticket->{'DynamicField_ZTicket-Parent'} );
    return if !defined $Parent || $Parent eq '';

    my $OwnerGroup = _ZTSMNormalizeValue( $Ticket->{'DynamicField_ZTicket-OwnerGroup'} );
    my $Owner      = _ZTSMNormalizeValue( $Ticket->{'DynamicField_ZTicket-Owner'} );

    return 1
        if ( defined $OwnerGroup && $OwnerGroup ne '' )
        || ( defined $Owner && $Owner ne '' );

    return;
}

sub _ZTSMStandardTicketIDsFilter {
    my (%Param) = @_;

    return if !$Param{CustomerUserID};

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my @TicketIDs;

    TICKETID:
    for my $TicketID ( @{ $Param{TicketIDs} || [] } ) {
        next TICKETID if !$TicketID;

        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            UserID        => 1,
        );

        next TICKETID if !%Ticket;

        if ( _ZTSMExecutionTicketProtected( Ticket => \%Ticket ) ) {
            my @AllowedTicketIDs = _ZTSMPermissionFilter(
                CustomerUserID => $Param{CustomerUserID},
                TicketIDs      => [$TicketID],
            );

            next TICKETID if !@AllowedTicketIDs;
        }

        push @TicketIDs, $TicketID;
    }

    return @TicketIDs;
}

# Avoid a fixed candidate cap before permission filtering and dashboard aggregation.
sub _ZTSMOverviewSearchAll {
    my ($Ticket,%P)=@_;
    my $Count=$Ticket->TicketSearch(%P,Result=>'COUNT',Limit=>1);
    return if !defined $Count || $Count !~ /^\d+$/ || !$Count;
    return $Ticket->TicketSearch(%P,Result=>'ARRAY',Limit=>$Count);
}

sub _ZTSMExportActionHTML { return ''; }

sub _ZTSMWorkableTicketIDs {
    my (%Param) = @_;

    return if !$Param{CustomerUserID};

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my %Candidate;
    my @Candidate;

    my %SearchBase = (
        Result  => 'ARRAY',
        SortBy  => $Param{SortBy}  || 'Age',
        OrderBy => $Param{OrderBy} || 'Down',
        UserID  => 1,
    );

    $SearchBase{StateType} = $Param{StateType}
        if $Param{StateType};

    if ( defined $Param{Fulltext} && $Param{Fulltext} ne '' ) {
        $SearchBase{Fulltext}            = $Param{Fulltext};
        $SearchBase{FullTextIndex}       = 1;
        $SearchBase{ContentSearchPrefix} = '*';
        $SearchBase{ContentSearchSuffix} = '*';
    }

    if ( _ZTSMIsIPCAgent( CustomerUserID => $Param{CustomerUserID} ) ) {
        my @TicketIDs = _ZTSMOverviewSearchAll($TicketObject,%SearchBase);

        return _ZTSMPermissionFilter(
            CustomerUserID => $Param{CustomerUserID},
            TicketIDs      => \@TicketIDs,
        );
    }

    PROFILE:
    for my $SupportProfile ( _ZTSMSupportProfileList( CustomerUserID => $Param{CustomerUserID} ) ) {
        next PROFILE if !$SupportProfile;

        my @ProfileTicketIDs = _ZTSMOverviewSearchAll($TicketObject,
            %SearchBase,
            'DynamicField_ZTicket-OwnerGroup' => {
                Equals => $SupportProfile,
            },
        );

        for my $TicketID (@ProfileTicketIDs) {
            next if !$TicketID;
            next if $Candidate{$TicketID}++;
            push @Candidate, $TicketID;
        }
    }

    for my $CustomerUserID ( _ZTSMCustomerUserReferenceIDs( CustomerUserID => $Param{CustomerUserID} ) ) {
        next if !$CustomerUserID;

        my @OwnerTicketIDs = _ZTSMOverviewSearchAll($TicketObject,
            %SearchBase,
            'DynamicField_ZTicket-Owner' => {
                Equals => $CustomerUserID,
            },
        );

        for my $TicketID (@OwnerTicketIDs) {
            next if !$TicketID;
            next if $Candidate{$TicketID}++;
            push @Candidate, $TicketID;
        }
    }

    if ( $Param{CustomerUserLogin} && $Param{CustomerUserLogin} ne $Param{CustomerUserID} ) {
        for my $CustomerUserLogin ( _ZTSMCustomerUserReferenceIDs( CustomerUserID => $Param{CustomerUserLogin} ) ) {
            next if !$CustomerUserLogin;

            my @OwnerTicketIDs = _ZTSMOverviewSearchAll($TicketObject,
                %SearchBase,
                'DynamicField_ZTicket-Owner' => {
                    Equals => $CustomerUserLogin,
                },
            );

            for my $TicketID (@OwnerTicketIDs) {
                next if !$TicketID;
                next if $Candidate{$TicketID}++;
                push @Candidate, $TicketID;
            }
        }
    }

    return _ZTSMPermissionFilter(
        CustomerUserID => $Param{CustomerUserID},
        TicketIDs      => \@Candidate,
    );
}

sub _ZTSMServiceExtensionFieldSpecsParse {
    my (%Param) = @_;

    my $Value  = $Param{Value};
    my @Values = ref $Value eq 'ARRAY' ? @{$Value} : ($Value);

    my @FieldSpecs;
    my %Seen;
    VALUE:
    for my $Item (@Values) {
        next VALUE if !defined $Item;

        PART:
        for my $Part ( split m{\s*[|,;\r\n]\s*}, $Item ) {
            next PART if !$Part;

            $Part =~ s{\A\s+|\s+\z}{}g;

            my ( $FieldName, $Mandatory, $RenderLayout ) = split m{\s*:\s*}, $Part, 3;
            $FieldName //= '';
            $FieldName =~ s{\A\s+|\s+\z}{}g;
            $FieldName =~ s{\ADynamicField_}{};
            $RenderLayout //= '';
            $RenderLayout =~ s{\A\s+|\s+\z}{}g;

            next PART if !$FieldName;
            next PART if $Seen{$FieldName}++;

            push @FieldSpecs, {
                Name         => $FieldName,
                Mandatory    => $Mandatory && $Mandatory =~ m{\A1\z} ? 1 : 0,
                RenderLayout => $RenderLayout =~ m{\A(?:Horizontal|Vertical)\z}i ? ucfirst lc $RenderLayout : undef,
            };
        }
    }

    return @FieldSpecs;
}

sub _ZTSMServiceExtensionFieldsByService {
    my (%Param) = @_;

    my $DynamicFieldObject = $Param{DynamicFieldObject} || $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Param{BackendObject}      || $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $ServiceFieldConfig = $DynamicFieldObject->DynamicFieldGet(
        Name => 'ZService-Field',
    );

    return {} if !IsHashRefWithData($ServiceFieldConfig);
    return {} if $ServiceFieldConfig->{ObjectType} ne 'Service';

    my %ServiceList = $Kernel::OM->Get('Kernel::System::Service')->ServiceList(
        Valid  => 1,
        UserID => 1,
    );

    my %FieldSpecsByService;
    SERVICEID:
    for my $ServiceID ( sort keys %ServiceList ) {
        my $Value = $BackendObject->ValueGet(
            DynamicFieldConfig => $ServiceFieldConfig,
            ObjectID           => $ServiceID,
            UserID             => 1,
        );

        my @FieldSpecs = _ZTSMServiceExtensionFieldSpecsParse( Value => $Value );
        next SERVICEID if !@FieldSpecs;

        $FieldSpecsByService{$ServiceID} = \@FieldSpecs;
    }

    return \%FieldSpecsByService;
}

sub _ZTSMSetFieldOrder {
    my (%Param) = @_;

    my $Include = $Param{Include};
    return if ref $Include ne 'ARRAY';

    my @FieldOrder;
    ITEM:
    for my $IncludeItem ( @{$Include} ) {
        next ITEM if ref $IncludeItem ne 'HASH';

        if ( IsHashRefWithData( $IncludeItem->{Grid} ) && IsArrayRefWithData( $IncludeItem->{Grid}{Rows} ) ) {
            ROW:
            for my $Row ( @{ $IncludeItem->{Grid}{Rows} } ) {
                next ROW if ref $Row ne 'ARRAY';

                FIELD:
                for my $Field ( @{$Row} ) {
                    next FIELD if ref $Field ne 'HASH' || !$Field->{DF};
                    push @FieldOrder, $Field->{DF};
                }
            }
        }
        elsif ( $IncludeItem->{DF} ) {
            push @FieldOrder, $IncludeItem->{DF};
        }
    }

    return @FieldOrder;
}

sub _ZTSMExportDisplayValue {
    my (%Param) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig};
    my $Value              = $Param{Value};

    return '' if !IsHashRefWithData($DynamicFieldConfig);
    return '' if !defined $Value;
    return '' if ref $Value eq 'ARRAY' && !@{$Value};
    return '' if !ref $Value && $Value eq '';

    if (
        ( $DynamicFieldConfig->{FieldType} || '' ) eq 'ConfigItem'
        || ( $DynamicFieldConfig->{FieldType} || '' ) eq 'GovernanceObject'
        )
    {
        my @Values = ref $Value eq 'ARRAY' ? @{$Value} : ($Value);
        my @Display;

        VALUE:
        for my $Item (@Values) {
            next VALUE if !defined $Item || $Item eq '';
            push @Display, _ZTSMExportGovernanceObjectDisplayName( Value => $Item );
        }

        return join "\n", @Display;
    }

    my $Rendered = $Param{BackendObject}->DisplayValueRender(
        DynamicFieldConfig => $DynamicFieldConfig,
        Value              => $Value,
        LayoutObject       => $Param{LayoutObject},
        HTMLOutput         => 0,
    );

    return '' if !IsHashRefWithData($Rendered);
    return $Rendered->{Value} // '';
}

sub _ZTSMExportGovernanceObjectDisplayName {
    my (%Param) = @_;

    my $Value = $Param{Value};
    return '' if !defined $Value || $Value eq '';
    return $Value if $Value !~ m{\A\d+\z};

    my $GovernanceObjectObject = $Kernel::OM->Get('Kernel::System::GovernanceObject');
    for my $GetParam (
        { GovernanceObjectID => $Value },
        { VersionID          => $Value },
        )
    {
        my $GovernanceObject = $GovernanceObjectObject->GovernanceObjectGet(
            %{$GetParam},
            DynamicFields => 0,
            Silent        => 1,
        );

        next if !IsHashRefWithData($GovernanceObject);
        next if !$GovernanceObject->{Name};

        return $Value . ' - ' . $GovernanceObject->{Name};
    }

    return $Value;
}

sub _ZTSMExportDynamicFieldValue {
    my (%Param) = @_;

    my $FieldName = $Param{FieldName} || return '';
    my $DynamicFieldConfig = $Param{DynamicFieldConfig}
        || $Param{DynamicFieldObject}->DynamicFieldGet( Name => $FieldName );

    return '' if !IsHashRefWithData($DynamicFieldConfig);

    my $Value;
    if ( exists $Param{Ticket}->{"DynamicField_$FieldName"} ) {
        $Value = $Param{Ticket}->{"DynamicField_$FieldName"};
    }
    else {
        $Value = $Param{BackendObject}->ValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Param{Ticket}->{TicketID},
        );
    }

    return _ZTSMExportDisplayValue(
        %Param,
        DynamicFieldConfig => $DynamicFieldConfig,
        Value              => $Value,
    );
}

sub _ZTSMExportServicePayload {
    my (%Param) = @_;

    my $ServiceID = $Param{Ticket}->{ServiceID} || return '';
    my $FieldSpecs = $Param{ServiceFieldSpecsByService}->{$ServiceID};
    return '' if !IsArrayRefWithData($FieldSpecs);

    my %Payload;
    my $HasPayload;

    FIELD:
    for my $FieldSpec ( @{$FieldSpecs} ) {
        next FIELD if !IsHashRefWithData($FieldSpec);
        my $FieldName = $FieldSpec->{Name} || next FIELD;

        my $DynamicFieldConfig = $Param{DynamicFieldByName}->{$FieldName}
            ||= $Param{DynamicFieldObject}->DynamicFieldGet( Name => $FieldName );
        next FIELD if !IsHashRefWithData($DynamicFieldConfig);
        next FIELD if $DynamicFieldConfig->{ObjectType} ne 'Ticket';

        my $Value = exists $Param{Ticket}->{"DynamicField_$FieldName"}
            ? $Param{Ticket}->{"DynamicField_$FieldName"}
            : $Param{BackendObject}->ValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Param{Ticket}->{TicketID},
            );

        next FIELD if !defined $Value;
        next FIELD if ref $Value eq 'ARRAY' && !@{$Value};
        next FIELD if !ref $Value && $Value eq '';

        if ( ( $DynamicFieldConfig->{FieldType} || '' ) eq 'Set' ) {
            my @Rows = _ZTSMExportServicePayloadSetRows(
                %Param,
                DynamicFieldConfig => $DynamicFieldConfig,
                Value              => $Value,
            );
            next FIELD if !@Rows;

            $Payload{$FieldName} = \@Rows;
            $HasPayload = 1;
            next FIELD;
        }

        my $RenderedValue = _ZTSMExportDisplayValue(
            %Param,
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Value,
        );
        next FIELD if !defined $RenderedValue || $RenderedValue eq '';

        $Payload{$FieldName} = $RenderedValue;
        $HasPayload = 1;
    }

    return '' if !$HasPayload;

    return $Kernel::OM->Get('Kernel::System::JSON')->Encode(
        Data     => \%Payload,
        SortKeys => 1,
        Pretty   => 1,
    ) || '';
}

sub _ZTSMExportServicePayloadSetRows {
    my (%Param) = @_;

    my $DynamicFieldConfig = $Param{DynamicFieldConfig};
    my $Value              = $Param{Value};
    return if ref $Value ne 'ARRAY' || !@{$Value};

    my @FieldOrder = _ZTSMSetFieldOrder(
        Include => $DynamicFieldConfig->{Config}{Include},
    );
    return if !@FieldOrder;

    my @Rows;
    SETROW:
    for my $SetRow ( @{$Value} ) {
        next SETROW if ref $SetRow ne 'HASH';

        my %Row;
        my $HasValue;

        FIELD:
        for my $FieldName (@FieldOrder) {
            my $IncludedFieldConfig = $Param{DynamicFieldByName}->{$FieldName}
                ||= $Param{DynamicFieldObject}->DynamicFieldGet( Name => $FieldName );
            next FIELD if !IsHashRefWithData($IncludedFieldConfig);

            my $CellValue = $SetRow->{$FieldName};
            next FIELD if !defined $CellValue;
            next FIELD if ref $CellValue eq 'ARRAY' && !@{$CellValue};
            next FIELD if !ref $CellValue && $CellValue eq '';

            my $RenderedValue = _ZTSMExportDisplayValue(
                %Param,
                DynamicFieldConfig => $IncludedFieldConfig,
                Value              => $CellValue,
            );
            next FIELD if !defined $RenderedValue || $RenderedValue eq '';

            $Row{$FieldName} = $RenderedValue;
            $HasValue = 1;
        }

        push @Rows, \%Row if $HasValue;
    }

    return @Rows;
}

sub _ZTSMExportFirstArticle {
    my (%Param) = @_;

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my @ArticleList   = $ArticleObject->ArticleList(
        TicketID             => $Param{TicketID},
        IsVisibleForCustomer => 1,
        OnlyFirst            => 1,
    );

    return if !IsHashRefWithData( $ArticleList[0] );

    my $ArticleBackendObject = $ArticleObject->BackendForArticle( %{ $ArticleList[0] } );
    return $ArticleBackendObject->ArticleGet(
        TicketID  => $Param{TicketID},
        ArticleID => $ArticleList[0]->{ArticleID},
    );
}

sub _ZTSMExportArticleActor {
    my (%Param) = @_;

    my $Article = $Param{Article} || {};
    my $Ticket  = $Param{Ticket}  || {};

    if ( $Article->{CustomerUserID} ) {
        return $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
            UserLogin => $Article->{CustomerUserID},
        ) || $Article->{CustomerUserID};
    }

    if ( $Article->{From} ) {
        my $From = $Article->{From};
        $From =~ s{\A\s+|\s+\z}{}g;
        return $From if $From ne '';
    }

    if ( $Ticket->{CustomerUserID} ) {
        return $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
            UserLogin => $Ticket->{CustomerUserID},
        ) || $Ticket->{CustomerUserID};
    }

    if ( $Article->{CreateBy} ) {
        return $Kernel::OM->Get('Kernel::System::User')->UserName(
            UserID => $Article->{CreateBy},
        ) || $Article->{CreateBy};
    }

    return '';
}

sub _ZTSMExportArticleBodyText {
    my (%Param) = @_;

    my $Body = $Param{Article}->{Body} // '';
    return '' if $Body eq '';

    my $HTMLUtilsObject = $Kernel::OM->Get('Kernel::System::HTMLUtils');
    my $Text            = $HTMLUtilsObject->ToAscii( String => $Body ) // '';

    $Text =~ s{\r\n?}{\n}g;
    $Text =~ s{[ \t]+\n}{\n}g;
    $Text =~ s{\n{3,}}{\n\n}g;
    $Text =~ s{\A\s+|\s+\z}{}g;

    return $Text;
}

sub _ZTSMExportCreatedBy {
    my (%Param) = @_;

    my $Actor = _ZTSMExportArticleActor(%Param);
    return $Actor if $Actor;

    if ( $Param{Ticket}->{CustomerUserID} ) {
        return $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
            UserLogin => $Param{Ticket}->{CustomerUserID},
        ) || $Param{Ticket}->{CustomerUserID};
    }

    if ( $Param{Ticket}->{CreateBy} ) {
        return $Kernel::OM->Get('Kernel::System::User')->UserName(
            UserID => $Param{Ticket}->{CreateBy},
        ) || $Param{Ticket}->{CreateBy};
    }

    return '';
}

sub _ZTSMExportArticlesJSON {
    my (%Param) = @_;

    my $TicketID = $Param{TicketID} || return '';
    my $Ticket   = $Param{Ticket}   || {};

    my $ArticleObject = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my @ArticleList   = $ArticleObject->ArticleList(
        TicketID             => $TicketID,
        IsVisibleForCustomer => 1,
    );

    return '' if !@ArticleList;

    my %SenderTypeByID = $ArticleObject->ArticleSenderTypeList();
    my @Articles;

    METAARTICLE:
    for my $MetaArticle (
        sort {
            ( $b->{CreateTime} || '' ) cmp ( $a->{CreateTime} || '' )
                || ( $b->{ArticleID} || 0 ) <=> ( $a->{ArticleID} || 0 )
        } @ArticleList
        )
    {
        next METAARTICLE if !IsHashRefWithData($MetaArticle);

        my $ArticleBackendObject = $ArticleObject->BackendForArticle( %{$MetaArticle} );
        my %Article              = $ArticleBackendObject->ArticleGet(
            TicketID  => $TicketID,
            ArticleID => $MetaArticle->{ArticleID},
        );

        my $Body = _ZTSMExportArticleBodyText(
            Article => \%Article,
        );

        push @Articles, {
            ArticleID            => $MetaArticle->{ArticleID} || '',
            ArticleNumber        => $MetaArticle->{ArticleNumber} || '',
            Created              => $MetaArticle->{CreateTime} || $Article{CreateTime} || '',
            SenderType           => $SenderTypeByID{ $MetaArticle->{SenderTypeID} || 0 } || '',
            IsVisibleForCustomer => $MetaArticle->{IsVisibleForCustomer} ? 1 : 0,
            From                 => $Article{From} || '',
            To                   => $Article{To} || '',
            Cc                   => $Article{Cc} || '',
            Subject              => $Article{Subject} || '',
            CreatedBy            => _ZTSMExportArticleActor(
                Ticket  => $Ticket,
                Article => {
                    %{$MetaArticle},
                    %Article,
                },
            ),
            Body => $Body,
        };
    }

    return '' if !@Articles;

    return $Kernel::OM->Get('Kernel::System::JSON')->Encode(
        Data     => \@Articles,
        SortKeys => 1,
        Pretty   => 1,
    ) || '';
}

sub _ZTSMTicketReportExport {
    my ( $Self, %Param ) = @_;

    my $LayoutObject       = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $CSVObject          = $Kernel::OM->Get('Kernel::System::CSV');

    my $ServiceFieldSpecsByService = _ZTSMServiceExtensionFieldsByService(
        DynamicFieldObject => $DynamicFieldObject,
        BackendObject      => $BackendObject,
    );
    my %DynamicFieldByName;
    my @Rows;

    TICKETID:
    for my $TicketID ( @{ $Param{TicketIDs} || [] } ) {
        next TICKETID if !$TicketID;

        my %Ticket = $TicketObject->TicketGet(
            TicketID      => $TicketID,
            DynamicFields => 1,
            Extended      => 1,
            UserID        => $Self->{UserID},
        );
        next TICKETID if !%Ticket;

        my %Article = _ZTSMExportFirstArticle( TicketID => $TicketID );

        my $Description = _ZTSMExportArticleBodyText(
            Article => \%Article,
        );
        my $CreatedBy = _ZTSMExportCreatedBy(
            Ticket  => \%Ticket,
            Article => \%Article,
        );
        my $ArticlesJSON = _ZTSMExportArticlesJSON(
            TicketID => $TicketID,
            Ticket   => \%Ticket,
        );

        push @Rows, [
            $Ticket{TicketNumber} || '',
            $Ticket{Type}         || '',
            $Ticket{Service}      || '',
            $Ticket{Title}        || '',
            $Description,
            _ZTSMExportDynamicFieldValue(
                FieldName          => 'ZTicket-Location',
                Ticket             => \%Ticket,
                DynamicFieldObject => $DynamicFieldObject,
                BackendObject      => $BackendObject,
                LayoutObject       => $LayoutObject,
            ),
            _ZTSMExportDynamicFieldValue(
                FieldName          => 'ZTicket-Application',
                Ticket             => \%Ticket,
                DynamicFieldObject => $DynamicFieldObject,
                BackendObject      => $BackendObject,
                LayoutObject       => $LayoutObject,
            ),
            _ZTSMExportDynamicFieldValue(
                FieldName          => 'ZTicket-Env',
                Ticket             => \%Ticket,
                DynamicFieldObject => $DynamicFieldObject,
                BackendObject      => $BackendObject,
                LayoutObject       => $LayoutObject,
            ),
            $Ticket{State}  || '',
            $CreatedBy      || '',
            $Ticket{Created} || $Ticket{CreateTime} || '',
            $Ticket{CustomerUserID} || '',
            _ZTSMExportDynamicFieldValue(
                FieldName          => 'ZTicket-OwnerGroup',
                Ticket             => \%Ticket,
                DynamicFieldObject => $DynamicFieldObject,
                BackendObject      => $BackendObject,
                LayoutObject       => $LayoutObject,
            ),
            _ZTSMExportDynamicFieldValue(
                FieldName          => 'ZTicket-Owner',
                Ticket             => \%Ticket,
                DynamicFieldObject => $DynamicFieldObject,
                BackendObject      => $BackendObject,
                LayoutObject       => $LayoutObject,
            ),
            _ZTSMExportServicePayload(
                Ticket                     => \%Ticket,
                ServiceFieldSpecsByService => $ServiceFieldSpecsByService,
                DynamicFieldByName         => \%DynamicFieldByName,
                DynamicFieldObject         => $DynamicFieldObject,
                BackendObject              => $BackendObject,
                LayoutObject               => $LayoutObject,
            ),
            $ArticlesJSON,
        ];
    }

    my $Excel = $CSVObject->Array2CSV(
        Head   => \@ZTSMReportHead,
        Data   => \@Rows,
        Format => 'Excel',
    );

    my $CurSystemDateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');
    my $FileName                = sprintf(
        'ticket_report_%s_%s',
        lc( $Param{Filter} || 'tickets' ),
        $CurSystemDateTimeObject->Format(
            Format => '%Y-%m-%d_%H-%M',
        ),
    );
    $FileName =~ s{[^A-Za-z0-9_.-]+}{_}g;

    return $LayoutObject->Attachment(
        Filename    => $FileName . '.xlsx',
        ContentType => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        Content     => $Excel,
    );
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Kernel::OM->Get('Kernel::System::Log')->Log(
        Priority => 'debug',
        Message  => 'ZTSM CustomerTicketOverview Run enter: UserID='
            . ( $Self->{UserID} // '<undef>' )
            . ' Subaction='
            . ( $Self->{Subaction} // '<undef>' ),
    );

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');

    # disable output of customer company tickets
    my $DisableCompanyTickets = $ConfigObject->Get('Ticket::Frontend::CustomerDisableCompanyTicketAccess');

    # check subaction
    if ( !$Self->{Subaction} ) {
        return $LayoutObject->Redirect(
            OP => 'Action=CustomerTicketOverview;Subaction=MyTickets',
        );
    }
    elsif ( $Self->{Subaction} eq 'CompanyTickets' && $DisableCompanyTickets ) {
        return $LayoutObject->CustomerNoPermission( WithHeader => 'yes' );
    }

    # check needed CustomerID
    if ( !$Self->{UserCustomerID} ) {
        my $Output = $LayoutObject->CustomerHeader(
            Title => Translatable('Error'),
        );
        $Output .= $LayoutObject->CustomerError(
            Message => Translatable('Need CustomerID!'),
        );
        $Output .= $LayoutObject->CustomerFooter();

        return $Output;
    }

    $Kernel::OM->Get('Kernel::System::AuthSession')->UpdateSessionID(
        SessionID => $Self->{SessionID},
        Key       => 'LastScreenOverview',
        Value     => $Self->{RequestedURL},
    );

    my $SortBy         = $ParamObject->GetParam( Param => 'SortBy' )  || 'Age';
    my $OrderByCurrent = $ParamObject->GetParam( Param => 'OrderBy' ) || 'Down';
    my $Fulltext       = $ParamObject->GetParam( Param => 'Fulltext' );
    my $Display = ($ParamObject->GetParam(Param=>'Display')||'') eq 'List' || $Self->{Subaction} eq 'Search' ? 'List' : 'Dashboard';

    # filter definition
    my %Filters = (
        MyTickets => {
            All => {
                Name   => 'All',
                Prio   => 1000,
                Search => {
                    CustomerUserLoginRaw => $Self->{UserID},
                    OrderBy              => $OrderByCurrent,
                    SortBy               => $SortBy,
                    CustomerUserID       => $Self->{UserID},
                    Permission           => 'ro',
                },
            },
            Open => {
                Name   => 'Open',
                Prio   => 1100,
                Search => {
                    CustomerUserLoginRaw => $Self->{UserID},
                    StateType            => 'CustomerOpen',
                    OrderBy              => $OrderByCurrent,
                    SortBy               => $SortBy,
                    CustomerUserID       => $Self->{UserID},
                    Permission           => 'ro',
                },
            },
            Closed => {
                Name   => 'Closed',
                Prio   => 1200,
                Search => {
                    CustomerUserLoginRaw => $Self->{UserID},
                    StateType            => 'CustomerClosed',
                    OrderBy              => $OrderByCurrent,
                    SortBy               => $SortBy,
                    CustomerUserID       => $Self->{UserID},
                    Permission           => 'ro',
                },
            },
        },
    );

    my $UserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');

    my @CustomerIDs;

    # Add filter for customer company if the company tickets are not disabled.
    if ( !$DisableCompanyTickets ) {
        my %AccessibleCustomers = $Kernel::OM->Get('Kernel::System::CustomerGroup')->GroupContextCustomers(
            CustomerUserID => $Self->{UserID},
        );

        # Show customer companies as additional filter selection.
        if ( $Self->{Subaction} eq 'CompanyTickets' && scalar keys %AccessibleCustomers > 1 ) {

            @CustomerIDs = $ParamObject->GetArray( Param => 'CustomerIDs' );

            # Prevent array item duplication.
            my %CustomerIDsHash = map { $_ => 1 } @CustomerIDs;
            @CustomerIDs = sort keys %CustomerIDsHash;

            $Param{CustomerIDStrg} = $LayoutObject->BuildSelection(
                Data       => \%AccessibleCustomers,
                Name       => 'CustomerIDs',
                Multiple   => 1,
                Size       => 1,
                SelectedID => \@CustomerIDs,
                Class      => 'Modernize',
            );

            # Remember the active customer ID filter.
            $Param{CustomerIDs} = '';
            for my $CustomerID (@CustomerIDs) {
                $Param{CustomerIDs} .= ';CustomerIDs=' . $LayoutObject->LinkEncode($CustomerID);
            }
        }
        else {

            # Default behavior - use all available customer IDs.
            @CustomerIDs = sort keys %AccessibleCustomers;
        }

        $Filters{CompanyTickets} = {
            All => {
                Name   => 'All',
                Prio   => 1000,
                Search => {
                    CustomerIDRaw  => \@CustomerIDs,
                    OrderBy        => $OrderByCurrent,
                    SortBy         => $SortBy,
                    CustomerUserID => $Self->{UserID},
                    Permission     => 'ro',
                },
            },
            Open => {
                Name   => 'Open',
                Prio   => 1100,
                Search => {
                    CustomerIDRaw  => \@CustomerIDs,
                    StateType      => 'CustomerOpen',
                    OrderBy        => $OrderByCurrent,
                    SortBy         => $SortBy,
                    CustomerUserID => $Self->{UserID},
                    Permission     => 'ro',
                },
            },
            Closed => {
                Name   => 'Closed',
                Prio   => 1200,
                Search => {
                    CustomerIDRaw  => \@CustomerIDs,
                    StateType      => 'CustomerClosed',
                    OrderBy        => $OrderByCurrent,
                    SortBy         => $SortBy,
                    CustomerUserID => $Self->{UserID},
                    Permission     => 'ro',
                },
            },
        };
    }

    if ( $Self->{Subaction} eq 'Search' ) {

        # check whether company tickets are shown
        my %Selection = @CustomerIDs
            ?
            ( CustomerIDRaw => \@CustomerIDs )
            :
            ( CustomerUserLoginRaw => $Self->{UserID} );

        $Filters{Search} = {
            All => {
                Name   => 'All',
                Prio   => 1000,
                Search => {
                    %Selection,
                    OrderBy             => $OrderByCurrent,
                    SortBy              => $SortBy,
                    CustomerUserID      => $Self->{UserID},
                    Permission          => 'ro',
                    Fulltext            => $Fulltext,
                    FullTextIndex       => 1,
                    ContentSearchPrefix => '*',
                    ContentSearchSuffix => '*',
                },
            },
            Open => {
                Name   => 'Open',
                Prio   => 1100,
                Search => {
                    %Selection,
                    StateType           => 'CustomerOpen',
                    OrderBy             => $OrderByCurrent,
                    SortBy              => $SortBy,
                    CustomerUserID      => $Self->{UserID},
                    Permission          => 'ro',
                    Fulltext            => $Fulltext,
                    FullTextIndex       => 1,
                    ContentSearchPrefix => '*',
                    ContentSearchSuffix => '*',
                },
            },
            Closed => {
                Name   => 'Closed',
                Prio   => 1200,
                Search => {
                    %Selection,
                    StateType           => 'CustomerClosed',
                    OrderBy             => $OrderByCurrent,
                    SortBy              => $SortBy,
                    CustomerUserID      => $Self->{UserID},
                    Permission          => 'ro',
                    Fulltext            => $ParamObject->GetParam( Param => 'Fulltext' ),
                    FullTextIndex       => 1,
                    ContentSearchPrefix => '*',
                    ContentSearchSuffix => '*',
                },
            },
        };
    }

    my $FilterCurrent = $ParamObject->GetParam( Param => 'Filter' );
    if ( !$FilterCurrent ) {
        $FilterCurrent = ( $Self->{Subaction} && $Self->{Subaction} eq 'Search' ) ? 'All' : 'Open';
    }

    # check if filter is valid
    if ( !$Filters{ $Self->{Subaction} }->{$FilterCurrent} ) {
        my $Output = $LayoutObject->CustomerHeader(
            Title => Translatable('Error'),
        );
        $Output .= $LayoutObject->CustomerError(
            Message => $LayoutObject->{LanguageObject}->Translate( 'Invalid Filter: %s!', $FilterCurrent ),
        );
        $Output .= $LayoutObject->CustomerFooter();

        return $Output;
    }

    # check if archive search is allowed, otherwise search for all tickets
    my %SearchInArchive;
    if (
        $ConfigObject->Get('Ticket::ArchiveSystem')
        && !$ConfigObject->Get('Ticket::CustomerArchiveSystem')
        )
    {
        $SearchInArchive{ArchiveFlags} = [ 'y', 'n' ];
    }

    my %NavBarFilter;
    my $Counter         = 0;
    my $AllTickets      = 0;
    my $AllTicketsTotal = 0;
    my $TicketObject    = $Kernel::OM->Get('Kernel::System::Ticket');
    my %ZTSMFilterTicketIDs;
    my %StandardFilterTicketIDs;

    for my $Filter ( sort keys %{ $Filters{ $Self->{Subaction} } } ) {
        $Counter++;

        my @StandardTicketIDs = _ZTSMOverviewSearchAll($TicketObject,
            %{ $Filters{ $Self->{Subaction} }->{$Filter}->{Search} },
            %SearchInArchive,
            Result => 'ARRAY',
        );
        @StandardTicketIDs = _ZTSMStandardTicketIDsFilter(
            CustomerUserID => $Self->{UserID},
            TicketIDs      => \@StandardTicketIDs,
        );
        $StandardFilterTicketIDs{$Filter} = \@StandardTicketIDs;

        my @ZTSMWorkableTicketIDs = _ZTSMWorkableTicketIDs(
            CustomerUserID    => $Self->{UserID},
            CustomerUserLogin => $Self->{UserLogin},
            StateType         => $Filters{ $Self->{Subaction} }->{$Filter}->{Search}->{StateType},
            Fulltext          => $Fulltext,
            SortBy            => $SortBy,
            OrderBy           => $OrderByCurrent,
        );
        $ZTSMFilterTicketIDs{$Filter} = \@ZTSMWorkableTicketIDs;

        my %Counted;
        my $Count = grep { !$Counted{$_}++ } ( @StandardTicketIDs, @ZTSMWorkableTicketIDs );

        my $ClassA = '';
        if ( $Filter eq $FilterCurrent ) {
            $ClassA     = 'Selected';
            $AllTickets = $Count;
        }
        if ( $Filter eq 'All' ) {
            $AllTicketsTotal = $Count;
        }
        $NavBarFilter{ $Filters{ $Self->{Subaction} }->{$Filter}->{Prio} } = {
            %{ $Filters{ $Self->{Subaction} }->{$Filter} },
            Count  => $Count,
            Filter => $Filter,
            ClassA => $ClassA,
        };
    }

    my @CurrentViewableTickets = @{ $StandardFilterTicketIDs{$FilterCurrent} || [] };
    if ( $ZTSMFilterTicketIDs{$FilterCurrent} && @{ $ZTSMFilterTicketIDs{$FilterCurrent} } ) {
        my %Seen;
        @CurrentViewableTickets = grep { !$Seen{$_}++ } (
            @CurrentViewableTickets,
            @{ $ZTSMFilterTicketIDs{$FilterCurrent} },
        );
    }

    if ( ( $ParamObject->GetParam( Param => 'ExportTickets' ) || '' ) eq 'Excel' ) {
        if ($Display eq 'Dashboard') {my %Seen;@CurrentViewableTickets=grep {!$Seen{$_}++} (@{$StandardFilterTicketIDs{All}||[]},@{$ZTSMFilterTicketIDs{All}||[]});}
        return $Self->_ZTSMTicketReportExport(
            TicketIDs => \@CurrentViewableTickets,
            Filter    => $FilterCurrent,
        );
    }

    my $ExportLink = 'Action=CustomerTicketOverview'
        . ';Subaction=' . $LayoutObject->LinkEncode( $Self->{Subaction} )
        . ';Filter=' . $LayoutObject->LinkEncode($FilterCurrent)
        . ';SortBy=' . $LayoutObject->LinkEncode($SortBy)
        . ';OrderBy=' . $LayoutObject->LinkEncode($OrderByCurrent)
        . ';Display=' . $Display . ';ExportTickets=Excel';

    if ( defined $Fulltext ) {
        $ExportLink .= ';Fulltext=' . $LayoutObject->LinkEncode($Fulltext);
    }
    if ( IsArrayRefWithData( \@CustomerIDs ) ) {
        for my $CustomerID (@CustomerIDs) {
            $ExportLink .= ';CustomerIDs=' . $LayoutObject->LinkEncode($CustomerID);
        }
    }

    my $StartHit  = int( $ParamObject->GetParam( Param => 'StartHit' ) || 1 );
    my $PageShown = $Self->{UserShowTickets} || 1;
    my $TicketListHTML;
    my %PageNav;

    if ( !$AllTicketsTotal ) {

        my $CustomTexts = $ConfigObject->Get('Ticket::Frontend::CustomerTicketOverviewCustomEmptyText');

        # show message if there are no tickets
        my $TicketListObject = $Kernel::OM->Get('Kernel::Output::HTML::TicketOverview::CustomerList');
        $TicketListHTML = $TicketListObject->Run(
            TicketIDs   => [],
            NoAllTotal  => $Self->{Subaction} eq 'Search' ? 0            : 1,
            CustomTexts => ( ref $CustomTexts eq 'HASH' ) ? $CustomTexts : 0,
        );

    }
    else {

        if ( $AllTickets > $PageShown ) {

            # create pagination
            my $Link = 'Display=List;SortBy=' . $LayoutObject->Ascii2Html( Text => $SortBy )
                . ';OrderBy=' . $LayoutObject->Ascii2Html( Text => $OrderByCurrent )
                . ';Filter=' . $LayoutObject->Ascii2Html( Text => $FilterCurrent )
                . ';Subaction=' . $LayoutObject->Ascii2Html( Text => $Self->{Subaction} )
                . ';';

            # remember fulltext query
            if ( defined $Fulltext ) {
                $Link .= 'Fulltext=' . $LayoutObject->Ascii2Html( Text => $Fulltext ) . ';';
            }

            # Add CustomerIDs parameter if needed.
            if ( IsArrayRefWithData( \@CustomerIDs ) ) {
                for my $CustomerID (@CustomerIDs) {
                    $Link .= "CustomerIDs=$CustomerID;";
                }
            }

            %PageNav = $LayoutObject->PageNavBar(
                Limit     => $AllTickets || 1,
                StartHit  => $StartHit,
                PageShown => $PageShown,
                AllHits   => $AllTickets,
                Action    => 'Action=CustomerTicketOverview',
                Link      => $Link,
                IDPrefix  => 'CustomerTicketOverview',
            );
        }

        my $OrderBy = 'Down';
        if ( $OrderByCurrent eq 'Down' ) {
            $OrderBy = 'Up';
        }
        my $Sort       = '';
        my $StateSort  = '';
        my $TicketSort = '';
        my $TitleSort  = '';
        my $AgeSort    = '';
        my $QueueSort  = '';
        my $OwnerSort  = '';

        # this sets the opposite to the $OrderBy
        if ( $OrderBy eq 'Down' ) {
            $Sort = 'SortAscending';
        }
        if ( $OrderBy eq 'Up' ) {
            $Sort = 'SortDescending';
        }

        if ( $SortBy eq 'State' ) {
            $StateSort = $Sort;
        }
        elsif ( $SortBy eq 'Ticket' ) {
            $TicketSort = $Sort;
        }
        elsif ( $SortBy eq 'Title' ) {
            $TitleSort = $Sort;
        }
        elsif ( $SortBy eq 'Age' ) {
            $AgeSort = $Sort;
        }
        elsif ( $SortBy eq 'Queue' ) {
            $QueueSort = $Sort;
        }
        elsif ( $SortBy eq 'Owner' ) {
            $OwnerSort = $Sort;
        }

        my $Owner = $ConfigObject->Get('Ticket::Frontend::CustomerTicketOverview')->{Owner};
        my $Queue = $ConfigObject->Get('Ticket::Frontend::CustomerTicketOverview')->{Queue};

        if ($Owner) {
            $LayoutObject->Block(
                Name => 'OverviewNavBarPageOwner',
                Data => {
                    OrderBy   => $OrderBy,
                    OwnerSort => $OwnerSort,
                    Filter    => $FilterCurrent,
                },
            );
        }

        if ($Queue) {
            $LayoutObject->Block(
                Name => 'OverviewNavBarPageQueue',
                Data => {
                    OrderBy   => $OrderBy,
                    QueueSort => $QueueSort,
                    Filter    => $FilterCurrent,
                },
            );
        }

        # show header filter
        for my $Key ( sort keys %NavBarFilter ) {
            $LayoutObject->Block(
                Name => 'FilterHeader',
                Data => {
                    %Param,
                    %{ $NavBarFilter{$Key} },
                    Fulltext => $ParamObject->GetParam( Param => 'Fulltext' ),
                },
            );
        }

        # get the dynamic fields for this screen
        my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
        my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

        # get dynamic field config for frontend module
        my $DynamicFieldFilter = $ConfigObject->Get("Ticket::Frontend::CustomerTicketOverview")->{DynamicField};
        my $DynamicField       = $DynamicFieldObject->DynamicFieldListGet(
            Valid       => 1,
            ObjectType  => ['Ticket'],
            FieldFilter => $DynamicFieldFilter || {},
        );

        # reduce the dynamic fields to only the ones that are desinged for customer interface
        my @CustomerDynamicFields;
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $IsCustomerInterfaceCapable = $BackendObject->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsCustomerInterfaceCapable',
            );
            next DYNAMICFIELD if !$IsCustomerInterfaceCapable;

            push @CustomerDynamicFields, $DynamicFieldConfig;
        }
        $DynamicField = \@CustomerDynamicFields;

        # Dynamic fields
        # cycle trough the activated Dynamic Fields for this screen
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{$DynamicField} ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $Label = $DynamicFieldConfig->{Label};

            # get field sortable condition
            my $IsSortable = $BackendObject->HasBehavior(
                DynamicFieldConfig => $DynamicFieldConfig,
                Behavior           => 'IsSortable',
            );

            if ($IsSortable) {
                my $CSS = '';
                if (
                    $SortBy
                    && ( $SortBy eq ( 'DynamicField_' . $DynamicFieldConfig->{Name} ) )
                    )
                {
                    if ( $OrderByCurrent && ( $OrderByCurrent eq 'Up' ) ) {
                        $OrderBy = 'Down';
                        $CSS .= ' SortDescending';
                    }
                    else {
                        $OrderBy = 'Up';
                        $CSS .= ' SortAscending';
                    }
                }

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicField',
                    Data => {
                        %Param,
                        CSS => $CSS,
                    },
                );

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicFieldSortable',
                    Data => {
                        %Param,
                        OrderBy          => $OrderBy,
                        Label            => $Label,
                        DynamicFieldName => $DynamicFieldConfig->{Name},
                        Filter           => $FilterCurrent,
                    },
                );

                # example of dynamic fields order customization
                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicField_' . $DynamicFieldConfig->{Name},
                    Data => {
                        %Param,
                        CSS => $CSS,
                    },
                );

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicField_'
                        . $DynamicFieldConfig->{Name}
                        . '_Sortable',
                    Data => {
                        %Param,
                        OrderBy          => $OrderBy,
                        Label            => $Label,
                        DynamicFieldName => $DynamicFieldConfig->{Name},
                        Filter           => $FilterCurrent,
                    },
                );
            }
            else {

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicField',
                    Data => {
                        %Param,
                    },
                );

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicFieldNotSortable',
                    Data => {
                        %Param,
                        Label => $Label,
                    },
                );

                # example of dynamic fields order customization
                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicField_' . $DynamicFieldConfig->{Name},
                    Data => {
                        %Param,
                    },
                );

                $LayoutObject->Block(
                    Name => 'OverviewNavBarPageDynamicField_'
                        . $DynamicFieldConfig->{Name}
                        . '_NotSortable',
                    Data => {
                        %Param,
                        Label => $Label,
                    },
                );
            }
        }

        # show tickets
        #       $Counter = 0;
        #       for my $TicketID (@CurrentViewableTickets) {
        #           $Counter++;
        #           if (
        #               $Counter >= $StartHit
        #               && $Counter < ( $PageShown + $StartHit )
        #               )
        #           {
        #               $Self->ShowTicketStatus( TicketID => $TicketID );
        #           }
        #       }

        my $TicketListObject = $Kernel::OM->Get('Kernel::Output::HTML::TicketOverview::CustomerList');
        $TicketListHTML = $TicketListObject->Run(
            StartHit  => $StartHit,
            PageShown => $PageShown,
            TicketIDs => \@CurrentViewableTickets,
        );

    }

    my %DashboardSeen;
    my @DashboardIDs = grep {!$DashboardSeen{$_}++} (@{$StandardFilterTicketIDs{All}||[]},@{$ZTSMFilterTicketIDs{All}||[]});
    my $Dashboard = $Display eq 'Dashboard' ? $Self->_ZTSMDashboard(TicketIDs=>\@DashboardIDs,Selection=>$ParamObject->GetParam(Param=>'DashboardFilter')) : {};

    # create & return output
    my $Title = $Self->{Subaction};
    if ( $Title eq 'MyTickets' ) {
        $Title = Translatable('My Tickets');
    }
    elsif ( $Title eq 'CompanyTickets' ) {
        $Title = Translatable('Company Tickets');
    }
    my $Refresh = '';
    if ( $Self->{UserRefreshTime} ) {
        $Refresh = 60 * $Self->{UserRefreshTime};
    }
    my $Output = $LayoutObject->CustomerHeader(
        Title   => $Title,
        Refresh => $Refresh,
    );

    # AddJSData for ES
    my $ESActive = $ConfigObject->Get('Elasticsearch::Active');

    $LayoutObject->AddJSData(
        Key   => 'ESActive',
        Value => $ESActive,
    );

    my $NewTicketAccessKey = $ConfigObject->Get('CustomerFrontend::Navigation')->{'CustomerTicketMessage'}{'002-Ticket'}[0]{'AccessKey'}
        || '';

    $Output .= $LayoutObject->Output(
        TemplateFile => 'CustomerTicketOverview',
        Data         => {
            %Param,
            %PageNav,
            AccessKey      => $NewTicketAccessKey,
            TicketListHTML => $TicketListHTML,
            Fulltext       => $ParamObject->GetParam( Param => 'Fulltext' ),
            ExportLink     => $ExportLink,
            Display        => $Display,
            Dashboard      => $Dashboard,
            DashboardFilter => $ParamObject->GetParam(Param=>'DashboardFilter')||'',
        },
    );

    # build NavigationBar
    $Output .= $LayoutObject->CustomerNavigationBar();

    # get page footer
    $Output .= $LayoutObject->CustomerFooter();

    return $Output;
}

# Aggregation starts only after the existing requester/operational permission filters.
sub _ZTSMDashboard {
    my ($Self,%P)=@_;
    require DateTime;
    my $Ticket=$Kernel::OM->Get('Kernel::System::Ticket');
    my $Article=$Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $Now=defined $P{Now}?$P{Now}:time;
    my $Today=DateTime->from_epoch(epoch=>$Now,time_zone=>'UTC');
    my $Since=$Today->clone->subtract(months=>1,end_of_month=>'limit')->truncate(to=>'day');
    my %Seen;my @IDs=grep {!$Seen{$_}++} @{$P{TicketIDs}||[]};
    # Native last-closure history search, constrained to already permitted IDs.
    my %RecentClosed=map {$_=>1} @IDs ? _ZTSMOverviewSearchAll($Ticket,
        TicketID=>\@IDs,UserID=>1,StateType=>'Closed',
        TicketLastCloseTimeNewerDate=>$Since->strftime('%Y-%m-%d %H:%M:%S'),
        TicketLastCloseTimeOlderDate=>$Today->strftime('%Y-%m-%d %H:%M:%S')) : ();
    my %Lists=map {$_=>[]} qw(Outstanding Aged Closed Failed Delegated);
    for my $ID (@IDs) {
        my %T=$Ticket->TicketGet(TicketID=>$ID,DynamicFields=>1);
        next if !$T{TicketID};
        my $Group=_ZTSMNormalizeValue($T{'DynamicField_ZTicket-OwnerGroup'})||'';
        $Group=_ZTSMExportGovernanceObjectDisplayName(Value=>$Group) if $Group;
        $Group =~ s/^\d+ - //;
        my $Row={TicketID=>$ID,TicketNumber=>$T{TicketNumber},Title=>$T{Title},Type=>$T{Type}||'',OwnerGroup=>$Group,State=>$T{State},Created=>$T{Created}||$T{CreateTime}||''};
        my $Closed=($T{StateType}||'') eq 'closed';
        push @{$Lists{Outstanding}},$Row if !$Closed;
        push @{$Lists{Closed}},$Row if $Closed && $RecentClosed{$ID};
        push @{$Lists{Failed}},$Row if $Closed && ($T{State}||'') eq 'closed unsuccessful';
        if (!$Closed && $Row->{Created} =~ /^(\d{4})-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/) {
            require Time::Local;
            my $Created=eval {Time::Local::timegm($6,$5,$4,$3,$2-1,$1)};
            push @{$Lists{Aged}},$Row if defined $Created && $Created <= $Now-7*86400;
        }
        for my $Meta ($Article->ArticleList(TicketID=>$ID,IsVisibleForCustomer=>1)) {
            my %A=$Article->BackendForArticle(%{$Meta})->ArticleGet(TicketID=>$ID,ArticleID=>$Meta->{ArticleID});
            if (($A{Subject}||'') eq '[VVIP Delegate] Delegation override' && ($A{Body}||'') =~ /TESSERA VVIP DELEGATE OVERRIDE/) {push @{$Lists{Delegated}},$Row;last;}
        }
    }
    my %Titles=(Outstanding=>'Outstanding tickets',Aged=>'Unclosed for 7 days',Closed=>'Closed tickets',Failed=>'Failed tickets',Delegated=>'Delegated by IPC');
    my %Notes=(Closed=>'Closed from '.$Since->strftime('%Y-%m-%d').' to '.$Today->strftime('%Y-%m-%d').' (UTC)',Failed=>'Closed unsuccessful, all time');
    my %Result;my @Cards;
    for my $Key (qw(Outstanding Aged Closed Failed Delegated)) {
        @{$Lists{$Key}}=sort {$a->{Created} cmp $b->{Created} || $a->{TicketID}<=>$b->{TicketID}} @{$Lists{$Key}};
        $Result{$Key}=scalar @{$Lists{$Key}};
        push @Cards,{Key=>$Key,Title=>$Titles{$Key},Note=>$Notes{$Key}||'',Count=>$Result{$Key}};
    }
    my $Selected=$P{Selection}||'';
    $Result{Selected}=exists $Lists{$Selected}?{Title=>$Titles{$Selected},Note=>$Notes{$Selected}||'',Rows=>$Lists{$Selected}}:{};
    $Result{Cards}=\@Cards;$Result{AgedRows}=$Lists{Aged};
    return \%Result;
}

# ShowTicket
sub ShowTicketStatus {
    my ( $Self, %Param ) = @_;

    my $LayoutObject               = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $TicketObject               = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject              = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $CommunicationChannelObject = $Kernel::OM->Get('Kernel::System::CommunicationChannel');
    my $TicketID                   = $Param{TicketID} || return;

    # Get last customer article.
    my @ArticleList = $ArticleObject->ArticleList(
        TicketID             => $Param{TicketID},
        IsVisibleForCustomer => 1,
        OnlyLast             => 1,
    );

    my %Article;
    if ( $ArticleList[0] && IsHashRefWithData( $ArticleList[0] ) ) {
        my $ArticleBackendObject = $ArticleObject->BackendForArticle( %{ $ArticleList[0] } );
        %Article = $ArticleBackendObject->ArticleGet(
            TicketID  => $Param{TicketID},
            ArticleID => $ArticleList[0]->{ArticleID},
        );
    }

    # get ticket info
    my %Ticket = $TicketObject->TicketGet(
        TicketID      => $TicketID,
        DynamicFields => 0,
    );

    my $Subject;
    my $ConfigObject          = $Kernel::OM->Get('Kernel::Config');
    my $SmallViewColumnHeader = $ConfigObject->Get('Ticket::Frontend::CustomerTicketOverview')->{ColumnHeader};

    # Check if the last customer subject or ticket title should be shown.
    if ( $SmallViewColumnHeader eq 'LastCustomerSubject' ) {
        $Subject = $Article{Subject} || '';
    }
    else {
        $Subject = $Ticket{Title};
    }

    # Condense down the subject.
    $Subject = $TicketObject->TicketSubjectClean(
        TicketNumber => $Ticket{TicketNumber},
        Subject      => $Subject,
    );

    # Age design.
    $Ticket{CustomerAge} = $LayoutObject->CustomerAge(
        Age   => $Ticket{Age},
        Space => ' '
    ) || 0;

    # return ticket information if there is no article
    if ( !IsHashRefWithData( \%Article ) ) {
        $Article{State}        = $Ticket{State};
        $Article{TicketNumber} = $Ticket{TicketNumber};
        $Article{Body}         = $LayoutObject->{LanguageObject}->Translate('This item has no articles yet.');
    }

    # customer info (customer name)
    if ( $Article{CustomerUserID} ) {
        $Param{CustomerName} = $Kernel::OM->Get('Kernel::System::CustomerUser')->CustomerName(
            UserLogin => $Article{CustomerUserID},
        );
        $Param{CustomerName} = '(' . $Param{CustomerName} . ')' if ( $Param{CustomerName} );
    }

    # add block
    $LayoutObject->Block(
        Name => 'Record',
        Data => {
            %Article,
            %Ticket,
            Subject => $Subject,
            %Param,
        },
    );

    my $Owner = $ConfigObject->Get('Ticket::Frontend::CustomerTicketOverview')->{Owner};
    my $Queue = $ConfigObject->Get('Ticket::Frontend::CustomerTicketOverview')->{Queue};

    if ($Owner) {
        my $OwnerName = $Kernel::OM->Get('Kernel::System::User')->UserName( UserID => $Ticket{OwnerID} );
        $LayoutObject->Block(
            Name => 'RecordOwner',
            Data => {
                OwnerName => $OwnerName,
            },
        );
    }
    if ($Queue) {
        $LayoutObject->Block(
            Name => 'RecordQueue',
            Data => {
                %Ticket,
            },
        );
    }

    # get the dynamic fields for this screen
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $BackendObject      = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    # get dynamic field config for frontend module
    my $DynamicFieldFilter = $ConfigObject->Get("Ticket::Frontend::CustomerTicketOverview")->{DynamicField};
    my $DynamicField       = $DynamicFieldObject->DynamicFieldListGet(
        Valid       => 1,
        ObjectType  => ['Ticket'],
        FieldFilter => $DynamicFieldFilter || {},
    );

    # reduce the dynamic fields to only the ones that are desinged for customer interface
    my @CustomerDynamicFields;
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        my $IsCustomerInterfaceCapable = $BackendObject->HasBehavior(
            DynamicFieldConfig => $DynamicFieldConfig,
            Behavior           => 'IsCustomerInterfaceCapable',
        );
        next DYNAMICFIELD if !$IsCustomerInterfaceCapable;

        push @CustomerDynamicFields, $DynamicFieldConfig;
    }
    $DynamicField = \@CustomerDynamicFields;

    # Dynamic fields
    # cycle trough the activated Dynamic Fields for this screen
    DYNAMICFIELD:
    for my $DynamicFieldConfig ( @{$DynamicField} ) {
        next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

        # get field value
        my $Value = $BackendObject->ValueGet(
            DynamicFieldConfig => $DynamicFieldConfig,
            ObjectID           => $Ticket{TicketID},
        );

        my $ValueStrg = $BackendObject->DisplayValueRender(
            DynamicFieldConfig => $DynamicFieldConfig,
            Value              => $Value,
            ValueMaxChars      => 20,
            LayoutObject       => $LayoutObject,
        );

        $LayoutObject->Block(
            Name => 'RecordDynamicField',
            Data => {
                Value => $ValueStrg->{Value},
                Title => $ValueStrg->{Title},
            },
        );

        if ( $ValueStrg->{Link} ) {
            $LayoutObject->Block(
                Name => 'RecordDynamicFieldLink',
                Data => {
                    Value                       => $ValueStrg->{Value},
                    Title                       => $ValueStrg->{Title},
                    Link                        => $ValueStrg->{Link},
                    $DynamicFieldConfig->{Name} => $ValueStrg->{Title},
                },
            );
        }
        else {
            $LayoutObject->Block(
                Name => 'RecordDynamicFieldPlain',
                Data => {
                    Value => $ValueStrg->{Value},
                    Title => $ValueStrg->{Title},
                },
            );
        }

        # example of dynamic fields order customization
        $LayoutObject->Block(
            Name => 'RecordDynamicField' . $DynamicFieldConfig->{Name},
            Data => {
                Value => $ValueStrg->{Value},
                Title => $ValueStrg->{Title},
            },
        );

        if ( $ValueStrg->{Link} ) {
            $LayoutObject->Block(
                Name => 'RecordDynamicField' . $DynamicFieldConfig->{Name} . 'Link',
                Data => {
                    Value                       => $ValueStrg->{Value},
                    Title                       => $ValueStrg->{Title},
                    Link                        => $ValueStrg->{Link},
                    $DynamicFieldConfig->{Name} => $ValueStrg->{Title},
                },
            );
        }
        else {
            $LayoutObject->Block(
                Name => 'RecordDynamicField' . $DynamicFieldConfig->{Name} . 'Plain',
                Data => {
                    Value => $ValueStrg->{Value},
                    Title => $ValueStrg->{Title},
                },
            );
        }
    }

    return;
}

1;
