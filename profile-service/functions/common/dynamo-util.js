function exec(method) {
  return function(dynamoDbOrDocumentClient, params) {
    return new Promise((resolve, reject) => {
      dynamoDbOrDocumentClient[method](params, function(e, data) {
        if (e) {
          reject(e);
        } else {
          resolve(data);
        }
      });
    });
  };
}

function emptyToNull(object) {
  object = Object.assign({}, object);
  Object.keys(object).forEach(key => {
    if (object[key] === "" || typeof object[key] === 'undefined') {
      object[key] = null;
    }
  });
  return object;
}

module.exports = {
  emptyToNull: emptyToNull,
  get: exec('get'),
  put: exec('put'),
  delete: exec('delete'),
  scan: exec('scan'),
  batchGet: exec('batchGet'),
  query: exec('query'),
  createTable: exec('createTable')
};
