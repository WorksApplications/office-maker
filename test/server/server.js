var url = require('url');
var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var session = require('express-session');
var filestorage = require('./filestorage.js');
var db = require('./db.js');
var rdb = require('./mysql.js');

var rdbEnv = rdb.createEnv('localhost', 'root', '', 'map2');

var publicDir = __dirname + '/public';

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(session({
  secret: 'keyboard cat',
  resave: false,
  saveUninitialized: false,
  cookie: {
    maxAge: 30 * 60 * 1000
  }
}));

function hash(str) {
  return str;//TODO
}

function inTransaction(f) {
  return function(req, res) {
    rdbEnv.forConnectionAndTransaction((conn) => {
      return f(conn, req, res);
    }).then((data) => {
      res.send(data);
    }).catch((e) => {
      if(typeof e === 'number' && e >= 400) {
        res.status(e).send('');
      } else {
        console.log('error', e);
        res.status(500).send('');
      }
    });
  }
}

/* Login NOT required */
app.post('/api/v1/login', inTransaction((conn, req, res) => {
  var id = req.body.id;
  var pass = req.body.pass;
  return db.getUser(conn, id).then((user) => {
    if(user && hash(pass) === user.pass) {
      req.session.user = id;
      return Promise.resolve({});
    } else {
      return Promise.reject(401);
    }
  })
}));

app.post('/api/v1/logout', (req, res) => {
  req.session.user = null;
  res.send({});
});

app.use(express.static(publicDir));

function isValidFloor(floor) {
  if(!floor.name.trim()) {
    return false;
  }
  return true;
}

/* Login required */

app.get('/login', (req, res) => {
  res.sendfile(publicDir + '/login.html');
});

app.get('/logout', (req, res) => {
  req.session.user = null;
  res.redirect('/login');
});

app.get('/api/v1/people/:id', inTransaction((conn, req, res) => {
  var id = req.params.id;
  return db.getPerson(conn, id).then((person) => {
    if(!person) {
      return Promise.reject(404);
    }
    return Promise.resolve(person);
  });
}));

app.get('/api/v1/auth', inTransaction((conn, req, res) => {
  var id = req.session.user;
  if(id) {
    return db.getUserWithPerson(conn, id).then((user) => {
      if(!user) {
        return Promise.reject(404);
      }
      user.pass = null;
      return Promise.resolve(user);
    });
  } else {
    return Promise.resolve({});
  }
}));

app.get('/api/v1/users/:id', inTransaction((conn, req, res) => {
  var id = req.params.id;
  return db.getUserWithPerson(conn, id).then((user) => {
    if(!user) {
      return Promise.reject(404);
    }
    user.pass = null;
    return Promise.resolve(user);
  });
}));

app.get('/api/v1/prototypes', inTransaction((conn, req, res) => {
  return db.getUser(conn, req.session.user).then((user) => {
    if(!user) {
      return Promise.reject(401);
    }
    return db.getPrototypes(conn).then((prototypes) => {
      return Promise.resolve(prototypes);
    });
  });
}));

app.put('/api/v1/prototypes', inTransaction((conn, req, res) => {
  return db.getUser(conn, req.session.user).then((user) => {
    if(!user) {
      return Promise.reject(401);
    }
    var prototypes = req.body;
    if(!prototypes || !prototypes.length) {
      return Promise.reject(403);
    }
    return db.savePrototypes(conn, prototypes).then(() => {
      return Promise.resolve({});
    });
  })
}));

app.get('/api/v1/colors', inTransaction((conn, req, res) => {
  return db.getUser(conn, req.session.user).then((user) => {
    if(!user) {
      return Promise.reject(401);
    }
    return db.getColors(conn).then((colors) => {
      return Promise.resolve(colors);
    })
  })
}));

app.put('/api/v1/colors', inTransaction((conn, req, res) => {
  return db.getUser(conn, req.session.user).then((user) => {
    if(!user) {
      return Promise.reject(401);
    }
    var colors = req.body;
    if(!colors || !prototypes_.length) {
      return Promise.reject(403);
    }
    return db.saveColors(conn, colors).then(() => {
      return Promise.resolve({});
    })
  });
}));

app.get('/api/v1/floors', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  return db.getUser(conn, req.session.user).then((user) => {
    if(!user && options.all) {
      return Promise.reject(401);
    }
    // ignore all option for now
    return db.getFloorsInfoWithObjects(conn).then((floorInfoList) => {
      return Promise.resolve(floorInfoList);
    })
  });
}));

app.get('/api/v1/search/:query', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  var query = req.params.query;
  return db.search(conn, query, options.all).then((results) => {
    return Promise.resolve(results);
  });
}));

app.get('/api/v1/candidates/:name', inTransaction((conn, req, res) => {
  var name = req.params.name;
  return db.getCandidate(conn, name).then((results) => {
    return Promise.resolve(results);
  });
}));

app.get('/api/v1/floors/:id', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  return db.getUser(conn, req.session.user).then((user) => {
    if(!user) {
      return Promise.reject(404);//401?
    }
    var id = req.params.id;
    console.log('get: ' + id);
    return db.getFloorWithObjects(conn, options.all, id).then((floor) => {
      if(!floor) {
        return Promise.reject(404);
      }
      console.log('gotFloor: ' + id + ' ' + floor.objects.length);
      return Promise.resolve(floor);
    })
  });
}));

app.put('/api/v1/floors/:id', inTransaction((conn, req, res) => {
  return db.getUser(conn, req.session.user).then((user) => {
    if(!user) {
      return Promise.reject(401);
    }
    var newFloor = req.body;
    if(newFloor.id && req.params.id !== newFloor.id) {
      return Promise.reject(400);
    }
    if(!isValidFloor(newFloor)) {
      return Promise.reject(400);
    }
    var updateBy = user.id;
    return db.saveFloorWithObjects(conn, newFloor, updateBy).then((newIdAndVersion) => {
      console.log('saved floor: ' + newIdAndVersion.id);
      return Promise.resolve(newIdAndVersion);
    });
  });
}));

// publish
app.put('/api/v1/floors/:id/public', inTransaction((conn, req, res) => {
  return db.getUser(conn, req.session.user).then((user) => {
    if(!user || user.role !== 'admin') {
      return Promise.reject(401);
    }
    var id = req.params.id;
    var updateBy = req.session.user;
    return db.publishFloor(conn, id, updateBy).then((newVersion) => {
      console.log('published floor: ' + id + '/' + newVersion);
      return Promise.resolve({ version : newVersion });
    });
  });
}));

app.put('/api/v1/images/:id', inTransaction((conn, req, res) => {
  return new Promise((resolve, reject) => {
    db.getUser(conn, req.session.user).then((user) => {
      if(!user || user.role !== 'admin') {
        return Promise.reject(401);
      }
      var id = req.params.id;
      var all = [];
      req.on('data', (data) => {
        all.push(data);
      });
      req.on('end', () => {
        var image = Buffer.concat(all);
        db.saveImage(conn, 'images/floors/' + id, image).then(() => {
          res.end();
          // TODO commit
        }).catch(reject);
      })
    });
  });
}));

process.on('uncaughtException', (e) => {
  console.log('uncaughtException');
  console.log(e.stack);
});

app.listen(3000, () => {
  console.log('mock server listening on port 3000.');
});
