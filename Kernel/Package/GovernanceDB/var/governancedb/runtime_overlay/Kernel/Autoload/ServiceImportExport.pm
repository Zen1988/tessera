# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2025 Rother OSS GmbH, https://ncs.com.sg
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

## no critic (Modules::RequireExplicitPackage)

use Kernel::System::Service ();    ## no perlimports

package Kernel::System::Service;   ## no critic (Modules::RequireFilenameMatchesPackage)

use strict;
use warnings;
use v5.24;
use utf8;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(IsArrayRefWithData IsHashRefWithData);

our @ObjectDependencies = (
    'Kernel::System::DynamicField',
    'Kernel::System::DynamicField::Backend',
    'Kernel::System::GeneralCatalog',
    'Kernel::System::Queue',
    'Kernel::System::Service',
    'Kernel::System::Type',
    'Kernel::System::Valid',
);

sub ExportServices {
    my ( $Self, %Param ) = @_;

    my $UserID = $Self->{UserID} || $Param{UserID};

    my %ServiceFilter;
    if ( IsArrayRefWithData( $Param{Services} ) ) {
        %ServiceFilter = map { $_ => 1 } $Param{Services}->@*;
    }

    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $GeneralCatalogObject      = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $ServiceObject             = $Kernel::OM->Get('Kernel::System::Service');
    my $TypeObject                = $Kernel::OM->Get('Kernel::System::Type');
    my $ServiceDynamicFields      = $DynamicFieldObject->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => ['Service'],
    ) || [];
    my $ServiceTypeList = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::Service::Type',
        Valid => 0,
    ) || {};

    my %ServiceList = $ServiceObject->ServiceList(
        Valid  => 0,
        UserID => $UserID,
    );

    my %ExportData;
    SERVICEID:
    for my $ServiceID ( sort keys %ServiceList ) {

        my %ServiceData = $ServiceObject->ServiceGet(
            ServiceID => $ServiceID,
            UserID    => $UserID,
        );

        if (%ServiceFilter) {
            next SERVICEID unless $ServiceFilter{ $ServiceData{Name} };
        }

        # translate IDs into names or name-like identifiers
        my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
        my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');

        ATTRIBUTE:
        for my $Attribute ( keys %ServiceData ) {

            next ATTRIBUTE unless $Attribute =~ /ID/;

            if ( $Attribute eq 'ParentID' ) {
                my $ParentService = $ServiceObject->ServiceLookup(
                    ServiceID => $ServiceData{ParentID},
                );
                $ServiceData{Parent} = $ParentService;
                delete $ServiceData{ParentID};
            }
            elsif ( $Attribute eq 'ValidID' ) {
                my $Valid = $ValidObject->ValidLookup(
                    ValidID => $ServiceData{ValidID},
                );
                $ServiceData{Valid} = $Valid;
                $ServiceData{State} = $Valid;
                delete $ServiceData{ValidID};
            }
            elsif ( $Attribute eq 'DestQueueID' ) {
                my $Queue = $QueueObject->QueueLookup(
                    QueueID => $ServiceData{DestQueueID},
                );
                $ServiceData{DestQueue} = $Queue;
                $ServiceData{TicketDestinationQueue} = $Queue;
                delete $ServiceData{DestQueueID};
            }
            elsif ( $Attribute eq 'TicketTypeIDs' ) {
                if ( IsArrayRefWithData( $ServiceData{TicketTypeIDs} ) ) {
                    my @TicketTypes;
                    for my $TicketTypeID ( $ServiceData{TicketTypeIDs}->@* ) {
                        push @TicketTypes, $TypeObject->TypeLookup(
                            TypeID => $TicketTypeID,
                        );
                    }
                    $ServiceData{TicketTypes} = \@TicketTypes;
                    delete $ServiceData{TicketTypeIDs};
                }
            }
        }

        delete $ServiceData{ChangeBy};
        delete $ServiceData{ChangeTime};
        delete $ServiceData{CreateBy};
        delete $ServiceData{CreateTime};
        delete $ServiceData{ServiceID};

        $ServiceData{Service} = $ServiceData{Name};

        $ServiceData{Type} = $ServiceData{TypeID} ? $ServiceTypeList->{ $ServiceData{TypeID} } || '' : '';
        delete $ServiceData{TypeID};

        DYNAMICFIELD:
        for my $DynamicFieldConfig ( $ServiceDynamicFields->@* ) {
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $Value = $DynamicFieldBackendObject->ValueGet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $ServiceID,
                UserID             => $UserID,
            );
            next DYNAMICFIELD if !defined $Value;

            $ServiceData{DynamicFields}->{ $DynamicFieldConfig->{Name} } = $Value;

            if ( $DynamicFieldConfig->{Name} eq 'ZService-Field' ) {
                $ServiceData{'ZService-Field'} = $Value;
            }
        }

        if ( IsHashRefWithData( $ServiceData{Descriptions} ) ) {
            my $Descriptions = $ServiceData{Descriptions};
            my $Language     = ( sort keys $Descriptions->%* )[0];

            if ($Language) {
                $ServiceData{ShortDescription} = $Descriptions->{$Language}->{DescriptionShort};
                $ServiceData{LongDescription}  = $Descriptions->{$Language}->{DescriptionLong};
            }
        }

        $ExportData{ $ServiceData{Name} } = \%ServiceData;
    }

    return \%ExportData;
}

