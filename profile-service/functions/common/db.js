var AWS = require('aws-sdk');
var options = process.argv.includes('--mock') ? {
  region: 'ap-northeast-1',
  endpoint: 'http://localhost:4569',
  // port: 4569
} : undefined;
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

module.exports = {
  getProfile: getProfile,
  putProfile: putProfile,
  deleteProfile: deleteProfile,
  scanProfile: scanProfile
};
