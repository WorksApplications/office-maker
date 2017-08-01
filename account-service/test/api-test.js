process.env.EXEC_MODE = 'test';

var childProcess = require('child_process');
var fs = require('fs');
var assert = require('assert');
var request = require('request');

var project = JSON.parse(fs.readFileSync('./project.json', 'utf8'));
var region = project.region;
var restApiId = project.restApiId;
var stageName = 'dev';
var serviceRoot = `https://${restApiId}.execute-api.${region}.amazonaws.com/${stageName}`;
var mockAuth = 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiQURNSU4iLCJ1c2VySWQiOiJtb2NrQGV4YW1wbGUuY29tIiwiaWF0IjoxNDk4NzI2NzAwfQ.H03xsyZJSAdKFsBf6CMCZhnmaUOh9HK0Dn8ty2rimmU';

describe('Accounts Service', () => {
  var dbProcess = null;
  before(() => {
    return Promise.resolve();
  });
  beforeEach(() => {
    return Promise.resolve();
  });
  describe('POST /authentication', () => {
    it('returns 400 if either userId or password does not exist', () => {
      var url = serviceRoot + '/authentication';
      return send(null, 'POST', url, {
        userId: 'foo'
      }).then(assertStatus(400));
    });
    it('returns 400 if either userId or password does not exist', () => {
      var url = serviceRoot + '/authentication';
      return send(null, 'POST', url, {
        password: 'bar'
      }).then(assertStatus(400));
    });
    it('returns 401 if authentication fails', () => {
      var url = serviceRoot + '/authentication';
      return send(null, 'POST', url, {
        userId: 'foo',
        password: 'bar'
      }).then(assertStatus(401));
    });
  });
});

function send(authorization, method, url, data) {
  return new Promise((resolve, reject) => {
    var options = {
      method: method,
      url: url,
      headers: {
        'Authorization': authorization || ''
      },
      body: data || undefined,
      json: true
    };
    request(options, (e, response) => {
      if (e) {
        reject(e);
      } else {
        resolve(response);
      }
    });
  });
}



function assertStatus(expect) {
  return res => {
    if (res.statusCode !== expect) {
      var bodyStr = JSON.stringify(res.body);
      if (bodyStr.length > 500) {
        bodyStr = bodyStr.substring(0, 500);
        bodyStr = bodyStr + '...';
      }
      res.body = bodyStr;
      return Promise.reject(`Expected statusCode ${expect} but got ${res.statusCode}: ${JSON.stringify(res)}`);
    }
    return Promise.resolve();
  };
}

function reducePromises(promises) {
  return promises.reduce((prev, toPromise) => {
    return prev.then(toPromise);
  }, Promise.resolve());
}

function delay(time) {
  return new Promise((resolve, reject) => {
    setTimeout(resolve, time);
  });
}
