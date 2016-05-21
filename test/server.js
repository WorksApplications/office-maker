var url = require('url');
var fs = require('fs-extra');
var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var session = require('express-session');
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

/* Login NOT required */
app.post('/api/v1/login', function(req, res) {
  var id = req.body.id;
  var pass = req.body.pass;
  if(db.getPass(id) === pass) {
    req.session.user = id;
    res.send({});
  } else {
    res.status(401).send('');
  }
});

app.post('/api/v1/logout', function(req, res) {
  req.session.user = null;
  res.send({});
});

app.use(express.static(publicDir));

function role(req) {
  if(!req.session.user) {
    return "guest"
  } else {
    return db.getUser(req.session.user).role;
  }
}

function isValidFloor(floor) {
  if(!floor.name.trim()) {
    return false;
  }
  return true;
}

/* Login required */

app.get('/login', function(req, res) {
  res.sendfile(publicDir + '/login.html');
});
app.get('/logout', function(req, res) {
  req.session.user = null;
  res.redirect('/login');
});
app.get('/api/v1/people/:id', function(req, res) {
  var id = req.params.id;
  var person = db.getPerson(id);
  if(!person) {
    res.status(404).send('');
    return;
  }
  res.send(person);
});
app.get('/api/v1/auth', function(req, res) {
  var id = req.session.user;
  if(id) {
    res.send(db.getUser(id));
  } else {
    res.send({});
  }
});
app.get('/api/v1/prototypes', function (req, res) {
  if(role(req) === 'guest') {
    res.status(401).send('');
    return;
  }
  res.send(db.getPrototypes());
});
app.put('/api/v1/prototypes', function (req, res) {
  if(role(req) === 'guest') {
    res.status(401).send('');
    return;
  }
  var prototypes = req.body;
  if(!prototypes || !prototypes_.length) {
    res.status(403).send('');
    return;
  }
  db.savePrototypes(prototypes);
  res.send();
});
app.get('/api/v1/colors', function (req, res) {
  if(role(req) === 'guest') {
    res.status(401).send('');
    return;
  }
  res.send(db.getColors());
});
app.put('/api/v1/colors', function (req, res) {
  if(role(req) === 'guest') {
    res.status(401).send('');
    return;
  }
  var colors = req.body;
  if(!colors || !prototypes_.length) {
    res.status(403).send('');
    return;
  }
  db.saveColors(colors);
  res.send();
});
app.get('/api/v1/floors', function (req, res) {
  var options = url.parse(req.url, true).query;
  if(role(req) === 'guest' && options.all) {
    res.status(401).send('');
    return;
  }
  res.send(db.getFloors(options.all));
});
app.get('/api/v1/search/:query', function (req, res) {
  var options = url.parse(req.url, true).query;
  var query = req.params.query;
  var results = db.search(query, options.all);
  res.send(results);
});
app.get('/api/v1/candidate/:name', function (req, res) {
  var name = req.params.name;
  var results = db.getCandidate(name);
  res.send(results);
});
app.get('/api/v1/floor/:id/edit', function (req, res) {
  if(role(req) === 'guest') {
    res.status(401).send('');
    return;
  }
  var id = req.params.id;
  console.log('get: ' + id);
  var floor = db.getFloor(true, id);
  if(floor) {
    res.send(floor);
  } else {
    res.status(404).send('not found by id: ' + id);
  }
});
app.get('/api/v1/floor/:id', function (req, res) {
  var id = req.params.id;
  console.log('get: ' + id);
  var floor = db.getFloor(false, id);
  if(floor) {
    res.send(floor);
  } else {
    res.status(404).send('not found by id: ' + id);
  }
});
app.put('/api/v1/floor/:id/edit', function (req, res) {
  if(role(req) === 'guest') {
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

  db.saveFloor(newFloor);

  console.log('saved floor: ' + id);
  // console.log(newFloor);
  res.send({});
});

// publish
app.post('/api/v1/floor/:id', function (req, res) {

  if(role(req) !== 'admin') {
    console.log('unauthorized: ' + role(req));
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
    res.status(403).send('');
    return;
  }
  if(!isValidFloor(newFloor)) {
    res.status(400).send('');
    return;
  }
  newFloor.public = true;
  newFloor.updateBy = req.session.user;
  newFloor.updateAt = new Date().getTime();

  db.ensureFloor(id);
  db.publishFloor(newFloor);

  console.log('published floor: ' + id);

  // console.log(newFloor);
  res.send({});
});

app.put('/api/v1/image/:id', function (req, res) {
  if(role(req) !== 'admin') {
    res.status(401).send('');
    return;
  }
  var id = req.params.id;
  var all = [];
  req.on('data', function(data) {
    all.push(data);
  });
  req.on('end', function() {
    var image = Buffer.concat(all);
    db.saveImage(publicDir + '/images/floors/' + id, image, function(e) {
      if(e) {
        res.status(500).send('' + e);
      } else {
        res.end();
      }
    });
  })
});
process.on('uncaughtException', function(e) {
  console.log(e);
});
db.resetImage(publicDir + '/images/floors', function() {
  app.listen(3000, function () {
    console.log('mock server listening on port 3000.');
  });
});
