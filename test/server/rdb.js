var alasql = require('alasql');
var fs = require('fs');

console.log('You are using dummuy DB.');

function exec(sql, cb) {
  var err = null;
  try {
    var res = alasql(sql);

    var _res = res.length || res;
    console.log(`${sql.split('\n').join()} => ${_res}`);
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
    exec(head, (e, result) => {
      if(e) {
        cb && cb(e);
      } else {
        batch(tail, (e, results) => {
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
batch(fs.readFileSync(__dirname + '/sql/1.sql', 'utf8').split('\r').join('').split('\n\n'), function(e) {
  if(e) {
    throw e;
  }
});
module.exports = {
  exec: exec,
  batch: batch
};
