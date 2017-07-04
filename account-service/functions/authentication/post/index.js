var AWS = require('aws-sdk');
var crypto = require('crypto');
var jwt = require('jsonwebtoken');
var documentClient = new AWS.DynamoDB.DocumentClient();

var privateKey = process.env.PRIVATE_KEY;

exports.handler = (event, context, callback) => {
  var body = JSON.parse(event.body);
  var userId = body.userId;
  var salt = crypto.createHash('sha512').update(userId).digest('hex');
  var hash = crypto.createHash('sha512').update(body.password + salt).digest('hex');

  documentClient.get({
    TableName: "accounts",
    Key: {
      userId: userId
    }
  }, function(e, data) {
    if (e) {
      callback(e);
      return;
    }
    var user = data.Item;
    if (!user || user.hashedPassword != hash) {
      callback(null, {
        statusCode: 401,
        headers: {},
        body: ''
      });
      return;
    }
    delete user.hashedPassword;
    var accessToken = jwt.sign(user, privateKey, {
      algorithm: 'RS256'
    });
    callback(null, {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        "Access-Control-Allow-Origin": "*"
      },
      body: JSON.stringify({
        accessToken: accessToken
      })
    });
  });
};
