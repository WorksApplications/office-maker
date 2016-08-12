var mysql = require('mysql');

function exec(conn, sql, cb) {
  return new Promise((resolve, reject) => {
    conn.query(sql, (e, rows, fields) => {
      if(e) {
        reject(e);
      } else {
        (rows.length ? rows : []).forEach((row) => {
          (fields || []).forEach((field) => {
            if(field.type === 1) {
              row[field.name] = !!row[field.name];
            }
          });
        });
        var _res = rows.length || rows.affectedRows || '';
        // console.log(`${sql.split('\n').join()} => ${_res}`);
        resolve(rows);
      }
    });
  });
}

function batch(conn, list) {
  var promises = list.map((sql) => {
    return exec(conn, sql);
  });
  return promises.reduce((promise, next) => {
    return promise.then((result) => next);
  }, Promise.resolve());
}

function beginTransaction(conn) {
  return new Promise((resolve, reject) => {
    conn.beginTransaction((e) => {
      if(e) {
        reject(e);
      } else {
        resolve();
      }
    });
  });
}

function getConnection(pool) {
  return new Promise((resolve, reject) => {
    pool.getConnection((e, conn) => {
      if(e) {
        reject(e);
      } else {
        resolve(conn);
      }
    });
  });
}

function commit(conn) {
  return new Promise((resolve, reject) => {
    conn.commit((e) => {
      if(e) {
        reject(e);
      } else {
        resolve();
      }
    });
  });
}

function rollback(conn) {
  return new Promise((resolve, reject) => {
    conn.rollback((e) => {
      if(e) {
        reject(e);
      } else {
        resolve();
      }
    });
  });
}

function forTransaction(conn, f) {
  return beginTransaction(conn).then(() => {
    return f(conn).then((data) => {
      return commit(conn).then(() => {
        return Promise.resolve(data);
      });
    }).catch((e) => {
      return rollback(conn).catch((e2) => {
        return Promise.reject([e, e2]);
      }).then(() => {
        return Promise.reject(e);
      });
    });
  });
}

function createEnv(host, user, pass, dbname) {

  var pool = mysql.createPool({
    host     : host,
    user     : user,
    password : pass,
    database : dbname
  });

  function forConnection(f) {
    return getConnection(pool).then((conn) => {
      return f(conn).then((data) => {
        conn.release();
        return Promise.resolve(data);
      }).catch((e) => {
        conn.release();
        return Promise.reject(e);
      });
    });
  }

  // maybe logic is incorrect
  function forConnectionAndTransaction(f) {
    return forConnection((conn) => {
      return forTransaction(conn, f);
    });
  }

  return {
    forConnection: forConnection,
    forConnectionAndTransaction: forConnectionAndTransaction
  };
}

module.exports = {
  createEnv: createEnv,
  exec: exec,
  batch: batch,
  forTransaction: forTransaction
};
