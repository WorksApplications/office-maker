var readline = require('readline');
var find = require('find');
var fs = require('fs');
var childProcess = require('child_process');
var Path = require('path');
var AWS = require('aws-sdk');
var archiver = require('archiver');

var project = JSON.parse(fs.readFileSync('./project.json', 'utf8'));

var lambda = new AWS.Lambda({
  region: project.region
});
var apigateway = new AWS.APIGateway({
  region: project.region,
  apiVersion: '2015-07-09'
});

function getResources() {
  return new Promise((resolve, reject) => {
    apigateway.getResources({
      restApiId: project.apiId
    }, function(e, data) {
      if (e) {
        reject(e);
      } else {
        resolve(data.items);
      }
    });
  });
}


var funcDefs;
try {
  funcDefs = find.fileSync('function.json', './functions').map(toFuncDef);
} catch (e) {
  console.log(e.message);
  process.exit(1);
}

var rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

var model = {
  mode: 'init'
};

getResources().then(remoteResources => {
  var functionsDict = {};
  funcDefs.forEach(def => {
    var key = def.resource.method + def.resource.path;
    functionsDict[key] = def;
  });

  remoteResources.forEach(r => {
    // console.log(r);
    Object.keys(r.resourceMethods || {}).forEach(method => {
      var key = method + r.path;
      var funcDef = functionsDict[key];
      if (funcDef) {
        funcDef.resource.id = r.id;
      }
    });
  });
  // console.log(functionsDict);
  recursiveAsyncReadLine();
}).catch(e => {
  console.error(e.message);
  console.error(e.stack);
  process.exit(1);
});


// ---------- functions ---------------

function toFuncDef(jsonPath) {
  try {
    var def = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    def.path = Path.dirname(jsonPath);
    return def;
  } catch (e) {
    throw new Error("mulformed JSON found: " + jsonPath + ": " + e.message);
  }
}

function recursiveAsyncReadLine() {
  if (model.mode == 'init') {
    doInit();
  } else if (model.mode == 'upload') {
    doUpload();
  } else if (model.mode == 'test') {
    doTest();
  }
};

function doInit() {
  rl.question('What do you want?\n  0: upload\n  1: test\n', ans => {
    if (ans == '0') {
      model.mode = 'upload';
      recursiveAsyncReadLine();
    } else if (ans == '1') {
      model.mode = 'test';
      recursiveAsyncReadLine();
    } else {
      console.log('bye!');
      rl.close();
    }
  });
}

function doUpload() {
  rl.question('choose function\n' + list(), ans => {
    var def = funcDefs[+ans];
    if (def) {
      if (fs.existsSync(def.path + '/package.json')) {
        npmInstall(def.path);
      }
      return makeZipFile(def.path, def.name).then(zipFileName => {
        return upload(def.path, def.resource, def.name, zipFileName).then(_ => {
          rl.close();
        });
      }).catch(e => {
        console.error(e);
        rl.close();
        process.exit(1);
      });
    } else {
      console.log('bye!');
      rl.close();
    }
  });
}

function doTest() {
  rl.question('choose function\n' + list(), ans => {
    var def = funcDefs[+ans];
    if (def) {
      console.log('Testing Lambda...');
      invoke(def.name, def.path).then(out => {
        console.log(out);
        console.log('Testing API Gateway...');
        return testInvokeMethod(def.name, def.path, def.resource).then(out => {
          console.log(out);
        });
      }).then(_ => {
        rl.close();
      }).catch(e => {
        console.error(e);
        rl.close();
        process.exit(1);
      });
    } else {
      console.log('bye!');
      rl.close();
    }
  });
}

function testInvokeMethod(funcName, dir, resource) {
  return new Promise((resolve, reject) => {
    var inputJson = JSON.parse(fs.readFileSync(dir + '/input.json', 'utf8'));
    var body;
    try {
      body = JSON.stringify(inputJson.body);
    } catch (e) {
      body = inputJson.body;
    }
    var params = {
      httpMethod: resource.method,
      resourceId: resource.id,
      restApiId: project.apiId,
      body: body || '',
      headers: inputJson.headers,
      pathWithQueryString: inputJson.pathWithQueryString || ''
    };
    apigateway.testInvokeMethod(params, function(e, data) {
      if (e) {
        reject(e);
      } else {
        resolve(data);
      }
    });
  });
}

