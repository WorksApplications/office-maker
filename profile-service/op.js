var readline = require('readline');
var find = require('find');
var fs = require('fs');
var childProcess = require('child_process');
var Path = require('path');
var AWS = require('aws-sdk');
var archiver = require('archiver');

var project = JSON.parse(fs.readFileSync(__dirname + '/project.json', 'utf8'));
var funcDefs = find.fileSync('function.json', __dirname + '/functions').map(toFuncDef);

var lambda = new AWS.Lambda({
  region: project.region
});

function toFuncDef(jsonPath) {
  var def = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
  def.path = Path.dirname(jsonPath);
  return def;
}

var rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

var model = {
  mode: 'init'
};

recursiveAsyncReadLine();

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
      npmInstall(def.path);
      return makeZipFile(def.path, def.name).then(zipFileName => {
        return upload(def.resource, def.name, zipFileName).then(_ => {
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
      invoke(def.name, def.path).then(out => {
        console.log(out);
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
    var zipFileName = __dirname + '/dest/' + funcName + '.zip';
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

function upload(resource, funcName, zipFileName) {
  console.log('Uploading...');
  return deleteFunction(funcName).then(_ => {
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
        ZipFile: fs.readFileSync(`${__dirname}/dest/${funcName}.zip`)
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

function addPermission(funcName, accountId, apiId, resource) {
  return new Promise((resolve, reject) => {
    lambda.addPermission({
      Action: "lambda:InvokeFunction",
      FunctionName: funcName,
      Principal: "apigateway.amazonaws.com",
      SourceArn: `arn:aws:execute-api:ap-northeast-1:${accountId}:${apiId}/*/${resource}`,
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
    lambda.invoke({
      FunctionName: funcName,
      Payload: fs.readFileSync(dir + '/input.json')
    }, function(e, data) {
      if (e) {
        reject(e)
      } else {
        resolve(data);
      }
    });
  });
}
