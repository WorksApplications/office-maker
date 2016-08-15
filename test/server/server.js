var url = require('url');
var express = require('express');
var app = express();
var bodyParser = require('body-parser');
var session = require('express-session');
var fs = require('fs');
var ejs = require('ejs');
var filestorage = require('./lib/filestorage.js');
var db = require('./lib/db.js');
var rdb = require('./lib/mysql.js');
var accountService = require('./lib/account-service');

var config = null;
if(fs.existsSync(__dirname + '/config.json')) {
  config = JSON.parse(fs.readFileSync(__dirname + '/config.json', 'utf8'));
} else {
  config = JSON.parse(fs.readFileSync(__dirname + '/defaultConfig.json', 'utf8'));
}
config.apiRoot = '/api';

var paasMode = config.accountServiceRoot && config.profileServiceRoot;
if(!paasMode) {
  config.accountServiceRoot = '/api';
  config.profileServiceRoot = '/api';
}

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

function getSessionId(req) {
  if(paasMode) {
    if(req.headers['set-cookie']) {
      return req.headers['set-cookie']['AUTH_SESSION'];
    } else {
      return null;
    }
  } else {
    return req.session.user;
  }
}

function getSelf(conn, sessionId) {
  if(!sessionId) {
    return Promise.reject(401);
  }
  if(paasMode) {
    return accountService.whoami(config.accountService, sessionId).then((user) => {
      if(!user) {
        return Promise.reject(401);
      }
      return Promise.resolve(user);
    });
  } else {
    var id = sessionId;
    return db.getUser(conn, id).then((user) => {
      if(!user) {
        return Promise.reject(404);
      }
      return Promise.resolve(user);
    });
  }
}

function getPerson(conn, sessionId, personId) {
  return paasMode ?
    profileService.getPerson(config.profileServiceRoot, sessionId, personId) :
    db.getPerson(conn, personId);
}

/* For on-premiss mode only */
app.post('/api/v1/authentication', inTransaction((conn, req, res) => {
  // ignore tenantId
  var id = req.body.id;
  var pass = req.body.pass;
  return db.getUser(conn, id).then((user) => {
    if(user && hash(pass) === user.pass) {
      return Promise.resolve(id);
    } else {
      return Promise.reject(401);
    }
  }).then((user) => {
    req.session.user = id;
    return Promise.resolve({});
  });
}));

/* For on-premiss mode only */
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

var templateDir = __dirname + '/template';
var indexHtml = ejs.render(fs.readFileSync(templateDir + '/index.html', 'utf8'), {
  apiRoot: config.apiRoot,
  title: config.title
});
var loginHtml = ejs.render(fs.readFileSync(templateDir + '/login.html', 'utf8'), {
  accountServiceRoot: config.accountServiceRoot,
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
  var sessionId = getSessionId(req);
  var id = req.params.id;
  return getSelf(conn, sessionId).then((user) => {
    var getPerson = paasMode ?
      profileService.getPerson(config.profileServiceRoot, sessionId, id) :
      db.getPerson(conn, id);

    return getPerson.then((person) => {
      if(!person) {
        return Promise.reject(404);
      }
      return Promise.resolve(person);
    });
  });
}));

app.get('/api/v1/self', inTransaction((conn, req, res) => {
  var sessionId = getSessionId(req);
  if(!sessionId) {
    return Promise.resolve({});
  }
  return getSelf(conn, sessionId).then((user) => {
    return getPerson(conn, sessionId, user.personId).then((person) => {
      user.person = person;
      return Promise.resolve(user);
    });
  });
}));

app.get('/api/v1/users/:id', inTransaction((conn, req, res) => {
  var sessionId = getSessionId(req);
  var userId = req.params.id;
  return getSelf(conn, sessionId).then((user) => {
    if(!user) {
      return Promise.reject(401);
    }
    if(paasMode) {
      var user = {
        id: userId,
        role: 'admin'
      };
      return profileService.getByUserId(userId).then((person) => {
        user.person = person;
        return Promise.resolve(user);
      });
    } else {
      return db.getUser(conn, userId).then((user) => {
        if(!user) {
          return Promise.reject(404);
        }
        return db.getPerson(conn, user.personId);
      }).then((person) => {
        user.person = person;
        return Promise.resolve(user);
      });
    }
  });
}));

