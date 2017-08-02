exports.handler = (event, context, callback) => {
  console.log(event, context);
  callback(null, {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
      "Access-Control-Allow-Origin": "*"
    },
    body: '{ "foo": "bar" }'
  });
};
