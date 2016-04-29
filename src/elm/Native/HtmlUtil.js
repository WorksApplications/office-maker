Elm.Native.HtmlUtil = {};

Elm.Native.HtmlUtil.make = function(localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.HtmlUtil = localRuntime.Native.HtmlUtil || {};
    if (localRuntime.Native.HtmlUtil.values) return localRuntime.Native.HtmlUtil.values;

    var Task = Elm.Native.Task.make(localRuntime);
    var Utils = Elm.Native.Utils.make(localRuntime);
    var Signal = Elm.Native.Signal.make(localRuntime);
    // var Maybe = Elm.Maybe.make(localRuntime);
    //
    // function getElementById(id) {
    //   return Task.asyncFunction(function(callback) {
    //     var el = document.getElementById(id);
    //     if(el) {
    //       callback(Task.succeed(Maybe.Just(el)));
    //     } else {
    //       callback(Task.succeed(Maybe.Nothing));
    //     }
    //   });
    // }

    function focus(id) {
      return Task.asyncFunction(function(callback) {
        var el = document.getElementById(id);
        if(el) {
          el.focus();
          return callback(Task.succeed(Utils.Tuple0));
        } else {
          return callback(Task.fail(Utils.Tuple0));
        }
      });
    }
    function blur(id) {
      return Task.asyncFunction(function(callback) {
        var el = document.getElementById(id);
        if(el) {
          el.blur();
          return callback(Task.succeed(Utils.Tuple0));
        } else {
          return callback(Task.fail(Utils.Tuple0));
        }
      });
    }


    var locationHash = Signal.input('locationHash', window.location.hash);
    window.addEventListener('hashchange', function() {
      var hash = window.location.hash;
      localRuntime.notify(locationHash.id, hash);
    });

    return localRuntime.Native.HtmlUtil.values = {
        focus: focus,
        blur: blur,
        locationHash: locationHash
    };
};
