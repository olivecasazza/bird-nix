//! bird-nix playground — real Nix evaluation in the browser via tvix-eval.
//!
//! This crate compiles to WASM and runs actual Nix evaluation using tvix-eval.
//! Bird-nix source files are embedded at compile time and served through a
//! virtual filesystem, so `import ./birds.nix {}` works in the browser.

use std::collections::HashMap;
use std::io;
use std::path::{Path, PathBuf};
use std::rc::Rc;

use tvix_eval::{EvalIO, Evaluation, FileType};
use wasm_bindgen::prelude::*;

// ── Virtual Filesystem ─────────────────────────────────────────────────────
//
// Embeds bird-nix source files at compile time. When tvix-eval encounters
// `import ./birds.nix {}`, our VFS serves the file content from memory.

/// All bird-nix source files, embedded at compile time.
/// Paths are relative to the virtual root `/bird-nix/src/`.
macro_rules! embed_nix_files {
    ($($vpath:expr => $rpath:expr),+ $(,)?) => {
        fn build_vfs() -> HashMap<PathBuf, &'static str> {
            let mut m = HashMap::new();
            $(
                m.insert(PathBuf::from($vpath), include_str!($rpath));
            )+
            m
        }
    };
}

embed_nix_files! {
    "/bird-nix/src/ast.nix"              => "../../src/ast.nix",
    "/bird-nix/src/birds.nix"            => "../../src/birds.nix",
    "/bird-nix/src/birds-speech.nix"     => "../../src/birds-speech.nix",
    "/bird-nix/src/bird-compiler.nix"    => "../../src/bird-compiler.nix",
    "/bird-nix/src/bird-dsl.nix"         => "../../src/bird-dsl.nix",
    "/bird-nix/src/bird-format.nix"      => "../../src/bird-format.nix",
    "/bird-nix/src/bird-nix.nix"         => "../../src/bird-nix.nix",
    "/bird-nix/src/bird-toolchain.nix"   => "../../src/bird-toolchain.nix",
    "/bird-nix/src/default.nix"          => "../../src/default.nix",
    "/bird-nix/src/graph.nix"            => "../../src/graph.nix",
    "/bird-nix/src/graph-combinators.nix" => "../../src/graph-combinators.nix",
    "/bird-nix/src/gc-min.nix" => "../../src/gc-min.nix",
    // Tests referenced by src/default.nix
    "/bird-nix/tests/bird-pbt.nix"       => "../../tests/bird-pbt.nix",
    "/bird-nix/tests/test-harness.nix"   => "../../tests/test-harness.nix",
    "/bird-nix/tests/real-world-birds.nix" => "../../tests/real-world-birds.nix",
    // Demo files
    "/bird-nix/demos/i-identity.nix" => "../demos/i-identity.nix",
    "/bird-nix/demos/k-kestrel.nix" => "../demos/k-kestrel.nix",
    "/bird-nix/demos/ki-kite.nix" => "../demos/ki-kite.nix",
    "/bird-nix/demos/m-mockingbird.nix" => "../demos/m-mockingbird.nix",
    "/bird-nix/demos/b-bluebird-compose.nix" => "../demos/b-bluebird-compose.nix",
    "/bird-nix/demos/c-cardinal-flip.nix" => "../demos/c-cardinal-flip.nix",
    "/bird-nix/demos/w-warbler-duplicate.nix" => "../demos/w-warbler-duplicate.nix",
    "/bird-nix/demos/s-starling-fork.nix" => "../demos/s-starling-fork.nix",
    "/bird-nix/demos/v-vireo-pair.nix" => "../demos/v-vireo-pair.nix",
    "/bird-nix/demos/l-lark.nix" => "../demos/l-lark.nix",
    "/bird-nix/demos/y-sage-fixpoint.nix" => "../demos/y-sage-fixpoint.nix",
    "/bird-nix/demos/s-k-k-i.nix" => "../demos/s-k-k-i.nix",
    "/bird-nix/demos/w-k-i.nix" => "../demos/w-k-i.nix",
    "/bird-nix/demos/m-i-i.nix" => "../demos/m-i-i.nix",
    "/bird-nix/demos/b-f-i-f.nix" => "../demos/b-f-i-f.nix",
    "/bird-nix/demos/b-i-f-f.nix" => "../demos/b-i-f-f.nix",
    "/bird-nix/demos/c-k-ki.nix" => "../demos/c-k-ki.nix",
    "/bird-nix/demos/v-pair-selectors.nix" => "../demos/v-pair-selectors.nix",
    "/bird-nix/demos/church-booleans.nix" => "../demos/church-booleans.nix",
    "/bird-nix/demos/church-numerals.nix" => "../demos/church-numerals.nix",
    "/bird-nix/demos/church-pairs-vireo.nix" => "../demos/church-pairs-vireo.nix",
    "/bird-nix/demos/birds-as-data.nix" => "../demos/birds-as-data.nix",
    "/bird-nix/demos/pipeline-with-b.nix" => "../demos/pipeline-with-b.nix",
    "/bird-nix/demos/map-with-combinators.nix" => "../demos/map-with-combinators.nix",
    "/bird-nix/demos/recursive-factorial-y.nix" => "../demos/recursive-factorial-y.nix",
    "/bird-nix/demos/import-birds-nix.nix" => "../demos/import-birds-nix.nix",
    "/bird-nix/demos/bird-speech.nix" => "../demos/bird-speech.nix",
    "/bird-nix/demos/full-library.nix" => "../demos/full-library.nix",
    "/bird-nix/demos/path-graph.nix" => "../demos/path-graph.nix",
    "/bird-nix/demos/star-graph.nix" => "../demos/star-graph.nix",
    "/bird-nix/demos/complete-graph.nix" => "../demos/complete-graph.nix",
    "/bird-nix/demos/cycle-graph.nix" => "../demos/cycle-graph.nix",
    "/bird-nix/demos/grid-graph.nix" => "../demos/grid-graph.nix",
    "/bird-nix/demos/subdivide-edge.nix" => "../demos/subdivide-edge.nix",
    "/bird-nix/demos/hub-rule.nix" => "../demos/hub-rule.nix",
    "/bird-nix/demos/reverse-edges.nix" => "../demos/reverse-edges.nix",
    "/bird-nix/demos/compose-transforms.nix" => "../demos/compose-transforms.nix",
    "/bird-nix/demos/social-network.nix" => "../demos/social-network.nix",
    "/bird-nix/demos/neural-network-layers.nix" => "../demos/neural-network-layers.nix",
    "/bird-nix/demos/hpc-cluster-topology.nix" => "../demos/hpc-cluster-topology.nix",
    "/bird-nix/demos/quantum-circuit.nix" => "../demos/quantum-circuit.nix",
    "/bird-nix/demos/toroidal-mesh.nix" => "../demos/toroidal-mesh.nix",
    "/bird-nix/demos/protein-interaction-network.nix" => "../demos/protein-interaction-network.nix",
    "/bird-nix/demos/chemical-reaction-graph.nix" => "../demos/chemical-reaction-graph.nix",
}

