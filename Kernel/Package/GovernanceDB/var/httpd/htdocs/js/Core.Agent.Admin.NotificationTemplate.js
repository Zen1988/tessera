'use strict';

Core.Agent.Admin.NotificationTemplate = (function (TargetNS) {
    TargetNS.Init = function () {
        const Form = document.getElementById('NotificationTemplateForm');
        if (Form) {
            Form.addEventListener('click', InsertVariable);
            Core.UI.RichTextEditor.InitAllEditors();
        }
    };

    function InsertVariable(Event) {
        const Button = Event.target.closest('[data-notify-target]');
        if (!Button) {
            return;
        }

        const Variable = document.getElementById('NotifyVariable').value;
        if (!/^[A-Za-z][A-Za-z0-9_]{0,39}$/.test(Variable)
            || (Variable === 'OpenInTessera' && Button.dataset.notifyTarget === 'NotifySubject')) {
            return;
        }
        const Target = document.getElementById(Button.dataset.notifyTarget);
        const Token = '{{' + Variable + '}}';
        const Editor = typeof CKEditorInstances !== 'undefined' && CKEditorInstances[Target.id];
        if (Editor) {
            Editor.model.change(function (Writer) {
                Editor.model.insertContent(Writer.createText(Token));
            });
            Editor.editing.view.focus();
            Event.preventDefault();
        }
        else if (Target.getClientRects().length && typeof Target.setRangeText === 'function') {
            Target.setRangeText(Token, Target.selectionStart, Target.selectionEnd, 'end');
            Target.focus();
            Event.preventDefault();
        }
    }

    Core.Init.RegisterNamespace(TargetNS, 'APP_MODULE');
    return TargetNS;
}(Core.Agent.Admin.NotificationTemplate || {}));
