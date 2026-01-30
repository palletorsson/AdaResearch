# Rhizomatic Structure

Procedural generation of non-hierarchical, multiply-connected growth structures — inspired by Deleuze & Guattari's concept of the rhizome.

## QFEP Connection

Rhizomes embody **radical horizontality**. Unlike trees (hierarchical, F-dominant), rhizomes have no center, no root, no defined path — any point can connect to any other (E-dominant). The `connection_probability` parameter controls how networked vs linear the structure becomes: λ manifested as spatial topology.

## How It Works

```
     ·───·       ·
    /│   │\     /│
   · │   · ·───· ·
    \│  /│ │   │/
     ·───· ·───·
      │   ×   │
      ·───·───·

No hierarchy. Multiple connections.
Any point can connect to any other.
```

Algorithm:
1. Start with a root node (but it's not privileged)
2. For each branch: pick random parent, grow in semi-random direction
3. For each node pair: probabilistically add cross-connections
4. Result: networked, non-hierarchical structure

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `num_branches` | 50 | Total growth events |
| `min_branch_length` | 1.0 | Minimum segment length |
| `max_branch_length` | 5.0 | Maximum segment length |
| `min_branch_thickness` | 0.1 | Thinnest branch |
| `max_branch_thickness` | 0.3 | Thickest branch |
| `growth_direction_randomness` | 0.7 | How chaotic the growth |
| `connection_probability` | 0.2 | Chance of lateral connections |
| `min_distance_for_connection` | 1.0 | Minimum connection range |
| `max_distance_for_connection` | 3.0 | Maximum connection range |

## Rhizome Principles (Deleuze & Guattari)

1. **Connection**: Any point can connect to any other
2. **Heterogeneity**: Different kinds of links possible
3. **Multiplicity**: No unity, just multiplicities
4. **Asignifying rupture**: Can break and restart anywhere
5. **Cartography**: Maps territory rather than tracing origins
6. **Decalcomania**: Not a copy but a productive map

## Files

| File | Purpose |
|------|---------|
| `rhizomatic_structure.gd` | Generation algorithm |

## Usage

```gdscript
var rhizome = RhizomaticStructure.new()
rhizome.num_branches = 100
rhizome.connection_probability = 0.4  # More interconnected
add_child(rhizome)
```

## VR Experience

Walk through the rhizome. Unlike a tree, there's no trunk to orient you — every path is valid, every connection is lateral. The structure resists hierarchy: you can't find "the center" because there isn't one.

## Theoretical Context

From *A Thousand Plateaus* (1980):
> "A rhizome has no beginning or end; it is always in the middle, between things, interbeing, intermezzo."

This contrasts with arborescent (tree-like) structures that dominate Western thought: family trees, organizational charts, taxonomies. Rhizomes are the counter-model.

## See Also

- `rhizomaticmazespace/` — Navigable rhizomatic environments
- `lsystems/` — Tree-like (arborescent) structures
- `graphtheory/` — Network connectivity
