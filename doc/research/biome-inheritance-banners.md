# Doors become banners

**Progression correction:** [Evolution belongs to the journey](biome-evolution-between-maps.md).
The shipped prototype is now map-driven. The twenty-second loop documented below
is retained only as the earlier movement study.

19 September 2026. User proposal: the quad doors rise like Japanese war flags,
with beautiful patterns. This pass uses nobori-inspired proportions and
crossbars with five original geometric patterns, rather than historical insignia.

Review: <http://127.0.0.1:3003/biome-primitives/inheritance.html>

## Inherited form, added capability

The five actual AnimatableBody3D panel instances are retained. Their identifiers,
original two-triangle faces, widths, yaw and x/z positions survive. The early
walking archive and its clock are preserved. No substitute flag meshes are
introduced. The existing hinge pins extend into poles; each panel gains a gold
crossbar. Panels rise 2.35 m in a staggered twenty-second cycle, hold, then return.

A shader maps the existing faces into five patterns: wave arcs, nested diamonds,
a circle lattice, chevrons and branching lines. Indigo, vermilion, teal, gold and
plum palettes keep the forms distinct. Pattern fades in during the lift. The
faces remain rigid. This connects translation and surface pattern to the earlier
line/triangle/grid vocabulary; cloth and wind would be later capabilities.

The composed `.tscn` now enables `banners`. The script defaults it off so the
earlier width study and its evidence can still be reproduced. The mature
BiomeObject generator, seeds and published RSI baseline are unchanged.

## A spatial consequence

The first bridge used footprint clearance. The new study also compares the
world-local plant-mesh AABB's vertical range to the lifted panel, retaining the
same 0.35 m margin. The pole keeps its own footprint. Lowering the panel restores
exactly the same candidate membership; lifting does not reroll the ecosystem.

Seed 7: 572 candidates, 465 standing below the doors, 484 below the raised banners.
These figures differ from the earlier footprint-only width study because this
pass introduces vertical intervals and persistent poles. Ground-cover membership
changes immediately. This is neither simulated plant growth nor a shade model.
Larger catalogue residents still use the existing placement rules.

## Evidence

- 995 banner checks pass: retained live bodies and archive, unchanged terrain and
  dimensions, translated collisions, distinct pattern assignments, short/tall
  plant clearance, boundary contact, rendered counts and reversible membership.
- The original 1,020 inheritance checks also pass unchanged.
- Native Godot rendering and the headless probe agree on both recorded states.
- Four native views and 240 frames form a 20-second, 1440×900, 12 fps film.
- Capture: `commons/testing/capture_biome_banners.gd`.
- Verification/encoding: `tools/verify_biome_banners.py`.
- Publisher: `tools/publish_biome_inheritance.py`.
- Evidence: `ada_run/biome_inheritance/banners/`.

This remains a standalone prototype, not a completed museum integration. There
is no in-world interface. Headset reach, collision comfort and performance have
not been tested. Fixed-step capture is not an FPS benchmark.

The useful relation is now concrete: the same face can obstruct at one height,
carry a pattern at another, and leave room beneath it. Its identity persists
while its role changes.
