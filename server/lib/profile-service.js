var request = require('request');
var uuid = require('uuid');

function send(token, method, url, data) {
  console.log(method, url, data);
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
        console.log(response ? response.statusCode : e, 'profile service: failed ' + method + ' ' + url);
        reject(e || response.statusCode);
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
    org: profile.organization,
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
  return get(token, root + '/1/profiles?userId=' + encodeURIComponent(userId)).then((people) => {
    if(people[0]) {
      return Promise.resolve(fixPerson(people[0]));
    }
    return Promise.resolve(null);
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
  return get(token, root + '/1/profiles?q=' + query);
}

module.exports = {
  getPerson: getPerson,
  getPersonByUserId: getPersonByUserId,
  addPerson: addPerson,
  search: search
};
