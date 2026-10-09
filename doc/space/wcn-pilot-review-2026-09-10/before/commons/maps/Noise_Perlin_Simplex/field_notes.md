## 2026-09-10 — the Noise_Perlin_Simplex pilot (doc/research/waves-chance-noise)

Ruling: a fair comparison matters more than the current cabinet (the card's latitude), and the map is the placement authority.

Structure CHANGED, and why: the pre-museum map (a36f33c9) was an all-void basin with four floor cells; the 100 m `noise_terrain` WAS the floor. The museum conversion added a walkable rim and three piers; the pathfinder read 1 of 89 cells reachable, and the museum had to move the terrain to keep its walk. The interior is now floor (`1`), the three east piers at (10,3),(10,7),(10,11) are removed (they were the conversion's, not the room's), and the walk reads 149 of 195 reachable. The basin is archived (doc/space/waves-chance-noise-pilots-2026-09-10/{before,pre-museum}); `noise_terrain` is removed from this hall and its book line left in place for Astra to rule on. `perlin_noise_terrain` stays as the secondary, moved to (2,11); dark_sphere to (6,11); the portal keeps its cell and is relabelled "Lab Path (optional)". No teleporter was added: the museum carries its own passage to CA_Introduction.

Placement: `simplex_noise:0:1.1#seed:20260910#size:8#ramp:shared#panel:front` at (3,7) and `perlin_noise:0:1.1#generator:perlin#seed:20260910#size:8#ramp:shared#panel:front` at (8,7). y 1.1 lifts the root by one amplitude so the relief's lowest cube sits on the floor; size 8 keeps the 0.5 m resolution (fewer cubes, not smaller), so two 4 m fields fit with a one-metre aisle; `size` is an already-listed grid config key, `seed`/`octaves` are newly listed.

Artifacts: both visualizers gain seed_value (−1 = shipped randi), a recorded current_seed, reseed(), rebuild_size(), sample_at() and a shared colour ramp; NoiseVisualizer gains the fractal gain it never set (it ran on the 0.5 default by luck). Both roots gain seed/ramp/size/panel, a RackTemplates panel (FREQ, OCTAVES, REGEN, REPLAY), a readout that names the basis FROM THE GENERATOR and prints the value at (0,0) and (2.5,2.5), and root-side parameter state so the stripped 2D UI is no longer dereferenced. Defaults untouched. The two roots are kept as deliberate twins (local first, share on a third consumer).

The correction the card called high-value: the Perlin display's basis. `_noise_type_for`'s default is simplex and no placement had ever passed the word; it drew simplex under the Perlin name until today.

Exactness: the final quotes `_noise_type_for` and `generate_noise_at` verbatim; the same-integer-two-bases caveat is stated, not hidden.

Rejected: scaling the roots (would shrink the panels with them); keeping the basin with the fields floating over void; a lattice overlay (technical.md's proposal — a later instrument).

Evidence: source checks pass (gdparse, pathfinder 149/195 OK, token gate, final_tags, cite_gate held on critical.md's quoted sentence, excerpts verbatim). Runtime probe written, NOT RUN (Godot occupied). Headset: not walked.

Supporting texts: intent, blurb, summary, tutorial, critical rewritten (they described crosshairs, a 45° toggle and identical-parameter terrains that were never built); technical.md's invented configurations and the terrain-versus-terrain section replaced with the real build.
