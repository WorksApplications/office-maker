var AWS = require('aws-sdk');
var documentClient = new AWS.DynamoDB.DocumentClient();

exports.handler = (event, context, callback) => {
  var params = event.queryStringParameters;
  params.limit = +params.limit || undefined;
  params.exclusiveStartKey = params.exclusiveStartKey ? JSON.parse(event.exclusiveStartKey) : undefined;
  documentClient.scan({
    TableName: "profiles",
    Limit: event.limit,
    ExclusiveStartKey: event.exclusiveStartKey
  }, function(e, data) {
    if (e) {
      callback(e);
      return;
    }
    var result = {
      profiles: data.Items,
      lastEvaluatedKey: JSON.stringify(data.LastEvaluatedKey)
    };
    callback(null, {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(result)
    });
  });
};
