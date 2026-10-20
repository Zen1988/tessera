/* global Core, $ */
(function () {
    'use strict';
    function init() {
        var $calendar = $('#TESSERATicketCalendar');
        if (!$calendar.length || !$.fn.fullCalendar) { return; }
        $calendar.fullCalendar({
            header: { left: 'prev,next today', center: 'title', right: 'month,agendaWeek,agendaDay' },
            defaultView: 'month',
            height: 'auto',
            eventLimit: true,
            timezone: 'local',
            events: function (start, end, timezone, callback) {
                $.getJSON(Core.Config.Get('Baselink') + 'Action=AgentTESSERATicketCalendar;Subaction=Events', {
                    Start: start.format('YYYY-MM-DD'), End: end.format('YYYY-MM-DD')
                }).done(function (result) {
                    if (!$.isArray(result)) {
                        $('#TESSERATicketCalendarError').text('Calendar events could not be loaded.').prop('hidden', false);
                        callback([]);
                        return;
                    }
                    $('#TESSERATicketCalendarError').prop('hidden', true);
                    callback(result);
                }).fail(function () {
                    $('#TESSERATicketCalendarError').text('Calendar events could not be loaded.').prop('hidden', false);
                    callback([]);
                });
            }
        });
    }
    Core.Init.RegisterNamespace({ Init: init }, 'APP_MODULE');
}());
