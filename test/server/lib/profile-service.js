var request = require('request');

function get(tenentId, url) {
  return new Promise((resolve, reject) => {
    request(url, function(e, response, body) {
      if (e || response.statusCode >= 400) {
        reject(e || response.statusCode);
      } else {
        resolve(JSON.parse(body));
      }
    });
  });
}

function getPerson(root, tenentId, personId) {
  return get(tenentId, root + '/' + personId).catch((e) => {
    if(e === 404) {
      return Promise.resolve(null);
    }
    return Promise.reject(e);
  });
}

function search(root, tenentId, query) {
  return get(tenentId, root + '/search?q=' + query);
}

module.exports = {
  getPerson: getPerson,
  search: search
};
