var sql = require('./sql.js');
var rdb = require('./rdb.js');
var db = require('./db.js');

function select(table, where) {
  return `SELECT * FROM ${table}` + (where ? ` ${where}` : '');
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
  rdb.exec(sql.select('floors', sql.where('id', id)));
}
function getFloors(withPrivate) {
  rdb.exec(sql.select('floors', withPrivate ? null : sql.where('public', true)));
}
function ensureFloor(id) {
  // nothing to do
}
function saveFloor(newFloor) {
  // TODO upsert
  var where = 'TODO';
  rdb.exec(sql.update('floors', floorKeyValues(newFloor), where));
}
function publishFloor(newFloor) {
  rdb.exec(sql.insert('floors', floorKeyValues(newFloor)));
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
