var AWS = require('aws-sdk');
var options = require('./db-options.js');
var documentClient = new AWS.DynamoDB.DocumentClient(options);
var dynamoUtil = require('./dynamo-util.js');

function getProfile(userId) {
  return dynamoUtil.get(documentClient, {
    TableName: "profiles",
    Key: {
      userId: userId
    }
  }).then(data => {
    return Promise.resolve(data.Item);
  });
}

function putProfile(profile) {
  return dynamoUtil.put(documentClient, {
    TableName: "profiles",
    Item: profile
  });
}

function deleteProfile(userId) {
  return dynamoUtil.delete(documentClient, {
    TableName: "profiles",
    Key: {
      userId: userId
    }
  });
}

function scanProfile(limit, exclusiveStartKey) {
  return dynamoUtil.scan(documentClient, {
    TableName: "profiles",
    Limit: limit,
    ExclusiveStartKey: exclusiveStartKey ? JSON.parse(exclusiveStartKey) : undefined
  }).then(data => {
    return Promise.resolve({
      profiles: data.Items,
      lastEvaluatedKey: JSON.stringify(data.LastEvaluatedKey)
    });
  });
};

function findProfileByUserIds(userIds, limit, exclusiveStartKey) {
  return dynamoUtil.batchGet(documentClient, {
    RequestItems: {
      'profiles': {
        Keys: userIds.map(userId => {
          return {
            userId: userId
          };
        })
      }
    },
    Limit: limit,
    ExclusiveStartKey: exclusiveStartKey ? JSON.parse(exclusiveStartKey) : undefined
  }).then(data => {
    return Promise.resolve({
      profiles: data.Responses['profiles'].map(response => {
        return response.Item;
      }),
      lastEvaluatedKey: JSON.stringify(data.LastEvaluatedKey)
    });
  });
}

function varyCase(s) {
  var dict = {};
  dict[s] = true;
  dict[s.toUpperCase()] = true;
  dict[s.toLowerCase()] = true;
  return Object.keys(dict);
}

function findProfileByQuery(q, limit, exclusiveStartKey) {
  return dynamoUtil.scan(documentClient, {
    TableName: 'profiles',
    FilterExpression: 'begins_with(#name, :name)' +
      ' or contains(#name, :nameWithSpace)' +
      ' or begins_with(ruby, :ruby)' +
      ' or contains(ruby, :rubyWithSpace)' +
      ' or begins_with(mail, :mail)' +
      ' or employeeId = :employeeId',
    ExpressionAttributeNames: {
      "#name": 'name' // because `name` is a reserved keyword
    },
    ExpressionAttributeValues: {
      ":mail": q,
      ":name": q,
      ":nameWithSpace": ' ' + q,
      ":ruby": q,
      ":rubyWithSpace": ' ' + q,
      ":employeeId": q
    },
    Limit: limit,
    ExclusiveStartKey: exclusiveStartKey ? JSON.parse(exclusiveStartKey) : undefined
  }).then(data => {
    return Promise.resolve({
      profiles: data.Items,
      lastEvaluatedKey: JSON.stringify(data.LastEvaluatedKey)
    });
  });
}

module.exports = {
  getProfile: getProfile,
  putProfile: putProfile,
  deleteProfile: deleteProfile,
  scanProfile: scanProfile,
  findProfileByUserIds: findProfileByUserIds,
  findProfileByQuery: findProfileByQuery
};
