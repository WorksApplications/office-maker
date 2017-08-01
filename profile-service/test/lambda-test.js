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
        // console.log(templateOutYml.Resources.ProfilesTable.Properties);
        return dynamoUtil.createTable(dynamodb, templateOutYml.Resources.ProfilesTable.Properties);
      });
    });
  });
  beforeEach(() => {
    return dynamoUtil.put(documentClient, {
      TableName: "profiles",
      Item: {
        userId: 'yamada@example.com',
        picture: null,
        name: '山田 太郎',
        ruby: 'やまだ たろう',
        employeeId: '1234',
        organization: 'Example Co., Ltd.',
        post: 'Tech',
        rank: 'Manager',
        cellPhone: '080-XXX-4567',
        extensionPhone: 'XXXXX',
        mail: 'yamada@example.com',
        workplace: null
      }
    }).then(_ => dynamoUtil.put(documentClient, {
      TableName: "profiles",
      Item: {
        userId: 'tanaka@example.com',
        picture: null, // be sure to allow empty string
        name: '山岡 三郎',
        ruby: 'やまおか さぶろう',
        employeeId: '1235',
        organization: 'Example Co., Ltd.',
        post: 'Sales and Tech',
        rank: 'Assistant',
        cellPhone: '080-XXX-5678',
        extensionPhone: 'XXXXX',
        mail: 'yamaoka@example.com',
        workplace: null // be sure to allow empty string
      }
    }));
  });
  describe('GET /profiles', () => {
    it('should search profiles by userId', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "userId": "not_exist@example.com"
        }
      }, {}).then(assertProfileLength(0));
    });
    it('should search profiles by userId', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "userId": "yamada@example.com"
        }
      }, {}).then(assertProfileLength(1));
    });
    it('should search profiles by q', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "not_exist"
        }
      }, {}).then(assertProfileLength(0));
    });
    it('should search profiles by q (match to name)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "山"
        }
      }, {}).then(assertProfileLength(2));
    });
    it('should search profiles by q (match to name)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "太"
        }
      }, {}).then(assertProfileLength(1));
    });
    it('should search profiles by q (match to ruby)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "やま"
        }
      }, {}).then(assertProfileLength(2));
    });
    it('should search profiles by q (match to ruby)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "たろ"
        }
      }, {}).then(assertProfileLength(1));
    });
    it('should search profiles by q (match to mail)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "yama"
        }
      }, {}).then(assertProfileLength(2));
    });
    it('should search profiles by q (match to employeeId)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "1234"
        }
      }, {}).then(assertProfileLength(1));
    });
    it('should search profiles by q (match to employeeId)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "123"
        }
      }, {}).then(assertProfileLength(0));
    });
    it('should NOT search profiles by q (match to organization)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "Example"
        }
      }, {}).then(assertProfileLength(0));
    });
    it('should search profiles by q (match to post)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "Tech"
        }
      }, {}).then(assertProfileLength(2));
    });
  });
  describe('GET /profiles/{userId}', () => {
    it('returns 200 if profile exists', () => {
      return handlerToPromise(profilesGet.handler)({
        "pathParameters": {
          "userId": "yamada@example.com"
        }
      }, {}).then(assertStatus(200));
    });
    it('returns 404 if profile does not exist', () => {
      return handlerToPromise(profilesGet.handler)({
        "pathParameters": {
          "userId": "not_exist@example.com"
        }
      }, {}).then(assertStatus(404));
    });
  });
  describe('PUT /profiles/{userId}', () => {
    it('returns 400 if data is invalid', () => {
      return handlerToPromise(profilesPut.handler)({
        "pathParameters": {
          "userId": "test@example.com"
        }
      }, {}).then(assertStatus(400));
    });
    it('returns 200 if data is valid', () => {
      return handlerToPromise(profilesPut.handler)({
        "pathParameters": {
          "userId": "test@example.com"
        },
        "body": JSON.stringify({
          "userId": "test@example.com",
          "name": "テスト"
        })
      }, {}).then(assertStatus(200));
    });
    it('still returns 200 if data contains empty string', () => {
      return handlerToPromise(profilesPut.handler)({
        "pathParameters": {
          "userId": "test@example.com"
        },
        "body": JSON.stringify({
          "userId": "test@example.com",
          "name": "テスト",
          "picture": "",
          "extensionPhone": ""
        })
      }, {}).then(assertStatus(200));
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

function assertProfileLength(expect) {
  return result => {
    if (result.statusCode !== 200) {
      throw `Expected statusCode 200 but got ${result.statusCode}: ${JSON.stringify(result)}`;
    }
    var profiles = JSON.parse(result.body).profiles;
    if (profiles.length !== expect) {
      throw `Expected profile length ${expect} but got ${profiles.length}`;
    }
    return Promise.resolve();
  };
}


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