/// In-memory filesystem for tvix-eval. Serves embedded Nix files and the
/// user's code (injected as `/playground/input.nix`).
struct BirdNixIO {
    files: HashMap<PathBuf, String>,
}

impl BirdNixIO {
    fn new() -> Self {
        let vfs = build_vfs();
        let mut files: HashMap<PathBuf, String> = HashMap::new();
        for (path, content) in vfs {
            files.insert(path, content.to_string());
        }
        BirdNixIO { files }
    }

    /// Add or update a file in the virtual filesystem.
    #[allow(dead_code)]
    fn set_file(&mut self, path: PathBuf, content: String) {
        self.files.insert(path, content);
    }
}

impl EvalIO for BirdNixIO {
    fn path_exists(&self, path: &Path) -> io::Result<bool> {
        // Check both file and directory existence
        if self.files.contains_key(path) {
            return Ok(true);
        }
        // Check if it's a directory (any file starts with this path)
        let path_str = path.to_string_lossy();
        let is_dir = self.files.keys().any(|k| {
            let k_str = k.to_string_lossy();
            k_str.starts_with(path_str.as_ref()) && k_str.len() > path_str.len()
        });
        Ok(is_dir)
    }

    fn open(&self, path: &Path) -> io::Result<Box<dyn io::Read>> {
        match self.files.get(path) {
            Some(content) => Ok(Box::new(io::Cursor::new(content.clone().into_bytes()))),
            None => Err(io::Error::new(
                io::ErrorKind::NotFound,
                format!("file not found in VFS: {}", path.display()),
            )),
        }
    }

    fn file_type(&self, path: &Path) -> io::Result<FileType> {
        if self.files.contains_key(path) {
            return Ok(FileType::Regular);
        }
        // Check directory
        let path_str = path.to_string_lossy();
        let is_dir = self.files.keys().any(|k| {
            let k_str = k.to_string_lossy();
            k_str.starts_with(path_str.as_ref()) && k_str.len() > path_str.len()
        });
        if is_dir {
            Ok(FileType::Directory)
        } else {
            Err(io::Error::new(
                io::ErrorKind::NotFound,
                format!("not found in VFS: {}", path.display()),
            ))
        }
    }

    fn read_dir(&self, path: &Path) -> io::Result<Vec<(bytes::Bytes, FileType)>> {
        let path_str = format!("{}/", path.display());
        let mut entries: HashMap<String, FileType> = HashMap::new();

        for key in self.files.keys() {
            let key_str = key.to_string_lossy();
            if let Some(rest) = key_str.strip_prefix(&path_str) {
                // Direct child: no more '/' in the rest, or first segment before '/'
                let name = if let Some(idx) = rest.find('/') {
                    rest[..idx].to_string()
                } else {
                    rest.to_string()
                };
                let ft = if rest.contains('/') {
                    FileType::Directory
                } else {
                    FileType::Regular
                };
                entries.insert(name, ft);
            }
        }

        Ok(entries
            .into_iter()
            .map(|(name, ft)| (bytes::Bytes::from(name), ft))
            .collect())
    }

    fn import_path(&self, path: &Path) -> io::Result<PathBuf> {
        // In-memory: just return the path as-is
        Ok(path.to_path_buf())
    }
}

// ── Nix Evaluation ─────────────────────────────────────────────────────────

/// Evaluate a Nix expression using tvix-eval with the bird-nix library
/// available via import.
fn eval_nix(code: &str) -> Result<String, String> {
    let io = Rc::new(BirdNixIO::new());

    let eval = Evaluation::builder(io as Rc<dyn EvalIO>)
        .enable_import()
        .build();

    let result = eval.evaluate(code, Some(PathBuf::from("/bird-nix/src")));

    // Collect errors
    if !result.errors.is_empty() {
        let error_msgs: Vec<String> = result.errors.iter().map(|e| format!("{:#}", e)).collect();
        return Err(error_msgs.join("\n"));
    }

    // Collect warnings too for diagnostics
    if !result.warnings.is_empty() {
        let warns: Vec<String> = result.warnings.iter().map(|w| format!("{:?}", w)).collect();
        eprintln!("  warnings: {}", warns.join("; "));
    }

    match result.value {
        Some(value) => Ok(format!("{}", value)),
        None => Err("evaluation produced no value".to_string()),
    }
}

/// Evaluate Nix code with the bird-nix prelude automatically imported.
/// Wraps user code so `birds`, `B`, `K`, `S`, etc. are in scope.
fn eval_with_prelude(code: &str) -> Result<String, String> {
    let wrapped = format!(
        r#"let
  birds = import ./birds.nix {{}};
  inherit (birds) I M K KI B C L W S V Y;
  __result = {};
in builtins.deepSeq __result __result"#,
        code
    );
    eval_nix(&wrapped)
}

