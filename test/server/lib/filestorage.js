var fs = require('fs-extra');

var publicDir = __dirname + '/../public';

function save(path, image) {
  return new Promise((resolve, reject) => {
    fs.writeFile(publicDir + '/' + path, image, (e) => {
      if(e) {
        reject(e);
      } else {
        resolve();
      }
    });
  });
}

function empty(dir) {
  return new Promise((resolve, reject) => {
    fs.emptyDir(publicDir + '/' + dir, (e) => {
      if(e) {
        reject(e);
      } else {
        resolve();
      }
    });
  });
}

module.exports = {
  save: save,
  empty: empty,
  publicDir: publicDir
};
