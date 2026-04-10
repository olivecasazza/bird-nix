# AGENTS.md — bird-nix project instructions for AI coding agents

## Project Overview

bird-nix is a combinator library implementing the birds from Raymond Smullyan's
"To Mock a Mockingbird" as pure Nix expressions. It provides combinators (I, M, K,
KI, B, L, W, S, Y), a DSL, a compiler, a pretty-printer, and a self-bootstrapping
test framework — all in Nix.

## The Dogfooding Rule (MANDATORY)

**Every component of this library MUST use its own tools whenever possible.**

This is the single most important directive. Before writing any new code, ask:
"Can I import and use an existing bird-nix module instead of reimplementing?"

### What this means concretely:

1. **Never redefine combinators.** `birds.nix` is the single canonical source for
   I, M, K, KI, B, L, W, S, Y. Every other file MUST import them:
   ```nix
   birds = import ./birds.nix {};
   inherit (birds) I M K KI B W S L Y;
   ```

2. **Use bird combinators over Nix builtins when semantically equivalent.**
   - Use `K` instead of writing `x: y: x` inline
   - Use `B` instead of manual function composition
   - Use `W` for self-application patterns
   - Use `S` for fork-join patterns
   - Use the `pipe` function from `bird-dsl.nix` for pipelines
   - Only fall back to builtins for irreducible primitives (string ops, arithmetic,
     type checks, regex) that have no combinator equivalent

3. **Use the test harness for all tests.** Never write ad-hoc test assertions.
   Import `test-harness.nix` and use `assertEq`, `assertTrue`, `runSuite`, etc.

4. **Use AST constructors from the compiler/formatter.** When building or
   manipulating bird expressions programmatically, use `mkBird`, `mkApp`,
   `mkVar`, `mkLambda` from `bird-compiler.nix` or `bird-format.nix`.

5. **Use the toolchain for end-to-end operations.** `bird-toolchain.nix` is the
   unified entry point — use `compileBird`, `ppBird`, `typeCheck` rather than
   calling compiler and formatter separately.

### Acceptable exceptions:

- `birds.nix` itself (it IS the canonical definitions)
- `bird-nix.nix` (tagged-union encoding is intentionally a different representation)
- `bird-compiler.nix` may define birds not in the core set (C, V) locally
- Nix builtins for string manipulation, arithmetic, list operations, and type
  introspection (these have no combinator equivalent)

## Architecture

```
blackhole/
  birds.nix              ← CANONICAL source for all combinators
  birds-speech.nix       ← Conversational wrappers (imports birds.nix)
  real-world-birds.nix   ← Practical examples (imports birds.nix)
  bird-dsl.nix           ← DSL with pipe operator and birdMap (imports birds.nix)
  bird-nix.nix           ← Tagged-union kernel (independent encoding)
  bird-compiler.nix      ← AST compiler with rewrite rules (imports birds.nix)
  bird-format.nix        ← Pretty-printer and eta-reducer (standalone AST ops)
  bird-toolchain.nix     ← Unified toolchain (imports birds.nix, compiler, format)
  test-harness.nix       ← Test framework built FROM birds (imports birds.nix)
  tests/
    test-birds.nix       ← Core combinator + DSL + speech tests
    test-compiler.nix    ← Compiler + formatter tests
    test-kernel.nix      ← Tagged kernel + toolchain + real-world tests
    run-all.nix          ← Aggregator: imports all test files
```

### Dependency DAG

```
birds.nix (root — no deps)
├── birds-speech.nix
├── real-world-birds.nix
├── bird-dsl.nix
├── bird-compiler.nix (+ local C, V)
├── bird-toolchain.nix → bird-compiler.nix, bird-format.nix
└── test-harness.nix
    └── tests/*.nix

bird-format.nix (standalone — AST ops only, no runtime combinators)
bird-nix.nix (standalone — tagged-union encoding)
```

## Conventions

### File structure

Every `.nix` file follows this pattern:
```nix
# Description comment
# Dogfoods birds.nix — explanation of what's imported
{ }:
let
  birds = import ./birds.nix {};
  inherit (birds) I K B ...;
  # ... definitions ...
in { ... }
```

### Testing

- Test files live in `blackhole/tests/`
- Every test file returns a `combineSuites` result
- Run all tests: `nix eval --impure --raw --expr '(import ./blackhole/tests/run-all.nix {}).summary'`
- Run one suite: `nix eval --impure --expr '(import ./blackhole/tests/test-birds.nix {}).summary'`
- All test files use `--impure` flag
- Test harness API:
  - `assertEq "name" actual expected` — equality check
  - `assertTrue "name" value` — boolean true check
  - `assertFalse "name" value` — boolean false check
  - `assertEval "name" expr` — evaluates without error
  - `assertThrows "name" expr` — evaluates WITH error
  - `runSuite "name" [ ...tests... ]` — collect test results
  - `combineSuites "name" [ ...suites... ]` — aggregate suites

### Naming

- Combinator names: single uppercase letters (I, K, B, S, W, M, Y, L)
- Multi-letter birds: KI (Kite), not K' (Nix doesn't allow primes in identifiers)
- AST node constructors: `mk` prefix (mkApp, mkBird, mkVar, mkLambda)
- Test suites: descriptive with bird name (e.g., "K — Kestrel")

### Adding new birds

1. Add the definition to `birds.nix` with a comment showing its rule
2. Add it to the `inherit` line in the `in { ... }` block
3. Add its type to `typeEnv` in `bird-compiler.nix` and `bird-toolchain.nix`
4. Add it to `birdMap` in `bird-dsl.nix`
5. Add a speech wrapper in `birds-speech.nix`
6. Write tests in `blackhole/tests/test-birds.nix`
7. Run the full test suite to verify

### Combinator laws to preserve

These identities MUST always hold (tested in the suite):
- `S K K = I` (starling-kestrel-kestrel = identity)
- `W K = I` (warbler-kestrel = identity)
- `M I = I` (mockingbird-identity = identity)
- `B f I = f` (right identity of composition)
- `B I f = f` (left identity of composition)
- `K x y = x` (kestrel always returns first)
- `KI x y = y` (kite always returns second)

## For AI Agents

When modifying this codebase:

1. **Read birds.nix first** to understand what's available
2. **Never copy-paste combinator definitions** — always import
3. **Run the test suite** after any change:
   `nix eval --impure --raw --expr '(import ./blackhole/tests/run-all.nix {}).summary'`
4. **If you add a function**, check if it can be expressed as a composition of
   existing birds (B, S, K, etc.) rather than writing a raw lambda
5. **If you find a file redefining combinators**, refactor it to import birds.nix
6. **All files must parse**: `nix-instantiate --parse-only blackhole/<file>.nix`
