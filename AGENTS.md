# AGENTS.md — bird-nix project instructions for AI coding agents

## Project Overview

bird-nix is a combinator library implementing the birds from Raymond Smullyan's
"To Mock a Mockingbird" as pure Nix expressions. It provides combinators (I, M, K,
KI, B, C, L, W, S, V, Y), a DSL, a compiler, a pretty-printer, a property-based
testing framework, and a self-bootstrapping test harness — all in pure Nix.

It is packaged as a Nix flake that other flakes can import and use.

## The Dogfooding Rule (MANDATORY)

**Every component of this library MUST use its own tools whenever possible.**

This is the single most important directive. Before writing any new code, ask:
"Can I import and use an existing bird-nix module instead of reimplementing?"

### What this means concretely:

1. **Never redefine combinators.** `birds.nix` is the single canonical source for
   I, M, K, KI, B, C, L, W, S, V, Y. Every other file MUST import them:
   ```nix
   birds = import ./birds.nix {};
   inherit (birds) I M K KI B C W S L V Y;
   ```

2. **Use bird combinators over Nix builtins when semantically equivalent.**
   - Use `K` instead of writing `x: y: x` inline
   - Use `B` instead of manual function composition
   - Use `W` for self-application patterns
   - Use `S` for fork-join patterns
   - Use `C` for argument flipping
   - Use `V` for pair construction
   - Use the `pipe` function from `bird-dsl.nix` for pipelines
   - Only fall back to builtins for irreducible primitives (string ops, arithmetic,
     type checks, regex) that have no combinator equivalent

3. **Use the test harness for all tests.** Never write ad-hoc test assertions.
   Import `test-harness.nix` and use `assertEq`, `assertTrue`, `runSuite`, etc.

4. **Use property-based tests for algebraic laws.** Import `bird-pbt.nix` and use
   `forAll`, `forAll2`, `property` to verify combinator identities hold across
   many inputs rather than just individual examples.

5. **Use AST constructors from the compiler/formatter.** When building or
   manipulating bird expressions programmatically, use `mkBird`, `mkApp`,
   `mkVar`, `mkLambda` from `bird-compiler.nix` or `bird-format.nix`.

6. **Use the toolchain for end-to-end operations.** `bird-toolchain.nix` is the
   unified entry point — use `compileBird`, `ppBird`, `typeCheck` rather than
   calling compiler and formatter separately.

### Acceptable exceptions:

- `birds.nix` itself (it IS the canonical definitions)
- `bird-nix.nix` (tagged-union encoding is intentionally a different representation)
- Nix builtins for string manipulation, arithmetic, list operations, and type
  introspection (these have no combinator equivalent)

## Architecture

```
flake.nix                ← Flake entry point (lib, tests, checks)
src/
  default.nix            ← Unified library entry point
  birds.nix              ← CANONICAL source for all combinators
  birds-speech.nix       ← Conversational wrappers (imports birds.nix)
  real-world-birds.nix   ← Practical examples (imports birds.nix)
  bird-dsl.nix           ← DSL with pipe operator and birdMap (imports birds.nix)
  bird-nix.nix           ← Tagged-union kernel (independent encoding)
  bird-compiler.nix      ← AST compiler with rewrite rules (imports birds.nix)
  bird-format.nix        ← Pretty-printer and eta-reducer (standalone AST ops)
  bird-toolchain.nix     ← Unified toolchain (imports birds.nix, compiler, format)
  bird-pbt.nix           ← Property-based testing framework (imports birds.nix)
  test-harness.nix       ← Test framework built FROM birds (imports birds.nix)
tests/
  test-birds.nix         ← Core combinator + DSL + speech tests
  test-compiler.nix      ← Compiler + formatter tests
  test-kernel.nix        ← Tagged kernel + toolchain + real-world tests
  test-pbt.nix           ← Property-based tests for algebraic laws
  run-all.nix            ← Aggregator: imports all test files
```

### Dependency DAG

```
birds.nix (root — no deps)
├── birds-speech.nix
├── real-world-birds.nix
├── bird-dsl.nix
├── bird-compiler.nix
├── bird-pbt.nix
├── bird-toolchain.nix → bird-compiler.nix, bird-format.nix
└── test-harness.nix
    └── tests/*.nix

bird-format.nix (standalone — AST ops only, no runtime combinators)
bird-nix.nix (standalone — tagged-union encoding)
```

### Flake Interface

