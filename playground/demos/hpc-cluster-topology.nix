# Dragonfly network topology — modeled after ORNL Frontier
# Source: Kim, J. et al. (2008) "Technology-Driven, Highly-Scalable
# Dragonfly Topology." ISCA '08, pp. 77-88.
# Also: Frontier uses HPE Slingshot with dragonfly topology.
#
# A dragonfly network has three levels:
#   1. Compute nodes connect to leaf (ToR) switches within a group
#   2. Switches within a group are fully connected (intra-group links)
#   3. Groups connect via global links (inter-group, one per switch pair)
#
# Parameters (scaled model of Frontier's topology):
#   p = 4 compute nodes per switch
#   a = 4 switches per group (fully connected within group)
#   g = 4 groups (each switch has 1 global link to each other group)
#   Total: 4 groups * 4 switches * 4 nodes = 64 compute nodes
#
# This gives a 2-level fat-tree within groups and a fully-connected
# graph between groups — the hallmark of dragonfly's O(log N) diameter.
let
  g = import ./graph.nix {};

  # Topology parameters (Frontier-inspired, scaled down)
  p = 4;   # compute nodes per switch
  a = 4;   # switches per group
  numGroups = 4;

  # Naming
  str = n: if n == 0 then "0" else if n == 1 then "1" else if n == 2 then "2" else if n == 3 then "3" else if n == 4 then "4" else if n == 5 then "5" else if n == 6 then "6" else if n == 7 then "7" else if n == 8 then "8" else "9";
  nodeName = group: sw: port: "n_g" + str group + "_s" + str sw + "_p" + str port;
  swName = group: sw: "sw_g" + str group + "_s" + str sw;

  # ── Node generators (let-recursive builders) ─────────────────────
  # Compute nodes: one per (group, switch, port)
  computeRow = grp: sw: port:
    if port >= p then []
    else [ { id = nodeName grp sw port; type = "compute_g" + str grp; } ]
      ++ computeRow grp sw (port + 1);
  computeSwitch = grp: sw:
    if sw >= a then []
    else computeRow grp sw 0 ++ computeSwitch grp (sw + 1);
  computeGroup = grp:
    if grp >= numGroups then []
    else computeSwitch grp 0 ++ computeGroup (grp + 1);
  computeNodes = computeGroup 0;

  # Switches: one per (group, switch)
  switchRow = grp: sw:
    if sw >= a then []
    else [ { id = swName grp sw; type = "switch"; } ]
      ++ switchRow grp (sw + 1);
  switchGroups = grp:
    if grp >= numGroups then []
    else switchRow grp 0 ++ switchGroups (grp + 1);
  switchNodes = switchGroups 0;

  # ── Edge generators ──────────────────────────────────────────────
  # Tier 1: compute node -> its ToR switch
  linkRow = grp: sw: port:
    if port >= p then []
    else
      let
        nid = nodeName grp sw port;
        sid = swName grp sw;
      in
        [ { from = nid; to = sid; id = "link_" + nid + "_" + sid; directed = false; } ]
        ++ linkRow grp sw (port + 1);
  linkSwitch = grp: sw:
    if sw >= a then []
    else linkRow grp sw 0 ++ linkSwitch grp (sw + 1);
  linkGroups = grp:
    if grp >= numGroups then []
    else linkSwitch grp 0 ++ linkGroups (grp + 1);
  nodeLinks = linkGroups 0;

  # Tier 2: full mesh among switches in each group (sw1 < sw2)
  intraPair = grp: sw1: sw2:
    if sw2 >= a then []
    else
      (if sw1 < sw2
         then [ { from = swName grp sw1; to = swName grp sw2; id = "intra_g" + str grp + "_s" + str sw1 + "_s" + str sw2; directed = false; } ]
         else [])
      ++ intraPair grp sw1 (sw2 + 1);
  intraSwitch = grp: sw1:
    if sw1 >= a then []
    else intraPair grp sw1 0 ++ intraSwitch grp (sw1 + 1);
  intraGroup = grp:
    if grp >= numGroups then []
    else intraSwitch grp 0 ++ intraGroup (grp + 1);
  intraLinks = intraGroup 0;

  # Tier 3: one global link per (g1, g2) group pair, g1 < g2
  globalPair = g1: g2:
    if g2 >= numGroups then []
    else
      (if g1 < g2
         then [ { from = swName g1 g2; to = swName g2 g1; id = "global_g" + str g1 + "_g" + str g2; directed = false; } ]
         else [])
      ++ globalPair g1 (g2 + 1);
  globalGroup = g1:
    if g1 >= numGroups then []
    else globalPair g1 0 ++ globalGroup (g1 + 1);
  globalLinks = globalGroup 0;

  # ── Infrastructure: scheduler + storage ──────────────────────────
  # Connect to switch 0 of group 0 (head-node convention)
  infraNodes = [
    { id = "scheduler"; type = "slurm_ctld"; }
    { id = "lustre_mds"; type = "storage"; }
  ];
  infraLinks = [
    { from = "scheduler"; to = "sw_g0_s0"; id = "sched_link"; directed = false; }
    { from = "lustre_mds"; to = "sw_g0_s0"; id = "storage_link"; directed = false; }
  ];

  cluster = g.fromSpec {
    nodes = computeNodes ++ switchNodes ++ infraNodes;
    edges = nodeLinks ++ intraLinks ++ globalLinks ++ infraLinks;
  };
in {
  topology = "Dragonfly (Kim 2008, ISCA)";
  reference = "ORNL Frontier, HPE Slingshot interconnect";

  # Topology parameters
  nodes_per_switch = p;
  switches_per_group = a;
  groups = numGroups;
  total_compute = p * a * numGroups;

  total_nodes = g.nodeCount cluster;
  total_links = g.edgeCount cluster;

  # Expected link counts:
  # Node-switch: 64, Intra-group: 4*C(4,2)=24, Inter-group: C(4,2)=6
  # Infrastructure: 2. Total = 96
  node_switch_links = p * a * numGroups;                    # 64
  intra_group_links = numGroups * (a * (a - 1) / 2);       # 24
  inter_group_links = numGroups * (numGroups - 1) / 2;     # 6

  # Switch connectivity analysis
  # Each switch connects to: p nodes + (a-1) intra-group + global links
  sw_g0_s0_degree = g.degree "sw_g0_s0" cluster;
  sw_g0_s0_neighbors = g.neighbors "sw_g0_s0" cluster;

  # A compute node connects only to its ToR switch
  n_g0_s0_p0_degree = g.degree "n_g0_s0_p0" cluster;

  json = g.toGraphJSON cluster;
}
