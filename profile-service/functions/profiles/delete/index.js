var AWS = require('aws-sdk');
var documentClient = new AWS.DynamoDB.DocumentClient();

exports.handler = (event, context, callback) => {
  documentClient.delete({
    TableName: "profiles",
    Key: {
      userId: event.pathParameters.userId
    }
  }, function(e, data) {
    if (e) {
      callback(e);
      return;
    }
    callback(null, {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json'
      },
      body: ''
    });
  });
};
