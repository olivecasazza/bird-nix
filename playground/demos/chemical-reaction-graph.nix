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
  g = import ./graph.nix { };
  gcl = import ./graph-combinators.nix { graph = g; };

  # ── Metabolite species (KEGG compound IDs) ───────────────────────
  pathway = gcl.fromSpec {
    nodes = {
      Glc = "metabolite"; # C00267 alpha-D-Glucose
      G6P = "metabolite"; # C00668 Glucose-6-phosphate
      F6P = "metabolite"; # C00085 Fructose-6-phosphate
      F16BP = "metabolite"; # C00354 Fructose-1,6-bisphosphate
      DHAP = "metabolite"; # C00111 Dihydroxyacetone phosphate
      GAP = "metabolite"; # C00118 Glyceraldehyde-3-phosphate
      BPG13 = "metabolite"; # C00236 1,3-Bisphosphoglycerate
      PG3 = "metabolite"; # C00197 3-Phosphoglycerate
      PG2 = "metabolite"; # C00631 2-Phosphoglycerate
      PEP = "metabolite"; # C00074 Phosphoenolpyruvate
      Pyr = "metabolite"; # C00022 Pyruvate

      # ── Cofactors ────────────────────────────────────────────────────
      ATP = "cofactor";
      ADP = "cofactor";
      NAD = "cofactor"; # NAD+
      NADH = "cofactor";
      Pi = "cofactor"; # inorganic phosphate
      H2O = "cofactor";

      # ── Enzyme/reaction nodes (EC numbers from KEGG) ─────────────────
      HK = "enzyme"; # EC 2.7.1.1 — Hexokinase
      GPI = "enzyme"; # EC 5.3.1.9 — Phosphoglucose isomerase
      PFK1 = "enzyme"; # EC 2.7.1.11 — Phosphofructokinase-1
      ALDO = "enzyme"; # EC 4.1.2.13 — Aldolase
      TPI = "enzyme"; # EC 5.3.1.1 — Triosephosphate isomerase
      GAPDH = "enzyme"; # EC 1.2.1.12 — GA3P dehydrogenase
      PGK = "enzyme"; # EC 2.7.2.3 — Phosphoglycerate kinase
      PGM = "enzyme"; # EC 5.4.2.11 — Phosphoglycerate mutase
      ENO = "enzyme"; # EC 4.2.1.11 — Enolase
      PK = "enzyme"; # EC 2.7.1.40 — Pyruvate kinase
    };

    # ── Bipartite edges: substrates -> enzyme -> products ────────────
    # Step 1: Glucose + ATP --(HK)--> G6P + ADP [irreversible, regulatory]

    edges = [
      { id = "s1_Glc"; from = "Glc"; to = "HK"; }
      { id = "s1_ATP"; from = "ATP"; to = "HK"; }
      { id = "s1_G6P"; from = "HK"; to = "G6P"; }
      { id = "s1_ADP"; from = "HK"; to = "ADP"; }

      # Step 2: G6P --(GPI)--> F6P [reversible]
      { id = "s2_G6P"; from = "G6P"; to = "GPI"; }
      { id = "s2_F6P"; from = "GPI"; to = "F6P"; }

      # Step 3: F6P + ATP --(PFK1)--> F16BP + ADP [irreversible, committed/rate-limiting]
      { id = "s3_F6P"; from = "F6P"; to = "PFK1"; }
      { id = "s3_ATP"; from = "ATP"; to = "PFK1"; }
      { id = "s3_F16BP"; from = "PFK1"; to = "F16BP"; }
      { id = "s3_ADP"; from = "PFK1"; to = "ADP"; }

      # Step 4: F16BP --(ALDO)--> GAP + DHAP [reversible]
      { id = "s4_F16BP"; from = "F16BP"; to = "ALDO"; }
      { id = "s4_GAP"; from = "ALDO"; to = "GAP"; }
      { id = "s4_DHAP"; from = "ALDO"; to = "DHAP"; }

      # Step 5: DHAP --(TPI)--> GAP [reversible]
      { id = "s5_DHAP"; from = "DHAP"; to = "TPI"; }
      { id = "s5_GAP"; from = "TPI"; to = "GAP"; }

      # Step 6: GAP + NAD+ + Pi --(GAPDH)--> BPG13 + NADH [reversible]
      { id = "s6_GAP"; from = "GAP"; to = "GAPDH"; }
      { id = "s6_NAD"; from = "NAD"; to = "GAPDH"; }
      { id = "s6_Pi"; from = "Pi"; to = "GAPDH"; }
      { id = "s6_BPG13"; from = "GAPDH"; to = "BPG13"; }
      { id = "s6_NADH"; from = "GAPDH"; to = "NADH"; }

      # Step 7: BPG13 + ADP --(PGK)--> PG3 + ATP [reversible, substrate-level phosphorylation]
      { id = "s7_BPG13"; from = "BPG13"; to = "PGK"; }
      { id = "s7_ADP"; from = "ADP"; to = "PGK"; }
      { id = "s7_PG3"; from = "PGK"; to = "PG3"; }
      { id = "s7_ATP"; from = "PGK"; to = "ATP"; }

      # Step 8: PG3 --(PGM)--> PG2 [reversible]
      { id = "s8_PG3"; from = "PG3"; to = "PGM"; }
      { id = "s8_PG2"; from = "PGM"; to = "PG2"; }

      # Step 9: PG2 --(ENO)--> PEP + H2O [reversible]
      { id = "s9_PG2"; from = "PG2"; to = "ENO"; }
      { id = "s9_PEP"; from = "ENO"; to = "PEP"; }
      { id = "s9_H2O"; from = "ENO"; to = "H2O"; }

      # Step 10: PEP + ADP --(PK)--> Pyr + ATP [irreversible, regulatory]
      { id = "s10_PEP"; from = "PEP"; to = "PK"; }
      { id = "s10_ADP"; from = "ADP"; to = "PK"; }
      { id = "s10_Pyr"; from = "PK"; to = "Pyr"; }
      { id = "s10_ATP"; from = "PK"; to = "ATP"; }
    ];
  };
in
{
  source = "KEGG map00010 (Glycolysis / Gluconeogenesis)";
  net_equation = "Glucose + 2NAD+ + 2ADP + 2Pi -> 2Pyruvate + 2NADH + 2ATP + 2H2O";

  total_species = gcl.nodeCount pathway;
  total_reactions = gcl.edgeCount pathway;

  # Enzyme list with EC numbers
  enzymes = gcl.filterNodes
    (n:
      (gcl.getNode n pathway).type == "enzyme"
    )
    pathway;

  metabolite_nodes = gcl.filterNodes
    (n:
      (gcl.getNode n pathway).type == "metabolite"
    )
    pathway;

  # PFK1 is the committed/rate-limiting step (most regulated enzyme)
  pfk1_substrates = gcl.inNeighbors "PFK1" pathway;
  pfk1_products = gcl.neighbors "PFK1" pathway;

  # ATP is a hub — consumed by HK + PFK1, produced by PGK + PK
  atp_consumers = gcl.neighbors "ATP" pathway;
  atp_producers = gcl.inNeighbors "ATP" pathway;

  # Step 4 (aldolase) is the only step that splits one substrate into two
  aldo_products = gcl.neighbors "ALDO" pathway;

  json = gcl.toGraphJSON pathway;
}
