var url = require('url');
var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var session = require('express-session');
var filestorage = require('./filestorage.js');
var db = require('./db.js');
var rdb = require('./rdb2.js');

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
    rdb.forConnectionAndTransaction((e, conn, done) => {
      if(e) {
        console.log(e)
        res.status(500).send('');
      } else {
        var originalSend = res.send;
        var originalStatus = res.status;
        var newRes = Object.assign({}, res, {
          status: function() {
            var args = arguments;
            return originalStatus.apply(res, args);
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
                  // res.status(500);
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
  db.getUser(conn, id, (e, user) => {
    if(e) {
      res.status(500).send('');
    } else {
      if(hash(pass) === user.pass) {
        req.session.user = id;
        res.send({});
      } else {
        res.status(401).send('');
      }
    }
  });
}));

app.post('/api/v1/logout', (req, res) => {
  req.session.user = null;
  res.send({});
});

app.use(express.static(publicDir));

function role(conn, req, cb) {
  if(!req.session.user) {
    cb(null, "guest")
  } else {
    db.getUser(conn, req.session.user, (e, user) => {
      if(e) {
        cb(e);
      } else {
        cb(null, user.role, user);
      }
    });
  }
}

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
  db.getPerson(conn, id, (e, person) => {
    if(e) {
      console.log(e);
      res.status(500).send('');
      return;
    }
    if(!person) {
      res.status(404).send('');
      return;
    }
    res.send(person);
  });
}));
app.get('/api/v1/auth', inTransaction((conn, req, res) => {
  var id = req.session.user;
  if(id) {
    db.getUserWithPerson(conn, id, (e, user) => {
      if(e) {
        console.log(e);
        res.status(500).send('');
        return;
      }
      if(!user) {
        res.status(404).send('');
      }
      user.pass = null;
      res.send(user);
    });
  } else {
    res.send({});
  }
}));
app.get('/api/v1/users/:id', inTransaction((conn, req, res) => {
  var id = req.params.id;
  db.getUserWithPerson(conn, id, (e, user) => {
    if(e) {
      console.log(e);
      res.status(500).send('');
      return;
    }
    if(!user) {
      res.status(404).send('');
    }
    user.pass = null;
    res.send(user);
  });
}));
app.get('/api/v1/prototypes', inTransaction((conn, req, res) => {
  role(conn, req, (e, role) => {
    if(e) {
      console.log(e);
      res.status(500).send('');
      return;
    }
    if(role === 'guest') {
      res.status(401).send('');
      return;
    }
    db.getPrototypes(conn, (e, prototypes) => {
      if(e) {
        console.log(e);
        res.status(500).send('');
        return;
      }
      res.send(prototypes);
    });
  });
}));
app.put('/api/v1/prototypes', inTransaction((conn, req, res) => {
  role(conn, req, (e, role) => {
    if(e) {
      console.log(e);
      res.status(500).send('');
      return;
    }
    if(role === 'guest') {
      res.status(401).send('');
      return;
    }
    var prototypes = req.body;
    if(!prototypes || !prototypes_.length) {
      res.status(403).send('');
      return;
    }
    db.savePrototypes(conn, prototypes, (e) => {
      if(e) {
        console.log(e);
        res.status(500).send('');
        return;
      }
      res.send();
    });
  });
}));
app.get('/api/v1/colors', inTransaction((conn, req, res) => {
  role(conn, req, (e, role) => {
    if(e) {
      console.log(e);
      res.status(500).send('');
      return;
    }
    if(role === 'guest') {
      res.status(401).send('');
      return;
    }
    db.getColors(conn, (e, colors) => {
      if(e) {
        console.log(e);
        res.status(500).send('');
        return;
      }
      res.send(colors);
    });
  });
}));
app.put('/api/v1/colors', inTransaction((conn, req, res) => {
  role(conn, req, (e, role) => {
    if(e) {
      console.log(e);
      res.status(500).send('');
      return;
    }
    if(role === 'guest') {
      res.status(401).send('');
      return;
    }
    var colors = req.body;
    if(!colors || !prototypes_.length) {
      res.status(403).send('');
      return;
    }
    db.saveColors(conn, colors, (e) => {
      if(e) {
        console.log(e);
        res.status(500).send('');
        return;
      }
      res.send();
    });
  });
}));
app.get('/api/v1/floors', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  role(conn, req, (e, role, user) => {
    if(e) {
      console.log(e);
      res.status(500).send('');
      return;
    }
    if(role === 'guest' && options.all) {
      res.status(401).send('');
      return;
    }
    // ignore all option for now
    db.getFloorsInfoWithEquipments(conn, (e, floorInfoList) => {
      if(e) {
        console.log(e);
        res.status(500).send('');
        return;
      }
      floorInfoList = floorInfoList.filter(function(floorInfo) {
        if(floorInfo[0].id.startsWith('tmp')) {
          return user && floorInfo[0].id === 'tmp-' + user.id;
        } else {
          return true;
        }
      });
      floorInfoList.forEach(function(floorInfo) {
        if(floorInfo[0].id.startsWith('tmp')) {
          floorInfo[0].id = null;
          floorInfo[1].id = null;
        }
      });
      res.send(floorInfoList);
    });
  });
}));
app.get('/api/v1/search/:query', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  var query = req.params.query;
  db.search(conn, query, options.all, (e, results) => {
    if(e) {
      console.log(e);
      res.status(500).send('');
      return;
    }
    results.forEach(function(r) {
      if(r[1] && r[1].startsWith('tmp')) {
        r[1] = 'draft';
      }
    })
    res.send(results);
  });
}));
app.get('/api/v1/candidate/:name', inTransaction((conn, req, res) => {
  var name = req.params.name;
  db.getCandidate(conn, name, (e, results) => {
    if(e) {
      console.log(e);
      res.status(500).send('');
      return;
    }
    res.send(results);
  });
}));
app.get('/api/v1/floor/:id/edit', inTransaction((conn, req, res) => {
  role(conn, req, (e, role, user) => {
    if(e) {
      console.log(e);
      res.status(500).send('');
      return;
    }
    if(role === 'guest') {
      res.status(401).send('');
      return;
    }
    var id = req.params.id === 'draft' ? 'tmp-' + user.id : req.params.id;
    console.log('get: ' + id);
    db.getFloorWithEquipments(conn, true, id, (e, floor) => {
      if(e) {
        res.status(500).send('');
        return;
      }
      if(floor) {
        if(floor.id.startsWith('tmp')) {
          floor.id = null;
        }
        res.send(floor);
      } else {
        res.status(404).send('not found by id: ' + id);
      }
    });
  });
}));
app.get('/api/v1/floor/:id', inTransaction((conn, req, res) => {
  role(conn, req, (e, role, user) => {
    if(role === 'guest' && req.params.id === 'draft') {
      res.status(404).send('not found by id: ' + req.params.id);//401?
      return;
    }
    var id = req.params.id === 'draft' ? 'tmp-' + user.id : req.params.id;
    // console.log('get: ' + id);
    db.getFloorWithEquipments(conn, false, id, (e, floor) => {
      // console.log("floor:", floor)
      if(e) {
        console.log(e);
        res.status(500).send('');
        return;
      }
      if(floor) {
        if(floor.id.startsWith('tmp')) {
          floor.id = null;
        }
        res.send(floor);
      } else {
        res.status(404).send({ message : 'not found by id: ' + id });
      }
    });
  });

}));
app.put('/api/v1/floor/:id/edit', inTransaction((conn, req, res) => {
  role(conn, req, (e, role, user) => {
    if(e) {
      console.log(e);
      res.status(500).send('');
      return;
    }
    if(role === 'guest') {
      res.status(401).send('');
      return;
    }
    var newFloor = req.body;
    if(newFloor.id && req.params.id !== newFloor.id) {
      res.status(400).send('');
      return;
    }
    if(!isValidFloor(newFloor)) {
      res.status(400).send('');
      return;
    }
    var id = req.params.id === 'draft' ? 'tmp-' + user.id : req.params.id;
    newFloor.id = id
    newFloor.public = false;
    newFloor.updateBy = req.session.user;
    newFloor.updateAt = new Date().getTime();

    db.saveFloorWithEquipments(conn, newFloor, true, (e) => {
      if(e) {
        console.log(e);
        res.status(500).send('');
        return;
      }
      console.log('saved floor: ' + id);
      // console.log(newFloor);
      res.send({});
    });
  });
}));

