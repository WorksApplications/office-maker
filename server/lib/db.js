var url = require('url');
var fs = require('fs-extra');

var sql = require('./sql.js');
var rdb = require('./mysql.js');
var schema = require('./schema.js');
var filestorage = require('./filestorage.js');
var profileService = require('./profile-service.js');


function saveObjects(conn, added, modified, deleted) {
  return added.reduce((memo, object) => {
    return memo.then(objects => {
      var query = sql.insert('objects', schema.objectKeyValues(object));
      return rdb.exec(conn, query).then((okPacket) => {
        if(!okPacket.affectedRows) {
          throw `didn't update by ` + query;
        }
        objects.push(object);
        return Promise.resolve(objects);
      });
    });
  }, Promise.resolve([])).then(objects => {
    return modified.reduce((memo, object) => {
      return memo.then(objects => {
        var query = sql.update('objects', schema.objectKeyValues(object),
          sql.whereList([['id', object.id], ['floorVersion', object.floorVersion]])// TODO , ['updateAt', object.updateAt]
        );
        return rdb.exec(conn, query).then((okPacket) => {
          if(!okPacket.affectedRows) {
            throw `didn't update by ` + query;
          }
          objects.push(object);
          return Promise.resolve(objects);
        });
      });
    }, Promise.resolve(objects));
  }).then(objects => {
    return deleted.reduce((memo, object) => {
      var sql = sql.delete('objects', sql.whereList([['id', object.id], ['floorVersion', object.floorVersion]]));// TODO , ['updateAt', object.updateAt]
      return memo.then(objects => {
        return rdb.exec(conn, sql).then(() => {
          if(!okPacket.affectedRows) {
            throw `didn't update by ` + query;
          }
          return Promise.resolve(objects);
        });
      });
    }, Promise.resolve(objects));
  });
}

function getObjects(conn, floorId, floorVersion) {
  var q = sql.select('objects', sql.whereList([['floorId', floorId], ['floorVersion', floorVersion]]));
  return rdb.exec(conn, q);
}

function getFloorWithObjects(conn, tenantId, withPrivate, id) {
  return getFloor(conn, tenantId, withPrivate, id).then((floor) => {
    if(!floor) {
      return Promise.resolve(null);
    }
    return getObjects(conn, floor.id, floor.version).then((objects) => {
      floor.objects = objects;
      return Promise.resolve(floor);
    });
  });
}

function getFloorOfVersionWithObjects(conn, tenantId, id, version) {
  return getFloorOfVersion(conn, tenantId, id, version).then((floor) => {
    if(!floor) {
      return Promise.resolve(null);
    }
    return getObjects(conn, floor.id, floor.version).then((objects) => {
      floor.objects = objects;
      return Promise.resolve(floor);
    });
  });
}

function getFloorOfVersion(conn, tenantId, id, version) {
  var q = sql.select('floors', sql.whereList([['id', id], ['tenantId', tenantId], ['version', version]]));
  return rdb.one(conn, q);
}

function getFloor(conn, tenantId, withPrivate, id) {
  var q = sql.select('floors', sql.whereList([['id', id], ['tenantId', tenantId]]));
  return rdb.exec(conn, q).then((floors) => {
    var _floor = null;
    floors.forEach((floor) => {
      if(!_floor || _floor.version < floor.version) {
        if(floor.public || withPrivate) {
          _floor = floor;
        }
      }
    });
    return Promise.resolve(_floor);
  });
}

function getFloors(conn, tenantId, withPrivate) {
  var sql_ = sql.select('floors', sql.where('tenantId', tenantId));
  return rdb.exec(conn, sql_).then((floors) => {
    var results = {};
    floors.forEach((floor) => {
      if(!results[floor.id] || results[floor.id].version < floor.version) {
        if(floor.public || withPrivate) {
          results[floor.id] = floor;
        }
      }
    });
    var ret = Object.keys(results).map((id) => {
      return results[id];
    });
    return Promise.resolve(ret);
  });
}

function getFloorsWithObjects(conn, tenantId, withPrivate) {
  return getFloors(conn, tenantId, withPrivate).then((floors) => {
    var promises = floors.map((floor) => {
      return getObjects(conn, floor.id, floor.version).then((objects) => {
        floor.objects = objects;
        return Promise.resolve(floor);
      });
    });
    return Promise.all(promises);
  });
}

