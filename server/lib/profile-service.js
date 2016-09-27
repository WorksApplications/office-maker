var request = require('request');
var uuid = require('uuid');
var log = require('./log.js');

function send(token, method, url, data) {
  log.system.debug(method, url);
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
        log.system.error(response ? response.statusCode : e, 'profile service: failed ' + method + ' ' + url);
        body && log.system.error(body.message);
        reject(body ? body.message : e || response.statusCode);
      } else {
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

function fixPerson(profile) {
  return {
    id: profile.id,
    tenantId: profile.tenantId,
    name: profile.name,
    empNo: profile.employeeId,
    org: profile.post || '',//TODO
    tel: profile.cellPhone || profile.extensionPhone,
    mail: profile.mail,
    image: profile.picture
  };
}

function getPerson(root, token, personId) {
  return get(token, root + '/1/profiles/' + personId).then((person) => {
    return Promise.resolve(fixPerson(person));
  }).catch((e) => {
    if(e === 404) {
      return Promise.resolve(null);
    }
    return Promise.reject(e);
  });
}

function getPersonByUserId(root, token, userId) {
  return get(token, root + '/1/profiles?userId=' + encodeURIComponent(userId)).then((data) => {
    if(data.profiles[0]) {
      return Promise.resolve(fixPerson(data.profiles[0]));
    }
    return Promise.resolve(null);
  });
}

function getPeopleByOrg(root, token, org) {
  return get(token, root + '/1/profiles?organization=' + encodeURIComponent(org)).then((data) => {
    return Promise.resolve(data.profiles.map(fixPerson));
  });
}

function addPerson(root, token, person) {
  person.id = uuid.v4();
  person.userId = person.mail;
  person.employeeId = person.empNo;
  person.ruby = '' || null;
  person.cellPhone = person.tel || null;
  person.extensionPhone = person.tel || null;
  person.picture = person.image || null;
  person.organization = person.org || null;
  person.post = '' || null;
  person.rank = '' || null;
  person.workspace = '' || null;
  return post(token, root + '/1/profiles', person);
}

function search(root, token, query) {
  return get(token, root + '/1/profiles?q=' + encodeURIComponent(query)).then((data) => {
    return Promise.resolve(data.profiles.map(fixPerson));
  });
}

module.exports = {
  getPerson: getPerson,
  getPersonByUserId: getPersonByUserId,
  getPeopleByOrg: getPeopleByOrg,
  addPerson: addPerson,
  search: search
};
