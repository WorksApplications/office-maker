var AWS = require('aws-sdk');
var lambdaUtil = require('../common/lambda-util.js');
var db = require('../common/db.js');

exports.handler = (event, context, callback) => {
  // console.log(event.authorizationToken);
  var ip = (event.authorizationToken || '').split(',')[0].trim();
  if (!ip) {
    callback('Unauthorized');
    // callback(null, {
    //   // principalId: 'mock-tenant',
    //   policyDocument: {
    //     Version: '2012-10-17',
    //     Statement: [{
    //       Action: 'execute-api:Invoke',
    //       Effect: 'Deny',
    //       Resource: event.methodArn
    //     }]
    //   }
    // });
    return;
  }
  db.getTenant(ip).then(tenantId => {
    console.log(tenantId);
    var guestUser = {};
    callback(null, {
      principalId: 'mock-tenant',
      policyDocument: {
        Version: '2012-10-17',
        Statement: [{
          Action: 'execute-api:Invoke',
          Effect: 'Allow',
          Resource: event.methodArn
        }]
      },
      context: guestUser
    });
  }).catch(e => {
    callback('Unauthorized');
    // callback(null, {
    //   // principalId: 'mock-tenant',
    //   policyDocument: {
    //     Version: '2012-10-17',
    //     Statement: [{
    //       Action: 'execute-api:Invoke',
    //       Effect: 'Deny',
    //       Resource: event.methodArn
    //     }]
    //   }
    // });
  });
}