// ── WASM API ───────────────────────────────────────────────────────────────

/// Evaluate a Nix expression. Returns JSON:
/// { "ok": true, "value": "...", "type": "..." }
/// or { "ok": false, "error": "..." }
#[wasm_bindgen]
pub fn nix_eval(code: &str) -> String {
    match eval_with_prelude(code) {
        Ok(value) => serde_json::json!({
            "ok": true,
            "value": value,
        })
        .to_string(),
        Err(err) => serde_json::json!({
            "ok": false,
            "error": err,
        })
        .to_string(),
    }
}

/// Evaluate raw Nix (no prelude). For advanced use / importing specific modules.
#[wasm_bindgen]
pub fn nix_eval_raw(code: &str) -> String {
    match eval_nix(code) {
        Ok(value) => serde_json::json!({
            "ok": true,
            "value": value,
        })
        .to_string(),
        Err(err) => serde_json::json!({
            "ok": false,
            "error": err,
        })
        .to_string(),
    }
}

/// Validate Nix code and return diagnostics for Monaco.
/// Uses tvix's compiler in compile-only mode for real Nix diagnostics.
#[wasm_bindgen]
pub fn nix_validate(code: &str) -> String {
    let io = Rc::new(BirdNixIO::new());

    let eval = Evaluation::builder(io as Rc<dyn EvalIO>)
        .enable_import()
        .build();

    // Wrap with prelude for validation too
    let wrapped = format!(
        r#"let
  birds = import ./birds.nix {{}};
  inherit (birds) I M K KI B C L W S V Y;
in
{}"#,
        code
    );

    let result = eval.compile_only(&wrapped, Some(PathBuf::from("/bird-nix/src")));

    let mut diagnostics = Vec::new();

    // The prelude adds 4 lines before user code
    let _prelude_lines: usize = 4;

    for error in &result.errors {
        diagnostics.push(serde_json::json!({
            "line": 1,
            "col": 1,
            "endCol": 100,
            "message": format!("{}", error),
            "severity": "error"
        }));
    }

    for warning in &result.warnings {
        diagnostics.push(serde_json::json!({
            "line": 1,
            "col": 1,
            "endCol": 100,
            "message": format!("{:?}", warning),
            "severity": "warning"
        }));
    }

    let ok = result.errors.is_empty();
    serde_json::json!({
        "ok": ok,
        "diagnostics": diagnostics
    })
    .to_string()
}

