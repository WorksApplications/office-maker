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

describe('Profile Service', () => {
  var dbProcess = null;
  before(() => {
    return Promise.resolve();
  });
  beforeEach(() => {
    return Promise.resolve();
  });
  describe('GET /profiles', () => {
    it('returns 400 if q or userId does not exist', () => {
      var url = serviceRoot + '/profiles?limit=100';
      return send(mockAuth, 'GET', url).then(assertStatus(400));
    });
    it('returns 400 if order is invalid', () => {
      var url = serviceRoot + '/profiles?order=foo';
      return send(mockAuth, 'GET', url).then(assertStatus(400));
    });
    it('returns [] if no one matched by q', () => {
      var url = serviceRoot + '/profiles?q=hogehogehogehoge';
      return send(mockAuth, 'GET', url).then(res => {
        if (res.statusCode !== 200) {
          return Promise.reject('Unexpected statusCode: ' + res.statusCode);
        }
        if (res.body.profiles.length !== 0) {
          return Promise.reject('Unexpected profile count: ' + res.body.profiles.length);
        }
        return Promise.resolve();
      });
    });
    it('returns [] if no one matched by userId', () => {
      var url = serviceRoot + '/profiles?userId=notexist';
      return send(mockAuth, 'GET', url).then(res => {
        if (res.statusCode !== 200) {
          return Promise.reject('Unexpected statusCode: ' + res.statusCode);
        }
        if (res.body.profiles.length !== 0) {
          return Promise.reject('Unexpected profile count: ' + res.body.profiles.length);
        }
        return Promise.resolve();
      });
    });
  });
  describe('GET /profiles/{userId}', () => {
    it('returns 404 if profile does not exist', () => {
      var url = serviceRoot + '/profiles/notexist@example.com';
      return send(mockAuth, 'GET', url).then(assertStatus(404));
    });
    it('returns 200 if profile exists', () => {
      var url = serviceRoot + '/profiles/0001@example.com';
      return send(mockAuth, 'GET', url).then(res => {
        if (res.statusCode !== 200) {
          return Promise.reject('Unexpected statusCode: ' + res.statusCode);
        }
        if (!res.body.userId) {
          return Promise.reject('Unexpected profile: ' + res.body);
        }
        return Promise.resolve();
      });
    });
  });
  describe('PUT /profiles/{userId}', () => {
    it('returns 400 if body is invalid (userId required)', () => {
      var url = serviceRoot + '/profiles/0001@example.com';
      var data = {
        name: 'Test'
      };
      return send(mockAuth, 'PUT', url, data).then(assertStatus(400));
    });
    it('returns 400 if body is invalid (name required)', () => {
      var url = serviceRoot + '/profiles/0001@example.com';
      var data = {
        userId: '0001@example.com'
      };
      return send(mockAuth, 'PUT', url, data).then(assertStatus(400));
    });
    it('returns 200 if everything is ok', () => {
      var url = serviceRoot + '/profiles/0001@example.com';
      var data = {
        "userId": "0001@example.com",
        "name": "Test"
      };
      return send(mockAuth, 'PUT', url, data).then(assertStatus(200));
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
