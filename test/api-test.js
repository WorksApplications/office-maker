var http = require( "http" );
var url = require( "url" );
var request = require('request');
var deepDiff = require('deep-diff');
var cp = require('child_process');

var testCase = withServer(function(done) {
  var admin = user();
  var server = host('http://localhost:3000');
  test([
    server.send(admin, 'POST', '/api/v1/login', {
      id: 'admin01',
      pass: 'admin01'
    }, noError),
    server.send(admin, 'GET', '/api/v1/floors', {
    }, exactJson([])),
  ], done);
});

testCase(function(e) {
  if(e) {
    console.log('error')
    console.log(e);
  }
  console.log('done!');
});

function withServer(test) {
  return function(done) {
    var server = cp.spawn('node', ['test/server']);
    server.stdout.on('data', function (data) {
      test(function(e) {
        server.kill();
        done(e);
      });
    });
  };
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
        done(e);
      }
    }

  };
}
function noError(error, response, body, done) {
  if(error) {
    done(response);
  } else {
    done();
  }
}

function ignore(error, response, body, done) {
  done();
}

function test(steps, done) {
  var tail = steps.concat();
  var head = tail.pop();
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
      send(user, method, host + path, form, asssertion);
    }
  }
}
function send(user, method, url, form, asssertion) {
  return function(cb) {
    user.send(method, url, form, function(error, response, body) {
      (asssertion || ignore)(error, response, body, cb);
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
      cookie = response.headers["set-cookie"];
      cb(error, response, body);
    });
  };
  return {
    send: send,
    reset: function() {
      cookie = '';
    }
  };
}
