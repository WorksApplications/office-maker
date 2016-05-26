var mysql = require('mysql');

var pool = mysql.createPool({
  host     : 'localhost',
  user     : 'root',
  password : '',
  database : 'map2'
});

function exec(connection, sql, cb) {
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
      var _res = rows.length || rows.affectedRows || '';
      console.log(`${sql.split('\n').join()} => ${_res}`);
      try {
        cb && cb(null, rows);
      } catch(e) {
        console.trace();
        console.log('exec', e);
      }
    }
  });
}
function inTransaction(process, cb) {
  pool.getConnection(function(e, connection) {
    if(e) {
      cb(e);
    } else {
      connection.beginTransaction(function(e) {
        if(e) {
          cb(e);
        } else {
          try {
            process(connection, {
              success: function(cb) {
                var callbackArgs = arguments;
                connection.commit(function(e) {
                  if(e) {
                    // console.log(e);
                    connection.rollback(function() {
                      connection.release();
                      cb && cb(e);
                    });
                  } else {
                    connection.release();
                    cb && cb();
                  }
                });
              },
              fail: function(cb) {
                connection.rollback(function(e) {
                  cb && cb(e);
                });
              }
            });
          } catch(e) {
            // console.log(e);
            connection.rollback(function() {
              connection.release();
              cb(e);
            });
          }

        }
      });
    }
  });
}
function batch(conn, list, cb) {
  var list = list.concat();
  var head = list.shift();
  var tail = list;
  if(head) {
    exec(conn, head, function(e, result) {
      if(e) {
        cb && cb(e);
      } else {
        batch(conn, tail, function(e, results) {
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
  batch: batch,
  inTransaction: inTransaction
};
