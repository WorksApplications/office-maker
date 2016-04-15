var express = require('express');
var app = express();

app.get('/floor/:id', function (req, res) {
  res.send('Hello World!');
});

app.put('/floor/:id', function (req, res) {
  res.send('Hello World!');
});

app.listen(3000, function () {
  console.log('mock server listening on port 3000.');
});
