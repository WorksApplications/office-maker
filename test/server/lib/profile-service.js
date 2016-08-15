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

function getPerson(root, sessionId, personId) {
  return get(sessionId, root + '/v1/profiles/' + personId).then((person) => {
    var fixedPerson = {
      id: profile.id,
      tenantId: profile.tenantId,
      name: profile.name,
      empNo: profile.profileId,
      org: profile.organization,
      tel: profile.phones[0],
      mail: profile.emails[0],
      image: 'images/users/default.png'//TODO
    };
    return Promise.resolve(fixedPerson);
  }).catch((e) => {
    if(e === 404) {
      return Promise.resolve(null);
    }
    return Promise.reject(e);
  });
}

function search(root, sessionId, query) {
  return get(sessionId, root + '/v1/profiles?q=' + query);
}

module.exports = {
  getPerson: getPerson,
  search: search
};
