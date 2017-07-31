process.env.EXEC_MODE = 'test';

var childProcess = require('child_process');
var fs = require('fs');
var AWS = require('aws-sdk');
var dynamoUtil = require('../functions/common/dynamo-util.js');
var options = require('../functions/common/db-options.js');
var dynamodb = new AWS.DynamoDB(options);
var documentClient = new AWS.DynamoDB.DocumentClient(options);
var yaml = require('js-yaml');
var templateOutYml = yaml.safeLoad(fs.readFileSync('./template_out.yml', 'utf8'));
var assert = require('assert');

var profilesGet = require('../functions/profiles/get.js');
var profilesPut = require('../functions/profiles/put.js');
var profilesDelete = require('../functions/profiles/delete.js');
var profilesQuery = require('../functions/profiles/query.js');

var dynamodbLocalPath = __dirname + '/../../dynamodb_local';
var port = 4569;

describe('Profile Lambda', () => {
  var dbProcess = null;

  before(function() {
    this.timeout(5000);
    return runLocalDynamo(dynamodbLocalPath, port).then(p => {
      dbProcess = p;
      return delay(700).then(_ => {
        return dynamoUtil.createTable(dynamodb, templateOutYml.Resources.ProfilesTable.Properties);
      });
    });
  });
  beforeEach(() => {
    return dynamoUtil.delete(documentClient, {
      TableName: "profiles",
      Key: {
        userId: 'mock@example.com'
      }
    });
  });
  describe('GET /profiles', () => {
    it('works', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "userId": "mock@example.com"
        }
      }, {}).then(assertStatus(200));
    });
  });
  describe('GET /profiles/{userId}', () => {
    it('returns 404 if profile does not exist', () => {
      return handlerToPromise(profilesGet.handler)({
        "pathParameters": {
          "userId": "mock@example.com"
        }
      }, {}).then(assertStatus(404));
    });
  });
  describe('PUT /profiles/{userId}', () => {
    it('returns 400 if data is invalid', () => {
      return handlerToPromise(profilesPut.handler)({
        "pathParameters": {
          "userId": "mock@example.com"
        }
      }, {}).then(assertStatus(400));
    });
  });
  describe('PUT /profiles/{userId}', () => {
    it('returns 400 if data is invalid', () => {
      return handlerToPromise(profilesPut.handler)({
        "pathParameters": {
          "userId": "mock@example.com"
        },
        "body": "{}"
      }, {}).then(assertStatus(400));
    });
  });
});

function assertStatus(expect) {
  return result => {
    if (result.statusCode !== expect) {
      throw `Expected statusCode ${expect} but got ${result.statusCode}: ${JSON.stringify(result)}`;
    }
    return Promise.resolve();
  };
}

// function assertRoughStatus(expect) {
//   var actual = result.statusCode - result.statusCode % 100;
//   return result => {
//     if (actual !== expect) {
//       throw `Expected statusCode ${expect} but got ${result.statusCode}: ${JSON.stringify(result)}`;
//     }
//     return Promise.resolve();
//   };
// }

function reducePromises(promises) {
  return promises.reduce((prev, toPromise) => {
    return prev.then(toPromise);
  }, Promise.resolve());
}

function handlerToPromise(handler) {
  return function(event, context) {
    return new Promise((resolve, reject) => {
      handler(event, context, function(e, data) {
        if (e) {
          reject(e);
        } else {
          resolve(data);
        }
      });
    });
  };
}

function duringRunningLocalDynamo(dynamodbLocalPath, port, promise) {
  return runLocalDynamo(dynamodbLocalPath, port).then(p => {
    return new Promise((resolve, reject) => {
      var err = undefined;
      var result = undefined;
      p.on('close', code => {
        if (err) {
          reject(err);
        } else if (code) {
          reject('child process exited with code: ' + code);
        } else {
          resolve(result);
        }
      });
      delay(200).then(_ => {
        return promise.then(result_ => {
          result = result_;
          p.kill();
        }).catch(e => {
          err = e;
          p.kill();
        });
      });
    });
  });
}

function delay(time) {
  return new Promise((resolve, reject) => {
    setTimeout(resolve, time);
  });
}

function runLocalDynamo(dynamodbLocalPath, port) {
  return new Promise((resolve, reject) => {
    var p = childProcess.spawn('java', [
      `-Djava.library.path=.;./DynamoDBLocal_lib`,
      '-jar',
      'DynamoDBLocal.jar',
      '-inMemory',
      '-port',
      '' + port
    ], {
      // stdio: 'inherit',
      cwd: dynamodbLocalPath
    });
    resolve(p);
  });
}
