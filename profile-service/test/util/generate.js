//http://www.gaoshukai.com/lab/0003/
// $$('#main > ul > li').map(e => { return e.querySelectorAll('ruby > rb')[0].textContent + ' ' + e.querySelectorAll('ruby > rb')[1].textContent + ',' + e.querySelectorAll('ruby > rt')[0].textContent.split('／')[0] + ' ' + e.querySelectorAll('ruby > rt')[1].textContent.split('／')[0]; }).join('\r\n');

var fs = require('fs');
var AWS = require('aws-sdk');
var dynamoUtil = require('../functions/common/dynamo-util.js');
var dynamodb = new AWS.DynamoDB();
var project = JSON.parse(fs.readFileSync('./project.json', 'utf8'));
var documentClient = new AWS.DynamoDB.DocumentClient({
  region: project.region
});

var profiles = fs.readFileSync(__dirname + '/mock.csv', 'utf8').replace(/\r/g, '').split('\n').map((line, index) => {
  var name = line.split(',')[0];
  var ruby = line.split(',')[1];
  if (!name || !ruby) {
    return null;
  }
  return {
    userId: zeroPadding(index, 4) + '@example.com',
    employeeId: zeroPadding(index, 4),
    picture: null,
    name: name,
    ruby: ruby,
    organization: 'Example Co., Ltd.',
    post: 'Example ' + Math.floor(index / 1000),
    rank: index % 10 === 0 ? 'Manager' : 'Assistant',
    cellPhone: '080-XXX-' + zeroPadding(index, 4),
    extensionPhone: 'XXXXX',
    mail: zeroPadding(index, 4) + '@example.com',
    workplace: null
  }
}).filter(profile => !!profile);

profiles.push({
  userId: 'arai_s@worksap.co.jp',
  employeeId: 'XXXX',
  picture: null,
  name: '新井 テスト',
  ruby: 'あらい てすと',
  organization: 'Example Co., Ltd.',
  post: 'Example 0',
  rank: 'Manager',
  cellPhone: '080-XXX-XXXX',
  extensionPhone: 'XXXXX',
  mail: 'arai_s@worksap.co.jp',
  workplace: null
});

console.log('generating mock data...');
// profiles.reduce((promise, profile) => {
//   return promise.then(_ => putProfile(profile));
// }, Promise.resolve()).then(_ => {
//   console.log('done');
//   process.exit(0);
// }).catch(e => {
//   console.error(e);
//   process.exit(1);
// });

function putProfile(profile) {
  return dynamoUtil.put(documentClient, {
    TableName: "profiles",
    Item: profile
  });
}

function zeroPadding(num, length) {
  return ('0000000000' + num).slice(-length);
}
