var jwt = require('jsonwebtoken');

var publicKey = process.env.PUBLIC_KEY.replace('_', '\n');

function getSelf(token) {
  if (!token) {
    return Promise.reject();
  }
  return new Promise((resolve, reject) => {
    jwt.verify(token, publicKey, {
      algorithms: ['RS256', 'RS384', 'RS512', 'HS256', 'HS256', 'HS512', 'ES256', 'ES384', 'ES512']
    }, function(e, user) {
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
  var token = (event.authorizationToken || '').split('Bearer ')[1];
  (token ? getSelf(token) : Promise.reject()).then(user => {
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
  }).catch(_ => {
    callback(null, {
      // principalId: 'mock-tenant',
      policyDocument: {
        Version: '2012-10-17',
        Statement: [{
          Action: 'execute-api:Invoke',
          Effect: 'Deny',
          Resource: event.methodArn
        }]
      }
    });
    // callback(message);
  });
}
