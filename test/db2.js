var mysql = require('mysql');
var alasql = require('alasql');
var db = require('./db.js');

var esc = mysql.escape.bind(mysql);

function getFloor(withPrivate, id) {
  console.log(`SELECT * FROM FLOOR WHERE id = ${esc(id)}`);
}
function getFloors(withPrivate) {

}
function ensureFloor(id) {

}
function saveFloor(newFloor) {

}
function publishFloor(newFloor) {

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
