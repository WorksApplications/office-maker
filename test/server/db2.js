var _async = require('async');

var sql = require('./sql.js');
var rdb = require('./rdb.js');
var db = require('./db.js');
// var filestorage = require('./filestorage.js');
var mock = require('./mock.js');


rdb.batch([`
  CREATE TABLE users (
    id string NOT NULL,
    role string NOT NULL,
    personId string NOT NULL
  )`,`
  CREATE TABLE persons (
    id string NOT NULL,
    name number NOT NULL,
    org string NOT NULL,
    mail string,
    image number
  )`,`
  CREATE TABLE floors (
    id string NOT NULL,
    version number NOT NULL,
    name string NOT NULL,
    image string,
    realWidth number,
    realHeight number,
    public boolean,
    publishedBy string,
    publishedAt number,
  )`, `
  CREATE TABLE equipments (
    id string NOT NULL,
    name string NOT NULL,
    image string,
    width number NOT NULL,
    height number NOT NULL,
    color string NOT NULL,
    personId string,
    floorId string NOT NULL
  )`, `
  CREATE TABLE colors (
    id string NOT NULL,
    color0 string,
    color1 string,
    color2 string,
    color3 string,
    color4 string,
    color5 string,
    color6 string,
    color7 string,
    color8 string,
    color9 string,
    color10 string
  )`
]);
_async.series(mock.users.map(function(user) {
  return saveUser.bind(null, user);
}));
_async.series(mock.persons.map(function(person) {
  return savePerson.bind(null, person);
}));
_async.series([savePrototypes.bind(null, mock.prototypes)]);
_async.series([saveColors.bind(null, mock.colors)]);

function userKeyValues(user) {
  return [
    ["id", user.id],
    ["role", user.role],
    ["personId", user.personId],
  ];
}
function personKeyValues(person) {
  return [
    ["id", person.id],
    ["name", person.name],
    ["org", person.org],
    ["tel", person.tel],
    ["mail", person.mail],
    ["image", person.image]
  ];
}
function floorKeyValues(floor) {
  return [
    ["id", floor.id],
    ["version", 0],//TODO
    ["name", floor.name],
    ["image", floor.image],
    ["realWidth", floor.realWidth],
    ["realHeight", floor.realHeight],
    ["public", floor.public],
    ["publishedBy", floor.publishedBy],
    ["publishedAt", floor.publishedAt]
  ];
}
function prototypeKeyValues(proto) {
  return [
    ["id", proto.id],
    ["name", proto.name],
    ["width", proto.width],
    ["height", proto.height],
    ["color", proto.color]
  ];
}
function saveUser(user, cb) {
  //TODO upsert
  rdb.exec(sql.insert('users', userKeyValues(user)), cb);
}
function getUser(id) {

}
function savePerson(person, cb) {
  //TODO upsert
  rdb.exec(sql.insert('persons', personKeyValues(person)), cb);
}
function getFloor(withPrivate, id, cb) {
  rdb.exec(sql.select('floors', sql.where('id', id)), cb);
}
function getFloors(withPrivate, cb) {
  // rdb.exec(sql.select('floors', withPrivate ? null : sql.where('public', true)), cb);
}
function ensureFloor(id) {
  // nothing to do
}
function saveFloor(newFloor, cb) {
  // TODO upsert
  var where = 'TODO';
  rdb.exec(sql.update('floors', floorKeyValues(newFloor), where), cb);
}
function publishFloor(newFloor, cb) {
  rdb.exec(sql.insert('floors', floorKeyValues(newFloor)), cb);
}
function saveImage(path, image, cb) {

}
function resetImage(dir, cb) {

}
function getCandidate(name) {

}
function search(query, all) {

}
function getPrototypes() {

}
function savePrototypes(newPrototypes, cb) {
  var inserts = newPrototypes.map(function(proto) {
    return sql.insert('prototypes', prototypeKeyValues(proto));
  });
  inserts.unshift(sql.delete('prototypes'));
  rdb.batch(inserts, cb);
}
function getPerson(id) {

}
function getPass(id) {

}
function getColors() {

}
function saveColors(newColors, cb) {
  var keyValues = newColors.map(function(c, index) {
    return ['color' + index, c];
  });
  keyValues.unshift(['id', '1']);
  rdb.batch([
    sql.delete('colors'),
    sql.insert('colors', keyValues)
  ], cb);
}
function wrapForDebug(functions) {
  return Object.keys(functions).reduce(function(memo, key) {
    var f = functions[key];
    memo[key] = function() {
      var args = (arguments.length === 1?[arguments[0]]:Array.apply(null, arguments));
      var args2 = args.concat();
      args.length = args.length - 1;
      f.apply(null, args);
      return db[key].apply(null, args2);
    };
    return memo;
  }, functions);
}

module.exports = wrapForDebug({
  getPass: getPass,
  getUser: getUser,
  getPerson: getPerson,
  getCandidate: getCandidate,
  search: search,
  getPrototypes: getPrototypes,
  savePrototypes: savePrototypes,
  getColors: getColors,
  saveColors: saveColors,
  getFloor: getFloor,
  getFloors: getFloors,
  ensureFloor: ensureFloor,
  saveFloor: saveFloor,
  publishFloor: publishFloor,
  saveImage: saveImage,
  resetImage: resetImage
});
