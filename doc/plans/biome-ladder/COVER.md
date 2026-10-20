# Primitives cover — B10 implementation, 2026-10-13

Four boxes and two cylinders now provide standing cover along the route. Both are 2 m tall. Boxes are 1.35 m wide and deep, centred at x ±2.2 m; cylinders retain radius 0.55 m and sit at x ±1.6 m. The narrowest central gap is 2.1 m. Low spheres and cones, the white outlined floor, skull positions, damage and shot speed retain their previous settings. This change applies to Primitives only.

The box gives a broad sheltered area; the cylinder gives a curved edge to move around. Protection is relative to the firing head, not immunity from every direction.

## Native evidence

- `cover-before.png`: previous Primitives layout, recorded before editing.
- `cover-after.png`: new layout from the same standing view (camera at 0.3, 1.65, 8.2).
- `cover-behind-box.png` and `cover-step-out.png`: the same head hidden by the box, then revealed by stepping into the lane.
- `cover-checks.json`: 27/27 assertions, Godot process exit 0.

Actual skull balls collide with the box and cylinder before reaching the sheltered player: zero damage. From exposed positions beside those shelters, the same firing path mechanism reaches the player's capsule and registers one hit. The central route clears a swept player capsule; all three heads are visible from the central standing view at (0, 1.65, 8.2). This does not claim every head is visible from every position.

The desktop input suite also passes 47/47 and the four-stage regression passes 54/54; both processes exit 0. Existing ObjectDB cleanup warnings remain. These are rendered engine checks, not headset acceptance.

## Scope and handoff

Runtime change: `_landscape()` in `commons/hazards/biome_ladder/ladder_encounter.gd`.

Codex's probe: `tools/probes/biome_primitives_cover.gd`. Run rendered with the same Godot flags in HANDOVER.md. Source evidence and logs: `ada_run/biome_primitives_cover/`.

The desktop test now fires from the open lane in Primitives; its old firing position was beside the newly functional box, where the muzzle must correctly be blocked.

Claude subsequently supplied `tools/probes/biome_ladder_cover.gd`: 106 real flights confirm all six tall Primitives shelters stop the tested standing shots. Later stages have no working standing cover at the sampled positions, so the independent test exits 1. This follow-up changes the priority of B11: carry useful cover forward as well as making Transformation readable. See NEXT-ITERATION.md and `claude-cover-checks.json`. The former proposed path `biome_ladder_review.gd` was not used.


B11 follow-up is now implemented: the six shelters continue into later stages. TRANSFORMATION.md records the passing rerun and new phase evidence.
