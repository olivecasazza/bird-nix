# Bird-Nix Test Plan

## Overview
This test plan catalogs every function, combinator, and feature from the bird-nix Nix files that requires test coverage. Tests are grouped into: unit tests, property tests, integration tests, and regression tests.

---

## File: birds.nix — Core Combinators

### Exported Functions
| Function | Type Signature | Behavior | Edge Cases |
|----------|---------------|----------|------------|
| `I` | `a -> a` | Identity: returns input unchanged | `I` applied to functions, `I` applied to itself |
| `M` | `(a -> a) -> a` | Mockingbird: applies input to itself | `M` applied to `I`, `M` applied to `K` (diverges with `M M`) |
| `K` | `a -> b -> a` | Kestrel: returns first of two args | `K x` applied to anything, curried application |
| `KI` | `a -> b -> b` | Kite: returns second of two args | `KI x` applied to anything, curried application |
| `B` | `(b -> c) -> (a -> b) -> a -> c` | Bluebird: function composition | Chain of `B`s, `B` with identity functions |
| `L` | `a -> (b -> c) -> b -> a c` | Lark: applies second to first, then first to result | `L` with various combinations |
| `W` | `(a -> a -> b) -> a -> b` | Warbler: duplicates argument | `W K` (proves W K = I), `W` with binary functions |
| `S` | `(a -> b -> c) -> (a -> b) -> a -> c` | Starling: applies to both functions then combines | `S K K` (proves S K K = I), `S` with K |
| `Y` | `(a -> a) -> a` | Sage: fixed-point combinator | `Y` with constant function, `Y` with increment |

### Test Cases from File
- `testI`: `I "hello"` should equal `"hello"`
- `testK`: `K "true" "false"` should equal `"true"`
- `testKI`: `KI "true" "false"` should equal `"false"`
- `testB`: `B (x: x + 1) (x: x * 2) 5` should equal `11`
- `testW_K`: `W K "anything"` should equal `"anything"` (W K = I)
- `testS_KK`: `S K K "test"` should equal `"test"` (S K K = I)

### Unit Tests Required
1. **Identity**: Test `I` with strings, numbers, functions, lists, records
2. **Mockingbird**: Test `M I`, `M K`, verify divergence with `M M`
3. **Kestrel/Kite**: Test both with various types, test partial application
4. **Bluebird**: Test composition chains, test with arithmetic functions
5. **Lark**: Test `L K I`, `L I K`, verify behavior
6. **Warbler**: Test `W K x = x`, `W (x: y: x + y) 5 = 10`
7. **Starling**: Test `S K K = I`, `S K I`, `S I I`
8. **Sage**: Test `Y (f: x: f)`, `Y (x: x + 1)` (diverges)

### Property Tests
- `S K K = I` (starling-kestrel-kestrel equals identity)
- `W K = I` (warbler-kestrel equals identity)
- `B f I = f` (bluebird with identity)
- `M I = I` (mockingbird with identity)
- `K x y = x` for all x, y
- `KI x y = y` for all x, y

---

## File: birds-speech.nix — Speech-Style Combinators

### Exported Functions/Attributes
| Function/Attribute | Type | Behavior | Edge Cases |
|-------------------|------|----------|------------|
| `identityBird.speech` | String | "I hear you — and echo you back exactly." | - |
| `identityBird.call` | `call -> call` | Echoes input function | - |
| `mockingbird.speech` | String | "If you tell me how to respond..." | - |
| `mockingbird.call` | `call -> call call` | Applies input to itself | - |
| `kestrel.speech` | String | "I only hear the first caller..." | - |
| `kestrel.call` | `first: second: first` | Returns first argument | - |
| `kite.speech` | String | "Sorry, I didn't catch the first..." | - |
| `kite.call` | `first: second: second` | Returns second argument | - |
| `bluebird.speech` | String | "Tell me two birds..." | - |
| `bluebird.call` | `composer: performer: input: composer (performer input)` | Composes two birds | - |
| `lark.speech` | String | "Tell me how to react..." | - |
| `lark.call` | `observer: call: observer (call observer)` | Lark behavior | - |
| `warbler.speech` | String | "You want me to sing once?" | - |
| `warbler.call` | `performer: input: performer input input` | Duplicates argument | - |
| `starling.speech` | String | "I'll take your plan..." | - |
| `starling.call` | `planA: planB: input: planA input (planB input)` | Applies to both | - |
| `sageBird.speech` | String | "I make it possible to repeat..." | - |
| `sageBird.call` | `f: let x = f x; in x` | Fixed-point combinator | - |
| `sentences.identityEcho` | { description, result } | Test case: identity echo | - |
| `sentences.mockingIdentity` | { description, result } | Test case: mockingbird hears identity | - |
| `sentences.kestrelChoice` | { description, result } | Test case: kestrel picks first | - |
| `sentences.kiteChoice` | { description, result } | Test case: kite picks second | - |
| `sentences.bluebirdDemo` | { description, result } | Test case: compose inc and double | - |
| `sentences.warblerDemo` | { description, result } | Test case: warbler with kestrel | - |
| `sentences.starlingDemo` | { description, result } | Test case: S K K = I proof | - |

