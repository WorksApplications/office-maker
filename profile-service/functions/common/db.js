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
  var start = Date.now();
  return search.then(data => {
    var profiles = data.Items.map(deleteNormalizedFields);
    console.log('got ' + profiles.length, 'took ' + (Date.now() - start) + 'ms');
    return Promise.resolve({
      profiles: profiles,
      lastEvaluatedKey: JSON.stringify(data.LastEvaluatedKey)
    });
  });
}

function findProfileByQueryOpt(q, limit, exclusiveStartKey, previousProfiles) {
  previousProfiles = previousProfiles || [];
  return findProfileByQuery(q, null, exclusiveStartKey).then(res => {
    var profiles = previousProfiles.concat(res.profiles);
    if (limit && profiles.length >= limit) {
      profiles.length = limit;
      var lastProfile = profiles[limit - 1];
      if (lastProfile) {
        return Promise.resolve({
          profiles: profiles,
          lastEvaluatedKey: JSON.stringify({
            userId: lastProfile.userId
          })
        });
      } else {
        return Promise.resolve({
          profiles: profiles
        });
      }
    } else if (res.lastEvaluatedKey) {
      return findProfileByQueryOpt(q, limit, res.lastEvaluatedKey, profiles);
    } else {
      return Promise.resolve({
        profiles: profiles
      });
    }
  });
}

module.exports = {
  getProfile: getProfile,
  putProfile: putProfile,
  deleteProfile: deleteProfile,
  scanProfile: scanProfile,
  findProfileByUserIds: findProfileByUserIds,
  findProfileByQuery: findProfileByQueryOpt
};