function getFloorsInfo(conn, tenantId) {
  return getFloors(conn, tenantId, false).then((floorsNotIncludingLastPrivate) => {
    return getFloors(conn, tenantId, true).then((floorsIncludingLastPrivate) => {
      var floorInfos = {};
      floorsNotIncludingLastPrivate.forEach((floor) => {
        floorInfos[floor.id] = floorInfos[floor.id] || [];
        floorInfos[floor.id][0] = floor;
      });
      floorsIncludingLastPrivate.forEach((floor) => {
        floorInfos[floor.id] = floorInfos[floor.id] || [];
        floorInfos[floor.id][1] = floor;
      });
      var values = Object.keys(floorInfos).map((key) => {
        return floorInfos[key];
      });
      values.forEach((value) => {
        value[0] = value[0] || value[1];
        value[1] = value[1] || value[0];
      });
      return Promise.resolve(values);
    });
  });
}

function saveOrCreateFloor(conn, tenantId, newFloor) {
  return getFloor(conn, tenantId, true, newFloor.id).then((floor) => {
    if(floor) {
      if(floor.public) {
        throw "illeagal";
      }
      newFloor.version = floor.version;
      return rdb.exec(
        conn,
        sql.update('floors', schema.floorKeyValues(tenantId, newFloor),
          sql.whereList([['id', newFloor.id], ['tenantId', tenantId], ['version', floor.version]])
        )
      ).then(() => {
        return Promise.resolve(newFloor);
      });
    } else {
      return rdb.exec(
        conn,
        sql.insert('floors', schema.floorKeyValues(tenantId, newFloor))
      ).then(() => {
        return Promise.resolve(newFloor);
      });
    }
  });
}

function saveFloorWithObjects(conn, tenantId, newFloor, updateBy) {
  newFloor.public = false;
  newFloor.updateBy = updateBy;
  newFloor.updateAt = new Date().getTime();
  return saveOrCreateFloor(conn, tenantId, newFloor).then((floor) => {
    var added = newFloor.added.map((object) => {
      object.floorVersion = floor.version;
      return object;
    });
    var modified = newFloor.modified.map((mod) => {
      var object = mod.new;
      return object;
    });
    var deleted = newFloor.deleted.map((object) => {
      return object;
    });
    return saveObjects(conn, added, modified, deleted).then((objects) => {
      delete newFloor.added;
      delete newFloor.modified;
      delete newFloor.deleted;
      newFloor.objects = objects;
      return Promise.resolve(newFloor);
    });
  });
}


function publishFloor(conn, tenantId, floorId, updateBy) {
  return getFloorWithObjects(conn, tenantId, true, floorId).then((floor) => {
    if(!floor) {
      return Promise.reject('floor not found: ' + floorId);
    }
    var sqls = [];

    // 最新のフロアをpublicにする
    floor.public = true;
    floor.updateBy = updateBy;
    floor.updateAt = new Date().getTime();
    sqls.push(sql.replace('floors', schema.floorKeyValues(tenantId, floor)));

    // コピーしてprivate（編集中）のフロアを作る
    floor.version = floor.version + 1;
    floor.public = false;
    floor.updateBy = null;
    floor.updateAt = null;
    sqls.push(sql.replace('floors', schema.floorKeyValues(tenantId, floor)));

    // オブジェクトもコピーして最新の編集中フロアを参照させる
    floor.objects.forEach(o => {
      o.floorVersion = floor.version;
    });
    sqls = sqls.concat(floor.objects.map((object) => {
      return sql.insert('objects', schema.objectKeyValues(object));
    }));
    return rdb.batch(conn, sqls).then(() => {
      return Promise.resolve(floor);
    });
  });
}

function deleteUnrelatedObjects(conn) {
  return rdb.exec(conn,
  `DELETE FROM objects
      WHERE
          NOT EXISTS( SELECT
              1
          FROM
              floors AS f
          WHERE
              objects.floorId = f.id
              AND objects.floorVersion = f.version)`
  );
}

function deleteFloor(conn, tenantId, floorId) {
  var sqls = [
    sql.delete('floors', sql.whereList([['id', floorId], ['tenantId', tenantId]]))
  ];
  return rdb.batch(conn, sqls);
}

function deleteFloorWithObjects(conn, tenantId, floorId) {
  var sqls = [
    sql.delete('floors', sql.whereList([['id', floorId], ['tenantId', tenantId]])),
    sql.delete('objects', sql.whereList([['floorId', floorId]])),
  ];
  return rdb.batch(conn, sqls);
}

