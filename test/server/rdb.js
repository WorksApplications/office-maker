var mysql = require('mysql');


function exec(conn, sql, cb) {
  return new Promise((resolve, reject) => {
    conn.query(sql, (e, rows, fields) => {
      if(e) {
        reject(e);
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
        resolve(rows);
      }
    });
  });
}

function batch(conn, list) {
  var promises = list.map((sql) => {
    return exec(conn, sql);
  });
  return promises.reduce(function(promise, next) {
    return promise.then((result) => next);
  }, Promise.resolve());
}

function createEnv(host, user, pass, dbname) {

  var pool = mysql.createPool({
    host     : host,
    user     : user,
    password : pass,
    database : dbname
  });

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
              console.log('rdb.forConnection1', e);
            }
            onClose && onClose();
          });
        } catch(e) {
          console.log('rdb.forConnection2', e);
          try {
            // console.log('release 2');
            conn.release();
          } catch(e) {
            console.log('rdb.forConnection3', e);
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

  return {
    forConnection: forConnection,
    forTransaction: forTransaction,
    forConnectionAndTransaction: forConnectionAndTransaction
  };
}


module.exports = {
  createEnv: createEnv,
  exec: exec,
  batch: batch
};