### Unit Tests Required
1. Test each bird's `speech` attribute returns expected string
2. Test each bird's `call` function with various inputs
3. Test `identityBird.call inc 5` = 6
4. Test `mockingbird.call identityBird.call` behavior
5. Test `kestrel.call "a" "b"` = "a"
6. Test `kite.call "a" "b"` = "b"
7. Test `bluebird.call inc double 3` = 7
8. Test `warbler.call kestrel.call "A"` = "A"
9. Test `starling.call kestrel.call kestrel.call 42` = 42

### Property Tests
- `identityBird.call = I`
- `mockingbird.call = M`
- `kestrel.call = K`
- `kite.call = KI`
- `bluebird.call = B`
- `lark.call = L`
- `warbler.call = W`
- `starling.call = S`
- `sageBird.call = Y`

---

## File: real-world-birds.nix — Practical Examples

### Exported Functions
| Function | Type | Behavior | Edge Cases |
|----------|------|----------|------------|
| `const` | `K` | Alias for Kestrel | - |
| `ifThenElse` | `Bool -> a -> a -> a` | Conditional selection | - |
| `env` | String | "production" | - |
| `configProduction` | Record | `{ port = 80; debug = false; }` | - |
| `configDevelopment` | Record | `{ port = 3000; debug = true; }` | - |
| `selectedConfig` | Record | Conditional config selection | - |
| `trim` | `String -> String` | Removes spaces | Empty string |
| `toLower` | `String -> String` | Converts to lowercase | Non-alphabetic chars |
| `isValidEmail` | `String -> Bool` | Regex email validation | Edge cases in email format |
| `validateEmail` | `String -> Bool` | Composed email validation | - |
| `isPalindrome` | `String -> Bool` | Self-comparison (always true per comment) | - |
| `hasMinLength` | `Int -> String -> Bool` | Length check | Negative len, empty string |
| `selfAware` | `String -> Record` | Self-describing config | - |
| `cons` | `a -> b -> Record` | Cons cell constructor | - |
| `repeatHi` | Lazy infinite structure | Y combinator application | - |

### Unit Tests Required
1. Test `ifThenElse true x y` = x, `ifThenElse false x y` = y
2. Test `trim " hello "` = "hello"
3. Test `toLower "HELLO"` = "hello"
4. Test `isValidEmail` with valid/invalid emails
5. Test `validateEmail` composed pipeline
6. Test `hasMinLength 5 "hello"` = true
7. Test `hasMinLength 10 "hi"` = false
8. Test `selfAware "test"` = `{ name = "test"; description = "I am test"; }`
9. Test `cons 1 (cons 2 null)` structure
10. Test `repeatHi` produces infinite lazy structure

### Integration Tests
1. Full email validation pipeline: `validateEmail "  TEST@EXAMPLE.COM  "`
2. Config selection based on environment
3. Chained composition with B combinator

---

## File: bird-dsl.nix — DSL with Pipe Operator

### Exported Functions
| Function | Type | Behavior | Edge Cases |
|----------|------|----------|------------|
| `birdMap` | `{"I" = I; ... "Y" = Y;}` | Maps string names to combinators | Missing keys |
| `say` | `bird -> input -> bird input` | Applies bird to input | Unknown birds |
| `pipe` | `x -> [functions] -> result` | Left fold application | Empty list, single function |
| `examples.identityPipe` | `pipe "hello" [I]` | Identity pipeline | - |
| `examples.composePipe` | `pipe 5 [(x: x*2) (x: x+1)]` | Function composition | - |
| `examples.trimLowerValidate` | Pipeline example | String processing | - |

### Unit Tests Required
1. Test `birdMap."I"` = I combinator
2. Test `birdMap."K"` = K combinator
3. Test `birdMap."S"` = S combinator
4. Test all 9 bird names map correctly
5. Test `say I "test"` = "test"
6. Test `say K "a" "b"` = "a"
7. Test `pipe "x" []` = "x" (empty list)
8. Test `pipe 5 [I]` = 5
9. Test `pipe 5 [(x: x*2)]` = 10
10. Test `pipe 5 [(x: x*2) (x: x+1)]` = 11 (left-to-right)

### Property Tests
- `pipe x [I]` = x
- `pipe x [f]` = f x
- `pipe x [f, g]` = g (f x)
- `pipe x functions` = foldl (flip apply) x functions

---

## File: bird-nix.nix — Tagged Union Kernel

