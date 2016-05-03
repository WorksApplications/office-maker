var _user$project$Native_HttpUtil = function(localRuntime) {
    function sendFile(method, url, file) {
      return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
        var xhr = new XMLHttpRequest();
        xhr.open(method, url, true);
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
    var reload = _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      location.reload();
      callback(_elm_lang$core$Native_Scheduler.succeed(_elm_lang$core$Native_Utils.Tuple0));
    });
    function goTo(url) {
      return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
        location.href = url;
        callback(_elm_lang$core$Native_Scheduler.succeed(_elm_lang$core$Native_Utils.Tuple0));
      });
    }
    return {
        sendFile: F3(sendFile),
        reload: reload,
        goTo: goTo
    };
}();
