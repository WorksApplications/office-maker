var request = require('request');

function get(sessionId, url) {
  return new Promise((resolve, reject) => {
    var options = {
      url: url,
      headers: {
        'Set-Cookie': sessionId
      }
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

function whoami(root, sessionId) {
  return get(sessionId, root + '/v1/authenticate').then((user) => {
    var fixedUser = {
      id: user.userId,
      tenantId: user.tenantId,
      role: 'admin'
    };
    return Promise.resolve(fixedUser);
  }).catch((e) => {
    if(e === 404) {
      return Promise.resolve(null);
    }
    return Promise.reject(e);
  });
}

module.exports = {
  whoami: whoami
};