### Exported Functions
| Function | Type | Behavior | Edge Cases |
|----------|------|----------|------------|
| `I` | `{ bird = "I"; apply = x: x; }` | Tagged identity | - |
| `M` | `{ bird = "M"; apply = x: x.apply x; }` | Tagged mockingbird | Diverges with M M |
| `K` | `{ bird = "K"; apply = x: { bird = "K1"; apply = y: x; }; }` | Tagged kestrel | Curried application |
| `KI` | `{ bird = "KI"; apply = x: { bird = "KI1"; apply = y: y; }; }` | Tagged kite | - |
| `B` | Tagged bluebird with nested records | - | - |
| `W` | Tagged warbler | - | - |
| `S` | Tagged starling | - | - |
| `L` | Tagged lark | - | - |
| `Y` | Tagged sage | - | - |
| `apply` | `bird -> arg -> bird.apply arg` | Applies tagged bird | - |
| `show` | `bird -> String` | Returns bird name | Non-tagged inputs |
| `pipe` | `x -> [functions] -> result` | Pipe using apply | - |
| `cons` | `head -> tail -> { h = head; t = tail; }` | Cons cell | - |
| `examples.identity` | `apply I "hello"` | - | - |
| `examples.mockingIdentity` | `apply M I` | - | - |
| `examples.kestrelChoice` | `apply (apply K "yes") "no"` | - | - |
| `examples.starlingIdentity` | `apply (apply (apply S K) K) "test"` | - | - |
| `examples.repeatHi` | `apply Y { bird = "repeat"; apply = f: cons "hi" f; }` | - | - |

### Unit Tests Required
1. Test `apply I "test"` = "test"
2. Test `apply M I` = `I I`
3. Test `apply (apply K "a") "b"` = "a"
4. Test `show I` = "I"
5. Test `show { bird = "K"; ... }` = "K"
6. Test `show "not-a-bird"` = "not-a-bird"
7. Test `pipe x []` = x
8. Test `pipe x [I, I]` = x
9. Test `cons 1 (cons 2 null)` structure
10. Test `examples.starlingIdentity` = "test"

---

## File: bird-compiler.nix — AST Compiler

### Exported Functions
| Function | Type | Behavior | Edge Cases |
|----------|------|----------|------------|
| `mkApp` | `fn -> arg -> { op = "App"; fn; arg; }` | AST constructor | - |
| `mkVar` | `name -> { op = "Var"; name; }` | Variable AST node | - |
| `mkBird` | `name -> { op = "Bird"; name; }` | Bird AST node | - |
| `mkLambda` | `param -> body -> { op = "Lambda"; param; body; }` | Lambda AST node | - |
| `I, K, S, B, C, W, M, Y, L, V` | Combinator functions | Core combinators | - |
| `typeEnv` | `{ I = "a -> a"; ... }` | Type environment | - |
| `isBird` | `name -> ast -> Bool` | Pattern match helper | - |
| `isApp` | `fnCond -> argCond -> ast -> Bool` | App pattern match | - |
| `rewrite` | `ast -> ast` | Rewrite rules simplifier | Infinite loops? |
| `compile` | `ast -> function` | Compile AST to Nix function | - |
| `inferType` | `ast -> String` | Simple type inference | - |
| `examples.sKK_*` | Various | S K K = I test cases | - |
| `examples.mI_*` | Various | M I = I test cases | - |
| `examples.kxy_*` | Various | K x y = x test cases | - |
| `examples.wK_*` | Various | W K = I test cases | - |

### Rewrite Rules (test each)
1. `S K K` -> `I`
2. `W K` -> `I`
3. `K x y` -> `x` (when both args applied)
4. `M I` -> `I`
5. `B f I` -> `f`

### Unit Tests Required
1. Test `mkApp`, `mkVar`, `mkBird`, `mkLambda` produce correct AST
2. Test `compile (mkBird "I")` = I combinator
3. Test `compile (mkBird "K")` = K combinator
4. Test `compile (mkApp (mkBird "S") (mkBird "K"))` = S K
5. Test `compile (mkApp (mkApp (mkBird "S") (mkBird "K")) (mkBird "K"))` = I
6. Test `rewrite` applies all 5 rules correctly
7. Test `inferType (mkBird "I")` = "a -> a"
8. Test `inferType (mkBird "K")` = "a -> b -> a"
9. Test `inferType (mkApp ...)` = "applied"
10. Test `compile` throws on free variables

### Property Tests
- `compile (rewrite ast)` = `compile ast` for all ast
- `compile (mkApp (mkApp (mkBird "S") (mkBird "K")) (mkBird "K"))` = I
- `compile (mkApp (mkBird "W") (mkBird "K"))` = I
- `compile (mkApp (mkApp (mkBird "K") x) y)` = K x y = x

---

## File: bird-format.nix — Pretty Printer

