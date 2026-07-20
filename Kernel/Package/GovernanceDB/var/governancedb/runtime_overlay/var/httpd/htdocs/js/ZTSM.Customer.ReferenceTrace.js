// TESSERA customer ticket reference diagnostics.
(function () {
    'use strict';

    if (window.ZTSMCustomerReferenceTraceInstalled) {
        return;
    }
    window.ZTSMCustomerReferenceTraceInstalled = true;

    var Prefix = '[TESSERA reference trace]';
    var InterestingAction = /(?:AgentReferenceSearch|ZTSMServicePayloadReferenceResolve|ZTSMServiceExtensionDynamicFields)/;
    var InterestingField = /(?:DynamicField_|Autocomplete_DynamicField_|ZTSMServicePayload|select2-|select2-search|ui-autocomplete)/;
    var InputTimer;
    var PickerScanTimer;
    var LastLoggedKey = '';
    var SearchTimers = {};
    var WatcherStarted = false;
    var PickerStyleInstalled = false;
    var PickerRequests = {};

    function Log(Stage, Data) {
        if (/measure/i.test(Stage || '')) {
            if (window.console && typeof window.console.warn === 'function') {
                window.console.warn(Prefix, Stage, Data || {});
            }
            return;
        }
        if (!/(?:fail|error|exception)/i.test(Stage || '')) {
            return;
        }
        if (!window.console || typeof window.console.error !== 'function') {
            return;
        }
        window.console.error(Prefix, Stage, Data || {});
        try {
            window.console.error(Prefix + ' ' + Stage + ' ' + JSON.stringify(Data || {}));
        }
        catch (Error) {
            // Keep diagnostics non-fatal.
        }
    }

    function FieldInfo(Element) {
        var Related;

        if (!Element) {
            return {};
        }

        Related = RelatedFieldInfo(Element);

        return {
            id: Element.id || '',
            name: Element.name || '',
            tagName: Element.tagName || '',
            type: Element.type || '',
            value: Element.value || '',
            className: Element.className || '',
            role: Element.getAttribute ? (Element.getAttribute('role') || '') : '',
            ariaControls: Element.getAttribute ? (Element.getAttribute('aria-controls') || '') : '',
            ariaOwns: Element.getAttribute ? (Element.getAttribute('aria-owns') || '') : '',
            relatedId: Related.id || '',
            relatedName: Related.name || '',
            relatedValue: Related.value || '',
            autocompleteBound: !!(
                window.jQuery
                && window.jQuery(Element).data('ui-autocomplete')
            ),
            autocompleteOptions: AutocompleteOptions(Element)
        };
    }

    function AutocompleteOptions(Element) {
        var $Element,
            Options = {};

        if (!window.jQuery || !Element || !window.jQuery(Element).data('ui-autocomplete')) {
            return Options;
        }

        $Element = window.jQuery(Element);

        try {
            Options.minLength = $Element.autocomplete('option', 'minLength');
            Options.delay = $Element.autocomplete('option', 'delay');
            Options.disabled = $Element.autocomplete('option', 'disabled');
            Options.hasSource = typeof $Element.autocomplete('option', 'source') === 'function';
        }
        catch (Error) {
            Options.error = Error.message;
        }

        return Options;
    }

    function RelatedFieldInfo(Element) {
        var Field,
            Match,
            Wrapper;

        if (!Element) {
            return {};
        }

        if ((Element.id || '').indexOf('select2-') === 0) {
            Match = (Element.id || '').match(/^select2-(.+?)(?:-container|-results)?$/);
            if (Match && document.getElementById(Match[1])) {
                Field = document.getElementById(Match[1]);
            }
        }

        if (!Field && Element.getAttribute) {
            Match = String(Element.getAttribute('aria-controls') || Element.getAttribute('aria-owns') || '').match(/^select2-(.+?)-results$/);
            if (Match && document.getElementById(Match[1])) {
                Field = document.getElementById(Match[1]);
            }
        }

        if (!Field && Element.closest) {
            Wrapper = Element.closest('.ZTSMServiceExtensionField, .Field, .Row, li, div');
            if (Wrapper) {
                Field = Wrapper.querySelector('[id*="ZTicket-"], [name*="ZTicket-"], [id^="DynamicField_"], [name^="DynamicField_"], [id^="Autocomplete_DynamicField_"], [name^="Autocomplete_DynamicField_"]');
            }
        }

        if (!Field) {
            return {};
        }

        return {
            id: Field.id || '',
            name: Field.name || '',
            value: Field.value || '',
            className: Field.className || ''
        };
    }

    function IsInterestingField(Element) {
        var Info;

        if (!Element) {
            return false;
        }

        Info = FieldInfo(Element);

        return InterestingField.test(Element.id || '')
            || InterestingField.test(Element.name || '')
            || InterestingField.test(String(Element.className || ''))
            || InterestingField.test(Info.relatedId || '')
            || InterestingField.test(Info.relatedName || '')
            || String(Element.className || '').indexOf('DynamicFieldReference') !== -1
            || String(Element.className || '').indexOf('select2-search__field') !== -1;
    }

    function IsZTicketReference(Element) {
        if (!Element) {
            return false;
        }

        return /(?:^|_)DynamicField_ZTicket-/.test(Element.id || '')
            || /(?:^|_)DynamicField_ZTicket-/.test(Element.name || '')
            || (
                String(Element.className || '').indexOf('DynamicFieldReference') !== -1
                && /ZTicket-/.test((Element.id || '') + ' ' + (Element.name || ''))
            );
    }

    function IsZTicketAutocompleteInput(Element) {
        if (!Element) {
            return false;
        }

        return Element.tagName === 'INPUT'
            && (Element.type || 'text') !== 'hidden'
            && String(Element.className || '').indexOf('DynamicFieldReference') !== -1
            && /(?:^|_)DynamicField_/.test((Element.id || '') + ' ' + (Element.name || ''));
    }

    function IsReferencePickerControl(Element) {
        if (!Element || String(Element.className || '').indexOf('DynamicFieldReference') === -1) {
            return false;
        }

        if (!/(?:^|_)DynamicField_/.test((Element.id || '') + ' ' + (Element.name || ''))) {
            return false;
        }

        return (
            Element.tagName === 'SELECT'
            || (
                Element.tagName === 'INPUT'
                && (Element.type || 'text') !== 'hidden'
            )
        );
    }

    function AutocompleteConfig() {
        var Config = {};

        if (
            window.Core
            && Core.Config
            && typeof Core.Config.Get === 'function'
            && Core.Config.Get('Autocomplete')
            && Core.Config.Get('Autocomplete').DynamicFieldReference
        ) {
            Config = Core.Config.Get('Autocomplete').DynamicFieldReference;
        }

        return {
            minLength: parseInt(Config.MinQueryLength, 10) || 2,
            delay: parseInt(Config.QueryDelay, 10) || 100,
            active: String(Config.AutoCompleteActive) !== '0'
        };
    }

    function EnsureAutocompleteActive(Element, Reason) {
        var $Element,
            Options,
            Config;

        if (!window.jQuery || !Element || !IsZTicketAutocompleteInput(Element)) {
            if (Element && /ZTicket-/.test((Element.id || '') + ' ' + (Element.name || ''))) {
                Log('autocomplete-search-skip', {
                    reason: Reason || '',
                    skip: 'not-text-autocomplete-input',
                    field: FieldInfo(Element)
                });
            }
            return;
        }

        $Element = window.jQuery(Element);
        if (!$Element.data('ui-autocomplete')) {
            Log('autocomplete-search-skip', {
                reason: Reason || '',
                skip: 'not-bound',
                field: FieldInfo(Element)
            });
            return;
        }

        Options = AutocompleteOptions(Element);
        Config = AutocompleteConfig();

        if (Options.minLength >= 500 || Options.disabled) {
            try {
                $Element.autocomplete('option', 'minLength', Config.minLength);
                $Element.autocomplete('option', 'delay', Config.delay);
                $Element.autocomplete('option', 'disabled', false);
                Log('autocomplete-repaired', {
                    reason: Reason || '',
                    field: FieldInfo(Element),
                    previousOptions: Options,
                    config: Config
                });
            }
            catch (Error) {
                Log('autocomplete-repair-failed', {
                    reason: Reason || '',
                    field: FieldInfo(Element),
                    error: Error.message
                });
            }
        }
        else if (!$Element.data('ZTSMReferenceTraceOptionsLogged')) {
            $Element.data('ZTSMReferenceTraceOptionsLogged', 1);
            Log('autocomplete-options', {
                reason: Reason || '',
                field: FieldInfo(Element),
                config: Config
            });
        }

        WrapAutocompleteSource(Element, Reason);
        BindElementEvents(Element);
    }

    function WrapAutocompleteSource(Element, Reason) {
        var $Element,
            Source;

        if (!window.jQuery || !Element || !IsZTicketAutocompleteInput(Element)) {
            return;
        }

        $Element = window.jQuery(Element);
        if (!$Element.data('ui-autocomplete') || $Element.data('ZTSMReferenceTraceSourceWrapped')) {
            return;
        }

        try {
            Source = $Element.autocomplete('option', 'source');
            if (typeof Source !== 'function') {
                return;
            }

            $Element.autocomplete('option', 'source', function (Request, Response) {
                Log('autocomplete-source-call', {
                    reason: Reason || '',
                    term: Request && Request.term ? Request.term : '',
                    field: FieldInfo(Element)
                });

                return Source.call(this, Request, function (Result) {
                    var NormalizedResult = NormalizeAutocompleteResults(Result);
                    var Count = NormalizedResult && typeof NormalizedResult.length !== 'undefined' ? NormalizedResult.length : '';
                    Log('autocomplete-source-response', {
                        term: Request && Request.term ? Request.term : '',
                        count: Count,
                        first: Count ? NormalizedResult[0] : {},
                        field: FieldInfo(Element)
                    });
                    return Response(NormalizedResult);
                });
            });

            $Element.data('ZTSMReferenceTraceSourceWrapped', 1);
            Log('autocomplete-source-wrapped', {
                reason: Reason || '',
                field: FieldInfo(Element)
            });
        }
        catch (Error) {
            Log('autocomplete-source-wrap-failed', {
                reason: Reason || '',
                field: FieldInfo(Element),
                error: Error.message
            });
        }
    }

    function NormalizeAutocompleteResults(Result) {
        if (!window.jQuery || !window.jQuery.isArray(Result)) {
            return Result;
        }

        return window.jQuery.map(Result, function (Item) {
            var Label,
                Value,
                Key;

            if (!Item) {
                return null;
            }

            if (typeof Item === 'string') {
                return {
                    label: Item,
                    value: Item,
                    key: Item
                };
            }

            Label = Item.label || Item.Value || Item.value || Item.Name || Item.Key || Item.key || '';
            Value = Item.value || Item.Value || Label;
            Key = Item.key || Item.Key || Value;

            if (!Label) {
                return null;
            }

            Item.label = String(Label);
            Item.value = String(Value);
            Item.key = String(Key);

            return Item;
        });
    }

    function ForceAutocompleteSearch(Element, Reason) {
        var $Element,
            Options,
            Term,
            Key,
            MinLength;

        if (!window.jQuery || !Element || !IsZTicketAutocompleteInput(Element)) {
            return;
        }

        $Element = window.jQuery(Element);
        if (!$Element.data('ui-autocomplete')) {
            return;
        }

        Options = AutocompleteOptions(Element);
        Term = String(Element.value || '').trim();
        MinLength = parseInt(Options.minLength, 10);
        if (!MinLength && MinLength !== 0) {
            MinLength = 2;
        }

        if (!Term || Term.length < MinLength) {
            Log('autocomplete-search-skip', {
                reason: Reason || '',
                skip: 'term-too-short',
                term: Term,
                minLength: MinLength,
                field: FieldInfo(Element)
            });
            return;
        }

        Key = Element.id || Element.name || 'ZTicketReference';
        if (
            $Element.data('ZTSMReferenceTraceLastSearchTerm') === Term
            && !$Element.data('ZTSMReferenceTracePendingSearch')
        ) {
            Log('autocomplete-search-skip', {
                reason: Reason || '',
                skip: 'duplicate-term',
                term: Term,
                field: FieldInfo(Element)
            });
            return;
        }
        $Element.data('ZTSMReferenceTracePendingSearch', Term);

        Log('autocomplete-search-scheduled', {
            reason: Reason || '',
            term: Term,
            key: Key,
            field: FieldInfo(Element)
        });

        window.clearTimeout(SearchTimers[Key]);
        SearchTimers[Key] = window.setTimeout(function () {
            try {
                $Element.removeData('ZTSMReferenceTracePendingSearch');
                $Element.data('ZTSMReferenceTraceLastSearchTerm', Term);
                Log('autocomplete-search-forced', {
                    reason: Reason || '',
                    term: Term,
                    field: FieldInfo(Element)
                });
                $Element.autocomplete('search', Term);
            }
            catch (Error) {
                $Element.removeData('ZTSMReferenceTracePendingSearch');
                $Element.removeData('ZTSMReferenceTraceLastSearchTerm');
                Log('autocomplete-search-force-failed', {
                    reason: Reason || '',
                    term: Term,
                    field: FieldInfo(Element),
                    error: Error.message
                });
            }
        }, 120);
    }

    function BindElementEvents(Element) {
        var $Element;

        if (!window.jQuery || !Element || !IsZTicketAutocompleteInput(Element)) {
            return;
        }

        $Element = window.jQuery(Element);
        if ($Element.data('ZTSMReferenceTraceEventsBound')) {
            return;
        }

        $Element.data('ZTSMReferenceTraceEventsBound', 1);
        $Element.on('input.ZTSMReferenceTrace keyup.ZTSMReferenceTrace paste.ZTSMReferenceTrace change.ZTSMReferenceTrace', function (Event) {
            EnsureAutocompleteActive(this, 'direct-' + (Event.type || 'event'));
            ForceAutocompleteSearch(this, 'direct-' + (Event.type || 'event'));
            Log('direct-' + (Event.type || 'event'), FieldInfo(this));
        });

        Log('direct-events-bound', {
            field: FieldInfo(Element)
        });
    }

    function WatchReferenceValues() {
        if (!window.jQuery) {
            return;
        }

        window.jQuery('input.DynamicFieldReference[id*="DynamicField_"], input.DynamicFieldReference[name*="DynamicField_"], input[id^="Autocomplete_DynamicField_"], input[name^="Autocomplete_DynamicField_"]').each(function () {
            var Element = this;
            var Value = String(Element.value || '');
            var LastValue = window.jQuery(Element).data('ZTSMReferenceTraceLastValue') || '';

            EnsureAutocompleteActive(Element, 'watch');

            if (Value !== LastValue) {
                window.jQuery(Element).data('ZTSMReferenceTraceLastValue', Value);
                Log('value-watch-change', FieldInfo(Element));
                ForceAutocompleteSearch(Element, 'watch');
            }
        });
    }

    function StartWatcher() {
        if (WatcherStarted) {
            return;
        }

        WatcherStarted = true;
        window.setInterval(WatchReferenceValues, 400);
    }

    function InstallPickerStyles() {
        var Style;

        if (PickerStyleInstalled) {
            return;
        }
        PickerStyleInstalled = true;

        Style = document.createElement('style');
        Style.type = 'text/css';
        Style.appendChild(document.createTextNode([
            '.ZTSMReferencePickerButton{all:unset!important;appearance:none!important;-webkit-appearance:none!important;box-sizing:border-box!important;display:inline-flex!important;align-items:center!important;justify-content:center!important;flex:0 0 34px!important;width:34px!important;min-width:34px!important;max-width:34px!important;height:34px!important;min-height:34px!important;max-height:34px!important;padding:0!important;margin:0 0 0 6px!important;border:1px solid #8784aa!important;background:#fff!important;color:#04084f!important;border-radius:6px!important;cursor:pointer!important;vertical-align:middle!important;font-size:16px!important;line-height:1!important;box-shadow:none!important;font-family:Arial,sans-serif!important;text-align:center!important;text-decoration:none!important;overflow:hidden!important}',
            '.ZTSMReferencePickerButton:hover,.ZTSMReferencePickerButton:focus{background:#f6f6fb!important;outline:2px solid #b9b7d5!important;outline-offset:2px!important}',
            '.ZTSMReferencePickerInputHost{position:static!important;padding-right:0!important}',
            '.ZTSMReferencePickerInputButton{position:static!important;right:auto!important;top:auto!important;transform:none!important;z-index:auto!important;margin:0 6px 0 0!important}',
            '.Field.ZTSMReferencePickerInputHost{position:relative!important}',
            '.Field.ZTSMReferencePickerInputHost > .ZTSMReferencePickerInputButton{position:absolute!important;right:-48px!important;left:auto!important;top:50%!important;transform:translateY(-50%)!important;z-index:2!important;margin:0!important}',
            '.FieldCell.ZTSMReferencePickerFieldCell > .ZTSMReferencePickerAddRemoveLane{display:inline-flex!important;align-items:center!important;justify-content:flex-start!important;gap:8px!important;width:52px!important;min-width:52px!important;max-width:52px!important;right:-108px!important;left:auto!important;top:20px!important;margin:0!important;white-space:nowrap!important;overflow:visible!important;vertical-align:middle!important}',
            '.FieldCell.ZTSMReferencePickerFieldCell > .ZTSMReferencePickerAddRemoveLane .AddValueRow,.FieldCell.ZTSMReferencePickerFieldCell > .ZTSMReferencePickerAddRemoveLane .RemoveValueRow{display:inline-flex!important;align-items:center!important;justify-content:center!important;flex:0 0 20px!important;width:20px!important;min-width:20px!important;max-width:20px!important;height:34px!important;min-height:34px!important;max-height:34px!important;margin:0!important;padding:0!important;line-height:1!important;vertical-align:middle!important}',
            '.FieldCell.ZTSMReferencePickerFieldCell > .ZTSMReferencePickerAddRemoveLane .AddValueRow > i,.FieldCell.ZTSMReferencePickerFieldCell > .ZTSMReferencePickerAddRemoveLane .RemoveValueRow > i{display:inline-flex!important;align-items:center!important;justify-content:center!important;width:20px!important;height:34px!important;margin:0!important;padding:0!important;line-height:1!important}',
            '.ZTSMReferencePickerSelectShell,.ZTSMReferencePickerSelectDisplay{display:none!important}',
            '.ZTSMReferencePickerOverlay{position:fixed;z-index:99999;inset:0;background:rgba(10,12,32,.38);display:flex;align-items:center;justify-content:center;padding:24px}',
            '.ZTSMReferencePickerDialog{background:#fff;color:#11153f;width:min(980px,96vw);max-height:88vh;border-radius:8px;box-shadow:0 18px 60px rgba(0,0,0,.25);display:flex;flex-direction:column;overflow:hidden}',
            '.ZTSMReferencePickerHeader{display:flex;align-items:center;justify-content:space-between;padding:14px 18px;border-bottom:1px solid #dedeee;font-weight:600}',
            '.ZTSMReferencePickerClose{border:0;background:transparent;font-size:24px;line-height:1;cursor:pointer;color:#04084f}',
            '.ZTSMReferencePickerToolbar{display:flex;gap:8px;padding:12px 18px;border-bottom:1px solid #ececf4}',
            '.ZTSMReferencePickerSearch{flex:1;min-width:0;border:1px solid #b6b3d2;border-radius:6px;padding:9px 10px;font-size:14px}',
            '.ZTSMReferencePickerSearchButton,.ZTSMReferencePickerApply{border:1px solid #04084f;background:#04084f;color:#fff;border-radius:6px;padding:8px 14px;cursor:pointer}',
            '.ZTSMReferencePickerContext{padding:0 18px 10px;color:#555b7a;font-size:12px}',
            '.ZTSMReferencePickerBody{overflow:auto;padding:0 18px 16px}',
            '.ZTSMReferencePickerTable{width:100%;border-collapse:collapse;font-size:13px}',
            '.ZTSMReferencePickerTable th,.ZTSMReferencePickerTable td{border-bottom:1px solid #ececf4;text-align:left;padding:9px 8px;vertical-align:top}',
            '.ZTSMReferencePickerTable th{position:sticky;top:0;background:#fff;color:#30345f;font-weight:600}',
            '.ZTSMReferencePickerEmpty{padding:18px;color:#6a6f8d;text-align:center}',
            '.ZTSMReferencePickerFooter{display:flex;justify-content:flex-end;gap:8px;padding:12px 18px;border-top:1px solid #ececf4}',
            '.ZTSMReferencePickerCancel{border:1px solid #b6b3d2;background:#fff;color:#04084f;border-radius:6px;padding:8px 14px;cursor:pointer}'
        ].join('\n')));
        document.head.appendChild(Style);
    }

    function EscapeHTML(Value) {
        if (window.Core && Core.App && typeof Core.App.EscapeHTML === 'function') {
            return Core.App.EscapeHTML(String(Value || ''));
        }

        return String(Value || '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function PickerFieldName(Element) {
        return String((Element && (Element.id || Element.name)) || '')
            .replace(/^Autocomplete_/, '')
            .replace(/^DynamicField_/, '')
            .replace(/_\d+(?:_\d+)?$/, '');
    }

    function PickerDisplayValue(Element) {
        var Selected;

        if (!Element) {
            return '';
        }

        if (Element.tagName === 'SELECT') {
            Selected = Element.options && Element.selectedIndex >= 0 ? Element.options[Element.selectedIndex] : null;
            return Selected && Selected.text ? Selected.text : '';
        }

        return Element.value || '';
    }

    function SelectOptionExists(Element, Value) {
        var Index;

        if (!Element || !Element.options) {
            return false;
        }

        for (Index = 0; Index < Element.options.length; Index++) {
            if (String(Element.options[Index].value) === String(Value)) {
                return true;
            }
        }

        return false;
    }

    function PickerTitle(Element) {
        var FieldName = PickerFieldName(Element),
            Label;

        if (Element && Element.id) {
            Label = document.querySelector('label[for="' + Element.id + '"]');
        }
        if (!Label) {
            Label = document.querySelector('label[for="DynamicField_' + FieldName + '"]');
        }

        return (Label && Label.textContent ? Label.textContent : FieldName)
            .replace(/\s*\*\s*$/, '')
            .trim();
    }

    function SerializeCurrentForm(Element, Extra) {
        var Form = Element && Element.closest ? Element.closest('form') : document.querySelector('form'),
            Parts = [],
            Data = Extra || {};

        if (Form && window.Core && Core.AJAX && typeof Core.AJAX.SerializeForm === 'function' && window.jQuery) {
            return Core.AJAX.SerializeForm(window.jQuery(Form), {
                Action: 1,
                Subaction: 1,
                Term: 1,
                Field: 1,
                MaxResults: 1,
                Picker: 1
            });
        }

        if (Form) {
            Array.prototype.forEach.call(Form.elements, function (Field) {
                if (!Field.name || Field.disabled) {
                    return;
                }
                if ((Field.type === 'checkbox' || Field.type === 'radio') && !Field.checked) {
                    return;
                }
                Parts.push(encodeURIComponent(Field.name) + '=' + encodeURIComponent(Field.value || ''));
            });
        }

        Object.keys(Data).forEach(function (Key) {
            Parts.push(encodeURIComponent(Key) + '=' + encodeURIComponent(Data[Key] || ''));
        });

        return Parts.join(';');
    }

    function PickerSearch(Element, Term, Callback) {
        var URL,
            QueryString;

        if (!Element || !window.Core || !Core.Config || typeof Core.Config.Get !== 'function') {
            Callback([]);
            return;
        }

        URL = Core.Config.Get('Baselink');
        QueryString = 'Action=AgentReferenceSearch;Picker=1;Term=' + encodeURIComponent(Term || '')
            + ';Field=' + encodeURIComponent(Element.id || Element.name || '')
            + ';MaxResults=50;';
        QueryString += SerializeCurrentForm(Element);

        var RequestKey = Element.id || Element.name || 'ZTSMReferencePicker';
        if (PickerRequests[RequestKey] && typeof PickerRequests[RequestKey].abort === 'function') {
            PickerRequests[RequestKey].abort();
        }

        PickerRequests[RequestKey] = new XMLHttpRequest();
        PickerRequests[RequestKey].open('GET', URL + QueryString, true);
        PickerRequests[RequestKey].onreadystatechange = function () {
            var Result = [];
            var Request = PickerRequests[RequestKey];

            if (!Request || Request.readyState !== 4) {
                return;
            }

            if (Request.status >= 200 && Request.status < 300) {
                try {
                    Result = JSON.parse(Request.responseText || '[]');
                }
                catch (Error) {
                    Result = [];
                }
            }

            Log('picker-search-result', {
                field: FieldInfo(Element),
                term: Term || '',
                count: Result && Result.length ? Result.length : 0
            });
            Callback(NormalizeAutocompleteResults(Result) || []);
        };
        PickerRequests[RequestKey].send();
    }

    function ApplyReferenceSelection(Element, Items) {
        var Item = Items && Items[0],
            Label,
            Key,
            Hidden;

        if (!Element || !Item) {
            return;
        }

        Label = Item.value || Item.Value || Item.label || '';
        Key = Item.key || Item.Key || '';
        Hidden = document.getElementById((Element.id || '').replace(/^Autocomplete_/, ''));

        if (Element.tagName === 'SELECT') {
            if (Key && !SelectOptionExists(Element, Key)) {
                Element.appendChild(new Option(Label, Key));
            }
            Element.value = Key;
        }
        else if (
            window.Core
            && Core.Agent
            && Core.Agent.DynamicFieldReferenceSearch
            && typeof Core.Agent.DynamicFieldReferenceSearch.AddTicketReference === 'function'
        ) {
            Core.Agent.DynamicFieldReferenceSearch.AddTicketReference(Element.id, Label, Key);
        }
        else {
            Element.value = Label;
            if (Hidden) {
                Hidden.value = Key;
            }
        }

        if (window.jQuery) {
            window.jQuery(Element).trigger('change');
            if (Hidden) {
                window.jQuery(Hidden).trigger('change');
            }
        }
        else {
            Element.dispatchEvent(new Event('change', { bubbles: true }));
            if (Hidden) {
                Hidden.dispatchEvent(new Event('change', { bubbles: true }));
            }
        }

        Log('picker-selection-applied', {
            field: FieldInfo(Element),
            item: Item
        });
    }

    function RenderPickerRows(Dialog, Element, Rows) {
        var Body = Dialog.querySelector('.ZTSMReferencePickerBody'),
            HTML;

        if (!Rows || !Rows.length) {
            Body.innerHTML = '<div class="ZTSMReferencePickerEmpty">No matching records.</div>';
            return;
        }

        HTML = '<table class="ZTSMReferencePickerTable"><thead><tr>'
            + '<th></th><th>Name</th><th>Class</th><th>Number</th><th>Status</th><th>Description</th>'
            + '</tr></thead><tbody>';

        Rows.forEach(function (Row, Index) {
            HTML += '<tr>'
                + '<td><input type="radio" name="ZTSMReferencePickerChoice" value="' + Index + '"></td>'
                + '<td>' + EscapeHTML(Row.Name || Row.label || Row.Value || Row.value) + '</td>'
                + '<td>' + EscapeHTML(Row.Class || Row.ObjectType || '') + '</td>'
                + '<td>' + EscapeHTML(Row.Number || Row.key || Row.Key || '') + '</td>'
                + '<td>' + EscapeHTML(Row.Status || '') + '</td>'
                + '<td>' + EscapeHTML(Row.Description || Row.label || Row.Value || Row.value || '') + '</td>'
                + '</tr>';
        });
        HTML += '</tbody></table>';
        Body.innerHTML = HTML;
        Body.ZTSMReferencePickerRows = Rows;
    }

    function OpenReferencePicker(Element) {
        var Overlay,
            Dialog,
            InitialTerm = PickerDisplayValue(Element);

        InstallPickerStyles();

        Overlay = document.createElement('div');
        Overlay.className = 'ZTSMReferencePickerOverlay';
        Overlay.innerHTML = ''
            + '<div class="ZTSMReferencePickerDialog" role="dialog" aria-modal="true">'
            + '<div class="ZTSMReferencePickerHeader"><span>Select ' + EscapeHTML(PickerTitle(Element)) + '</span><button type="button" class="ZTSMReferencePickerClose" title="Close">&times;</button></div>'
            + '<div class="ZTSMReferencePickerToolbar"><input class="ZTSMReferencePickerSearch" type="search" value="' + EscapeHTML(InitialTerm) + '" placeholder="Search name, number, or description"><button type="button" class="ZTSMReferencePickerSearchButton">Search</button></div>'
            + '<div class="ZTSMReferencePickerContext">Current form values are included as search context.</div>'
            + '<div class="ZTSMReferencePickerBody"><div class="ZTSMReferencePickerEmpty">Search to choose a record.</div></div>'
            + '<div class="ZTSMReferencePickerFooter"><button type="button" class="ZTSMReferencePickerCancel">Cancel</button><button type="button" class="ZTSMReferencePickerApply">Apply</button></div>'
            + '</div>';
        document.body.appendChild(Overlay);

        Dialog = Overlay.querySelector('.ZTSMReferencePickerDialog');

        function Close() {
            if (Overlay.parentNode) {
                Overlay.parentNode.removeChild(Overlay);
            }
        }

        function Search() {
            var Term = Overlay.querySelector('.ZTSMReferencePickerSearch').value || '';
            Overlay.querySelector('.ZTSMReferencePickerBody').innerHTML = '<div class="ZTSMReferencePickerEmpty">Searching...</div>';
            PickerSearch(Element, Term, function (Rows) {
                RenderPickerRows(Dialog, Element, Rows);
            });
        }

        Overlay.querySelector('.ZTSMReferencePickerClose').addEventListener('click', Close);
        Overlay.querySelector('.ZTSMReferencePickerCancel').addEventListener('click', Close);
        Overlay.querySelector('.ZTSMReferencePickerSearchButton').addEventListener('click', Search);
        Overlay.querySelector('.ZTSMReferencePickerSearch').addEventListener('keydown', function (Event) {
            if (Event.key === 'Enter') {
                Event.preventDefault();
                Search();
            }
        });
        Overlay.querySelector('.ZTSMReferencePickerApply').addEventListener('click', function () {
            var Checked = Overlay.querySelector('input[name="ZTSMReferencePickerChoice"]:checked'),
                Rows = Dialog.querySelector('.ZTSMReferencePickerBody').ZTSMReferencePickerRows || [];

            if (!Checked) {
                return;
            }

            ApplyReferenceSelection(Element, [ Rows[parseInt(Checked.value, 10)] ]);
            Close();
        });

        Search();
    }

    function EnsurePickerButtons(Root) {
        Array.prototype.forEach.call((Root || document).querySelectorAll('input.DynamicFieldReference[id*="DynamicField_"], input.DynamicFieldReference[name*="DynamicField_"], input[id^="Autocomplete_DynamicField_"], input[name^="Autocomplete_DynamicField_"], select.DynamicFieldReference[id*="DynamicField_"], select.DynamicFieldReference[name*="DynamicField_"]'), function (Element) {
            var Button,
                Host;

            if (
                !IsReferencePickerControl(Element)
            ) {
                return;
            }

            if (Element.getAttribute('data-ztsm-reference-picker')) {
                RelocatePickerButton(Element);
                return;
            }

            Element.setAttribute('data-ztsm-reference-picker', '1');
            Button = document.createElement('span');
            Button.className = 'ZTSMReferencePickerButton';
            Button.setAttribute('role', 'button');
            Button.setAttribute('tabindex', '0');
            Button.setAttribute('data-ztsm-reference-picker-for', Element.id || Element.name || '');
            Button.title = 'Search and select';
            Button.setAttribute('aria-label', 'Search and select ' + PickerTitle(Element));
            Button.innerHTML = '&#128269;';
            Button.addEventListener('click', function () {
                OpenReferencePicker(Element);
            });
            Button.addEventListener('keydown', function (Event) {
                if (!Event || (Event.key !== 'Enter' && Event.key !== ' ')) {
                    return;
                }
                Event.preventDefault();
                OpenReferencePicker(Element);
            });

            Button.classList.add('ZTSMReferencePickerInputButton');
            Host = PickerHostGet(Element);
            if (Host && Host.classList) {
                Host.classList.add('ZTSMReferencePickerInputHost');
                if (HostHasSetControls(Host)) {
                    Host.classList.add('ZTSMReferencePickerInputHostWithSetControls');
                }
            }
            MarkPickerField(Element);
            InsertPickerButton(Element, Host || Element.parentNode, Button);
            Host = ApplyPickerButtonSlot(Element, Host || Element.parentNode, Button);
            UpdatePickerLayout(Element, Host || Element.parentNode, Button);
        });
    }

    function RelocatePickerButton(Element) {
        var Button,
            Host;

        Button = ExistingPickerButtonGet(Element);
        Host = PickerHostGet(Element);

        if (!Button || !Host) {
            return;
        }

        if (Host.classList) {
            Host.classList.add('ZTSMReferencePickerInputHost');
            Host.classList.remove('ZTSMReferencePickerInputHostWithSetControls');
        }
        MarkPickerField(Element);

        if (Button.parentNode !== Host) {
            InsertPickerButton(Element, Host, Button);
        }
        Host = ApplyPickerButtonSlot(Element, Host, Button);
        UpdatePickerLayout(Element, Host, Button);
    }

    function InsertPickerButton(Element, Host, Button) {
        if (!Host || !Button) {
            return;
        }

        if (Host.classList && Host.classList.contains('AddRemoveValueRow')) {
            Host.insertBefore(Button, Host.firstChild);
            return;
        }

        Host.appendChild(Button);
    }

    function ApplyPickerButtonSlot(Element, Host, Button) {
        var Field = Element && Element.closest ? Element.closest('.Field') : null;

        if (!Button) {
            return Host;
        }

        if (Field && Field.appendChild && Button.parentNode !== Field) {
            Field.appendChild(Button);
        }

        if (Field && Field.classList) {
            Field.classList.add('ZTSMReferencePickerInputHost');
            Field.style.setProperty('position', 'relative', 'important');
        }

        Button.classList.add('ZTSMReferencePickerFieldSlotButton');
        Button.style.setProperty('position', 'absolute', 'important');
        Button.style.setProperty('right', '-48px', 'important');
        Button.style.setProperty('left', 'auto', 'important');
        Button.style.setProperty('top', '50%', 'important');
        Button.style.setProperty('transform', 'translateY(-50%)', 'important');
        Button.style.setProperty('z-index', '2', 'important');
        Button.style.setProperty('display', 'inline-flex', 'important');
        Button.style.setProperty('align-items', 'center', 'important');
        Button.style.setProperty('justify-content', 'center', 'important');
        Button.style.setProperty('width', '34px', 'important');
        Button.style.setProperty('min-width', '34px', 'important');
        Button.style.setProperty('max-width', '34px', 'important');
        Button.style.setProperty('height', '34px', 'important');
        Button.style.setProperty('min-height', '34px', 'important');
        Button.style.setProperty('max-height', '34px', 'important');
        Button.style.setProperty('margin', '0', 'important');
        Button.style.setProperty('padding', '0', 'important');
        Button.style.setProperty('box-sizing', 'border-box', 'important');

        return Field || Host;
    }

    function MarkPickerField(Element) {
        var AddRemoveRows,
            Field = Element && Element.closest ? Element.closest('.Field') : null,
            FieldCell = Element && Element.closest ? Element.closest('.FieldCell') : null;

        if (Field && Field.classList) {
            Field.classList.add('ZTSMReferencePickerField');
        }
        if (FieldCell && FieldCell.classList) {
            FieldCell.classList.add('ZTSMReferencePickerFieldCell');
            AddRemoveRows = FieldCell.querySelectorAll ? FieldCell.querySelectorAll('.AddRemoveValueRow') : [];
            Array.prototype.forEach.call(AddRemoveRows, function (Row) {
                if (Row && Row.classList) {
                    Row.classList.add('ZTSMReferencePickerAddRemoveLane');
                }
            });
        }
    }

    function UpdatePickerLayout(Element, Host, Button) {
        var Field,
            HostRect,
            HelpRect,
            AddRemoveCount = 0,
            HelpCount = 0,
            AddRemoveWidth = 0,
            HelpWidth = 24,
            HelpFallbackWidth = 64,
            PickerWidth = 34,
            Gap = 10,
            Right,
            Padding;

        if (!Element || !Host || !Host.style) {
            return;
        }

        Field = Element.closest ? Element.closest('.Field') : null;
        if (Field && Field.querySelector) {
            AddRemoveCount = VisibleCandidateCount(Field, '.AddRemoveValueRow, .AddRemoveValueRow *', Button);
            HelpCount = CandidateCount(Field, '.Tooltip, .Tooltip *, .oooTooltip, .oooTooltip *, [id$="_Tooltip"], [id$="_Tooltip"] *, [class*="Tooltip"], [class*="Tooltip"] *, [class*="question"], [class*="question"] *, [class*="help"], [class*="help"] *', Button);
            AddRemoveWidth = VisibleUnionWidth(Field, '.AddRemoveValueRow, .AddRemoveValueRow *', Button);
            HelpRect = RightmostVisibleRect(Field, '.Tooltip, .Tooltip *, .oooTooltip, .oooTooltip *, [id$="_Tooltip"], [id$="_Tooltip"] *, [class*="Tooltip"], [class*="Tooltip"] *, [class*="question"], [class*="question"] *, [class*="help"], [class*="help"] *', Button);
        }

        if (typeof Host.getBoundingClientRect === 'function') {
            HostRect = Host.getBoundingClientRect();
        }
        if (HelpRect) {
            HelpWidth = Math.max(HelpWidth, Math.ceil(HelpRect.width || 0));
        }
        if (Button && typeof Button.getBoundingClientRect === 'function') {
            PickerWidth = Math.max(PickerWidth, Math.ceil(Button.getBoundingClientRect().width || 0));
        }

        if (HostRect && HelpRect && HelpRect.left > HostRect.left && HelpRect.left < HostRect.right) {
            Right = Math.max(HelpWidth + Gap, Math.ceil(HostRect.right - HelpRect.left + Gap));
        }
        else if (HelpCount > 0) {
            HelpWidth = Math.max(HelpWidth, HelpFallbackWidth);
            Right = HelpWidth + Gap;
        }
        else {
            Right = HelpWidth + Gap;
        }
        Padding = HelpWidth + PickerWidth + (Gap * 3);

        if (AddRemoveWidth > 0) {
            Right += AddRemoveWidth + Gap;
            Padding += AddRemoveWidth + Gap;
        }

        Host.style.setProperty('--ztsm-reference-picker-right', Right + 'px');
        Host.style.setProperty('--ztsm-reference-picker-padding', Padding + 'px');
        Host.setAttribute('data-ztsm-reference-picker-right', String(Right));
        Host.setAttribute('data-ztsm-reference-picker-padding', String(Padding));
        Host.setAttribute('data-ztsm-reference-picker-help-width', String(HelpWidth));
        Host.setAttribute('data-ztsm-reference-picker-help-count', String(HelpCount));
        Host.setAttribute('data-ztsm-reference-picker-addremove-width', String(AddRemoveWidth));
        Host.setAttribute('data-ztsm-reference-picker-addremove-count', String(AddRemoveCount));
        Host.setAttribute('data-ztsm-reference-picker-button-width', String(PickerWidth));
        if (Button && Button.setAttribute) {
            Button.setAttribute('data-ztsm-reference-picker-right', String(Right));
            Button.setAttribute('data-ztsm-reference-picker-padding', String(Padding));
            Button.setAttribute('data-ztsm-reference-picker-help-width', String(HelpWidth));
            Button.setAttribute('data-ztsm-reference-picker-help-count', String(HelpCount));
            Button.setAttribute('data-ztsm-reference-picker-addremove-width', String(AddRemoveWidth));
            Button.setAttribute('data-ztsm-reference-picker-addremove-count', String(AddRemoveCount));
        }
    }

    function CandidateCount(Root, Selector, Exclude) {
        var Count = 0;

        if (!Root || !Root.querySelectorAll) {
            return 0;
        }

        Array.prototype.forEach.call(Root.querySelectorAll(Selector), function (Node) {
            if (!Node || Node === Exclude || (Exclude && Exclude.contains && Exclude.contains(Node))) {
                return;
            }
            if (Node.classList && Node.classList.contains('ZTSMReferencePickerButton')) {
                return;
            }
            Count += 1;
        });

        return Count;
    }

    function VisibleCandidateCount(Root, Selector, Exclude) {
        var Count = 0;

        if (!Root || !Root.querySelectorAll) {
            return 0;
        }

        Array.prototype.forEach.call(Root.querySelectorAll(Selector), function (Node) {
            var Rect;

            if (!Node || Node === Exclude || (Exclude && Exclude.contains && Exclude.contains(Node))) {
                return;
            }
            if (typeof Node.getBoundingClientRect !== 'function') {
                return;
            }

            Rect = Node.getBoundingClientRect();
            if (!Rect || Rect.width < 2 || Rect.height < 2 || Rect.right <= 0 || Rect.bottom <= 0) {
                return;
            }
            Count += 1;
        });

        return Count;
    }

    function RightmostVisibleRect(Root, Selector, Exclude) {
        var Best;

        if (!Root || !Root.querySelectorAll) {
            return null;
        }

        Array.prototype.forEach.call(Root.querySelectorAll(Selector), function (Node) {
            var Rect;

            if (!Node || Node === Exclude || (Exclude && Exclude.contains && Exclude.contains(Node))) {
                return;
            }
            if (Node.classList && Node.classList.contains('ZTSMReferencePickerButton')) {
                return;
            }
            if (typeof Node.getBoundingClientRect !== 'function') {
                return;
            }

            Rect = Node.getBoundingClientRect();
            if (!Rect || Rect.width < 2 || Rect.height < 2 || Rect.right <= 0 || Rect.bottom <= 0) {
                return;
            }

            if (!Best || Rect.right > Best.right) {
                Best = Rect;
            }
        });

        return Best || null;
    }

    function VisibleUnionWidth(Root, Selector, Exclude) {
        var Left,
            Right;

        if (!Root || !Root.querySelectorAll) {
            return 0;
        }

        Array.prototype.forEach.call(Root.querySelectorAll(Selector), function (Node) {
            var Rect;

            if (!Node || Node === Exclude || (Exclude && Exclude.contains && Exclude.contains(Node))) {
                return;
            }
            if (typeof Node.getBoundingClientRect !== 'function') {
                return;
            }

            Rect = Node.getBoundingClientRect();
            if (!Rect || Rect.width < 2 || Rect.height < 2 || Rect.right <= 0 || Rect.bottom <= 0) {
                return;
            }

            Left = typeof Left === 'number' ? Math.min(Left, Rect.left) : Rect.left;
            Right = typeof Right === 'number' ? Math.max(Right, Rect.right) : Rect.right;
        });

        if (typeof Left !== 'number' || typeof Right !== 'number') {
            return 0;
        }

        return Math.ceil(Math.max(0, Right - Left));
    }

    function ExistingPickerButtonGet(Element) {
        var Field,
            Key,
            Selector;

        if (!Element || !Element.closest) {
            return null;
        }

        Field = Element.closest('.Field') || Element.parentNode;
        Key = Element.id || Element.name || '';

        if (Key && Field && Field.querySelector) {
            Selector = '.ZTSMReferencePickerButton[data-ztsm-reference-picker-for="' + Key.replace(/"/g, '\\"') + '"]';
            return Field.querySelector(Selector);
        }

        return Field && Field.querySelector ? Field.querySelector('.ZTSMReferencePickerButton') : null;
    }

    function PickerHostGet(Element) {
        var Field,
            Host;

        if (!Element || !Element.closest) {
            return Element ? Element.parentNode : null;
        }

        Field = Element.closest('.Field');
        if (Field && Field.querySelector) {
            Host = Field.querySelector('.InputField_Container');
            if (Host) {
                return Host;
            }
        }

        Host = Element.closest('.InputField_Container');
        if (Host) {
            return Host;
        }

        Host = Element.closest('.FieldCell');
        if (Host) {
            return Host;
        }

        return Element.closest('fieldset, .Field, .Row, .ZTSMServiceExtensionField, li, div') || Element.parentNode;
    }

    function HostHasSetControls(Host) {
        var Controls;

        if (!Host || !Host.querySelectorAll) {
            return false;
        }

        Controls = Host.querySelectorAll('a, button, input[type="button"], input[type="submit"], span[role="button"]');
        return Array.prototype.some.call(Controls, function (Control) {
            var Text;

            if (!Control || (Control.classList && Control.classList.contains('ZTSMReferencePickerButton'))) {
                return false;
            }

            Text = (Control.value || Control.textContent || Control.getAttribute('aria-label') || Control.title || '').replace(/\s+/g, ' ').trim();
            return Text === '+' || Text === '-' || Text === '+/-' || Text === '- +';
        });
    }

    function AutoPopulatePlatformFromApplication() {
        var Platform = document.getElementById('Autocomplete_DynamicField_ZTicket-Platform'),
            Hidden = document.getElementById('DynamicField_ZTicket-Platform'),
            Application = document.getElementById('DynamicField_ZTicket-Application');

        if (!Platform || !Application || !Application.value) {
            return;
        }
        if ((Hidden && Hidden.value) || Platform.value) {
            return;
        }

        PickerSearch(Platform, '', function (Rows) {
            if (Rows && Rows.length === 1) {
                Log('picker-platform-autofill', {
                    application: Application.value,
                    item: Rows[0]
                });
                ApplyReferenceSelection(Platform, [ Rows[0] ]);
            }
            else {
                Log('picker-platform-autofill-skip', {
                    application: Application.value,
                    count: Rows && Rows.length ? Rows.length : 0
                });
            }
        });
    }

    function Scan() {
        var ReferenceFields = document.querySelectorAll(
            '.DynamicFieldReference, [id^="DynamicField_"], [name^="DynamicField_"], [id^="Autocomplete_DynamicField_"], [name^="Autocomplete_DynamicField_"]'
        );
        var PlatformFields = document.querySelectorAll(
            '[id*="ZTicket-Platform"], [name*="ZTicket-Platform"]'
        );
        var FieldInventory = Array.prototype.slice.call(document.querySelectorAll(
            'input, select, textarea, [contenteditable="true"], .select2-selection, .select2-search__field'
        )).filter(function (Element) {
            var Text = [
                Element.id || '',
                Element.name || '',
                Element.className || '',
                Element.getAttribute ? (Element.getAttribute('aria-controls') || '') : '',
                Element.getAttribute ? (Element.getAttribute('aria-owns') || '') : ''
            ].join(' ');
            return /(?:ZTicket|DynamicField|select2|Service|Subject)/.test(Text);
        }).slice(0, 40).map(FieldInfo);

        Log('ready', {
            href: window.location.href,
            action: (window.Core && Core.Config && Core.Config.Get) ? Core.Config.Get('Action') : '',
            referenceFieldCount: ReferenceFields.length,
            platformFieldCount: PlatformFields.length,
            fields: FieldInventory,
            coreReferenceSearchAvailable: !!(
                window.Core
                && Core.Agent
                && Core.Agent.DynamicFieldReferenceSearch
            ),
            initElementAvailable: !!(
                window.Core
                && Core.Agent
                && Core.Agent.DynamicFieldReferenceSearch
                && typeof Core.Agent.DynamicFieldReferenceSearch.InitElement === 'function'
            )
        });

        Array.prototype.forEach.call(ReferenceFields, function (Element) {
            EnsureAutocompleteActive(Element, 'scan');
        });
        EnsurePickerButtons(document);
        AutoPopulatePlatformFromApplication();
        StartWatcher();
    }

    function OnInput(Event) {
        var Element = Event && Event.target;
        var Info;
        var Key;

        if (!IsInterestingField(Element)) {
            return;
        }

        EnsureAutocompleteActive(Element, Event.type || 'input');

        Info = FieldInfo(Element);
        if ((Event.type || '') !== 'focusin') {
            ForceAutocompleteSearch(Element, Event.type || 'input');
        }
        Key = [
            Event.type || '',
            Info.id,
            Info.name,
            Info.relatedId,
            Info.relatedName,
            Info.value
        ].join('|');

        if (Key === LastLoggedKey) {
            return;
        }
        LastLoggedKey = Key;

        window.clearTimeout(InputTimer);
        InputTimer = window.setTimeout(function () {
            Log(Event.type || 'input', Info);
        }, 100);
    }

    function HookXHR() {
        if (!window.XMLHttpRequest || !window.XMLHttpRequest.prototype) {
            return;
        }

        var OriginalOpen = window.XMLHttpRequest.prototype.open;
        var OriginalSend = window.XMLHttpRequest.prototype.send;

        if (OriginalOpen && !OriginalOpen.ZTSMCustomerReferenceTraceWrapped) {
            window.XMLHttpRequest.prototype.open = function (Method, URL) {
                this.ZTSMTraceURL = URL || '';
                this.ZTSMTraceMethod = Method || '';
                if (InterestingAction.test(this.ZTSMTraceURL)) {
                    Log('xhr-open', {
                        method: this.ZTSMTraceMethod,
                        url: this.ZTSMTraceURL
                    });
                }
                return OriginalOpen.apply(this, arguments);
            };
            window.XMLHttpRequest.prototype.open.ZTSMCustomerReferenceTraceWrapped = true;
        }

        if (OriginalSend && !OriginalSend.ZTSMCustomerReferenceTraceWrapped) {
            window.XMLHttpRequest.prototype.send = function (Body) {
                if (InterestingAction.test(this.ZTSMTraceURL || '')) {
                    Log('xhr-send', {
                        method: this.ZTSMTraceMethod || '',
                        url: this.ZTSMTraceURL || '',
                        bodyType: Body && Body.constructor ? Body.constructor.name : typeof Body
                    });
                }
                return OriginalSend.apply(this, arguments);
            };
            window.XMLHttpRequest.prototype.send.ZTSMCustomerReferenceTraceWrapped = true;
        }
    }

    function HookJQuery() {
        if (!window.jQuery || typeof window.jQuery.ajaxPrefilter !== 'function') {
            return;
        }

        window.jQuery.ajaxPrefilter(function (Options) {
            var URL = Options && Options.url ? Options.url : '';
            if (InterestingAction.test(URL)) {
                Log('jquery-ajax', {
                    type: Options.type || Options.method || '',
                    url: URL
                });
            }
        });
    }

    HookXHR();
    HookJQuery();
    if (window.MutationObserver) {
        new MutationObserver(function () {
            window.clearTimeout(PickerScanTimer);
            PickerScanTimer = window.setTimeout(function () {
                EnsurePickerButtons(document);
            }, 100);
        }).observe(document.documentElement, {
            childList: true,
            subtree: true
        });
    }
    document.addEventListener('focusin', OnInput, true);
    document.addEventListener('input', OnInput, true);
    document.addEventListener('keyup', OnInput, true);
    document.addEventListener('paste', OnInput, true);
    document.addEventListener('change', OnInput, true);
    document.addEventListener('change', function (Event) {
        if (Event && Event.target && /DynamicField_ZTicket-Application/.test((Event.target.id || '') + ' ' + (Event.target.name || ''))) {
            window.setTimeout(AutoPopulatePlatformFromApplication, 150);
        }
        window.setTimeout(function () {
            EnsurePickerButtons(document);
        }, 150);
    }, true);

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', Scan);
    }
    else {
        window.setTimeout(Scan, 0);
    }
}());
