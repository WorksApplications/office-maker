var db = require('../common/db.js');
var lambdaUtil = require('../common/lambda-util.js');

exports.handler = (event, context, callback) => {
  throw "not implemented yet."
  var profile;
  try {
    profile = JSON.parse(event.body);
  } catch (e) {
    lambdaUtil.send(callback, 400, {
      message: e.message
    });
    return;
  }
  db.putProfile(profile).then(_ => {
    lambdaUtil.send(callback, 200);
  }).catch(e => {
    lambdaUtil.send(callback, 500, e);
  });
};
