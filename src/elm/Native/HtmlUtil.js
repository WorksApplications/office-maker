var _user$project$Native_HtmlUtil = function(localRuntime) {
  var canvas = document.createElement('canvas');
  var context = canvas.getContext('2d');

  function measureText(fontFamily, fontSize, s) {
    context.font = fontSize + "px '" + fontFamily + "'";
    var metrics = context.measureText(s);
    return metrics.width;
  }
  return {
    measureText: F3(measureText)
  };
}();
