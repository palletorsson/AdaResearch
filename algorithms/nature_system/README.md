# Nature System

Procedural life. DNA-driven organisms that grow, breed, evolve, and transform.

## QFEP Connection

The Nature System is the project's deepest embodiment of QFEP. Every organism is defined by a continuous genome where `body_type` is a float, not an enum — a value of 1.7 is a creature-flower hybrid, boundaries are soft, and categories are suggestions. This is Donna Haraway's critter discourse made procedural: nothing is purely one thing. Evolution minimizes free energy (**F**) through fitness selection, but mutation and cross-kingdom breeding inject entropy (**E**), and the player's bond with a critter — the transmutation mechanic — is the phase transition itself.

## Contents

### DNA

The genome shared by all five kingdoms (Tree, Creature, Flower, Fungus, Hybrid). Every gene is a typed export — directly visible in the Godot inspector, serializable, and participating in crossover/mutation without encoding.

| File | Description |
|------|-------------|
| `dna/critter_dna.gd` | CritterDNA Resource — phenotype, morphology, behavior, metabolism, ecology, and lineage genes. Includes crossover, mutation, random generation, and genetic distance. |
| `dna/critter_trait_mapper.gd` | Bridge between CritterDNA and shader materials. Maps genes to shader parameters with per-instance variation, bond overlays, and kingdom-specific animation. |

### Morphology (Body Builders)

Each kingdom has a dedicated mesh generator that reads CritterDNA and produces procedural geometry with LOD support. All follow the same static-method architecture.

| File | Description |
|------|-------------|
| `morphology/creature_morphology.gd` | Segmented body spine with bilateral limbs, head (eyes, antennae/horns), and tail. Limb type interpolates between legs, tentacles, and fins based on mobility gene. |
| `morphology/flower_morphology.gd` | Concentric petal rings with per-petal Bezier curves, stamen cluster, stem, and inflorescence. Uses MultiMeshInstance3D for efficient petal rendering. |
| `morphology/tree_morphology.gd` | L-system branching with 3D turtle interpretation. Segments, branch angle, decay, leaf density, and phyllotaxis all driven by DNA. Leaves batched into MultiMesh. |
| `morphology/fungus_morphology.gd` | Mushroom forms: cap + stem + gills/pores + spore clusters. Supports bracket fungi, fairy rings, bioluminescence, and colony clustering. |

### Entities

| File | Description |
|------|-------------|
| `entities/critter_entity.gd` | Base class for every living thing. Owns a CritterDNA, manages mesh collection, material application, bond/transmutation visuals, energy/metabolism, aging, and sexual/asexual reproduction. |

### Systems

| File | Description |
|------|-------------|
| `systems/morphology_router.gd` | Routes `body_type` float to the correct kingdom builder. Handles hybrid decorations when body_type falls between kingdoms. |
| `systems/spawner.gd` | Instantiation pipeline: DNA to realized entity with LOD, population caps, batch seeding, and spatial queries. |
| `systems/evolution_system.gd` | Generational cycles: fitness evaluation, tournament selection, crossover reproduction, culling, and emergency asexual rescue. Pluggable fitness function. |
| `systems/transmutation_manager.gd` | Player-critter bond tracking. Interaction types (observe, feed, touch, survive, fight) modulate trust. At threshold, the critter's latent ability unlocks — 6 categories x 4 kingdoms = 24 unique abilities. Includes kingdom-specific rituals. |

### Shaders

| File | Description |
|------|-------------|
| `shaders/critter_dna.gdshader` | Shared shader for all kingdoms. Reads DNA-derived parameters: colors, 20-type pattern interpolation, surface quality, wave animation, and effect flags. |

### Demo

| File | Description |
|------|-------------|
| `demo/nature_system_demo.gd` | Visual test scene. Spawns a grid of all 4 kingdoms, supports keyboard interaction (spawn, randomize, evolve, cycle LOD, toggle hybrids). |
| `demo/nature_system_demo.tscn` | Scene file for the demo. |

## Key Concepts

1. **Continuous genome** — All genes are floats or colors. No enums, no hard boundaries. `body_type = 1.7` is valid.
2. **Five kingdoms** — Tree (0), Creature (1), Flower (2), Fungus (3), Hybrid (4). Each has distinct morphology but shares the same DNA.
3. **Crossover + mutation** — Sexual reproduction blends parent genes with random inheritance (A, B, or blend). Mutation nudges values within their export ranges.
4. **Genetic distance** — Normalized 0-1 measure of how different two DNAs are. Used for speciation and diversity tracking.
5. **LOD system** — Four detail levels (0=highest, 3=lowest). Morphology builders adjust segment counts, radial resolution, and limb caps per LOD.
6. **Transmutation** — Player bonds with critters through interaction. At high bond, the critter's `latent_ability` gene unlocks one of 24 unique abilities.
7. **Rituals** — Kingdom-specific interaction sequences (e.g., rest under a tree, survive then observe a creature) that accelerate bonding.
8. **Hybrid decorations** — When `body_type` is fractional (hybridity > 0.35), secondary-kingdom visual markers (branch stubs, eye spots, petal buds, fungal caps) appear on the primary body.

## Architecture

```
CritterDNA (Resource)
    |
    +-- MorphologyRouter.build(dna, parent, mapper, lod)
    |       |
    |       +-- TreeMorphology.build()      (body_type ~ 0)
    |       +-- CreatureMorphology.build()   (body_type ~ 1)
    |       +-- FlowerMorphology.build()     (body_type ~ 2)
    |       +-- FungusMorphology.build()     (body_type ~ 3)
    |       +-- Hybrid decorations           (fractional body_type)
    |
    +-- CritterTraitMapper.apply_dna(material, dna)
    |       |
    |       +-- critter_dna.gdshader
    |
    +-- CritterEntity (Node3D)
    |       |
    |       +-- Bond / Transmutation visuals
    |       +-- Energy / Metabolism
    |       +-- Reproduction (sexual + asexual)
    |
    +-- CritterSpawner          (instantiation + LOD management)
    +-- EvolutionSystem          (selection + reproduction + culling)
    +-- TransmutationManager     (player bond + ability granting)
```

## VR Experience

- Watch procedural organisms grow from DNA
- Interact to build trust (observe, feed, touch)
- Witness evolution across generations
- Unlock abilities through transmutation bonds
- See hybrid forms emerge from cross-kingdom breeding

## Files

- 12 GDScript files
- 1 shader file
- 1 scene file
