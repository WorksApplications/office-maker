var express = require('express');
var app = express();
var bodyParser = require('body-parser');

app.use(bodyParser.json());
app.use(express.static(__dirname + '/public'));

var floors = {
  '1': {
    id: '1',
    name: '2ndFloor',
    equipments: [ { id: '1', x: 80, y:60, width: 80, height: 60, color: '#fa0', name: 'Foo' } ],
    width: 700,
    height: 350,
  }
};

app.get('/floor/:id', function (req, res) {
  var id = req.params.id;
  var floor = floors[id];
  console.log(floor);
  if(floor) {
    res.send(floor);
  } else {
    res.status(404).send('not found by id: ' + id);
  }
});

app.put('/floor/:id', function (req, res) {
  var id = req.params.id;
  var newFloor = req.body;
  if(id !== newFloor.id) {
    throw "invalid!";
  }
  floors[id] = newFloor;
  console.log('saved floor: ' + id);
  console.log(newFloor);
  res.send('');
});

app.listen(3000, function () {
  console.log('mock server listening on port 3000.');
});
