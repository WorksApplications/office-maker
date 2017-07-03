var jwt = require('jsonwebtoken');

function getSelf(token) {
  if (!token) {
    return Promise.reject();
  }
  return new Promise((resolve, reject) => {
    jwt.verify(token, 'mock-key', function(e, user) {
      if (e) {
        reject(e);
      } else {
        resolve(user);
      }
    });
  }).catch(e => {
    if (e.name === 'JsonWebTokenError') {
      return Promise.reject(401);
    } else {
      return Promise.reject(e);
    }
  });
}

function authorized(f) {
  return (event, context, callback) => {
    event.headers = event.headers || {};
    var token = (event.headers['Authorization'] || '').split('JWT ')[1];
    if (!token) {
      callback(null, {
        statusCode: 401,
        headers: {
          "Content-Type": "application/json"
        },
        body: ''
      });
      return;
    };
    getSelf(token).then(user => {
      f(event, context, user, callback);
    }).catch(e => {
      if (typeof e === 'number') {
        callback(null, {
          statusCode: e,
          headers: {
            "Content-Type": "application/json"
          },
          body: ''
        });
        return;
      }
      callback(null, {
        statusCode: 500,
        headers: {
          "Content-Type": "application/json"
        },
        body: e ? e.toString() : ''
      });
    });
  };
}

module.exports = {
  getSelf: getSelf,
  authorized: authorized
};