### Exported Functions
| Function | Type | Behavior | Edge Cases |
|----------|------|----------|------------|
| `mkApp, mkVar, mkBird, mkLambda` | AST constructors | - | - |
| `pp` | `ast -> String` | Pretty-printer | Complex nesting |
| `freeVars` | `ast -> [String]` | Free variable finder | Lambda shadows |
| `etaReduce` | `ast -> ast` | Eta-reduction | Non-reducible cases |
| `examples.ppSKK` | `pp (S K K)` | Should be "S K K" | - |
| `examples.etaFx` | `pp (etaReduce (lambda x. f x))` | Should be "f" | - |
| `examples.etaId` | `pp (etaReduce (lambda x. x))` | Should be "I" | - |

### Unit Tests Required
1. Test `pp (mkBird "I")` = "I"
2. Test `pp (mkVar "x")` = "x"
3. Test `pp (mkApp (mkBird "S") (mkBird "K"))` = "S K"
4. Test `pp (mkApp (mkApp (mkBird "S") (mkBird "K")) (mkBird "K"))` = "S K K"
5. Test `pp (mkLambda "x" (mkVar "x"))` = "(lambda x. x)"
6. Test `freeVars (mkVar "x")` = ["x"]
7. Test `freeVars (mkLambda "x" (mkVar "x"))` = []
8. Test `freeVars (mkLambda "x" (mkVar "y"))` = ["y"]
9. Test `etaReduce (lambda x. f x)` = f (if x not free in f)
10. Test `etaReduce (lambda x. x)` = I

### Property Tests
- `pp (etaReduce ast)` reduces eta-redexes
- `etaReduce (lambda x. x)` = I
- `etaReduce (lambda x. f x)` = f when x not free in f

---

## File: bird-toolchain.nix — Unified Toolchain

### Exported Functions
| Function | Type | Behavior | Edge Cases |
|----------|------|----------|------------|
| `compiler` | Module | bird-compiler.nix | - |
| `format` | Module | bird-format.nix | - |
| `I, M, K, KI, B, W, S, L, Y` | Combinators | Re-exported | - |
| `typeEnv` | Type environment | Type signatures | - |
| `typeCheck` | `birdName -> { ok, type, errors }` | Type checking | Unknown birds |
| `compileBird` | `ast -> function` | Compile + rewrite + compile | - |
| `ppBird` | `ast -> String` | Pretty-print | - |
| `demos.sKK` | Full demo | S K K = I | - |
| `demos.mI` | Full demo | M I = I | - |
| `demos.typeChecks` | Type check examples | - | - |
| `configExample` | Config demo | NixOS-style example | - |

### Unit Tests Required
1. Test `typeCheck "I"` = `{ ok = true; type = "a -> a"; errors = []; }`
2. Test `typeCheck "Z"` = `{ ok = false; type = null; errors = ["Unknown bird: Z"]; }`
3. Test `compileBird` with S K K AST
4. Test `compileBird` with W K AST
5. Test `ppBird` with various ASTs
6. Test `configExample.serverName` = "example.com"
7. Test `configExample.port` = 8080
8. Test `configExample.selfRef` = "nginx"

### Integration Tests
1. Full pipeline: AST -> rewrite -> compile -> run
2. Full pipeline: AST -> rewrite -> pretty-print
3. Type check -> compile -> run

---

## Comprehensive Test Categories

### Unit Tests (Individual Combinators)
- Test each combinator in birds.nix with basic inputs
- Test each speech bird's call function
- Test each real-world example function
- Test AST construction functions
- Test pretty-printer with simple ASTs
- Test type checker with known birds

### Property Tests (Combinator Laws)
- `S K K = I`
- `W K = I`
- `M I = I`
- `B f I = f`
- `K x y = x`
- `KI x y = y`
- `L x y = x (y x)`
- `Y f = f (Y f)` (conceptually)

### Integration Tests (Compiler Pipeline)
1. Build AST from string representation
2. Apply rewrite rules
3. Compile to Nix function
4. Execute with test inputs
5. Compare output to expected

### Regression Tests
- S K K = I (identity proof)
- W K = I (identity proof)
- M I = I (identity proof)
- Full demo in bird-toolchain.nix

### Edge Cases to Test
- Divergence: `M M`, `Y (x: x + 1)`
- Empty inputs: `pipe x []`
- Partial application: `K x`, `B f g`
- Type mismatches: compile invalid ASTs
- Non-reducible eta: `lambda x. f (g x)`

---

## Test Execution Strategy

1. **Unit tests**: Run individually for each combinator
2. **Property tests**: Use property-based testing if available
3. **Integration tests**: Run full pipeline end-to-end
4. **Regression tests**: Run as part of CI to catch breaking changes

## Expected Test Framework
- Nix's `test` function or external test framework
- Each test should verify expected output or property
- Tests should document expected behavior in comments
