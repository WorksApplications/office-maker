var alasql = require('alasql');

function exec(sql, cb) {
  try {
    var res = alasql(sql);
    console.log(`${sql} => ${res}`);
    cb && cb(null, res);
  } catch(e) {
    cb && cb(e);
  }
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
            cb && cb(null, results);
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
