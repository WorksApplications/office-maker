var log4js = require('log4js');
var fs = require('fs');
var config = require('./config.js');

var options = {
  appenders: [{
    category: "access",
    type: "dateFile",
    filename: "/tmp/access.log",
    pattern: "-yyyy-MM-dd",
    backups: 3
  }, {
    category: "system",
    type: "dateFile",
    filename: "/tmp/system.log",
    pattern: "-yyyy-MM-dd",
    backups: 3
  }],
  levels: config.log
};
var debug = true;
if (debug) {
  options.appenders.forEach(appender => {
    appender.type = 'console';
  });
}

log4js.configure(options);

module.exports = {
  access: log4js.getLogger('access'),
  system: log4js.getLogger('system'),
  express: log4js.connectLogger(log4js.getLogger('access'), {
    level: log4js.levels.INFO
  })
};
