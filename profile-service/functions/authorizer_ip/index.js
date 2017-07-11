var AWS = require('aws-sdk');
var documentClient = new AWS.DynamoDB.DocumentClient();

exports.handler = (event, context, callback) => {
  var ip = (event.authorizationToken || '').split(',')[0].trim();
  if (!ip) {
    callback('Unauthorized');
    return;
  }
  documentClient.get({
    TableName: "profiles_tenant_ip",
    Key: {
      ipAddress: ip
    }
  }, function(e, data) {
    if (e) {
      callback(e);
      return;
    }
    var guestUser = data.Item;
    if (!guestUser) {
      callback('Unauthorized');
      return;
    }

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
  });

}
