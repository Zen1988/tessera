Core.ZTSM = Core.ZTSM || {};
Core.ZTSM.Agent = Core.ZTSM.Agent || {};
Core.ZTSM.Agent.ConfigItem = Core.ZTSM.Agent.ConfigItem || {};

(function (TargetNS) {
    'use strict';

    function ParseCell(Value) {
        if (typeof Value !== 'string') { return Value; }
        var Text = Value.trim();
        if ((Text[0] === '{' && Text[Text.length - 1] === '}') || (Text[0] === '[' && Text[Text.length - 1] === ']')) {
            try { return JSON.parse(Text); } catch (Ignore) { return Value; }
        }
        return Value;
    }

    TargetNS.Init = function () {
        var Preview = Core.Config.Get('ZTSMConfigItemWorkbookPreview') || [];
        var ExportButton = document.getElementById('ZTSMWorkbookExport');
        var TemplateButton = document.getElementById('ZTSMWorkbookTemplate');
        var PreviewButton = document.getElementById('ZTSMWorkbookPreview');
        var CommitButton = document.getElementById('ZTSMWorkbookCommit');

        function DownloadWorkbook(EmptyTemplate) {
            var Select = document.getElementById('ZTSMWorkbookClassID');
            var SelectedClassID = Select ? Select.value : '';
            if (!SelectedClassID) {
                window.alert('Select a ConfigItem class first.');
                return;
            }
            window.location.href = (Core.Config.Get('Baselink') || 'index.pl?')
                + 'Action=AgentITSMConfigItemWorkbook;Subaction=Download;ClassID=' + encodeURIComponent(SelectedClassID)
                + ';Empty=' + (EmptyTemplate ? '1' : '0');
        }

        if (ExportButton) {
            ExportButton.addEventListener('click', function () { DownloadWorkbook(false); });
        }
        if (TemplateButton) {
            TemplateButton.addEventListener('click', function () { DownloadWorkbook(true); });
        }
        var ClassSelect = document.getElementById('ZTSMWorkbookClassID');
        if (ClassSelect) {
            ClassSelect.addEventListener('change', function () {
                window.location.href = (Core.Config.Get('Baselink') || 'index.pl?')
                    + 'Action=AgentITSMConfigItemWorkbook;ClassID=' + encodeURIComponent(ClassSelect.value);
            });
        }

        if (PreviewButton) {
            PreviewButton.addEventListener('click', function () {
                var File = document.getElementById('ZTSMWorkbookFile').files[0];
                if (!File) { window.alert('Select an XLSX file first.'); return; }
                File.arrayBuffer().then(function (Buffer) {
                    var Workbook = XLSX.read(Buffer, { type: 'array', cellDates: false });
                    var Rows = [];
                    Workbook.SheetNames.forEach(function (SheetName) {
                        if (SheetName === 'Instructions' || SheetName === '_Selections') { return; }
                        XLSX.utils.sheet_to_json(Workbook.Sheets[SheetName], { defval: '' }).forEach(function (Row) {
                            var Parsed = { Class: Row.Class || SheetName };
                            Object.keys(Row).forEach(function (Key) { Parsed[Key] = ParseCell(Row[Key]); });
                            Parsed.__ExcelDate1904 = !!(Workbook.Workbook && Workbook.Workbook.WBProps && Workbook.Workbook.WBProps.date1904);
                            Rows.push(Parsed);
                        });
                    });
                    document.getElementById('ZTSMWorkbookPayload').value = JSON.stringify(Rows);
                    document.getElementById('ZTSMWorkbookPreviewForm').submit();
                });
            });
        }

        var PreviewContainer = document.getElementById('ZTSMWorkbookPreviewTable');
        if (PreviewContainer && Preview.length) {
            var HTML = '<table class="DataTable"><thead><tr><th>Row</th><th>Class</th><th>Number</th><th>Name</th><th>Status</th><th>Candidate</th><th>Operation</th></tr></thead><tbody>';
            Preview.forEach(function (Row, Index) {
                var Update = Row.CandidateNumber || Row.Number || '';
                var Clears = Row.ClearFields || [];
                var UpdateValue = Clears.length ? 'UPDATE_CLEAR:' + Update : 'UPDATE:' + Update;
                var UpdateLabel = Clears.length ? 'Update and clear ' + Clears.length + ' field(s)' : 'Update ' + Update;
                var Warning = Clears.length ? '<br><strong>Will clear:</strong> ' + Core.App.EscapeHTML(Clears.join(', ')) : '';
                var CandidateCount = parseInt(Row.CandidateCount, 10) || 0;
                var DefaultUpdate = Update && (Row.Status === 'MATCH_NUMBER' || CandidateCount === 1);
                var DefaultCreate = !DefaultUpdate && Row.Status === 'CREATE_CANDIDATE' && CandidateCount === 0;
                var DefaultDecision = DefaultUpdate ? UpdateValue : (DefaultCreate ? 'CREATE' : '');
                HTML += '<tr><td>' + (Index + 1) + '</td><td>' + Core.App.EscapeHTML(Row.Class) + '</td><td>' + Core.App.EscapeHTML(Row.Number) + '</td><td>' + Core.App.EscapeHTML(Row.Name) + '</td><td>' + Core.App.EscapeHTML(Row.Status) + Warning + '</td><td>' + Core.App.EscapeHTML(Row.CandidateNumber) + '</td><td><select class="ZTSMWorkbookDecision" data-default="' + Core.App.EscapeHTML(DefaultDecision) + '"><option value="">-- review --</option><option value="CREATE">Create new</option>' + (Update ? '<option value="' + Core.App.EscapeHTML(UpdateValue) + '">' + Core.App.EscapeHTML(UpdateLabel) + '</option>' : '') + '<option value="SKIP">Skip</option></select></td></tr>';
            });
            PreviewContainer.innerHTML = HTML + '</tbody></table>';
            Array.prototype.forEach.call(PreviewContainer.querySelectorAll('.ZTSMWorkbookDecision'), function (Select) {
                Select.value = Select.getAttribute('data-default') || '';
            });
        }

        if (CommitButton) {
            CommitButton.addEventListener('click', function () {
                var Decisions = Array.prototype.map.call(document.querySelectorAll('.ZTSMWorkbookDecision'), function (Select) { return Select.value; });
                if (Decisions.some(function (Value) { return !Value; })) { window.alert('Review rows with ambiguous identity and choose an operation.'); return; }
                if (Decisions.some(function (Value) { return Value.indexOf('UPDATE_CLEAR:') === 0; }) && !window.confirm('One or more updates will clear existing populated fields. Continue with these destructive updates?')) { return; }
                document.getElementById('ZTSMWorkbookDecisions').value = JSON.stringify(Decisions);
                document.getElementById('ZTSMWorkbookCommitForm').submit();
            });
        }
    };
    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');
}(Core.ZTSM.Agent.ConfigItem.Workbook = Core.ZTSM.Agent.ConfigItem.Workbook || {}));
