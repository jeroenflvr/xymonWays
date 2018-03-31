var express = require('express');
var app = express();
var fs = require("fs");
var net = require('net');
var parseString = require('xml2js').parseString;

var xymonServer = '127.0.0.1';
var xymonPort = 1984;
var xymonAPIPort = 1976;


app.get('/xymonapi', function (req, res) {
	host = req.query.host  || "";
	color = req.query.color || "";
	page = req.query.page || "";
	test = req.query.test || "";
	fields = req.query.fields || "";

	    console.log('params:');
	    console.log(req.query);
        console.log('number of options passed: ' + Object.keys(req.query).length);

    var client = new net.Socket();
      client.connect(xymonPort, xymonServer, function() {
      client.write('xymondxboard host=' + host + " test=" + test + " page=" + page + " color=" + color + " fields=" + fields);
      client.end();
    });
    client.on('data', function(data,result){
      parseString(data,function (err, r) {
      result = JSON.stringify(r)  ;
	});
      console.log(result);
      res.end(result);
   });
})

var server = app.listen(xymonAPIPort, function () {

  var host = server.address().address
  var port = server.address().port

  console.log("XyMonAPI is listening on http://%s:%s", host, port)

})