app.get('/api/v1/prototypes', inTransaction((conn, req, res) => {
  return getSelf(conn, getSessionId(req)).then((user) => {
    if(!user) {
      return Promise.reject(401);
    }
    return db.getPrototypes(conn, user.tenantId).then((prototypes) => {
      return Promise.resolve(prototypes);
    });
  });
}));

app.put('/api/v1/prototypes', inTransaction((conn, req, res) => {
  return getSelf(conn, getSessionId(req)).then((user) => {
    if(!user) {
      return Promise.reject(401);
    }
    var prototypes = req.body;
    if(!prototypes || !prototypes.length) {
      return Promise.reject(403);
    }
    return db.savePrototypes(conn, user.tenantId, prototypes).then(() => {
      return Promise.resolve({});
    });
  })
}));

app.get('/api/v1/colors', inTransaction((conn, req, res) => {
  return getSelf(conn, getSessionId(req)).then((user) => {
    if(!user) {
      return Promise.reject(401);
    }
    //TODO tenantId
    return db.getColors(conn, user.tenantId).then((colors) => {
      return Promise.resolve(colors);
    })
  })
}));

app.put('/api/v1/colors', inTransaction((conn, req, res) => {
  return getSelf(conn, getSessionId(req)).then((user) => {
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
  return getSelf(conn, getSessionId(req)).then((user) => {
    if(!user && options.all) {
      return Promise.reject(401);
    }
    // ignore all option for now
    return db.getFloorsInfoWithObjects(conn, user.tenantId).then((floorInfoList) => {
      return Promise.resolve(floorInfoList);
    })
  });
}));

app.get('/api/v1/search/:query', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  var query = req.params.query;
  if(paasMode) {
    return getSelf(conn, getSessionId(req)).then((user) => {
      return db.searchWithProfileService(config.profileServiceRoot, id, user.tenantId, query, options.all);
    });
  } else {
    return db.search(conn, '', query, options.all);
  }
}));

app.get('/api/v1/candidates/:name', inTransaction((conn, req, res) => {
  var sessionId = getSessionId(req);
  var name = req.params.name;
  if(paasMode) {
    // TODO query from browser
    return profielService.search(config.profileServiceRoot, sessionId, name);
  } else {
    return db.getCandidate(conn, name);
  }
}));

app.get('/api/v1/floors/:id', inTransaction((conn, req, res) => {
  var options = url.parse(req.url, true).query;
  return getSelf(conn, getSessionId(req)).then((user) => {
    if(!user) {
      return Promise.reject(404);//401?
    }
    var id = req.params.id;
    console.log('get: ' + id);
    // TODO tenantId
    return db.getFloorWithObjects(conn, user.tenantId, options.all, id).then((floor) => {
      if(!floor) {
        return Promise.reject(404);
      }
      console.log('gotFloor: ' + id + ' ' + floor.objects.length);
      return Promise.resolve(floor);
    })
  });
}));

app.put('/api/v1/floors/:id', inTransaction((conn, req, res) => {
  return getSelf(conn, getSessionId(req)).then((user) => {
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
    return db.saveFloorWithObjects(conn, user.tenantId, newFloor, updateBy).then((newIdAndVersion) => {
      console.log('saved floor: ' + newIdAndVersion.id);
      return Promise.resolve(newIdAndVersion);
    });
  });
}));

// publish
app.put('/api/v1/floors/:id/public', inTransaction((conn, req, res) => {
  var sessionId = getSessionId(req)
  return getSelf(conn, sessionId).then((user) => {
    if(!user || user.role !== 'admin') {
      return Promise.reject(401);
    }
    var id = req.params.id;
    var updateBy = user.id;
    //TODO tenantId
    return db.publishFloor(conn, user.tenantId, id, updateBy).then((newVersion) => {
      console.log('published floor: ' + id + '/' + newVersion);
      return Promise.resolve({ version : newVersion });
    });
  });
}));

app.put('/api/v1/images/:id', inTransaction((conn, req, res) => {
  return new Promise((resolve, reject) => {
    getSelf(conn, getSessionId(req)).then((user) => {
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
  console.log('server listening on port 3000.');
  if(paasMode) {
    console.log('paas mode');
  } else {
    console.log('on-premiss mode');
  }
});
