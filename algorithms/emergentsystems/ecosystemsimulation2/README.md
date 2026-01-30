# Queer Computational Ecosystem

A simulated ecosystem where entities evolve, transform, and form relationships through queer-theoretic principles — fluidity, boundary-pushing, and perpetual becoming.

## QFEP Connection

This is **QFEP made ecology**. Entities balance order (F) against entropy (E) through:
- **λ** manifests as the order↔chaos spectrum in entity traits
- **φ** (rate of change) appears in fluidity and transformation probability
- **Boundaries** can be challenged and dissolved, not just respected
- **Identity** is process, not state — entities are always becoming

The ecosystem embodies queer theory: rejecting fixed categories, valuing diversity, celebrating transformation.

## Architecture

```
EcosystemController
├── Environment        (terrain, day/night, seasons, weather)
├── ResourceSystem     (energy, material, information, essence)
├── RelationshipNetwork (kinship, alliance, romantic, queer bonds)
├── MorphologyGenerator (procedural entity forms)
├── BoundarySystem     (physical, relational, cognitive, expressive)
├── EventSystem        (celebrations, challenges, transformations)
├── Visualization      (rendering, effects, highlighting)
└── Entities[]         (autonomous agents with QueerTraits)
```

## Queer Traits System

Each entity has continuous spectra (not binary categories):

### Core Traits (0.0 → 1.0)
| Trait | Description |
|-------|-------------|
| `fluidity` | Ability to transform and change |
| `expressiveness` | Visual and behavioral intensity |
| `sociality` | Desire for connection |
| `boundary_pushing` | Tendency to challenge norms |
| `uniqueness` | Tendency toward novel traits |
| `adaptability` | Response speed to change |
| `resilience` | Recovery from adversity |

### Spectra Positions
| Spectrum | Endpoints |
|----------|-----------|
| `material_immaterial` | Physical ↔ Ethereal |
| `individual_collective` | Autonomy ↔ Integration |
| `order_chaos` | Structure ↔ Entropy |
| `visible_invisible` | Overt ↔ Subtle |
| `stable_evolving` | Consistent ↔ Becoming |

## Boundary System

Four boundary types that can be challenged:

| Type | Color | Challenge Traits |
|------|-------|------------------|
| **Physical** | Blue | fluidity, boundary_pushing |
| **Relational** | Red | uniqueness, sociality |
| **Cognitive** | Green | adaptability, fluidity |
| **Expressive** | Yellow | expressiveness, uniqueness |

Boundaries have permeability and stability — some dissolve easily, others persist.

## Relationship Network

Connection types beyond heteronormative models:

| Type | Color | Description |
|------|-------|-------------|
| `kinship` | Green | Chosen family bonds |
| `alliance` | Blue | Mutual aid, collaboration |
| `romantic` | Red | Intimate connection |
| `mentorship` | Yellow | Knowledge transfer |
| `creative` | Purple | Collaborative creation |
| `fluid` | Cyan | Constantly evolving |
| `nomadic` | Brown | Temporary, traveling |
| `queer` | Pink | Challenges normative patterns |

## Event System

### Celebration Events
convergence, emergence, flowering, resonance, coalescence, symmetry_breaking

### Challenge Events
boundary_test, entropy_spike, resource_scarcity, identity_crisis, form_instability

### Transformation Events
morphic_resonance, quantum_shift, collective_evolution, phase_transition

## Files

| File | Purpose |
|------|---------|
| `main.tscn` | Scene root |
| `ecosystem_controller.gd` | Orchestrates all systems |
| `entity.gd` | Autonomous agent with traits |
| `queer_traits.gd` | Trait resource class |
| `environment.gd` | Terrain, weather, seasons |
| `resource_system.gd` | Four resource types |
| `relationship_network.gd` | Bond formation and decay |
| `morphology_generator.gd` | Procedural entity forms |
| `boundary_system.gd` | Boundary types and challenges |
| `event_system.gd` | Narrative events |
| `visualization.gd` | Rendering and effects |

## Parameters

### Ecosystem Controller
| Export | Default | Description |
|--------|---------|-------------|
| `initial_entity_count` | 20 | Starting population |
| `environment_size` | (50, 20, 50) | World bounds |
| `season_duration_days` | 30 | In-simulation days per season |
| `day_duration_seconds` | 10.0 | Real seconds per sim day |
| `entropy_growth_rate` | 0.05 | Global entropy increase |

## Usage

```gdscript
var ecosystem = preload("res://algorithms/emergentsystems/ecosystemsimulation2/main.tscn").instantiate()
ecosystem.initial_entity_count = 50
ecosystem.entropy_growth_rate = 0.08  # More chaos
add_child(ecosystem)
```

## VR Experience

Observe the ecosystem from above or walk among the entities. Watch relationships form (visible connections), boundaries get challenged, entities transform. The visualization modes let you highlight different aspects — trait distributions, relationship networks, resource flows.

## Theoretical Foundation

This simulation implements concepts from:
- **Judith Butler**: Identity as performative, always in process
- **Karen Barad**: Intra-action, boundaries as enacted not given
- **Sara Ahmed**: Queer phenomenology, orientation and desire
- **Free Energy Principle**: Life minimizes surprise while maintaining adaptability

## See Also

- `qfep/` — Direct QFEP parameter manipulation
- `cellularautomata/` — Simpler emergent systems
- `steering/` — Agent-based behaviors
