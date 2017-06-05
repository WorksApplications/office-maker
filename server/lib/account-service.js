var request = require('request');
var log = require('./log.js');

function send(token, method, url, data) {
  return new Promise((resolve, reject) => {
    var options = {
      method: method,
      url: url,
      headers: {
        'Authorization': 'JWT ' + token
      },
      body: data,
      json: true
    };
    request(options, function(e, response, body) {
      if (e || response.statusCode >= 400) {
        log.system.error(response.statusCode, 'account service: failed ' + method + ' ' + url);
        body && log.system.error(body.message);
        if (response && response.statusCode === 401) {
          reject(401);
        } else {
          reject(body ? body.message : e || response.statusCode);
        }
      } else {
        log.system.debug(response.statusCode, 'account service: success ' + method + ' ' + url);
        resolve(body);
      }
    });
  });
}

function get(token, url) {
  return send(token, 'GET', url);
}

function post(token, url, data) {
  return send(token, 'POST', url, data);
}

function login(root, userId, password) {
  return post('', root + '/1/authentication', {
    userId: userId,
    password: password
  }).then(obj => {
    return obj.accessToken;
  });
}

function addUser(root, token, user) {
  user.userId = user.id;
  user.password = user.pass;
  user.role = user.role.toUpperCase();
  return post(token, root + '/1/users', user);
}

function getAllAdmins(root, token, exclusiveStartKey) {
  var url = root + '/1/users' +
    (exclusiveStartKey ? '?exclusiveStartKey=' + exclusiveStartKey : '')
  return get(token, url).then((data) => {
    var users = data.users.map(user => {
      toMapUser(user);
      return user;
    }).filter(user => {
      return user.role === 'admin';
    });
    if (data.lastEvaluatedKey) {
      return getAllAdmins(root, token, data.lastEvaluatedKey).then((users2) => {
        return Promise.resolve(users.concat(users2));
      });
    } else {
      return Promise.resolve(users);
    }
  });
}

function toMapUser(user) {
  user.id = user.id || user.userId;
  user.role = user.role.toLowerCase();
  user.tenantId = '';
}

module.exports = {
  addUser: addUser,
  login: login,
  getAllAdmins: getAllAdmins,
  toMapUser: toMapUser
};