/// Return demo expressions as real Nix code.
/// Core birds, algebraic laws, GCL graph examples (translated from old .ggl),
/// and real-world Nix patterns.
#[wasm_bindgen]
pub fn nix_demos() -> String {
    serde_json::json!([
        serde_json::json!({"category": "Core Birds", "name": "I — Identity", "description": "Identity bird returns its argument unchanged: I x = x", "code": include_str!("../demos/i-identity.nix")}),
        serde_json::json!({"category": "Core Birds", "name": "K — Kestrel", "description": "Kestrel keeps the first, discards the second: K x y = x", "code": include_str!("../demos/k-kestrel.nix")}),
        serde_json::json!({"category": "Core Birds", "name": "KI — Kite", "description": "Kite discards the first, keeps the second: KI x y = y", "code": include_str!("../demos/ki-kite.nix")}),
        serde_json::json!({"category": "Core Birds", "name": "M — Mockingbird", "description": "Mockingbird self-applies: M f = f f. M I = I I = I", "code": include_str!("../demos/m-mockingbird.nix")}),
        serde_json::json!({"category": "Core Birds", "name": "B — Bluebird (Compose)", "description": "Bluebird composes functions: B f g x = f (g x). Here: (5*2)+1 = 11", "code": include_str!("../demos/b-bluebird-compose.nix")}),
        serde_json::json!({"category": "Core Birds", "name": "C — Cardinal (Flip)", "description": "Cardinal flips arguments: C f x y = f y x", "code": include_str!("../demos/c-cardinal-flip.nix")}),
        serde_json::json!({"category": "Core Birds", "name": "W — Warbler (Duplicate)", "description": "Warbler duplicates: W f x = f x x. Here: 5 + 5 = 10", "code": include_str!("../demos/w-warbler-duplicate.nix")}),
        serde_json::json!({"category": "Core Birds", "name": "S — Starling (Fork)", "description": "Starling forks: S f g x = f x (g x). Here: 3 + (3*2) = 9", "code": include_str!("../demos/s-starling-fork.nix")}),
        serde_json::json!({"category": "Core Birds", "name": "V — Vireo (Pair)", "description": "Vireo pairs: V x y f = f x y. Use K to extract first, KI for second", "code": include_str!("../demos/v-vireo-pair.nix")}),
        serde_json::json!({"category": "Core Birds", "name": "L — Lark", "description": "Lark: L f g = f (g g). Combines composition with self-application", "code": include_str!("../demos/l-lark.nix")}),
        serde_json::json!({"category": "Core Birds", "name": "Y — Sage (Fixpoint)", "description": "Y combinator: Y f = f (Y f). Enables recursion without explicit self-reference", "code": include_str!("../demos/y-sage-fixpoint.nix")}),
        serde_json::json!({"category": "Algebraic Laws", "name": "S K K = I", "description": "S K K reduces to identity. Proof: S K K x = K x (K x) = x", "code": include_str!("../demos/s-k-k-i.nix")}),
        serde_json::json!({"category": "Algebraic Laws", "name": "W K = I", "description": "W K x = K x x = x. Warbler-Kestrel is another Identity encoding", "code": include_str!("../demos/w-k-i.nix")}),
        serde_json::json!({"category": "Algebraic Laws", "name": "M I = I", "description": "M I = I I = I. Mockingbird-Identity stays identity", "code": include_str!("../demos/m-i-i.nix")}),
        serde_json::json!({"category": "Algebraic Laws", "name": "B f I = f", "description": "Right identity of composition: composing with identity is a no-op", "code": include_str!("../demos/b-f-i-f.nix")}),
        serde_json::json!({"category": "Algebraic Laws", "name": "B I f = f", "description": "Left identity of composition: identity composed with f is still f", "code": include_str!("../demos/b-i-f-f.nix")}),
        serde_json::json!({"category": "Algebraic Laws", "name": "C K = KI", "description": "C K x y = K y x = y. Cardinal-Kestrel = Kite", "code": include_str!("../demos/c-k-ki.nix")}),
        serde_json::json!({"category": "Algebraic Laws", "name": "V pair selectors", "description": "V x y K = x, V x y KI = y — Vireo pairs with Kestrel/Kite select elements", "code": include_str!("../demos/v-pair-selectors.nix")}),
        serde_json::json!({"category": "Church Encodings", "name": "Church Booleans", "description": "true = K (select first), false = KI (select second), not = C (flip)", "code": include_str!("../demos/church-booleans.nix")}),
        serde_json::json!({"category": "Church Encodings", "name": "Church Numerals", "description": "Numbers as repeated function application: n f x = f^n(x)", "code": include_str!("../demos/church-numerals.nix")}),
        serde_json::json!({"category": "Church Encodings", "name": "Church Pairs (Vireo)", "description": "Pairs built from V, linked list from nested pairs", "code": include_str!("../demos/church-pairs-vireo.nix")}),
        serde_json::json!({"category": "Real Nix", "name": "Birds as data", "description": "Wrap bird combinators in attribute sets with metadata", "code": include_str!("../demos/birds-as-data.nix")}),
        serde_json::json!({"category": "Real Nix", "name": "Pipeline with B", "description": "Chain transformations using bluebird composition", "code": include_str!("../demos/pipeline-with-b.nix")}),
        serde_json::json!({"category": "Real Nix", "name": "Map with combinators", "description": "Use S and K to build map/filter from scratch", "code": include_str!("../demos/map-with-combinators.nix")}),
        serde_json::json!({"category": "Real Nix", "name": "Recursive factorial (Y)", "description": "Y combinator enables anonymous recursion — no let rec needed", "code": include_str!("../demos/recursive-factorial-y.nix")}),
        serde_json::json!({"category": "Library", "name": "Import birds.nix", "description": "Import the canonical bird definitions directly", "code": include_str!("../demos/import-birds-nix.nix")}),
        serde_json::json!({"category": "Library", "name": "Bird speech", "description": "Each bird has a personality and explains what it does", "code": include_str!("../demos/bird-speech.nix")}),
        serde_json::json!({"category": "Library", "name": "Full library", "description": "Import the entire bird-nix library with all modules", "code": include_str!("../demos/full-library.nix")}),
        serde_json::json!({"category": "GCL Generators", "name": "Path graph", "description": "Generate a linear chain: n0 → n1 → n2 → n3 → n4", "code": include_str!("../demos/path-graph.nix")}),
        serde_json::json!({"category": "GCL Generators", "name": "Star graph", "description": "Hub-and-spoke: center node connected to all spokes", "code": include_str!("../demos/star-graph.nix")}),
        serde_json::json!({"category": "GCL Generators", "name": "Complete graph", "description": "Every node connected to every other node (K₄)", "code": include_str!("../demos/complete-graph.nix")}),
        serde_json::json!({"category": "GCL Generators", "name": "Cycle graph", "description": "Path with last node looping back to first", "code": include_str!("../demos/cycle-graph.nix")}),
        serde_json::json!({"category": "GCL Generators", "name": "Grid graph", "description": "2D lattice — each node connects right and down", "code": include_str!("../demos/grid-graph.nix")}),
        serde_json::json!({"category": "GCL Rewrites", "name": "Subdivide edge", "description": "Replace edge a→b with a→mid→b (insert intermediate node)", "code": include_str!("../demos/subdivide-edge.nix")}),
        serde_json::json!({"category": "GCL Rewrites", "name": "Hub rule", "description": "Add a central hub connected bidirectionally to all existing nodes", "code": include_str!("../demos/hub-rule.nix")}),
        serde_json::json!({"category": "GCL Rewrites", "name": "Reverse edges", "description": "Flip all directed edges (the Cardinal transformation)", "code": include_str!("../demos/reverse-edges.nix")}),
        serde_json::json!({"category": "GCL Rewrites", "name": "Compose transforms", "description": "B (Bluebird) composes graph transformations sequentially", "code": include_str!("../demos/compose-transforms.nix")}),
        serde_json::json!({"category": "GCL Real-World", "name": "Social network", "description": "Friend graph with metadata — translated from social_network.ggl", "code": include_str!("../demos/social-network.nix")}),
        serde_json::json!({"category": "GCL Real-World", "name": "Neural network layers", "description": "Input → Hidden → Output layer connectivity — from neural_network.ggl", "code": include_str!("../demos/neural-network-layers.nix")}),
        serde_json::json!({"category": "GCL Real-World", "name": "HPC cluster topology", "description": "GPU/CPU compute nodes with scheduler — from hpc_network.ggl", "code": include_str!("../demos/hpc-cluster-topology.nix")}),
        serde_json::json!({"category": "GCL Real-World", "name": "Quantum circuit", "description": "Qubits and gates with entanglement edges — from quantum_circuit.ggl", "code": include_str!("../demos/quantum-circuit.nix")}),
        serde_json::json!({"category": "GCL Real-World", "name": "Toroidal mesh", "description": "6×6 torus network with wrap-around edges — from toroidal_mesh.ggl", "code": include_str!("../demos/toroidal-mesh.nix")}),
        serde_json::json!({"category": "GCL Real-World", "name": "Protein interaction network", "description": "p53/MDM2/ATM signaling pathway — from protein_network.ggl", "code": include_str!("../demos/protein-interaction-network.nix")}),
        serde_json::json!({"category": "GCL Real-World", "name": "Chemical reaction graph", "description": "H₂ + O₂ → H₂O catalyzed by Pt — from chemical_reaction.ggl", "code": include_str!("../demos/chemical-reaction-graph.nix")}),
    ])
    .to_string()
}

