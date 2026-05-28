# --
# OTOBO is a web-based ticketing system for service organisations.
# --
# Copyright (C) 2001-2020 OTRS AG, https://otrs.com/
# Copyright (C) 2019-2024 Rother OSS GmbH, https://otobo.io/
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

package Kernel::Language::ja_ITSMIncidentProblemManagement;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    # Template: AgentTicketOverviewMedium
    $Self->{Translation}->{'Criticality'} = '重要度';
    $Self->{Translation}->{'Impact'} = '影響度';

    # JS Template: ServiceIncidentState
    $Self->{Translation}->{'Service Incident State'} = 'サービスインシデント状況';

    # Perl Module: Kernel/Output/HTML/FilterElementPost/ITSMIncidentProblemManagement.pm
    $Self->{Translation}->{'Link ticket'} = 'チケットをリンクする';
    $Self->{Translation}->{'Change Decision of %s%s%s'} = '%s%s%sの決定を変更';
    $Self->{Translation}->{'Change ITSM fields of %s%s%s'} = '%s%s%sのITSMフィールドを変更';

    # Perl Module: var/packagesetup/ITSMIncidentProblemManagement.pm
    $Self->{Translation}->{'Review Required'} = 'レビュー必須';
    $Self->{Translation}->{'Decision Result'} = '決定結果';
    $Self->{Translation}->{'Approved'} = '承認';
    $Self->{Translation}->{'Postponed'} = '延期';
    $Self->{Translation}->{'Pre-approved'} = '事前承認済み';
    $Self->{Translation}->{'Rejected'} = '拒否';
    $Self->{Translation}->{'Repair Start Time'} = '修理開始時間';
    $Self->{Translation}->{'Recovery Start Time'} = '回復開始時間';
    $Self->{Translation}->{'Decision Date'} = '決定日付';
    $Self->{Translation}->{'Due Date'} = '対応期限';

    # Database XML / SOPM Definition: ITSMIncidentProblemManagement.sopm
    $Self->{Translation}->{'closed with workaround'} = 'ワークアラウンドで完了';

    # SysConfig
    $Self->{Translation}->{'Add a decision!'} = '決定を追加する！';
    $Self->{Translation}->{'Additional ITSM Fields'} = '追加のITSM項目';
    $Self->{Translation}->{'Additional ITSM ticket fields.'} = '追加の ITSM チケット･フィールド';
    $Self->{Translation}->{'Allows adding notes in the additional ITSM field screen of the agent interface.'} =
        '担当者インターフェイスのITSMフィールド画面でメモの追加を許可します。';
    $Self->{Translation}->{'Allows adding notes in the decision screen of the agent interface.'} =
        '担当者インタフェースの決定 画面で、メモの追加を許可します。';
    $Self->{Translation}->{'Allows defining new types for ticket (if ticket type feature is enabled).'} =
        'チケットに関して新規タイプを定義することを許可します（チケット責任者機能が有効となっている場合）。';
    $Self->{Translation}->{'Change the ITSM fields!'} = 'ITSM項目を変更する！';
    $Self->{Translation}->{'Decision'} = '決定';
    $Self->{Translation}->{'Defines if a ticket lock is required in the additional ITSM field screen of the agent interface (if the ticket isn\'t locked yet, the ticket gets locked and the current agent will be set automatically as its owner).'} =
        '担当者 インターフェイスの ITSM フィールド画面でチケット ロックが必要かどうかを定義します。 (チケットがまだロックされていない場合、チケットはロックされ、現在の担当者がその所有者として自動的に設定されます。)';
    $Self->{Translation}->{'Defines if a ticket lock is required in the decision screen of the agent interface (if the ticket isn\'t locked yet, the ticket gets locked and the current agent will be set automatically as its owner).'} =
        '担当者インターフェイスの決定画面でチケット ロックが必要かどうかを定義します。 (チケットがまだロックされていない場合、チケットはロックされ、現在の担当者が自動的に所有者として設定されます。)';
    $Self->{Translation}->{'Defines if the service incident state should be shown during service selection in the agent interface.'} =
        '担当者インターフェイスでサービス選択時にサービスインシデント・ステータスを表示するか定義します。';
    $Self->{Translation}->{'Defines the default body of a note in the additional ITSM field screen of the agent interface.'} =
        '担当者インタフェースの追加のITSMのフィールド画面で用いるデフォルトのメモ本文を定義します。';
    $Self->{Translation}->{'Defines the default body of a note in the decision screen of the agent interface.'} =
        '担当者インタフェースの決定画面で用いるデフォルトのメモ本文を定義します。';
    $Self->{Translation}->{'Defines the default next state of a ticket after adding a note, in the additional ITSM field screen of the agent interface.'} =
        '担当者インタフェースの追加のITSMのフィールド画面で、メモ追加後の「次の状態」についてデフォルトの選択肢を定義します。';
    $Self->{Translation}->{'Defines the default next state of a ticket after adding a note, in the decision screen of the agent interface.'} =
        '担当者インタフェースの決定画面で、メモ追加後の「次の状態」についてデフォルトの選択肢を定義します。';
    $Self->{Translation}->{'Defines the default subject of a note in the additional ITSM field screen of the agent interface.'} =
        '担当者インターフェイスの追加 ITSMフィールド画面で用いるデフォルトのメモの件名を定義します。';
    $Self->{Translation}->{'Defines the default subject of a note in the decision screen of the agent interface.'} =
        '担当者インターフェイスの決定画面でメモのデフォルトの件名を定義します。';
    $Self->{Translation}->{'Defines the default ticket priority in the additional ITSM field screen of the agent interface.'} =
        '担当者インターフェイスの追加ITSMフィールド画面でデフォルトのチケット優先度を定義します。';
    $Self->{Translation}->{'Defines the default ticket priority in the decision screen of the agent interface.'} =
        '担当者インターフェイスの決定画面でデフォルトのチケット優先度を定義します。';
    $Self->{Translation}->{'Defines the history comment for the additional ITSM field screen action, which gets used for ticket history.'} =
        'チケット履歴に使用される、追加の ITSM フィールド画面アクションの履歴コメントを定義します。';
    $Self->{Translation}->{'Defines the history comment for the decision screen action, which gets used for ticket history.'} =
        'チケット履歴に使用される、決定画面アクションの履歴コメントを定義します。';
    $Self->{Translation}->{'Defines the history type for the additional ITSM field screen action, which gets used for ticket history.'} =
        '追加の ITSM フィールド画面アクションの履歴タイプを定義します。これはチケット履歴に使用されます。';
    $Self->{Translation}->{'Defines the history type for the decision screen action, which gets used for ticket history.'} =
        'チケット履歴に使用される、決定画面アクションの履歴タイプを定義します。';
    $Self->{Translation}->{'Defines the next state of a ticket after adding a note, in the additional ITSM field screen of the agent interface.'} =
        '担当者インターフェイスの追加 ITSMフィールド画面で、メモ追加後のチケットの次の状態について選択肢を定義します。';
    $Self->{Translation}->{'Defines the next state of a ticket after adding a note, in the decision screen of the agent interface.'} =
        '担当者インターフェイスの決定画面で、メモ追加後のチケットの次の状態について選択肢を定義します。';
    $Self->{Translation}->{'Dynamic fields shown in the additional ITSM field screen of the agent interface.'} =
        '担当者インターフェイスの ITSMフィールド画面に表示するダイナミック・フィールド';
    $Self->{Translation}->{'Dynamic fields shown in the decision screen of the agent interface.'} =
        '担当者インターフェイスの決定画面に表示するダイナミック・フィールド';
    $Self->{Translation}->{'Dynamic fields shown in the ticket zoom screen of the agent interface.'} =
        '担当者インターフェイスのチケットズーム画面に表示するダイナミック・フィールド';
    $Self->{Translation}->{'Enables the stats module to generate statistics about the average of ITSM ticket first level solution rate.'} =
        '統計モジュールが ITSM チケットの第 1 レベルのソリューション率の平均に関する統計を生成できるようにします。';
    $Self->{Translation}->{'Enables the stats module to generate statistics about the average of ITSM ticket solution.'} =
        '統計モジュールが ITSM チケット ソリューションの平均に関する統計を生成できるようにします。';
    $Self->{Translation}->{'If a note is added by an agent, sets the state of a ticket in the additional ITSM field screen of the agent interface.'} =
        '担当者によってメモが追加された場合、担当者インターフェイスの追加 ITSM フィールド画面でチケットのステータスを設定します。';
    $Self->{Translation}->{'If a note is added by an agent, sets the state of a ticket in the decision screen of the agent interface.'} =
        '担当者によってメモが追加された場合、担当者インターフェイスの決定画面でチケットのステータスを設定します。';
    $Self->{Translation}->{'Modifies the display order of the dynamic field ITSMImpact and other things.'} =
        'ダイナミック・フィールド ITSM影響度 影響度表示順序を変更します。';
    $Self->{Translation}->{'Module to dynamically show the service incident state and to calculate the priority.'} =
        'サービスインシデントのステータスを動的に表示し、優先度を計算するモジュール';
    $Self->{Translation}->{'Required permissions to use the additional ITSM field screen in the agent interface.'} =
        '担当者インターフェイスで追加の ITSM フィールド画面を使用するために必要な権限';
    $Self->{Translation}->{'Required permissions to use the decision screen in the agent interface.'} =
        '担当者インターフェイスの決定画面を使用するために必要な権限';
    $Self->{Translation}->{'Service Incident State and Priority Calculation'} = 'サービスインシデントのステータスと優先度の計算';
    $Self->{Translation}->{'Sets the service in the additional ITSM field screen of the agent interface (Ticket::Service needs to be activated).'} =
        '担当者インターフェースの追加ITSMフィールド画面でサービスを設定します。(Ticket::Serviceを有効化する必要があります。)';
    $Self->{Translation}->{'Sets the service in the decision screen of the agent interface (Ticket::Service needs to be activated).'} =
        '担当者インターフェースの決定画面でサービスを設定します。（Ticket::Serviceを有効化する必要があります。）';
    $Self->{Translation}->{'Sets the service in the ticket priority screen of a zoomed ticket in the agent interface (Ticket::Service needs to be activated).'} =
        '担当者インターフェースのズームチケットのチケット優先度画面でサービスを設定します・（Ticket::Serviceを有効にする必要があります。）';
    $Self->{Translation}->{'Sets the ticket owner in the additional ITSM field screen of the agent interface.'} =
        '担当者インターフェイスの追加ITSMフィールド画面でチケット所有者を設定します。';
    $Self->{Translation}->{'Sets the ticket owner in the decision screen of the agent interface.'} =
        '担当者インターフェースの決定画面でチケット所有者を設定します。';
    $Self->{Translation}->{'Sets the ticket responsible in the additional ITSM field screen of the agent interface.'} =
        '担当者インターフェイスの追加ITSMフィールド画面で担当するチケットを設定します。';
    $Self->{Translation}->{'Sets the ticket responsible in the decision screen of the agent interface.'} =
        '担当者インターフェースの決定画面で担当するチケットを設定します。';
    $Self->{Translation}->{'Sets the ticket type in the additional ITSM field screen of the agent interface (Ticket::Type needs to be activated).'} =
        '担当者インターフェイスの追加ITSMフィールド画面でチケットタイプを設定します・(Ticket::Typeを有効化する必要があります。)';
    $Self->{Translation}->{'Sets the ticket type in the decision screen of the agent interface (Ticket::Type needs to be activated).'} =
        '担当者インターフェースの決定画面でチケットタイプを設定します。（Ticket::Typeを有効にする必要があります。）';
    $Self->{Translation}->{'Sets the ticket type in the ticket priority screen of a zoomed ticket in the agent interface (Ticket::Type needs to be activated).'} =
        '担当者インターフェイスのズームチケットのチケット優先度画面でチケットタイプを設定します。（Ticket::Type を有効にする必要があります。）';
    $Self->{Translation}->{'Shows a link in the menu to change the decision of a ticket in its zoom view of the agent interface.'} =
        '担当者インターフェイスのズームビューでチケットの決定を変更するためのリンクをメニューに表示します。';
    $Self->{Translation}->{'Shows a link in the menu to modify additional ITSM fields in the ticket zoom view of the agent interface.'} =
        '担当者インターフェイスのチケット ズーム ビューで追加の ITSM フィールドを変更するためのリンクをメニューに表示します。';
    $Self->{Translation}->{'Shows a list of all the involved agents on this ticket, in the additional ITSM field screen of the agent interface.'} =
        '担当者インターフェイスの追加 ITSMフィールド画面で、そのチケットに関与する全担当者のリストです。';
    $Self->{Translation}->{'Shows a list of all the involved agents on this ticket, in the decision screen of the agent interface.'} =
        '担当者インターフェイスの決定画面で、そのチケットに関与する全ての担当者のリストを表示します。';
    $Self->{Translation}->{'Shows a list of all the possible agents (all agents with note permissions on the queue/ticket) to determine who should be informed about this note, in the additional ITSM field screen of the agent interface.'} =
        '担当者インターフェイスの追加の ITSM フィールド画面に、このメモについて誰に通知するかを決定するために、考えられる全ての担当者 (キュー/チケットに対するメモ権限を持つ全ての担当者) のリストを表示します。';
    $Self->{Translation}->{'Shows a list of all the possible agents (all agents with note permissions on the queue/ticket) to determine who should be informed about this note, in the decision screen of the agent interface.'} =
        '担当者インターフェイスの決定画面で、このメモについて誰に通知するかを決定するために、考えられる全ての担当者 (キュー/チケットに対するメモ権限を持つ全ての担当者) のリストを表示します。';
    $Self->{Translation}->{'Shows the ticket priority options in the additional ITSM field screen of the agent interface.'} =
        '担当者Webインターフェイスの追加ITSMフィールド画面にチケットの優先度オプションを表示します。';
    $Self->{Translation}->{'Shows the ticket priority options in the decision screen of the agent interface.'} =
        '担当者Webインターフェイスの決定画面にチケット優先度オプションを表示します。';
    $Self->{Translation}->{'Shows the title fields in the additional ITSM field screen of the agent interface.'} =
        '担当者インターフェイスの追加ITSMフィールド画面のタイトルフィールドを表示します。';
    $Self->{Translation}->{'Shows the title fields in the decision screen of the agent interface.'} =
        '担当者インターフェイスの決定画面のタイトルフィールドを表示します。';
    $Self->{Translation}->{'Ticket decision.'} = 'チケットの決定';


    push @{ $Self->{JavaScriptStrings} // [] }, (
    'Service Incident State',
    );

}

1;
