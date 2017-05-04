// read file from excel
var parsedJSON = require('./data.json');

// load the Cloudant library
var async = require('async'),
  Cloudant = require('cloudant'),
  username = "smarttravelchandra",
  password = "Lifestyle@123",
  cloudant = Cloudant({account:username, password:password}),
  dbname = 'coupons',
  doc = null,
  db = cloudant.db.use(dbname);

  for(var i = 0; i < parsedJSON.length; i++) {
    var obj = parsedJSON[i];
    console.log(obj._id);

    // create a document
	 db.insert({ _id: obj._id.toString(), date: obj.date, "description": obj.description, "location": obj.location}, function(err, data) {
    console.log("Error:", err);
    console.log("Data:", data);
    // callback(err, data);
  });

}

// create doc records in cloudant


