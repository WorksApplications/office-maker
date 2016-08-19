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
        console.log(response.statusCode, 'profile service: failed GET ' + url);
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
  person.employeeId = person.empNo;
  person.cellPhone = person.tel;
  person.extensionPhone = person.tel;
  person.picture = person.image;
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