sub ImportServices {
    my ( $Self, %Param ) = @_;

    my $UserID = $Self->{UserID} || $Param{UserID};

    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');
    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $GeneralCatalogObject      = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $DBObject                  = $Kernel::OM->Get('Kernel::System::DB');
    my $QueueObject               = $Kernel::OM->Get('Kernel::System::Queue');
    my $ServiceObject             = $Kernel::OM->Get('Kernel::System::Service');
    my $TypeObject                = $Kernel::OM->Get('Kernel::System::Type');
    my $ValidObject               = $Kernel::OM->Get('Kernel::System::Valid');
    my %ServiceList               = $ServiceObject->ServiceList(
        Valid  => 0,
        UserID => $UserID,
    );
    my %ServiceLookup = reverse %ServiceList;
    my %TicketTypeList = $TypeObject->TypeList(
        Valid => 0,
    );
    my $ServiceTypeList = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::Service::Type',
        Valid => 0,
    );
    my %ServiceTypeLookup;
    SERVICE_TYPE_ID:
    for my $ServiceTypeID ( sort keys $ServiceTypeList->%* ) {
        my $ServiceType = $ServiceTypeList->{$ServiceTypeID};
        next SERVICE_TYPE_ID if !defined $ServiceType;

        $ServiceTypeLookup{$ServiceType} = $ServiceTypeID;
        $ServiceTypeLookup{ _ServiceImportStringNormalize($ServiceType) } = $ServiceTypeID;
    }
    my %TicketTypeLookup;
    TICKET_TYPE_ID:
    for my $TicketTypeID ( sort keys %TicketTypeList ) {
        my $TicketType = $TicketTypeList{$TicketTypeID};
        next TICKET_TYPE_ID if !defined $TicketType;

        $TicketTypeLookup{$TicketType} = $TicketTypeID;
        $TicketTypeLookup{ _ServiceImportStringNormalize($TicketType) } = $TicketTypeID;
    }
    my $ServiceDynamicFields = $DynamicFieldObject->DynamicFieldListGet(
        Valid      => 1,
        ObjectType => ['Service'],
    ) || [];
    my %ServiceDynamicFieldByName = map { $_->{Name} => $_ } grep { IsHashRefWithData($_) } $ServiceDynamicFields->@*;

    # sort services by parent attribute
    my @FirstLevelServices;
    my @ChildServices;
    SERVICE_KEY:
    for my $ServiceName ( keys $Param{Services}->%* ) {
        next SERVICE_KEY if !IsHashRefWithData( $Param{Services}{$ServiceName} );

        $Param{Services}{$ServiceName}{Name} = _ServiceImportName(
            ServiceName => $ServiceName,
            ServiceData => $Param{Services}{$ServiceName},
        );

        if ( $Param{Services}{$ServiceName}{Parent} ) {
            push @ChildServices, $ServiceName;
        }
        else {
            push @FirstLevelServices, $ServiceName;
        }
    }
    my @ChildServicesSorted = sort {
        if ( ( $Param{Services}{$a}{Parent} // '' ) eq $Param{Services}{$b}{Name} ) {
            return 1;
        }
        elsif ( ( $Param{Services}{$b}{Parent} // '' ) eq $Param{Services}{$a}{Name} ) {
            return -1;
        }
        else {
            return 0;
        }
    } @ChildServices;

    my $ACLRefreshNeeded;

    SERVICENAME:
    for my $ServiceName ( @FirstLevelServices, @ChildServicesSorted ) {
        my $ServiceData = $Param{Services}{$ServiceName};

        if ( !$ServiceData->{Name} && $ServiceData->{Service} ) {
            $ServiceData->{Name} = $ServiceData->{Service};
        }
        if ( !$ServiceData->{NameShort} && $ServiceData->{Name} ) {
            my @NameParts = split m{::}, $ServiceData->{Name};
            $ServiceData->{NameShort} = $NameParts[-1];
        }
        if ( !$ServiceData->{Parent} && $ServiceData->{Name} && $ServiceData->{Name} =~ m{ \A (.*) :: .+? \z }xms ) {
            $ServiceData->{Parent} = $1;
        }
        if ( !$ServiceData->{DestQueue} && $ServiceData->{TicketDestinationQueue} ) {
            $ServiceData->{DestQueue} = $ServiceData->{TicketDestinationQueue};
        }

        # skip if parent attribute present but no corresponding service
        if ( $ServiceData->{Parent} ) {
            my $ParentServiceID = $ServiceObject->ServiceLookup(
                Name => $ServiceData->{Parent},
            );

            next SERVICENAME unless $ParentServiceID;

            $ServiceData->{ParentID} = $ParentServiceID;
        }

        # in case of child service, check if all parent services are present
        #   either in the system or in the import data
        my @NameElements = split( /::/, $ServiceData->{Name} );
        if ( scalar @NameElements > 1 ) {
            my $NameStrg = '';
            for my $Index ( 0 .. $#NameElements - 1 ) {
                if ($NameStrg) {
                    $NameStrg .= '::' . $NameElements[$Index];
                }
                else {
                    $NameStrg .= $NameElements[$Index];
                }

                if ( !$ServiceLookup{$NameStrg} && !$Param{Services}{$NameStrg} ) {

                    # parent element not found, skipping
                    next SERVICENAME;
                }
            }
        }

        my $ServiceID = $ServiceLookup{ $ServiceData->{Name} };

        # skip if service with same name exists and overwrite is not set
        next SERVICENAME if ( !$Param{OverwriteExistingEntities} && $ServiceID );

        # translate named service type back to ID
        if ( defined $ServiceData->{Type} && $ServiceData->{Type} ne '' ) {
            my $Type = _ServiceImportStringNormalize( $ServiceData->{Type} );
            $ServiceData->{TypeID} = $ServiceTypeLookup{ $ServiceData->{Type} } || $ServiceTypeLookup{$Type};

            if ( !$ServiceData->{TypeID} ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Could not resolve service Type '$ServiceData->{Type}' in GeneralCatalog class ITSM::Service::Type.",
                );
                return;
            }
        }

        if ( !$ServiceData->{TicketTypes} && $ServiceData->{TicketType} ) {
            $ServiceData->{TicketTypes} = [ $ServiceData->{TicketType} ];
        }

        if ( $ServiceID && ( !$ServiceData->{TypeID} || !$ServiceData->{Criticality} ) ) {
            my %ExistingServiceData = $ServiceObject->ServiceGet(
                ServiceID => $ServiceID,
                UserID    => $UserID,
            );

            $ServiceData->{TypeID}      ||= $ExistingServiceData{TypeID};
            $ServiceData->{Criticality} ||= $ExistingServiceData{Criticality};
        }
        if ( !$ServiceData->{Valid} && $ServiceData->{State} ) {
            $ServiceData->{Valid} = $ServiceData->{State};
        }
        if ( $ServiceData->{DestQueue} ) {
            $ServiceData->{DestQueueID} = $QueueObject->QueueLookup(
                Queue => $ServiceData->{DestQueue},
            );
        }
        if ( IsArrayRefWithData( $ServiceData->{TicketTypes} ) ) {
            my @TicketTypeIDs;
            for my $TicketType ( $ServiceData->{TicketTypes}->@* ) {
                my $TicketTypeID = $TicketTypeLookup{$TicketType}
                    || $TicketTypeLookup{ _ServiceImportStringNormalize($TicketType) };

                if ( !$TicketTypeID ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'error',
                        Message  => "Could not resolve service TicketTypes value '$TicketType' in ticket types.",
                    );
                    return;
                }

                push @TicketTypeIDs, $TicketTypeID;
            }
            $ServiceData->{TicketTypeIDs} = \@TicketTypeIDs;
        }
        $ServiceData->{ValidID} = $ValidObject->ValidLookup(
            Valid => $ServiceData->{Valid},
        );

        $ServiceData->{DynamicFields} ||= {};
        if ( $ServiceData->{'ZService-Field'} && !exists $ServiceData->{DynamicFields}->{'ZService-Field'} ) {
            $ServiceData->{DynamicFields}->{'ZService-Field'} = $ServiceData->{'ZService-Field'};
        }

        if ( ( $ServiceData->{ShortDescription} || $ServiceData->{LongDescription} ) && !$ServiceData->{Descriptions} ) {
            $ServiceData->{Descriptions} = {
                en => {
                    ContentType      => 'text/html',
                    DescriptionShort => $ServiceData->{ShortDescription} || '',
                    DescriptionLong  => $ServiceData->{LongDescription}  || '',
                },
            };
        }

        if ( !$ServiceData->{Descriptions} ) {
            if ($ServiceID) {
                my %ExistingServiceData = $ServiceObject->ServiceGet(
                    ServiceID => $ServiceID,
                    UserID    => $UserID,
                );
                $ServiceData->{Descriptions} = $ExistingServiceData{Descriptions};
            }
            else {
                $ServiceData->{Descriptions} = {
                    en => {
                        ContentType      => 'text/html',
                        DescriptionShort => '',
                        DescriptionLong  => '',
                    },
                };
            }
        }

        if ( IsHashRefWithData( $ServiceData->{Descriptions} ) ) {
            DESCRIPTION_LANGUAGE:
            for my $Language ( sort keys $ServiceData->{Descriptions}->%* ) {
                next DESCRIPTION_LANGUAGE if !IsHashRefWithData( $ServiceData->{Descriptions}{$Language} );

                $ServiceData->{Descriptions}{$Language}{ContentType} ||= 'text/html';
                $ServiceData->{Descriptions}{$Language}{DescriptionShort} //= '';
                $ServiceData->{Descriptions}{$Language}{DescriptionLong}  //= '';
            }
        }

        my %DynamicFieldValues = %{ delete $ServiceData->{DynamicFields} || {} };
        my %ServicePreferences = $Self->_ServiceImportPreferencesExtract(
            ServiceData => $ServiceData,
        );

        my $ImportedServiceID;
        if ($ServiceID) {

            my $Success = $ServiceObject->ServiceUpdate(
                $ServiceData->%*,
                Name      => $ServiceData->{NameShort},
                ServiceID => $ServiceID,
                UserID    => $UserID,
            );
            return unless $Success;
            $ImportedServiceID = $ServiceID;
        }
        else {
            my $ServiceID = $ServiceObject->ServiceAdd(
                $ServiceData->%*,
                Name   => $ServiceData->{NameShort},
                UserID => $UserID,
            );
            return unless $ServiceID;
            $ImportedServiceID = $ServiceID;
            $ServiceLookup{ $ServiceData->{Name} } = $ServiceID;
        }
        $ACLRefreshNeeded = 1;

        $Self->_ServiceImportCorePreferencesDelete(
            DBObject  => $DBObject,
            ServiceID => $ImportedServiceID,
        );

        if ( IsArrayRefWithData( $ServiceData->{TicketTypeIDs} ) ) {
            my $Success = $ServiceObject->ServicePreferencesSet(
                ServiceID => $ImportedServiceID,
                Key       => 'TicketTypeIDs',
                Value     => join( ',', $ServiceData->{TicketTypeIDs}->@* ),
                UserID    => $UserID,
            );
            return if !$Success;
        }

        DYNAMICFIELD:
        for my $DynamicFieldName ( sort keys %DynamicFieldValues ) {
            my $DynamicFieldConfig = $ServiceDynamicFieldByName{$DynamicFieldName};
            next DYNAMICFIELD if !IsHashRefWithData($DynamicFieldConfig);

            my $ValueSet = $DynamicFieldBackendObject->ValueSet(
                DynamicFieldConfig => $DynamicFieldConfig,
                ObjectID           => $ImportedServiceID,
                Value              => $DynamicFieldValues{$DynamicFieldName},
                UserID             => $UserID,
            );
            return if !$ValueSet;
        }

        PREFERENCE:
        for my $Key ( sort keys %ServicePreferences ) {
            next PREFERENCE if !defined $ServicePreferences{$Key};

            my $Success = $ServiceObject->ServicePreferencesSet(
                ServiceID => $ImportedServiceID,
                Key       => $Key,
                Value     => $ServicePreferences{$Key},
                UserID    => $UserID,
            );
            return if !$Success;
        }
    }

    if ($ACLRefreshNeeded) {
        my $Success = $ServiceObject->UpdateTypServiceACLs(
            UserID => $UserID,
        );
        return if !$Success;
    }

    return 1;
}