// publish
app.post('/api/v1/floor/:id', inTransaction((conn, req, res) => {
  role(conn, req, (e, role) => {
    if(e) {
      console.log(e);
      res.status(500).send('');
      return;
    }
    if(role !== 'admin') {
      res.status(401).send('');
      return;
    }
    var id = req.params.id;
    var newFloor = req.body;
    if(id !== newFloor.id) {
      res.status(400).send('');
      return;
    }
    if(!id || id.length !== 36) {// must be UUID
      res.status(400).send('');
      return;
    }
    if(!isValidFloor(newFloor)) {
      res.status(400).send('');
      return;
    }
    newFloor.public = true;
    newFloor.updateBy = req.session.user;
    newFloor.updateAt = new Date().getTime();


    db.publishFloor(conn, newFloor, (e) => {
      if(e) {
        console.log(e);
        res.status(500).send('');
        return;
      }
      console.log('published floor: ' + id);
      // console.log(newFloor);
      res.send({});
    });

  });

}));

app.put('/api/v1/image/:id', inTransaction((conn, req, res) => {
  role(conn, req, (e, role) => {
    if(e) {
      console.log(e);
      res.status(500).send('');
      return;
    }
    if(role !== 'admin') {
      res.status(401).send('');
      return;
    }
    var id = req.params.id;
    var all = [];
    req.on('data', (data) => {
      all.push(data);
    });
    req.on('end', () => {
      var image = Buffer.concat(all);
      db.saveImage(conn, 'images/floors/' + id, image, (e) => {
        if(e) {
          res.status(500).send('' + e);
        } else {
          res.end();
        }
      });
    })
  });
}));
process.on('uncaughtException', (e) => {
  console.log('uncaughtException');
  console.log(e.stack);
});
db.resetImage(null, 'images/floors', () => {
  app.listen(3000, function () {
    console.log('mock server listening on port 3000.');
  });
});
