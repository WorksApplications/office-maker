var http = require( "http" );
var url = require( "url" );
var request = require('request');
var deepDiff = require('deep-diff');
var cp = require('child_process');
var assert = require('chai').assert;

describe('guest', function () {
  it('cannot access to edit api', function (done) {
    withServer(function(done) {
      var admin = user();
      var server = host('http://localhost:3000');
      test([
        server.send(admin, 'POST', '/api/v1/floor/1', {
        }, status(401)),
        server.send(admin, 'PUT', '/api/v1/image/1', {
        }, status(401)),
        server.send(admin, 'PUT', '/api/v1/floor/1/edit', {
        }, status(401)),
        server.send(admin, 'GET', '/api/v1/floor/1/edit', {
        }, status(401)),
        server.send(admin, 'GET', '/api/v1/floors?all=true', {
        }, status(401)),
        server.send(admin, 'GET', '/api/v1/floors', {
        }, exactJson([])),
      ], done);
    }, done);
  });
});

describe('admin', function () {
  it('can access to /api/v1/floor/:id/edit', function (done) {
    withServer(function(done) {
      var admin = user();
      var server = host('http://localhost:3000');
      test([
        login(server, admin, 'admin01', 'admin01'),
        server.send(admin, 'PUT', '/api/v1/floor/1/edit', {
          id: '1',
          name: 'F1'
        }, status(200)),
        server.send(admin, 'GET', '/api/v1/floor/1/edit', {
        }, status(200)),
        server.send(admin, 'GET', '/api/v1/floors?all=true', {
        }, status(200)),
      ], done);
    }, done);
  });
});

function login(server, user, id, pass) {
  return server.send(user, 'POST', '/api/v1/login', {
    id: id,
    pass: pass
  }, status(200));
}

function withServer(test, done) {
  var started = false;
  var server = cp.spawn('node', [ __dirname + '/server.js']);
  server.stdout.on('data', function (data) {
    // console.log(data.toString());
    try {
      started || test(function(e) {
        server.kill();
        done(e);
      });
    } catch(e) {
      server.kill();
      done(e);
    }
    started = true;
  });
  server.stderr.on('data', function (data) {
    console.error(data.toString());
  });
}

function exactJson(expect) {
  return function(error, response, body, done) {
    if(error) {
      done(response);
    } else {
      try {
        var actual = JSON.parse(body);
        if(deepDiff.diff(expect, actual)) {
          done(actual);
        } else {
          done();
        }
      } catch(e) {
        done('invalid JSON: ' + body);
      }
    }
  };
}
function status(code) {
  return function(error, response, body, done) {
    if(error) {
      done(error);
    } else if(response.statusCode !== code) {
      done(response.statusCode + ' ' + response.request.method + ' ' + response.request.href);
    } else {
      done();
    }
  };
}

function test(steps, done) {
  var tail = steps.concat();
  var head = tail.shift();
  if(head) {
    try {
      head(function(e) {
        if(e) {
          done(e);
        } else {
          test(tail, done);
        }
      });
    } catch(e) {
      done(e);
    }
  } else {
    done();
  }

}
function host(host) {
  return {
    send: function(user, method, path, form, asssertion) {
      return send(user, method, host + path, form, asssertion);
    }
  }
}

function send(user, method, url, form, asssertion) {
  return function(cb) {
    user.send(method, url, form, function(error, response, body) {
      (asssertion || status(200))(error, response, body, cb);
    });
  };
}

function user() {
  var cookie = '';
  var send = function(method, url, form, cb) {
    var options = {
      method: method,
      url: url,
      headers: {
        'User-Agent': 'request',
        'Cookie': cookie
      },
      form : form
    };
    request(options, function(error, response, body) {
      if(error) {
        cb(error);
      } else {
        if(response.headers["set-cookie"]) {
          cookie = response.headers["set-cookie"][0]
        }
        cb(error, response, body);
      }
    });
  };
  return {
    send: send,
    reset: function() {
      cookie = '';
    }
  };
}
