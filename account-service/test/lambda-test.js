var fs = require('fs');
process.env.EXEC_MODE = 'test';
process.env.PRIVATE_KEY = fs.readFileSync(__dirname + '/private.key', 'utf8');
process.env.PUBLIC_KEY = fs.readFileSync(__dirname + '/public.key', 'utf8');

var childProcess = require('child_process');
var AWS = require('aws-sdk');
var dynamoUtil = require('../functions/common/dynamo-util.js');
var options = require('../functions/common/db-options.js');
var dynamodb = new AWS.DynamoDB(options);
var documentClient = new AWS.DynamoDB.DocumentClient(options);
var yaml = require('js-yaml');
var templateOutYml = yaml.safeLoad(fs.readFileSync('./template_out.yml', 'utf8'));
var assert = require('assert');
var jwt = require('jsonwebtoken');

var authenticationPost = require('../functions/authentication/post.js');
var authorizerIndex = require('../functions/authorizer/index.js');
var authorizerIp = require('../functions/authorizer/ip.js');
// var usersGet = require('../functions/users/get.js');
var usersPost = require('../functions/users/post.js');

var dynamodbLocalPath = __dirname + '/../../dynamodb_local';
var port = 4569;

var mockToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiaWF0IjoxNTAxNjg1MTk4fQ.GJRbktuj39KZ7QQeKZ--RW4zMUEKxK_5MDcNwVzf0nkNkRNGlRfkcXUBcmJIiUl7DzAEYE50mZa6ILiWmftDsP2MbqV-g5VOjXD3tlYt2Xo_5eklro_ZqoUkJb5gVNppQNS1-C_YSye3cWvyiA3_hqjxcIk17gGeMNQRfhIp92HVJVC40U_-qBb1d821FMvvDjiHszIQ_8yIwvimhbg5jmI7WMhsBIdMgEt_aPQXgNnqk_tS-N4NKT5Lzi6ZyD-lQBTzSl8Q3fjOpLKYW7AANggzfztCuMPNhj5t6qG5wQKUTdJvjMLlNF0WKnsUU5w6A-FKQlv8zPOSjdnxqsIELA";

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
  beforeEach(() => {
    return handlerToPromise(usersPost.handler)({
      "pathParameters": {
        "userId": "test@example.com"
      },
      "body": JSON.stringify({
        "userId": "test@example.com",
        "password": "pass"
      })
    }, {});
    // return dynamoUtil.put(documentClient, {
    //   TableName: "accounts",
    //   Item: {
    //     userId: 'mock@example.com',
    //   }
    // });
  });

  describe('JWT', () => {
    it('works', () => {
      return new Promise((resolve, reject) => {
        var user = {
          "userId": "test@example.com"
        };
        var token = jwt.sign(user, process.env.PRIVATE_KEY, {
          algorithm: 'RS256'
        });
        // console.log(token);
        jwt.verify(token, process.env.PUBLIC_KEY, {
          algorithms: ['RS256', 'RS384', 'RS512', 'HS256', 'HS256', 'HS512', 'ES256', 'ES384', 'ES512']
        }, function(e, user2) {
          if (e) {
            reject(e);
          } else {
            if (user.userId !== user2.userId) {
              reject(e);
            } else {
              resolve();
            }
          }
        });
      });
    });
  });
  describe('authorizer', () => {
    it('returns Deny if unauthorized', () => {
      return handlerToPromise(authorizerIndex.handler)({
        "authorizationToken": ""
      }, {}).then(assertAuth('Deny'));
    });
    it('returns Allow if unauthorized', () => {
      return handlerToPromise(authorizerIndex.handler)({
        "authorizationToken": "Bearer " + mockToken
      }, {}).then(assertAuth('Allow')).then(res => {
        var expect = 'test@example.com';
        if (res.context.userId !== expect) {
          throw 'expected ' + expect + ' but got: ' + res.context.userId;
        }
        return Promise.resolve(res);
      });
    });
  });
  describe('POST /authentication', () => {
    it('returns 401 if unauthenticated', () => {
      return handlerToPromise(authenticationPost.handler)({
        "body": JSON.stringify({
          "userId": "test@example.com",
          "password": "not_correct"
        })
      }, {}).then(assertStatus(401));
    });
    it('returns 401 if unauthenticated', () => {
      return handlerToPromise(authenticationPost.handler)({
        "body": JSON.stringify({
          "userId": "foo@example.com",
          "password": "pass"
        })
      }, {}).then(assertStatus(401));
    });
    it('returns 200 if authenticated and pass authorization with returned token', () => {
      return handlerToPromise(authenticationPost.handler)({
        "body": JSON.stringify({
          "userId": "test@example.com",
          "password": "pass"
        })
      }, {}).then(assertStatus(200)).then(res => {
        var accessToken = JSON.parse(res.body).accessToken;
        if (!accessToken) {
          throw 'accessToken not found';
        }
        return handlerToPromise(authorizerIndex.handler)({
          "authorizationToken": 'Bearer ' + accessToken
        }, {}).then(assertAuth('Allow')).then(res => {
          if (res.context.pass || res.context.password || res.context.hashedPassword) {
            throw 'password must not be included';
          }
          return Promise.resolve(res);
        });
      });
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

function assertAuth(expect) {
  return result => {
    var effect = result.policyDocument.Statement[0].Effect
    if (effect !== expect) {
      throw `Expected statusCode ${expect} but got ${effect}: ${JSON.stringify(result)}`;
    }
    return Promise.resolve(result);
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
