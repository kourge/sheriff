
[
  { rel: 'log-in', box: 'login-lightbox' },

  {
    rel: 'swap-offer', box: 'swapoffer-lightbox',
    beforeShow: function(box, link) {
      var date = link.readAttribute('data-day');
      var data = {
        nick: link.readAttribute('data-nick'),
        mail: link.readAttribute('data-mail')
      };
      box.find('p.date').update(new Date(date).strftime('%A, %B %d, %Y'));
      box.find('a.sheriff').update(
        '#{nick} <em>(#{mail})</em>'.interpolate(data)
      );
      box.find('textarea').clear();

      box.down('form').injectValues({ day: date, object: data.mail });
    },

    beforeSubmit: function(box, e, doHide) {
      e.stop();
      var form = box.down('form');
      console.log(form.serialize());
      return false;
    },

    beforeCancel: function(box) {
      box.select('input[type=hidden]').invoke('remove');
    }
  },

  {
    rel: 'swap-req', box: 'swapreq-lightbox',
    beforeShow: function(box, link) {
      var date = link.readAttribute('data-day');
      box.find('p.date').update(new Date(date).strftime('%A, %B %d, %Y'));
      box.find('textarea').clear();
      
      box.down('form').injectValues({ day: date });
    },

    beforeSubmit: function(box, e, doHide) {
      e.stop();
      var form = box.down('form');
      console.log(form.serialize());
      return false;
    },

    beforeCancel: function(box) {
      box.select('input[type=hidden]').invoke('remove');
    }
  }
  /*
  { rel: 'volunteer', box: 'volunteer-lightbox'  },
  { rel: 'back-out', box: 'backout-lightbox'  }
  */
].each(Lightboxes.add.bind(Lightboxes));

