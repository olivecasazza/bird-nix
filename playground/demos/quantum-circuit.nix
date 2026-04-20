# Grover's search algorithm — 2-qubit oracle for |11>
# Source: Grover, L.K. (1996) "A fast quantum mechanical algorithm for
# database search." STOC '96, pp. 212-219. arXiv:quant-ph/9605043
#
# DAG representation following Qiskit's DAGCircuit model (arXiv:2101.02109):
# - Wire nodes: qubit/classical bit inputs and outputs
# - Gate nodes: quantum operations at specific timesteps
# - Directed edges: qubit wire propagation (data flow left-to-right)
#
# The circuit finds |11> in a 2-qubit space with O(1) oracle query:
#   1. Hadamard on both qubits (superposition)
#   2. Oracle: CZ gate marks |11> with phase flip
#   3. Diffusion operator: H -> X -> CZ -> X -> H (amplitude amplification)
#   4. Measurement
#
# This is the simplest non-trivial Grover circuit — one iteration suffices
# for N=4 search space (2 qubits). Probability of measuring |11> = 1.
let
  g = import ./graph.nix {};

  # ── Wire input/output nodes (Qiskit DAGCircuit convention) ───────
  wires =
    g.addNode "q0_in" "qubit_input"        # qubit 0 starts in |0>
    (g.addNode "q1_in" "qubit_input"        # qubit 1 starts in |0>
    (g.addNode "c0_in" "cbit_input"         # classical bit 0
    (g.addNode "c1_in" "cbit_input"         # classical bit 1
    (g.addNode "q0_out" "qubit_output"
    (g.addNode "q1_out" "qubit_output"
    (g.addNode "c0_out" "cbit_output"
    (g.addNode "c1_out" "cbit_output"
    g.emptyGraph)))))))
  ;

  # ── Gate nodes (operations in circuit order) ─────────────────────
  # Step 1: Superposition
  withGates =
    g.addNode "H0_init" "hadamard"         # H on q0 (timestep 0)
    (g.addNode "H1_init" "hadamard"         # H on q1 (timestep 0)

    # Step 2: Oracle — CZ marks |11> with phase -1
    (g.addNode "CZ_oracle" "cz"             # controlled-Z (timestep 1)

    # Step 3: Diffusion operator (Grover diffusion = 2|s><s| - I)
    # Implemented as: H -> X -> CZ -> X -> H
    (g.addNode "H0_diff1" "hadamard"        # H on q0 (timestep 2)
    (g.addNode "H1_diff1" "hadamard"        # H on q1 (timestep 2)
    (g.addNode "X0_diff" "pauli_x"          # X on q0 (timestep 3)
    (g.addNode "X1_diff" "pauli_x"          # X on q1 (timestep 3)
    (g.addNode "CZ_diff" "cz"              # controlled-Z (timestep 4)
    (g.addNode "X0_diff2" "pauli_x"         # X on q0 (timestep 5)
    (g.addNode "X1_diff2" "pauli_x"         # X on q1 (timestep 5)
    (g.addNode "H0_diff2" "hadamard"        # H on q0 (timestep 6)
    (g.addNode "H1_diff2" "hadamard"        # H on q1 (timestep 6)

    # Step 4: Measurement
    (g.addNode "M0" "measure"               # measure q0 -> c0
    (g.addNode "M1" "measure"               # measure q1 -> c1
    wires)))))))))))))
  ;

  # ── Qubit wire edges (data flow through circuit) ─────────────────
  # Each edge represents a qubit wire between consecutive gate operations.
  # Two-qubit gates (CZ) have edges from both control and target qubits.
  circuit =
    # Qubit 0 wire: q0_in -> H0_init -> CZ_oracle -> H0_diff1 -> X0_diff
    #            -> CZ_diff -> X0_diff2 -> H0_diff2 -> M0 -> q0_out
    g.addEdge "q0_w0" "q0_in" "H0_init" true
    (g.addEdge "q0_w1" "H0_init" "CZ_oracle" true
    (g.addEdge "q0_w2" "CZ_oracle" "H0_diff1" true
    (g.addEdge "q0_w3" "H0_diff1" "X0_diff" true
    (g.addEdge "q0_w4" "X0_diff" "CZ_diff" true
    (g.addEdge "q0_w5" "CZ_diff" "X0_diff2" true
    (g.addEdge "q0_w6" "X0_diff2" "H0_diff2" true
    (g.addEdge "q0_w7" "H0_diff2" "M0" true
    (g.addEdge "q0_w8" "M0" "q0_out" true

    # Qubit 1 wire: q1_in -> H1_init -> CZ_oracle -> H1_diff1 -> X1_diff
    #            -> CZ_diff -> X1_diff2 -> H1_diff2 -> M1 -> q1_out
    (g.addEdge "q1_w0" "q1_in" "H1_init" true
    (g.addEdge "q1_w1" "H1_init" "CZ_oracle" true
    (g.addEdge "q1_w2" "CZ_oracle" "H1_diff1" true
    (g.addEdge "q1_w3" "H1_diff1" "X1_diff" true
    (g.addEdge "q1_w4" "X1_diff" "CZ_diff" true
    (g.addEdge "q1_w5" "CZ_diff" "X1_diff2" true
    (g.addEdge "q1_w6" "X1_diff2" "H1_diff2" true
    (g.addEdge "q1_w7" "H1_diff2" "M1" true
    (g.addEdge "q1_w8" "M1" "q1_out" true

    # Classical bit wires: measurement results
    (g.addEdge "c0_w0" "c0_in" "M0" true
    (g.addEdge "c0_w1" "M0" "c0_out" true
    (g.addEdge "c1_w0" "c1_in" "M1" true
    (g.addEdge "c1_w1" "M1" "c1_out" true

    withGates)))))))))))))))))))))
  ;
in {
  algorithm = "Grover's search (2-qubit, oracle for |11>)";
  paper = "Grover 1996, STOC, arXiv:quant-ph/9605043";
  dag_model = "Qiskit DAGCircuit (arXiv:2101.02109)";

  qubits = 2;
  classical_bits = 2;
  total_nodes = g.nodeCount circuit;
  total_wire_edges = g.edgeCount circuit;

  # Gate count by type
  gate_nodes = builtins.filter (n:
    let t = (g.getNode n circuit).type;
    in t != "qubit_input" && t != "qubit_output"
       && t != "cbit_input" && t != "cbit_output"
  ) (g.getNodeIds circuit);

  # Circuit depth: longest path through DAG = 9 gates per qubit wire
  # (H, CZ, H, X, CZ, X, H, M + wire I/O)
  q0_path = g.neighbors "q0_in" circuit;

  # CZ gates have in-degree 2 (both qubits feed in)
  cz_oracle_inputs = g.inNeighbors "CZ_oracle" circuit;
  cz_diff_inputs = g.inNeighbors "CZ_diff" circuit;

  # Measurements connect quantum and classical domains
  m0_inputs = g.inNeighbors "M0" circuit;
  m0_outputs = g.neighbors "M0" circuit;

  json = g.toGraphJSON circuit;
}
