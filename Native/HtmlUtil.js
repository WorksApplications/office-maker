Elm.Native.HtmlUtil = {};

Elm.Native.HtmlUtil.make = function(localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.HtmlUtil = localRuntime.Native.HtmlUtil || {};
    if (localRuntime.Native.HtmlUtil.values) return localRuntime.Native.HtmlUtil.values;

    /* ここに実装を書く */
    var Task = Elm.Native.Task.make(localRuntime);
    var Utils = Elm.Native.Utils.make(localRuntime);
    var Signal = Elm.Native.Signal.make(localRuntime);

    function focus(id) {
      return Task.asyncFunction(function(callback) {
        localRuntime.setTimeout(function() {
          console.log('focus')
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
          console.log('blur')
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

    function keyStream(node, eventName) {
  		var stream = Signal.input(eventName, { alt: false, meta: false, keyCode: 0 });
  		localRuntime.addListener([stream.id], node, eventName, function(e) {
  			localRuntime.notify(stream.id, e);
  		});
  		return stream;
  	}
    var downs = keyStream(document, 'keydown');

    return localRuntime.Native.HtmlUtil.values = {
        focus: focus,
        blur: blur,
        downs: downs,
    };
};
