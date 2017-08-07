process.env.EXEC_MODE = 'test';

var childProcess = require('child_process');
var fs = require('fs');
var assert = require('assert');
var request = require('request');
var mockAuth = require('./mockAuth.js');

var project = JSON.parse(fs.readFileSync('./project.json', 'utf8'));
var region = project.region;
var restApiId = project.restApiId;
var stageName = 'dev';
var serviceRoot = `https://${restApiId}.execute-api.${region}.amazonaws.com/${stageName}`;


describe('Profile Service', () => {
  var dbProcess = null;
  before(() => {
    var url = serviceRoot + '/profiles/test@example.com';
    return send(mockAuth.admin, 'PUT', url, {
      "userId": "test@example.com",
      "name": "Test"
    });
  });
  after(() => {
    var url = serviceRoot + '/profiles/test@example.com';
    // return send(mockAuth.admin, 'DELETE', url);
    return Promise.resolve();
  });
  beforeEach(() => {
    return Promise.resolve();
  });
  describe('GET /profiles', () => {
    it('returns 401 if not authenticated', () => {
      var url = serviceRoot + '/profiles?q=hoge';
      return send(null, 'GET', url).then(assertStatus(401));
    });
    it('returns 401 if not authenticated', () => {
      var url = serviceRoot + '/profiles?q=hoge';
      return send('Bearer hoge', 'GET', url).then(assertStatus(401));
    });
    it('returns 400 if q or userId does not exist', () => {
      var url = serviceRoot + '/profiles?limit=100';
      return send(mockAuth.officeMaker, 'GET', url).then(assertStatus(400));
    });
    it('returns 400 if order is invalid', () => {
      var url = serviceRoot + '/profiles?order=foo';
      return send(mockAuth.officeMaker, 'GET', url).then(assertStatus(400));
    });
    it('returns [] if no one matched by q', () => {
      var url = serviceRoot + '/profiles?q=hogehogehogehoge';
      return send(mockAuth.officeMaker, 'GET', url).then(res => {
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
      return send(mockAuth.officeMaker, 'GET', url).then(res => {
        if (res.statusCode !== 200) {
          return Promise.reject('Unexpected statusCode: ' + res.statusCode);
        }
        if (res.body.profiles.length !== 0) {
          return Promise.reject('Unexpected profile count: ' + res.body.profiles.length);
        }
        return Promise.resolve();
      });
    });
    it('returns [User] if someone matched by q', () => {
      var url = serviceRoot + '/profiles?q=Tes';
      return send(mockAuth.officeMaker, 'GET', url).then(res => {
        if (res.statusCode !== 200) {
          return Promise.reject('Unexpected statusCode: ' + res.statusCode);
        }
        if (res.body.profiles.length <= 0) {
          return Promise.reject('Unexpected profile count: ' + res.body.profiles.length);
        }
        return Promise.resolve();
      });
    });
    it('returns [User] if someone matched by userId', () => {
      var url = serviceRoot + '/profiles?userId=test@example.com';
      return send(mockAuth.officeMaker, 'GET', url).then(res => {
        if (res.statusCode !== 200) {
          return Promise.reject('Unexpected statusCode: ' + res.statusCode);
        }
        if (res.body.profiles.length !== 1) {
          return Promise.reject('Unexpected profile count: ' + res.body.profiles.length);
        }
        return Promise.resolve();
      });
    });
  });
  describe('GET /profiles/{userId}', () => {
    it('returns 401 if not authenticated', () => {
      var url = serviceRoot + '/profiles/not_exist@example.com';
      return send(null, 'GET', url).then(assertStatus(401));
    });
    it('returns 401 if not authenticated', () => {
      var url = serviceRoot + '/profiles/not_exist@example.com';
      return send('Bearer hoge', 'GET', url).then(assertStatus(401));
    });
    it('returns 404 if profile does not exist', () => {
      var url = serviceRoot + '/profiles/notexist@example.com';
      return send(mockAuth.officeMaker, 'GET', url).then(assertStatus(404));
    });
    it('returns 200 if profile exists', () => {
      var url = serviceRoot + '/profiles/test@example.com';
      return send(mockAuth.officeMaker, 'GET', url).then(res => {
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
    it('returns 401 if unauthorized', () => {
      var url = serviceRoot + '/profiles/not_exist@example.com';
      var data = {
        "userId": "dummy@example.com",
        "name": "Test"
      };
      return send('Bearer hogehoge', 'PUT', url, data).then(assertStatus(401));
    });
    it('returns 403 if unauthorized', () => {
      var url = serviceRoot + '/profiles/not_exist@example.com';
      var data = {
        "userId": "dummy@example.com",
        "name": "Test"
      };
      return send(mockAuth.officeMaker, 'PUT', url, data).then(assertStatus(403));
    });
    it('returns 400 if body is invalid (userId required)', () => {
      var url = serviceRoot + '/profiles/test@example.com';
      var data = {
        name: 'Test'
      };
      return send(mockAuth.admin, 'PUT', url, data).then(assertStatus(400));
    });
    it('returns 400 if body is invalid (name required)', () => {
      var url = serviceRoot + '/profiles/test@example.com';
      var data = {
        userId: 'test@example.com'
      };
      return send(mockAuth.admin, 'PUT', url, data).then(assertStatus(400));
    });
    it('returns 200 if everything is ok', () => {
      var url = serviceRoot + '/profiles/test@example.com';
      var data = {
        "userId": "test@example.com",
        "name": "Test"
      };
      return send(mockAuth.admin, 'PUT', url, data).then(assertStatus(200));
    });
  });
  describe('DELETE /profiles/{userId}', () => {
    it('returns 401 if unauthorized', () => {
      var url = serviceRoot + '/profiles/not_exist@example.com';
      return send('Bearer hogehoge', 'DELETE', url).then(assertStatus(401));
    });
    it('returns 403 if role is GENERAL', () => {
      var url = serviceRoot + '/profiles/not_exist@example.com';
      return send(mockAuth.officeMaker, 'DELETE', url).then(assertStatus(403));
    });
    it('returns 200 if used does not exist', () => {
      var url = serviceRoot + '/profiles/not_exist@example.com';
      return send(mockAuth.admin, 'DELETE', url).then(assertStatus(200));
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
      if (bodyStr && bodyStr.length > 500) {
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
