# Zachary's Karate Club — the canonical social network dataset
# Source: Zachary, W.W. (1977) "An Information Flow Model for Conflict
# and Fission in Small Groups." J. Anthropological Research 33(4):452-473
#
# 34 members of a university karate club, observed 1970-1972. A dispute
# between instructor "Mr. Hi" (node 0) and club president "John A"
# (node 33) split the club into two factions. Zachary predicted every
# member's allegiance except node 8 using max-flow/min-cut. This dataset
# is the standard benchmark for community detection (Girvan & Newman 2002).
#
# Data from networkx.karate_club_graph() — 34 nodes, 78 undirected edges.
# Faction labels: "Hi" = Mr. Hi's group, "Officer" = John A's group.
let
  g = import ./graph.nix {};

  # Faction membership from the original paper
  # Hi = sided with the instructor; Officer = sided with the president
  addMember = id: faction: g.addNode id faction;

  withNodes =
    addMember "n0" "Hi"          # Mr. Hi (instructor) — hub, degree 16
    (addMember "n1" "Hi"
    (addMember "n2" "Hi"
    (addMember "n3" "Hi"
    (addMember "n4" "Hi"
    (addMember "n5" "Hi"
    (addMember "n6" "Hi"
    (addMember "n7" "Hi"
    (addMember "n8" "Hi"         # predicted Officer, actually went Hi
    (addMember "n9" "Officer"
    (addMember "n10" "Hi"
    (addMember "n11" "Hi"
    (addMember "n12" "Hi"
    (addMember "n13" "Hi"
    (addMember "n14" "Officer"
    (addMember "n15" "Officer"
    (addMember "n16" "Hi"
    (addMember "n17" "Hi"
    (addMember "n18" "Officer"
    (addMember "n19" "Hi"
    (addMember "n20" "Officer"
    (addMember "n21" "Hi"
    (addMember "n22" "Officer"
    (addMember "n23" "Officer"
    (addMember "n24" "Officer"
    (addMember "n25" "Officer"
    (addMember "n26" "Officer"
    (addMember "n27" "Officer"
    (addMember "n28" "Officer"
    (addMember "n29" "Officer"
    (addMember "n30" "Officer"
    (addMember "n31" "Officer"
    (addMember "n32" "Officer"
    (addMember "n33" "Officer"   # John A (president) — hub, degree 17
    g.emptyGraph)))))))))))))))))))))))))))))))))
  ;

  # All 78 undirected edges from the original adjacency matrix
  # Edge IDs encode the endpoint pair for traceability
  e = eid: s: t: g.addEdge eid s t false;

  network =
    # Node 0 (Mr. Hi) connections — degree 16
    e "e0_1" "n0" "n1"
    (e "e0_2" "n0" "n2"
    (e "e0_3" "n0" "n3"
    (e "e0_4" "n0" "n4"
    (e "e0_5" "n0" "n5"
    (e "e0_6" "n0" "n6"
    (e "e0_7" "n0" "n7"
    (e "e0_8" "n0" "n8"
    (e "e0_10" "n0" "n10"
    (e "e0_11" "n0" "n11"
    (e "e0_12" "n0" "n12"
    (e "e0_13" "n0" "n13"
    (e "e0_17" "n0" "n17"
    (e "e0_19" "n0" "n19"
    (e "e0_21" "n0" "n21"
    (e "e0_31" "n0" "n31"
    # Node 1 connections (not already listed)
    (e "e1_2" "n1" "n2"
    (e "e1_3" "n1" "n3"
    (e "e1_7" "n1" "n7"
    (e "e1_13" "n1" "n13"
    (e "e1_17" "n1" "n17"
    (e "e1_19" "n1" "n19"
    (e "e1_21" "n1" "n21"
    (e "e1_30" "n1" "n30"
    # Node 2 connections
    (e "e2_3" "n2" "n3"
    (e "e2_7" "n2" "n7"
    (e "e2_8" "n2" "n8"
    (e "e2_9" "n2" "n9"
    (e "e2_13" "n2" "n13"
    (e "e2_27" "n2" "n27"
    (e "e2_28" "n2" "n28"
    (e "e2_32" "n2" "n32"
    # Node 3 connections
    (e "e3_7" "n3" "n7"
    (e "e3_12" "n3" "n12"
    (e "e3_13" "n3" "n13"
    # Node 4
    (e "e4_6" "n4" "n6"
    (e "e4_10" "n4" "n10"
    # Node 5
    (e "e5_6" "n5" "n6"
    (e "e5_10" "n5" "n10"
    (e "e5_16" "n5" "n16"
    # Node 6
    (e "e6_16" "n6" "n16"
    # Node 8
    (e "e8_30" "n8" "n30"
    (e "e8_32" "n8" "n32"
    (e "e8_33" "n8" "n33"
    # Node 9
    (e "e9_33" "n9" "n33"
    # Node 13
    (e "e13_33" "n13" "n33"
    # Nodes 14-15
    (e "e14_32" "n14" "n32"
    (e "e14_33" "n14" "n33"
    (e "e15_32" "n15" "n32"
    (e "e15_33" "n15" "n33"
    # Node 18
    (e "e18_32" "n18" "n32"
    (e "e18_33" "n18" "n33"
    # Node 19
    (e "e19_33" "n19" "n33"
    # Nodes 20, 22
    (e "e20_32" "n20" "n32"
    (e "e20_33" "n20" "n33"
    (e "e22_32" "n22" "n32"
    (e "e22_33" "n22" "n33"
    # Node 23
    (e "e23_25" "n23" "n25"
    (e "e23_27" "n23" "n27"
    (e "e23_29" "n23" "n29"
    (e "e23_32" "n23" "n32"
    (e "e23_33" "n23" "n33"
    # Nodes 24-25
    (e "e24_25" "n24" "n25"
    (e "e24_27" "n24" "n27"
    (e "e24_31" "n24" "n31"
    (e "e25_31" "n25" "n31"
    # Node 26
    (e "e26_29" "n26" "n29"
    (e "e26_33" "n26" "n33"
    # Node 27
    (e "e27_33" "n27" "n33"
    # Nodes 28-31
    (e "e28_31" "n28" "n31"
    (e "e28_33" "n28" "n33"
    (e "e29_32" "n29" "n32"
    (e "e29_33" "n29" "n33"
    (e "e30_32" "n30" "n32"
    (e "e30_33" "n30" "n33"
    (e "e31_32" "n31" "n32"
    (e "e31_33" "n31" "n33"
    # Node 32-33
    (e "e32_33" "n32" "n33"
    withNodes)))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))))
  ;
in {
  paper = "Zachary 1977, J. Anthropological Research 33(4):452-473";
  members = g.nodeCount network;
  interactions = g.edgeCount network;

  # The two faction leaders
  mrHi_degree = g.degree "n0" network;       # 16 — the instructor
  johnA_degree = g.degree "n33" network;      # 17 — the president

  # Node 2 is the key bridge — high betweenness centrality
  # Connected to both factions despite being labeled "Hi"
  node2_neighbors = g.neighbors "n2" network;

  # The misclassified node: node 8 went with Mr. Hi but
  # min-cut predicts Officer faction
  node8_neighbors = g.neighbors "n8" network;

  json = g.toGraphJSON network;
}
