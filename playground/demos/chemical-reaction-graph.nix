# KEGG map00010 — Glycolysis (all 10 steps, glucose to pyruvate)
# Source: Kanehisa & Goto (2000) Nucleic Acids Res. 28:27-30
# Pathway: https://www.kegg.jp/pathway/map00010
#
# Bipartite reaction graph in Petri net style: metabolite nodes and
# enzyme/reaction nodes connected by directed edges (substrates flow
# into reactions, products flow out). Each enzyme is annotated with its
# EC number. Cofactors (ATP, ADP, NAD+, NADH, Pi, H2O) are explicit
# nodes — they participate as substrates and products.
#
# Net equation: Glucose + 2 NAD+ + 2 ADP + 2 Pi
#            -> 2 Pyruvate + 2 NADH + 2 ATP + 2 H2O
#
# Three regulatory control points: hexokinase (step 1),
# phosphofructokinase-1 (step 3), pyruvate kinase (step 10).
let
  g = import ./graph.nix {};

  # ── Metabolite species (KEGG compound IDs) ───────────────────────
  metabolites =
    g.addNode "Glc" "metabolite"          # C00267 alpha-D-Glucose
    (g.addNode "G6P" "metabolite"          # C00668 Glucose-6-phosphate
    (g.addNode "F6P" "metabolite"          # C00085 Fructose-6-phosphate
    (g.addNode "F16BP" "metabolite"        # C00354 Fructose-1,6-bisphosphate
    (g.addNode "DHAP" "metabolite"         # C00111 Dihydroxyacetone phosphate
    (g.addNode "GAP" "metabolite"          # C00118 Glyceraldehyde-3-phosphate
    (g.addNode "BPG13" "metabolite"        # C00236 1,3-Bisphosphoglycerate
    (g.addNode "PG3" "metabolite"          # C00197 3-Phosphoglycerate
    (g.addNode "PG2" "metabolite"          # C00631 2-Phosphoglycerate
    (g.addNode "PEP" "metabolite"          # C00074 Phosphoenolpyruvate
    (g.addNode "Pyr" "metabolite"          # C00022 Pyruvate
    g.emptyGraph))))))))))
  ;

  # ── Cofactors ────────────────────────────────────────────────────
  withCofactors =
    g.addNode "ATP" "cofactor"
    (g.addNode "ADP" "cofactor"
    (g.addNode "NAD" "cofactor"            # NAD+
    (g.addNode "NADH" "cofactor"
    (g.addNode "Pi" "cofactor"             # inorganic phosphate
    (g.addNode "H2O" "cofactor"
    metabolites)))))
  ;

  # ── Enzyme/reaction nodes (EC numbers from KEGG) ─────────────────
  withEnzymes =
    g.addNode "HK" "enzyme"               # EC 2.7.1.1 — Hexokinase
    (g.addNode "GPI" "enzyme"              # EC 5.3.1.9 — Phosphoglucose isomerase
    (g.addNode "PFK1" "enzyme"             # EC 2.7.1.11 — Phosphofructokinase-1
    (g.addNode "ALDO" "enzyme"             # EC 4.1.2.13 — Aldolase
    (g.addNode "TPI" "enzyme"              # EC 5.3.1.1 — Triosephosphate isomerase
    (g.addNode "GAPDH" "enzyme"            # EC 1.2.1.12 — GA3P dehydrogenase
    (g.addNode "PGK" "enzyme"              # EC 2.7.2.3 — Phosphoglycerate kinase
    (g.addNode "PGM" "enzyme"              # EC 5.4.2.11 — Phosphoglycerate mutase
    (g.addNode "ENO" "enzyme"              # EC 4.2.1.11 — Enolase
    (g.addNode "PK" "enzyme"               # EC 2.7.1.40 — Pyruvate kinase
    withCofactors)))))))))
  ;

  # ── Bipartite edges: substrates -> enzyme -> products ────────────
  # Step 1: Glucose + ATP --(HK)--> G6P + ADP [irreversible, regulatory]
  pathway =
    g.addEdge "s1_Glc" "Glc" "HK" true
    (g.addEdge "s1_ATP" "ATP" "HK" true
    (g.addEdge "s1_G6P" "HK" "G6P" true
    (g.addEdge "s1_ADP" "HK" "ADP" true

    # Step 2: G6P --(GPI)--> F6P [reversible]
    (g.addEdge "s2_G6P" "G6P" "GPI" true
    (g.addEdge "s2_F6P" "GPI" "F6P" true

    # Step 3: F6P + ATP --(PFK1)--> F16BP + ADP [irreversible, committed/rate-limiting]
    (g.addEdge "s3_F6P" "F6P" "PFK1" true
    (g.addEdge "s3_ATP" "ATP" "PFK1" true
    (g.addEdge "s3_F16BP" "PFK1" "F16BP" true
    (g.addEdge "s3_ADP" "PFK1" "ADP" true

    # Step 4: F16BP --(ALDO)--> GAP + DHAP [reversible]
    (g.addEdge "s4_F16BP" "F16BP" "ALDO" true
    (g.addEdge "s4_GAP" "ALDO" "GAP" true
    (g.addEdge "s4_DHAP" "ALDO" "DHAP" true

    # Step 5: DHAP --(TPI)--> GAP [reversible]
    (g.addEdge "s5_DHAP" "DHAP" "TPI" true
    (g.addEdge "s5_GAP" "TPI" "GAP" true

    # Step 6: GAP + NAD+ + Pi --(GAPDH)--> BPG13 + NADH [reversible]
    (g.addEdge "s6_GAP" "GAP" "GAPDH" true
    (g.addEdge "s6_NAD" "NAD" "GAPDH" true
    (g.addEdge "s6_Pi" "Pi" "GAPDH" true
    (g.addEdge "s6_BPG13" "GAPDH" "BPG13" true
    (g.addEdge "s6_NADH" "GAPDH" "NADH" true

    # Step 7: BPG13 + ADP --(PGK)--> PG3 + ATP [reversible, substrate-level phosphorylation]
    (g.addEdge "s7_BPG13" "BPG13" "PGK" true
    (g.addEdge "s7_ADP" "ADP" "PGK" true
    (g.addEdge "s7_PG3" "PGK" "PG3" true
    (g.addEdge "s7_ATP" "PGK" "ATP" true

    # Step 8: PG3 --(PGM)--> PG2 [reversible]
    (g.addEdge "s8_PG3" "PG3" "PGM" true
    (g.addEdge "s8_PG2" "PGM" "PG2" true

    # Step 9: PG2 --(ENO)--> PEP + H2O [reversible]
    (g.addEdge "s9_PG2" "PG2" "ENO" true
    (g.addEdge "s9_PEP" "ENO" "PEP" true
    (g.addEdge "s9_H2O" "ENO" "H2O" true

    # Step 10: PEP + ADP --(PK)--> Pyr + ATP [irreversible, regulatory]
    (g.addEdge "s10_PEP" "PEP" "PK" true
    (g.addEdge "s10_ADP" "ADP" "PK" true
    (g.addEdge "s10_Pyr" "PK" "Pyr" true
    (g.addEdge "s10_ATP" "PK" "ATP" true

    withEnzymes))))))))))))))))))))))))))))))))
  ;
in {
  source = "KEGG map00010 (Glycolysis / Gluconeogenesis)";
  net_equation = "Glucose + 2NAD+ + 2ADP + 2Pi -> 2Pyruvate + 2NADH + 2ATP + 2H2O";

  total_species = g.nodeCount pathway;
  total_reactions = g.edgeCount pathway;

  # Enzyme list with EC numbers
  enzymes = builtins.filter (n:
    (g.getNode n pathway).type == "enzyme"
  ) (g.getNodeIds pathway);

  metabolite_nodes = builtins.filter (n:
    (g.getNode n pathway).type == "metabolite"
  ) (g.getNodeIds pathway);

  # PFK1 is the committed/rate-limiting step (most regulated enzyme)
  pfk1_substrates = g.inNeighbors "PFK1" pathway;
  pfk1_products = g.neighbors "PFK1" pathway;

  # ATP is a hub — consumed by HK + PFK1, produced by PGK + PK
  atp_consumers = g.neighbors "ATP" pathway;
  atp_producers = g.inNeighbors "ATP" pathway;

  # Step 4 (aldolase) is the only step that splits one substrate into two
  aldo_products = g.neighbors "ALDO" pathway;

  json = g.toGraphJSON pathway;
}
