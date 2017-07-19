var childProcess = require('child_process');
var fs = require('fs');
var AWS = require('aws-sdk');
var dynamoUtil = require('./functions/common/dynamo-util.js');
var options = require('./functions/common/db-options.js');
var dynamodb = new AWS.DynamoDB(options);
var yaml = require('js-yaml');
var templateYml = yaml.safeLoad(fs.readFileSync('./template.yml', 'utf8'));
var profilesGet = require('./functions/profiles/get.js');

var prepare = () => dynamoUtil.createTable(dynamodb, templateYml.Resources.ProfilesTable.Properties);

var assertion1 = () => handlerToPromise(profilesGet.handler)({
  "pathParameters": {
    "userId": "mock@example.com"
  }
}, {}).then(assertStatus(404));

var all = reducePromises([
  prepare,
  assertion1
]);

duringRunningLocalDynamo(__dirname + '/dynamodb_local', 4569, all).then(_ => {
  console.log('done.');
}).catch(e => {
  console.error(e);
  process.exit(1);
});

function assertStatus(expect) {
  return result => {
    if (result.statusCode !== expect) {
      throw `Expected statusCode ${expect} but got ${result.statusCode}: JSON.stringify(result)`;
    }
    return Promise.resolve();
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
      stdio: 'inherit',
      cwd: dynamodbLocalPath
    });
    resolve(p);
  });
}
