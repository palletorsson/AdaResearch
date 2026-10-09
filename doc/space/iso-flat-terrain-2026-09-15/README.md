# ISO_FlatTerrain — 15 September 2026

FlatTerrain is the sixth active isosurface hall. It preserves the original 16×12 map structure at `(3,32)` inside a 30×48 open-roof court and keeps all four inherited terrain artifacts. `mc_flat_landscape` and `mc_overhang_landscape` are the two primary works; `mc_terrain_demo` and `rhizome_cave_system` remain secondary collection pieces.

The new `iso_terrain_console` is a compact, reachable desk bound to the two existing GPU generators. `INTERIOR` steps the height field through none / undercut / caverned / warren. `TERMS` accumulates hillside / overhung / quarried / arched / compound terms on the second field. `HOLD` duplicates the left surface ten metres behind the live specimen. `COLUMN` marks crossings from a fixed 25×25 lattice, and `RULE` exposes the scope of the measurement. `RESET` returns both fields while keeping the held copy.

The rendered mobile review passed **53 checks**: actual pointer presses, both generator bindings, field rebuilds, multi-crossing columns, held-surface preservation, fixed specimen placement, reset geometry, physical side aisles and onward walking. The receipt records one renderer-shutdown mesh diagnostic separately; no interaction check failed. The run used an isolated snapshot of the necklace hand, leaving the open editor and saved hand untouched. Headset reach, comfort and Quest performance remain unverified.

The current book text makes the pedagogical hinge explicit: a height field can vary while assigning one height to each horizontal position; a volumetric field can classify solid and air at several heights in one column. The column counter makes the difference observable without pretending that a finite sample proves connectivity or body clearance.

Replay: `python ada_run/review_iso_terrain.py`, then `python tools/build_iso_terrain_review.py`, then `powershell -NoProfile -ExecutionPolicy Bypass -File ada_run/publish_iso_terrain.ps1`. Do not replay the one-time staging script over later edits.

Review: http://localhost:3003/research/possible-bodies/iso-flat-terrain.html

Next: ISO_Caves — when a volume has an opening, what makes it a route?
