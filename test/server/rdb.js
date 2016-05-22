var alasql = require('alasql');

function exec(sql, cb) {
  console.log(sql);
  cb && cb();
}
function batch(list, cb) {
  var list = list.concat();
  var head = list.shift();
  var tail = list;
  if(head) {
    exec(head, function(e, result) {
      if(e) {
        cb && cb(e);
      } else {
        batch(tail, function(e, results) {
          if(e) {
            cb && cb(e);
          } else {
            results = results.concat();
            results.unshift(result);
            cb && cb(results);
          }
        });
      }
    });
  } else {
    cb && cb(null, []);
  }
}
module.exports = {
  exec: exec,
  batch: batch
};
