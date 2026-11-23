/* global Core, $ */
(function () {
    'use strict';
    var generation = 0;
    var activeInput = 'oooSearch';

    function query($root) {
        var $input = $('#' + activeInput);
        if (!$input.length) { $input = $('#FulltextES'); }
        var value = String($input.val() || '').trim();
        // Native customer search clears #oooSearch on blur. The open dialog
        // still owns its query; explicit edits invalidate responses below.
        if (value || $input.is(':focus')) { return value; }
        return String($root.attr('data-search-query') || '').trim();
    }

    $(function () {
        $(document).off('.TESSERASearchPaging');
        $(document).on('input.TESSERASearchPaging', '#oooSearch, #FulltextES', function () {
            activeInput = this.id;
            generation += 1;
        });
        $(document).on('submit.TESSERASearchPaging', 'form[data-workplace-search="1"]', function (event) {
            event.preventDefault();
            $(this).find('#oooSearch').trigger('input');
        });
        $(document).on('click.TESSERASearchPaging', '.TESSERASearchPage, .TESSERASearchType', function (event) {
            event.preventDefault();
            var $button = $(this), $root = $button.closest('.TESSERATicketSearchResults'),
                $outer = $root.closest('#oooESOuter'), page = String($button.attr('data-search-page') || ''),
                text = String($root.attr('data-search-query') || ''),
                isType = $button.hasClass('TESSERASearchType'),
                scope = String((isType ? $button.attr('data-search-scope') : $root.attr('data-search-scope')) || 'Ticket'),
                direction = $button.attr('data-search-direction') === 'previous' ? 'previous' : 'next';
            if (isType) { page = '1'; }
            if ($button.prop('disabled') || !$outer.length || !/^[1-9][0-9]{0,8}$/.test(page) || query($root) !== text.trim()) { return; }
            var ticket = ++generation, root = $root[0], outer = $outer[0],
                controls = $root.find('.TESSERASearchPage, .TESSERASearchType').toArray(),
                disabled = controls.map(function (control) { return control.disabled; }),
                buttonHadFocus = document.activeElement === $button[0];
            function current() {
                return ticket === generation && $.contains(document, root) && $.contains(outer, root)
                    && $outer.closest('.Dialog').is(':visible') && query($root) === text.trim();
            }
            function error() {
                if (current()) { $root.find('.TESSERASearchPageError').text('Unable to load this page. Please try again.'); }
            }
            $root.attr('aria-busy', 'true').find('.TESSERASearchPageError').empty();
            $(controls).prop('disabled', true);
            var request = Core.AJAX.FunctionCall(Core.Config.Get('Baselink'), {
                Action: 'CustomerElasticsearchQuickResult', Subaction: 'SearchUpdate',
                FulltextES: text, SearchPage: page, SearchScope: scope, URL: window.location.href
            }, function (response) {
                if (!current()) { return; }
                var nodes = $.parseHTML(response, document, false), $content = $(nodes),
                    $replacement = $content.filter('.TESSERATicketSearchResults')
                        .add($content.find('.TESSERATicketSearchResults'));
                if ($replacement.length !== 1 || String($replacement.attr('data-search-query') || '') !== text) { error(); return; }
                var restoreFocus = document.activeElement === document.body || $.contains(root, document.activeElement);
                $outer.empty().append($replacement);
                $replacement.find('.TESSERASearchScroll').scrollTop(0);
                if (restoreFocus) {
                    var $focus = isType ? $replacement.find('.TESSERASearchType[aria-pressed="true"]').first()
                        : $replacement.find('.TESSERASearchPage[data-search-direction="' + direction + '"]:enabled').first();
                    if (!$focus.length) { $focus = $replacement.find('.TESSERASearchPage:enabled').first(); }
                    if (!$focus.length) { $focus = $replacement.find('.TESSERASearchSummary'); }
                    $focus.trigger('focus');
                }
            }, 'html');
            request.fail(error).always(function () {
                if (!current()) { return; }
                $root.removeAttr('aria-busy');
                controls.forEach(function (control, index) { control.disabled = disabled[index]; });
                if (buttonHadFocus && document.activeElement === document.body) { $button.trigger('focus'); }
            });
        });
    });
}());
