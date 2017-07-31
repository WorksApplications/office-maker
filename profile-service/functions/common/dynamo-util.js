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

module.exports = {
  get: exec('get'),
  put: exec('put'),
  delete: exec('delete'),
  scan: exec('scan'),
  batchGet: exec('batchGet'),
  query: exec('query'),
  createTable: exec('createTable')
};
