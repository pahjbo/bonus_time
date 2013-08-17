var bonus_time = {};

(function($){

bonus_time.render_month = function(month_entries) {
  bonus_time.cal.fullCalendar('removeEvents');
  $('#calendar .fc-day').each(function() {
    var cls_to_remove = ['hours-0'];
    for (var j = 1; j <= 10; j++) cls_to_remove.push('hours-lte' + j);
    $(this).removeClass(cls_to_remove.join(' '));
    var d = $(this).data('date'),
        hours = 0,
        day_class = 'hours-0';

    if (month_entries[d]) {
      var hours = parseFloat(month_entries[d]);
      bonus_time.cal.fullCalendar('renderEvent', {title: '' + hours, start: d});

      if (hours > 10) {
        day_class = 'hours-lte10';
      } else {
        for (var j = 0; j <= 10; j++) {
          if (hours <= j) {
            day_class = 'hours-lte' + j;
            break;
          }
        }
      }
    }
    $(this).addClass(day_class);
  });
  $('.fc-day').droppable({
    scope: 'eventdate',
    over: function() {
      $(this).addClass('active');
    },
    out: function() {
      $(this).removeClass('active');
    },
    drop: function(e, ui) {
      var date = $(this).data('date');
      var entry_id = $(ui.draggable).data('entryid');
      $(this).removeClass('active');
      $.ajax('/timesheet/' + entry_id + '/move', {
        type: 'POST',
        data: bonus_time.filter_data({
          new_date: date,
          _method: 'PUT'
        })
      });
    }
  });
}

bonus_time.filter_change = function() {
  $('#filter-wrapper form input[name=date]').val(bonus_time.redmine_date(bonus_time.active_date));
  $('#filter-wrapper form').submit();
}

bonus_time.day_click = function(date, is_all_day, e, view) {
  bonus_time.active_date = date;
  $.ajax('/timesheet/day', {
    data: bonus_time.filter_data({date: bonus_time.redmine_date(date)})
  });
}

bonus_time.filter_data = function(http_data) {
  if ($('#filter_user').length) {
    http_data['filter[user]'] = $('#filter_user').val();
  }
  http_data['filter[project]'] = $('#filter_project').val();
  return $.param(http_data);
}

bonus_time.first = true;

bonus_time.view_change = function(view) {
  bonus_time.cal.fullCalendar('option', 'aspectRatio', view.name == 'month' ? 1.6 : 3.6);
  bonus_time.active_date = view.start;
  if (bonus_time.first) return bonus_time.first = false;
  $.ajax('/timesheet/' + (view.name == 'month' ? 'month' : 'week'), {
    data: bonus_time.filter_data({date: bonus_time.redmine_date(view.start)})
  });
}

bonus_time.redmine_date = function(date) {
  var month = '' + (date.getMonth() + 1);
  if (month.length == 1) month = '0' + month;
  return date.getFullYear() + '-' + month + '-' + date.getDate();
}

bonus_time.init_draggable = function() {
  $('.entry.draggable').draggable({
    scope: 'eventdate',
    scroll: true,
    revert: 'invalid',
    cursor: 'move',
    aspectRatio: 1.6,
    cursorAt: {left: 0, top: 0},
    zIndex: 9999,
    helper: function() {
      return '<div class="drop-helper">' + $(this).find('h5').html() + '</div>'
    }
  });
}

$(document).ready(function() {
  if ($('#calendar').length > 0) {
    bonus_time.cal = $('#calendar');
    bonus_time.cal.fullCalendar({
      header: {
        left: 'month basicWeek',
        center: 'title',
        right: 'today prev,next'
      },
      dayClick: bonus_time.day_click,
      viewDisplay: bonus_time.view_change,
    });
    bonus_time.active_date = bonus_time.cal.fullCalendar('getDate');
  }
  bonus_time.init_draggable();
});

$(document).on('click', '.expand-entries', function(e) {
  e.preventDefault();
  $('.' + $(this).data('project')).toggle();
});

$(document).on('click', 'button[type=reset]', function() {
  $.ajax('/timesheet/day', {
    data: bonus_time.filter_data({date: bonus_time.redmine_date(bonus_time.active_date)})
  });
});

$(document).on('click', '.fc-day', function() {
  $('.fc-day').removeClass('active');
  $(this).addClass('active');
});

$(document).on('change', '#filter-wrapper select', bonus_time.filter_change);

})(jQuery);