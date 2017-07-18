function exec(method) {
  return function(documentClient, params) {
    return new Promise((resolve, reject) => {
      documentClient[method](params, function(e, data) {
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
  scan: exec('scan')
};
