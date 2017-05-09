var _user$project$Native_File = function(localRuntime) {

  function readAsDataURL(file) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function(callback) {
      var reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = function() {
        var dataUrl = reader.result;
        callback(_elm_lang$core$Native_Scheduler.succeed(dataUrl));
      };
      reader.onerror = function() {
        callback(_elm_lang$core$Native_Scheduler.succeed("")); //TODO
      };
    });
  }

  function getSizeOfImage(dataUrl) {
    var image = new Image();
    image.src = dataUrl;
    return _elm_lang$core$Native_Utils.Tuple2(image.width, image.height);
  }

  function length(fileList) {
    return fileList.length;
  }

  function getAt(i, fileList) {
    return fileList[i];
  }
  return {
    readAsDataURL: readAsDataURL,
    getSizeOfImage: getSizeOfImage,
    length: length,
    getAt: F2(getAt)
  };
}();
