# --
# OTOBO is a web-based ticketing system for service organisations.
# --
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

package Kernel::System::MELTObject::MELTObjectSearch;

use v5.24;
use strict;
use warnings;
use namespace::autoclean;
use utf8;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(IsArrayRefWithData IsStringWithData);

our $ObjectManagerDisabled = 1;

=head1 NAME

Kernel::System::MELTObject::MELTObjectSearch - sub module of Kernel::System::MELT Object for MELT Object search

=head1 DESCRIPTION

All MELT Object search functions. The functions are available via the C<Kernel::System::MELTObject> object.

=head2 MELTObjectSearch()

To find MELT Objects in your system.

    my @MELTObjectIDs = $MELTObjectObject->MELTObjectSearch(
        # result (optional, default is 'HASH')
        Result => 'ARRAY' || 'HASH' || 'COUNT',

        # limit the number of found MELT Objects (optional, default is 10000)
        Limit => 100,

        # Use MELTObjectSearch as a MELT Object filter on a single MELT Object,
        # or a predefined MELT Object list
        MELTObjectID     => 1234,
        MELTObjectID     => [1234, 1235],

        # MELT Object number (optional) as STRING or as ARRAYREF
        # The value will be treated as a SQL query expression.
        Number => '%123546%',
        Number => ['%123546%', '%123666%'],

        # MELT Object name (optional) as STRING or as ARRAYREF
        # The value will be treated as a SQL query expression.
        # When ConditionInline is set then remaining whitespace will be treated as a && condition and
        # and the settings of ContentSearchPrefix and ContentSearchSuffix will be honored.
        Name => '%SomeText%',
        Name => ['%SomeTest1%', '%SomeTest2%'],

        Classes         => ['Computer', 'Network']   # (optional)
        ClassIDs        => [9, 8, 7, 6],             # (optional)

        ZTSMStatuss      => ['Production']            # (optional)
        ZTSMStatusIDs    => [1, 2, 3, 4],             # (optional)

        ZTSMStatuss   => ['Production']            # (optional)
        ZTSMStatusIDs => [1, 2, 3, 4],             # (optional)

        ZTSMStatuss      => ['Warning']               # (optional)
        ZTSMStatusIDs    => [1, 2, 3, 4],             # (optional)

        ZTSMStatuss   => ['Warning']               # (optional)
        ZTSMStatusIDs => [1, 2, 3, 4],             # (optional)

        CreateBy        => [1, 2, 3],                # (optional)
        ChangeBy        => [3, 2, 1],                # (optional)

        # DynamicFields
        #   At least one operator must be specified. Operators will be connected with AND,
        #       values in an operator with OR.
        #   You can also pass more than one argument to an operator: ['value1', 'value2']
        DynamicField_FieldNameX => {
            Empty             => 1,                       # will return dynamic fields without a value
                                                          # set to 0 to search fields with a value present
            Equals            => 123,
            Like              => 'value*',                # "equals" operator with wildcard support
            GreaterThan       => '2001-01-01 01:01:01',
            GreaterThanEquals => '2001-01-01 01:01:01',
            SmallerThan       => '2002-02-02 02:02:02',
            SmallerThanEquals => '2002-02-02 02:02:02',
        }

        # MELT Objects created more than 60 minutes ago (MELT Object older than 60 minutes)  (optional)
        MELTObjectCreateTimeOlderMinutes => 60,
        # MELT Objects created less than 120 minutes ago (MELT Object newer than 120 minutes) (optional)
        MELTObjectCreateTimeNewerMinutes => 120,

        # MELT Objects with create time after ... (MELT Object newer than this date) (optional)
        MELTObjectCreateTimeNewerDate => '2006-01-09 00:00:01',
        # MELT Objects with created time before ... (MELT Object older than this date) (optional)
        MELTObjectCreateTimeOlderDate => '2006-01-19 23:59:59',

        # MELT Objects changed more than 60 minutes ago (optional)
        MELTObjectLastChangeTimeOlderMinutes => 60,
        # MELT Objects changed less than 120 minutes ago (optional)
        MELTObjectLastChangeTimeNewerMinutes => 120,

        # MELT Objects with changed time after ... (MELT Object changed newer than this date) (optional)
        MELTObjectLastChangeTimeNewerDate => '2006-01-09 00:00:01',
        # MELT Objects with changed time before ... (MELT Object changed older than this date) (optional)
        MELTObjectLastChangeTimeOlderDate => '2006-01-19 23:59:59',

        # OrderBy (optional, default is 'Down')
        OrderBy => 'Down',  # Down|Up

        # SortBy (optional, default is 'Number')
        SortBy  => 'Name',

        # OrderBy and SortBy as ARRAY for sub sorting (optional)
        OrderBy => ['Down', 'Up'],
        SortBy  => ['MELTObjectID', 'Number'],

        # user search
        UserID     => 123,          # optional
        Permission => 'ro' || 'rw', # optional, default is 'ro'

        # CacheTTL, cache search result in seconds (optional, the default is four minutes)
        CacheTTL => 60 * 15,
    );

