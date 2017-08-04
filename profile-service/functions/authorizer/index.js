var jwt = require('jsonwebtoken');
var fs = require('fs');
var publicKey = process.env.PUBLIC_KEY || fs.readFileSync(__dirname + '/pubkey.pem', 'utf8');
var sourceIp = require('./sourceIp.js');

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
  console.log(event, context);
  event.headers = event.headers || {};
  var token = (event.authorizationToken || '').split('Bearer ')[1];
  (token ? getSelf(token) : Promise.reject()).then(user => {
    console.log(user);
    if (user.role === 'ADMIN') {
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
    } else if (user.role === 'GENERAL') {
      console.log(event.methodArn, event.methodArn
        .replace('/POST/', '/GET/')
        .replace('/PUT/', '/GET/')
        .replace('/PATCH/', '/GET/')
        .replace('/DELETE/', '/GET/'))
      callback(null, {
        principalId: user.userId,
        policyDocument: {
          Version: '2012-10-17',
          Statement: [{
            Action: 'execute-api:Invoke',
            Effect: 'Allow',
            Resource: event.methodArn
              .replace('/POST/', '/GET/')
              .replace('/PUT/', '/GET/')
              .replace('/PATCH/', '/GET/')
              .replace('/DELETE/', '/GET/')
          }]
        },
        context: user
      });
    } else {
      return Promise.reject();
    }
  }).catch(_ => {
    callback('Unauthorized');
  });
}
