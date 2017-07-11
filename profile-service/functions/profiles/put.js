var AWS = require('aws-sdk');
var documentClient = new AWS.DynamoDB.DocumentClient();

exports.handler = (event, context, callback) => {
  documentClient.put({
    TableName: "profiles",
    Item: JSON.parse(event.body)
  }, function(e, data) {
    if (e) {
      callback(e);
      return;
    }
    callback(null, {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json"
      },
      body: ''
    });
  });
};
