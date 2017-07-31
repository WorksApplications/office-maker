var db = require('../common/db.js');
var lambdaUtil = require('../common/lambda-util.js');

function validateField(profile, key, tipe) {
  if (!profile[key]) {
    return "Field [" + key + "] must exist.";
  }
  if (typeof profile[key] != tipe) {
    return "Field [" + key + "] must be " + tipe + ".";
  }
  return;
}

function validateFields(profile, fields) {
  var warnings = fields.map(field => {
    return validateField(profile, field.key, field.type)
  }).filter(w => !!w);
  if (warnings.length) {
    throw new Error(warnings.toString());
  }
}

exports.handler = (event, context, callback) => {
  var profile;
  try {
    profile = JSON.parse(event.body);
    validateFields(profile, [{
      key: 'userId',
      type: 'string'
    }]);
  } catch (e) {
    lambdaUtil.send(callback, 400, {
      message: e.message
    });
    return;
  }
  db.putProfile(profile).then(_ => {
    lambdaUtil.send(callback, 200);
  }).catch(e => {
    lambdaUtil.send(callback, 500, {
      message: e.message
    });
  });
};
