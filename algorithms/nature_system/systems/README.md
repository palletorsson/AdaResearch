# Nature System — Systems

Runtime managers that drive the Nature System's lifecycle: spawning, evolution, morphology routing, and player-critter bonding.

## MorphologyRouter

Routes `CritterDNA.body_type` (a continuous float, 0–4) to the correct kingdom mesh generator. Fractional values produce hybrids — the primary kingdom's mesh is built, but DNA gene blending from crossover naturally shows hybrid traits. When hybridity exceeds 0.35, secondary-kingdom visual decorations (branch stubs, eye spots, petal buds, fungal caps) are added as child nodes.

## CritterSpawner

Instantiation pipeline: `DNA → MorphologyRouter → CritterEntity` with mesh, material, and metadata. Supports single spawning, batch spawning, population seeding, and distance-based LOD selection from a reference point (e.g., VR player head). Maintains population caps and provides spatial queries over active critters.

## EvolutionSystem

Generational cycles with pluggable fitness:
1. Evaluate fitness of all critters (default rewards survival, energy efficiency, player engagement).
2. Tournament selection of parents.
3. Crossover + mutation to produce offspring.
4. Cull the weakest to maintain population bounds.
5. Spawn offspring via CritterSpawner.

Cross-kingdom breeding is allowed but rare — controlled by `CROSS_KINGDOM_RATE`. Emergency asexual reproduction kicks in when population drops below minimum.

## TransmutationManager

Tracks the player's bond with each critter through interaction types (observe, feed, touch, survive, fight). Bond grows toward a transmutation threshold. At threshold, the critter's `latent_ability` gene (0–5) maps to one of six ability categories × four kingdoms = 24 unique abilities. Includes kingdom-specific rituals that accelerate bonding.

## Files

- `morphology_router.gd` — Kingdom dispatch and hybrid decoration.
- `spawner.gd` — Instantiation, LOD, population management.
- `evolution_system.gd` — Selection, reproduction, culling.
- `transmutation_manager.gd` — Bond tracking and ability granting.

See the parent [Nature System README](../README.md) for the full architecture diagram.
