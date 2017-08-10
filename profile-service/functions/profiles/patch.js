var db = require('../common/db.js');
var lambdaUtil = require('../common/lambda-util.js');

exports.handler = (event, context, callback) => {
  var profile = JSON.parse(event.body);
  db.patchProfile(profile).then(_ => {
    lambdaUtil.send(callback, 200);
  }).catch(e => {
    lambdaUtil.send(callback, 500, {
      message: e.message
    });
  });
};
