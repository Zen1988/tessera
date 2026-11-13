/* Local native-markup fixture check: requires jQuery, mocked Core.AJAX queue and rendered responses.json. No live portal calls. */
$(async function () {
    var results=[], metrics={};
    function check(name, value) { results.push({name:name,pass:!!value}); }
    function next() { return $('.TESSERASearchPage[data-search-direction="next"]'); }
    function root() { return $('.TESSERATicketSearchResults'); }
    function click() { next().trigger('focus').trigger('click'); return requests[requests.length-1]; }
    try {
        var pages=await (await fetch('responses.json')).json();
        var scroll=$('.TESSERASearchScroll')[0], header=$('.Header')[0].getBoundingClientRect(), pager=$('.TESSERASearchPager')[0].getBoundingClientRect(), dialog=$('.Dialog')[0].getBoundingClientRect();
        metrics={viewport:[innerWidth,innerHeight],dialog:[dialog.left,dialog.top,dialog.right,dialog.bottom],scrollHeight:scroll.scrollHeight,clientHeight:scroll.clientHeight,pagerBottom:pager.bottom};
        check('bounded scroll area actually overflows',scroll.scrollHeight>scroll.clientHeight && scroll.clientHeight>0);
        scroll.scrollTop=120;check('result rows can scroll',scroll.scrollTop>0);
        check('header stationary on results scroll',$('.Header')[0].getBoundingClientRect().top===header.top);
        check('pager stationary on results scroll',$('.TESSERASearchPager')[0].getBoundingClientRect().top===pager.top);
        check('footer remains within dialog',pager.bottom<=dialog.bottom+1 && pager.top>=header.bottom);
        check('dialog within horizontal viewport',dialog.left>=0 && dialog.right<=innerWidth+1);
        check('next touch target at least44px',next()[0].getBoundingClientRect().height>=44);
        check('previous disabled on first page',$('.TESSERASearchPage[data-search-direction="previous"]').prop('disabled'));
        var first=click();check('next sends page2',first.data.SearchPage==='2');check('same fulltext preserved',first.data.FulltextES==='needle');
        var before=requests.length;next().trigger('click');check('duplicate loading click ignored',requests.length===before);
        first.deferred.resolve(pages['2']);
        check('page2 replaces just popup content',$('.TESSERASearchSummary').text().indexOf('11 to 20 of 363')>=0);
        check('page2 contains distinct ticket11',$('#TicketID_11').length===1 && $('#TicketID_1').length===0);
        check('new page scroll starts at top',$('.TESSERASearchScroll').scrollTop()===0);
        check('keyboard focus retained on pager',document.activeElement===next()[0]);
        var stale=click();$('#FulltextES').val('changed').trigger('input');stale.deferred.resolve(pages['3']);
        check('changed-query response discarded',$('.TESSERASearchSummary').text().indexOf('11 to 20')>=0);
        $('#FulltextES').val('needle').trigger('input');$('#oooESOuter').html(pages['2']);
        var closed=click();$('.Dialog').hide();closed.deferred.resolve(pages['3']);
        check('closed dialog never reopened',!$('.Dialog').is(':visible'));
        check('closed dialog response discarded',$('.TESSERASearchSummary').text().indexOf('11 to 20')>=0);
        $('.Dialog').show();$('#oooESOuter').html(pages['2']);
        var failed=click();failed.deferred.reject();check('failure restores controls',!next().prop('disabled') && !root().attr('aria-busy'));
        check('failure is announced locally',$('.TESSERASearchPageError').text().length>0);
        var old=click();$('#oooESOuter').html(pages['1']);old.deferred.resolve(pages['3']);
        check('detached old response cannot overwrite new search',$('.TESSERASearchSummary').text().indexOf('1 to 10')>=0);
        var safe=click();safe.deferred.resolve(pages['2']+'<script>window.unwantedScript=true;<\/script>');
        check('paging response does not execute scripts',!window.unwantedScript);
        $('#oooESOuter').html(pages['37']);check('last page has3 rows',$('tbody tr[id^="TicketID_"]').length===3);check('next disabled last page',next().prop('disabled'));
        $('#oooESOuter').html(pages['1']);
    } catch(error) { check('unexpected exception: '+error.message,false); }
    var report={results:results,metrics:metrics,passed:results.every(function(r){return r.pass;})};
    $('#testStatus').text(results.filter(function(r){return !r.pass;}).map(function(r){return r.name;}).join(' | ') || ('PASS '+results.length+' browser assertions'));
    await fetch('/results?name='+(new URLSearchParams(location.search).get('name')||'desktop'),{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(report)});
});
