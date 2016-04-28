Elm.Native.HttpUtil = {};

Elm.Native.HttpUtil.make = function(localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.HttpUtil = localRuntime.Native.HttpUtil || {};
    if (localRuntime.Native.HttpUtil.values) return localRuntime.Native.HttpUtil.values;

    var Task = Elm.Native.Task.make(localRuntime);
    var Utils = Elm.Native.Utils.make(localRuntime);

    function sendFile(method, url, file) {
      return Task.asyncFunction(function(callback) {
        var xhr = new XMLHttpRequest();
        xhr.open(method, url, true);
        xhr.onload = function(e) {
          if (this.status == 200) {
            callback(Task.succeed(Utils.tuple0))
          } else {
            callback(Task.fail("")) //TODO
          }
        };
        xhr.send(file);
      });
    }
    return localRuntime.Native.HttpUtil.values = {
        sendFile: F3(sendFile)
    };
};
