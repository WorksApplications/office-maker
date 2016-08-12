var url = require('url');
var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var session = require('express-session');
var filestorage = require('./lib/filestorage.js');
var db = require('./lib/db.js');
var rdb = require('./lib/mysql.js');
var fs = require('fs');
var ejs = require('ejs');

var config = null;
if(fs.existsSync(__dirname + '/config.json')) {
  config = JSON.parse(fs.readFileSync(__dirname + '/config.json', 'utf8'));
} else {
  config = JSON.parse(fs.readFileSync(__dirname + '/defaultConfig.json', 'utf8'));
}
config.apiRoot = '/api';

var rdbEnv = rdb.createEnv(config.mysql.host, config.mysql.user, config.mysql.pass, 'map2');

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
        console.log(e.stack);
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

var templateDir = __dirname + '/template'
var indexHtml = ejs.render(fs.readFileSync(templateDir + '/index.html', 'utf8'), {
  apiRoot: config.apiRoot,
  title: config.title
});
var loginHtml = ejs.render(fs.readFileSync(templateDir + '/login.html', 'utf8'), {
  apiRoot: config.apiRoot,
  title: config.title
});

app.get('/', (req, res) => {
  res.send(indexHtml);
});

app.get('/login', (req, res) => {
  res.send(loginHtml);
});

app.get('/logout', (req, res) => {
  req.session.user = null;
  res.redirect('/login');
});

app.get('/api/v1/people/:id', inTransaction((conn, req, res) => {
  var id = req.params.id;
  // TODO tenantId
  var getPerson = config.profileServiceRoot ?
    db.getPersonWithProfileService(config.profileServiceRoot, '', id) :
    db.getPerson(conn, id);

  return getPerson.then((person) => {
    if(!person) {
      return Promise.reject(404);
    }
    return Promise.resolve(person);
  });
}));

app.get('/api/v1/auth', inTransaction((conn, req, res) => {
  var id = req.session.user;
  if(id) {
    // TODO tenantId
    console.log(config.profileServiceRoot);
    var getUserWithPerson = config.profileServiceRoot ?
      db.getUserWithPersonWithProfileService(config.profileServiceRoot, conn, '', id) :
      db.getUserWithPerson(conn, id);
    return getUserWithPerson.then((user) => {
      if(!user) {
        return Promise.reject(404);
      }
      if(!user.person) {
        console.log('invalid data: person not found');
        return Promise.reject(500);
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
  // TODO tenantId
  var getUserWithPerson = config.profileServiceRoot ?
    db.getUserWithPersonWithProfileService(config.profileServiceRoot, conn, '', id) :
    db.getUserWithPerson(conn, id);
  return getUserWithPerson.then((user) => {
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
    //TODO tenantId
    return db.getPrototypes(conn, '').then((prototypes) => {
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
    //TODO tenantId
    return db.savePrototypes(conn, '', prototypes).then(() => {
      return Promise.resolve({});
    });
  })
}));

app.get('/api/v1/colors', inTransaction((conn, req, res) => {
  return db.getUser(conn, req.session.user).then((user) => {
    if(!user) {
      return Promise.reject(401);
    }
    //TODO tenantId
    return db.getColors(conn, '').then((colors) => {
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
    //TODO tenantId
    return db.saveColors(conn, '', colors).then(() => {
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
    // TODO tenantId
    return db.getFloorsInfoWithObjects(conn, '').then((floorInfoList) => {
      return Promise.resolve(floorInfoList);
    })
  });
}));

app.get('/api/v1/search/:query', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  var query = req.params.query;
  // TODO tenantId
  var search = config.profileServiceRoot ?
    db.searchWithProfileService(config.profileServiceRoot, '', query, options.all) :
    db.search(conn, '', query, options.all);
  return search;
}));

app.get('/api/v1/candidates/:name', inTransaction((conn, req, res) => {
  var name = req.params.name;
  // TODO tenantId
  var getCandidate = config.profileServiceRoot ?
    db.getCandidateWithProfileService(config.profileServiceRoot, '', name) :
    db.getCandidate(conn, name);
  return getCandidate;
}));

app.get('/api/v1/floors/:id', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  return db.getUser(conn, req.session.user).then((user) => {
    if(!user) {
      return Promise.reject(404);//401?
    }
    var id = req.params.id;
    console.log('get: ' + id);
    // TODO tenantId
    return db.getFloorWithObjects(conn, '', options.all, id).then((floor) => {
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
    //TODO tenantId
    return db.saveFloorWithObjects(conn, '', newFloor, updateBy).then((newIdAndVersion) => {
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
    //TODO tenantId
    return db.publishFloor(conn, '', id, updateBy).then((newVersion) => {
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
