var AWS = require('aws-sdk');
var crypto = require('crypto');
var documentClient = new AWS.DynamoDB.DocumentClient();

exports.handler = (event, context, callback) => {
  var body = JSON.parse(event.body);
  var userId = body.userId;
  var salt = crypto.createHash('sha512').update(userId).digest('hex');
  var hash = crypto.createHash('sha512').update(body.password + salt).digest('hex');

  documentClient.put({
    TableName: "accounts",
    Item: {
      userId: userId,
      hashedPassword: hash,
      role: body.role
    }
  }, function(e, data) {
    if (e) {
      callback(e);
      return;
    }
    callback(null, {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        "Access-Control-Allow-Origin": "*"
      },
      body: ''
    });
  });
};
