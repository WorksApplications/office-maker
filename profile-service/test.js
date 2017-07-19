var localDynamo = require('local-dynamo');
var childProcess = require('child_process');
var profilesGet = require('./functions/profiles/get.js');

var assertion1 = handlerToPromise(profilesGet.handler)({
  "pathParameters": {
    "userId": "mock@example.com"
  }
}, {}).then(result => {
  if (result.statusCode >= 500) {
    throw "Internal Server Error: " + JSON.stringify(result);
  }
  return Promise.resolve();
});

var all = reducePromises([
  assertion1
]);

duringRunningLocalDynamo(__dirname + '/dynamodb_local', 4569, all).then(result => {
  console.log(result);
  console.log('done');
}).catch(e => {
  console.log(e);
  process.exit(1);
});

function reducePromises(promises) {
  return promises.reduce((prev, curr) => {
    return prev.then(_ => curr);
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
      delay(500).then(_ => {
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
      '-sharedDb',
      '-port',
      '' + port
    ], {
      stdio: 'inherit',
      cwd: dynamodbLocalPath
    });
    resolve(p);
  });
}
