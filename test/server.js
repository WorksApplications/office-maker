var url = require('url');
var fs = require('fs-extra');
var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var session = require('express-session');

var publicDir = __dirname + '/public';

var floors = {};
var passes = {
  admin01: 'admin01',
  user01 : 'user01'
};
var users = {
  admin01: { id:'admin01', org: 'Sample Co.,Ltd', name: 'Admin01', mail: 'admin01@xxx.com', role: 'admin' },
  user01 : { id:'user01', org: 'Sample Co.,Ltd', name: 'User01', mail: 'user01@xxx.com', role: 'general' }
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
app.post('/api/v1/login', function(req, res) {
  var id = req.body.id;
  var pass = req.body.pass;
  if(passes[id] === pass) {
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
    return users[req.session.user].role;
  }
}

function isValidFloor(floor) {
  if(!floor.name.trim()) {
    return false;
  }
  return true;
}

function getFloor(withPrivate, id) {
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
function getFloors(withPrivate) {
  return Object.keys(floors).map(function(id) {
    return getFloor(withPrivate, id);
  }).filter(function(floor) {
    return !!floor;
  });
}
function ensureFloor(id) {
  if(!floors[id]) {
    floors[id] = [];
  }
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
  var person = users[id];
  if(!person) {
    res.status(404).send('');
    return;
  }
  res.send(person);
});
app.get('/api/v1/auth', function(req, res) {
  var id = req.session.user;
  if(id) {
    var user = users[id];
    res.send(user);
  } else {
    res.send({});
  }
});
app.get('/api/v1/floors', function (req, res) {
  var options = url.parse(req.url, true).query;
  if(role(req) === 'guest' && options.all) {
    res.status(401).send('');
    return;
  }
  res.send(getFloors(options.all));
});
app.get('/api/v1/search/:query', function (req, res) {
  var options = url.parse(req.url, true).query;
  var query = req.params.query;
  var results = getFloors(options.all).reduce(function(memo, floor) {
    return floor.equipments.reduce(function(memo, e) {
      if(e.name.indexOf(query) >= 0) {
        return memo.concat([[e, floor.id]]);
      } else {
        return memo;
      }
    }, memo);
  }, []);
  res.send(results);
});
app.get('/api/v1/candidate/:name', function (req, res) {
  var name = req.params.name;
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
  res.send(results);
});
app.get('/api/v1/floor/:id/edit', function (req, res) {
  if(role(req) === 'guest') {
    res.status(401).send('');
    return;
  }
  var id = req.params.id;
  console.log('get: ' + id);
  var floor = getFloor(true, id);
  if(floor) {
    res.send(floor);
  } else {
    res.status(404).send('not found by id: ' + id);
  }
});
app.get('/api/v1/floor/:id', function (req, res) {
  var id = req.params.id;
  console.log('get: ' + id);
  var floor = getFloor(false, id);
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
  if(floors[id]) {
    if(floors[id][0].public) {
      floors[id].unshift(newFloor);
    } else {
      floors[id][0] = newFloor;
    }
  } else {
    floors[id] = [newFloor];
  }
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
  ensureFloor(id);
  if(floors[id][0] && !floors[id][0].public) {
    floors[id][0] = newFloor;
  } else {
    floors[id].unshift(newFloor);
  }
  console.log('published floor: ' + id);
  console.log(Object.keys(floors).map(function(key) { return key + ' => ' + floors[key].map(function(f) { return f.public }) } ));
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
    fs.writeFile(publicDir + '/images/' + id, image, function(e) {
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

fs.emptyDirSync(publicDir + '/images');
app.listen(3000, function () {
  console.log('mock server listening on port 3000.');
});
