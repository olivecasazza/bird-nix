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

  # ── Sensor kinases (DNA damage response) ─────────────────────────
  # ATM (hsa:472) — activated by double-strand breaks
  # ATR (hsa:545) — activated by single-strand breaks / replication stress
  # CHEK1 (hsa:1111) — checkpoint kinase 1, downstream of ATR
  # CHEK2 (hsa:11200) — checkpoint kinase 2, downstream of ATM
  network = g.fromSpec {
    nodes = {
      ATM = "kinase";
      ATR = "kinase";
      CHEK1 = "kinase";
      CHEK2 = "kinase";

      # ── Central hub ──────────────────────────────────────────────────
      # TP53 (hsa:7157) — the tumor suppressor, 26 transcriptional targets in KEGG
      TP53 = "transcription_factor";

      # ── Negative regulators ──────────────────────────────────────────
      # MDM2 (hsa:4193) — E3 ubiquitin ligase, targets p53 for degradation
      # MDM4 (hsa:4194) — MDM2 cofactor, inhibits p53 transactivation
      # PPM1D (hsa:8493) — Wip1 phosphatase, dephosphorylates p53/ATM/CHEK2
      # CDKN2A/p14ARF (hsa:1029) — inhibits MDM2
      MDM2 = "e3_ligase";
      MDM4 = "regulator";
      PPM1D = "phosphatase";
      CDKN2A = "tumor_suppressor";

      # ── Cell cycle arrest effectors ──────────────────────────────────
      # CDKN1A/p21 (hsa:1026) — CDK inhibitor, halts G1/S transition
      # SFN/14-3-3sigma (hsa:2810) — sequesters CDK1, G2/M arrest
      # RPRM/Reprimo (hsa:56475) — G2 arrest
      # CCNG1 (hsa:900) — cyclin G1, activates PP2A to dephosphorylate MDM2
      CDKN1A = "cdk_inhibitor";
      SFN = "cell_cycle";
      RPRM = "cell_cycle";
      CCNG1 = "cell_cycle";

      # ── Apoptosis effectors ──────────────────────────────────────────
      # BAX (hsa:581) — pro-apoptotic BCL-2 family, mitochondrial pore
      # BBC3/PUMA (hsa:27113) — BH3-only, neutralizes BCL-2
      # PMAIP1/NOXA (hsa:5366) — BH3-only, selective for MCL-1
      # FAS (hsa:355) — death receptor, extrinsic apoptosis
      # PIDD1 (hsa:55367) — p53-induced death domain protein
      # CASP9 (hsa:842) — initiator caspase, apoptosome
      # CASP3 (hsa:836) — executioner caspase
      # CYCS (hsa:54205) — cytochrome c, released from mitochondria
      BAX = "pro_apoptotic";
      BBC3 = "pro_apoptotic";
      PMAIP1 = "pro_apoptotic";
      FAS = "death_receptor";
      PIDD1 = "pro_apoptotic";
      CASP9 = "caspase";
      CASP3 = "caspase";
      CYCS = "effector";

      # ── DNA repair & other effectors ─────────────────────────────────
      # GADD45 (hsa:4616) — growth arrest and DNA damage
      # DDB2 (hsa:1643) — DNA damage binding, nucleotide excision repair
      # RRM2B (hsa:50484) — ribonucleotide reductase, dNTP supply for repair
      # SESN (hsa:83667) — sestrin, activates AMPK/mTOR
      # PTEN (hsa:5728) — phosphatase, inhibits PI3K/AKT survival signaling
      # TSC2 (hsa:7249) — tuberin, inhibits mTOR
      GADD45 = "repair";
      DDB2 = "repair";
      RRM2B = "repair";
      SESN = "metabolism";
      PTEN = "phosphatase";
      TSC2 = "metabolism";
    };

    # ── Signaling edges from KEGG KGML relation data ────────────────
    # PPrel = protein-protein relation; GErel = gene expression relation
    # Subtypes: activation(-->), inhibition(--|), expression(-->),
    #           phosphorylation(+p), ubiquitination(+u)

    edges = [
      # DNA damage sensing: kinase cascade (PPrel, phosphorylation)
      { id = "ATM_CHEK2"; from = "ATM"; to = "CHEK2"; } # PPrel activation +p
      { id = "ATR_CHEK1"; from = "ATR"; to = "CHEK1"; } # PPrel activation +p
      { id = "ATR_TP53"; from = "ATR"; to = "TP53"; } # PPrel activation +p
      { id = "CHEK1_TP53"; from = "CHEK1"; to = "TP53"; } # PPrel activation +p
      { id = "CHEK2_TP53"; from = "CHEK2"; to = "TP53"; } # PPrel activation +p
      { id = "ATM_TP53"; from = "ATM"; to = "TP53"; } # PPrel activation +p

      # Negative feedback loops (PPrel)
      { id = "MDM4_MDM2"; from = "MDM4"; to = "MDM2"; } # PPrel activation
      { id = "MDM4_TP53"; from = "MDM4"; to = "TP53"; } # PPrel inhibition
      { id = "CDKN2A_MDM2"; from = "CDKN2A"; to = "MDM2"; } # PPrel inhibition
      { id = "TP53_MDM2_ppr"; from = "TP53"; to = "MDM2"; } # PPrel activation

      # p53 transcriptional targets (GErel, expression)
      # Cell cycle arrest
      { id = "TP53_CDKN1A"; from = "TP53"; to = "CDKN1A"; } # GErel expression
      { id = "TP53_SFN"; from = "TP53"; to = "SFN"; } # GErel expression
      { id = "TP53_RPRM"; from = "TP53"; to = "RPRM"; } # GErel expression
      { id = "TP53_CCNG1"; from = "TP53"; to = "CCNG1"; } # GErel expression

      # Apoptosis
      { id = "TP53_BAX"; from = "TP53"; to = "BAX"; } # GErel expression
      { id = "TP53_BBC3"; from = "TP53"; to = "BBC3"; } # GErel expression
      { id = "TP53_PMAIP1"; from = "TP53"; to = "PMAIP1"; } # GErel expression
      { id = "TP53_FAS"; from = "TP53"; to = "FAS"; } # GErel expression
      { id = "TP53_PIDD1"; from = "TP53"; to = "PIDD1"; } # GErel expression

      # DNA repair & metabolism
      { id = "TP53_GADD45"; from = "TP53"; to = "GADD45"; } # GErel expression
      { id = "TP53_DDB2"; from = "TP53"; to = "DDB2"; } # GErel expression
      { id = "TP53_RRM2B"; from = "TP53"; to = "RRM2B"; } # GErel expression
      { id = "TP53_SESN"; from = "TP53"; to = "SESN"; } # GErel expression
      { id = "TP53_PTEN"; from = "TP53"; to = "PTEN"; } # GErel expression
      { id = "TP53_TSC2"; from = "TP53"; to = "TSC2"; } # GErel expression

      # Autoregulation: p53 transcribes its own regulators
      { id = "TP53_MDM2"; from = "TP53"; to = "MDM2"; } # GErel expression (feedback)
      { id = "TP53_PPM1D"; from = "TP53"; to = "PPM1D"; } # GErel expression (feedback)

      # Apoptosis cascade (PPrel)
      { id = "BAX_CYCS"; from = "BAX"; to = "CYCS"; } # PPrel indirect
      { id = "CYCS_CASP9"; from = "CYCS"; to = "CASP9"; } # PPrel activation
      { id = "CASP9_CASP3"; from = "CASP9"; to = "CASP3"; } # PPrel activation
    ];
  };
in
{
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
