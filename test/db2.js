var mysql = require('mysql');
var alasql = require('alasql');
var db = require('./db.js');

var esc = mysql.escape.bind(mysql);

function select(table, where) {
  return `SELECT * FROM ${table}` + (where ? ` ${where}` : '');
}

function insert(table, keyValues) {
  var columns = [];
  var values = [];
  keyValues.forEach(function(keyValue) {
    columns.push(esc(keyValue[0]));
    values.push(esc(keyValue[1]));
  });
  var columnsStr = `(${ columns.join(',') })`;
  var valuesStr = `VALUES(${ columns.join(',') })`;
  return `INSERT INTO ${table} ${columnsStr} ${valuesStr}`;
}
function update(table, keyValues, where) {
  var sets = keyValues.map(function(keyValue) {
    return `${ esc(keyValue[0]) }=${esc(keyValue[1]) }`
  });
  var str = `SET ${ sets.join(',') }`;
  return `UPDATE ${table} ${str} WHERE ${where}`;
}
function floorKeyValues(floor) {
  //id*	version*	name	image	realWidth	realHeight	public	publishedBy  publishedAt
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

function getFloor(withPrivate, id) {
  console.log(select('floors', `WHERE id=${esc(id)}`));
}
function getFloors(withPrivate) {
  console.log(select('floors', withPrivate ? null : `WHERE public=true`));
}
function ensureFloor(id) {
  // nothing to do
}
function saveFloor(newFloor) {
  // TODO upsert
  var where = 'TODO';
  console.log(update('floors', floorKeyValues(newFloor), where));
}
function publishFloor(newFloor) {
  console.log(insert('floors', floorKeyValues(newFloor)));
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
function savePrototypes(newPrototypes) {

}
function getUser(id) {

}
function getPerson(id) {

}
function getPass(id) {

}
function getColors() {

}
function saveColors(newColors) {

}
function wrapForDebug(functions) {
  return Object.keys(functions).reduce(function(memo, key) {
    var f = functions[key];
    memo[key] = function() {
      f.apply(null, arguments);
      return db[key].apply(null, arguments);
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
