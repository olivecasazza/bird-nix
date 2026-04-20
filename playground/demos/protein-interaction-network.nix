# KEGG hsa04115 — p53 signaling pathway (curated subset)
# Source: Kanehisa, M. & Goto, S. (2000) "KEGG: Kyoto Encyclopedia of
# Genes and Genomes." Nucleic Acids Res. 28:27-30.
# Pathway: https://www.kegg.jp/pathway/hsa04115
#
# The p53 pathway is the most studied tumor suppressor network. DNA
# damage activates sensor kinases (ATM/ATR), which phosphorylate p53.
# Stabilized p53 transcribes effectors for cell cycle arrest (CDKN1A),
# apoptosis (BAX, PUMA, FAS), DNA repair (GADD45), and its own negative
# regulator MDM2. This creates the canonical negative feedback loop.
#
# Node types from KEGG: kinase, transcription_factor, e3_ligase,
# cdk_inhibitor, pro_apoptotic, death_receptor, repair, cell_cycle.
# Edge types from KEGG KGML: PPrel (phosphorylation, inhibition),
# GErel (expression/transcriptional activation).
let
  g = import ./graph.nix {};

  # ── Sensor kinases (DNA damage response) ─────────────────────────
  # ATM (hsa:472) — activated by double-strand breaks
  # ATR (hsa:545) — activated by single-strand breaks / replication stress
  # CHEK1 (hsa:1111) — checkpoint kinase 1, downstream of ATR
  # CHEK2 (hsa:11200) — checkpoint kinase 2, downstream of ATM
  sensors =
    g.addNode "ATM" "kinase"
    (g.addNode "ATR" "kinase"
    (g.addNode "CHEK1" "kinase"
    (g.addNode "CHEK2" "kinase"

  # ── Central hub ──────────────────────────────────────────────────
  # TP53 (hsa:7157) — the tumor suppressor, 26 transcriptional targets in KEGG
    (g.addNode "TP53" "transcription_factor"

  # ── Negative regulators ──────────────────────────────────────────
  # MDM2 (hsa:4193) — E3 ubiquitin ligase, targets p53 for degradation
  # MDM4 (hsa:4194) — MDM2 cofactor, inhibits p53 transactivation
  # PPM1D (hsa:8493) — Wip1 phosphatase, dephosphorylates p53/ATM/CHEK2
  # CDKN2A/p14ARF (hsa:1029) — inhibits MDM2
    (g.addNode "MDM2" "e3_ligase"
    (g.addNode "MDM4" "regulator"
    (g.addNode "PPM1D" "phosphatase"
    (g.addNode "CDKN2A" "tumor_suppressor"

  # ── Cell cycle arrest effectors ──────────────────────────────────
  # CDKN1A/p21 (hsa:1026) — CDK inhibitor, halts G1/S transition
  # SFN/14-3-3sigma (hsa:2810) — sequesters CDK1, G2/M arrest
  # RPRM/Reprimo (hsa:56475) — G2 arrest
  # CCNG1 (hsa:900) — cyclin G1, activates PP2A to dephosphorylate MDM2
    (g.addNode "CDKN1A" "cdk_inhibitor"
    (g.addNode "SFN" "cell_cycle"
    (g.addNode "RPRM" "cell_cycle"
    (g.addNode "CCNG1" "cell_cycle"

  # ── Apoptosis effectors ──────────────────────────────────────────
  # BAX (hsa:581) — pro-apoptotic BCL-2 family, mitochondrial pore
  # BBC3/PUMA (hsa:27113) — BH3-only, neutralizes BCL-2
  # PMAIP1/NOXA (hsa:5366) — BH3-only, selective for MCL-1
  # FAS (hsa:355) — death receptor, extrinsic apoptosis
  # PIDD1 (hsa:55367) — p53-induced death domain protein
  # CASP9 (hsa:842) — initiator caspase, apoptosome
  # CASP3 (hsa:836) — executioner caspase
  # CYCS (hsa:54205) — cytochrome c, released from mitochondria
    (g.addNode "BAX" "pro_apoptotic"
    (g.addNode "BBC3" "pro_apoptotic"
    (g.addNode "PMAIP1" "pro_apoptotic"
    (g.addNode "FAS" "death_receptor"
    (g.addNode "PIDD1" "pro_apoptotic"
    (g.addNode "CASP9" "caspase"
    (g.addNode "CASP3" "caspase"
    (g.addNode "CYCS" "effector"

  # ── DNA repair & other effectors ─────────────────────────────────
  # GADD45 (hsa:4616) — growth arrest and DNA damage
  # DDB2 (hsa:1643) — DNA damage binding, nucleotide excision repair
  # RRM2B (hsa:50484) — ribonucleotide reductase, dNTP supply for repair
  # SESN (hsa:83667) — sestrin, activates AMPK/mTOR
  # PTEN (hsa:5728) — phosphatase, inhibits PI3K/AKT survival signaling
  # TSC2 (hsa:7249) — tuberin, inhibits mTOR
    (g.addNode "GADD45" "repair"
    (g.addNode "DDB2" "repair"
    (g.addNode "RRM2B" "repair"
    (g.addNode "SESN" "metabolism"
    (g.addNode "PTEN" "phosphatase"
    (g.addNode "TSC2" "metabolism"
    g.emptyGraph))))))))))))))))))))))))))
  ;

  # ── Signaling edges from KEGG KGML relation data ────────────────
  # PPrel = protein-protein relation; GErel = gene expression relation
  # Subtypes: activation(-->), inhibition(--|), expression(-->),
  #           phosphorylation(+p), ubiquitination(+u)

  network =
    # DNA damage sensing: kinase cascade (PPrel, phosphorylation)
    g.addEdge "ATM_CHEK2" "ATM" "CHEK2" true         # PPrel activation +p
    (g.addEdge "ATR_CHEK1" "ATR" "CHEK1" true         # PPrel activation +p
    (g.addEdge "ATR_TP53" "ATR" "TP53" true            # PPrel activation +p
    (g.addEdge "CHEK1_TP53" "CHEK1" "TP53" true        # PPrel activation +p
    (g.addEdge "CHEK2_TP53" "CHEK2" "TP53" true        # PPrel activation +p
    (g.addEdge "ATM_TP53" "ATM" "TP53" true            # PPrel activation +p

    # Negative feedback loops (PPrel)
    (g.addEdge "MDM4_MDM2" "MDM4" "MDM2" true          # PPrel activation
    (g.addEdge "MDM4_TP53" "MDM4" "TP53" true           # PPrel inhibition
    (g.addEdge "CDKN2A_MDM2" "CDKN2A" "MDM2" true      # PPrel inhibition
    (g.addEdge "TP53_MDM2_ppr" "TP53" "MDM2" true       # PPrel activation

    # p53 transcriptional targets (GErel, expression)
    # Cell cycle arrest
    (g.addEdge "TP53_CDKN1A" "TP53" "CDKN1A" true      # GErel expression
    (g.addEdge "TP53_SFN" "TP53" "SFN" true             # GErel expression
    (g.addEdge "TP53_RPRM" "TP53" "RPRM" true           # GErel expression
    (g.addEdge "TP53_CCNG1" "TP53" "CCNG1" true         # GErel expression

    # Apoptosis
    (g.addEdge "TP53_BAX" "TP53" "BAX" true             # GErel expression
    (g.addEdge "TP53_BBC3" "TP53" "BBC3" true            # GErel expression
    (g.addEdge "TP53_PMAIP1" "TP53" "PMAIP1" true       # GErel expression
    (g.addEdge "TP53_FAS" "TP53" "FAS" true              # GErel expression
    (g.addEdge "TP53_PIDD1" "TP53" "PIDD1" true          # GErel expression

    # DNA repair & metabolism
    (g.addEdge "TP53_GADD45" "TP53" "GADD45" true       # GErel expression
    (g.addEdge "TP53_DDB2" "TP53" "DDB2" true           # GErel expression
    (g.addEdge "TP53_RRM2B" "TP53" "RRM2B" true         # GErel expression
    (g.addEdge "TP53_SESN" "TP53" "SESN" true            # GErel expression
    (g.addEdge "TP53_PTEN" "TP53" "PTEN" true            # GErel expression
    (g.addEdge "TP53_TSC2" "TP53" "TSC2" true            # GErel expression

    # Autoregulation: p53 transcribes its own regulators
    (g.addEdge "TP53_MDM2" "TP53" "MDM2" true            # GErel expression (feedback)
    (g.addEdge "TP53_PPM1D" "TP53" "PPM1D" true          # GErel expression (feedback)

    # Apoptosis cascade (PPrel)
    (g.addEdge "BAX_CYCS" "BAX" "CYCS" true              # PPrel indirect
    (g.addEdge "CYCS_CASP9" "CYCS" "CASP9" true          # PPrel activation
    (g.addEdge "CASP9_CASP3" "CASP9" "CASP3" true        # PPrel activation

    sensors)))))))))))))))))))))))))))))
  ;
in {
  source = "KEGG hsa04115 (p53 signaling pathway)";
  proteins = g.nodeCount network;
  interactions = g.edgeCount network;

  # TP53 is the master hub — 17 transcriptional targets + 2 autoregulatory
  tp53_targets = g.neighbors "TP53" network;
  tp53_target_count = g.degree "TP53" network;

  # Sensor kinases converge on TP53 (4 inputs)
  tp53_activators = g.inNeighbors "TP53" network;

  # MDM2 negative feedback: TP53 transcribes MDM2, MDM2 degrades TP53
  mdm2_regulators = g.inNeighbors "MDM2" network;

  # Apoptosis cascade: BAX -> CYCS -> CASP9 -> CASP3
  casp3_activators = g.inNeighbors "CASP3" network;

  json = g.toGraphJSON network;
}
