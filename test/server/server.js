var url = require('url');
var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var session = require('express-session');
var filestorage = require('./filestorage.js');
var db = require('./db.js');
var rdb = require('./rdb.js');

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
    rdbEnv.forConnectionAndTransaction((e, conn, done) => {
      if(e) {
        console.log(e)
        res.status(500).send('');
      } else {
        var originalSend = res.send;
        var originalStatus = res.status;
        var newRes = Object.assign({}, res, {
          status: function() {
            var args = arguments;
            originalStatus.apply(res, args);
            return newRes;
          },
          send: function() {
            var args = arguments;
            if(res.statusCode >= 400) {
              done(true, function(rollbackFailed) {
                if(rollbackFailed) {
                  console.log(rollbackFailed);
                }
                originalSend.apply(res, args);
              });
            } else {
              done(false, function(commitFailed) {
                if(commitFailed) {
                  console.log(commitFailed);
                  newRes.status(500);
                }
                originalSend.apply(res, args);
              });
            }
          }
        });
        f(conn, req, newRes);
      }

    });
  }
}

/* Login NOT required */
app.post('/api/v1/login', inTransaction((conn, req, res) => {
  var id = req.body.id;
  var pass = req.body.pass;
  db.getUser(conn, id).then((user) => {
    if(user && hash(pass) === user.pass) {
      req.session.user = id;
      res.send({});
    } else {
      res.status(401).send('');
    }
  }).catch((e) => {
    console.log(e);
    res.status(500).send('');
  });
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
  db.getPerson(conn, id).then((person) => {
    if(!person) {
      res.status(404).send('');
      return;
    }
    res.send(person);
  }).catch((e) => {
    console.log(e);
    res.status(500).send('');
  });
}));
app.get('/api/v1/auth', inTransaction((conn, req, res) => {
  var id = req.session.user;
  if(id) {
    db.getUserWithPerson(conn, id).then((user) => {
      if(!user) {
        res.status(404).send('');
        return;
      }
      user.pass = null;
      res.send(user);
    }).catch((e) => {
      console.log(e);
      res.status(500).send('');
    });
  } else {
    res.send({});
  }
}));
app.get('/api/v1/users/:id', inTransaction((conn, req, res) => {
  var id = req.params.id;
  db.getUserWithPerson(conn, id).then((user) => {
    if(!user) {
      res.status(404).send('');
      return;
    }
    user.pass = null;
    res.send(user);
  }).catch((e) => {
    console.log(e);
    res.status(500).send('');
  });
}));
app.get('/api/v1/prototypes', inTransaction((conn, req, res) => {
  db.getUser(conn, req.session.user).then((user) => {
    if(!user) {
      res.status(401).send('');
      return;
    }
    db.getPrototypes(conn).then((prototypes) => {
      res.send(prototypes);
    }).catch((e) => {
      console.log(e);
      res.status(500).send('');
    });
  }).catch((e) => {
    console.log(e);
    res.status(500).send('');
  });
}));
app.put('/api/v1/prototypes', inTransaction((conn, req, res) => {
  db.getUser(conn, req.session.user).then((user) => {
    if(!user) {
      res.status(401).send('');
      return;
    }
    var prototypes = req.body;
    if(!prototypes || !prototypes.length) {
      res.status(403).send('');
      return;
    }
    db.savePrototypes(conn, prototypes).then(() => {
      res.send({});
    }).catch((e) => {
      console.log(e);
      res.status(500).send('');
    });
  }).catch((e) => {
    console.log(e);
    res.status(500).send('');
  });
}));
app.get('/api/v1/colors', inTransaction((conn, req, res) => {
  db.getUser(conn, req.session.user).then((user) => {
    if(!user) {
      res.status(401).send('');
      return;
    }
    return db.getColors(conn).then((colors) => {
      res.send(colors);
    })
  }).catch((e) => {
    console.log(e);
    res.status(500).send('');
  });
}));
app.put('/api/v1/colors', inTransaction((conn, req, res) => {
  db.getUser(conn, req.session.user).then((user) => {
    if(!user) {
      return Promise.reject(401);
    }
    var colors = req.body;
    if(!colors || !prototypes_.length) {
      return Promise.reject(403);
    }
    return db.saveColors(conn, colors).then(() => {
      res.send({});
    })
  }).catch((e) => {
    if(typeof e === 'number') {
      res.status(e).send('');
    } else {
      console.log(e);
      res.status(500).send('');
    }
  });
}));
app.get('/api/v1/floors', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  db.getUser(conn, req.session.user).then((user) => {
    if(!user && options.all) {
      return Promise.reject(401);
    }
    // ignore all option for now
    return db.getFloorsInfoWithObjects(conn).then((floorInfoList) => {
      res.send(floorInfoList);
    })
  }).catch((e) => {
    if(typeof e === 'number') {
      res.status(e).send('');
    } else {
      console.log(e);
      res.status(500).send('');
    }
  });
}));

app.get('/api/v1/search/:query', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  var query = req.params.query;
  db.search(conn, query, options.all).then((results) => {
    res.send(results);
  }).catch((e) => {
    console.log(e);
    res.status(500).send('');
  });
}));

app.get('/api/v1/candidates/:name', inTransaction((conn, req, res) => {
  var name = req.params.name;
  db.getCandidate(conn, name).then((results) => {
    res.send(results);
  }).catch((e) => {
    console.log(e);
    res.status(500).send('');
  });
}));

app.get('/api/v1/floors/:id', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  db.getUser(conn, req.session.user).then((user) => {
    if(!user) {
      return Promise.reject(404);//401?
    }
    var id = req.params.id;
    console.log('get: ' + id);
    return db.getFloorWithObjects(conn, options.all, id).then((floor) => {
      if(floor) {
        console.log('gotFloor: ' + id + ' ' + floor.objects.length);
        res.send(floor);
      } else {
        return Promise.reject(404);
      }
    })
  }).catch((e) => {
    if(typeof e === 'number') {
      res.status(e).send('');
    } else {
      console.log(e);
      res.status(500).send('');
    }
  });
}));
app.put('/api/v1/floors/:id', inTransaction((conn, req, res) => {
  db.getUser(conn, req.session.user).then((user) => {
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
      res.send(newIdAndVersion);
    });
  }).catch((e) => {
    if(typeof e === 'number') {
      res.status(e).send('');
    } else {
      console.log(e);
      res.status(500).send('');
    }
  });
}));

// publish
app.put('/api/v1/floors/:id/public', inTransaction((conn, req, res) => {
  db.getUser(conn, req.session.user).then((user) => {
    if(!user || user.role !== 'admin') {
      return Promise.reject(401);
    }
    var id = req.params.id;
    var updateBy = req.session.user;
    return db.publishFloor(conn, id, updateBy).then((newIdAndVersion) => {
      console.log('published floor: ' + newIdAndVersion.id);
      res.send(newIdAndVersion);
    });
  }).catch((e) => {
    if(typeof e === 'number') {
      res.status(e).send('');
    } else {
      console.log(e);
      res.status(500).send('');
    }
  });

}));

app.put('/api/v1/images/:id', inTransaction((conn, req, res) => {
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
      }).catch((e) => {
        console.log(e);
        res.status(500).send('');
      });
    })
  }).catch((e) => {
    if(typeof e === 'number') {
      res.status(e).send('');
    } else {
      console.log(e);
      res.status(500).send('');
    }
  });
}));

process.on('uncaughtException', (e) => {
  console.log('uncaughtException');
  console.log(e.stack);
});

app.listen(3000, () => {
  console.log('mock server listening on port 3000.');
});
