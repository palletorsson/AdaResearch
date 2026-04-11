# DNA Biome Ring — Real Organisms, LOD-Driven, VR-Safe

## Context

The biome ring currently uses placeholder MultiMesh shapes (cylinders for trees, spheres for flowers, capsules for creatures). This feels fake. The biome should be the **proof that the entire research works** — every organism born from CritterDNA, with real morphology from the same system used in the Pokemon Studio and nature demos. No defaults, no placeholders.

The challenge: VR needs 90fps. Full CritterEntity with L-system trees and segmented creatures can't run for 50+ organisms. Solution: **4-tier LOD** where only nearby organisms get full detail.

## Architecture

### LOD Tiers

| LOD | Distance | What renders | CPU cost | Mesh source |
|-----|----------|-------------|----------|-------------|
| **0** | < 5m | Full MorphologyRouter output — L-system branches, petal rings, segmented limbs, creature eyes | Per-frame for mobile creatures only | CritterEntity + MorphologyRouter |
| **1** | 5-15m | Simplified morphology — fewer segments, no fine detail (eyes, spots, leaf veins) | Static (no _process) | MorphologyRouter at LOD 1 |
| **2** | 15-30m | Single colored mesh approximation — one CylinderMesh for tree, SphereMesh for flower | None | Pre-generated from DNA colors |
| **3** | 30m+ | MultiMesh instance — current system, batched | None | Current BiomeRingComponent foliage |

### Key Insight: ChunkManager Already Exists

`commons/managers/ChunkManager.gd` does exactly this:
- 4x4m spatial chunks
- Distance-based LOD (4 tiers with configurable thresholds)
- Max 60 organisms managed
- LOD recalculation every 0.5s
- Uses CritterSpawner internally

The biome ring should **delegate to ChunkManager** instead of spawning its own organisms.

### Population Budget (VR)

| LOD | Max Count | Why |
|-----|-----------|-----|
| 0 | 3-5 | Full morphology is expensive — only what's in arm's reach |
| 1 | 10-15 | Simplified but still individual nodes |
| 2 | 20-30 | Single mesh each, very cheap |
| 3 | 200-500 | MultiMesh batched, current system |

Total: ~250-550 visual organisms, but only 3-5 are "real" at any time.

## Implementation Plan

### Step 1: BiomeRingComponent spawns DNA organisms via ChunkManager

**File**: `commons/grid/BiomeRingComponent.gd`

Instead of MultiMesh for everything, create a hybrid:
- Keep MultiMesh for LOD 3 (distant background fill) — current system
- Add a `ChunkManager` instance that manages LOD 0-2 organisms
- On generate(): seed ChunkManager with CritterDNA organisms at ring positions
- ChunkManager handles LOD transitions as player moves

```
generate() → 
  _place_foliage()           # LOD 3: MultiMesh background (existing)
  _spawn_dna_organisms()     # LOD 0-2: ChunkManager with CritterSpawner
```

### Step 2: DNA Seeding — Organisms Born from the Curriculum

Each kingdom gets DNA seeded from the map's sequence context:
- **Trees** (kingdom 0): DNA genes from the L-systems sequence learnings
- **Flowers** (kingdom 2): DNA from the color/wavefunctions sequences
- **Fungi** (kingdom 3): DNA from the cellular automata/randomness sequences  
- **Creatures** (kingdom 1): DNA from the swarm/morphogenesis sequences

The DNA isn't random — it reflects what the player has learned. Early sequences get simple organisms (few segments, low branch_angle). Late sequences get complex ones (high segments, deep recursion, iridescence).

**File**: New function `_create_sequence_dna(kingdom, density)` that builds CritterDNA with genes scaled by curriculum progression.

### Step 3: ChunkManager LOD Integration

**File**: `commons/managers/ChunkManager.gd` (already exists)

Configure ChunkManager for the biome ring:
- `chunk_size = 4.0` (4x4m spatial grid)
- `max_organisms = 60`
- LOD thresholds: [5.0, 15.0, 30.0]
- Reference point: XRCamera3D global_position (updated each frame)

When an organism transitions from LOD 2 → LOD 1 → LOD 0:
- LOD 2→1: MorphologyRouter.build() at LOD 1 (simplified)
- LOD 1→0: MorphologyRouter.build() at LOD 0 (full detail)
- LOD 0→1: Replace full mesh with simplified
- LOD 1→2: Replace with single colored mesh

### Step 4: Hybrid Rendering

The biome ring has two layers:
1. **Background layer** (LOD 3): MultiMesh instances — current system, always present, fills the horizon
2. **Foreground layer** (LOD 0-2): ChunkManager organisms — real DNA, real morphology, LOD-managed

The foreground organisms are placed at the same positions as some background instances. When a foreground organism is at LOD 0-2, the corresponding background MultiMesh instance is hidden (set transform to zero scale).

### Step 5: Static Organisms Don't Run _process

Key optimization: most organisms in the biome are **rooted** (trees, flowers, fungi — mobility < 0.1). CritterEntity already checks `is_static_kingdom()` and skips per-frame updates for rooted organisms. Only mobile creatures (kingdom 1 with mobility > 0.1) need _process.

With max 3-5 LOD 0 organisms and only ~1-2 being mobile creatures, the CPU cost is minimal.

## Critical Files

| File | Role | Change |
|------|------|--------|
| `commons/grid/BiomeRingComponent.gd` | Ring generator | Add ChunkManager integration, DNA seeding |
| `commons/managers/ChunkManager.gd` | LOD manager | Already exists — configure for biome use |
| `algorithms/nature_system/systems/spawner.gd` | CritterSpawner | Already exists — used by ChunkManager |
| `algorithms/nature_system/dna/critter_dna.gd` | DNA system | Already exists — create sequence-aware presets |
| `algorithms/nature_system/morphology/*.gd` | Mesh generators | Already exist — LOD 0-3 support built in |

## What Already Works

- CritterDNA → MorphologyRouter → mesh pipeline (all 5 kingdoms)
- LOD 0-3 in morphology generators (tube sides, branch counts, petal segments scale per LOD)
- ChunkManager with distance-based LOD recalculation
- CritterSpawner with population management
- BiomeRingComponent MultiMesh system (becomes LOD 3 layer)

## What Needs Building

1. `_spawn_dna_organisms()` in BiomeRingComponent — seeds ChunkManager
2. `_create_sequence_dna()` — curriculum-aware DNA generation
3. ChunkManager↔BiomeRing integration (foreground/background layer sync)
4. LOD transition smoothing (optional: scale tween on LOD change)

## Verification

1. Open a color map → sparse flowers at LOD 3 (MultiMesh) + 1-2 LOD 0 DNA flowers nearby
2. Open a fractals map → dense foliage + real L-system trees at LOD 0 when you walk close
3. Open an L-systems map → creatures visible as capsules at distance, full segmented bodies when close
4. Walk toward a tree → watch it transition from cylinder (LOD 3) → colored mesh (LOD 2) → simplified (LOD 1) → full L-system branches (LOD 0)
5. Check VR performance → 90fps maintained with 3-5 LOD 0 organisms

## The Promise

When you stand in the biome ring of the final QFEP map, every organism around you was born from the same DNA system. The tree next to you has L-system branches because you learned L-systems. The flower has golden-angle petal arrangement because you learned phyllotaxis. The creature has segmented limbs because you learned morphogenesis. The biome IS the curriculum, made alive.
