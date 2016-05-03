var _user$project$Native_HtmlUtil = function(localRuntime) {
    function focus(id) {
      return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
        var el = document.getElementById(id);
        if(el) {
          el.focus();
          return callback(_elm_lang$core$Native_Scheduler.succeed(_elm_lang$core$Native_Utils.Tuple0));
        } else {
          return callback(_elm_lang$core$Native_Scheduler.fail(_elm_lang$core$Native_Utils.Tuple0));
        }
      });
    }
    function blur(id) {
      return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
        var el = document.getElementById(id);
        if(el) {
          el.blur();
          return callback(_elm_lang$core$Native_Scheduler.succeed(_elm_lang$core$Native_Utils.Tuple0));
        } else {
          return callback(_elm_lang$core$Native_Scheduler.fail(_elm_lang$core$Native_Utils.Tuple0));
        }
      });
    }

    return {
        focus: focus,
        blur: blur
    };
}();
