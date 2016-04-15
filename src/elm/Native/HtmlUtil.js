Elm.Native.HtmlUtil = {};

Elm.Native.HtmlUtil.make = function(localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.HtmlUtil = localRuntime.Native.HtmlUtil || {};
    if (localRuntime.Native.HtmlUtil.values) return localRuntime.Native.HtmlUtil.values;

    var Task = Elm.Native.Task.make(localRuntime);
    var Utils = Elm.Native.Utils.make(localRuntime);

    function focus(id) {
      return Task.asyncFunction(function(callback) {
        localRuntime.setTimeout(function() {
          var el = document.getElementById(id);
          if(el) {
            el.focus();
            return callback(Task.succeed(Utils.Tuple0));
          } else {
            return callback(Task.fail(Utils.Tuple0));
          }
        }, 100);
      });
    }
    function blur(id) {
      return Task.asyncFunction(function(callback) {
        localRuntime.setTimeout(function() {
          var el = document.getElementById(id);
          if(el) {
            el.blur();
            return callback(Task.succeed(Utils.Tuple0));
          } else {
            return callback(Task.fail(Utils.Tuple0));
          }
        }, 100);
      });
    }
    function readAsDataURL(file) {
      return Task.asyncFunction(function(callback) {
        var reader = new FileReader();
        reader.readAsDataURL(file._0[0]);
        reader.onload = function() {
          var dataUrl = reader.result;
          callback(Task.succeed(dataUrl));
        };
        reader.onerror = function() {
          callback(Task.succeed(""));//TODO
        };
      });
    }
    function getWidthAndHeightOfImage(dataUrl) {
      var image = new Image();
      image.src = dataUrl;
      return Utils.Tuple2(image.width, image.height);
    }

    return localRuntime.Native.HtmlUtil.values = {
        focus: focus,
        blur: blur,
        readAsDataURL : readAsDataURL,
        getWidthAndHeightOfImage: getWidthAndHeightOfImage
    };
};
