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

  # Faction membership from the original paper
  # Hi = sided with the instructor; Officer = sided with the president

  network = gcl.fromSpec {
    nodes = {
      n0 = "Hi"; # Mr. Hi (instructor) — hub, degree 16
      n1 = "Hi";
      n2 = "Hi";
      n3 = "Hi";
      n4 = "Hi";
      n5 = "Hi";
      n6 = "Hi";
      n7 = "Hi";
      n8 = "Hi"; # predicted Officer, actually went Hi
      n9 = "Officer";
      n10 = "Hi";
      n11 = "Hi";
      n12 = "Hi";
      n13 = "Hi";
      n14 = "Officer";
      n15 = "Officer";
      n16 = "Hi";
      n17 = "Hi";
      n18 = "Officer";
      n19 = "Hi";
      n20 = "Officer";
      n21 = "Hi";
      n22 = "Officer";
      n23 = "Officer";
      n24 = "Officer";
      n25 = "Officer";
      n26 = "Officer";
      n27 = "Officer";
      n28 = "Officer";
      n29 = "Officer";
      n30 = "Officer";
      n31 = "Officer";
      n32 = "Officer";
      n33 = "Officer"; # John A (president) — hub, degree 17
    };

    # All 78 undirected edges from the original adjacency matrix
    # Edge IDs encode the endpoint pair for traceability

    edges = [
      # Node 0 (Mr. Hi) connections — degree 16
      { id = "e0_1"; from = "n0"; to = "n1"; directed = false; }
      { id = "e0_2"; from = "n0"; to = "n2"; directed = false; }
      { id = "e0_3"; from = "n0"; to = "n3"; directed = false; }
      { id = "e0_4"; from = "n0"; to = "n4"; directed = false; }
      { id = "e0_5"; from = "n0"; to = "n5"; directed = false; }
      { id = "e0_6"; from = "n0"; to = "n6"; directed = false; }
      { id = "e0_7"; from = "n0"; to = "n7"; directed = false; }
      { id = "e0_8"; from = "n0"; to = "n8"; directed = false; }
      { id = "e0_10"; from = "n0"; to = "n10"; directed = false; }
      { id = "e0_11"; from = "n0"; to = "n11"; directed = false; }
      { id = "e0_12"; from = "n0"; to = "n12"; directed = false; }
      { id = "e0_13"; from = "n0"; to = "n13"; directed = false; }
      { id = "e0_17"; from = "n0"; to = "n17"; directed = false; }
      { id = "e0_19"; from = "n0"; to = "n19"; directed = false; }
      { id = "e0_21"; from = "n0"; to = "n21"; directed = false; }
      { id = "e0_31"; from = "n0"; to = "n31"; directed = false; }
      # Node 1 connections (not already listed)
      { id = "e1_2"; from = "n1"; to = "n2"; directed = false; }
      { id = "e1_3"; from = "n1"; to = "n3"; directed = false; }
      { id = "e1_7"; from = "n1"; to = "n7"; directed = false; }
      { id = "e1_13"; from = "n1"; to = "n13"; directed = false; }
      { id = "e1_17"; from = "n1"; to = "n17"; directed = false; }
      { id = "e1_19"; from = "n1"; to = "n19"; directed = false; }
      { id = "e1_21"; from = "n1"; to = "n21"; directed = false; }
      { id = "e1_30"; from = "n1"; to = "n30"; directed = false; }
      # Node 2 connections
      { id = "e2_3"; from = "n2"; to = "n3"; directed = false; }
      { id = "e2_7"; from = "n2"; to = "n7"; directed = false; }
      { id = "e2_8"; from = "n2"; to = "n8"; directed = false; }
      { id = "e2_9"; from = "n2"; to = "n9"; directed = false; }
      { id = "e2_13"; from = "n2"; to = "n13"; directed = false; }
      { id = "e2_27"; from = "n2"; to = "n27"; directed = false; }
      { id = "e2_28"; from = "n2"; to = "n28"; directed = false; }
      { id = "e2_32"; from = "n2"; to = "n32"; directed = false; }
      # Node 3 connections
      { id = "e3_7"; from = "n3"; to = "n7"; directed = false; }
      { id = "e3_12"; from = "n3"; to = "n12"; directed = false; }
      { id = "e3_13"; from = "n3"; to = "n13"; directed = false; }
      # Node 4
      { id = "e4_6"; from = "n4"; to = "n6"; directed = false; }
      { id = "e4_10"; from = "n4"; to = "n10"; directed = false; }
      # Node 5
      { id = "e5_6"; from = "n5"; to = "n6"; directed = false; }
      { id = "e5_10"; from = "n5"; to = "n10"; directed = false; }
      { id = "e5_16"; from = "n5"; to = "n16"; directed = false; }
      # Node 6
      { id = "e6_16"; from = "n6"; to = "n16"; directed = false; }
      # Node 8
      { id = "e8_30"; from = "n8"; to = "n30"; directed = false; }
      { id = "e8_32"; from = "n8"; to = "n32"; directed = false; }
      { id = "e8_33"; from = "n8"; to = "n33"; directed = false; }
      # Node 9
      { id = "e9_33"; from = "n9"; to = "n33"; directed = false; }
      # Node 13
      { id = "e13_33"; from = "n13"; to = "n33"; directed = false; }
      # Nodes 14-15
      { id = "e14_32"; from = "n14"; to = "n32"; directed = false; }
      { id = "e14_33"; from = "n14"; to = "n33"; directed = false; }
      { id = "e15_32"; from = "n15"; to = "n32"; directed = false; }
      { id = "e15_33"; from = "n15"; to = "n33"; directed = false; }
      # Node 18
      { id = "e18_32"; from = "n18"; to = "n32"; directed = false; }
      { id = "e18_33"; from = "n18"; to = "n33"; directed = false; }
      # Node 19
      { id = "e19_33"; from = "n19"; to = "n33"; directed = false; }
      # Nodes 20, 22
      { id = "e20_32"; from = "n20"; to = "n32"; directed = false; }
      { id = "e20_33"; from = "n20"; to = "n33"; directed = false; }
      { id = "e22_32"; from = "n22"; to = "n32"; directed = false; }
      { id = "e22_33"; from = "n22"; to = "n33"; directed = false; }
      # Node 23
      { id = "e23_25"; from = "n23"; to = "n25"; directed = false; }
      { id = "e23_27"; from = "n23"; to = "n27"; directed = false; }
      { id = "e23_29"; from = "n23"; to = "n29"; directed = false; }
      { id = "e23_32"; from = "n23"; to = "n32"; directed = false; }
      { id = "e23_33"; from = "n23"; to = "n33"; directed = false; }
      # Nodes 24-25
      { id = "e24_25"; from = "n24"; to = "n25"; directed = false; }
      { id = "e24_27"; from = "n24"; to = "n27"; directed = false; }
      { id = "e24_31"; from = "n24"; to = "n31"; directed = false; }
      { id = "e25_31"; from = "n25"; to = "n31"; directed = false; }
      # Node 26
      { id = "e26_29"; from = "n26"; to = "n29"; directed = false; }
      { id = "e26_33"; from = "n26"; to = "n33"; directed = false; }
      # Node 27
      { id = "e27_33"; from = "n27"; to = "n33"; directed = false; }
      # Nodes 28-31
      { id = "e28_31"; from = "n28"; to = "n31"; directed = false; }
      { id = "e28_33"; from = "n28"; to = "n33"; directed = false; }
      { id = "e29_32"; from = "n29"; to = "n32"; directed = false; }
      { id = "e29_33"; from = "n29"; to = "n33"; directed = false; }
      { id = "e30_32"; from = "n30"; to = "n32"; directed = false; }
      { id = "e30_33"; from = "n30"; to = "n33"; directed = false; }
      { id = "e31_32"; from = "n31"; to = "n32"; directed = false; }
      { id = "e31_33"; from = "n31"; to = "n33"; directed = false; }
      # Node 32-33
      { id = "e32_33"; from = "n32"; to = "n33"; directed = false; }
    ];
  };
in
{
  paper = "Zachary 1977, J. Anthropological Research 33(4):452-473";
  members = gcl.nodeCount network;
  interactions = gcl.edgeCount network;

  # The two faction leaders
  mrHi_degree = gcl.degree "n0" network; # 16 — the instructor
  johnA_degree = gcl.degree "n33" network; # 17 — the president

  # Node 2 is the key bridge — high betweenness centrality
  # Connected to both factions despite being labeled "Hi"
  node2_neighbors = gcl.neighbors "n2" network;

  # The misclassified node: node 8 went with Mr. Hi but
  # min-cut predicts Officer faction
  node8_neighbors = gcl.neighbors "n8" network;

  json = gcl.toGraphJSON network;
}
