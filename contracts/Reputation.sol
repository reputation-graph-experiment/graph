contract Reputation {

  // HELPERS //////////////////////////////////////////////////////////////

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
  
  // ATTRIBUTES ///////////////////////////////////////////////////////////

  mapping (address => Member) members;
  mapping (string => EdgeLL) edges;
  uint public numMembers;

  // Members are nodes of the graph
  struct Member {
    string neighbors; // Edge string-ID in ``edges``
  }

  // A -> B is stored both in A and B's neighbors, so that it is easy to
  // remove a node and all edges involving this node in linear complexity
  // in |Adj(n)|
  struct EdgeLL {
    Member from;
    Member to;
    string nextFrom;
    string previousFrom;
    string nextTo;
    string previousTo;
  }

  // 2 addresses => one string
  function _edgeString (
    address fromAddr, address toAddr
  ) internal returns (string) {
    return strConcat(string(toBytes(fromAddr)),
                     string(toBytes(toAddr)));
  }

  function _addEdge(address fromAddr, address toAddr) internal {
    Member friender = members[fromAddr];
    Member newFriend = members[toAddr];

    // New Edge ID
    string memory edgeId = _edgeString(fromAddr, toAddr);

    // From
    string oldFromRootEdgeStr = friender.neighbors;
    EdgeLL oldFromRootEdge = edges[oldFromRootEdgeStr];
    friender.neighbors = edgeId;
    oldFromRootEdge.previousFrom = edgeId;

    // To
    string oldToRootEdgeStr = newFriend.neighbors;
    EdgeLL oldToRootEdge = edges[oldToRootEdgeStr];
    newFriend.neighbors = edgeId;
    oldToRootEdge.previousTo = edgeId;

    // New Edge
    edges[edgeId] = EdgeLL(friender, newFriend,
                           oldFromRootEdgeStr, "",
                           oldToRootEdgeStr, "");
  }

  function _removeEdgeId(string edgeId) internal {
    EdgeLL e = edges[edgeId];

    // From
    Member from = e.from;
    if (stringsEqual(e.previousFrom, "")) {
      from.neighbors = e.nextFrom;
    } else {
      edges[e.previousFrom].nextFrom = e.nextFrom;
    }
    if (stringsEqual(e.nextFrom, "")) {
      from.neighbors = "";
    } else {
      edges[e.nextFrom].previousFrom = e.previousFrom;
    }

    // To
    Member to = e.to;
    if (stringsEqual(e.previousTo, "")) {
      to.neighbors = e.nextTo;
    } else {
      edges[e.previousTo].nextTo = e.nextTo;
    }
    if (stringsEqual(e.nextTo, "")) {
      to.neighbors = "";
    } else {
      edges[e.nextTo].previousTo = e.previousTo;
    }

    delete edges[edgeId];
  }

  function _removeEdgeByAddr(
    address fromAddr, address toAddr
  ) internal {
    _removeEdgeId(_edgeString(fromAddr, toAddr));
  }

  // Member-stuff //

  function _addMember(address addr) internal {
    members[addr] = Member("");
    numMembers += 1;
  }

  function _removeMember(address addr) internal {
    Member m = members[addr];

    // Remove all edges
    while (!stringsEqual(m.neighbors, "")) {
      _removeEdgeId(m.neighbors);
    }

    delete members[addr];
    numMembers -= 1;
  }


  // External interface //////////////////////////////////////////////

  function createMember (address newMemberAddr) external  {
    // Don't create if the newMemberAddr corresponding object exists
    if (bytes(members[newMemberAddr].neighbors).length == 0 ) {
      _addMember(newMemberAddr);
      _addEdge(msg.sender, newMemberAddr);
      _addEdge(newMemberAddr, msg.sender);
    }
  }

  function leaveGraph() external {
    _removeMember(msg.sender);
  }

  function removeFriend(address friendAddr) external {
    _removeEdgeByAddr(msg.sender, friendAddr);
  }

  function addFriend(address friendAddr) external {
    _addEdge(msg.sender, friendAddr);
  }
}
