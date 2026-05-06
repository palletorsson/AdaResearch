# Grid Editor Subsets — Chemical Models, Periodic Table, Sticky Notes
**Date:** 2026-03-07

## Verification

All presets captured and verified via Godot headless pipeline:
- 7 chemical model molecules (including caffeine/adenine with explicit bonds)
- 5 periodic table views (including full 118-element table)
- 3 sticky note layouts

## Molecule Layouts

### Caffeine (C8H10N4O2)
Fused 6+5 ring (xanthine). 15 atoms on a 5x4 grid, 16 explicit bonds. Three methyl groups (C), two carbonyl oxygens (O), four ring nitrogens (N).

### Adenine (C5H5N5)
Purine nucleobase — the "A" in DNA/RNA/ATP. Directly related to adenosine deaminase (ADA), the project's namesake enzyme. 13 atoms on a 4x5 grid, 14 explicit bonds.

## Technical Highlights

### Polished Materials
Atom spheres: glossy clearcoat, subtle CPK-colored emission, rim lighting, 32-segment meshes.
Bond sticks: chrome-like finish (metallic 0.7, roughness 0.15), thicker radius for visibility.

### Explicit Bond Specification
For fused-ring molecules (caffeine, adenine), auto-detection creates spurious bonds between non-bonded adjacent atoms. Solution: optional `"bonds"` array in preset JSON.

```json
"bonds": [
  [[0, 1], [1, 1]],
  [[0, 1], [0, 2]],
  ...
]
```

Each entry is a pair of grid positions. When present, only specified bonds are drawn — auto-detection is bypassed entirely. Backwards compatible: presets without `"bonds"` still use Chebyshev neighbor detection.

### Chebyshev Bond Detection
For simple molecules, bonds auto-detect between atom elements within Chebyshev distance 1 (includes diagonals). Filters: skip non-atom elements (bond markers, lone pairs), skip H-H bonds.

### XY Plane Y-Flip
Wall-mounted subsets (sticky notes, periodic table) need grid row 0 at the top, but 3D Y=0 is the bottom. Fixed by negating Y in positioning: `Vector3(x * gs, -y * gs, 0)`.

## New Subsets

### Chemical Models
Tabletop ball-and-stick (XZ plane, 40cm grid). CPK-colored atom spheres connected by chrome bond cylinders. Auto-detects bonds via Chebyshev distance for simple molecules; uses explicit bond arrays for complex ring systems.

**7 presets:** water, methane, ethanol, benzene, NaCl crystal, caffeine, adenine

### Periodic Table
Wall-mounted tile grid (XY plane, 12cm grid). All 118 elements with category-colored tiles, symbol labels, and atomic numbers. Standard 18-column layout with lanthanide/actinide rows.

**5 presets:** first three periods, alkali column, noble gas column, transition row 4, full 118-element table

### Sticky Notes
Wall-mounted board (XY plane, 12cm grid). Colored rectangles with text labels — brainstorm boards, kanban layouts, concept maps. Elements include notes in five colors, header strips, push pins, and arrow connectors.

## Files Changed

**Created:**
- `tools/grid_editor/subsets/sticky_notes.json`
- `tools/grid_editor/subsets/chemical_models.json`
- `tools/grid_editor/subsets/periodic_table.json`
- `commons/testing/gen_periodic.py` — helper to generate all 118 elements

**Modified:**
- `tools/grid_editor/scripts/subset_loader.gd` — registered 3 new subset paths
- `tools/grid_editor/scripts/grid_editor_capture.gd` — 3 procedural builders, explicit bond support, Y-flip, material polish

## Summary

Added three new element-based systems to the grid editor, each with procedural 3D builders, JSON-driven presets, and a capture pipeline. The chemical models subset was extended with explicit bond specification for complex fused-ring molecules like caffeine and adenine.
