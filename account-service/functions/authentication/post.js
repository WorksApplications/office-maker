var AWS = require('aws-sdk');
var crypto = require('crypto');
var jwt = require('jsonwebtoken');
var lambdaUtil = require('../common/lambda-util.js');
var db = require('../common/db.js');

var privateKey = process.env.PRIVATE_KEY;

exports.handler = (event, context, callback) => {
  var body = JSON.parse(event.body);
  var userId = body.userId;
  var salt = crypto.createHash('sha512').update(userId).digest('hex');
  var hash = crypto.createHash('sha512').update(body.password + salt).digest('hex');

  db.getAccount(userId).then(user => {
    if (!user || user.hashedPassword !== hash) {
      lambdaUtil.send(callback, 401);
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
  }).catch(e => {
    lambdaUtil.send(callback, 500, {
      message: e.message
    });
  });
};
