var url = require('url');
var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var session = require('express-session');
var filestorage = require('./filestorage.js');
var db = require('./db.js');

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

/* Login NOT required */
app.post('/api/v1/login', (req, res) => {
  var id = req.body.id;
  var pass = req.body.pass;
  db.getUser(id, (e, user) => {
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
});

app.post('/api/v1/logout', (req, res) => {
  req.session.user = null;
  res.send({});
});

app.use(express.static(publicDir));

function role(req, cb) {
  if(!req.session.user) {
    cb(null, "guest")
  } else {
    db.getUser(req.session.user, (e, user) => {
      if(e) {
        cb(e);
      } else {
        cb(null, user.role);
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
app.get('/api/v1/people/:id', (req, res) => {
  var id = req.params.id;
  db.getPerson(id, (e, person) => {
    if(e) {
      res.status(500).send('');
      return;
    }
    if(!person) {
      res.status(404).send('');
      return;
    }
    res.send(person);
  });
});
app.get('/api/v1/auth', (req, res) => {
  var id = req.session.user;
  if(id) {
    db.getUserWithPerson(id, (e, user) => {
      if(e) {
        res.status(500).send('');
        return;
      }
      res.send(user);
    });
  } else {
    res.send({});
  }
});
app.get('/api/v1/prototypes', (req, res) => {
  role(req, (e, role) => {
    if(e) {
      res.status(500).send('');
      return;
    }
    if(role === 'guest') {
      res.status(401).send('');
      return;
    }
    db.getPrototypes((e, prototypes) => {
      if(e) {
        res.status(500).send('');
        return;
      }
      res.send(prototypes);
    });
  });
});
app.put('/api/v1/prototypes', (req, res) => {
  role(req, (e, role) => {
    if(e) {
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
    db.savePrototypes(prototypes, (e) => {
      if(e) {
        res.status(500).send('');
        return;
      }
      res.send();
    });
  });
});
app.get('/api/v1/colors', (req, res) => {
  role(req, (e, role) => {
    if(e) {
      res.status(500).send('');
      return;
    }
    if(role === 'guest') {
      res.status(401).send('');
      return;
    }
    db.getColors((e, colors) => {
      if(e) {
        res.status(500).send('');
        return;
      }
      res.send(colors);
    });
  });
});
app.put('/api/v1/colors', (req, res) => {
  role(req, (e, role) => {
    if(e) {
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
    db.saveColors(colors, (e) => {
      if(e) {
        res.status(500).send('');
        return;
      }
      res.send();
    });
  });
});
app.get('/api/v1/floors', (req, res) => {
  var options = url.parse(req.url, true).query;
  role(req, (e, role) => {
    if(e) {
      res.status(500).send('');
      return;
    }
    if(role === 'guest' && options.all) {
      res.status(401).send('');
      return;
    }
    db.getFloorsWithEquipments(options.all, (e, floors) => {
      if(e) {
        console.log(e);
        res.status(500).send('');
        return;
      }
      res.send(floors);
    });
  });
});
app.get('/api/v1/search/:query', (req, res) => {
  var options = url.parse(req.url, true).query;
  var query = req.params.query;
  db.search(query, options.all, (e, results) => {
    if(e) {
      res.status(500).send('');
      return;
    }
    res.send(results);
  });
});
app.get('/api/v1/candidate/:name', (req, res) => {
  var name = req.params.name;
  db.getCandidate(name, (e, results) => {
    if(e) {
      res.status(500).send('');
      return;
    }
    res.send(results);
  });
});
app.get('/api/v1/floor/:id/edit', (req, res) => {
  role(req, (e, role) => {
    if(e) {
      res.status(500).send('');
      return;
    }
    if(role === 'guest') {
      res.status(401).send('');
      return;
    }
    var id = req.params.id;
    console.log('get: ' + id);
    db.getFloorWithEquipments(true, id, (e, floor) => {
      if(e) {
        res.status(500).send('');
        return;
      }
      if(floor) {
        res.send(floor);
      } else {
        res.status(404).send('not found by id: ' + id);
      }
    });
  });
});
app.get('/api/v1/floor/:id', (req, res) => {
  var id = req.params.id;
  console.log('get: ' + id);
  db.getFloorWithEquipments(false, id, (e, floor) => {
    if(e) {
      res.status(500).send('');
      return;
    }
    if(floor) {
      res.send(floor);
    } else {
      res.status(404).send('not found by id: ' + id);
    }
  });
});
app.put('/api/v1/floor/:id/edit', (req, res) => {
  role(req, (e, role) => {
    if(e) {
      res.status(500).send('');
      return;
    }
    if(role === 'guest') {
      res.status(401).send('');
      return;
    }
    var id = req.params.id;
    var newFloor = req.body;
    if(id !== newFloor.id) {
      res.status(400).send('');
      return;
    }
    if(!isValidFloor(newFloor)) {
      res.status(400).send('');
      return;
    }
    newFloor.public = false;
    newFloor.updateBy = req.session.user;
    newFloor.updateAt = new Date().getTime();

    db.saveFloorWithEquipments(newFloor, (e) => {
      if(e) {
        res.status(500).send('');
        return;
      }
      console.log('saved floor: ' + id);
      // console.log(newFloor);
      res.send({});
    });
  });
});

// publish
app.post('/api/v1/floor/:id', (req, res) => {
  role(req, (e, role) => {
    if(e) {
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

    db.ensureFloor(id, () => {
      db.publishFloor(newFloor, (e) => {
        if(e) {
          res.status(500).send('');
          return;
        }
        console.log('published floor: ' + id);
        // console.log(newFloor);
        res.send({});
      });
    });
  });

});

app.put('/api/v1/image/:id', (req, res) => {
  role(req, (e, role) => {
    if(e) {
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
      db.saveImage('images/floors/' + id, image, (e) => {
        if(e) {
          res.status(500).send('' + e);
        } else {
          res.end();
        }
      });
    })
  });
});
process.on('uncaughtException', (e) => {
  console.log('uncaughtException');
  console.log(e);
});
db.resetImage('images/floors', () => {
  app.listen(3000, function () {
    console.log('mock server listening on port 3000.');
  });
});