// ── Panel Kit UI ──────────────────────────────────────────────────────────

#[cfg(target_arch = "wasm32")]
mod ui {
    use super::{eval_with_prelude, nix_demos};
    use dioxus::events::{Key, KeyboardEvent, MouseEvent};
    use dioxus::prelude::*;
    use panel_kit::{
        is_editing, use_workspace, LayoutBuilder, Mode, PanelKind, PanelWin, WinState, CSS,
    };
    use serde::{Deserialize, Serialize};

    const STORAGE_KEY: &str = "bird_nix_panelkit_layout";

    const APP_CSS: &str = r#"
/* bird-nix UI overlay.
   Do NOT override the panel-kit :root palette here — this playground is
   embedded via iframe inside the info.casazza.io workspace, which uses the
   same panel-kit chrome. Recoloring on :root breaks visual consistency with
   the outer panel. Only override what is genuinely bird-nix-specific:
   the mono font (Inconsolata, loaded in index.html) and the UI density. */
:root {
  --mono: 'Inconsolata', ui-monospace, monospace;
  font-size: 18px;
}
.topbar button {
  background: var(--bg);
  border: 1px solid var(--line2);
  border-radius: 3px;
  color: var(--fg);
  cursor: pointer;
  font-size: .72rem;
  padding: .15rem .5rem;
}
.topbar button:hover { border-color: var(--fg); }
.topbar .status-ok { color: var(--green); }
.topbar .status-bad { color: var(--pink); }
.ws.tiling .panel-editor,
.ws.tiling .panel-output { --panel-grow: 2; }
.panel-body { padding: 1.7rem .6rem .6rem; }
.toolbar { align-items: center; display: flex; gap: .45rem; margin-bottom: .5rem; }
.toolbar button, .demo-button, .ref-button, .repl-run {
  background: var(--bg);
  border: 1px solid var(--line2);
  border-radius: 3px;
  color: var(--fg);
  cursor: pointer;
  font-size: .72rem;
  padding: .2rem .5rem;
}
.toolbar button:hover, .demo-button:hover, .ref-button:hover, .repl-run:hover {
  border-color: var(--accent);
  color: var(--accent);
}
.code-area, .repl-input {
  background: var(--bg);
  border: 1px solid var(--line2);
  border-radius: 3px;
  color: var(--fg);
  font-family: var(--mono);
  font-size: .86rem;
  outline: none;
  padding: .55rem;
  width: 100%;
}
.code-area {
  height: calc(100% - 2.3rem);
  min-height: 180px;
  resize: none;
}
.output-pre, .repl-log {
  background: var(--bg);
  border: 1px solid var(--line);
  border-radius: 3px;
  color: var(--fg);
  font-size: .8rem;
  height: 100%;
  margin: 0;
  overflow: auto;
  padding: .55rem;
  white-space: pre-wrap;
}
.demo-group { border-bottom: 1px solid var(--line); padding: .35rem 0 .5rem; }
.demo-group-title, .section-title {
  color: var(--yellow);
  font-size: .72rem;
  font-weight: 700;
  letter-spacing: .04em;
  margin: .25rem 0;
  text-transform: uppercase;
}
.demo-button {
  display: block;
  margin: .22rem 0;
  overflow: hidden;
  text-align: left;
  text-overflow: ellipsis;
  width: 100%;
}
.muted { color: var(--dim); }
.ref-card, .law-card {
  background: var(--bg);
  border: 1px solid var(--line);
  border-radius: 3px;
  margin-bottom: .5rem;
  padding: .5rem;
}
.ref-button {
  display: flex;
  justify-content: space-between;
  margin-bottom: .35rem;
  width: 100%;
}
.ref-rule, .law-name { color: var(--yellow); font-weight: 700; }
.ref-type, .ref-description, .law-description {
  color: var(--dim);
  font-size: .74rem;
  line-height: 1.35;
}
.repl-shell { display: grid; gap: .5rem; grid-template-rows: 1fr auto; height: 100%; }
.repl-row { display: flex; gap: .4rem; }
.repl-input { flex: 1; }
.repl-line { margin-bottom: .3rem; }
.repl-in { color: var(--accent); }
.repl-out { color: var(--green); }
.repl-err { color: var(--pink); }
"#;

    const DEFAULT_CODE: &str = r#"# bird-nix playground - real Nix evaluation in the browser
# The bird combinators (I, M, K, KI, B, C, W, S, L, V, Y) are preloaded.
# Press Ctrl+Enter or Evaluate.

K "yes" "no""#;

    const BIRD_DATA_JSON: &str = include_str!("../bird-data.json");

    #[derive(Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
    enum PlaygroundPanel {
        Editor,
        Output,
        Demos,
        Reference,
        Laws,
        Repl,
    }

