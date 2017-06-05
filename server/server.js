var url = require('url');
var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var path = require('path');
var request = require('request');
var jwt = require('jsonwebtoken');
var db = require('./lib/db.js');
var rdb = require('./lib/mysql.js');
var accountService = require('./lib/account-service');
var profileService = require('./lib/profile-service');
var log = require('./lib/log.js');
var config = require('./lib/config.js');
var commands = require('./commands.js');

var rdbEnv = rdb.createEnv(config.mysql.host, config.mysql.user, config.mysql.pass, 'map2');

app.use(log.express);
app.use(bodyParser.json({
  limit: '50mb'
}));
app.use(bodyParser.urlencoded({
  limit: '50mb',
  extended: false
}));

function inTransaction(f) {
  return function(req, res) {
    rdbEnv.forConnectionAndTransaction(conn => {
      return f(conn, req, res);
    }).then(data => {
      res.send(data);
    }).catch(e => {
      if (typeof e === 'number' && e >= 400) {
        res.status(e).send('');
      } else {
        log.system.error('error', e);
        e.stack && log.system.error(e.stack);
        res.status(500).send('');
      }
    });
  }
}

function getAuthToken(req) {
  return req.headers['authorization'];
}

function getSelf(conn, token) {
  if (!token) {
    if (config.multiTenency) {
      return Promise.reject(403);
    } else {
      return Promise.resolve(null);
    }
  }
  return new Promise((resolve, reject) => {
    jwt.verify(token, config.secret.token, {
      algorithms: ['RS256', 'RS384', 'RS512', 'HS256', 'HS256', 'HS512', 'ES256', 'ES384', 'ES512']
    }, (e, user) => {
      if (e) {
        reject(e);
      } else {
        accountService.toMapUser(user);
        resolve(user);
      }
    });
  }).catch((e) => {
    log.system.debug(e);
    Promise.reject(401);
    // if(e.name === 'JsonWebTokenError') {
    //   return Promise.reject(401);
    // } else {
    //   return Promise.reject(e);
    // }
  });
}

if (config.redirect) {
  app.get('/', (req, res) => {
    return res.send('<a href="' +
      config.redirect +
      '">URL が変更されました。お手数ですがブックマークの変更をお願いいたします。</a>'
    );
  });
}

app.get('/api/1/people/search/:name', inTransaction((conn, req, res) => {
  var token = getAuthToken(req);
  var name = req.params.name;
  return profileService.search(config.profileServiceRoot, token, name);
}));

app.get('/api/1/people/:id', inTransaction((conn, req, res) => {
  var id = req.params.id;
  // using IP address
  return profileService.getPerson(config.profileServiceRoot, null, id).then((person) => {
    if (!person) {
      return Promise.reject(404);
    }
    return Promise.resolve(person);
  });
}));

app.get('/api/1/people', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  if (options.ids) {
    var ids = options.ids.split(',');
    return profileService.getPeopleByIds(config.profileServiceRoot, null, ids);
  }
  var token = getAuthToken(req);
  var floorId = options.floorId;
  var floorVersion = options.floorVersion;
  var postName = options.post;
  if (!floorId || !floorVersion || !postName) {
    return Promise.reject(400);
  }
  return getSelf(conn, token).then((user) => {
    return db.getFloorOfVersionWithObjects(conn, user.tenantId, floorId, floorVersion).then((floor) => {
      var peopleSet = {};
      floor.objects.forEach((object) => {
        if (object.personId) {
          peopleSet[object.personId] = true;
        }
      });
      return profileService.getPeopleByPost(config.profileServiceRoot, token, postName).then((people) => {
        return Promise.resolve(people.filter((person) => {
          return peopleSet[person.id];
        }));
      });
    });
  });
}));

app.get('/api/1/self', inTransaction((conn, req, res) => {
  var token = getAuthToken(req);
  if (!token) {
    return Promise.resolve({});
  }
  return getSelf(conn, token).then((user) => {
    if (!user) {
      return Promise.resolve({
        role: 'guest',
      });
    }
    return profileService.getPerson(config.profileServiceRoot, token, user.id).then((person) => {
      if (person == null) {
        throw "Relevant person for " + user.id + " not found."
      }
      user.person = person;
      return Promise.resolve(user);
    });
  });
}));


