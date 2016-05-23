var alasql = require('alasql');

function exec(sql, cb) {
  var err = null;
  try {
    var res = alasql(sql);

    var _res = res.length || res;
    console.log(`${sql} => ${_res}`);
    try {
      cb && cb(null, res);
    } catch(e) {
      err = e;
    }
  } catch(e) {
    console.log('Error on executing ' + sql);
    cb && cb(e);
  }
  if(err) {
    throw err;
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
