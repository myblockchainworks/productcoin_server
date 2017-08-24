pragma solidity ^0.4.8;

contract ProductCoin {
  string public name;
  uint public expiryDate;
  uint public launchDate;
  string public symbol;
  uint8 public decimals;

  uint public nominalValue;
  uint public issueSize;
  uint public payoutRate;

  uint public payoutsPerYear;
  uint public firstPayoutDate;
  uint public nextPayoutDate;

  uint public payoutsDone;
  uint public lastPayoutDone;
  uint public upcomingPayout;

  uint256 public reservedForPayout;

  // Status in each stage of Product
  enum Status {ACTIVE, FIRSTPAYOUTDUE, NEXTPAYOUTDUE, EXPIRED}

  Status public status;

  /* This creates an array with all balances */
  mapping (address => uint256) public balanceOf;

  event Transfer(address indexed from, address indexed to, uint256 value);

  event ExpiryAlert(address ownder, string name);
  event FirstPayoutDueAlert(address ownder, string name);
  event NextPayoutDueAlert(address ownder, string name);

  event PayoutProcessed(address indexed from, address indexed to, uint256 value);

  event ScheduledAlert(address ownder, string result);

  /* Initializes contract with initial supply tokens to the creator of the contract */
  function ProductCoin(uint productNominalValue, uint productIssueSize, uint productPayoutRate, string productName, string productAmountSymbol, uint productExpiryDate, uint productLaunchDate, uint productPayoutsPerYear) {

      uint256 productAmount = productNominalValue * productIssueSize;

      reservedForPayout = (((productPayoutRate *  1000000)/100) * productAmount) / 1000000;

      balanceOf[msg.sender] = productAmount;
      name = productName;
      symbol = productAmountSymbol;
      decimals = 2;
      expiryDate = productExpiryDate;
      launchDate = productLaunchDate;

      nominalValue = productNominalValue;
      issueSize = productIssueSize;
      payoutRate = productPayoutRate;

      payoutsPerYear = productPayoutsPerYear;
      uint payout = 365 / productPayoutsPerYear;
      uint _firstPayoutDate = launchDate + (1000 * 60 * 60 * 24 * payout);
      firstPayoutDate = _firstPayoutDate;
      nextPayoutDate = _firstPayoutDate + (1000 * 60 * 60 * 24 * payout);
      status = Status.ACTIVE;

      lastPayoutDone = 0;

      payoutsDone = 0;

      upcomingPayout = 1;
  }

  /* Send coins */
  function transfer(address _to, uint256 _value) {
      if (balanceOf[msg.sender] < _value) throw;
      if (balanceOf[_to] + _value < balanceOf[_to]) throw;
      balanceOf[msg.sender] -= _value;
      balanceOf[_to] += _value;
      Transfer(msg.sender, _to, _value);
  }

  /* Send coins */
  function transferFrom(address _from, address _to, uint256 _value) {
      if (balanceOf[_from] < _value) throw;
      if (balanceOf[_to] + _value < balanceOf[_to]) throw;
      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;
      Transfer(_from, _to, _value);
  }

  function stringToBytes32(string memory source) returns (bytes32 result) {
      assembly {
          result := mload(add(source, 32))
      }
  }

  function getName() public constant returns (bytes32){
    return stringToBytes32(name);
  }

  function getSymbol() public constant returns (bytes32){
    return stringToBytes32(symbol);
  }

  function getNominalValue() public constant returns (uint) {
    return nominalValue;
  }

  function getIssueSize() public constant returns (uint) {
    return issueSize;
  }

  function getPayoutRate() public constant returns (uint) {
    return payoutRate;
  }

  function getReservedForPayout() public constant returns (uint) {
    return reservedForPayout;
  }

  function getBalance() public constant returns (uint256){
    return balanceOf[msg.sender] - reservedForPayout;
  }

  function getBalanceByUser(address _account) public constant returns (uint) {
    return balanceOf[_account];
  }

  function getExpiryDate() public constant returns (uint){
    return expiryDate;
  }

  function getLaunchDate() public constant returns (uint){
    return launchDate;
  }

  function getNextPayoutDate() public constant returns (uint){
    return nextPayoutDate;
  }

  function getFirstPayoutDate() public constant returns (uint){
    return firstPayoutDate;
  }

  function getPayoutsPerYear() public constant returns (uint){
    return payoutsPerYear;
  }

  function getStatus() public constant returns(uint) {
      uint uintStatus = 0;
      if (status == Status.ACTIVE) {
        uintStatus = 0;
      } else if (status == Status.FIRSTPAYOUTDUE) {
        uintStatus = 1;
      } else if (status == Status.NEXTPAYOUTDUE) {
        uintStatus = 2;
      } else if (status == Status.EXPIRED) {
        uintStatus = 3;
      }
      return uintStatus;
  }

  function checkTriggerAlerts() public constant returns(bool) {
    uint nowTime = now * 1000;
    bool result = false;
    if (expiryDate < nowTime && status != Status.EXPIRED){
      result = true;
    } else if (firstPayoutDate < nowTime && lastPayoutDone == 0) {
      result = true;
    } else if (nextPayoutDate < nowTime && (lastPayoutDone != upcomingPayout)) {
      result = true;
    }
    return result;
  }

  function triggerAlerts() {
    uint nowTime = now * 1000;
    if (expiryDate < nowTime){
      status = Status.EXPIRED;
      ExpiryAlert(msg.sender, name);
    } else if (firstPayoutDate < nowTime &&  lastPayoutDone == 0) {
      status = Status.FIRSTPAYOUTDUE;
      FirstPayoutDueAlert(msg.sender, name);
    } else if (nextPayoutDate < nowTime &&  status == Status.ACTIVE) {
      if(lastPayoutDone != upcomingPayout) {
        status = Status.NEXTPAYOUTDUE;
        NextPayoutDueAlert(msg.sender, name);
      }
    }
  }

  function processPayout() {
    if (status == Status.FIRSTPAYOUTDUE) {
      status = Status.ACTIVE;
      lastPayoutDone = 1;
      payoutsDone = 1;
      upcomingPayout = 2;
    } else if (status == Status.NEXTPAYOUTDUE) {
      status = Status.ACTIVE;
      lastPayoutDone = lastPayoutDone + 1;
      payoutsDone =  payoutsDone + 1;
      if (payoutsDone < payoutsPerYear) {
        uint payout = 365 / payoutsPerYear;
        uint _currentPayoutDate = nextPayoutDate;
        nextPayoutDate = _currentPayoutDate + (1000 * 60 * 60 * 24 * payout);
        upcomingPayout = upcomingPayout + 1;
      }
    }
  }

  function processUserPayout(address userAccount) {
    uint coins = balanceOf[userAccount];
    if (coins > 0) {
      uint payoutValue = (((payoutRate * 1000000) / 100 / payoutsPerYear) * coins) / 1000000;
      reservedForPayout = reservedForPayout - payoutValue;

      // Send Payout
      if (balanceOf[msg.sender] < payoutValue) throw;
      if (balanceOf[userAccount] + payoutValue < balanceOf[userAccount]) throw;
      balanceOf[msg.sender] -= payoutValue;
      balanceOf[userAccount] += payoutValue;
      PayoutProcessed(msg.sender, userAccount, payoutValue);
    }
  }
}

