// TESSERA customer ticket reference picker.
//
// Keep this intentionally small. It adds the search button and modal only;
// it does not wrap autocomplete, poll values, hook XHR globally, or observe
// the full document. DynamicFieldSet/Group rows are enhanced after add/remove
// clicks or after the service payload explicitly asks for it.
(function () {
    'use strict';

    var StyleInstalled = false;
    var ScanTimer;
    var Requests = {};

    function InstallStyles() {
        var Style;

        if (StyleInstalled) {
            return;
        }
        StyleInstalled = true;

        Style = document.createElement('style');
        Style.type = 'text/css';
        Style.appendChild(document.createTextNode([
            '.ZTSMReferencePickerCell{position:relative!important}',
            '.ZTSMReferencePickerManaged .AddRemoveValueRow{display:none!important}',
            '.ZTSMReferencePickerHiddenRow{display:none!important}',
            '#NewCustomerTicket label.ZTSMReferencePickerLabelFloated{position:absolute!important;top:-9px!important;left:14px!important;width:auto!important;height:auto!important;max-width:calc(100% - 96px)!important;padding:0 6px!important;margin:0!important;display:inline-block!important;background:#fff!important;color:#7f809d!important;font-size:13px!important;line-height:18px!important;transform:none!important;z-index:3!important;white-space:nowrap!important;overflow:hidden!important;text-overflow:ellipsis!important;pointer-events:auto!important}',
            '#NewCustomerTicket .ZTSMReferencePickerCell.ZTSMReferencePickerHasValue{position:relative!important}',
            '#NewCustomerTicket .ZTSMReferencePickerCell.ZTSMReferencePickerHasValue input.DynamicFieldReference:not([type="hidden"]){min-height:70px!important;padding-top:18px!important;padding-bottom:8px!important;padding-right:128px!important;box-sizing:border-box!important}',
            '#NewCustomerTicket .ZTSMReferencePickerCell input.ZTSMReferencePickerReadonly{cursor:default!important;background-color:inherit!important;color:inherit!important;-webkit-text-fill-color:inherit!important}',
            '.ZTSMReferencePickerButton{all:unset!important;appearance:none!important;-webkit-appearance:none!important;box-sizing:border-box!important;position:absolute!important;right:72px!important;top:50%!important;transform:translateY(-50%)!important;z-index:50!important;display:inline-flex!important;align-items:center!important;justify-content:center!important;width:34px!important;min-width:34px!important;max-width:34px!important;height:34px!important;min-height:34px!important;max-height:34px!important;margin:0!important;padding:0!important;border:1px solid #8784aa!important;background:#fff!important;color:#04084f!important;border-radius:6px!important;cursor:pointer!important;font-size:16px!important;line-height:1!important;box-shadow:none!important;font-family:Arial,sans-serif!important;text-align:center!important;text-decoration:none!important;overflow:hidden!important;pointer-events:auto!important}',
            '.ZTSMReferencePickerButton:hover,.ZTSMReferencePickerButton:focus{background:#f6f6fb!important;outline:2px solid #b9b7d5!important;outline-offset:2px!important}',
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
        return String(Value || '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    function IsReferenceField(Element) {
        return Element
            && String(Element.className || '').indexOf('DynamicFieldReference') !== -1
            && /(?:^|_)DynamicField_/.test((Element.id || '') + ' ' + (Element.name || ''));
    }

    function FieldName(Element) {
        return String((Element && (Element.id || Element.name)) || '')
            .replace(/^Autocomplete_/, '')
            .replace(/^DynamicField_/, '')
            .replace(/_\d+(?:_\d+)?$/, '');
    }

    function FieldTitle(Element) {
        var Name = FieldName(Element),
            Label = Element && Element.id ? document.querySelector('label[for="' + Element.id + '"]') : null;

        if (!Label) {
            Label = document.querySelector('label[for="DynamicField_' + Name + '"]');
        }

        return String((Label && Label.textContent) || Name || 'reference')
            .replace(/\s*\*\s*$/, '')
            .trim();
    }

    function DisplayValue(Element) {
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

    function HiddenField(Element) {
        var HiddenID,
            Scope,
            Hidden;

        if (!Element) {
            return null;
        }

        HiddenID = (Element.id || '').replace(/^Autocomplete_/, '');
        Scope = Element.closest ? Element.closest('.FieldCell, .Field, .Row_DynamicField') : null;

        if (Scope && Scope.querySelector) {
            Hidden = Scope.querySelector('input[type="hidden"][id="' + HiddenID.replace(/"/g, '\\"') + '"]');
            if (Hidden) {
                return Hidden;
            }
        }

        return HiddenID ? document.getElementById(HiddenID) : null;
    }

    function LabelForField(Element, Hidden) {
        var Label,
            ID;

        ID = (Element && Element.id) || (Hidden && Hidden.id) || '';
        if (ID) {
            Label = document.querySelector('label[for="' + ID.replace(/"/g, '\\"') + '"]');
            if (Label) {
                return Label;
            }
        }

        if (Element && Element.closest) {
            Label = Element.closest('.FieldCell, .Field, .Row_DynamicField');
            if (Label && Label.querySelector) {
                return Label.querySelector('label');
            }
        }

        return null;
    }

    function LabelStateRefresh(Element, Hidden) {
        var Label = LabelForField(Element, Hidden),
            Scope = Element && Element.closest ? Element.closest('.ZTSMReferencePickerCell, .FieldCell, .Field, .Row_DynamicField') : null,
            HasValue = !!(
                (Element && String(Element.value || '').trim())
                || (Hidden && String(Hidden.value || '').trim())
            );

        if (Scope && Scope.classList) {
            if (HasValue) {
                Scope.classList.add('ZTSMReferencePickerHasValue');
                Scope.classList.add('ZTSMServicePayloadHasValue');
            }
            else {
                Scope.classList.remove('ZTSMReferencePickerHasValue');
                Scope.classList.remove('ZTSMServicePayloadHasValue');
            }
        }

        if (!Label || !Label.classList) {
            return;
        }

        if (HasValue) {
            Label.classList.add('ZTSMReferencePickerLabelFloated');
            Label.classList.add('ZTSMServicePayloadLabelFloated');
        }
        else {
            Label.classList.remove('ZTSMReferencePickerLabelFloated');
            Label.classList.remove('ZTSMServicePayloadLabelFloated');
        }
    }

    function FieldEventFire(Element, Type) {
        if (!Element) {
            return;
        }

        if (window.jQuery) {
            window.jQuery(Element).trigger(Type);
            return;
        }

        Element.dispatchEvent(new Event(Type, { bubbles: true }));
    }

    function PickerAppliedEventFire(Element, Items) {
        var Hidden = HiddenField(Element),
            FirstItem = Items && Items.length ? Items[0] : null,
            Detail;

        if (!Element) {
            return;
        }

        Detail = {
            element: Element,
            hidden: Hidden,
            field: FieldName(Element),
            value: Hidden ? (Hidden.value || '') : (Element.value || ''),
            label: Element.value || '',
            item: FirstItem || null,
            items: Items || []
        };

        document.dispatchEvent(new CustomEvent('ZTSMReferencePicker:applied', {
            bubbles: true,
            detail: Detail
        }));
    }

    function FieldValueSettle(Element, Hidden) {
        var Scope = Element && Element.closest ? Element.closest('.FieldCell, .Field, .Row_DynamicField') : null;

        LabelStateRefresh(Element, Hidden);

        if (typeof window.ZTSMServicePayloadVisibleSelectionRefresh === 'function') {
            window.ZTSMServicePayloadVisibleSelectionRefresh(Scope || Element || document);
        }
    }

    function RefreshVisibleState(Element, Hidden) {
        var Settle;

        if (Element && Element.classList) {
            if (String(Element.value || '').trim()) {
                Element.classList.add('oooFull');
            }
            else {
                Element.classList.remove('oooFull');
            }
        }
        Settle = function () {
            FieldValueSettle(Element, Hidden);
        };

        Settle();

        if (Element) {
            FieldEventFire(Element, 'input');
            FieldEventFire(Element, 'change');
            FieldEventFire(Element, 'focusout');
            FieldEventFire(Element, 'blur');
            if (document.activeElement === Element && Element.blur) {
                Element.blur();
            }
        }
        if (Hidden) {
            FieldEventFire(Hidden, 'input');
            FieldEventFire(Hidden, 'change');
        }

        window.setTimeout(Settle, 0);
        window.setTimeout(Settle, 80);
    }

    function MakeReadonlyDisplay(Element) {
        if (!Element || Element.tagName !== 'INPUT' || Element.type === 'hidden') {
            return;
        }

        Element.readOnly = true;
        Element.setAttribute('readonly', 'readonly');
        Element.classList.add('ZTSMReferencePickerReadonly');
    }

    function FormQuery(Element, Extra) {
        var Form = Element && Element.closest ? Element.closest('form') : document.querySelector('form'),
            Parts = [],
            Data = Extra || {};

        if (Form && window.Core && Core.AJAX && typeof Core.AJAX.SerializeForm === 'function' && window.jQuery) {
            Parts.push(Core.AJAX.SerializeForm(window.jQuery(Form), {
                Action: 1,
                Subaction: 1,
                Term: 1,
                Field: 1,
                MaxResults: 1,
                Picker: 1
            }));
        }
        else if (Form) {
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

        return Parts.filter(Boolean).join(';');
    }

    function NormalizeRows(Result) {
        if (!Result) {
            return [];
        }
        if (Array.isArray(Result)) {
            return Result;
        }
        if (Array.isArray(Result.results)) {
            return Result.results;
        }
        if (Array.isArray(Result.Result)) {
            return Result.Result;
        }
        return [];
    }

    function PickerSearch(Element, Term, Callback) {
        var Base,
            Key,
            Request,
            QueryString;

        if (!Element || !window.Core || !Core.Config || typeof Core.Config.Get !== 'function') {
            Callback([]);
            return;
        }

        Base = Core.Config.Get('Baselink');
        QueryString = 'Action=AgentReferenceSearch;Picker=1;Term=' + encodeURIComponent(Term || '')
            + ';Field=' + encodeURIComponent(Element.id || Element.name || '')
            + ';MaxResults=50;'
            + FormQuery(Element);

        Key = Element.id || Element.name || 'ZTSMReferencePicker';
        if (Requests[Key] && typeof Requests[Key].abort === 'function') {
            Requests[Key].abort();
        }

        Request = new XMLHttpRequest();
        Requests[Key] = Request;
        Request.open('GET', Base + QueryString, true);
        Request.onreadystatechange = function () {
            var Rows = [];

            if (Request.readyState !== 4) {
                return;
            }
            if (Request.status >= 200 && Request.status < 300) {
                try {
                    Rows = NormalizeRows(JSON.parse(Request.responseText || '[]'));
                }
                catch (Error) {
                    Rows = [];
                }
            }
            Callback(Rows);
        };
        Request.send();
    }

    function ApplySelection(Element, Item) {
        var Label,
            Key,
            Hidden;

        if (!Element || !Item) {
            return;
        }

        Label = Item.Description || Item.Label || Item.label || Item.Value || Item.value || Item.Name || '';
        Key = Item.key || Item.Key || Item.Number || '';
        Hidden = HiddenField(Element);

        if (Element.tagName === 'SELECT') {
            if (Key && !Array.prototype.some.call(Element.options || [], function (Option) {
                return String(Option.value) === String(Key);
            })) {
                Element.appendChild(new Option(Label, Key));
            }
            Element.value = Key;
        }
        else {
            Element.value = Label;
            if (Hidden) {
                Hidden.disabled = false;
                Hidden.value = Key;
            }
        }

        RefreshVisibleState(Element, Hidden);
    }

    function ItemLabel(Item) {
        return Item && (Item.Description || Item.Label || Item.label || Item.Value || Item.value || Item.Name || '') || '';
    }

    function ItemKey(Item) {
        return Item && (Item.key || Item.Key || Item.Number || '') || '';
    }

    function MultiValueSlots(Element, Hidden) {
        var Form = Element && Element.closest ? Element.closest('form') : document.querySelector('form'),
            Name = Hidden && Hidden.name,
            Slots = [];

        if (!Form || !Name) {
            return Slots;
        }

        Array.prototype.forEach.call(Form.querySelectorAll('input[type="hidden"][name="' + Name.replace(/"/g, '\\"') + '"]'), function (Field) {
            var ID = Field.id || '',
                Visible;

            if (/_Template$/.test(ID)) {
                return;
            }

            Visible = ID ? document.getElementById('Autocomplete_' + ID) : null;
            Slots.push({
                hidden: Field,
                visible: Visible,
                row: Field.closest ? Field.closest('.Row_DynamicField, .FieldCell, .Field') : null
            });
        });

        Slots.sort(function (A, B) {
            return String(A.hidden.id || '').localeCompare(String(B.hidden.id || ''), undefined, { numeric: true });
        });

        return Slots;
    }

    function NestedGroupReference(Element, Hidden) {
        var Name = Hidden && Hidden.name || Element && Element.name || Element && Element.id || '';

        return /^DynamicField_.+_.+_\d+_\d+(?:\[\])?$/.test(Name);
    }

    function PickerMultiValue(Element, Rows) {
        var Hidden = HiddenField(Element);

        if (NestedGroupReference(Element, Hidden)) {
            return false;
        }

        return !!(Rows || []).some(function (Row) {
            return !!(Row && Row.MultiValue);
        });
    }

    function ApplySelections(Element, Items) {
        var Hidden = HiddenField(Element),
            IsMultiValue = PickerMultiValue(Element, Items),
            Slots,
            Labels,
            Keys;

        if (!Element || !Items || !Items.length) {
            return;
        }

        if (!IsMultiValue) {
            ApplySelection(Element, Items[0]);
            PickerAppliedEventFire(Element, Items);
            return;
        }

        Labels = Items.map(ItemLabel).filter(Boolean);
        Keys = Items.map(ItemKey).filter(Boolean);
        Slots = MultiValueSlots(Element, Hidden);
        if (!Slots.length) {
            ApplySelection(Element, Items[0]);
            PickerAppliedEventFire(Element, Items);
            return;
        }

        Slots.forEach(function (Slot, Index) {
            var Label = Labels[Index] || '',
                Key = Keys[Index] || '';

            Slot.hidden.disabled = !Key;
            Slot.hidden.value = Key;

            if (Slot.visible) {
                Slot.visible.disabled = Index > 0;
                Slot.visible.value = Index === 0 ? Labels.join('; ') : Label;
                RefreshVisibleState(Slot.visible, Slot.hidden);
            }

            if (Slot.row && Slot.row.classList) {
                if (Index > 0 || !Key) {
                    Slot.row.classList.add('ZTSMReferencePickerHiddenRow');
                }
                else {
                    Slot.row.classList.remove('ZTSMReferencePickerHiddenRow');
                }
            }
        });

        if (Slots[0]) {
            RefreshVisibleState(Slots[0].visible || Element, Slots[0].hidden);
        }
        PickerAppliedEventFire(Element, Items);
    }

    function RenderRows(Dialog, Rows) {
        var Body = Dialog.querySelector('.ZTSMReferencePickerBody'),
            IsMultiValue,
            ChoiceType,
            HTML;

        if (!Rows || !Rows.length) {
            Body.innerHTML = '<div class="ZTSMReferencePickerEmpty">No matching records.</div>';
            Body.ZTSMReferencePickerRows = [];
            Body.ZTSMReferencePickerMultiValue = false;
            return;
        }

        IsMultiValue = PickerMultiValue(Element, Rows);
        ChoiceType = IsMultiValue ? 'checkbox' : 'radio';
        HTML = '<table class="ZTSMReferencePickerTable"><thead><tr>'
            + '<th></th><th>Name</th><th>Class</th><th>Number</th><th>Status</th><th>Description</th>'
            + '</tr></thead><tbody>';
        Rows.forEach(function (Row, Index) {
            HTML += '<tr>'
                + '<td><input type="' + ChoiceType + '" name="ZTSMReferencePickerChoice" value="' + Index + '"></td>'
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
        Body.ZTSMReferencePickerMultiValue = IsMultiValue;
    }

    function OpenPicker(Element) {
        var Overlay,
            Dialog;

        InstallStyles();
        Overlay = document.createElement('div');
        Overlay.className = 'ZTSMReferencePickerOverlay';
        Overlay.innerHTML = ''
            + '<div class="ZTSMReferencePickerDialog" role="dialog" aria-modal="true">'
            + '<div class="ZTSMReferencePickerHeader"><span>Select ' + EscapeHTML(FieldTitle(Element)) + '</span><button type="button" class="ZTSMReferencePickerClose" title="Close">&times;</button></div>'
            + '<div class="ZTSMReferencePickerToolbar"><input class="ZTSMReferencePickerSearch" type="search" value="' + EscapeHTML(DisplayValue(Element)) + '"><button type="button" class="ZTSMReferencePickerSearchButton">Search</button></div>'
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
                RenderRows(Dialog, Rows);
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
            var Checked = Overlay.querySelectorAll('input[name="ZTSMReferencePickerChoice"]:checked'),
                Rows = Dialog.querySelector('.ZTSMReferencePickerBody').ZTSMReferencePickerRows || [];

            if (!Checked.length) {
                return;
            }
            ApplySelections(Element, Array.prototype.map.call(Checked, function (Choice) {
                return Rows[parseInt(Choice.value, 10)];
            }).filter(Boolean));
            Close();
        });
        Search();
    }

    function ExistingButton(Cell, Key) {
        var Button;

        if (!Cell || !Cell.querySelector) {
            return null;
        }

        Button = Cell.querySelector('.ZTSMReferencePickerButton[data-ztsm-reference-picker-for="' + String(Key || '').replace(/"/g, '\\"') + '"]');
        if (Button) {
            return Button;
        }

        return Array.prototype.filter.call(Cell.querySelectorAll('.ZTSMReferencePickerButton'), function (Candidate) {
            return Candidate.parentNode === Cell;
        })[0] || null;
    }

    function BindPickerButton(Button, Element, Key) {
        if (!Button || !Element) {
            return;
        }

        Button.type = 'button';
        Button.setAttribute('tabindex', '0');
        Button.setAttribute('data-ztsm-reference-picker-for', Key);
        Button.title = 'Search and select';
        Button.setAttribute('aria-label', 'Search and select ' + FieldTitle(Element));
        Button.innerHTML = '&#128269;';

        if (Button.ZTSMReferencePickerBoundElement === Element) {
            return;
        }
        Button.ZTSMReferencePickerBoundElement = Element;

        Button.addEventListener('pointerdown', function (Event) {
            Event.preventDefault();
            Event.stopPropagation();
        }, true);
        Button.addEventListener('mousedown', function (Event) {
            Event.preventDefault();
            Event.stopPropagation();
        }, true);
        Button.addEventListener('click', function (Event) {
            Event.preventDefault();
            Event.stopPropagation();
            OpenPicker(Element);
        }, true);
        Button.addEventListener('keydown', function (Event) {
            if (Event.key === 'Enter' || Event.key === ' ') {
                Event.preventDefault();
                Event.stopPropagation();
                OpenPicker(Element);
            }
        }, true);
    }

    function Enhance(Root) {
        Root = Root || document;
        InstallStyles();
        Array.prototype.forEach.call(Root.querySelectorAll('input.DynamicFieldReference[id*="DynamicField_"], input[id^="Autocomplete_DynamicField_"], select.DynamicFieldReference[id*="DynamicField_"]'), function (Element) {
            var Cell,
                Row,
                Key,
                Button,
                Tooltip,
                TooltipContent;

            if (!IsReferenceField(Element) || Element.type === 'hidden') {
                return;
            }

            Cell = Element.closest ? (Element.closest('.FieldCell') || Element.closest('.Field') || Element.parentNode) : Element.parentNode;
            if (!Cell) {
                return;
            }

            Key = Element.id || Element.name || '';
            Cell.classList.add('ZTSMReferencePickerCell');
            Tooltip = Array.prototype.filter.call(Cell.children || [], function (Child) {
                return Child.classList
                    && Child.classList.contains('Tooltip')
                    && Child.classList.contains('oooTooltip');
            })[0];
            if (Tooltip) {
                Tooltip.classList.add('ZTSMReferencePickerTooltip');
                Tooltip.style.setProperty('position', 'absolute', 'important');
                Tooltip.style.setProperty('top', '50%', 'important');
                Tooltip.style.setProperty('right', '116px', 'important');
                Tooltip.style.setProperty('bottom', 'auto', 'important');
                Tooltip.style.setProperty('left', 'auto', 'important');
                Tooltip.style.setProperty('margin', '-9px 0 0', 'important');
                Tooltip.style.setProperty('transform', 'none', 'important');
                TooltipContent = Tooltip.querySelector(':scope > .Content');
                if (TooltipContent) {
                    TooltipContent.style.setProperty('right', '0', 'important');
                    TooltipContent.style.setProperty('left', 'auto', 'important');
                }
            }
            MakeReadonlyDisplay(Element);
            Row = Element.closest ? Element.closest('.Row_DynamicField') : null;
            if (Row && Row.classList) {
                Row.classList.add('ZTSMReferencePickerManaged');
            }
            LabelStateRefresh(Element, HiddenField(Element));

            Button = ExistingButton(Cell, Key);
            if (Button) {
                BindPickerButton(Button, Element, Key);
                return;
            }

            Button = document.createElement('button');
            Button.className = 'ZTSMReferencePickerButton';
            BindPickerButton(Button, Element, Key);
            Cell.appendChild(Button);
        });
    }

    function EnhanceLater(Root) {
        window.clearTimeout(ScanTimer);
        ScanTimer = window.setTimeout(function () {
            Enhance(Root || document);
        }, 80);
    }

    window.ZTSMReferencePickerEnhance = EnhanceLater;

    document.addEventListener('click', function (Event) {
        var Control = Event && Event.target && Event.target.closest
            ? Event.target.closest('.AddValueRow, .RemoveValueRow')
            : null;

        if (Control) {
            EnhanceLater((Control.closest && Control.closest('.ZTSMServiceExtensionField, .FieldCell, .Row_DynamicField, .Field')) || document);
        }
    }, true);

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function () {
            Enhance(document);
        });
    }
    else {
        EnhanceLater(document);
    }
}());
