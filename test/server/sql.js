var mysql = require('mysql');
var esc = mysql.escape.bind(mysql);

function select(table, where) {
  return `SELECT * FROM ${table}` + (where ? ` ${where}` : '');
}

function insert(table, keyValues) {
  var columns = [];
  var values = [];
  keyValues.forEach(function(keyValue) {
    columns.push(keyValue[0]);
    values.push(esc(keyValue[1]));
  });
  var columnsStr = `(${ columns.join(',') })`;
  var valuesStr = `VALUES(${ columns.join(',') })`;
  return `INSERT INTO ${table} ${columnsStr} ${valuesStr}`;
}
function update(table, keyValues, where) {
  var sets = keyValues.map(function(keyValue) {
    return `${ keyValue[0] }=${ esc(keyValue[1]) }`;
  });
  var str = `SET ${ sets.join(',') }`;
  return `UPDATE ${ table } ${ str } WHERE ${ where }`;
}
function where(key, value) {
  return `WHERE ${key}=${esc(value)}`;
}
module.exports = {
  select: select,
  insert: insert,
  update: update,
  where: where
};
