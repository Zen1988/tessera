"use strict";
var TESSERA = TESSERA || {};
TESSERA.APIIdentity = (function (TargetNS) {
    TargetNS.Init = function () {
        var $Search = $('#PermissionSubjectSearch'),
            $Login = $('#CustomerUserID'),
            $Status = $('#PermissionSubjectStatus');
        if (!$Search.length || $Search.prop('readOnly')) {
            return;
        }
        $Search.on('input', function () {
            $Login.val('');
            $Search[0].setCustomValidity('Select an existing customer user from the suggestions.');
            $Status.text('No account selected.');
        });
        Core.UI.Autocomplete.Init($Search, function (Request, Response) {
            $Search.data('AutoCompleteXHR', Core.AJAX.FunctionCall(Core.Config.Get('Baselink'), {
                Action: 'AgentTESSERAAPIIdentity',
                Subaction: 'SearchSubjects',
                Term: Request.term
            }, function (Result) {
                $Search.removeData('AutoCompleteXHR');
                Response($.map(Result, function (Item) {
                    return {label: Item.Label, value: Item.Value};
                }));
                if (!Result.length) {
                    $Status.text('No matching active customer users. Try another name, login or email.');
                }
            }));
        }, function (Event, UI) {
            $Search.val(UI.item.label);
            $Login.val(UI.item.value);
            $Search[0].setCustomValidity('');
            $Status.text('Selected account: ' + UI.item.value);
            Event.preventDefault();
            return false;
        }, 'CustomerSearch', {AutoCompleteActive: 1, MinQueryLength: 2, QueryDelay: 300, MaxResultsDisplayed: 20});
        $Search.closest('form').on('submit', function (Event) {
            if (!$Login.val()) {
                Event.preventDefault();
                $Search[0].setCustomValidity('Select an existing customer user from the suggestions.');
                $Search[0].reportValidity();
            }
        });
    };
    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');
    return TargetNS;
}(TESSERA.APIIdentity || {}));
