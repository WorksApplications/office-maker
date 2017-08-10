process.env.EXEC_MODE = 'test';

var childProcess = require('child_process');
var fs = require('fs');
var AWS = require('aws-sdk');
var db = require('../functions/common/db.js');
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


// temporary
var tableDefYaml = fs.readFileSync(__dirname + '/test-table.yml', 'utf8');
var table2DefYaml = fs.readFileSync(__dirname + '/test-table2.yml', 'utf8');


describe('Profile Lambda', () => {
  var dbProcess = null;

  before(function() {
    this.timeout(5000);
    return runLocalDynamo(dynamodbLocalPath, port).then(p => {
      dbProcess = p;
      return delay(700).then(_ => {
        // var tableDef = templateOutYml.Resources.ProfilesTable.Properties;
        var tableDef = yaml.safeLoad(tableDefYaml).Properties;
        return dynamoUtil.createTable(dynamodb, tableDef);
      }).then(_ => {
        // var tableDef = templateOutYml.Resources.ProfilesSearchHelpTable.Properties;
        var tableDef = yaml.safeLoad(table2DefYaml).Properties;
        return dynamoUtil.createTable(dynamodb, tableDef);
      });
    });
  });
  beforeEach(() => {
    return db.putProfile({
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
    }).then(_ => db.putProfile({
      userId: 'yamada_s@example.com',
      picture: null, // be sure to allow empty string
      name: '山田 Saburo',
      ruby: 'やまだ さぶろう',
      employeeId: '1235',
      organization: 'Example Co., Ltd.',
      post: 'Sales and Tech',
      rank: 'Assistant',
      cellPhone: '080-XXX-5678',
      extensionPhone: 'XXXXX',
      mail: 'yamada_s@example.com',
      workplace: null // be sure to allow empty string
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
      }, {}).then(assertProfileLength(1)).then(res => {
        var profile = JSON.parse(res.body).profiles[0];
        if (!profile) {
          return Promise.reject("unexpected empty user");
        }
        Object.keys(profile).forEach(key => {
          if (key.indexOf('normalized') === 0) {
            throw new Error('normalized field found: ' + key);
          }
        });
        return Promise.resolve();
      });
    });
    it('should search multiple profiles by userId', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "userId": "yamada@example.com,yamada_s@example.com"
        }
      }, {}).then(assertProfileLength(2));
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
          "q": "山田"
        }
      }, {}).then(assertProfileLength(2));
    });
    it('should search profiles by q (match to name)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "太郎"
        }
      }, {}).then(assertProfileLength(1));
    });
    it('should search profiles by q (match to name, case sensitive)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "saburo"
        }
      }, {}).then(assertProfileLength(1));
    });
    it('should search profiles by q (match to ruby)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "やまだ"
        }
      }, {}).then(assertProfileLength(2));
    });
    it('should search profiles by q (match to ruby)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "たろう"
        }
      }, {}).then(assertProfileLength(1));
    });
    it('should search profiles by q (match to mail before @)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "yamada"
        }
      }, {}).then(assertProfileLength(1));
    });
    it('should NOT search profiles by q (match to mail, upper case)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "YAMADA"
        }
      }, {}).then(assertProfileLength(0));
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
    it('should search profiles by q (match to post)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "Tech"
        }
      }, {}).then(assertProfileLength(1));
    });
    it('should search profiles by q (match to quoted post)', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "\"Sales and Tech\""
        }
      }, {}).then(assertProfileLength(1));
    });
    // it('should work with limit and exclusiveStartKey', () => {
    //   return handlerToPromise(profilesQuery.handler)({
    //     "queryStringParameters": {
    //       "q": "やまだ",
    //       "limit": 1
    //     }
    //   }, {}).then(assertProfileLength(1)).then(res => {
    //     // console.log(JSON.parse(res.body).lastEvaluatedKey);
    //     return handlerToPromise(profilesQuery.handler)({
    //       "queryStringParameters": {
    //         "q": "やまだ",
    //         "limit": 1,
    //         "exclusiveStartKey": JSON.parse(res.body).lastEvaluatedKey
    //       }
    //     }, {}).then(assertProfileLength(1)).then(res => {
    //       return handlerToPromise(profilesQuery.handler)({
    //         "queryStringParameters": {
    //           "q": "やまだ",
    //           "limit": 1,
    //           "exclusiveStartKey": JSON.parse(res.body).lastEvaluatedKey
    //         }
    //       }, {}).then(assertProfileLength(0)).then(res => {
    //         if (JSON.parse(res.body).lastEvaluatedKey) {
    //           return Promise.reject('lastEvaluatedKey found: ' + JSON.parse(res.body).lastEvaluatedKey);
    //         }
    //         return Promise.resolve();
    //       });
    //     });
    //   });
    // });
    it('should support multiple queries at once', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "やまだ やまもと"
        }
      }, {}).then(assertProfileLength(2));
    });
    it('should support double-quotation', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "\"やまだ やまもと\""
        }
      }, {}).then(assertProfileLength(0));
    });
  });
  describe('GET /profiles (large)', () => {
    // var count = 3000;
    var totalCount = 120; //
    before(function() {
      this.timeout(30 * 1000);
      return Array.from(Array(totalCount).keys()).reduce((p, i) => {
        return p.then(_ => {
          var mail = `user${i}@example.com`;
          return db.putProfile({
            userId: mail,
            picture: null,
            name: '竹中 洋子',
            ruby: 'たけなか ようこ',
            employeeId: '1234',
            organization: 'Example Co., Ltd.',
            post: 'Tech',
            rank: 'Manager',
            cellPhone: '080-XXX-4567',
            extensionPhone: 'XXXXX',
            mail: mail,
            workplace: null
          });
        });
      }, Promise.resolve());
    });
    it('should search', () => {
      return handlerToPromise(profilesQuery.handler)({
        "queryStringParameters": {
          "q": "竹中"
        }
      }, {}).then(assertStatus(200)).then(res => {
        var profiles = JSON.parse(res.body).profiles;
        // console.log('found', profiles.length);
        return Promise.resolve();
      });
    });
    // it('should work with limit', function() {
    //   this.timeout(30 * 1000);
    //
    //   function recursivelyGetAll(previous, exclusiveStartKey) {
    //     previous = previous || [];
    //     return handlerToPromise(profilesQuery.handler)({
    //       "queryStringParameters": {
    //         "q": "竹中",
    //         "limit": 100,
    //         "exclusiveStartKey": exclusiveStartKey
    //       }
    //     }, {}).then(res => {
    //       var profiles = JSON.parse(res.body).profiles;
    //       var lastEvaluatedKey = JSON.parse(res.body).lastEvaluatedKey;
    //       if (lastEvaluatedKey) {
    //         return recursivelyGetAll(previous.concat(profiles), lastEvaluatedKey);
    //       } else {
    //         return Promise.resolve(previous.concat(profiles));
    //       }
    //     });
    //   }
    //   return recursivelyGetAll().then(profiles => {
    //     if (profiles.length !== totalCount) {
    //       return Promise.reject('Unexpected profiles count: ' + profiles.length);
    //     }
    //     return Promise.resolve();
    //   });
    // });
  });
  describe('GET /profiles/{userId}', () => {
    it('returns 200 if profile exists', () => {
      return handlerToPromise(profilesGet.handler)({
        "pathParameters": {
          "userId": "yamada@example.com"
        }
      }, {}).then(assertStatus(200)).then(res => {
        var profile = JSON.parse(res.body);
        Object.keys(profile).forEach(key => {
          if (key.indexOf('normalized') === 0) {
            throw new Error('normalized field found: ' + key);
          }
        });
        return Promise.resolve();
      });
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
    it('returns 200 if data is valid', () => {
      return handlerToPromise(profilesPut.handler)({
        "pathParameters": {
          "userId": "test@example.com"
        },
        "body": JSON.stringify({
          "userId": "test@example.com",
          "name": "テスト"
        })
      }, {}).then(assertStatus(200)).then(assertProfileLengthInDB(3));;
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
      }, {}).then(assertStatus(200)).then(assertProfileLengthInDB(3));
    });
  });
  describe('DELETE /profiles/{userId}', () => {
    it('delete profile correctly', () => {
      return handlerToPromise(profilesDelete.handler)({
        "pathParameters": {
          "userId": "mock@example.com"
        }
      }, {}).then(assertStatus(200)).then(assertProfileLengthInDB(1));
    });
    it('does not matter if user is not there', () => {
      return handlerToPromise(profilesDelete.handler)({
        "pathParameters": {
          "userId": "not_exist@example.com"
        }
      }, {}).then(assertStatus(200));
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
    return Promise.resolve(result);
  };
}

function assertProfileLengthInDB(expect) {
  return result => {
    return dynamoUtil.scan(documentClient, {
      TableName: "profiles"
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
