var request = require('request');
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

function get(token, url, exclusiveStartKey) {
  return send(token, 'GET', url, null, exclusiveStartKey);
}

function post(token, url, data) {
  return send(token, 'POST', url, data);
}

function put(token, url, data) {
  return send(token, 'PUT', url, data);
}

function fixPerson(profile) {
  return {
    id: profile.userId,
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

function getPeopleByOrg(root, token, org, exclusiveStartKey) {
  var url = root + '/1/profiles?q=' + encodeURIComponent(org)
    + (exclusiveStartKey ? '&exclusiveStartKey=' + exclusiveStartKey : '')
  return get(token, url).then((data) => {
    var people = data.profiles.map(fixPerson)
    if(data.lastEvaluatedKey) {
      return getPeopleByOrg(root, token, org, data.lastEvaluatedKey).then((people2) => {
        return Promise.resolve(people.concat(people2));
      });
    } else {
      return Promise.resolve(people);
    }
  });
}

function savePerson(root, token, person) {
  person.userId = person.mail;
  person.employeeId = person.empNo;
  person.ruby = '' || null;
  person.cellPhone = person.tel || null;
  person.extensionPhone = person.tel || null;
  person.picture = person.image || null;
  person.organization = person.org || null;//TODO
  person.post = '' || null;
  person.rank = '' || null;
  person.workspace = '' || null;
  return put(token, root + '/1/profiles/' + encodeURIComponent(person.userId), person);
}

function search(root, token, query) {
  return get(token, root + '/1/profiles?q=' + encodeURIComponent(query)).then((data) => {
    return Promise.resolve(data.profiles.map(fixPerson));
  });
}

module.exports = {
  getPerson: getPerson,
  getPeopleByOrg: getPeopleByOrg,
  savePerson: savePerson,
  search: search
};
