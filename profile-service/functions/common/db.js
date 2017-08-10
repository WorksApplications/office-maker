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

function convertProfileBeforeSave(profile) {
  profile = Object.assign({}, profile);

  var normalizedName = searchHelper.normalize(profile.name);
  var normalizedNameArray = normalizedName.split(' ');
  profile.normalizedName = normalizedName;
  profile.normalizedName1 = normalizedNameArray[0] || '???';
  profile.normalizedName2 = normalizedNameArray[normalizedNameArray.length - 1] || '???';

  var normalizedRuby = searchHelper.normalize(profile.ruby);
  var normalizedRubyArray = normalizedRuby.split(' ');
  profile.normalizedRuby = normalizedRuby;
  profile.normalizedRuby1 = normalizedRubyArray[0] || '???';
  profile.normalizedRuby2 = normalizedRubyArray[normalizedRubyArray.length - 1] || '???';

  profile.employeeId = profile.employeeId || '???';
  profile.mail = profile.mail || '???';
  profile.normalizedMailBeforeAt = (profile.mail || '').split('@')[0] || '???';
  profile.normalizedPost = searchHelper.normalize(profile.post) || '???';
  profile.normalizedOrganization = searchHelper.normalize(profile.organization) || '???';
  return profile;
}

function putProfile(profile) {
  profile = convertProfileBeforeSave(profile);
  profile = dynamoUtil.emptyToNull(profile);

  return dynamoUtil.put(documentClient, {
    TableName: "profiles",
    Item: profile
  }).then(_ => {
    return dynamoUtil.put(documentClient, {
      TableName: "profilesSearchHelp",
      Item: profile
    });
  });
}
var patchProfile = putProfile;

function deleteProfile(userId) {
  return dynamoUtil.delete(documentClient, {
    TableName: "profiles",
    Key: {
      userId: userId
    }
  }).then(_ => {
    return dynamoUtil.delete(documentClient, {
      TableName: "profilesSearchHelp",
      Key: {
        userId: userId
      }
    });
  });
}

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
  // each search should return one profile
  var searches = [
    queryHelpName1(normalizedQ),
    queryHelpName2(normalizedQ),
    queryHelpRuby1(normalizedQ),
    queryHelpRuby2(normalizedQ),
    queryHelpPost(q),
    queryHelpEmployeeId(q),
  ].concat(normalizedQ === q ? [ // lower case string
    queryHelpMail(q),
    queryHelpMailBeforeAt(q)
  ] : []);
  var start = Date.now();
  return Promise.all(searches).then(profilesList => {
    var dict = {};
    profilesList.forEach(profiles => {
      profiles.forEach(profile => {
        dict[profile.userId] = profile;
      });
    });
    console.log('got ' + Object.keys(dict).length, 'took ' + (Date.now() - start) + 'ms');
    return Promise.resolve({
      profiles: Object.keys(dict).map(key => dict[key])
    });
  });
}

function queryHelpName1(q) {
  return dynamoUtil.query(documentClient, {
    TableName: 'profiles',
    IndexName: "profilesName1Index",
    KeyConditionExpression: 'normalizedName1 = :normalizedName1',
    ExpressionAttributeValues: {
      ":normalizedName1": q
    }
  }).then(data => {
    return Promise.resolve(data.Items.map(deleteNormalizedFields));
  });
}

function queryHelpName2(q) {
  return dynamoUtil.query(documentClient, {
    TableName: 'profiles',
    IndexName: "profilesName2Index",
    KeyConditionExpression: 'normalizedName2 = :normalizedName2',
    ExpressionAttributeValues: {
      ":normalizedName2": q
    }
  }).then(data => {
    return Promise.resolve(data.Items.map(deleteNormalizedFields));
  });
}

function queryHelpRuby1(q) {
  return dynamoUtil.query(documentClient, {
    TableName: 'profiles',
    IndexName: "profilesRuby1Index",
    KeyConditionExpression: 'normalizedRuby1 = :normalizedRuby1',
    ExpressionAttributeValues: {
      ":normalizedRuby1": q
    }
  }).then(data => {
    return Promise.resolve(data.Items.map(deleteNormalizedFields));
  });
}

function queryHelpRuby2(q) {
  return dynamoUtil.query(documentClient, {
    TableName: 'profiles',
    IndexName: "profilesRuby2Index",
    KeyConditionExpression: 'normalizedRuby2 = :normalizedRuby2',
    ExpressionAttributeValues: {
      ":normalizedRuby2": q
    }
  }).then(data => {
    return Promise.resolve(data.Items.map(deleteNormalizedFields));
  });
}

function queryHelpEmployeeId(q) {
  return dynamoUtil.query(documentClient, {
    TableName: 'profiles',
    IndexName: "profilesEmployeeIdIndex",
    KeyConditionExpression: 'employeeId = :employeeId',
    ExpressionAttributeValues: {
      ":employeeId": q
    }
  }).then(data => {
    return Promise.resolve(data.Items.map(deleteNormalizedFields));
  });
}

function queryHelpMail(q) {
  return dynamoUtil.query(documentClient, {
    TableName: 'profilesSearchHelp',
    IndexName: "profilesMailIndex",
    KeyConditionExpression: 'mail = :mail',
    ExpressionAttributeValues: {
      ":mail": q
    }
  }).then(data => {
    return Promise.resolve(data.Items.map(deleteNormalizedFields));
  });
}

function queryHelpMailBeforeAt(q) {
  return dynamoUtil.query(documentClient, {
    TableName: 'profilesSearchHelp',
    IndexName: "profilesMailBeforeAtIndex",
    KeyConditionExpression: 'normalizedMailBeforeAt = :normalizedMailBeforeAt',
    ExpressionAttributeValues: {
      ":normalizedMailBeforeAt": q
    }
  }).then(data => {
    return Promise.resolve(data.Items.map(deleteNormalizedFields));
  });
}

function queryHelpPost(q) {
  return dynamoUtil.query(documentClient, {
    TableName: 'profilesSearchHelp',
    IndexName: "profilesPostIndex",
    KeyConditionExpression: 'post = :post',
    ExpressionAttributeValues: {
      ":post": q
    }
  }).then(data => {
    return Promise.resolve(data.Items.map(deleteNormalizedFields));
  });
}

module.exports = {
  getProfile: getProfile,
  putProfile: putProfile,
  patchProfile: patchProfile,
  deleteProfile: deleteProfile,
  findProfileByUserIds: findProfileByUserIds,
  findProfileByQuery: findProfileByQuery
};
