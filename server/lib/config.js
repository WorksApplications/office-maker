var fs = require('fs');
var path = require('path');

/* paths */
var configJsonPath = path.resolve(__dirname, '../config.json');
var defaultConfigJsonPath = path.resolve(__dirname, '../defaultConfig.json');
var replaceSecret = config => {
  var secretFilePath = path.resolve(__dirname, '..', config.secret);
  config.secret = fs.readFileSync(secretFilePath, 'utf8');
};

/* load */
var config = null;
if(fs.existsSync(configJsonPath)) {
  config = JSON.parse(fs.readFileSync(configJsonPath, 'utf8'));
} else {
  config = JSON.parse(fs.readFileSync(defaultConfigJsonPath, 'utf8'));
}

/* additional/replace */
replaceSecret(config);
config.apiRoot = '/api';

module.exports = config;
