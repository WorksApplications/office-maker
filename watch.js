const cp = require('child_process');
const watch = require('watch');
const path = require('path');
const slash = require('slash');
const minimatch = require('minimatch');


var server = null;

var queued = {
  build: false,
  server: false
};
function taskBuild(cb) {
  if(queued.build) {
    queued.build = false;
    // console.log('build start\n');
    var sh = cp.spawn('sh', ['build.sh'], {stdio: 'inherit'});
    sh.on('close', cb);
  } else {
    cb();
  }
}
function taskServer(cb) {
  if(queued.server) {
    queued.server = false;
    server && server.kill();
    server = cp.spawn('node', ['test/server'], {stdio: 'inherit'});
    cb();
  } else {
    cb();
  }
}
function run() {
  taskBuild(function() {
    taskServer(function() {
      setTimeout(run, 300);
    });
  });
}

function schedule(type, stat) {
  queued[type] = true;
}
watch.createMonitor('src', function (monitor) {
  monitor.on("created", schedule.bind(null, 'build'));
  monitor.on("changed", schedule.bind(null, 'build'));
  monitor.on("removed", schedule.bind(null, 'build'));
});

watch.createMonitor('test', {
  filter: function(stat) {
    return minimatch(slash(stat), 'test/server.js') ||
           minimatch(slash(stat), 'test/db.js') ||
           minimatch(slash(stat), 'test/db2.js');
  }
}, function (monitor) {
  monitor.on("created", schedule.bind(null, 'server'));
  monitor.on("changed", schedule.bind(null, 'server'));
  monitor.on("removed", schedule.bind(null, 'server'));
});

schedule('build');
schedule('server');
run();