function list() {
  return funcDefs.map((def, index) => {
    return '  ' + index + ': ' + def.name + '\n';
  }).join('');
}


function npmInstall(cwd) {
  console.log('Resolving dependencies...');
  childProcess.execSync('npm install', {
    cwd: cwd
  });
  console.log('done.');
}

function makeZipFile(funcDir, funcName) {
  return new Promise((resolve, reject) => {
    console.log('Zipping ' + funcDir + '...');
    var zipFileName = './dest/' + funcName + '.zip';
    var output = fs.createWriteStream(zipFileName);
    var archive = archiver('zip');
    output.on('close', function() {
      console.log(archive.pointer() + ' total bytes');
      console.log('done.');
      resolve(zipFileName);
    });
    archive.on('error', reject);
    archive.pipe(output);
    archive.directory(funcDir + '/', false);
    archive.finalize();
  });
}

function upload(path, resource, funcName, zipFileName) {
  console.log('Uploading...');
  return updateFunctionCode(funcName, project.accountId, project.role, zipFileName).then(_ => {
    if (fs.existsSync(path + '/env.json')) {
      console.log('found env.json');
      var envJson = JSON.parse(fs.readFileSync(path + '/env.json', 'utf8'));
      return updateFunctionConfiguration(funcName, envJson);
    }
    return Promise.resolve();
  }).then(_ => {
    console.log('done.');
    return Promise.resolve();
  }).catch(_ => {
    return createFunction(funcName, project.accountId, project.role, zipFileName).then(_ => {
      return addPermission(funcName, project.accountId, project.apiId, resource).then(_ => {
        console.log('done.');
        return Promise.resolve();
      });
    });
  });
}

function deleteFunction(funcName) {
  return new Promise((resolve, reject) => {
    lambda.deleteFunction({
      FunctionName: funcName
    }, function(e, data) {
      if (e) {
        if (e.statusCode == 404) {
          resolve();
        } else {
          reject(e);
        }
      } else {
        resolve();
      }
    });
  });

}

function createFunction(funcName, accountId, role, zipFileName) {
  return new Promise((resolve, reject) => {
    lambda.createFunction({
      FunctionName: funcName,
      Role: `arn:aws:iam::${accountId}:role/${role}`,
      Runtime: "nodejs6.10",
      Handler: "index.handler",
      Code: {
        ZipFile: fs.readFileSync(`./dest/${funcName}.zip`)
      }
    }, function(e, data) {
      if (e) {
        reject(e)
      } else {
        resolve(data);
      }
    });
  });
}

function updateFunctionCode(funcName, accountId, role, zipFileName) {
  return new Promise((resolve, reject) => {
    lambda.updateFunctionCode({
      FunctionName: funcName,
      ZipFile: fs.readFileSync(`./dest/${funcName}.zip`)
    }, function(e, data) {
      if (e) {
        reject(e)
      } else {
        resolve(data);
      }
    });
  });
}

function updateFunctionConfiguration(funcName, env) {
  return new Promise((resolve, reject) => {
    lambda.updateFunctionConfiguration({
      FunctionName: funcName,
      Environment: {
        Variables: env
      },
    }, function(e, data) {
      if (e) {
        reject(e)
      } else {
        resolve(data);
      }
    });
  });
}

function addPermission(funcName, accountId, apiId, resource) {
  return new Promise((resolve, reject) => {
    lambda.addPermission({
      Action: "lambda:InvokeFunction",
      FunctionName: funcName,
      Principal: "apigateway.amazonaws.com",
      SourceArn: `arn:aws:execute-api:${project.region}:${accountId}:${apiId}/*/${resource.method}${resource.path}`,
      StatementId: "1"
    }, function(e, data) {
      if (e) {
        reject(e)
      } else {
        resolve(data);
      }
    });
  });
}

function invoke(funcName, dir) {
  return new Promise((resolve, reject) => {
    var inputJson = JSON.parse(fs.readFileSync(dir + '/input.json', 'utf8'));
    try {
      inputJson.body = JSON.stringify(inputJson.body);
    } catch (e) {}
    lambda.invoke({
      FunctionName: funcName,
      Payload: JSON.stringify(inputJson)
    }, function(e, data) {
      if (e) {
        reject(e)
      } else {
        resolve(data);
      }
    });
  });
}
