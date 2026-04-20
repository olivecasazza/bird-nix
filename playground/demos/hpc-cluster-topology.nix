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
  str = builtins.toString;

  # Topology parameters (Frontier-inspired, scaled down)
  p = 4;   # compute nodes per switch
  a = 4;   # switches per group
  numGroups = 4;

  # Helper: node/switch naming
  nodeName = group: sw: port: "n_g${str group}_s${str sw}_p${str port}";
  swName = group: sw: "sw_g${str group}_s${str sw}";

  # ── Step 1: Create all compute nodes ─────────────────────────────
  # Each node has type indicating its group (for community analysis)
  withNodes = builtins.foldl' (acc: group:
    builtins.foldl' (acc2: sw:
      builtins.foldl' (acc3: port:
        g.addNode (nodeName group sw port) "compute_g${str group}" acc3
      ) acc2 (builtins.genList (x: x) p)
    ) acc (builtins.genList (x: x) a)
  ) g.emptyGraph (builtins.genList (x: x) numGroups);

  # ── Step 2: Create all switches ──────────────────────────────────
  withSwitches = builtins.foldl' (acc: group:
    builtins.foldl' (acc2: sw:
      g.addNode (swName group sw) "switch" acc2
    ) acc (builtins.genList (x: x) a)
  ) withNodes (builtins.genList (x: x) numGroups);

  # ── Step 3: Node-to-switch links (Tier 1) ────────────────────────
  withNodeLinks = builtins.foldl' (acc: group:
    builtins.foldl' (acc2: sw:
      builtins.foldl' (acc3: port:
        let
          nid = nodeName group sw port;
          sid = swName group sw;
          eid = "link_${nid}_${sid}";
        in g.addEdge eid nid sid false acc3
      ) acc2 (builtins.genList (x: x) p)
    ) acc (builtins.genList (x: x) a)
  ) withSwitches (builtins.genList (x: x) numGroups);

  # ── Step 4: Intra-group links (full mesh within each group) ──────
  # Every switch in a group connects to every other switch in the same group
  withIntraLinks = builtins.foldl' (acc: group:
    builtins.foldl' (acc2: sw1:
      builtins.foldl' (acc3: sw2:
        if sw1 < sw2 then
          let
            eid = "intra_g${str group}_s${str sw1}_s${str sw2}";
            s1 = swName group sw1;
            s2 = swName group sw2;
          in g.addEdge eid s1 s2 false acc3
        else
          acc3
      ) acc2 (builtins.genList (x: x) a)
    ) acc (builtins.genList (x: x) a)
  ) withNodeLinks (builtins.genList (x: x) numGroups);

  # ── Step 5: Inter-group (global) links ───────────────────────────
  # Each group connects to every other group. In a real dragonfly,
  # global links are distributed across switches. We assign one global
  # link per (group_i, group_j) pair, cycling through switch indices.
  dragonfly = builtins.foldl' (acc: g1:
    builtins.foldl' (acc2: g2:
      if g1 < g2 then
        let
          # Distribute global links across switches (round-robin)
          sw_idx = builtins.length (builtins.filter (x: x < g2)
                     (builtins.genList (x: x) numGroups));
          s1 = swName g1 (g.nodeCount g.emptyGraph + g1 + g2 - g1 - g2 + (g2 - 1));
          s2 = swName g2 (g1);
          # Simpler: just use g1 and g2 as switch indices within their groups
          src = swName g1 g2;
          dst = swName g2 g1;
          eid = "global_g${str g1}_g${str g2}";
        in g.addEdge eid src dst false acc2
      else
        acc2
    ) acc (builtins.genList (x: x) numGroups)
  ) withIntraLinks (builtins.genList (x: x) numGroups);

  # ── Infrastructure: scheduler + storage ──────────────────────────
  # These connect to switch 0 of group 0 (head node convention)
  cluster =
    g.addNode "scheduler" "slurm_ctld"
    (g.addNode "lustre_mds" "storage"
    (g.addEdge "sched_link" "scheduler" "sw_g0_s0" false
    (g.addEdge "storage_link" "lustre_mds" "sw_g0_s0" false
    dragonfly)));
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
  node_switch_links = p * a * numGroups;                   # 64
  intra_group_links = numGroups * (a * (a - 1) / 2);      # 24
  inter_group_links = numGroups * (numGroups - 1) / 2;     # 6

  # Switch connectivity analysis
  # Each switch connects to: p nodes + (a-1) intra-group + global links
  sw_g0_s0_degree = g.degree "sw_g0_s0" cluster;
  sw_g0_s0_neighbors = g.neighbors "sw_g0_s0" cluster;

  # A compute node connects only to its ToR switch
  n_g0_s0_p0_degree = g.degree "n_g0_s0_p0" cluster;

  json = g.toGraphJSON cluster;
}
