var mysql = require('mysql');
var esc = mysql.escape.bind(mysql);

function select(table, where) {
  return `SELECT * FROM ${table}` + (where ? ` ${where}` : '');
}

function insert(table, keyValues) {
  var columns = [];
  var values = [];
  keyValues.forEach((keyValue) => {
    columns.push(keyValue[0]);
    values.push(esc(keyValue[1]));
  });
  var columnsStr = `(${ columns.join(',') })`;
  var valuesStr = `VALUES(${ values.join(',') })`;
  return `INSERT INTO ${table} ${columnsStr} ${valuesStr}`;
}
function replace(table, keyValues) {
  var columns = [];
  var values = [];
  keyValues.forEach((keyValue) => {
    columns.push(keyValue[0]);
    values.push(esc(keyValue[1]));
  });
  var columnsStr = `(${ columns.join(',') })`;
  var valuesStr = `VALUES(${ values.join(',') })`;
  return `REPLACE INTO ${table} ${columnsStr} ${valuesStr}`;
}
function update(table, keyValues, where) {
  var sets = keyValues.map((keyValue) => {
    return `${ keyValue[0] }=${ esc(keyValue[1]) }`;
  });
  var str = `SET ${ sets.join(',') }`;
  return `UPDATE ${ table } ${ str } ${ where }`;
}
function where(key, value) {
  return `WHERE ${key}=${esc(value)}`;
}
function whereList(keyValues) {
  return `WHERE ` + keyValues.map((keyValue) => {
    return `${keyValue[0]}=${esc(keyValue[1])}`;
  }).join(' AND ');
}
function _delete(table, where) {
  return `DELETE FROM ${ table }` + (where ? ` ${where}` : '');
}
module.exports = {
  select: select,
  insert: insert,
  replace: replace,
  update: update,
  delete: _delete,
  where: where,
  whereList: whereList
};
