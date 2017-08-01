var AWS = require('aws-sdk');
var options = require('./db-options.js');
var documentClient = new AWS.DynamoDB.DocumentClient(options);
var dynamoUtil = require('./dynamo-util.js');

function getAccount(userId) {
  return dynamoUtil.get(documentClient, {
    TableName: "accounts",
    Key: {
      userId: userId
    }
  }).then(data => {
    return Promise.resolve(data.Item);
  });
}

function putAccount(account) {
  profile = dynamoUtil.emptyToNull(account);
  return dynamoUtil.put(documentClient, {
    TableName: "accounts",
    Item: account
  });
}

function getTenant(ipAddress) {
  return dynamoUtil.get({
    TableName: "accounts_tenant_ip",
    Key: {
      ipAddress: ipAddress
    }
  }).then(data => {
    return Promise.resolve(data.Item ? data.Item.tenantId : null);
  });
}

module.exports = {
  getAccount: getAccount,
  putAccount: putAccount,
  getTenant: getTenant
};
