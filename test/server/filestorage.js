var fs = require('fs-extra');

var publicDir = __dirname + '/public';

function save(path, cb) {
  fs.writeFile(publicDir + '/' + path, image, cb);
}
function empty(dir, cb) {
  fs.emptyDir(publicDir + '/' + dir, cb);
}

module.exports = {
  save: save,
  empty: empty,
  publicDir: publicDir
};