function deletePrototype(conn, tenantId, id) {
  var sqls = [
    sql.delete('prototypes', sql.whereList([['id', id], ['tenantId', tenantId]]))
  ];
  return rdb.batch(conn, sqls);
}

function saveImage(conn, path, image) {
  return filestorage.save(path, image);
}

function resetImage(conn, dir) {
  return filestorage.empty(dir);
}

function search(conn, tenantId, query, all, people) {
  return getFloorsWithObjects(conn, tenantId, all).then((floors) => {
    var results = {};
    var arr = [];
    people.forEach((person) => {
      results[person.id] = [];
    });
    floors.forEach((floor) => {
      floor.objects.forEach((e) => {
        if(e.personId) {
          if(results[e.personId]) {
            results[e.personId].push(e);
          }
        } else if(e.name.toLowerCase().indexOf(query.toLowerCase()) >= 0) {
          // { Nothing, Just } -- objects that has no person
          arr.push({
            personId : null,
            objectAndFloorId : [e, e.floorId]
          });
        }
      });
    });

    Object.keys(results).forEach((personId) => {
      var objects = results[personId];
      objects.forEach(e => {
        // { Just, Just } -- people who exist in map
        arr.push({
          personId : personId,
          objectAndFloorId : [e, e.floorId]
        });
      })
      // { Just, Nothing } -- missing people
      if(!objects.length) {
        arr.push({
          personId : personId,
          objectAndFloorId : null
        });
      }
    });
    return Promise.resolve(arr);
  });
}

// function searchObjectsByName(conn, tenantId, name, all) {
//   var filterByPublic =
//     all ? '' : 'AND f.public = 1';
//
//   // TODO avoid injection
//   var sql =
//     `SELECT o.*
//        FROM map2.objects AS o, map2.floors AS f
//        WHERE o.name like "%${name}%" AND o.floorId = f.id AND o.floorVersion = f.version AND f.tenantId = "${tenantId}" ${filterByPublic}
//        ORDER BY o.id, o.floorId, o.floorVersion`;
//
//   return rdb.exec(conn, sql).then((records) => {
//     var objects = {};
//     records.forEach(record => {
//       objects[records.id] = record;// keep newest
//     });
//     return Promise.resolve(Object.keys(objects).map(objectId => {
//       return objects[objectId];
//     }));
//   });
// }

function getPrototypes(conn, tenantId) {
  return rdb.exec(conn, sql.select('prototypes', sql.where('tenantId', tenantId)));
}

function savePrototype(conn, tenantId, newPrototype) {
  return rdb.exec(conn, sql.replace('prototypes', schema.prototypeKeyValues(tenantId, newPrototype)));
}

function savePrototypes(conn, tenantId, newPrototypes) {
  var inserts = newPrototypes.map((proto) => {
    return sql.insert('prototypes', schema.prototypeKeyValues(tenantId, proto));
  });
  inserts.unshift(sql.delete('prototypes', sql.where('tenantId', tenantId)));
  return rdb.batch(conn, inserts);
}

function getColors(conn, tenantId) {
  return rdb.exec(conn, sql.select('colors', sql.where('tenantId', tenantId)));
}

function saveColors(conn, tenantId, colors) {
  var inserts = colors.map((c, index) => {
    c.id = index + '';
    return schema.colorKeyValues(tenantId, c);
  }).map((keyValues) => {
    return sql.insert('colors', keyValues);
  });
  inserts.unshift(sql.delete('colors', sql.where('tenantId', tenantId)));
  return rdb.batch(conn, inserts);
}

module.exports = {
  search: search,
  getPrototypes: getPrototypes,
  savePrototype: savePrototype,
  savePrototypes: savePrototypes,
  getColors: getColors,
  saveColors: saveColors,
  getFloorWithObjects: getFloorWithObjects,
  getFloorOfVersionWithObjects: getFloorOfVersionWithObjects,
  getFloorsInfo: getFloorsInfo,
  saveFloorWithObjects: saveFloorWithObjects,
  publishFloor: publishFloor,
  deleteFloor: deleteFloor,
  deleteFloorWithObjects: deleteFloorWithObjects,
  deletePrototype: deletePrototype,
  saveImage: saveImage,
  resetImage: resetImage
};
