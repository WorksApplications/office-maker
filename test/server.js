var fs = require('fs-extra');
var express = require('express');
var app = express();
var bodyParser = require('body-parser');

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(express.static(__dirname + '/public'));

var floors = {};

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

app.put('/api/v1/image/:id', function (req, res) {
  var id = req.params.id;
  console.log(id);
  var all = [];
  req.on('data', function(data) {
    all.push(data);
  });
  req.on('end', function() {
    var image = Buffer.concat(all);
    fs.writeFile('public/images/' + id, image, function(e) {
      if(e) {
        res.status(500).send('' + e);
      } else {
        res.end();
      }
    });
  })
});

fs.emptyDirSync(__dirname + '/public/images');
app.listen(3000, function () {
  console.log('mock server listening on port 3000.');
});
