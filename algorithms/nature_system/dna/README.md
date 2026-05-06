# Critter DNA

A genetic system for the Nature System that teaches **genetics, crossover, mutation, and phenotype expression**. Every living creature in the ecosystem carries a `CritterDNA` resource whose genes are continuous floats -- not discrete enums -- reflecting Donna Haraway's idea that biological boundaries are soft and identity is fluid. A companion `CritterTraitMapper` bridges the genome to GPU shaders so that genes directly control how a creature looks and moves.

## How It Works

### CritterDNA (the genome)

`CritterDNA` is a Godot `Resource` with dozens of `@export` fields organized into domains:

- **Phenotype** -- primary, secondary, and tertiary colors.
- **Morphology** -- `body_type` (a continuous 0--4 float spanning tree, creature, flower, fungus, hybrid), segment count, radial symmetry, scale, and pattern parameters.
- **Material** -- roughness, metallic, iridescence, transparency, cracking (age / metamorphosis).
- **Behavior** -- mobility, aggression, sociality, curiosity.
- **Metabolism** -- energy source, efficiency, growth speed, fertility.
- **Kingdom-specific** -- branch angle, branch decay, leaf density, interpreted differently per body type.
- **Geometry detail** -- part length, width, curve, taper, twist, tilt for petals / branches / limbs.
- **Ecology** -- scent strength, nectar quality.
- **Potential** -- affinity (bond ease), volatility, latent ability (transmutation).
- **Lineage** -- generation counter, parent IDs, mutation log.

Static methods provide the genetic operators:

| Method | Purpose |
|--------|---------|
| `crossover(a, b)` | Produces a child. Each gene is randomly inherited from A, B, or blended. |
| `mutate(dna, rate, strength)` | In-place perturbation. Floats are nudged within their `@export_range`; colors shift per channel. |
| `random(seed)` | Fully random DNA respecting all range constraints. |
| `random_kingdom(k, seed)` | Random DNA biased toward a specific kingdom (tree, creature, flower, fungus, hybrid). |
| `distance(a, b)` | Normalized 0--1 genetic distance for speciation checks. |

### CritterTraitMapper (genome to shader)

`CritterTraitMapper` takes a `CritterDNA` and writes its genes as shader parameters on a `ShaderMaterial`:

1. **Colors** -- primary, secondary, tertiary mapped directly; near-black values are replaced with seeded randoms.
2. **Pattern** -- pattern type, density, scale, and a per-instance random rotation.
3. **Surface** -- roughness, metallic, iridescence, transparency, cracking.
4. **Animation** -- kingdom-dependent wave intensity, amplitude, frequency, and speed (trees sway gently, creatures undulate, flowers bob, fungi pulse).
5. **Effects** -- edge detection, cellular influence, darkness, and color mixing packed into a `Vector4`.

Additional methods:

- `apply_bond_overlay()` -- Ramps emission, rim light, cracking, and iridescence as bond level approaches transmutation.
- `apply_variation()` -- Per-instance color drift and pattern rotation for visual uniqueness within a population.

## Parameters

All parameters are the `@export` fields on `CritterDNA`. Key ranges include:

| Gene | Range | Domain |
|------|-------|--------|
| `body_type` | 0.0 -- 4.0 | Morphology |
| `segments` | 2.0 -- 12.0 | Morphology |
| `symmetry` | 1.0 -- 8.0 | Morphology |
| `mobility` | 0.0 -- 1.0 | Behavior |
| `aggression` | 0.0 -- 1.0 | Behavior |
| `roughness` | 0.05 -- 1.0 | Material |
| `iridescence` | 0.0 -- 1.0 | Material |
| `branch_angle` | 15.0 -- 90.0 | Kingdom |
| `affinity` | 0.0 -- 1.0 | Potential |

See the full export list in `critter_dna.gd` for all 40+ genes.

## Features

- Continuous body type -- a value of 1.7 is a creature-flower hybrid; boundaries are intentionally soft.
- Full genetic algebra: crossover, mutation, random generation, kingdom-biased generation, and genetic distance.
- Automatic `@export_range` introspection for mutation bounds -- no hard-coded limits.
- Direct shader parameter mapping with kingdom-aware animation interpretation.
- Bond overlay system for transmutation visuals (cracking, iridescence ramp, emission glow).
- Per-instance variation for natural-looking populations.
- Serializable as `.tres` for save / load of creature lineages.

## Files

| File | Purpose |
|------|---------|
| `critter_dna.gd` | `CritterDNA` Resource -- genome definition, crossover, mutation, random generation |
| `critter_trait_mapper.gd` | `CritterTraitMapper` -- maps DNA genes to shader material parameters |