// Products contract
contract Products {

  address public owner; // address of the Contract

  function Products() payable {
    owner = msg.sender;
  }

  // modifier to allow only owner has full control on the function
  modifier onlyOwnder {
    if (msg.sender != owner) {
      throw;
    } else {
      _;
    }
  }

  // Delete / kill the contract... only the owner has rights to do this
  function kill() onlyOwnder {
    suicide(owner);
  }

  ProductCoin[] public productCoins;

  // Create a new product
  function createProduct(uint productNominalValue, uint productIssueSize, uint productPayoutRate, string productName, string productAmountSymbol, uint productExpiryDate, uint productLaunchDate, uint productPayoutsPerYear) onlyOwnder {
    ProductCoin coin = new ProductCoin(productNominalValue, productIssueSize, productPayoutRate, productName, productAmountSymbol, productExpiryDate, productLaunchDate, productPayoutsPerYear);
    productCoins.push(coin);
  }

  function getProductCount() public constant returns (uint) {
		return productCoins.length;
	}

  function bytes32ToString (bytes32 data) returns (string) {
    bytes memory bytesString = new bytes(32);
    for (uint j=0; j<32; j++) {
        byte char = byte(bytes32(uint(data) * 2 ** (8 * j)));
        if (char != 0) {
            bytesString[j] = char;
        }
    }
    return string(bytesString);
  }

  function getUserBalance(uint index, address account) public constant returns (uint) {
    uint balance = productCoins[index].getBalanceByUser(account);
    return (balance);
  }

  function getProduct(uint index) public constant returns(string, uint256, string, uint, uint, uint, uint) {
    bytes32 name = productCoins[index].getName();
    uint256 balance = productCoins[index].getBalance();
    bytes32 symbol = productCoins[index].getSymbol();
    uint launchDate = productCoins[index].getLaunchDate();
    uint expiryDate = productCoins[index].getExpiryDate();
    uint payoutsPerYear = productCoins[index].getPayoutsPerYear();
    uint getReservedForPayout = productCoins[index].getReservedForPayout();
    return (bytes32ToString(name), balance, bytes32ToString(symbol), launchDate, expiryDate, payoutsPerYear, getReservedForPayout);
  }

  function getProductDetail(uint index) public constant returns(address, uint, uint, uint, uint, uint, uint) {
    uint firstPayoutDate = productCoins[index].getFirstPayoutDate();
    uint nextPayoutDate = productCoins[index].getNextPayoutDate();
    uint status = productCoins[index].getStatus();
    uint nominalValue = productCoins[index].getNominalValue();
    uint issueSize = productCoins[index].getIssueSize();
    uint payoutRate = productCoins[index].getPayoutRate();
    return(productCoins[index], firstPayoutDate, nextPayoutDate, status, nominalValue, issueSize, payoutRate);
  }

  function checkTriggerAlerts() {
    for (uint index = 0; index < productCoins.length; index++) {
      productCoins[index].triggerAlerts();
    }
  }

  function processUserPayout(uint index, address userAccount) {
    productCoins[index].processUserPayout(userAccount);
  }

  function processPayout(uint index) {
    productCoins[index].processPayout();
  }

  function transferAmount(uint index, address _to, uint256 _value) {
    productCoins[index].transfer(_to, _value);
  }

  function transferAmountFrom(uint index, address _from, address _to, uint256 _value) {
    productCoins[index].transferFrom(_from, _to, _value);
  }

}