app.get('/api/1/admins', inTransaction((conn, req, res) => {
  var token = getAuthToken(req);
  return getSelf(conn, token).then((user) => {
    return accountService.getAllAdmins(config.accountServiceRoot, token).then(admins => {
      var ids = admins.map(admin => admin.userId);
      var dict = {};
      admins.forEach(admin => {
        dict[admin.userId] = admin;
      });
      return profileService.getPeopleByIds(config.profileServiceRoot, token, ids).then((people) => {
        people.forEach(person => {
          dict[person.id].person = person;
        });
        var list = Object.keys(dict).map(key => {
          return dict[key];
        });
        return Promise.resolve(list);
      });
      return Promise.resolve(admins);
    });
  });
}));


// should be person?
app.get('/api/1/users/:id', inTransaction((conn, req, res) => {
  var token = getAuthToken(req);
  var userId = req.params.id;
  return getSelf(conn, token).then((user) => {
    return profileService.getPerson(config.profileServiceRoot, token, userId).then((person) => {
      user.person = person;
      return Promise.resolve(user);
    });
  });
}));

app.put('/api/1/prototypes/:id', inTransaction((conn, req, res) => {
  return getSelf(conn, getAuthToken(req)).then((user) => {
    if (!user) {
      return Promise.reject(403);
    }
    var prototype = req.body;
    if (!prototype) {
      return Promise.reject(403);
    }
    return db.savePrototype(conn, user.tenantId, prototype).then(() => {
      return Promise.resolve({});
    });
  })
}));


app.get('/api/1/prototypes', inTransaction((conn, req, res) => {
  return getSelf(conn, getAuthToken(req)).then((user) => {
    if (!user) {
      return Promise.reject(403);
    }
    return db.getPrototypes(conn, user.tenantId).then((prototypes) => {
      return Promise.resolve(prototypes);
    });
  });
}));


app.put('/api/1/prototypes', inTransaction((conn, req, res) => {
  return getSelf(conn, getAuthToken(req)).then((user) => {
    if (!user) {
      return Promise.reject(403);
    }
    var prototypes = req.body;
    if (!prototypes || !prototypes.length) {
      return Promise.reject(403);
    }
    return db.savePrototypes(conn, user.tenantId, prototypes).then(() => {
      return Promise.resolve({});
    });
  })
}));

app.get('/api/1/colors', inTransaction((conn, req, res) => {
  return getSelf(conn, getAuthToken(req)).then((user) => {
    if (!user) {
      return Promise.reject(403);
    }
    return db.getColors(conn, user.tenantId).then((colors) => {
      return Promise.resolve(colors);
    });
  })
}));

app.put('/api/1/colors', inTransaction((conn, req, res) => {
  return getSelf(conn, getAuthToken(req)).then((user) => {
    if (!user) {
      return Promise.reject(403);
    }
    var colors = req.body;
    if (!colors || !colors.length) {
      return Promise.reject(403);
    }
    return db.saveColors(conn, user.tenantId, colors).then(() => {
      return Promise.resolve({});
    });
  });
}));

app.get('/api/1/floors', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  return getSelf(conn, getAuthToken(req)).then(user => {
    var tenantId = user ? user.tenantId : '';
    return db.getFloorsInfo(conn, tenantId, user && user.id).then(floorInfoList => {
      return Promise.resolve(floorInfoList);
    });
  });
}));

// admin only
app.get('/api/1/floors/:id/:version', inTransaction((conn, req, res) => {
  return getSelf(conn, getAuthToken(req)).then(user => {
    if (!user || user.role !== 'admin') {
      return Promise.reject(403);
    }
    var tenantId = user ? user.tenantId : '';
    var id = req.params.id;
    var version = req.params.version;
    log.system.debug('get: ' + id + '/' + version);
    return db.getFloorOfVersionWithObjects(conn, tenantId, id, version).then(floor => {
      if (!floor) {
        return Promise.reject(404);
      }
      log.system.debug('gotFloor: ' + id + '/' + version + ' ' + floor.objects.length);
      return Promise.resolve(floor);
    })
  });
}));

app.get('/api/1/floors/:id', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  return getSelf(conn, getAuthToken(req)).then(user => {
    if (!user && options.all) {
      return Promise.reject(403);
    }
    var tenantId = user ? user.tenantId : '';
    var id = req.params.id;
    log.system.debug('get: ' + id);
    var getFloorWithObjects = options.all ?
      db.getEditingFloorWithObjects(conn, tenantId, id) :
      db.getPublicFloorWithObjects(conn, tenantId, id);
    return getFloorWithObjects.then(floor => {
      if (!floor) {
        return Promise.reject(404);
      }
      log.system.debug('gotFloor: ' + id + ' ' + floor.objects.length);
      return Promise.resolve(floor);
    })
  });
}));

