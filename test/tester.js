var url = require( "url" );
var request = require('request');
var deepDiff = require('deep-diff');

function json(expect) {
  return function(error, response, body, done) {
    if(error) {
      done(response);
    } else {
      try {
        var actual = JSON.parse(body);
        var diff = deepDiff.diff(expect, actual)
        if(diff) {
          var invalid = false;
          for(var i = 0; i < diff.length; i++) {
            if(diff[i].kind !== 'N') {
              invalid = true;
              break;
            }
          }
          done(invalid ? actual : null);
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

function length(len) {
  return function(error, response, body, done) {
    if(error) {
      done(error);
    } else if(JSON.parse(body).length !== len) {
      done('actual length: ' + JSON.parse(body).length);
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
    send: function(user, method, path, form, assertion) {
      if(!assertion) {
        throw "too few arguments.";
      }
      return send(user, method, host + path, form, assertion);
    }
  }
}

function send(user, method, url, form, assertion) {
  return function(cb) {
    user.send(method, url, form, function(error, response, body) {
      (assertion || status(200))(error, response, body, cb);
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


module.exports = {
  json: json,
  status: status,
  test: test,
  host: host,
  send: send,
  user: user,
  length: length
};