    impl PanelKind for PlaygroundPanel {
        fn title(self) -> &'static str {
            match self {
                PlaygroundPanel::Editor => "Editor",
                PlaygroundPanel::Output => "Output",
                PlaygroundPanel::Demos => "Demos",
                PlaygroundPanel::Reference => "Reference",
                PlaygroundPanel::Laws => "Laws",
                PlaygroundPanel::Repl => "REPL",
            }
        }
    }

    #[derive(Clone, Deserialize)]
    struct Demo {
        category: String,
        name: String,
        description: String,
        code: String,
    }

    #[derive(Clone, Deserialize)]
    struct BirdInfo {
        aka: String,
        description: String,
        name: String,
        rule: String,
        speech: String,
        #[serde(rename = "type")]
        ty: String,
    }

    #[derive(Clone, Deserialize)]
    struct Law {
        description: String,
        name: String,
    }

    #[derive(Clone, Deserialize)]
    struct BirdData {
        #[serde(rename = "birdList")]
        bird_list: Vec<BirdInfo>,
        laws: Vec<Law>,
    }

    #[derive(Clone)]
    struct ReplEntry {
        input: String,
        output: String,
        ok: bool,
    }

    fn default_layout() -> Vec<PanelWin<PlaygroundPanel>> {
        let mut b = LayoutBuilder::new();
        let mut laws = b.at(PlaygroundPanel::Laws, 900.0, 350.0, 320.0, 250.0);
        laws.state = WinState::Minimized;
        vec![
            b.at(PlaygroundPanel::Editor, 300.0, 16.0, 560.0, 430.0),
            b.at(PlaygroundPanel::Output, 300.0, 462.0, 560.0, 250.0),
            b.at(PlaygroundPanel::Demos, 16.0, 16.0, 260.0, 696.0),
            b.at(PlaygroundPanel::Reference, 884.0, 16.0, 330.0, 320.0),
            laws,
            b.at(PlaygroundPanel::Repl, 884.0, 350.0, 330.0, 250.0),
        ]
    }

    fn run_eval(code: &str) -> (String, bool) {
        match eval_with_prelude(code) {
            Ok(value) => (value, true),
            Err(err) => (err, false),
        }
    }

    fn grouped_demos(demos: &[Demo]) -> Vec<(String, Vec<Demo>)> {
        let mut groups: Vec<(String, Vec<Demo>)> = Vec::new();
        for demo in demos {
            if let Some((_, items)) = groups.iter_mut().find(|(cat, _)| cat == &demo.category) {
                items.push(demo.clone());
            } else {
                groups.push((demo.category.clone(), vec![demo.clone()]));
            }
        }
        groups
    }

    #[wasm_bindgen::prelude::wasm_bindgen(start)]
    pub fn start() {
        dioxus::launch(App);
    }

    #[component]
    fn App() -> Element {
        let ws = use_workspace(STORAGE_KEY, default_layout);
        let mut code = use_signal(|| DEFAULT_CODE.to_string());
        let mut output = use_signal(|| "# Output will appear here".to_string());
        let mut status = use_signal(|| "tvix ready".to_string());
        let mut last_ok = use_signal(|| true);
        let mut repl_input = use_signal(String::new);
        let mut repl_log = use_signal(Vec::<ReplEntry>::new);
        let demos =
            use_signal(|| serde_json::from_str::<Vec<Demo>>(&nix_demos()).unwrap_or_default());
        let bird_data = use_signal(|| {
            serde_json::from_str::<BirdData>(BIRD_DATA_JSON).unwrap_or(BirdData {
                bird_list: Vec::new(),
                laws: Vec::new(),
            })
        });

        let mut evaluate = move || {
            let current = code.read().clone();
            let (value, ok) = run_eval(&current);
            output.set(value);
            last_ok.set(ok);
            status.set(if ok { "evaluated" } else { "evaluation failed" }.to_string());
        };

        let mut submit_repl = move || {
            let text = repl_input.read().trim().to_string();
            if text.is_empty() {
                return;
            }
            let (value, ok) = run_eval(&text);
            repl_log.write().push(ReplEntry {
                input: text,
                output: value,
                ok,
            });
            repl_input.set(String::new());
        };

        let mode_label = match ws.effective_mode() {
            Mode::Floating => "floating",
            Mode::Tiling => "tiling",
        };

        let body = move |kind: PlaygroundPanel, _maximized: bool| -> Element {
            match kind {
                PlaygroundPanel::Editor => rsx! {
                    div { class: "toolbar",
                        button { onclick: move |_| evaluate(), "Evaluate" }
                        span { class: "muted", "Ctrl+Enter works here; panel chrome comes from panel-kit." }
                    }
                    textarea {
                        class: "code-area",
                        value: "{code.read()}",
                        spellcheck: "false",
                        oninput: move |e| code.set(e.value()),
                        onkeydown: move |e: KeyboardEvent| {
                            if e.modifiers().ctrl() && e.key() == Key::Enter {
                                evaluate();
                            }
                        },
                    }
                },
                PlaygroundPanel::Output => rsx! {
                    pre { class: "output-pre", "{output.read()}" }
                },
                PlaygroundPanel::Demos => {
                    let groups = grouped_demos(&demos.read());
                    rsx! {
                        for (category, items) in groups {
                            div { class: "demo-group",
                                div { class: "demo-group-title", "{category}" }
                                for demo in items {
                                    button {
                                        class: "demo-button",
                                        title: "{demo.description}",
                                        onclick: move |_| {
                                            let current = format!("# {}\n{}", demo.description, demo.code);
                                            code.set(current.clone());
                                            let (value, ok) = run_eval(&current);
                                            output.set(value);
                                            last_ok.set(ok);
                                            status.set(if ok { "demo evaluated" } else { "demo failed" }.to_string());
                                        },
                                        "{demo.name}"
                                    }
                                }
                            }
                        }
                    }
                }
                PlaygroundPanel::Reference => {
                    let birds = bird_data.read().bird_list.clone();
                    rsx! {
                        div { class: "section-title", "Birds" }
                        for bird in birds {
                            div { class: "ref-card",
                                button {
                                    class: "ref-button",
                                    onclick: move |_| code.set(bird.name.clone()),
                                    span { "{bird.aka}" }
                                    span { "{bird.name}" }
                                }
                                div { class: "ref-rule", "{bird.rule}" }
                                div { class: "ref-type", "{bird.ty}" }
                                div { class: "ref-description", "{bird.description}" }
                                div { class: "ref-description", "{bird.speech}" }
                            }
                        }
                    }
                }
                PlaygroundPanel::Laws => {
                    let laws = bird_data.read().laws.clone();
                    rsx! {
                        div { class: "section-title", "Algebraic laws" }
                        for law in laws {
                            div { class: "law-card",
                                div { class: "law-name", "{law.name}" }
                                div { class: "law-description", "{law.description}" }
                            }
                        }
                    }
                }
                PlaygroundPanel::Repl => rsx! {
                    div { class: "repl-shell",
                        div { class: "repl-log",
                            if repl_log.read().is_empty() {
                                div { class: "muted", "The bird-nix prelude is loaded. Try: S K K \"hello\"" }
                            }
                            for entry in repl_log.read().iter() {
                                div { class: "repl-line repl-in", "nix> {entry.input}" }
                                div { class: if entry.ok { "repl-line repl-out" } else { "repl-line repl-err" }, "{entry.output}" }
                            }
                        }
                        div { class: "repl-row",
                            input {
                                class: "repl-input",
                                value: "{repl_input.read()}",
                                placeholder: "K \"yes\" \"no\"",
                                oninput: move |e| repl_input.set(e.value()),
                                onkeydown: move |e: KeyboardEvent| {
                                    if e.key() == Key::Enter {
                                        submit_repl();
                                    }
                                },
                            }
                            button { class: "repl-run", onclick: move |_| submit_repl(), "Run" }
                        }
                    }
                },
            }
        };

        rsx! {
            style { {CSS} }
            style { {APP_CSS} }
            div {
                class: ws.root_class(),
                tabindex: "0",
                onmousemove: move |e: MouseEvent| ws.handle_mouse_move(&e),
                onmouseup: move |_| ws.handle_mouse_up(),
                onkeydown: move |e: KeyboardEvent| {
                    if is_editing() {
                        return;
                    }
                    if let Key::Character(c) = e.key() {
                        if c == "t" {
                            let mut mode = ws.mode;
                            let next = if *mode.read() == Mode::Tiling {
                                Mode::Floating
                            } else {
                                Mode::Tiling
                            };
                            mode.set(next);
                        }
                    }
                },
                header { class: "topbar",
                    h1 { "bird-nix playground" }
                    span { class: "hint", "panel-kit default layout · {mode_label} · drag, resize, minimize, dock" }
                    button { onclick: move |_| evaluate(), "evaluate" }
                    button {
                        onclick: move |_| {
                            let mut mode = ws.mode;
                            let next = if *mode.read() == Mode::Tiling { Mode::Floating } else { Mode::Tiling };
                            mode.set(next);
                        },
                        "toggle mode"
                    }
                    span { class: if *last_ok.read() { "activity status-ok" } else { "activity status-bad" }, "{status.read()}" }
                }
                {ws.render(body)}
                {ws.dock()}
            }
        }
    }
}

