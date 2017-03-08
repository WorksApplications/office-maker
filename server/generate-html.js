var fs = require('fs');
var path = require('path');
var ejs = require('ejs');

var config = null;
if(fs.existsSync(__dirname + '/config.json')) {
  config = JSON.parse(fs.readFileSync(__dirname + '/config.json', 'utf8'));
} else {
  config = JSON.parse(fs.readFileSync(__dirname + '/defaultConfig.json', 'utf8'));
}
config.apiRoot = '/api';

var publicDir = __dirname + '/public';
var templateDir = __dirname + '/template';
var indexHtml = ejs.render(fs.readFileSync(templateDir + '/index.html', 'utf8'), {
  apiRoot: config.apiRoot,
  accountServiceRoot: config.accountServiceRoot,
  title: config.title
});
fs.writeFileSync(path.join(publicDir, 'index.html'), indexHtml);

var loginHtml = ejs.render(fs.readFileSync(templateDir + '/login.html', 'utf8'), {
  accountServiceRoot: config.accountServiceRoot,
  title: config.title
});
fs.writeFileSync(path.join(publicDir, 'login'), loginHtml);

var masterHtml = ejs.render(fs.readFileSync(templateDir + '/master.html', 'utf8'), {
  apiRoot: config.apiRoot,
  accountServiceRoot: config.accountServiceRoot,
  title: config.title
});
fs.writeFileSync(path.join(publicDir, 'master'), masterHtml);
