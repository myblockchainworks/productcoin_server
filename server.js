var express = require('express'),
    cors = require('cors'),
    app = express();
//var router = express.Router();
var bodyParser = require('body-parser');
var Web3 = require('web3');

var bodyParser = require('body-parser')
app.use(bodyParser.urlencoded({
    extended: false
}));
app.use(bodyParser.json());

//session configs
var expressSession = require('express-session');
var cookieParser = require('cookie-parser'); // the session is stored in a cookie, so we use this to parse it


app.use(cookieParser());

app.use(expressSession({
    secret: 'test_session',
    resave: false,
    saveUninitialized: true
}));


//For enabling CORS
app.use(cors());


var web3;
if (typeof web3 !== 'undefined') {
    web3 = new Web3(web3.currentProvider);
} else {
    web3 = new Web3(new Web3.providers.HttpProvider("http://10.0.0.14:8545"));
    console.log(web3.net.peerCount);
}

//web3.eth.defaultAccount = 0xaf148d7e9c5a1f6ee493f0a808fdc877953bf273;
web3.eth.defaultAccount=web3.eth.accounts[0];

var productCoinContractAddress = "0xe8bbec5ab972d4628ecc4bdeccdf3c7434e68341";

var productCoinContractABI = [ { "constant": false, "inputs": [ { "name": "productNominalValue", "type": "uint256" }, { "name": "productIssueSize", "type": "uint256" }, { "name": "productPayoutRate", "type": "uint256" }, { "name": "productName", "type": "string" }, { "name": "productAmountSymbol", "type": "string" }, { "name": "productExpiryDate", "type": "uint256" }, { "name": "productLaunchDate", "type": "uint256" }, { "name": "productPayoutsPerYear", "type": "uint256" } ], "name": "createProduct", "outputs": [], "payable": false, "type": "function" }, { "constant": false, "inputs": [ { "name": "index", "type": "uint256" }, { "name": "_from", "type": "address" }, { "name": "_to", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "transferAmountFrom", "outputs": [], "payable": false, "type": "function" }, { "constant": false, "inputs": [], "name": "kill", "outputs": [], "payable": false, "type": "function" }, { "constant": true, "inputs": [], "name": "getProductCount", "outputs": [ { "name": "", "type": "uint256" } ], "payable": false, "type": "function" }, { "constant": true, "inputs": [ { "name": "index", "type": "uint256" } ], "name": "getProductDetail", "outputs": [ { "name": "", "type": "address" }, { "name": "", "type": "uint256" }, { "name": "", "type": "uint256" }, { "name": "", "type": "uint256" }, { "name": "", "type": "uint256" }, { "name": "", "type": "uint256" }, { "name": "", "type": "uint256" } ], "payable": false, "type": "function" }, { "constant": false, "inputs": [ { "name": "index", "type": "uint256" }, { "name": "_to", "type": "address" }, { "name": "_value", "type": "uint256" } ], "name": "transferAmount", "outputs": [], "payable": false, "type": "function" }, { "constant": false, "inputs": [ { "name": "index", "type": "uint256" }, { "name": "userAccount", "type": "address" } ], "name": "processUserPayout", "outputs": [], "payable": false, "type": "function" }, { "constant": false, "inputs": [ { "name": "index", "type": "uint256" } ], "name": "processPayout", "outputs": [], "payable": false, "type": "function" }, { "constant": true, "inputs": [], "name": "owner", "outputs": [ { "name": "", "type": "address" } ], "payable": false, "type": "function" }, { "constant": false, "inputs": [ { "name": "data", "type": "bytes32" } ], "name": "bytes32ToString", "outputs": [ { "name": "", "type": "string" } ], "payable": false, "type": "function" }, { "constant": false, "inputs": [], "name": "checkTriggerAlerts", "outputs": [], "payable": false, "type": "function" }, { "constant": true, "inputs": [ { "name": "index", "type": "uint256" } ], "name": "getProduct", "outputs": [ { "name": "", "type": "string" }, { "name": "", "type": "uint256" }, { "name": "", "type": "string" }, { "name": "", "type": "uint256" }, { "name": "", "type": "uint256" }, { "name": "", "type": "uint256" }, { "name": "", "type": "uint256" } ], "payable": false, "type": "function" }, { "constant": true, "inputs": [ { "name": "index", "type": "uint256" }, { "name": "account", "type": "address" } ], "name": "getUserBalance", "outputs": [ { "name": "", "type": "uint256" } ], "payable": false, "type": "function" }, { "constant": true, "inputs": [ { "name": "", "type": "uint256" } ], "name": "productCoins", "outputs": [ { "name": "", "type": "address" } ], "payable": false, "type": "function" }, { "inputs": [], "payable": true, "type": "constructor" } ];

//contract data

var productCoinContract = web3.eth.contract(productCoinContractABI).at(productCoinContractAddress);


app.get('/', function(req, res) {

    res.send("This is the API server developed for ProductCoin");
})

app.get('/getProductCoinCount', function(req, res) {

    productCoinContract.getProductCount.call(function(err, result) {
        console.log(result);
        if (!err) {
            res.json({"productCoinCount":result});
        } else
            res.status(401).json("Error" + err);
    });
});

app.post('/createProductCoin', function(req, res) {

     var productName = req.body._productName;
     var productNominalValue = req.body._productNominalValue;
     var productIssueSize = req.body._productIssueSize;
     var productPayoutRate = req.body._productPayoutRate;
     var productSymbol = req.body._productSymbol;
     var launchDate = req.body._launchDate;
     var expiryDate = req.body._expiryDate;
     var payoutsPerYear = req.body._payoutsPerYear;

     productCoinContract.createProduct.sendTransaction(productNominalValue, productIssueSize, productPayoutRate, productName, productSymbol, expiryDate, launchDate, payoutsPerYear,{
        from: web3.eth.defaultAccount,gas:4712388
     }, function(err, result) {
        console.log(result);
        if (!err) {
            res.end(JSON.stringify(result));
        } else
            res.status(401).json("Error" + err);
    });

});

app.post('/transferAmount', function(req, res) {

  var selectedIndex = req.body._selectedIndex;
  var fromAccount = req.body._fromAccount;
  var toAccount = req.body._toAccount;
  var amountValue = req.body._amountValue;

  productCoinContract.transferAmount.sendTransaction(selectedIndex, toAccount, amountValue,{
     from: web3.eth.defaultAccount, gas:4712388
  }, function(err, result) {
     console.log(result);
     if (!err) {
         res.end(JSON.stringify(result));
     } else
         res.status(401).json("Error" + err);
 });

});

app.post('/getUserBalance', function(req, res) {
  var currentIndex = req.body._currentIndex;
  var userAccount = req.body._userAccount;
  productCoinContract.getUserBalance.call(currentIndex, userAccount, function(err, result) {
      console.log(result);
      if (!err) {
           res.json(JSON.stringify(result));
      } else
          res.status(401).json("Error" + err);
  });
});

app.post('/processUserPayout', function(req, res) {
  var currentIndex = req.body._currentIndex;
  var userAccount = req.body._userAccount;
  productCoinContract.processUserPayout.sendTransaction(currentIndex, userAccount, { from: web3.eth.defaultAccount, gas:400000 }, function(err, result) {
      console.log(result);
      if (!err) {
          res.json({"Success":true});
      } else
          res.status(401).json("Error" + err);
  });
});

app.post('/updatePayoutProcessedStatus', function(req, res) {
    var currentIndex = req.body._currentIndex;

    productCoinContract.processPayout.sendTransaction(currentIndex, { from: web3.eth.defaultAccount }, function(err, result) {
        console.log(result);
        if (!err) {
            res.json({"Success":true});
        } else
            res.status(401).json("Error" + err);
    });
});

app.post('/getProductCoinDetail', function(req, res) {

    var currentIndex = req.body._currentIndex;

    productCoinContract.getProduct.call(currentIndex, function(err, result) {
        console.log(result);
        if (!err) {
            res.json({"Name":result[0],"Amount":result[1],"Symbol":result[2],"LaunchDate":result[3],"ExpiryDate":result[4],"PayoutsPerYear":result[5],"ReservedForPayout":result[6]});
        } else
            res.status(401).json("Error" + err);
    });
});

app.post('/getProductCoinMoreDetail', function(req, res) {

    var currentIndex = req.body._currentIndex;

    productCoinContract.getProductDetail.call(currentIndex, function(err, result) {
        console.log(result);
        if (!err) {
            res.json({"ProductAddress":result[0], "FirstPayoutDate":result[1],"NextPayoutDate":result[2],"Status":result[3],"NominalValue":result[4],"IssueSize":result[5],"PayoutRate":result[6]});
        } else
            res.status(401).json("Error" + err);
    });
});

app.post('/checkTriggerAlerts', function(req, res) {

    productCoinContract.checkTriggerAlerts.sendTransaction({ from: web3.eth.defaultAccount }, function(err, result) {
        console.log(result);
        if (!err) {
            res.json({"Success":true});
        } else
            res.status(401).json("Error" + err);
    });
});


app.listen(3001, function() {
    console.log('app running on port : 3001');
});