Returns for C<Result => 'ARRAY'>:

    @MELTObjectIDs = ( 1, 2, 3 );

Returns for C<Result => 'HASH'> or when no result type is specified:

    %MELTObjectIDs = (
        1 => '2010102700001',
        2 => '2010102700002',
        3 => '2010102700003',
    );

Returns for C<Result => 'COUNT'>:

    $NumMELTObjectIDs = 3; # three results

=cut

# TODO: Check all instances where this is called. Change DynamicFields, OrderBy -> SortBy, OrderByDirection -> OrderBy, Return => ARRAY returns not a ref
sub MELTObjectSearch {
    my ( $Self, %Param ) = @_;

    # default values
    my $Result  = $Param{Result}  || 'HASH';
    my $OrderBy = $Param{OrderBy} || 'Down';
    my $SortBy  = $Param{SortBy}  || 'Number';
    my $Limit   = $Param{Limit}   || 10000;

    my %SortOptions = (
        MELTObject => 'ci.meltid',
        Number       => 'ci.meltid',
        Name         => 'v.name',
        ZTSMStatus  => 'gc_status.name',
        Age          => 'ci.create_time',
        Created      => 'ci.create_time',
        Changed      => 'ci.change_time',
    );

    # check types of given arguments
    KEY:
    for my $Key (
        qw(
            MELTObjectID ClassIDs ZTSMStatusIDs CreateBy ChangeBy
        )
        )
    {
        next KEY if !$Param{$Key};                                      # why no search for '0' ???
        next KEY if ref $Param{$Key} eq 'ARRAY' && @{ $Param{$Key} };

        # log error
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => "The given param '$Key' is invalid or an empty array reference!",
        );

        return;
    }

    # get objects
    my $DBObject             = $Kernel::OM->Get('Kernel::System::DB');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # quote id array elements
    ARGUMENT:
    for my $Key (
        qw(
            ClassIDs ZTSMStatusIDs CreateBy ChangeBy
        )
        )
    {
        next ARGUMENT if !$Param{$Key};

        # quote elements
        for my $Element ( @{ $Param{$Key} } ) {
            if ( !defined $DBObject->Quote( $Element, 'Integer' ) ) {

                # log error
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "The given param '$Element' in '$Key' is invalid!",
                );
                return;
            }
        }
    }

    # check sort/order by options
    my @SortByArray  = ref $SortBy eq 'ARRAY'  ? $SortBy->@*  : $SortBy;
    my @OrderByArray = ref $OrderBy eq 'ARRAY' ? $OrderBy->@* : $OrderBy;

    for my $Count ( 0 .. $#SortByArray ) {
        if (
            !$SortOptions{ $SortByArray[$Count] }
            && $SortByArray[$Count] !~ /^DynamicField_/
            )
        {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Need valid SortBy (' . $SortByArray[$Count] . ')!',
            );

            return;
        }

        # TODO: fall back to a default of 'Up'
        if ( $OrderByArray[$Count] ne 'Down' && $OrderByArray[$Count] ne 'Up' ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Need valid OrderBy (' . $OrderByArray[$Count] . ')!',
            );

            return;
        }
    }

    # create sql
    my $SQLSelect;

    # TODO: add version search
    if ( $Result eq 'COUNT' ) {
        $SQLSelect = 'SELECT COUNT(DISTINCT(ci.id))';
    }
    else {
        $SQLSelect = 'SELECT DISTINCT ci.id, ci.meltid';
    }

    my $SQLFrom = ' FROM melt_object_item ci';

    # check for needed version search index table join
    my $VersionTableJoined;
    if ( $Self->_VersionSearchIndexSQLJoinNeeded( SearchParams => \%Param ) ) {
        $SQLFrom .= ' INNER JOIN melt_object_item_version v ON ci.last_version_id = v.id';
        $VersionTableJoined = 1;
    }

    my $SQLExt = ' WHERE 1 = 1';

    # Limit the search to just one (or a list) MELTObjectID
    if ( IsStringWithData( $Param{MELTObjectID} ) || IsArrayRefWithData( $Param{MELTObjectID} ) ) {

        my $SQLQueryInCondition = $Kernel::OM->Get('Kernel::System::DB')->QueryInCondition(
            Key       => 'ci.id',
            Values    => ref $Param{MELTObjectID} eq 'ARRAY' ? $Param{MELTObjectID} : [ $Param{MELTObjectID} ],
            QuoteType => 'Integer',
            BindMode  => 0,
        );
        $SQLExt .= ' AND ( ' . $SQLQueryInCondition . ' ) ';
    }

    # lookup classes
    if ( $Param{Classes} ) {

        # get class list
        my %ClassLookup = reverse %{
            $GeneralCatalogObject->ItemList(
                Class => 'ZTSM::MELT::Class',
            ) // {}
        };

        for my $Class ( @{ $Param{Classes} } ) {

            if ( !$ClassLookup{$Class} ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "No ID for $Class found!",
                );

                return;
            }

            push @{ $Param{ClassIDs} }, $ClassLookup{$Class};
        }
    }

    # permissions are handled via classes
    if ( $Param{UserID} && $Param{UserID} != 1 ) {

        my @ClassIDs = $Param{ClassIDs} ? $Param{ClassIDs}->@* :
            keys %{
                $GeneralCatalogObject->ItemList(
                    Class => 'ZTSM::MELT::Class',
                ) // {}
            };

        my @AllowedClassIDs;

        for my $ClassID (@ClassIDs) {
            my $HasAccess = $Self->Permission(
                Scope   => 'Class',
                ClassID => $ClassID,
                UserID  => $Param{UserID},
                Type    => $Param{Permission} // 'ro',
            );

            if ($HasAccess) {
                push @AllowedClassIDs, $ClassID;
            }
        }

        return if !@AllowedClassIDs;

        $Param{ClassIDs} = \@AllowedClassIDs;
    }

    # class ids
    if ( $Param{ClassIDs} ) {
        my $SQLQueryInCondition = $Kernel::OM->Get('Kernel::System::DB')->QueryInCondition(
            Key       => 'ci.class_id',
            Values    => $Param{ClassIDs},
            QuoteType => 'Integer',
            BindMode  => 0,
        );
        $SQLExt .= ' AND ( ' . $SQLQueryInCondition . ' ) ';
    }

    # lookup current ZTSM Statuss
    if ( $Param{ZTSMStatuss} ) {

        # get class list
        my %ZTSMStatusLookup = reverse %{
            $GeneralCatalogObject->ItemList(
                Class => 'ZTSM::MELT::Status',
            ) // {}
        };

        for my $ZTSMStatus ( @{ $Param{ZTSMStatuss} } ) {

            if ( !$ZTSMStatusLookup{$ZTSMStatus} ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "No ID for $ZTSMStatus found!",
                );

                return;
            }

            push @{ $Param{ZTSMStatusIDs} }, $ZTSMStatusLookup{$ZTSMStatus};
        }
    }

    # current ZTSM Status ids
    if ( $Param{ZTSMStatusIDs} ) {
        my $SQLQueryInCondition = $Kernel::OM->Get('Kernel::System::DB')->QueryInCondition(
            Key       => 'ci.ztsm_status_id',
            Values    => $Param{ZTSMStatusIDs},
            QuoteType => 'Integer',
            BindMode  => 0,
        );
        $SQLExt .= ' AND ( ' . $SQLQueryInCondition . ' ) ';
    }

    # other MELT Object stuff
    my %FieldSQLMap = (
        Number   => 'ci.meltid',
        Name     => 'v.name',
        CreateBy => 'ci.create_by',
        ChangeBy => 'ci.change_by',
    );

    ATTRIBUTE:
    for my $Key ( sort keys %FieldSQLMap ) {
        next ATTRIBUTE if !defined $Param{$Key};

        # if it's no ref, put it to array ref
        if ( ref $Param{$Key} eq '' ) {
            $Param{$Key} = [ $Param{$Key} ];
        }

        # proccess array ref
        my $Used = 0;

        VALUE:
        for my $Value ( @{ $Param{$Key} } ) {
            next VALUE if !defined $Value || !length $Value;

            $Value =~ s/\*/%/gi;

            # check search attribute, we do not need to search for *
            next VALUE if $Value =~ /^\%{1,3}$/;

            if ( !$Used ) {
                $SQLExt .= ' AND (';
                $Used = 1;
            }
            else {
                $SQLExt .= ' OR ';
            }

            # use search condition extension
            $SQLExt .= $DBObject->QueryCondition(
                Key   => $FieldSQLMap{$Key},
                Value => $Value,
            );
        }

        if ($Used) {
            $SQLExt .= ')';
        }
    }

    # Remember already joined tables for sorting.
    my %DynamicFieldJoinTables;
    my $DynamicFieldJoinCounter = 1;

    # get dynamic field objects
    my $DynamicFieldObject        = $Kernel::OM->Get('Kernel::System::DynamicField');
    my $DynamicFieldBackendObject = $Kernel::OM->Get('Kernel::System::DynamicField::Backend');

    DYNAMICFIELD:
    for my $ParamName ( keys %Param ) {
        next DYNAMICFIELD unless $ParamName =~ m/^DynamicField_(.+)/;

        my $DynamicField = $DynamicFieldObject->DynamicFieldGet(
            Name => $1,
        );

        if ( !$DynamicField->%* ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'Error',
                Message  => qq[No such dynamic field "$1" (or it is inactive)],
            );

            return;
        }

        my $SearchParam = delete $Param{"DynamicField_$DynamicField->{Name}"};

        next DYNAMICFIELD unless $SearchParam;
        next DYNAMICFIELD unless ref $SearchParam eq 'HASH';

        my $NeedJoin;
        my $QueryForEmptyValues = 0;

        for my $Operator ( sort keys $SearchParam->%* ) {

            my @SearchParams = ( ref $SearchParam->{$Operator} eq 'ARRAY' )
                ? @{ $SearchParam->{$Operator} }
                : ( $SearchParam->{$Operator} );

            my $SQLExtSub = ' AND (';
            my $Counter   = 0;
            TEXT:
            for my $Text (@SearchParams) {
                next TEXT unless defined $Text;
                next TEXT if $Text eq '';

                $Text =~ s/\*/%/gi;

                # check search attribute, we do not need to search for *
                next TEXT if $Text =~ /^\%{1,3}$/;

                # skip validation for empty values
                if ( $Operator ne 'Empty' ) {

                    # validate data type
                    my $ValidateSuccess = $DynamicFieldBackendObject->ValueValidate(
                        DynamicFieldConfig => $DynamicField,
                        Value              => $Text,
                        NoValidateRegex    => 1,
                        UserID             => $Param{UserID} || 1,
                    );
                    if ( !$ValidateSuccess ) {
                        $Kernel::OM->Get('Kernel::System::Log')->Log(
                            Priority => 'error',
                            Message  =>
                                "Search not executed due to invalid value '"
                                . $Text
                                . "' on field '"
                                . $DynamicField->{Name}
                                . "'!",
                        );
                        return;
                    }
                }

                if ($Counter) {
                    $SQLExtSub .= ' OR ';
                }

                # Empty => 1 requires a LEFT JOIN.
                if ( $Operator eq 'Empty' && $Text ) {
                    $SQLExtSub .= $DynamicFieldBackendObject->SearchSQLGet(
                        DynamicFieldConfig => $DynamicField,
                        TableAlias         => "dfvEmpty$DynamicFieldJoinCounter",
                        Operator           => $Operator,
                        SearchTerm         => $Text,
                    );
                    $QueryForEmptyValues = 1;
                }
                else {
                    $SQLExtSub .= $DynamicFieldBackendObject->SearchSQLGet(
                        DynamicFieldConfig => $DynamicField,
                        TableAlias         => "dfv$DynamicFieldJoinCounter",
                        Operator           => $Operator,
                        SearchTerm         => $Text,
                    );
                }

                $Counter++;
            }
            $SQLExtSub .= ')';
            if ($Counter) {
                $SQLExt .= $SQLExtSub;
                $NeedJoin = 1;
            }
        }

        if ($NeedJoin) {

            if ( !$VersionTableJoined ) {
                $SQLFrom .= ' INNER JOIN melt_object_item_version v ON ci.last_version_id = v.id';
                $VersionTableJoined = 1;
            }

            if ($QueryForEmptyValues) {

                # Use LEFT JOIN to allow for null values.
                $SQLFrom .= " LEFT JOIN dynamic_field_value dfvEmpty$DynamicFieldJoinCounter
                    ON (v.id = dfvEmpty$DynamicFieldJoinCounter.object_id
                        AND dfvEmpty$DynamicFieldJoinCounter.field_id = " .
                    $DBObject->Quote( $DynamicField->{ID}, 'Integer' ) . ") ";
            }
            else {
                $SQLFrom .= " INNER JOIN dynamic_field_value dfv$DynamicFieldJoinCounter
                    ON (v.id = dfv$DynamicFieldJoinCounter.object_id
                        AND dfv$DynamicFieldJoinCounter.field_id = " .
                    $DBObject->Quote( $DynamicField->{ID}, 'Integer' ) . ") ";
            }

            $DynamicFieldJoinTables{ $DynamicField->{Name} } = "dfv$DynamicFieldJoinCounter";

            $DynamicFieldJoinCounter++;
        }
    }

    # get time object
    # remember current time to prevent searches for future timestamps
    my $DateTimeObject = $Kernel::OM->Create('Kernel::System::DateTime');

    # get MELT Objects created older/newer than x minutes
    my %MELTObjectTime = (
        MELTObjectCreateTime => 'ci.create_time',
    );
    for my $Key ( sort keys %MELTObjectTime ) {

        # get MELT Objects created older than x minutes
        if ( defined $Param{ $Key . 'OlderMinutes' } ) {

            $Param{ $Key . 'OlderMinutes' } ||= 0;

            my $Time = $DateTimeObject->Clone();
            $Time->Subtract( Minutes => $Param{ $Key . 'OlderMinutes' } );

            my $TargetTime = $Key eq 'MELTObjectCreateTime' ? $Time->ToString() : $Time->ToEpoch();

            $SQLExt .= sprintf( " AND ( %s <= '%s' )", $MELTObjectTime{$Key}, $TargetTime );
        }

        # get MELT Objects created newer than x minutes
        if ( defined $Param{ $Key . 'NewerMinutes' } ) {

            $Param{ $Key . 'NewerMinutes' } ||= 0;

            my $Time = $Kernel::OM->Create('Kernel::System::DateTime');
            $Time->Subtract( Minutes => $Param{ $Key . 'NewerMinutes' } );

            my $TargetTime = $Key eq 'MELTObjectCreateTime' ? $Time->ToString() : $Time->ToEpoch();

            $SQLExt .= sprintf( " AND ( %s >= '%s' )", $MELTObjectTime{$Key}, $TargetTime );
        }
    }

    # get MELT Objects created older/newer than xxxx-xx-xx xx:xx date
    for my $Key ( sort keys %MELTObjectTime ) {

        # get MELT Objects created older than xxxx-xx-xx xx:xx date
        my $CompareOlderNewerDate;
        if ( $Param{ $Key . 'OlderDate' } ) {

            # check time format
            if (
                $Param{ $Key . 'OlderDate' }
                !~ /\d\d\d\d-(\d\d|\d)-(\d\d|\d) (\d\d|\d):(\d\d|\d):(\d\d|\d)/
                )
            {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Invalid time format '" . $Param{ $Key . 'OlderDate' } . "'!",
                );
                return;
            }

            my $Time = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    String => $Param{ $Key . 'OlderDate' },
                }
            );
            if ( !$Time ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  =>
                        "Search not executed due to invalid time '"
                        . $Param{ $Key . 'OlderDate' } . "'!",
                );
                return;
            }
            $CompareOlderNewerDate = $Time;

            my $TargetTime = $Key eq 'MELTObjectCreateTime' ? $Time->ToString() : $Time->ToEpoch();

            $SQLExt .= sprintf( " AND ( %s <= '%s' )", $MELTObjectTime{$Key}, $TargetTime );
        }

        # get MELT Objects created newer than xxxx-xx-xx xx:xx date
        if ( $Param{ $Key . 'NewerDate' } ) {
            if (
                $Param{ $Key . 'NewerDate' }
                !~ /\d\d\d\d-(\d\d|\d)-(\d\d|\d) (\d\d|\d):(\d\d|\d):(\d\d|\d)/
                )
            {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Invalid time format '" . $Param{ $Key . 'NewerDate' } . "'!",
                );
                return;
            }

            my $Time = $Kernel::OM->Create(
                'Kernel::System::DateTime',
                ObjectParams => {
                    String => $Param{ $Key . 'NewerDate' },
                }
            );
            if ( !$Time ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  =>
                        "Search not executed due to invalid time '"
                        . $Param{ $Key . 'NewerDate' } . "'!",
                );
                return;
            }

            # don't execute queries if newer date is after current date
            return if $Time > $DateTimeObject;

            # don't execute queries if older/newer date restriction show now valid timeframe
            return if $CompareOlderNewerDate && $Time > $CompareOlderNewerDate;

            my $TargetTime = $Key eq 'MELTObjectCreateTime' ? $Time->ToString() : $Time->ToEpoch();

            $SQLExt .= sprintf( " AND ( %s >= '%s' )", $MELTObjectTime{$Key}, $TargetTime );
        }
    }

    # get MELT Objects changed older than x minutes
    if ( defined $Param{MELTObjectLastChangeTimeOlderMinutes} ) {

        $Param{MELTObjectLastChangeTimeOlderMinutes} ||= 0;

        my $TimeStamp = $DateTimeObject->Clone();
        $TimeStamp->Subtract( Minutes => $Param{MELTObjectLastChangeTimeOlderMinutes} );

        $Param{MELTObjectLastChangeTimeOlderDate} = $TimeStamp->ToString();
    }

    # get MELT Objects changed newer than x minutes
    if ( defined $Param{MELTObjectLastChangeTimeNewerMinutes} ) {

        $Param{MELTObjectLastChangeTimeNewerMinutes} ||= 0;

        my $TimeStamp = $DateTimeObject->Clone();
        $TimeStamp->Subtract( Minutes => $Param{MELTObjectLastChangeTimeNewerMinutes} );

        $Param{MELTObjectLastChangeTimeNewerDate} = $TimeStamp->ToString();
    }

    # get MELT Objects changed older than xxxx-xx-xx xx:xx date
    my $CompareLastChangeTimeOlderNewerDate;
    if ( $Param{MELTObjectLastChangeTimeOlderDate} ) {

        # check time format
        if (
            $Param{MELTObjectLastChangeTimeOlderDate}
            !~ /\d\d\d\d-(\d\d|\d)-(\d\d|\d) (\d\d|\d):(\d\d|\d):(\d\d|\d)/
            )
        {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Invalid time format '$Param{MELTObjectLastChangeTimeOlderDate}'!",
            );
            return;
        }

        my $Time = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Param{MELTObjectLastChangeTimeOlderDate},
            }
        );

        if ( !$Time ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  =>
                    "Search not executed due to invalid time '"
                    . $Param{MELTObjectLastChangeTimeOlderDate} . "'!",
            );
            return;
        }
        $CompareLastChangeTimeOlderNewerDate = $Time;

        $SQLExt .= " AND ci.change_time <= '" . $Time->ToString() . "'";
    }

    # get MELT Objects changed newer than xxxx-xx-xx xx:xx date
    if ( $Param{MELTObjectLastChangeTimeNewerDate} ) {
        if (
            $Param{MELTObjectLastChangeTimeNewerDate}
            !~ /\d\d\d\d-(\d\d|\d)-(\d\d|\d) (\d\d|\d):(\d\d|\d):(\d\d|\d)/
            )
        {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "Invalid time format '$Param{MELTObjectLastChangeTimeNewerDate}'!",
            );
            return;
        }

        my $Time = $Kernel::OM->Create(
            'Kernel::System::DateTime',
            ObjectParams => {
                String => $Param{MELTObjectLastChangeTimeNewerDate},
            }
        );

        if ( !$Time ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  =>
                    "Search not executed due to invalid time '"
                    . $Param{MELTObjectLastChangeTimeNewerDate} . "'!",
            );
            return;
        }

        # don't execute queries if newer date is after current date
        return if $Time > $DateTimeObject;

        # don't execute queries if older/newer date restriction show now valid timeframe
        return
            if $CompareLastChangeTimeOlderNewerDate && $Time > $CompareLastChangeTimeOlderNewerDate;

        $SQLExt .= " AND ci.change_time >= '" . $Time->ToString() . "'";
    }

    # database query for sort/order by option
    if ( $Result ne 'COUNT' ) {
        $SQLExt .= ' ORDER BY';

        my %JoinedTables;
        for my $Count ( 0 .. $#SortByArray ) {
            if ( $Count > 0 ) {
                $SQLExt .= ',';
            }

            # sort by dynamic field
            if ( $SortByArray[$Count] =~ /^DynamicField_(.*)/ ) {
                my $DynamicFieldName = $1;
                my $DynamicField     = $DynamicFieldObject->DynamicFieldGet(
                    Name => $1,
                );

                if ( !$DynamicField ) {
                    $Kernel::OM->Get('Kernel::System::Log')->Log(
                        Priority => 'error',
                        Message  => 'Need valid SortBy (' . $SortByArray[$Count] . ')!',
                    );

                    return;
                }

                # If the table was already joined for searching, we reuse it.
                if ( !$DynamicFieldJoinTables{$DynamicFieldName} ) {

                    if ( !$VersionTableJoined ) {
                        $SQLFrom .= ' INNER JOIN melt_object_item_version v ON ci.last_version_id = v.id';
                        $VersionTableJoined = 1;
                    }

                    $SQLFrom
                        .= " LEFT OUTER JOIN dynamic_field_value dfv$DynamicFieldJoinCounter
                        ON (v.id = dfv$DynamicFieldJoinCounter.object_id
                            AND dfv$DynamicFieldJoinCounter.field_id = " .
                        $DBObject->Quote( $DynamicField->{ID}, 'Integer' ) . ") ";

                    $DynamicFieldJoinTables{ $DynamicField->{Name} } = "dfv$DynamicFieldJoinCounter";

                    $DynamicFieldJoinCounter++;
                }

                my $SQLOrderField = $DynamicFieldBackendObject->SearchSQLOrderFieldGet(
                    DynamicFieldConfig => $DynamicField,
                    TableAlias         => $DynamicFieldJoinTables{$DynamicFieldName},
                );

                $SQLSelect .= ", $SQLOrderField ";
                $SQLExt    .= " $SQLOrderField ";
            }
            else {

                # join the general catalog for sorting
                if ( $SortByArray[$Count] eq 'ZTSMStatus' && !$JoinedTables{ZTSMStatus}++ ) {
                    $SQLFrom .= ' INNER JOIN general_catalog gc_status ON (ci.ztsm_status_id = gc_status.id)';
                }

                # Regular sort.
                $SQLSelect .= ', ' . $SortOptions{ $SortByArray[$Count] };
                $SQLExt    .= ' ' . $SortOptions{ $SortByArray[$Count] };
            }

            if ( $OrderByArray[$Count] eq 'Up' ) {
                $SQLExt .= ' ASC';
            }
            else {
                $SQLExt .= ' DESC';
            }
        }
    }

    # check cache
    my $CacheObject;

    if ( $Param{CacheTTL} ) {
        $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
        my $CacheData = $CacheObject->Get(
            Type => 'MELTObjectSearch',
            Key  => $SQLSelect . $SQLFrom . $SQLExt . $Result . $Limit,
        );

        if ( defined $CacheData ) {
            if ( ref $CacheData eq 'HASH' ) {
                return %{$CacheData};
            }
            elsif ( ref $CacheData eq 'ARRAY' ) {
                return @{$CacheData};
            }
            elsif ( ref $CacheData eq '' ) {
                return $CacheData;
            }
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => 'Invalid ref ' . ref($CacheData) . '!'
            );
            return;
        }
    }

    # database query
    my %MELTObjects;
    my @MELTObjectIDs;
    my $Count;

    return if !$DBObject->Prepare(
        SQL   => $SQLSelect . $SQLFrom . $SQLExt,
        Limit => $Limit
    );

    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Count = $Row[0];
        $MELTObjects{ $Row[0] } = $Row[1];
        push @MELTObjectIDs, $Row[0];
    }

    # return COUNT
    if ( $Result eq 'COUNT' ) {
        if ($CacheObject) {
            $CacheObject->Set(
                Type  => 'MELTObjectSearch',
                Key   => $SQLSelect . $SQLFrom . $SQLExt . $Result . $Limit,
                Value => $Count,
                TTL   => $Param{CacheTTL} || 60 * 4,
            );
        }
        return $Count;
    }

    # return HASH
    elsif ( $Result eq 'HASH' ) {
        if ($CacheObject) {
            $CacheObject->Set(
                Type  => 'MELTObjectSearch',
                Key   => $SQLSelect . $SQLFrom . $SQLExt . $Result . $Limit,
                Value => \%MELTObjects,
                TTL   => $Param{CacheTTL} || 60 * 4,
            );
        }
        return %MELTObjects;
    }

    # return ARRAY
    else {
        if ($CacheObject) {
            $CacheObject->Set(
                Type  => 'MELTObjectSearch',
                Key   => $SQLSelect . $SQLFrom . $SQLExt . $Result . $Limit,
                Value => \@MELTObjectIDs,
                TTL   => $Param{CacheTTL} || 60 * 4,
            );
        }
        return @MELTObjectIDs;
    }
}

sub _VersionSearchIndexSQLJoinNeeded {
    my ( $Self, %Param ) = @_;

    for my $Attribute (qw/Name ZTSMStatuss ZTSMStatusIDs/) {
        return 1 if $Param{SearchParams}{$Attribute};
    }

    for my $Key ( keys $Param{SearchParams}->%* ) {
        return 1 if $Key =~ /^DynamicField_/;
    }

    return;
}

1;

