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

  # ── Wire input/output nodes (Qiskit DAGCircuit convention) ───────
  circuit = gcl.fromSpec {
    nodes = {
      q0_in = "qubit_input"; # qubit 0 starts in |0>
      q1_in = "qubit_input"; # qubit 1 starts in |0>
      c0_in = "cbit_input"; # classical bit 0
      c1_in = "cbit_input"; # classical bit 1
      q0_out = "qubit_output";
      q1_out = "qubit_output";
      c0_out = "cbit_output";
      c1_out = "cbit_output";

      # ── Gate nodes (operations in circuit order) ─────────────────────
      # Step 1: Superposition
      H0_init = "hadamard"; # H on q0 (timestep 0)
      H1_init = "hadamard"; # H on q1 (timestep 0)

      # Step 2: Oracle — CZ marks |11> with phase -1
      CZ_oracle = "cz"; # controlled-Z (timestep 1)

      # Step 3: Diffusion operator (Grover diffusion = 2|s><s| - I)
      # Implemented as: H -> X -> CZ -> X -> H
      H0_diff1 = "hadamard"; # H on q0 (timestep 2)
      H1_diff1 = "hadamard"; # H on q1 (timestep 2)
      X0_diff = "pauli_x"; # X on q0 (timestep 3)
      X1_diff = "pauli_x"; # X on q1 (timestep 3)
      CZ_diff = "cz"; # controlled-Z (timestep 4)
      X0_diff2 = "pauli_x"; # X on q0 (timestep 5)
      X1_diff2 = "pauli_x"; # X on q1 (timestep 5)
      H0_diff2 = "hadamard"; # H on q0 (timestep 6)
      H1_diff2 = "hadamard"; # H on q1 (timestep 6)

      # Step 4: Measurement
      M0 = "measure"; # measure q0 -> c0
      M1 = "measure"; # measure q1 -> c1
    };

    # ── Qubit wire edges (data flow through circuit) ─────────────────
    # Each edge represents a qubit wire between consecutive gate operations.
    # Two-qubit gates (CZ) have edges from both control and target qubits.

    edges = [
      # Qubit 0 wire: q0_in -> H0_init -> CZ_oracle -> H0_diff1 -> X0_diff
      #            -> CZ_diff -> X0_diff2 -> H0_diff2 -> M0 -> q0_out
      { id = "q0_w0"; from = "q0_in"; to = "H0_init"; }
      { id = "q0_w1"; from = "H0_init"; to = "CZ_oracle"; }
      { id = "q0_w2"; from = "CZ_oracle"; to = "H0_diff1"; }
      { id = "q0_w3"; from = "H0_diff1"; to = "X0_diff"; }
      { id = "q0_w4"; from = "X0_diff"; to = "CZ_diff"; }
      { id = "q0_w5"; from = "CZ_diff"; to = "X0_diff2"; }
      { id = "q0_w6"; from = "X0_diff2"; to = "H0_diff2"; }
      { id = "q0_w7"; from = "H0_diff2"; to = "M0"; }
      { id = "q0_w8"; from = "M0"; to = "q0_out"; }

      # Qubit 1 wire: q1_in -> H1_init -> CZ_oracle -> H1_diff1 -> X1_diff
      #            -> CZ_diff -> X1_diff2 -> H1_diff2 -> M1 -> q1_out
      { id = "q1_w0"; from = "q1_in"; to = "H1_init"; }
      { id = "q1_w1"; from = "H1_init"; to = "CZ_oracle"; }
      { id = "q1_w2"; from = "CZ_oracle"; to = "H1_diff1"; }
      { id = "q1_w3"; from = "H1_diff1"; to = "X1_diff"; }
      { id = "q1_w4"; from = "X1_diff"; to = "CZ_diff"; }
      { id = "q1_w5"; from = "CZ_diff"; to = "X1_diff2"; }
      { id = "q1_w6"; from = "X1_diff2"; to = "H1_diff2"; }
      { id = "q1_w7"; from = "H1_diff2"; to = "M1"; }
      { id = "q1_w8"; from = "M1"; to = "q1_out"; }

      # Classical bit wires: measurement results
      { id = "c0_w0"; from = "c0_in"; to = "M0"; }
      { id = "c0_w1"; from = "M0"; to = "c0_out"; }
      { id = "c1_w0"; from = "c1_in"; to = "M1"; }
      { id = "c1_w1"; from = "M1"; to = "c1_out"; }
    ];
  };
in
{
  algorithm = "Grover's search (2-qubit, oracle for |11>)";
  paper = "Grover 1996, STOC, arXiv:quant-ph/9605043";
  dag_model = "Qiskit DAGCircuit (arXiv:2101.02109)";

  qubits = 2;
  classical_bits = 2;
  total_nodes = gcl.nodeCount circuit;
  total_wire_edges = gcl.edgeCount circuit;

  # Gate count by type
  gate_nodes = gcl.filterNodes
    (n:
      let t = (gcl.getNode n circuit).type;
      in t != "qubit_input" && t != "qubit_output"
        && t != "cbit_input" && t != "cbit_output"
    )
    circuit;

  # Circuit depth: longest path through DAG = 9 gates per qubit wire
  # (H, CZ, H, X, CZ, X, H, M + wire I/O)
  q0_path = gcl.neighbors "q0_in" circuit;

  # CZ gates have in-degree 2 (both qubits feed in)
  cz_oracle_inputs = gcl.inNeighbors "CZ_oracle" circuit;
  cz_diff_inputs = gcl.inNeighbors "CZ_diff" circuit;

  # Measurements connect quantum and classical domains
  m0_inputs = gcl.inNeighbors "M0" circuit;
  m0_outputs = gcl.neighbors "M0" circuit;

  json = gcl.toGraphJSON circuit;
}
