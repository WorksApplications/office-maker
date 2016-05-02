var fs = require('fs-extra');
var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var session = require('express-session');

var publicDir = __dirname + '/public';

var floors = {};
var users = {
  admin01: { pass: 'admin01', mail: 'admin01@xxx.com', role: 'admin' },
  user01 : { pass: 'user01', mail: 'user01@xxx.com', role: 'general' }
};


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

app.get('/login', function(req, res) {
  res.sendfile(publicDir + '/login.html');
});
app.get('/logout', function(req, res) {
  req.session.user = null;
  res.redirect('/login');
});
app.post('/api/v1/login', function(req, res) {
  var id = req.body.id;
  var pass = req.body.pass;
  var account = users[id];
  if(account && (account.pass === pass)) {
    req.session.user = id;
    res.send({});
  } else {
    res.status(401).send('');
  }
});
app.use(express.static(publicDir));

// Login
app.use('/', function(req, res, next) {
  if (req.session.user) {
    next();
  } else {
    if(req.url.indexOf('/api') === 0) {
      res.status(401).send('');
    } else {
      res.redirect('/login');
    }
  }
});

/* Login required */

app.get('/api/v1/floor/:id/edit', function (req, res) {
  var id = req.params.id;
  var floor = floors[id];
  console.log('get: ' + id);
  // console.log(floor);
  if(floor) {
    res.send(floor);
  } else {
    res.status(404).send('not found by id: ' + id);
  }
});

app.put('/api/v1/floor/:id/edit', function (req, res) {
  var id = req.params.id;
  var newFloor = req.body;
  if(id !== newFloor.id) {
    throw "invalid!";
  }
  floors[id] = newFloor;
  console.log('saved floor: ' + id);
  // console.log(newFloor);
  res.send('');
});

// publish
app.post('/api/v1/floor/:id', function (req, res) {
  var id = req.params.id;
  var newFloor = req.body;
  console.log(req.body);
  if(id !== newFloor.id) {
    throw "invalid! : " + [id, newFloor.id];
  }
  floors[id] = newFloor;
  console.log('published floor: ' + id);
  // console.log(newFloor);
  res.send('');
});


app.put('/api/v1/image/:id', function (req, res) {
  var id = req.params.id;
  console.log(id);
  var all = [];
  req.on('data', function(data) {
    all.push(data);
  });
  req.on('end', function() {
    var image = Buffer.concat(all);
    fs.writeFile(publicDir + '/images/' + id, image, function(e) {
      if(e) {
        res.status(500).send('' + e);
      } else {
        res.end();
      }
    });
  })
});

fs.emptyDirSync(publicDir + '/images');
app.listen(3000, function () {
  console.log('mock server listening on port 3000.');
});