app.get('/api/1/search/*', inTransaction((conn, req, res) => {
  var token = getAuthToken(req);
  var options = url.parse(req.url, true).query;
  var query = req.params[0];

  return getSelf(conn, token).then(user => {
    return profileService.search(config.profileServiceRoot, token, query).then(people => {
      var tenantId = user ? user.tenantId : '';
      return db.search(conn, tenantId, query, options.all, people).then(result => {
        return Promise.resolve({
          result: result,
          people: people
        });
      });
    });
  });
}));

// TODO move to service logic
function isValidFloor(floor) {
  if (!floor.name.trim()) {
    return false;
  }
  return true;
}

app.put('/api/1/floors/:id', inTransaction((conn, req, res) => {
  return getSelf(conn, getAuthToken(req)).then((user) => {
    if (!user) {
      return Promise.reject(403);
    }
    var newFloor = req.body;
    if (newFloor.id && req.params.id !== newFloor.id) {
      return Promise.reject(400);
    }
    if (!isValidFloor(newFloor)) {
      return Promise.reject(400);
    }
    var updateBy = user.id;
    return db.saveFloor(conn, user.tenantId, newFloor, updateBy).then(floor => {
      log.system.debug('saved floor: ' + floor.id);
      return Promise.resolve(floor);
    });
  });
}));

// publish
app.put('/api/1/floors/:id/public', inTransaction((conn, req, res) => {
  var token = getAuthToken(req)
  return getSelf(conn, token).then((user) => {
    if (!user || user.role !== 'admin') {
      return Promise.reject(403);
    }
    var id = req.params.id;
    var updateBy = user.id;
    return db.publishFloor(conn, user.tenantId, id, updateBy).then((floor) => {
      log.system.info('published floor: ' + floor.id + '/' + floor.version);
      return Promise.resolve(floor);
    });
  });
}));

app.delete('/api/1/floors/:id', inTransaction((conn, req, res) => {
  var token = getAuthToken(req)
  return getSelf(conn, token).then((user) => {
    if (!user || user.role !== 'admin') {
      return Promise.reject(403);
    }
    var id = req.params.id;
    return db.deleteFloor(conn, user.tenantId, id).then(() => {
      log.system.info('deleted floor');
      return Promise.resolve();
    });
  });
}));

app.get('/api/1/objects/:id', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  return getSelf(conn, getAuthToken(req)).then(user => {
    var tenantId = user ? user.tenantId : '';
    var id = req.params.id;
    return db.getObjectByIdFromPublicFloor(conn, id).then(object => {
      if (!object) {
        return Promise.reject(404);
      }
      return Promise.resolve(object);
    });
  });
}));

app.patch('/api/1/objects', inTransaction((conn, req, res) => {
  return getSelf(conn, getAuthToken(req)).then((user) => {
    if (!user) {
      return Promise.reject(403);
    }
    var objectsChange = req.body;
    return db.saveObjectsChange(conn, objectsChange).then(objectsChange => {
      log.system.debug('saved objects');
      return Promise.resolve(objectsChange);
    });
  });
}));

// app.put('/api/1/objects/:id', inTransaction((conn, req, res) => {
//   return getSelf(conn, getAuthToken(req)).then((user) => {
//     if(!user) {
//       return Promise.reject(403);
//     }
//     var newObject = req.body;
//     if(newObject.id && req.params.id !== newObject.id) {
//       return Promise.reject(400);
//     }
//     var updateAt = Date.now();
//     return db.saveObject(conn, newObject, updateAt).then((object) => {
//       log.system.debug('saved object: ' + object.id);
//       return Promise.resolve(object);
//     });
//   });
// }));

app.put('/api/1/images/:id', inTransaction((conn, req, res) => {
  return new Promise((resolve, reject) => {
    getSelf(conn, getAuthToken(req)).then((user) => {
      if (!user || user.role !== 'admin') {
        return reject(403);
      }
      var id = req.params.id;
      var all = [];
      req.on('data', (data) => {
        all.push(data);
      });
      req.on('end', () => {
        var image = Buffer.concat(all);
        db.saveImage(conn, 'images/floors/' + id, image).then(() => {
          // res.end();
          resolve({});
        }).catch(reject);
      })
    });
  });
}));

process.on('uncaughtException', (e) => {
  log.system.error('uncaughtException');
  log.system.error(e.stack);
});

var port = 3000;
app.listen(port, () => {
  log.system.info('server listening on port ' + port + '.');
});

// For now, execute batch process here.
function doCreateObjectOptTable() {
  commands.createObjectOptTable().then(() => {
    log.system.info('done');
  }).catch(e => {
    log.system.error(e);
  });
}
doCreateObjectOptTable();
setInterval(function() {
  doCreateObjectOptTable();
}, 1000 * 60 * 20);
