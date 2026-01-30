# L-System (Procedural Generation)

L-System utilities and experiments in procedural generation context.

## QFEP Connection

L-Systems are **grammar-driven geometry**. An axiom and rules (F, formal system) rewrite to produce complex strings (E, emergent length). Turtle interpretation converts strings to form. λ as the iteration count — each step adds complexity.

## Core Concept

```
Axiom: F
Rule: F → F[+F]F[-F]
Gen 0: F
Gen 1: F[+F]F[-F]
Gen 2: F[+F]F[-F][+F[+F]F[-F]]F[+F]F[-F][-F[+F]F[-F]]
...
```

## See Also

- `lsystems/` — Main L-system implementations
- `lsystems/Architecture/` — Architectural L-systems
- `lsystems/Ecosystem/` — Competing L-systems
