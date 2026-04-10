# Bird-Nix VS Code Extension

A VS Code extension for the **Bird-Nix** language - a DSL for combinatory logic in Nix.

## Features

- Syntax highlighting for bird combinators (I, M, K, KI, B, W, S, L, Y)
- Code snippets for common bird patterns
- Hover documentation showing bird signatures and descriptions
- Support for `.bird.nix` file extension

## Bird Combinators

| Bird | Symbol | Description |
|------|--------|-------------|
| Identity | `I` | Returns argument unchanged |
| Mockingbird | `M` | Self-application: `M x = x x` |
| Kestrel | `K` | Returns first argument: `K x y = x` |
| Kite | `KI` | Returns second argument: `KI x y = y` |
| Bluebird | `B` | Function composition: `B f g x = f (g x)` |
| Warbler | `W` | Duplicates argument: `W f x = f x x` |
| Starling | `S` | Distributes application: `S f g x = f x (g x)` |
| Lark | `L` | Self-application helper: `L x y = x (y x)` |
| Sage Bird | `Y` | Fixed-point combinator for recursion |

## Snippets

Type `bird-` to see all available snippets:
- `bird-I`, `bird-M`, `bird-K`, etc. for individual birds
- `bird-all` for all combinators at once
- `skk` for `S K K = I`
- `bird-pipe` for pipeline syntax

## Installation

1. Build the extension: `npm install && npm run compile`
2. Install in VS Code: `ext install bird-nix.vsix`

## License

MIT
