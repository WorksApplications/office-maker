var db = require('../common/db.js');
var lambdaUtil = require('../common/lambda-util.js');

exports.handler = (event, context, callback) => {
  var limit = +params.limit || undefined;
  var exclusiveStartKey = params.exclusiveStartKey;
  db.scanProfile(limit, exclusiveStartKey).then(result => {
    lambdaUtil.send(callback, 200, result);
  }).catch(e => {
    lambdaUtil.send(callback, 500, e);
  });
};
