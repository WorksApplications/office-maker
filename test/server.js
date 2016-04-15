var express = require('express');
var app = express();
var bodyParser = require('body-parser');

app.use(bodyParser.json());
app.use(express.static(__dirname + '/public'));

var floors = {
}


app.get('/floor/:id', function (req, res) {
  var id = req.params.id;
  console.log(id);
  var floor = floors[id];
  res.send('Hello World!');
});

app.put('/floor/:id', function (req, res) {
  var id = req.params.id;
  var newFloor = req.body;
  if(id !== newFloor.id) {
    throw "invalid!";
  }
  floors[id] = newFloor;
  console.log('saved floor: ' + id);
  res.send('');
});

app.listen(3000, function () {
  console.log('mock server listening on port 3000.');
});
