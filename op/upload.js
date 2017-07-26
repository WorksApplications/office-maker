var readline = require('readline');
var find = require('find');
var fs = require('fs');
var childProcess = require('child_process');
var Path = require('path');
var AWS = require('aws-sdk');
var archiver = require('archiver');

var project = JSON.parse(fs.readFileSync('./project.json', 'utf8'));

var cloudformation = new AWS.CloudFormation({
  region: project.region
});
var s3 = new AWS.S3({
  region: project.region
});

var templateFile = './template.yml';
var outputTemplateFile = './template_out.yml';
var funcDir = './functions';


rmdir('./node_modules').then(_ => {
  return generateSwaggerYml(project.accountId, project.region).then(_ => {
    return npmInstall(true).then(_ => {
      return cloudFormationPackage(templateFile, outputTemplateFile, project.s3Bucket).then(_ => {
        return cloudFormationDeploy(outputTemplateFile, project.stackName);
      });
    });
  }).then(_ => npmInstall(false));
}).then(result => {
  console.log(result);
}).catch(e => {
  console.log(e);
  process.exit(1);
});

function generateSwaggerYml(accountId, region) {
  if (fs.existsSync('./swagger-template.yml')) {
    var replacedText = fs.readFileSync('./swagger-template.yml', 'utf8')
      .replace(/__ACCOUNT_ID__/g, accountId)
      .replace(/__REGION__/g, region);
    fs.writeFileSync('./swagger.yml', replacedText);
  }
  return Promise.resolve();
}

function rmdir(path) {
  return new Promise((resolve, reject) => {
    childProcess.exec('rm -r ' + path, {
      cwd: '.'
    }, function(e) {
      if (e) {
        reject(e);
      } else {
        resolve();
      }
    });
  });
}

function npmInstall(prod) {
  return new Promise((resolve, reject) => {
    childProcess.exec('npm install' + (prod ? ' --production' : ''), {
      cwd: '.'
    }, function(e) {
      if (e) {
        reject(e);
      } else {
        resolve();
      }
    });
  });
}

function cloudFormationPackage(templateFile, outputTemplateFile, s3Bucket) {
  return spawnCommand('aws', [
    'cloudformation',
    'package',
    '--template-file',
    templateFile,
    '--output-template-file',
    outputTemplateFile,
    '--s3-bucket',
    s3Bucket
  ]);
}

function cloudFormationDeploy(templateFile, stackName) {
  return spawnCommand('aws', [
    'cloudformation',
    'deploy',
    '--template-file',
    templateFile,
    '--stack-name',
    stackName,
    '--capabilities',
    'CAPABILITY_IAM'
  ]);
}

function spawnCommand(command, args) {
  console.log('exec:', command + ' ' + args.join(' '));
  return new Promise((resolve, reject) => {
    childProcess.spawn(command, (args || []), {
      stdio: 'inherit'
    }).on('close', code => {
      if (code) {
        reject('exited with code ' + code);
      } else {
        resolve();
      }
    });
  });
}

function toPromise(object, method) {
  return function(params) {
    return new Promise((resolve, reject) => {
      object[method](params, function(e, data) {
        if (e) {
          reject(e);
        } else {
          resolve(data);
        }
      });
    });
  };
}
