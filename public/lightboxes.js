
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
            if (Object.isFunction(lightbox.beforeSubmit) &&
                !lightbox.beforeSubmit(box, e, doHide)) {
              return;
            }
            // doHide();
          });
        }
        
        var doHide = function(e) {
          e && e.stop();
          onEscape.stop();
          onSubmit && onSubmit.stop();
          box.hideLightbox();
        };

        box.down('.cancel').on('click', function(e) {
          Object.isFunction(lightbox.beforeCancel) && lightbox.beforeCancel(box);
          doHide(e);
        });
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

$(document).on('dom:loaded', function() {
  Lightboxes.setup();
});

