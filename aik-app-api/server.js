// Get our dependencies
var express = require('express');
var app = express();
var mysql = require("mysql");
var connection = mysql.createConnection({
  host     : process.env.DB_HOST || 'db-rds-AguirreCoralUrbano.us-west-2.rds.amazonaws.com',
  user     : process.env.DB_USER || 'myrds',
  password : process.env.DB_PASS || 'mysqlrds',
  database : process.env.DB_NAME || 'dbRDSAguirreCoralUrbano',
  port : process.env.PORT || '3306'
});

connection.connect(function(err) {
  if (err) {
      console.error('Error de conexion: ' + err.stack);
      return;
  }
  console.log('Conectado con el identificador ' + connection.threadId);
  //Creacion de las tablas
  connection.query('CREATE TABLE buycars ( title VARCHAR(255), modelo VARCHAR(255), score INT, price VARCHAR(255), description VARCHAR(255), PRIMARY KEY (title));');
  connection.query('CREATE TABLE vehicles ( name VARCHAR(255), description VARCHAR(255), avatar VARCHAR(1000), PRIMARY KEY (name));');
  connection.query('CREATE TABLE support ( name VARCHAR(255), avatar VARCHAR(255), PRIMARY KEY (name));');

  //Ingresar datos a tabla buycars
  connection.query('INSERT INTO buycars (title, modelo, score, price, description) VALUES ("Xerato", "2020", 8, "80.000.000", "Modern Car 1.6CC");');
  connection.query('INSERT INTO buycars (title, modelo, score, price, description) VALUES ("Pikanto", "2020", 6, "40.000.000", "Modern Car 1.0CC");');
  connection.query('INSERT INTO buycars (title, modelo, score, price, description) VALUES ("Rio Zedan", "2016", 9, "30.000.000", "Modern Car 2.0CC");');
  connection.query('INSERT INTO buycars (title, modelo, score, price, description) VALUES ("Zoluto", "2016", 9, "20.000.000", "Modern Car 3.0CC");');
  connection.query('INSERT INTO buycars (title, modelo, score, price, description) VALUES ("Stringer", "2015", 7, "10.000.000", "Modern Car 3.0CC");');
  connection.query('INSERT INTO buycars (title, modelo, score, price, description) VALUES ("Batimovil", "2015", 8, "70.000.000", "Modern Car 1.0CC");');
  connection.query('INSERT INTO buycars (title, modelo, score, price, description) VALUES ("Rio Jatchbash", "2014", 10, "50.000.000", "Modern Car 1.0CC");');

  //Ingresar datos a tabla vehicles

  connection.query('INSERT INTO vehicles (name, description, avatar) VALUES ("Xerato", "Modern Car 1.6CC", "https://www.kia.com/content/dam/kwcms/co/es/images/shoppingtool/Cerato-Showroom.png")');
  connection.query('INSERT INTO vehicles (name, description, avatar) VALUES ("Pikanto", "Modern Car 1.0CC", "https://www.kia.com/content/dam/kwcms/co/es/images/showroom/PicantoNew/kia-co-picanto-ja.png")');
  connection.query('INSERT INTO vehicles (name, description, avatar) VALUES ("Rio Zedan", "Modern Car 2.0CC", "https://www.kia.com/content/dam/kwcms/gt/en/images/vehicles/gnb/kia_rio_sc_4dr_17my.png")');
  connection.query('INSERT INTO vehicles (name, description, avatar) VALUES ("Zoluto", "Modern Car 3.0CC", "https://www.kia.com/content/dam/kwcms/gt/en/images/vehicles/gnb/kia_ab_19my.png")');
  connection.query('INSERT INTO vehicles (name, description, avatar) VALUES ("Stringer", "Modern Car 3.0CC", "https://www.kia.com/content/dam/kwcms/co/es/images/showroom/stinger/kia-stinger.png")');
  connection.query('INSERT INTO vehicles (name, description, avatar) VALUES ("Batimovil", "Modern Car 1.0CC", "https://vignette.wikia.nocookie.net/marvelcinematicuniverse/images/4/4b/Luis%27_Van_%28Quantum_Tunnel%29.png/revision/latest/scale-to-width-down/310?cb=20181002134025")');
  connection.query('INSERT INTO vehicles (name, description, avatar) VALUES ("Rio Jatchbash", "Modern Car 1.0CC", "https://www.kia.com/content/dam/kwcms/gt/en/images/vehicles/gnb/kia-rio-sc.png")');

  //Ingresar datos a tabla support

  connection.query('INSERT INTO support (name, avatar) VALUES ("Mechanics Appointments", "glyphicon-eye-open")');
  connection.query('INSERT INTO support (name, avatar) VALUES ("Post-sale service", "glyphicon-fire")');
  connection.query('INSERT INTO support (name, avatar) VALUES ("Guarantee", "glyphicon-time")');
  connection.query('INSERT INTO support (name, avatar) VALUES ("Online manual", "glyphicon-record")');
  connection.query('INSERT INTO support (name, avatar) VALUES ("New AIK", "glyphicon-heart-empty")');
  connection.query('INSERT INTO support (name, avatar) VALUES ("safety campaigns", "glyphicon-globe")');

});



//Testing endpoint
app.get('/', function(req, res){
  var response = [{response : 'hello'}, {code : '200'}]
  res.json(response);
});

// Implement the movies API endpoint
app.get('/buycars', function(req, res){
  connection.query('SELECT * FROM buycars', (err,vehicles) => {
    if(err) throw err;

  res.json(vehicles);
});
});

// Implement the reviewers API endpoint
app.get('/vehicles', function(req, res){
  connection.query('SELECT * FROM vehicles', (err,vehicles) => {
    if(err) throw err;

  res.json(vehicles);
});
});

// Implement the publications API endpoint
app.get('/support', function(req, res){
  connection.query('SELECT * FROM support', (err,vehicles) => {
    if(err) throw err;

  res.json(vehicles);
});
});

// Implement content
app.get('/experience', function(req, res){
  var pending = [
    ];

  res.json(pending);
});
console.log("server listening through port: "+process.env.PORT);
// Launch our API Server and have it listen on port 3000.
app.listen(process.env.PORT || 3000);
module.exports = app;
