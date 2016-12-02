var request = require('request');
var log = require('./log.js');

function send(token, method, url, data) {
  return new Promise((resolve, reject) => {
    var options = {
      method: method,
      url: url,
      headers: {
        'Authorization': token ? 'JWT ' + token : ''
      },
      body: data,
      json: true
    };
    request(options, function(e, response, body) {
      if (e || response.statusCode >= 400) {
        log.system.error(response ? response.statusCode : e, 'profile service: failed ' + method + ' ' + url);
        body && body.message && log.system.error(body.message);
        if(response.statusCode === 401) {
          reject(401);
        } else {
          reject(body ? body.message : e || response.statusCode);
        }
      } else {
        log.system.debug(response.statusCode, 'profile service: success ' + method + ' ' + url);
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
    post: profile.post || '',//TODO
    tel: profile.cellPhone || profile.extensionPhone,
    mail: profile.mail,
    image: profile.picture || ''//TODO or default.png
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

function getPeopleByPost(root, token, post, exclusiveStartKey) {
  var url = root + '/1/profiles?q=' + encodeURIComponent(post)
    + (exclusiveStartKey ? '&exclusiveStartKey=' + exclusiveStartKey : '')
  return get(token, url).then((data) => {
    var people = data.profiles.map(fixPerson)
    if(data.lastEvaluatedKey) {
      return getPeopleByPost(root, token, post, data.lastEvaluatedKey).then((people2) => {
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
  person.ruby = person.ruby || null;
  person.cellPhone = person.tel || null;
  person.extensionPhone = person.tel || null;
  person.picture = person.image || null;
  person.organization = person.organization || null;//TODO
  person.post = person.post || null;
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
  getPeopleByPost: getPeopleByPost,
  savePerson: savePerson,
  search: search
};
