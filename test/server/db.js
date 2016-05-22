var url = require('url');
var fs = require('fs-extra');
var _async = require('async');

var sql = require('./sql.js');
var rdb = require('./rdb.js');
var schema = require('./schema.js');
var filestorage = require('./filestorage.js');
var mock = require('./mock.js');

var floors = {};
var passes = {
  admin01: 'admin01',
  user01 : 'user01'
};
var users = {
  admin01: {
    id:'admin01',
    org: 'Sample Co.,Ltd',
    name: 'Admin01',
    mail: 'admin01@xxx.com',
    image: 'images/users/admin01.png',
    role: 'admin'
  },
  user01 : {
    id:'user01',
    org: 'Sample Co.,Ltd',
    name: 'User01',
    tel: '33510',
    role: 'general'
  }
};
var gridSize = 8;
function getFloorSync(withPrivate, id) {
  if(withPrivate) {
    return floors[id] ? floors[id][0] : null;
  } else {
    if(floors[id]) {
      return floors[id][0].public ? floors[id][0] : floors[id][1];
    } else {
      return null;
    }
  }
}
function getFloor(withPrivate, id, cb) {
  cb(null, getFloorSync(withPrivate, id));
}
// function getFloor(withPrivate, id, cb) {
//   rdb.exec(sql.select('floors', sql.where('id', id)), cb);
// }
function getFloors(withPrivate, cb) {
  var floors_ = Object.keys(floors).map(function(id) {
    return getFloorSync(withPrivate, id);
  }).filter(function(floor) {
    return !!floor;
  });
  cb(null, floors_);
}
function ensureFloor(id, cb) {
  if(!floors[id]) {
    floors[id] = [];
  }
  cb && cb();
}
function saveFloor(newFloor, cb) {
  var id = newFloor.id;
  if(floors[id]) {
    if(floors[id][0].public) {
      floors[id].unshift(newFloor);
    } else {
      floors[id][0] = newFloor;
    }
  } else {
    floors[id] = [newFloor];
  }
  cb && cb();
}
// function saveFloor(newFloor, cb) {
//   // TODO upsert
//   var where = 'TODO';
//   rdb.exec(sql.update('floors', schema.floorKeyValues(newFloor), where), cb);
// }
function publishFloor(newFloor, cb) {
  var id = newFloor.id;
  if(floors[id][0] && !floors[id][0].public) {
    floors[id][0] = newFloor;
  } else {
    floors[id].unshift(newFloor);
  }
  console.log(Object.keys(floors).map(function(key) {
    return key + ' => ' + floors[key].map(function(f) {
      return f.public
    })
  }));
}
// function publishFloor(newFloor, cb) {
//   rdb.exec(sql.insert('floors', schema.floorKeyValues(newFloor)), cb);
// }

function saveUser(user, cb) {
  //TODO upsert
  rdb.exec(sql.insert('users', schema.userKeyValues(user)), cb);
}

function savePerson(person, cb) {
  //TODO upsert
  rdb.exec(sql.insert('persons', schema.personKeyValues(person)), cb);
}

function saveImage(path, image, cb) {
  filestorage.save(path, image, cb);
}
function resetImage(dir, cb) {
  filestorage.empty(dir, cb);
}
function getCandidate(name, cb) {
  var users_ = Object.keys(users).map(function(id) {
    return users[id];
  });
  var results = users_.reduce(function(memo, user) {
    if(user.name.toLowerCase().indexOf(name.toLowerCase()) >= 0) {
      return memo.concat([user]);
    } else {
      return memo;
    }
  }, []);
  cb(null, results);
}
function search(query, all, cb) {
  getFloors(all, function(e, floors) {
    if(e) {
      cb(e);
    } else {
      var results = floors.reduce(function(memo, floor) {
        return floor.equipments.reduce(function(memo, e) {
          if(e.name.indexOf(query) >= 0) {
            return memo.concat([[e, floor.id]]);
          } else {
            return memo;
          }
        }, memo);
      }, []);
      cb(null, results);
    }
  });
}
function getPrototypes(cb) {
  rdb.exec(sql.select('prototypes'), function(e, prototypes) {
    console.log(prototypes);
    cb(null, prototypes);
  });
}
function savePrototypes(newPrototypes, cb) {
  var inserts = newPrototypes.map(function(proto) {
    return sql.insert('prototypes', schema.prototypeKeyValues(proto));
  });
  inserts.unshift(sql.delete('prototypes'));
  console.log(inserts);
  rdb.batch(inserts, cb);
}
function getUser(id, cb) {
  cb(null, users[id]);
}
function getPerson(id, cb) {
  cb(null, users[id]);
}
function getPass(id, cb) {
  cb(null, passes[id]);
}
function getColors(cb) {
  rdb.exec(sql.select('colors', sql.where('id', '1')), function(e, colors) {
    if(e) {
      cb(e);
    } else {
      var _colors = [];
      [1,2,3,4,5,6,7,8,9,10].forEach(function(i) {
        var c = colors[0]['color' + i];
        if(c) {
          _colors.push(c);
        }
      });
      cb(null, _colors);
    }
  });
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

function init(cb) {
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
      publishedAt number
    )`, `
    CREATE TABLE equipments (
      id string NOT NULL,
      name string NOT NULL,
      width number NOT NULL,
      height number NOT NULL,
      color string NOT NULL,
      personId string,
      floorId string NOT NULL
    )`, `
    CREATE TABLE prototypes (
      id string NOT NULL,
      name string NOT NULL,
      width number NOT NULL,
      height number NOT NULL,
      color string NOT NULL
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
  ], function(e) {
    if(e) {
      cb && cb(e);
    } else {
      _async.series(mock.users.map(function(user) {
        return saveUser.bind(null, user);
      }).concat(mock.persons.map(function(person) {
        return savePerson.bind(null, person);
      })).concat([
        savePrototypes.bind(null, mock.prototypes)
      ]).concat([
        saveColors.bind(null, mock.colors)
      ]), cb);
    }
  });
}
init(function(e) {
  if(e) {
    console.log(e);
  }
});//TODO export

module.exports = {
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
};
