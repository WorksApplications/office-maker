process.env.EXEC_MODE = 'test';
process.env.PRIVATE_KEY = 'TODO';

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

var authenticationPost = require('../functions/authentication/post.js');
var authorizerIndex = require('../functions/authorizer/index.js');
var authorizerIp = require('../functions/authorizer/ip.js');
// var usersGet = require('../functions/users/get.js');
var usersPost = require('../functions/users/post.js');

var dynamodbLocalPath = __dirname + '/../../dynamodb_local';
var port = 4569;

describe('Accounts Lambda', () => {
  var dbProcess = null;

  before(function() {
    this.timeout(5000);
    return runLocalDynamo(dynamodbLocalPath, port).then(p => {
      dbProcess = p;
      return delay(700).then(_ => {
        return dynamoUtil.createTable(dynamodb, templateOutYml.Resources.AccountsTable.Properties);
      });
    });
  });
  beforeEach(() => {});
  describe('POST /authentication', () => {
    it('returns 401 if unauthorized', () => {
      return handlerToPromise(authenticationPost.handler)({
        "body": JSON.stringify({
          "userId": "test@example.com",
          "password": "not_correct"
        })
      }, {}).then(assertStatus(401));
    });
  });

  // describe('GET /users/{userId}', () => {
  //   it('returns 200 if ok', () => {
  //     return handlerToPromise(usersGet.handler)({
  //       "pathParameters": {
  //         "userId": "test@example.com"
  //       }
  //     }, {}).then(assertStatus(200));
  //   });
  //   it('returns 404 if user not found', () => {
  //     return handlerToPromise(usersGet.handler)({
  //       "pathParameters": {
  //         "userId": "test@example.com"
  //       }
  //     }, {}).then(assertStatus(404));
  //   });
  // });
  describe('POST /users/{userId}', () => {
    it('returns 200 if ok', () => {
      return handlerToPromise(usersPost.handler)({
        "pathParameters": {
          "userId": "test@example.com"
        },
        "body": JSON.stringify({
          "userId": "test@example.com"
        })
      }, {}).then(assertStatus(200)).then(assertAccountsLengthInDB(1));
    });
  });
});


function assertAccountsLengthInDB(expect) {
  return result => {
    return dynamoUtil.scan(documentClient, {
      TableName: "accounts"
    }).then(data => {
      if (data.Items.length !== expect) {
        `Expected profile length ${expect} but got ${data.Items.length}`;
      }
      return Promise.resolve(result);
    });
  };
}

function assertStatus(expect) {
  return result => {
    if (result.statusCode !== expect) {
      throw `Expected statusCode ${expect} but got ${result.statusCode}: ${JSON.stringify(result)}`;
    }
    return Promise.resolve(result);
  };
}

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
