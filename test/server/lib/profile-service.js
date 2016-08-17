var request = require('request');

function get(token, url) {
  return new Promise((resolve, reject) => {
    var options = {
      url: url,
      headers: {
        'Authorization': token
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

function fixPerson(person) {
  return {
    id: profile.id,
    tenantId: profile.tenantId,
    name: profile.name,
    empNo: profile.profileId,
    org: profile.organization,
    tel: profile.phones[0],
    mail: profile.emails[0],
    image: 'images/users/default.png'//TODO
  };
}

function getPerson(root, token, personId) {
  return get(token, root + '/v1/profiles/' + personId).then((person) => {
    return Promise.resolve(fixPerson(person));
  }).catch((e) => {
    if(e === 404) {
      return Promise.resolve(null);
    }
    return Promise.reject(e);
  });
}

function getPersonByUserId(token, userId) {
  return get(token, root + '/v1/profiles?userId=' + userId).then((people) => {
    if(people[0]) {
      return Promise.resolve(fixPerson(people[0]));
    }
    return Promise.resolve(null);
  });
}

function search(root, token, query) {
  return get(token, root + '/v1/profiles?q=' + query);
}

module.exports = {
  getPerson: getPerson,
  getPersonByUserId: getPersonByUserId,
  search: search
};
