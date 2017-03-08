var fs = require('fs');
var path = require('path');
var ejs = require('ejs');

function generate(config, publicDir) {
  var outputFiles = {
    index: path.join(publicDir, 'index.html'),
    login: path.join(publicDir, 'login.html'),
    master: path.join(publicDir, 'master.html')
  };

  var templateDir = __dirname + '/template';
  var indexHtml = ejs.render(fs.readFileSync(templateDir + '/index.html', 'utf8'), {
    apiRoot: config.apiRoot,
    accountServiceRoot: config.accountServiceRoot,
    title: config.title
  });
  fs.writeFileSync(outputFiles.index, indexHtml);

  var loginHtml = ejs.render(fs.readFileSync(templateDir + '/login.html', 'utf8'), {
    accountServiceRoot: config.accountServiceRoot,
    title: config.title
  });
  fs.writeFileSync(outputFiles.login, loginHtml);

  var masterHtml = ejs.render(fs.readFileSync(templateDir + '/master.html', 'utf8'), {
    apiRoot: config.apiRoot,
    accountServiceRoot: config.accountServiceRoot,
    title: config.title
  });
  fs.writeFileSync(outputFiles.master, masterHtml);

  return outputFiles;
}

module.exports = generate;