```nix
# In another flake:
{
  inputs.bird-nix.url = "github:olivecasazza/bird-nix";

  outputs = { bird-nix, ... }:
  let
    bn = bird-nix.lib {};
  in {
    # Use combinators directly
    example = bn.I "hello";           # → "hello"
    example2 = bn.K "yes" "no";      # → "yes"
    example3 = bn.S bn.K bn.K 42;    # → 42

    # Use the compiler
    compiled = bn.compile (bn.mkBird "I");

    # Use the pipe DSL
    piped = bn.pipe 5 [(x: x * 2) (x: x + 1)];  # → 11

    # Use PBT in your own tests
    myProp = bn.property "addition commutes"
      (bn.forAll bn.domains.ints (x: x + 0 == 0 + x));
  };
}
```

## Conventions

### File structure

Every `.nix` file in `src/` follows this pattern:
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

- Test files live in `tests/`
- Every test file returns a `combineSuites` result
- Run all tests: `nix eval .#tests.summary --impure --raw`
- Run one suite: `nix eval --impure --raw --expr '(import ./tests/test-birds.nix {}).summary'`
- All test files use `--impure` flag
- Test harness API:
  - `assertEq "name" actual expected` — equality check
  - `assertTrue "name" value` — boolean true check
  - `assertFalse "name" value` — boolean false check
  - `assertEval "name" expr` — evaluates without error
  - `assertThrows "name" expr` — evaluates WITH error
  - `runSuite "name" [ ...tests... ]` — collect test results
  - `combineSuites "name" [ ...suites... ]` — aggregate suites
- PBT API (from `bird-pbt.nix`):
  - `forAll domain (x: <bool>)` — test property over all domain values
  - `forAll2 domA domB (x: y: <bool>)` — binary quantifier
  - `forAll3 domA domB domC (x: y: z: <bool>)` — ternary quantifier
  - `property "name" (forAll ...)` — named property with pass/fail/counterexample
  - `toHarnessSuite "name" [props]` — integrate PBT into combineSuites

### Naming

- Combinator names: single uppercase letters (I, K, B, S, W, M, Y, L, C, V)
- Multi-letter birds: KI (Kite), not K' (Nix doesn't allow primes in identifiers)
- AST node constructors: `mk` prefix (mkApp, mkBird, mkVar, mkLambda)
- Test suites: descriptive with bird name (e.g., "K — Kestrel")

### Adding new birds

1. Add the definition to `src/birds.nix` with a comment showing its rule
2. Add it to the `inherit` line in the `in { ... }` block
3. Add its type to `typeEnv` in `src/bird-compiler.nix` and `src/bird-toolchain.nix`
4. Add it to `birdMap` in `src/bird-dsl.nix`
5. Add a speech wrapper in `src/birds-speech.nix`
6. Add tagged-union version in `src/bird-nix.nix` (use `apply` helper for multi-arg)
7. Add to `src/default.nix` inherit if it's a core combinator
8. Write unit tests in `tests/test-birds.nix`
9. Write property-based tests in `tests/test-pbt.nix`
10. Run the full test suite: `nix eval .#tests.summary --impure --raw`

### Combinator laws to preserve

These identities MUST always hold (tested in both unit and PBT suites):
- `S K K = I` (starling-kestrel-kestrel = identity)
- `W K = I` (warbler-kestrel = identity)
- `M I = I` (mockingbird-identity = identity)
- `B f I = f` (right identity of composition)
- `B I f = f` (left identity of composition)
- `K x y = x` (kestrel always returns first)
- `KI x y = y` (kite always returns second)
- `C K = KI` (cardinal-kestrel = kite)
- `V x y K = x` (vireo pair with kestrel selects first)
- `V x y KI = y` (vireo pair with kite selects second)

## For AI Agents

When modifying this codebase:

1. **Read `src/birds.nix` first** to understand what's available
2. **Never copy-paste combinator definitions** — always import
3. **Run the test suite** after any change:
   `nix eval .#tests.summary --impure --raw`
4. **If you add a function**, check if it can be expressed as a composition of
   existing birds (B, S, K, C, etc.) rather than writing a raw lambda
5. **If you find a file redefining combinators**, refactor it to import birds.nix
6. **All files must parse**: `nix-instantiate --parse-only src/<file>.nix`
7. **For tagged-union birds in bird-nix.nix**: when a bird's `.apply` returns
   another tagged union, use the `apply` helper for the next step:
   `apply (f.apply y) x` NOT `f.apply y x`
