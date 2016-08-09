var mysql = require('mysql');

var pool = mysql.createPool({
  host     : 'localhost',
  user     : 'root',
  password : '',
  database : 'map2'
});

function exec(conn, sql, cb) {
  // console.log(sql);
  conn.query(sql, (e, rows, fields) => {
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
      // try {
        cb && cb(null, rows);
      // } catch(e) {
      //   // console.trace();
      //   console.log('db2.exec', e);
      // }
    }
  });
}
function forConnection(onGetConnection) {
  pool.getConnection(function(e, conn) {
    if(e) {
      onGetConnection(e);
    } else {
      try {
        // console.log('getConnection');
        onGetConnection(null, conn, function done(onClose) {
          try {
            // console.log('release 1');
            conn.release();
          } catch(e) {
            console.log('rdb2.forConnection1', e);
          }
          onClose && onClose();
        });
      } catch(e) {
        console.log('rdb2.forConnection2', e);
        try {
          // console.log('release 2');
          conn.release();
        } catch(e) {
          console.log('rdb2.forConnection3', e);
        }
      }
    }
  });
}
function forTransaction(conn, onBeginTransaction) {
  conn.beginTransaction(function(e) {
    if(e) {
      onBeginTransaction(e);
    } else {
      try {
        onBeginTransaction(null, function commit(e, onFinishCommit) {
          if(e) {
            conn.rollback(function(e) {
              onFinishCommit && onFinishCommit(e);
            });
          } else {
            var callbackArgs = arguments;
            conn.commit(function(e) {
              if(e) {
                // console.log(e);
                conn.rollback(function() {
                  onFinishCommit && onFinishCommit(e);
                });
              } else {
                onFinishCommit && onFinishCommit();
              }
            });
          }
        });
      } catch(e) {
        conn.rollback(function() {
          onBeginTransaction(e);
        });
      }
    }
  });
}

// maybe logic is incorrect
function forConnectionAndTransaction(f) {
  forConnection(function(e, conn, connectionDone) {
    if(e) {
      f(e);
    } else {
      forTransaction(conn, function(e, commit) {
        if(e) {
          f(e);
        } else {
          // console.log('f');
          f(null, conn, function(e, onFinishClose) {
            // console.log('commit');
            commit(e, function onFinishCommit(e) {
              // console.log('committed');
              connectionDone(function onClose() {
                // console.log('closed');
                onFinishClose();
              });
            });
          });
        }
      });
    }
  });
}
function batch(conn, list, cb) {
  if(!conn) {
    console.log('connection does not exist');
    // console.trace();
    throw 'connection does not exist';
  }
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
  forConnection: forConnection,
  forTransaction: forTransaction,
  forConnectionAndTransaction: forConnectionAndTransaction
};
