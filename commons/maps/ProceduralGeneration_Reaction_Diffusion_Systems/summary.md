# Reaction-Diffusion — Summary

## What You'll Learn

Reaction-diffusion systems demonstrate **morphogenesis** — how patterns emerge from homogeneous initial conditions through local chemical interactions.

## Turing's Insight (1952)

Alan Turing showed that two chemicals (morphogens) can create stable patterns if:
1. Both diffuse through space
2. One activates, one inhibits
3. The inhibitor diffuses faster than the activator

This creates **local activation + long-range inhibition** — the recipe for emergence.

## The Gray-Scott Model

A popular reaction-diffusion system:
- **U** = substrate chemical (starts full)
- **V** = catalyst chemical (starts sparse)
- **F** = feed rate (how fast U is replenished)
- **k** = kill rate (how fast V dies)

Different F and k values produce different patterns:
- **Spots** — low F, moderate k
- **Stripes** — moderate F and k
- **Coral** — high F, moderate k
- **Mitosis** — cells that divide
- **Worms** — moving patterns

## QFEP Connection

Reaction-diffusion IS the morphogenesis term of QFEP:
- Diffusion = **E(S)** (entropy-increasing, homogenizing)
- Reaction = **F** (local structure-building)
- When balanced = **λ ≈ 0.4** (edge of chaos)

The **λ slider** in QFEP maps directly to the feed/kill ratio. Move it, and patterns transform.

## Applications

- Animal coat patterns (zebra, leopard, fish)
- Shell pigmentation
- Fingerprint formation
- Vegetation patterns in arid regions
- Procedural textures

## Key Insight

**You don't need a blueprint.** Complex patterns emerge from simple rules + diffusion. This is computation at the chemical level, long before brains.
