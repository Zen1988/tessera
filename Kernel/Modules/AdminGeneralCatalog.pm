# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2026 Rother OSS GmbH, https://otobo.io/
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

package Kernel::Modules::AdminGeneralCatalog;

use strict;
use warnings;

# core modules

# CPAN modules

# OTOBO modules
use Kernel::System::VariableCheck qw(IsHashRefWithData);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # set pref for columns key
    $Self->{PrefKeyIncludeInvalid} = 'IncludeInvalid' . '-' . $Self->{Action};

    my %Preferences = $Kernel::OM->Get('Kernel::System::User')->GetPreferences(
        UserID => $Self->{UserID},
    );

    $Self->{IncludeInvalid} = $Preferences{ $Self->{PrefKeyIncludeInvalid} };

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get needed object
    my $ConfigObject         = $Kernel::OM->Get('Kernel::Config');
    my $ParamObject          = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ValidObject          = $Kernel::OM->Get('Kernel::System::Valid');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    $Param{IncludeInvalid} = $ParamObject->GetParam( Param => 'IncludeInvalid' );

    if ( defined $Param{IncludeInvalid} ) {
        $Kernel::OM->Get('Kernel::System::User')->SetPreferences(
            UserID => $Self->{UserID},
            Key    => $Self->{PrefKeyIncludeInvalid},
            Value  => $Param{IncludeInvalid},
        );

        $Self->{IncludeInvalid} = $Param{IncludeInvalid};
    }

    $LayoutObject->AddJSData(
        Key   => 'GeneralCatalog::Frontend::JSColorPickerPath',
        Value => $ConfigObject->Get('GeneralCatalog::Frontend::JSColorPickerPath'),
    );

    # ------------------------------------------------------------ #
    # catalog item list
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'ItemList' ) {
        my $Class = $ParamObject->GetParam( Param => "Class" ) || '';

        # check needed class
        if ( !$Class ) {
            return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
        }

        # output overview
        $LayoutObject->Block(
            Name => 'Overview',
            Data => {
                Param     => \%Param,
                Class     => $Class,
                Subaction => $Self->{Subaction},
            },
        );
        $LayoutObject->Block(
            Name => 'OverviewItem',
            Data => {
                %Param,
                Class => $Class,
            },
        );
        $LayoutObject->Block(
            Name => 'IncludeInvalid',
            Data => {
                IncludeInvalid        => $Self->{IncludeInvalid},
                IncludeInvalidChecked => $Self->{IncludeInvalid} ? 'checked' : '',
            },
        );

        # get availability list
        my %ValidList = $ValidObject->ValidList();

        # get catalog item list
        my $ItemIDList = $GeneralCatalogObject->ItemList(
            Class => $Class,
            Valid => $Self->{IncludeInvalid} ? 0 : 1,
        );

        # check item list
        if ( !$ItemIDList || !%{$ItemIDList} ) {
            return $LayoutObject->ErrorScreen();
        }

        for my $ItemID ( sort { $ItemIDList->{$a} cmp $ItemIDList->{$b} } keys %{$ItemIDList} ) {

            # get item data
            my $ItemData = $GeneralCatalogObject->ItemGet(
                ItemID => $ItemID,
            );

            # output overview item list
            $LayoutObject->Block(
                Name => 'OverviewItemList',
                Data => {
                    %{$ItemData},
                    Valid => $ValidList{ $ItemData->{ValidID} },
                },
            );
        }

        # ActionOverview
        $LayoutObject->Block(
            Name => 'ActionAddItem',
            Data => {
                %Param,
                Class => $Class,
            },
        );

        # ActionOverview
        $LayoutObject->Block(
            Name => 'ActionOverview',
        );

        # output header and navbar
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # create output string
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminGeneralCatalog',
            Data         => \%Param,
        );

        # add footer
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # catalog item edit
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ItemEdit' ) {
        my %ItemData;

        # get params
        $ItemData{ItemID} = $ParamObject->GetParam( Param => "ItemID" );

        # add a new catalog item
        if ( $ItemData{ItemID} eq 'NEW' ) {

            # get class
            $ItemData{Class} = $ParamObject->GetParam( Param => "Class" );

            # redirect to overview
            if ( !$ItemData{Class} ) {
                return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
            }
        }

        # edit an existing catalog item
        else {

            # get item data
            my $ItemDataRef = $GeneralCatalogObject->ItemGet(
                ItemID => $ItemData{ItemID},
            );

            # Send data to JS if there is a specific screen ('Warning' item in 'ITSM::Core::IncidentState' class).
            # See bug#14682.
            if ( $ItemDataRef->{Class} eq 'ITSM::Core::IncidentState' && $ItemDataRef->{Name} eq 'Warning' ) {
                $LayoutObject->AddJSData(
                    Key   => 'WarningIncidentState',
                    Value => 1,
                );
            }

            # check item data
            if ( !$ItemDataRef ) {
                return $LayoutObject->ErrorScreen();
            }

            %ItemData = %{$ItemDataRef};
        }

        # output overview
        $LayoutObject->Block(
            Name => 'Overview',
            Data => {
                %Param,
                Class     => $ItemData{Class},
                Subaction => $Self->{Subaction},
                ItemName  => $ItemData{Name},
                ItemEdit  => $ItemData{ItemID} eq 'NEW' ? 0 : 1,
            },
        );

        # generate ValidOptionStrg
        my %ValidList        = $ValidObject->ValidList();
        my %ValidListReverse = reverse %ValidList;
        my $ValidOptionStrg  = $LayoutObject->BuildSelection(
            Name       => 'ValidID',
            Data       => \%ValidList,
            SelectedID => $ItemData{ValidID} || $ValidListReverse{valid},
            Class      => 'Modernize',
        );

        # output ItemEdit
        $LayoutObject->Block(
            Name => 'ItemEdit',
            Data => {
                %ItemData,
                ValidOptionStrg => $ValidOptionStrg,
                ItemEdit        => $ItemData{ItemID} eq 'NEW' ? 0 : 1,
            },
        );

        # show each preferences setting
        my %Preferences = ();
        if ( $ConfigObject->Get('GeneralCatalogPreferences') ) {
            %Preferences = %{ $ConfigObject->Get('GeneralCatalogPreferences') };
        }

        ITEM:
        for my $Item (

            # sort items by priority
            sort {
                if ( defined $Preferences{$a}{Priority} && defined $Preferences{$b}{Priority} ) {
                    $Preferences{$a}{Priority} <=> $Preferences{$b}{Priority};
                }

                # sort alphabetically if no priority is configured
                elsif ( !defined $Preferences{$a}{Priority} && !defined $Preferences{$b}{Priority} ) {
                    $a cmp $b;
                }

                # sort priority above non-priority
                else {
                    return int( defined $Preferences{$a}{Priority} ) <=> int( defined $Preferences{$b}{Priority} );
                }
            } keys %Preferences
            )
        {

            # skip items that don't belong to the class
            if ( $Preferences{$Item}->{Class} && $Preferences{$Item}->{Class} ne $ItemData{Class} )
            {
                next ITEM;
            }

            # find output module
            my $Module = $Preferences{$Item}->{Module}
                || 'Kernel::Output::HTML::GeneralCatalogPreferences::Generic';

            # load module
            if ( !$Kernel::OM->Get('Kernel::System::Main')->Require($Module) ) {
                return $LayoutObject->FatalError();
            }

            # create object for this preferences item
            my $Object = $Module->new(
                %{$Self},
                ConfigItem => $Preferences{$Item},
                Debug      => $Self->{Debug},
            );

            # show all parameters
            my @Params = $Object->Param( GeneralCatalogData => { %ItemData, %Param } );
            for my $ParamItem (@Params) {

                if (
                    ref( $ParamItem->{Data} ) eq 'HASH'
                    || ref( $Preferences{$Item}->{Data} ) eq 'HASH'
                    )
                {
                    $ParamItem->{'Option'} = $LayoutObject->BuildSelection(
                        %{ $Preferences{$Item} },
                        %{$ParamItem},
                        PossibleNone => !$ParamItem->{Mandatory},
                        Class        => 'Modernize' . ( $ParamItem->{Mandatory} ? ' Validate_Required' : '' ),
                        Translation  => 0,
                    );
                }

                if ( ref $ParamItem->{SelectedID} eq 'ARRAY' && !$ParamItem->{Multiple} ) {
                    $ParamItem->{SelectedID} = $ParamItem->{SelectedID}[0];
                }

                $LayoutObject->Block(
                    Name => 'PreferenceItem',
                    Data => {
                        %{ $Preferences{$Item} },
                        %{$ParamItem},
                        Type => $ParamItem->{Block} || $Preferences{$Item}->{Block} || 'Option',
                    },
                );
            }
        }

        if ( $ItemData{Class} eq 'NEW' ) {

            # output ItemEditClassAdd
            $LayoutObject->Block(
                Name => 'ItemEditClassAdd',
                Data => {
                    Class => $ItemData{Class},
                },
            );
        }
        else {

            # output ItemEditClassExist
            $LayoutObject->Block(
                Name => 'ItemEditClassExist',
                Data => {
                    Class => $ItemData{Class},
                },
            );
        }

        # ActionOverview
        $LayoutObject->Block(
            Name => 'ActionOverview',
        );

        # output header
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # create output string
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminGeneralCatalog',
            Data         => \%Param,
        );

        # add footer
        $Output .= $LayoutObject->Footer();

        return $Output;
    }

    # ------------------------------------------------------------ #
    # catalog item save
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ItemSave' ) {
        my %ItemData;

        # get params
        for my $Param (qw(Class ItemID ValidID Comment)) {
            $ItemData{$Param} = $ParamObject->GetParam( Param => $Param ) || '';
        }

        # get name param, name must be not empty, but number zero (0) is allowed
        $ItemData{Name} = $ParamObject->GetParam( Param => 'Name' );

        # check class
        if ( $ItemData{Class} eq 'NEW' ) {
            return $LayoutObject->Redirect( OP => "Action=$Self->{Action}" );
        }

        # save to database
        my $Success;
        my $ItemID = $ItemData{ItemID};
        if ( $ItemData{ItemID} eq 'NEW' ) {
            $Success = $GeneralCatalogObject->ItemAdd(
                %ItemData,
                UserID => $Self->{UserID},
            );
            $ItemID = $Success;

            if ($Success) {

                # check if item is first of class
                my $ItemList = $GeneralCatalogObject->ItemList(
                    Class => $ItemData{Class},
                    Valid => 0,
                );

                # if so, redirect into edit mask with newly created item to force setting preferences values
                if ( IsHashRefWithData($ItemList) && ( keys $ItemList->%* ) == 1 ) {
                    return $LayoutObject->Redirect(
                        OP => "Action=$Self->{Action};Subaction=ItemEdit;Class=$ItemData{Class};ItemID=$ItemID"
                    );
                }
            }
        }
        else {
            $Success = $GeneralCatalogObject->ItemUpdate(
                %ItemData,
                UserID => $Self->{UserID},
            );
        }
        if ( !$Success ) {
            return $LayoutObject->ErrorScreen();
        }

        # update preferences
        my $GCData      = $GeneralCatalogObject->ItemGet( ItemID => $ItemID );
        my %Preferences = ();
        my $Note        = '';

        if ( $ConfigObject->Get('GeneralCatalogPreferences') ) {
            %Preferences = %{ $ConfigObject->Get('GeneralCatalogPreferences') };
        }

        for my $Item ( sort keys %Preferences ) {
            my $Module = $Preferences{$Item}->{Module}
                || 'Kernel::Output::HTML::GeneralCatalogPreferences::Generic';

            # load module
            if ( !$Kernel::OM->Get('Kernel::System::Main')->Require($Module) ) {
                return $LayoutObject->FatalError();
            }

            my $Object = $Module->new(
                %{$Self},
                ConfigItem => $Preferences{$Item},
                Debug      => $Self->{Debug},
            );
            my @Params = $Object->Param( GeneralCatalogData => $GCData );
            if (@Params) {
                my %GetParam = ();
                for my $ParamItem (@Params) {
                    my @Array = $ParamObject->GetArray( Param => $ParamItem->{Name} );
                    $GetParam{ $ParamItem->{Name} } = \@Array;
                }
                if (
                    !$Object->Run(
                        GetParam => \%GetParam,
                        ItemID   => $GCData->{ItemID},
                    )
                    )
                {
                    $Note .= $LayoutObject->Notify( Info => $Object->Error() );
                }
            }
        }

        if ( !$Success ) {
            return $LayoutObject->ErrorScreen();
        }

        my $ContinueAfterSave = $ParamObject->GetParam( Param => 'ContinueAfterSave' );
        if ($ContinueAfterSave) {
            return $LayoutObject->Redirect(
                OP => "Action=$Self->{Action};Subaction=ItemEdit;Class=$ItemData{Class};ItemID=$ItemData{ItemID}"
            );
        }

        # redirect to overview class list
        return $LayoutObject->Redirect(
            OP => "Action=$Self->{Action};Subaction=ItemList;Class=$ItemData{Class}"
        );
    }

    # ------------------------------------------------------------ #
    # overview
    # ------------------------------------------------------------ #
    else {

        # output overview
        $LayoutObject->Block(
            Name => 'Overview',
            Data => {
                %Param,
            },
        );
        $LayoutObject->Block(
            Name => 'OverviewClass',
            Data => {
                %Param,
            },
        );

        # get catalog class list
        my $ClassList = $GeneralCatalogObject->ClassList();

        if ( @{$ClassList} ) {

            for my $Class ( @{$ClassList} ) {

                # output overview class list
                $LayoutObject->Block(
                    Name => 'OverviewClassList',
                    Data => {
                        Class => $Class,
                    },
                );
            }
        }

        # otherwise it displays a no data found message
        else {
            $LayoutObject->Block(
                Name => 'NoDataFoundMsg',
            );
        }

        # ActionAddClass
        $LayoutObject->Block(
            Name => 'ActionAddClass',
        );

        # output header and navbar
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();

        # create output string
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminGeneralCatalog',
            Data         => \%Param,
        );

        # add footer
        $Output .= $LayoutObject->Footer();

        return $Output;
    }
}

1;
