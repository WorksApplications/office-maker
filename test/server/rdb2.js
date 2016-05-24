var mysql = require('mysql');

var connection = mysql.createConnection({
  host     : 'localhost',
  user     : 'root',
  password : '',
  database : 'map2'
});

connection.connect();

function exec(sql, cb) {
  connection.query(sql, (e, rows, fields) => {
    if(e) {
      cb(e);
    } else {
      (rows.length ? rows : []).forEach(function(row) {
        (fields || []).forEach(function(field) {
          if(field.type === 1) {
            row[field.name] = !!row[field.name];
          }
        });
      });
      var _res = rows.length || '';
      // console.log(`${sql.split('\n').join()} => ${_res}`);
      try {
        cb && cb(null, rows);
      } catch(e) {
        // console.trace();
        console.log(e);
      }

    }
  });
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
