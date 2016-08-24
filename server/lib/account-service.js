var request = require('request');

function send(token, method, url, data) {
  return new Promise((resolve, reject) => {
    var options = {
      method: method,
      url: url,
      headers: {
        'Authorization': token
      },
      form: data
    };
    request(options, function(e, response, body) {
      if (e || response.statusCode >= 400) {
        console.log(response.statusCode, 'account service: failed ' + method + ' ' + url);
        reject(e || response.statusCode);
      } else {
        resolve(JSON.parse(body));
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
    return obj.authToken;
  });
}

function addUser(root, token, user) {
  return post(token, root + '/1/users', user);
}

module.exports = {
  addUser: addUser,
  login: login
};
