var _user$project$Native_Emoji = function(localRuntime) {
  var impl = {
    render: function(model) {
      var node = document.createElement('span');
      node.textContent = model;
      twemoji.parse(node);
      return node;
    },
    diff: function(a, b) {
      if(a.model !== b.model) {
        return {
          data: b.model,
          applyPatch: function (domNode, data) {
            domNode.textContent = data;
            twemoji.parse(domNode);
            return domNode;
          }
        }
      }
      return null;
    }
  };
  function view(factList, text) {
    return _elm_lang$virtual_dom$Native_VirtualDom.custom(factList, text, impl);
  }
  return {
    view: F2(view)
  };
}();
