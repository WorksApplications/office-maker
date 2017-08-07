var AWS = require('aws-sdk');
var options = require('./db-options.js');
var documentClient = new AWS.DynamoDB.DocumentClient(options);
var dynamoUtil = require('./dynamo-util.js');
var searchHelper = require('./search-helper.js');

function getProfile(userId) {
  return dynamoUtil.get(documentClient, {
    TableName: "profiles",
    Key: {
      userId: userId
    }
  }).then(data => {
    return Promise.resolve(deleteNormalizedFields(data.Item));
  });
}

function putProfile(profile) {
  profile = Object.assign({}, profile);
  profile.normalizedName = searchHelper.normalize(profile.name);
  profile.normalizedRuby = searchHelper.normalize(profile.ruby);
  profile.normalizedPost = searchHelper.normalize(profile.post);
  profile.normalizedOrganization = searchHelper.normalize(profile.organization);
  profile = dynamoUtil.emptyToNull(profile);
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
      profiles: data.Responses['profiles'].map(deleteNormalizedFields),
      lastEvaluatedKey: JSON.stringify(data.LastEvaluatedKey)
    });
  });
}

function deleteNormalizedFields(profile) {
  if (!profile) {
    return null;
  }
  profile = Object.assign({}, profile);
  Object.keys(profile).forEach(key => {
    if (key.indexOf('normalized') === 0) {
      delete profile[key];
    }
  });
  return profile;
}

function findProfileByQuery(q, limit, exclusiveStartKey) {
  if (q[0] === '"' && q[q.length - 1] === '"') {
    q = q.substring(1, q.length - 1);
  }
  var normalizedQ = searchHelper.normalize(q);
  var search = dynamoUtil.scan(documentClient, {
    TableName: 'profiles',
    FilterExpression: 'begins_with(normalizedName, :normalizedName)' +
      ' or contains(normalizedName, :normalizedNameWithSpace)' +
      ' or begins_with(normalizedRuby, :normalizedRuby)' +
      ' or contains(normalizedRuby, :normalizedRubyWithSpace)' +
      ' or begins_with(mail, :mail)' +
      ' or employeeId = :employeeId' +
      ' or contains(normalizedPost, :normalizedPost)',
    ExpressionAttributeValues: {
      ":mail": q,
      ":normalizedName": normalizedQ,
      ":normalizedNameWithSpace": ' ' + normalizedQ,
      ":normalizedRuby": normalizedQ,
      ":normalizedRubyWithSpace": ' ' + normalizedQ,
      ":employeeId": q,
      ":normalizedPost": normalizedQ
    },
    Limit: limit,
    ExclusiveStartKey: exclusiveStartKey ? JSON.parse(exclusiveStartKey) : undefined
  });

  return search.then(data => {
    return Promise.resolve({
      profiles: data.Items.map(deleteNormalizedFields),
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
