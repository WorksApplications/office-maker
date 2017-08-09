var db = require('../common/db.js');
var lambdaUtil = require('../common/lambda-util.js');

exports.handler = (event, context, callback) => {
  var q = event.queryStringParameters.q || undefined;
  var userId = event.queryStringParameters.userId || undefined;
  var employeeId = event.queryStringParameters.employeeId || undefined;
  var order = event.queryStringParameters.order;
  var limit = event.queryStringParameters.limit;
  var exclusiveStartKey = event.queryStringParameters.exclusiveStartKey;
  console.log('Query:', q);

  if (userId) {
    var userIds = userId.split(',');
    db.findProfileByUserIds(userIds, limit, exclusiveStartKey).then(result => {
      lambdaUtil.send(callback, 200, result);
    }).catch(e => {
      lambdaUtil.send(callback, 500, {
        message: e.message
      });
    });
  } else if (q) {
    db.findProfileByQuery(q, limit, exclusiveStartKey).then(result => {
      lambdaUtil.send(callback, 200, result);
    }).catch(e => {
      lambdaUtil.send(callback, 500, {
        message: e.message
      });
    });
  } else {
    lambdaUtil.send(callback, 400);
  }

};
