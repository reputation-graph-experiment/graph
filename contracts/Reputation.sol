library GraphLib {

  // HELPERS //////////////////////////////////////////////////////////////
  // [TODO] - try deploy with private instead of internal

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
  function toBytes(address x) internal returns (bytes b){
    b = new bytes(20);
    for (uint i = 0; i < 20; i++){
      b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
    }
  }

  // 2 addresses => one string
  // [TODO] - Use hashing instead of concat of 2 strings
  function _edgeString (
    address fromAddr, address toAddr
  ) internal returns (string) {
    return strConcat(string(toBytes(fromAddr)),
                     string(toBytes(toAddr)));
  }
  
  // ATTRIBUTES ///////////////////////////////////////////////////////////

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

  struct Graph {
    mapping (address => Member) members;
    mapping (string => EdgeLL) edges;
    uint numMembers;
  }

  // LIB INTERFACE /////////////////////////////////////////////////////////

  function addEdge(
    Graph storage self, address fromAddr, address toAddr
  ) internal {
    Member friender = self.members[fromAddr];
    Member newFriend = self.members[toAddr];

    // New Edge ID
    string memory edgeId = _edgeString(fromAddr, toAddr);

    // From
    string oldFromRootEdgeStr = friender.neighbors;
    EdgeLL oldFromRootEdge = self.edges[oldFromRootEdgeStr];
    friender.neighbors = edgeId;
    oldFromRootEdge.previousFrom = edgeId;

    // To
    string oldToRootEdgeStr = newFriend.neighbors;
    EdgeLL oldToRootEdge = self.edges[oldToRootEdgeStr];
    newFriend.neighbors = edgeId;
    oldToRootEdge.previousTo = edgeId;

    // New Edge
    self.edges[edgeId] = EdgeLL(friender, newFriend,
                                oldFromRootEdgeStr, "",
                                oldToRootEdgeStr, "");
  }

  function removeEdgeId(Graph storage self, string edgeId) internal {
    EdgeLL e = self.edges[edgeId];

    // From
    Member from = e.from;
    if (stringsEqual(e.previousFrom, "")) {
      from.neighbors = e.nextFrom;
    } else {
      self.edges[e.previousFrom].nextFrom = e.nextFrom;
    }
    if (stringsEqual(e.nextFrom, "")) {
      from.neighbors = "";
    } else {
      self.edges[e.nextFrom].previousFrom = e.previousFrom;
    }

    // To
    Member to = e.to;
    if (stringsEqual(e.previousTo, "")) {
      to.neighbors = e.nextTo;
    } else {
      self.edges[e.previousTo].nextTo = e.nextTo;
    }
    if (stringsEqual(e.nextTo, "")) {
      to.neighbors = "";
    } else {
      self.edges[e.nextTo].previousTo = e.previousTo;
    }

    delete self.edges[edgeId];
  }

  function removeEdgeByAddr(
    Graph storage self,
    address fromAddr, address toAddr
  ) internal {
    removeEdgeId(self, _edgeString(fromAddr, toAddr));
  }

  // Member-stuff //

  function addMember(Graph storage self, address addr) internal {
    self.members[addr] = Member("");
    self.numMembers += 1;
  }

  function removeMember(Graph storage self, address addr) internal {
    Member m = self.members[addr];

    // Remove all edges
    while (!stringsEqual(m.neighbors, "")) {
      removeEdgeId(self, m.neighbors);
    }

    delete self.members[addr];
    self.numMembers -= 1;
  }

}


contract Reputation {

  using GraphLib for GraphLib.Graph;
  GraphLib.Graph graph;

  function createMember (address newMemberAddr) external  {
    // Don't create if the newMemberAddr corresponding object exists
    if (bytes(graph.members[newMemberAddr].neighbors).length == 0 ) {
      graph.addMember(newMemberAddr);
      graph.addEdge(msg.sender, newMemberAddr);
      graph.addEdge(newMemberAddr, msg.sender);
    }
  }

  function leaveGraph() external {
    graph.removeMember(msg.sender);
  }

  function removeFriend(address friendAddr) external {
    graph.removeEdgeByAddr(msg.sender, friendAddr);
  }

  function addFriend(address friendAddr) external {
    graph.addEdge(msg.sender, friendAddr);
  }

  function getNumMembers() external returns (uint) {
    return graph.numMembers;
  }
}
