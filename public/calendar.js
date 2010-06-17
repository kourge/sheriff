
Object.extend(Date.prototype, {
  strftime: function(format) {
    var day = this.getUTCDay(), month = this.getUTCMonth();
    var hours = this.getUTCHours(), minutes = this.getUTCMinutes();
    function pad(num) { return num.toPaddedString(2); };

    return format.gsub(/\%([aAbBcdDHiImMpSwyY])/, function(part) {
      switch(part[1]) {
        case 'a': return $w("Sun Mon Tue Wed Thu Fri Sat")[day]; break;
        case 'A': return $w("Sunday Monday Tuesday Wednesday Thursday Friday Saturday")[day]; break;
        case 'b': return $w("Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec")[month]; break;
        case 'B': return $w("January February March April May June July August September October November December")[month]; break;
        case 'c': return this.toString(); break;
        case 'd': return this.getUTCDate(); break;
        case 'D': return pad(this.getUTCDate()); break;
        case 'H': return pad(hours); break;
        case 'i': return (hours === 12 || hours === 0) ? 12 : (hours + 12) % 12; break;
        case 'I': return pad((hours === 12 || hours === 0) ? 12 : (hours + 12) % 12); break;
        case 'm': return pad(month + 1); break;
        case 'M': return pad(minutes); break;
        case 'p': return hours > 11 ? 'PM' : 'AM'; break;
        case 'S': return pad(this.getUTCSeconds()); break;
        case 'w': return day; break;
        case 'y': return pad(this.getUTCFullYear() % 100); break;
        case 'Y': return this.getUTCFullYear().toString(); break;
      }
    }.bind(this));
  }, 

  window: function window(before, after) {
    before = before == undefined ? 1 : before;
    after = after == undefined ? 3 : after;
    var day = 1000 * 60 * 60 * 24;
    var first = this.valueOf() - (7 * day * before);
    first -= (new Date(first)).getDay() * day;
    var last = this.valueOf() + (7 * day * after);
    last += (6 - (new Date(last)).getDay()) * day;
    return new ObjectRange(new Date(first), new Date(last));
  },
});

var Calendar = (function() {
  var week = 1000 * 60 * 60 * 24 * 7;
  var month = 1000 * 60 * 60 * 24 * 7 * 4;

  function previousWeek() {
    EXPORT.start -= week;
    EXPORT.end -= week;
  }

  function nextWeek() {
    EXPORT.start += week;
    EXPORT.end += week;
  }

  function previousMonth() {
    EXPORT.start -= month;
    EXPORT.end -= month;
  }

  function nextMonth() {
    EXPORT.start += month;
    EXPORT.end += month;
  }

  function resetToToday() {
    var today = (new Date()).window();
    EXPORT.start = today.start;
    EXPORT.end = today.end;
  }

  function updateDisplay() {
    new Ajax.Updater('calendar', '/', {
      method: 'get',
      parameters: {
        today: new Date(EXPORT.today).strftime('%Y-%m-%d'),
        from: new Date(EXPORT.start).strftime('%Y-%m-%d'),
        to: new Date(EXPORT.end).strftime('%Y-%m-%d')
      },
      onComplete: function() {
        Object.isFunction(Lightboxes.setup) && Lightboxes.setup();
      }
    });
  }

  function updateNavMenu(monthRange) {
    $$('#calendar-nav option.month').each(function(opt) {
      if (monthRange.include(new Month(opt.readAttribute('data-month')))) {
        opt.addClassName('current');
      } else {
        opt.removeClassName('current');
      }
    });
  }

  var EXPORT = {
    today: null,
    start: null,
    end: null,

    previousWeek: previousWeek,
    nextWeek: nextWeek,
    resetToToday: resetToToday,
    previousMonth: previousMonth,
    nextMonth: nextMonth,

    updateDisplay: updateDisplay,
    updateNavMenu: updateNavMenu
  };

  return EXPORT;
})();

var Month = (function() {
  function initialize() {
    this.value = 0;
    var args = arguments;
    if (typeof args[0] == 'number' && typeof args[1] == 'undefined') {
      this.value = args[0];
      return;
    } else if (typeof args[0] == 'object') {
      var year = args[0].getFullYear(), month = args[0].getMonth() + 1;
    } else if (typeof args[0] == 'string') {
      var parts = args[0].split('-');
      var year = parseInt(parts[0], 10), month = parseInt(parts[1], 10);
    } else if (typeof args[0] == 'number' && typeof args[1] == 'number') {
      var year = args[0], month = args[1];
    } else {
      throw new TypeError();
    }
    month--;
    this.value = year * 12 + month;
  }

  function valueOf() { return this.value; }
  function succ() { return new Month(this.value + 1); }
  function getFullYear() { return Math.floor(this.value / 12); }
  function getMonth() { return this.value % 12; }
  function toString() {
    return this.getFullYear() + '-' + this.getMonth().succ().toPaddedString(2);
  }

  return Class.create({
    initialize: initialize,
    valueOf: valueOf,
    succ: succ,
    getFullYear: getFullYear,
    getMonth: getMonth,
    toString: toString
  });
})();

$(document).on('dom:loaded', function() {
  $w('previous-month previous-week reset-to-today next-month next-week').each(function(id) {
    $(id).on('click', function(event) {
      event.stop();
      Calendar[id.camelize()](); Calendar.updateDisplay();
    });
  });

  var nav;
  if (nav = $('calendar-nav')) {
    var options = nav.select('option.month');
    options.each(function(option) {
      var month = option.readAttribute('data-month');
      var dateWindow = new Date(month + '-02').window();
      var newWindow = $R(new Month(dateWindow.start), new Month(dateWindow.end));
      option.on('click', function() {
        nav.select('option.current').invoke('removeClassName', 'current');
        Calendar.start = dateWindow.start.valueOf();
        Calendar.end = dateWindow.end.valueOf();
        Calendar.updateDisplay();
        Calendar.updateNavMenu(newWindow);
      });
    });
  }
});

