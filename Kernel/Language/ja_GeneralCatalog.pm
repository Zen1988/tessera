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

package Kernel::Language::ja_GeneralCatalog;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AAAGeneralCatalog
    $Self->{Translation}->{'Functionality'} = '機能性';

    # Template: AdminDynamicFieldGeneralCatalog
    $Self->{Translation}->{'Filter items by class.'} = '';
    $Self->{Translation}->{'Set the general catalog class.'} = '';

    # Template: AdminGeneralCatalog
    $Self->{Translation}->{'General Catalog Management'} = 'ジェネラル・カタログ管理';
    $Self->{Translation}->{'Items in Class'} = 'クラス内のアイテム';
    $Self->{Translation}->{'Edit Item'} = 'アイテムを修正';
    $Self->{Translation}->{'Add Class'} = 'クラスの追加';
    $Self->{Translation}->{'Add Item'} = 'アイテムを追加';
    $Self->{Translation}->{'Add Catalog Item'} = 'カタログ項目を追加';
    $Self->{Translation}->{'Add Catalog Class'} = 'カタログクラスを追加';
    $Self->{Translation}->{'Catalog Class'} = 'クラスのカタログ';
    $Self->{Translation}->{'Edit Catalog Item'} = 'カタログ・アイテムを修正';

    # JS File: ITSM.GeneralCatalog
    $Self->{Translation}->{'Warning incident state can not be set to invalid.'} = '警告インシデントのステータスを無効に設定することはできません。';

    # SysConfig
    $Self->{Translation}->{'Comment 2'} = 'コメント2';
    $Self->{Translation}->{'Create and manage the General Catalog.'} = 'ジャネラル・カタログの作成と管理します。';
    $Self->{Translation}->{'Define the general catalog comment 2.'} = 'ジェネラル・カタログのコメント 2を定義します。';
    $Self->{Translation}->{'Defines the URL JS Color Picker path.'} = 'URL JS カラーピッカーのパスを定義します。';
    $Self->{Translation}->{'Dynamic Fields GeneralCatalog Backend GUI'} = '';
    $Self->{Translation}->{'Frontend module registration for the AdminGeneralCatalog configuration in the admin area.'} =
        '管理エリアでのAdminGeneralCatalogのフロントエンドモジュールの登録します。';
    $Self->{Translation}->{'General Catalog'} = 'ジェネラル・カタログ';
    $Self->{Translation}->{'GeneralCatalog'} = '';
    $Self->{Translation}->{'Parameters for the example comment 2 of the general catalog attributes.'} =
        'ジェネラル・カタログ属性のコメント例 2の設定値';
    $Self->{Translation}->{'Parameters for the example permission groups of the general catalog attributes.'} =
        'ジェネラル・カタログの属性の権限グループの設定値例です。';
    $Self->{Translation}->{'Permission Group'} = '権限グループ';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Cancel',
    'Warning',
    'Warning incident state can not be set to invalid.',
    );

}

1;
