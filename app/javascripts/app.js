var numMembers;
// var accounts;
// var account;
// var balance;

function setStatus(message) {
  var status = document.getElementById("status");
  status.innerHTML = message;
};

function refreshNumMembers() {
  var reputation = Reputation.deployed();

  reputation.getNumMembers.call(account, {from: account}).then(function(value) {
    var members_element = document.getElementById("numMembers");
    members_element.innerHTML = value.valueOf();
    numMembers = value.valueOf();
  }).catch(function(e) {
    console.log(e);
    setStatus("Error getting number of members; see log.");
  });
};

function createMember() {
    var reputation = Reputation.deployed();
    reputation._initialMember(account,{from: account}).then(function(){
	setStatus("Creating initial Member...");
    }	
    ).catch(function(e) {
	console.log(e);
	setStatus("Error creating member; see log.");
    });
}

function addNode(){
    var reputation = Reputation.deployed();
    var newGuy = document.getElementById("newGuy").value;
    setStatus(newGuy);
    
    setStatus("Adding new guy... (please wait)");
    
    reputation.createMember(newGuy, {from: account}).then(function(b) {
	if(b){
	setStatus("Added new guy!");
	}
	else{
	setStatus("Failed adding new guy, maybe he already exists?");
	}
	refreshNumMembers();
	return(true);
    }).catch(function(e) {
	console.log(e);
	setStatus("Error adding new guy; see log.");
    });
    
}

// function sendCoin() {
//   var meta = MetaCoin.deployed();

//   var amount = parseInt(document.getElementById("amount").value);
//   var receiver = document.getElementById("receiver").value;

//   setStatus("Initiating transaction... (please wait)");

//   meta.sendCoin(receiver, amount, {from: account}).then(function() {
//     setStatus("Transaction complete!");
//     refreshBalance();
//   }).catch(function(e) {
//     console.log(e);
//     setStatus("Error sending coin; see log.");
//   });
// };

window.onload = function() {
  web3.eth.getAccounts(function(err, accs) {
    if (err != null) {
      alert("There was an error fetching your accounts.");
      return;
    }

    if (accs.length == 0) {
      alert("Couldn't get any accounts! Make sure your Ethereum client is configured correctly.");
      return;
    }

    accounts = accs;
    account = accounts[0];

    if(numMembers == 0){
	createMember();
    }
    refreshNumMembers();

  });
}