sub _ServiceImportPreferencesExtract {
    my ( $Self, %Param ) = @_;

    my $ServiceData = $Param{ServiceData} || {};

    my %CoreAttribute = _ServiceImportCoreAttributes();

    my %Preferences;
    ATTRIBUTE:
    for my $Attribute ( keys $ServiceData->%* ) {
        next ATTRIBUTE if $CoreAttribute{$Attribute};
        next ATTRIBUTE if ref $ServiceData->{$Attribute};

        $Preferences{$Attribute} = delete $ServiceData->{$Attribute};
    }

    return %Preferences;
}

sub _ServiceImportCorePreferencesDelete {
    my ( $Self, %Param ) = @_;

    return if !$Param{DBObject};
    return if !$Param{ServiceID};

    my %CoreAttribute = _ServiceImportCoreAttributes();

    COREATTRIBUTE:
    for my $Attribute ( sort keys %CoreAttribute ) {
        next COREATTRIBUTE if !$Attribute;
        next COREATTRIBUTE if $Attribute eq 'TicketType';
        next COREATTRIBUTE if $Attribute eq 'TicketTypes';
        next COREATTRIBUTE if $Attribute eq 'TicketTypeIDs';

        my $Success = $Param{DBObject}->Do(
            SQL  => 'DELETE FROM service_preferences WHERE service_id = ? AND preferences_key = ?',
            Bind => [ \$Param{ServiceID}, \$Attribute ],
        );
        return if !$Success;
    }

    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'ServicePreferencesDB',
    );
    $Kernel::OM->Get('Kernel::System::Cache')->CleanUp(
        Type => 'Service',
    );

    return 1;
}

sub _ServiceImportCoreAttributes {
    return map { $_ => 1 } qw(
        ChangeBy ChangeTime Comment CreateBy CreateTime Criticality
        CurInciState CurInciStateID CurInciStateType State
        DestQueue DestQueueID
        Descriptions DynamicFields LongDescription Name NameShort Parent ParentID Service
        ServiceID ShortDescription Type TypeID Valid ValidID ZService-Field
        TicketDestinationQueue TicketType TicketTypes TicketTypeIDs
    );
}

sub _ServiceImportName {
    my (%Param) = @_;

    my $ServiceData = $Param{ServiceData} || {};

    return $ServiceData->{Name}    if defined $ServiceData->{Name}    && $ServiceData->{Name} ne '';
    return $ServiceData->{Service} if defined $ServiceData->{Service} && $ServiceData->{Service} ne '';
    return $Param{ServiceName};
}

sub _ServiceImportStringNormalize {
    my ($Value) = @_;

    $Value //= '';
    $Value =~ s{\A\s+|\s+\z}{}g;
    $Value =~ s{\s+}{ }g;

    return lc $Value;
}

1;
