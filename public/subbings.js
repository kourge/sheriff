
[
  { rel: 'log-in', box: 'login-lightbox' },

  {
    rel: 'sub-offer', box: 'sub-offer-lightbox',
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

      box.down('form').writeAttribute(
        'action', '/subbings/offers'
      ).injectValues({ day: date, object: data.mail });
      box.down('input.submit').enable();
    },

    beforeSubmit: function(box, e, doHide) {
      box.down('input.submit').disable();
      return true;
    },

    beforeCancel: function(box) {
      box.select('input[type=hidden]').invoke('remove');
    }
  },

  {
    rel: 'sub-req', box: 'sub-req-lightbox',
    beforeShow: function(box, link) {
      var date = link.readAttribute('data-day');
      box.find('p.date').update(new Date(date).strftime('%A, %B %d, %Y'));
      box.find('textarea').clear();
      
      box.down('form').injectValues({ day: date });
      box.down('input.submit').enable();
    },

    beforeSubmit: function(box, e, doHide) {
      box.down('input.submit').disable();
      return true;
    },

    beforeCancel: function(box) {
      box.select('input[type=hidden]').invoke('remove');
    }
  },

  {
    rel: 'sub-req-take', box: 'sub-req-take-lightbox',
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

      var id = link.readAttribute('data-id');
      box.down('form').writeAttribute('action', '/subbings/request/take/' + id);
      box.down('input.submit').enable();
    },

    beforeSubmit: function(box, e, doHide) {
      box.down('input.submit').disable();
      return true;
    },

    beforeCancel: function(box) {
      box.select('input[type=hidden]').invoke('remove');
    }
  },

  {
    rel: 'sub-offer-accept', box: 'sub-offer-accept-lightbox',
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

      var id = link.readAttribute('data-id');
      box.down('form').writeAttribute('action', '/subbings/offer/accept/' + id);
      box.down('input.submit').enable();
    },
    
    beforeSubmit: function(box, e, doHide) {
      box.down('input.submit').disable();
      return true;
    },

    beforeCancel: function(box) {
      box.select('input[type=hidden]').invoke('remove');
      box.down('form').writeAttribute('action', '#');
    }
  },

  {
    rel: 'sub-offer-decline', box: 'sub-offer-decline-lightbox',
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

      var id = link.readAttribute('data-id');
      box.down('form').writeAttribute('action', '/subbings/offer/decline/' + id);
      box.down('input.submit').enable();
    },
    
    beforeSubmit: function(box, e, doHide) {
      box.down('input.submit').disable();
      return true;
    },

    beforeCancel: function(box) {
      box.select('input[type=hidden]').invoke('remove');
      box.down('form').writeAttribute('action', '#');
    }
  }

  /*
  { rel: 'volunteer', box: 'volunteer-lightbox'  },
  { rel: 'back-out', box: 'backout-lightbox'  }
  */
].each(Lightboxes.add.bind(Lightboxes));

