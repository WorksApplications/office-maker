function send(callback, statusCode, data) {
  callback(null, {
    statusCode: statusCode,
    headers: {
      "Content-Type": "application/json"
    },
    body: data ? JSON.stringify(data) : ''
  });
}

module.exports = {
  send: send
};
