# Cheng Simulation -- Multi-Agent Ecosystem Simulation

A large-scale artificial life simulation featuring five distinct entity types -- wanderers, growers, networkers, predators, and builders -- that interact within a procedurally generated environment. The system demonstrates **emergent behavior**, **spatial partitioning**, **steering behaviors**, and **evolutionary adaptation** in a VR-compatible setting.

## Concept Taught

**Emergent systems** arise when simple individual rules produce complex collective behavior. This simulation teaches how agent-based models work: each entity type follows its own behavioral logic (wander, seek, flee, grow, connect, attack, build), but the interactions between types create an evolving ecosystem. Concepts covered include Reynolds' steering behaviors, spatial hashing for efficient neighbor queries, predator-prey dynamics, network formation, and evolutionary pressure on agent attributes.

## How It Works

1. An environment is generated with mounds, pits, and box structures based on `complexity_level`.
2. Resource points are scattered across the terrain, providing energy that regenerates over time.
3. Entities are spawned with randomized attributes and assigned one of five behavioral types.
4. Each frame, entities execute type-specific update logic:
   - **Wanderers** explore using wander steering, seek interesting targets, and share information on contact.
   - **Growers** slowly expand in scale, consume nearby resources, and reproduce by splitting when large enough.
   - **Networkers** form persistent connections with nearby networkers, share energy, and warn allies of predators.
   - **Predators** hunt other entity types using seek steering, attack on proximity, and form hunting packs.
   - **Builders** gather resources and construct structures over time, with precision improved through collaboration.
5. A spatial partitioning grid accelerates neighbor lookups for interaction processing.
6. Entities evolve their attributes over time based on their current state, adapting to environmental pressures.
7. Population is maintained through reproduction and removal of depleted entities.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `entity_count` | int | 30 | Initial number of entities |
| `environment_size` | Vector3 | (15, 8, 15) | World bounds |
| `complexity_level` | float | 0.7 | Environment feature density |
| `evolution_speed` | float | 1.0 | Rate of entity evolution |
| `chaos_factor` | float | 0.5 | Random velocity noise magnitude |
| `environment_reactivity` | float | 0.6 | Environment response strength |
| `visual_style` | int | 0 | 0=minimal, 1=organic, 2=glitch, 3=painterly |
| `enable_wanderers` | bool | true | Include wanderer entities |
| `enable_growers` | bool | true | Include grower entities |
| `enable_networkers` | bool | true | Include networker entities |
| `enable_predators` | bool | true | Include predator entities |
| `enable_builders` | bool | true | Include builder entities |
| `max_entities` | int | 100 | Population cap |
| `use_spatial_partitioning` | bool | true | Grid-based neighbor queries |

## Features

- Five distinct entity types with unique meshes, materials, and behavioral logic
- Spatial partitioning grid for O(n) neighbor detection instead of O(n^2)
- Reynolds steering behaviors: seek, flee, wander with configurable weights
- Predator-prey energy transfer and attack visual effects
- Networker connection visualization and cooperative warning systems
- Builder construction progress tracking and collaborative building
- Grower reproduction through splitting at size thresholds
- Evolutionary adaptation of entity attributes based on behavioral state
- Four visual style presets (minimal, organic, glitch, painterly)
- VR integration with XR controller interaction and entity highlighting
- Procedural environment generation with mounds, pits, and structures
- Resource point system with regeneration and consumption

## Files

- `cheng_simulation.gd` -- Full simulation implementation (~1300 lines) with entity AI, interactions, environment, and VR support
- `ChengSimulation.tscn` -- Main scene file
- `ChengSimulationScaled.tscn` -- Scaled variant scene
