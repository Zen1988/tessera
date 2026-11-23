/* Local real-template fixture. AJAX is mocked; no live requests or accounts. */
$(function () {
    'use strict';
    var checks = [];
    function check(name, value) { checks.push({name: name, pass: !!value}); }
    function scope(name) { return $('.TESSERASearchType[data-search-scope="' + name + '"]'); }
    function root() { return $('.TESSERAWorkplaceSearch'); }
    function summary() { return $('.TESSERASearchSummary').text(); }
    try {
        var box = $('.Dialog')[0].getBoundingClientRect(), scroll = $('.TESSERASearchScroll')[0];
        check('dialog fits viewport', box.left >= 0 && box.right <= innerWidth + 1);
        check('results have bounded internal scrolling', scroll.clientHeight > 0 && scroll.scrollHeight > scroll.clientHeight);
        check('filter touch target44px', scope('People')[0].getBoundingClientRect().height >= 44);
        check('four result types appear in All', $('tbody tr').length === 40);
        scope('People').trigger('focus').trigger('click');
        var first = requests[requests.length - 1];
        check('People filter sends explicit scope', first.data.SearchScope === 'People' && first.data.SearchPage === '1');
        var count = requests.length; scope('Asset').trigger('click');
        check('inflight filter click suppressed', count === requests.length);
        first.deferred.resolve(pages.People);
        check('selected filter announced', scope('People').attr('aria-pressed') === 'true');
        check('filter keyboard focus retained', document.activeElement === scope('People')[0]);
        check('people rows contain email', $('tbody').text().indexOf('@example.test') >= 0);
        $('.TESSERASearchPage[data-search-direction="next"]').trigger('focus').trigger('click');
        var next = requests[requests.length - 1];
        check('paging preserves selected scope', next.data.SearchScope === 'People' && next.data.SearchPage === '2');
        next.deferred.resolve(pages.People2);
        check('page2 distinct results reached', $('tbody').text().indexOf('Person 11') >= 0);
        check('last page next disabled', $('.TESSERASearchPage[data-search-direction="next"]').prop('disabled'));
        scope('FAQ').trigger('click'); var stale = requests[requests.length - 1];
        $('#oooSearch').val('changed').trigger('input'); stale.deferred.resolve(pages.FAQ);
        check('changed query discards late scope response', root().attr('data-search-scope') === 'People');
        $('#oooSearch').val('needle').trigger('input'); $('#oooESOuter').html(pages.People);
        scope('FAQ').trigger('click'); requests[requests.length - 1].deferred.reject();
        check('failed scope request recovers controls', !scope('FAQ').prop('disabled') && !root().attr('aria-busy'));
        check('failed scope request announced', $('.TESSERASearchPageError').text().length > 0);
        scope('Asset').trigger('click'); requests[requests.length - 1].deferred.resolve(pages.Asset + '<script>window.badScript=true;<\/script>');
        check('scope response scripts not executed', !window.badScript);
        check('asset link uses native detail destination', $('tbody a').first().attr('href').indexOf('CustomerITSMConfigItemZoom') >= 0);
        scope('FAQ').trigger('click'); var closed = requests[requests.length - 1]; $('.Dialog').hide(); closed.deferred.resolve(pages.FAQ);
        check('closed dialog never reopened or replaced', !$('.Dialog').is(':visible') && root().attr('data-search-scope') === 'Asset');
        $('.Dialog').show(); $('#oooESOuter').html(pages.All);
        scroll = $('.TESSERASearchScroll')[0]; scroll.scrollTop = 160;
        check('result rows scroll', scroll.scrollTop > 0);
        check('filters remain visible while rows scroll', scope('All')[0].getBoundingClientRect().top >= $('.Header')[0].getBoundingClientRect().bottom);
    }
    catch (error) { check('unexpected exception: ' + error.message, false); }
    $('#testStatus').text(JSON.stringify({passed: checks.every(function (c) { return c.pass; }), checks: checks}));
});
