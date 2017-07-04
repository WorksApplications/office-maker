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
      return Promise.reject('Unauthorized');
    } else {
      return Promise.reject(e.toString());
    }
  });
}

exports.handler = (event, context, callback) => {
  event.headers = event.headers || {};
  var token = (event.authorizationToken || '').split('JWT ')[1];
  if (!token) {
    callback('Unauthorized');
    return;
  };
  getSelf(token).then(user => {
    callback(null, {
      principalId: user.userId,
      policyDocument: {
        Version: '2012-10-17',
        Statement: [{
          Action: 'execute-api:Invoke',
          Effect: 'Allow',
          Resource: event.methodArn
        }]
      },
      context: user
    });
  }).catch(message => {
    callback(message);
  });
}
