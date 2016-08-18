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
  return send(sessionId, 'POST', url, data);
}

function addUser(root, token, user) {
  return post(token, root + '/v1/users', user);
}

module.exports = {
  addUser: addUser
};
