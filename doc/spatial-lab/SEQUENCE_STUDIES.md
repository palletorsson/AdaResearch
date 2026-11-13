# Spatial Lab across the tutorial sequences

13 November 2026. User chose **lab studies first**, with no new main-tower placement.

The same `/spatial-lab` now has Transformation, Array, Fractal and Randomness
areas. Recipes can belong to more than one area. Each corresponding encyclopedia
sequence page links into its lab area. Existing Colour, Portal and review tools
remain available.

| Area | Direct link | Studies |
|---|---|---|
| Transformation | http://localhost:3003/spatial-lab?sequence=transformation | Existing arrangements and Backrooms, growing dominoes, narrowing thresholds, turning passage |
| Array | http://localhost:3003/spatial-lab?sequence=array | Packed/radial/growing repetitions, warehouse grid, Backrooms, dominoes, thresholds and seeded field |
| Fractal | http://localhost:3003/spatial-lab?sequence=fractals | Recursive branching scaffold |
| Randomness | http://localhost:3003/spatial-lab?sequence=randomness | Repeatable seeded field |

## New recipes

- `lab_domino`: upright pieces grow by a ratio, with adjustable clear gap and lean.
  **Static study; not a physical toppling simulation.**
- `lab_thresholds`: repeated openings shrink or expand and roll around their
  centres. Reduced headroom is part of the question; not all settings are walkable.
- `lab_turning_passage`: thick portal ribs advance along a path with separate yaw,
  pitch and roll controls. Ribs overlap intentionally. Strong bends may intersect
  or go below the floor; a later installation needs route/slide validation.
- `lab_branching`: each beam produces two smaller beams at its tip. Generation
  depth 0–5 gives 1, 3, 7, 15, 31 or 63 parts. Branch angle and ratio are adjustable.
- `lab_seeded_field`: Park–Miller seeded choices vary cell displacement, yaw,
  height and omissions. Every cell consumes five draws even when omitted, so
  increasing omissions leaves surviving cells unchanged. The first cell is an
  explicit anchor. The seed makes a saved result reproducible.

All five use original construction-prefab meshes/materials fitted to explicit
structural dimensions, with matching static box colliders. This fitting is shown
in the interface. Source scenes stay unchanged; stable member IDs let the editor
move, rotate and copy each member independently. Existing unfitted recipes retain
their previous behavior. No automatic clearing of overlaps or fit correction.

Use the recipe selector, choose a prefab, adjust sliders or try a preset, then
**Save variation + native check**. The result is a separate trial and an editor
link. Existing variations are never replaced by the save operation. Settings are
held stable during the check. Saved settings can be reused in the same area.

## Evidence

Five reference studies: 379 native checks, 116 editable construction members,
131 exported model files. Reference IDs, timings and results:
`ada_run/spatial-studies-2026-11-13/references.json`.

The independent `tools/test_spatial_studies.cjs` checks control boundaries,
recursion counts, deterministic seeds, omission stability, Three.js/Godot position
and rotation parity, real member GLBs, and each recipe's move/rotate/copy plus
validated save/reload and stale-save rejection in isolated fixtures.

Browser checks: sequence switching, recursion depth 3→5, construction-cube swap,
branch presets, ordered→disordered field, seed change, timber-source swap and an
actual save. That additional field became `spatial_lab_aaad436eea` with 20 members,
67 passing checks, and 40.9 seconds for save/export/native startup/checks.

One native run observed a concurrent main-tower layout change. The runner records
before/after hashes rather than restoring or failing an unrelated isolated trial.
No main-tower arrangements were changed by this task.

These are static construction and editor checks. They are not acceptance of
domino dynamics, walking every possible parameter setting, or physical-headset use.

## Implementation

Catalogue: `commons/modular/lab.json` and `commons/modular/terms.json`.
Numeric grammar: `commons/modular/spatial_studies.gd`, mirrored by the web's
`src/lib/spatial-studies.ts`. Existing recipe adapter, export, native slot and
save APIs are reused. New studies are registered under the matching modular
chapter; the recipe data is shared with the knowledge tree.
