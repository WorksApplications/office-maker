Elm.Native.HttpUtil = {};

Elm.Native.HttpUtil.make = function(localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.HttpUtil = localRuntime.Native.HttpUtil || {};
    if (localRuntime.Native.HttpUtil.values) return localRuntime.Native.HttpUtil.values;

    var Task = Elm.Native.Task.make(localRuntime);
    var Utils = Elm.Native.Utils.make(localRuntime);

    function putFile(url, filelist) {
      console.log('putFile', url, filelist)
      return Task.asyncFunction(function(callback) {
        var xhr = new XMLHttpRequest();
        xhr.open('PUT', url, true);
        var formData = new FormData();
        formData.append("uploads", filelist[0]);
        xhr.onload = function(e) {
          if (this.status == 200) {
            callback(Task.succeed(Utils.tuple0))
          } else {
            callback(Task.fail("")) //TODO
          }
        };
        xhr.send(filelist[0]);
      });
    }
    return localRuntime.Native.HttpUtil.values = {
        putFile: F2(putFile)
    };
};