// ── Tests ──────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_vfs_contains_birds() {
        let io = BirdNixIO::new();
        assert!(io
            .files
            .contains_key(&PathBuf::from("/bird-nix/src/birds.nix")));
        assert!(io
            .files
            .contains_key(&PathBuf::from("/bird-nix/src/ast.nix")));
    }

    #[test]
    fn test_eval_literal() {
        let result = eval_nix("42");
        assert_eq!(result.unwrap(), "42");
    }

    #[test]
    fn test_eval_string() {
        let result = eval_nix("\"hello\"");
        assert_eq!(result.unwrap(), "\"hello\"");
    }

    #[test]
    fn test_eval_let() {
        let result = eval_nix("let x = 1; y = 2; in x + y");
        assert_eq!(result.unwrap(), "3");
    }

    #[test]
    fn test_eval_lambda() {
        let result = eval_nix("let f = x: x + 1; in f 5");
        assert_eq!(result.unwrap(), "6");
    }

    #[test]
    fn test_eval_attrset() {
        let result = eval_nix("{ a = 1; b = 2; }");
        assert!(result.is_ok());
    }

    #[test]
    fn test_eval_import_birds() {
        let result = eval_nix("let birds = import ./birds.nix {}; in birds.K \"yes\" \"no\"");
        assert_eq!(result.unwrap(), "\"yes\"");
    }

    #[test]
    fn test_prelude_identity() {
        let result = eval_with_prelude("I \"hello\"");
        assert_eq!(result.unwrap(), "\"hello\"");
    }

    #[test]
    fn test_prelude_kestrel() {
        let result = eval_with_prelude("K \"yes\" \"no\"");
        assert_eq!(result.unwrap(), "\"yes\"");
    }

    #[test]
    fn test_prelude_kite() {
        let result = eval_with_prelude("KI \"yes\" \"no\"");
        assert_eq!(result.unwrap(), "\"no\"");
    }

    #[test]
    fn test_prelude_composition() {
        let result = eval_with_prelude("let f = x: x + 1; g = x: x * 2; in B f g 5");
        assert_eq!(result.unwrap(), "11");
    }

    #[test]
    fn test_prelude_skk_identity() {
        let result = eval_with_prelude("S K K \"test\"");
        assert_eq!(result.unwrap(), "\"test\"");
    }

    #[test]
    fn test_prelude_vireo_k() {
        let result = eval_with_prelude("V \"a\" \"b\" K");
        assert_eq!(result.unwrap(), "\"a\"");
    }

    #[test]
    fn test_prelude_vireo_ki() {
        let result = eval_with_prelude("V \"a\" \"b\" KI");
        assert_eq!(result.unwrap(), "\"b\"");
    }

    #[test]
    fn test_syntax_error() {
        let result = eval_nix("let x = in");
        assert!(result.is_err());
    }

    #[test]
    fn test_graph_import() {
        // Step 1: bare import — returns lambda
        let r1 = eval_nix("import ./graph.nix");
        eprintln!("1. bare import: {:?}", r1);

        // Step 2: call with {} and get emptyGraph
        let r2 = eval_nix("(import ./graph.nix {}).emptyGraph");
        eprintln!("2. emptyGraph: {:?}", r2);

        // Step 3: nodeCount is B builtins.length getNodeIds — it's a lambda
        // tvix might choke on deepSeq of a partially-applied builtin
        let r3 = eval_nix("let g = import ./graph.nix {}; in g.nodeCount g.emptyGraph");
        eprintln!("3. nodeCount applied: {:?}", r3);

        // Step 3b: same thing without deepSeq (eval_nix wraps with deepSeq via eval_with_prelude — wait, no it doesn't)
        // Actually eval_nix does NOT wrap. Let me check — the issue is nodeCount = B builtins.length getNodeIds
        // which returns a closure over builtins.length. tvix might fail to apply a partially-applied builtin via B.
        let r3b = eval_nix("let birds = import ./birds.nix {}; nc = birds.B builtins.length builtins.attrNames; in nc { a = 1; }");
        eprintln!("3b. B length attrNames inline: {:?}", r3b);

        // Step 3c: same definition as graph.nix uses
        let r3c = eval_nix("let birds = import ./birds.nix {}; getNodeIds = g: builtins.attrNames g.nodes; nc = birds.B builtins.length getNodeIds; in nc { nodes = {}; edges = {}; }");
        eprintln!("3c. B length getNodeIds applied: {:?}", r3c);

        // Step 3d: is it the double-import? graph.nix imports birds.nix, we also import birds.nix
        let r3d = eval_nix("let g = import ./graph.nix {}; in builtins.length (builtins.attrNames g.emptyGraph.nodes)");
        eprintln!("3d. inline nodeCount: {:?}", r3d);

        // Step 3e: get individual attrs from graph
        let r3e = eval_nix("let g = import ./graph.nix {}; in builtins.attrNames g");
        eprintln!("3e. graph attrNames: {:?}", r3e);

        // Step 3f: try calling nodeCount
        let r3f =
            eval_nix("let g = import ./graph.nix {}; in g.nodeCount { nodes = {}; edges = {}; }");
        eprintln!("3f. nodeCount on literal: {:?}", r3f);

        let r7 = r3;

        assert!(r7.is_ok(), "graph import failed: {:?}", r7.err());
    }

    #[test]
    fn test_graph_combinators_import() {
        // graph-combinators.nix now takes { graph } parameter to avoid tvix closure bugs

        // Step 1: can we list attrs?
        let r1 = eval_nix("let g = import ./graph.nix {}; gc = import ./graph-combinators.nix { graph = g; }; in builtins.attrNames gc");
        eprintln!("gc1. attrNames: {:?}", r1);
        assert!(r1.is_ok(), "attrNames failed: {:?}", r1.err());

        // Step 2: identityGraph on a simple value
        let r2a = eval_nix(
            r#"let g = import ./graph.nix {}; gc = import ./graph-combinators.nix { graph = g; }; in gc.identityGraph 42"#,
        );
        eprintln!("gc2a. identityGraph 42: {:?}", r2a);
        assert!(r2a.is_ok(), "identityGraph failed: {:?}", r2a.err());

        // Step 3: gclTypeEnv pass-through
        let r3 = eval_nix(
            r#"let g = import ./graph.nix {}; gc = import ./graph-combinators.nix { graph = g; }; in gc.gclTypeEnv.I"#,
        );
        eprintln!("gc3. gclTypeEnv.I: {:?}", r3);
        assert!(r3.is_ok(), "gclTypeEnv failed: {:?}", r3.err());

        // Step 4: pathGen
        let r4 = eval_nix(
            r#"let g = import ./graph.nix {}; gc = import ./graph-combinators.nix { graph = g; }; in gc.pathGen { nodes = 1; prefix = "p"; }"#,
        );
        eprintln!("gc4. pathGen 1 node: {:?}", r4);
        assert!(r4.is_ok(), "pathGen failed: {:?}", r4.err());

        // Step 5: pathGen with nodeCount
        let r5 = eval_nix(
            r#"let g = import ./graph.nix {}; gc = import ./graph-combinators.nix { graph = g; }; in g.nodeCount (gc.pathGen { nodes = 3; prefix = "p"; })"#,
        );
        eprintln!("gc5. pathGen 3 nodeCount: {:?}", r5);
        assert!(r5.is_ok(), "pathGen nodeCount failed: {:?}", r5.err());
    }

    #[test]
    fn test_social_network_demo() {
        let code = include_str!("../demos/social-network.nix");
        let result = eval_with_prelude(code);
        assert!(
            result.is_ok(),
            "social network demo failed: {:?}",
            result.err()
        );
    }

    #[test]
    fn test_path_graph_demo() {
        let code = include_str!("../demos/path-graph.nix");
        let result = eval_with_prelude(code);
        assert!(result.is_ok(), "path graph demo failed: {:?}", result.err());
    }

    #[test]
    fn test_neural_network_demo() {
        let code = include_str!("../demos/neural-network-layers.nix");
        let result = eval_with_prelude(code);
        assert!(
            result.is_ok(),
            "neural network demo failed: {:?}",
            result.err()
        );
    }

    #[test]
    fn test_hpc_cluster_demo() {
        let code = include_str!("../demos/hpc-cluster-topology.nix");
        let result = eval_with_prelude(code);
        assert!(
            result.is_ok(),
            "hpc cluster demo failed: {:?}",
            result.err()
        );
    }

    #[test]
    fn test_quantum_circuit_demo() {
        let code = include_str!("../demos/quantum-circuit.nix");
        let result = eval_with_prelude(code);
        assert!(
            result.is_ok(),
            "quantum circuit demo failed: {:?}",
            result.err()
        );
    }

    #[test]
    fn test_toroidal_mesh_demo() {
        let code = include_str!("../demos/toroidal-mesh.nix");
        let result = eval_with_prelude(code);
        assert!(
            result.is_ok(),
            "toroidal mesh demo failed: {:?}",
            result.err()
        );
    }

    #[test]
    fn test_protein_interaction_demo() {
        let code = include_str!("../demos/protein-interaction-network.nix");
        let result = eval_with_prelude(code);
        assert!(
            result.is_ok(),
            "protein interaction demo failed: {:?}",
            result.err()
        );
    }

    #[test]
    fn test_chemical_reaction_demo() {
        let code = include_str!("../demos/chemical-reaction-graph.nix");
        let result = eval_with_prelude(code);
        assert!(
            result.is_ok(),
            "chemical reaction demo failed: {:?}",
            result.err()
        );
    }
}
