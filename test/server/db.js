var url = require('url');
var fs = require('fs-extra');
var sql = require('./sql.js');
var rdb = require('./rdb.js');
var filestorage = require('./filestorage.js');

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
var colors = ["#ed9", "#b9f", "#fa9", "#8bd", "#af6", "#6df"
, "#bbb", "#fff", "rgba(255,255,255,0.5)"];
var prototypes = [
  { id: "1", color: "#ed9", name: "", size : [gridSize*6, gridSize*10] },
  { id: "2", color: "#8bd", name: "foo", size : [gridSize*7, gridSize*12] }
];
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
function getFloors(withPrivate, cb) {
  floors_ = Object.keys(floors).map(function(id) {
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
  var results = getFloors(all).reduce(function(memo, floor) {
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
function getPrototypes(cb) {
  cb(null, prototypes);
}
function savePrototypes(newPrototypes, cb) {
  prototypes = newPrototypes;
  cb && cb();
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
  cb(null, colors);
}
function saveColors(newColors, cb) {
  colors = newColors;
  cb && cb();
}
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
