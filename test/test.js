var http = require( "http" );
var url = require( "url" );
var request = require('request');
var deepDiff = require('deep-diff');
var cp = require('child_process');
var assert = require('chai').assert;
var tester = require('./tester.js');

var status = tester.status;
var host = tester.host;
var test = tester.test;
var user = tester.user;
var length = tester.length;
var json = tester.json;

describe('guest', function () {
  it('cannot access to edit api', function (done) {
    withServer(function(done) {
      var admin = user();
      var server = host('http://localhost:3000');
      var floorId = '550e8400-e29b-41d4-a716-446655440000';
      test([
        server.send(admin, 'POST', `/api/v1/floor/${floorId}`, {
        }, status(401)),
        server.send(admin, 'PUT', `/api/v1/image/${floorId}`, {
        }, status(401)),
        server.send(admin, 'PUT', `/api/v1/floor/${floorId}/edit`, {
        }, status(401)),
        server.send(admin, 'GET', `/api/v1/floor/${floorId}/edit`, {
        }, status(401)),
        server.send(admin, 'GET', `/api/v1/floors?all=true`, {
        }, status(401)),
        server.send(admin, 'GET', `/api/v1/floors`, {
        }, length(0)),
      ], done);
    }, done);
  });
});

describe('admin', function () {
  it('can access to /api/v1/floor/:id/edit', function (done) {
    withServer(function(done) {
      var admin = user();
      var server = host('http://localhost:3000');
      var floorId = '550e8400-e29b-41d4-a716-446655440000';
      test([
        login(server, admin, 'admin01', 'admin01'),
        server.send(admin, 'PUT', `/api/v1/floor/${floorId}/edit`, {
          id: floorId,
          name: 'F1'
        }, status(200)),
        server.send(admin, 'GET', `/api/v1/floor/${floorId}/edit`, {
        }, status(200)),
        server.send(admin, 'GET', `/api/v1/floors?all=true`, {
        }, status(200)),
      ], done);
    }, done);
  });
});

describe('private floor', function () {
  it('cannot be accessed by guest', function (done) {
    withServer(function(done) {
      var admin = user();
      var guest = user();
      var server = host('http://localhost:3000');
      var floorId = '550e8400-e29b-41d4-a716-446655440000';
      test([
        login(server, admin, 'admin01', 'admin01'),
        login(server, guest, 'user01', 'user01'),
        server.send(admin, 'PUT', `/api/v1/floor/${floorId}/edit`, {
          id: floorId,
          name: 'F1'
        }, status(200)),
        server.send(admin, 'GET', `/api/v1/floors`, {
        }, length(0)),
        server.send(admin, 'GET', `/api/v1/floors?all=true`, {
        }, length(1)),
        server.send(guest, 'GET', `/api/v1/floors`, {
        }, length(0)),
        server.send(admin, 'GET', `/api/v1/floor/${floorId}`, {
        }, status(404)),
        server.send(guest, 'GET', `/api/v1/floor/${floorId}`, {
        }, status(404)),
        server.send(admin, 'POST', `/api/v1/floor/${floorId}`, {
          id: floorId,
          name: 'F2'
        }, status(200)),
        server.send(guest, 'GET', `/api/v1/floors`, {
        }, length(1)),
        server.send(guest, 'GET', `/api/v1/floor/${floorId}`, {
        }, json({
          id: floorId,
          name: 'F2'
        })),
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
  var server = cp.spawn('node', [ __dirname + '/server/server.js']);
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
