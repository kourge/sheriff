
var ElementDatasetHash = (function() {
  var element = null;
  var NotImplementedError = Class.create(Error, {});

  function initialize(elem) {
    if (!Object.isElement(elem)) {
      throw new TypeError();
    }
    element = elem;
  }

  function get(key) { return element.readAttribute("data-" + key); }
  function set(key, value) { element.writeAttribute("data-" + key, value); }
  function unset(key) { element.removeAttribute("data-" + key); }
  function include(key) { element.hasAttribute("data-" + key); }

  var EXPORT = {
    initialize: initialize,
    get: get,
    set: set,
    unset: unset,
    include: include
  };
  console.log(EXPORT);

  $w('each index keys merge update values toJSON').each(function(method) {
    EXPORT[method] = function() { throw new NotImplementedError(); };
  });
  console.log(EXPORT);

  return Class.create(EXPORT);
})();

Element.addMethods({
  getDataset: function getDataset(element) {
    if (!(element = $(element))) {
      return undefined;
    }
    return new ElementDatasetHash(element);
  }
});
