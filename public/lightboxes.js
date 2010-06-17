
Element.addMethods({
  showLightbox: function showLightbox(element) {
    if (!(element = $(element))) return;
    return element.setStyle({opacity: 0}).addClassName('visible').fadeTo(500, 1);
  },

  hideLightbox: function hideLightbox(element) {
    if (!(element = $(element))) return;
    return element.fadeTo(500, 0, function() {
      this.removeClassName('visible');
    });
  }
});

var Lightboxes = {
  lightboxes: [],

  /*
    When adding a lightbox, pass an object with the following keys and values:
    - box, a string that is the id of the lightbox element
    - rel, which specifies which links trigger this lightbox
    - beforeShow, an optional callback that performs tasks before showing the 
        lightbox. Examples include populating some form in the lightbox with 
        meaningful data.
    - beforeSubmit, an optional callback that performs tasks before hiding the 
        lightbox. Submitting form data is this function's responsibility. If 
        this function returns a falsy value, the task performed is assumed to 
        have failed and the lightbox is not hidden.
  */
  add: function add(lightbox) {
    this.lightboxes.push(lightbox);
  },

  setup: function setup() {
    this.lightboxes.each(function(lightbox) {
      var box = $(lightbox.box);
      var links = $$('a[rel=' + lightbox.rel + ']');
      links.reject(function(link) {
        return link.retrieve('lightboxEnabled');
      }).invoke('on', 'click', 'a[rel]', function(event, link) {
        event.stop();
        var onEscape = $(document).on('keypressed:esc', function(e) {
          doHide();
        });
        
        var onSubmit = null;
        if (lightbox.rel != 'log-in') {
          onSubmit = box.down('form').on('submit', function(e) {
            e.stop();
            if (Object.isFunction(lightbox.beforeSubmit)) {
              if (!lightbox.beforeSubmit(box)) {
                return;
              }
            }
            doHide();
          });
        }
        
        var doHide = function() {
          onEscape.stop();
          onSubmit && onSubmit.stop();
          box.hideLightbox();
        };

        box.down('.cancel').on('click', doHide);
        Object.isFunction(lightbox.beforeShow) && lightbox.beforeShow(box, link);
        box.showLightbox();
        box.down('input:first').focus();
      });
      links.invoke('store', 'lightboxEnabled', true);

      $(document).on('keypressed:esc', function() {
        box.hideLightbox();
      });
    });
  }
};

[
  { rel: 'log-in', box: 'login-lightbox' },

  {
    rel: 'swap-offer', box: 'swapoffer-lightbox',
    beforeShow: function(box, link) {
      var parent = link.up('td');
      var date = parent.find('[data-day]').readAttribute('data-day');
      var sheriff = parent.find('.sheriff');
      var data = {
        nick: sheriff.readAttribute('data-nick'),
        mail: sheriff.readAttribute('data-mail')
      };
      box.find('p.date').update(new Date(date).strftime('%A, %B %d, %Y'));
      box.find('a.sheriff').update(
        '#{nick} <em>(#{mail})</em>'.interpolate(data)
      );
      box.find('textarea').clear();

      box.down('form').injectValues({ day: date, object: data.mail });
    },

    beforeSubmit: function(box) {
      var form = box.down('form');
      console.log(form.serialize());
      return false;
    }
  },

  {
    rel: 'swap-req', box: 'swapreq-lightbox',
    beforeShow: function(box, link) {
      console.log(this, box, link);
    },

    beforeSubmit: function(box) {
      console.log(box);
      return true;
    }
  }
  /*
  { rel: 'volunteer', box: 'volunteer-lightbox'  },
  { rel: 'back-out', box: 'backout-lightbox'  }
  */
].each(Lightboxes.add.bind(Lightboxes));

$(document).on('dom:loaded', function() {
  Lightboxes.setup();
});

