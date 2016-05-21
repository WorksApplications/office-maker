var alasql = require('alasql');

function init(cb) {
  cb && cb();
}

function exec(sql, cb) {
  console.log(sql);
  cb && cb();
}

module.exports = {
  init: init,
  exec: exec
};
