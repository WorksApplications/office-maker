var _user$project$Native_HttpUtil = function(localRuntime) {
  function sendFile(method, url, headers, file) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      var xhr = new XMLHttpRequest();
      xhr.open(method, url, true);
      headers.forEach(function(header) {
        xhr.setRequestHeader(header[0], header[1]);
      });
      xhr.onload = function(e) {
        if (this.status == 200) {
          callback(_elm_lang$core$Native_Scheduler.succeed(_elm_lang$core$Native_Utils.Tuple0))
        } else {
          callback(_elm_lang$core$Native_Scheduler.fail("")) //TODO
        }
      };
      xhr.send(file);
    });
  }
  return {
    sendFile: F4(sendFile)
  };
}();
