contract Reputation {

    function stringsEqual(string storage _a, string memory _b) internal returns (bool) {
	bytes storage a = bytes(_a);
	bytes memory b = bytes(_b);
	if (a.length != b.length)
	    return false;
	// @todo unroll this loop
	for (uint i = 0; i < a.length; i ++)
	    if (a[i] != b[i])
		return false;
	return true;
    }

    function strConcat(string _a, string _b) internal returns (string){
	bytes memory _ba = bytes(_a);
	bytes memory _bb = bytes(_b);
	string memory abcde = new string(_ba.length + _bb.length);
	bytes memory babcde = bytes(abcde);
	uint k = 0;
	for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
	for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
	return string(babcde);
    }


    // from Stack overflow
    function toBytes(address x) returns (bytes b){
	b = new bytes(20);
	for (uint i = 0; i < 20; i++){
	    b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
	}
    }

    function toString(bytes b) returns (string){
	return(string(b));
    }

    //mapping () memberCount
    mapping (address => Member) members;
    mapping (string => EdgeLL) edges;
    uint numMembers; // number of members

    struct Member {
	address addr;
	string neighbors;
	//mapping (address => string) edges;
    }

    // A -> B is stored both in A and B's neighbors, so that it is easy to
    // remove a node and all edges involving this node in linear complexity
    //in |Adj(n)|
    struct EdgeLL {
	Member from;
	Member to;
	string nextFrom;
	string previousFrom;
	string nextTo;
	string previousTo;
    }

    function getNumMembers() returns (uint){
	return(numMembers);
    }

    function edgeString(address fromAddr,address toAddr) returns (string){
	return(strConcat(toString(toBytes(fromAddr)),toString(toBytes(toAddr))));
    }

    function _addEdge(address fromAddr, address toAddr){
	Member friender = members[fromAddr];
	Member newFriend = members[toAddr];

	//From
	string oldFromRootEdgeStr = friender.neighbors;
	EdgeLL oldFromRootEdge = edges[oldFromRootEdgeStr];
	string memory edgeId = edgeString(fromAddr,toAddr);
	friender.neighbors = edgeId;//strConcat(toString(toBytes(sender)),toString(toBytes(toAddr)));
	oldFromRootEdge.previousFrom = edgeId;
	//friender.edges[toAddr] = edgeId;

	//To
	string oldToRootEdgeStr = newFriend.neighbors;
	EdgeLL oldToRootEdge = edges[oldToRootEdgeStr];
	newFriend.neighbors = edgeId;
	oldToRootEdge.previousTo = edgeId;
	//newFriend.edges[toAddr] = edgeId;

	//From and To
	edges[edgeId] = EdgeLL(friender,newFriend,oldFromRootEdgeStr,"",oldToRootEdgeStr,"");

    }

    function _removeEdge(address fromAddr, address toAddr){
	string memory edgeId = edgeString(fromAddr,toAddr);
	EdgeLL e = edges[edgeId];

	//From
	Member from = members[fromAddr];
	if(stringsEqual(e.previousFrom,"")){
	    from.neighbors = e.nextFrom;
	}
	else{
	    edges[e.previousFrom].nextFrom = e.nextFrom;
	}
	if(stringsEqual(e.nextFrom,""))
	    from.neighbors = "";
	else{
	    edges[e.nextFrom].previousFrom = e.previousFrom;
	}


	//To
	Member to = members[toAddr];
	if(stringsEqual(e.previousTo,"")){
	    to.neighbors = e.nextTo;
	} else{
	    edges[e.previousTo].nextTo = e.nextTo;
	}
	if(stringsEqual(e.nextTo,"")){
	    to.neighbors = "";
	}else{
	    edges[e.nextTo].previousTo = e.previousTo;
	}





	delete(edges[edgeId]);
	//delete members[msg.sender].edges[removed];
    }

    function _removeNode(address nodeAddr){
	Member node = members[nodeAddr];
	//        string edgeId = node.neighbors;
	while(!(stringsEqual(node.neighbors,""))){
	    EdgeLL e = edges[node.neighbors];
	    _removeEdge(e.from.addr,e.to.addr);
	}

	delete members[nodeAddr];
	numMembers -=1;
    }

    function leaveGraph(){
	_removeNode(msg.sender);
    }

    function removeFriend(address friendAddr){
	_removeEdge(msg.sender,friendAddr);
    }

    function addFriend(address friendAddr){
	_addEdge(msg.sender,friendAddr);
    }

    function _initialMember(address ownerAddr){
	Member memory ownerMbr = Member(ownerAddr, "");
	members[ownerAddr] = ownerMbr;
	numMembers = 1;
    }

    function createMember(address newMemberAddr) returns (bool){
	if(members[newMemberAddr].addr == 0)
	    return false;
	Member creator = members[msg.sender];
	members[newMemberAddr] = Member(newMemberAddr, "");
	_addEdge(msg.sender, newMemberAddr);
	_addEdge(newMemberAddr,msg.sender);
	numMembers += 1;
	return true;
    }
}
