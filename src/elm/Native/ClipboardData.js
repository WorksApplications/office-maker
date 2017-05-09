var _user$project$Native_ClipboardData = function(localRuntime) {
  function getHtml(clipboardData) {
    return clipboardData.getData('text/html');
  }

  function getText(clipboardData) {
    return clipboardData.getData('text');
  }

  function execCopy(s) {
    var textArea = document.createElement("textarea");
    textArea.value = s;
    document.body.appendChild(textArea);
    textArea.select();
    var result = document.execCommand("copy");
    document.body.removeChild(textArea);
  };
  return {
    execCopy: execCopy,
    getHtml: getHtml,
    getText: getText
  };
}();


// var items = clipboardData.items;
// for (var i = 0 ; i < items.length ; i++) {
//   var item = items[i];
// 	console.log(item.type);
//   if (item.type.indexOf("image") != -1) {
//     var file = item.getAsFile();
//     console.log(file);
//   }
// }
// console.log(clipboardData.types);
// console.log(clipboardData.files[0]);
// console.log(clipboardData.items[0]);
// console.log(clipboardData.getData('text'));
// console.log(clipboardData.getData('text/html'));
// console.log(clipboardData.getData('text/rtf'));
// console.log(clipboardData.getData('text/plain'));
// console.log(clipboardData.getData('Files'));
// console.log(clipboardData.getData('image/png'));
