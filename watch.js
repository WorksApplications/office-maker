const cp = require('child_process');
const watch = require('watch');
const path = require('path');
const slash = require('slash');
const minimatch = require('minimatch');

var runServer = !process.argv.filter(a => {
  return a == '--no-server'
}).length;
var debugMode = process.argv.filter(a => {
  return a == '--debug'
}).length;
var server = null;

var queued = {
  build: false,
  server: false
};

function taskBuild(cb) {
  if (queued.build) {
    queued.build = false;
    // console.log('build start\n');
    var args = ['build.sh'];
    if (debugMode) {
      args.push('--debug');
    }
    var sh = cp.spawn('sh', args, {
      stdio: 'inherit'
    });
    sh.on('close', cb);
  } else {
    cb();
  }
}

function taskServer(cb) {
  if (runServer && queued.server) {
    queued.server = false;
    server && server.kill();
    server = cp.spawn('node', ['server/server'], {
      stdio: 'inherit'
    });
    cb();
  } else {
    cb();
  }
}

function run() {
  taskBuild(() => {
    taskServer(() => {
      setTimeout(run, 300);
    });
  });
}

function schedule(type, stat) {
  queued[type] = true;
}
watch.createMonitor('src', (monitor) => {
  monitor.on("created", schedule.bind(null, 'build'));
  monitor.on("changed", schedule.bind(null, 'build'));
  monitor.on("removed", schedule.bind(null, 'build'));
});

watch.createMonitor('server', {
  filter: function(file) {
    return !file.includes('public') && !file.includes('node_modules');
  }
}, (monitor) => {
  monitor.on("created", schedule.bind(null, 'server'));
  monitor.on("changed", schedule.bind(null, 'server'));
  monitor.on("removed", schedule.bind(null, 'server'));
});

schedule('build');
schedule('server');
run();
