
Element.addMethods('form', {
  injectValues: function injectValues(form, hash) {
    form = $(form);
    $H(hash).each(function(pair) {
      var k = pair[0], v = pair[1];
      form.insert(new Element('input', { type: 'hidden', name: k, value: v }));
    });
  }
});

Element.addMethods({
  insertTo: function insertTo(element, target) {
    if (!(element = $(element))) return;
    if (!(target = $(target))) return;
    target.insert(element);
  },

  find: function find(element, expr) {
    if (!(element = $(element))) return;
    return element.select(expr)[0];
  }
});

// Let some jQuery methods bleed through.
(function(names) {
  var methods = {};
  $w(names).each(function(m) {
    methods[m] = function() {
      arguments = $A(arguments);
      var element = arguments.shift(), wrapped = jQuery(element);
      return wrapped[m].apply(wrapped, arguments);
    };
  });
  Element.addMethods(methods);
})('slideDown slideToggle slideUp fadeIn fadeOut fadeTo animate dequeue queue stop');

$(document).on('keypress', function(event) {
  if (event.keyCode == 27) {
    this.fire('keypressed:esc');
  }
});

$(document).on('dom:loaded', function() {
  // Attach close links to flash messages.
  $$("div.flash").each(function(flash) {
    new Element('div', {'class': 'flash-close'}).on('click', function() {
      this.up().fadeOut();
      event.stop();
    }).update('<a href="#">&times;</a>').insertTo(this);
  });
});

