var AWS = require('aws-sdk');
var lambdaUtil = require('../common/lambda-util.js');
var db = require('../common/db.js');
var crypto = require('crypto');

exports.handler = (event, context, callback) => {
  var body = JSON.parse(event.body);
  var userId = body.userId;
  var password = body.password;
  var role = body.role;
  var salt = crypto.createHash('sha512').update(userId).digest('hex');
  var hash = crypto.createHash('sha512').update(password + salt).digest('hex');

  var account = {
    userId: userId,
    hashedPassword: hash,
    role: role
  };
  db.putAccount(account).then(account => {
    // lambdaUtil.send(callback, 200, user);
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
