/* global Core, $ */
(function () {
    'use strict';
    function init() {
        var $calendar = $('#ZTSMCustomerTicketCalendar');
        if (!$calendar.length || !$.fn.fullCalendar) { return; }
        var requestGeneration = 0;
        function renderGroups(events) {
            var $panel = $('#ZTSMCustomerTicketGroups').empty();
            var groups = {}, other = [];
            $.each(events, function (_, event) {
                if (event.master && event.master.number) {
                    var key = String(event.master.id);
                    if (!groups[key]) { groups[key] = { master: event.master, tickets: [] }; }
                    groups[key].tickets.push(event);
                } else { other.push(event); }
            });
            other = $.grep(other, function (event) {
                var group = groups[String(event.id)];
                if (group) { group.tickets.unshift(event); return false; }
                return true;
            });
            function addList($container, tickets) {
                var $list = $('<ul>').appendTo($container);
                $.each(tickets, function (_, event) {
                    var $item = $('<li>').appendTo($list);
                    $('<a>').attr('href', event.url).text(event.title).appendTo($item);
                    $('<small>').addClass('ZTSMCalendarTicketDates')
                        .text(event.start.format('DD MMM YYYY HH:mm') + ' > ' + event.end.format('DD MMM YYYY HH:mm'))
                        .appendTo($item);
                    var $badges = $('<div>').addClass('ZTSMCalendarTicketCategories').appendTo($item);
                    $.each(event.categories || [], function (_, category) {
                        var label = category.text;
                        if (category.translate && Core.Language) { label = Core.Language.Translate(label); }
                        var $badge = $('<span>').addClass('ZTSMCalendarTicketCategory')
                            .text((category.prefix || '') + label).attr('title', category.name).appendTo($badges);
                        if (/^#[0-9a-f]{3}([0-9a-f]{3})?$/i.test(category.color)) {
                            var hex = category.color.slice(1);
                            if (hex.length === 3) { hex = hex.replace(/./g, function (c) { return c + c; }); }
                            var luminance = 0.2126 * parseInt(hex.slice(0, 2), 16)
                                + 0.7152 * parseInt(hex.slice(2, 4), 16) + 0.0722 * parseInt(hex.slice(4, 6), 16);
                            $badge.css({ backgroundColor: category.color, color: luminance > 150 ? '#000539' : '#fff' });
                        }
                    });
                });
            }
            $('<h3>').text('Tickets by master').appendTo($panel);
            $.each(Object.keys(groups).sort(function (a, b) { return groups[a].master.number.localeCompare(groups[b].master.number); }), function (_, key) {
                var group = groups[key], master = group.master;
                var $section = $('<details>').addClass('ZTSMCalendarGroup').prop('open', true).appendTo($panel);
                $('<summary>').text('Master ' + master.number + ' (' + group.tickets.length + ')').appendTo($section);
                if (master.url) { $('<a>').addClass('ZTSMCalendarMasterLink').attr('href', master.url)
                    .text(master.title || master.number).appendTo($section); }
                addList($section, group.tickets);
            });
            if (other.length) {
                var $other = $('<details>').addClass('ZTSMCalendarGroup').prop('open', true).appendTo($panel);
                $('<summary>').text('Other tickets (' + other.length + ')').appendTo($other);
                addList($other, other);
            }
            if (!events.length) { $('<p>').text('No tickets in this period.').appendTo($panel); }
        }
        $calendar.fullCalendar({
            header: { left: 'prev,next today', center: 'title', right: 'month,agendaWeek,agendaDay' },
            defaultView: 'month',
            height: 'auto',
            eventLimit: true,
            timezone: 'local',
            eventAfterAllRender: function (view) {
                // Use the selected interval, not the adjacent days in a month grid.
                // Rebuild after rendering, including navigation served from FullCalendar's cache.
                var events = $calendar.fullCalendar('clientEvents');
                renderGroups($.grep(events, function (event) {
                    return event.start && event.end
                        && event.start.valueOf() < view.intervalEnd.valueOf()
                        && event.end.valueOf() > view.intervalStart.valueOf();
                }));
            },
            events: function (start, end, timezone, callback) {
                var generation = ++requestGeneration;
                var url = Core.Config.Get('Baselink') + 'Action=CustomerTicketOverview;Subaction=MyTickets;Display=Calendar;CalendarEvents=1';
                var range = { Start: start.format('YYYY-MM-DD'), End: end.format('YYYY-MM-DD') };
                $('#ZTSMCustomerTicketCalendarError').prop('hidden', true);
                function failed(attempt) {
                    if (generation !== requestGeneration) { callback([]); return; }
                    if (attempt === 0) { fetch(1); return; }
                    $('#ZTSMCustomerTicketCalendarError').text('Calendar events could not be loaded.').prop('hidden', false);
                    renderGroups([]);
                    callback([]);
                }
                function fetch(attempt) {
                    $.getJSON(url, range).done(function (result) {
                        if (generation !== requestGeneration) { callback([]); return; }
                        if (!$.isArray(result)) { failed(attempt); return; }
                        $('#ZTSMCustomerTicketCalendarError').prop('hidden', true);
                        callback(result);
                    }).fail(function () { failed(attempt); });
                }
                fetch(0);
            }
        });
    }
    Core.Init.RegisterNamespace({ Init: init }, 'APP_MODULE');
}());
