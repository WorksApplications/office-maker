var _user$project$Native_Emoji = function(localRuntime) {
  function splitText(s) {
    var node = document.createElement('div');
    node.textContent = s;
    twemoji.parse(node);
    var result = [];
    for (var i = 0; i < node.childNodes.length; i++) {
      var child = node.childNodes[i];
      if (child.tagName === 'IMG') {
        result.push({
          type: 'image',
          original: child.getAttribute('alt'),
          url: child.getAttribute('src')
        });
      } else {
        result.push({
          type: 'text',
          value: child.nodeValue
        });
      }
    }
    return _elm_lang$core$Native_List.fromArray(result);
  }
  return {
    splitText: splitText
  };
}();
