Elm.Native.File = {};

Elm.Native.File.make = function(localRuntime) {
    localRuntime.Native = localRuntime.Native || {};
    localRuntime.Native.File = localRuntime.Native.File || {};
    if (localRuntime.Native.File.values) return localRuntime.Native.File.values;

    var Task = Elm.Native.Task.make(localRuntime);
    var Utils = Elm.Native.Utils.make(localRuntime);

    function readAsDataURL(file) {
      return Task.asyncFunction(function(callback) {
        var reader = new FileReader();
        reader.readAsDataURL(file);
        reader.onload = function() {
          var dataUrl = reader.result;
          callback(Task.succeed(dataUrl));
        };
        reader.onerror = function() {
          callback(Task.succeed(""));//TODO
        };
      });
    }
    function getSizeOfImage(dataUrl) {
      var image = new Image();
      image.src = dataUrl;
      return Utils.Tuple2(image.width, image.height);
    }
    function length(fileList) {
      return fileList.length;
    }
    function getAt(i, fileList) {
      return fileList[i];
    }
    return localRuntime.Native.File.values = {
        readAsDataURL: readAsDataURL,
        getSizeOfImage: getSizeOfImage,
        length: length,
        getAt: F2(getAt)
    };
};
