## 2026-09-10 — the Random_Definition pilot (doc/research/waves-chance-noise)

Ruling followed: the map is the placement authority. This hall was live-claimed by a 15-bead bench stamp from 2026-08-21 (`randomness|random definition` in ada_run/necklace_hand.json, hall stamp true): the pack report showed every body built off its map cell, seed_replay_demo at [9,9] instead of its cell. The transplant's hand lookup in endless_museum.gd (line ~10898) now carries the same authored exemption the peek at 8204 already had, so map-authored halls build from their maps as map_authored.json's readme says. The stamp itself is untouched; commons/testing/probe_wcn_random_definition.gd loads the REAL hand file on purpose and asserts the demo stands at its map cell.

Structure: the interior 2-cells at x=1,5 z=14–18 are the pre-museum map's raised platforms (a36f33c9 shows them; summary.md called them raised platforms); under the default wall threshold the museum read them as walls. The wave recovery's contract is applied here in the same form — `museum.wall_height: 3, gate_depth_rows: 0` — and nothing else in the layers moved. Perimeter was already `w`.

Placement: `seed_replay_demo:0:-0.5` → `seed_replay_demo:0:-0.5#comparison:replicas`. The catalyst's label `CHAOS CATALYST` → `RANDOMNESS CATALYST` (its behaviour is a sequence catalyst; the room says random ≠ chaos).

Artifact: seed_replay_demo.gd gains comparison=offset, `extra_draws` (#offset:N), a +1 DRAW button that toggles the extra draw on the last grid live, the draw count under the headline, and a local RandomNumberGenerator for RANDOM (the shipped code advanced the global randi()). Defaults untouched: single with the extra draw off prints exactly the shipped headline. Registry dna.axes.comparison re-derived from code (now includes offset).

Exactness: the final quotes `_regenerate`'s seeding/colouring lines and the extra-draw guard verbatim (reduced: the material cast line is omitted and the excerpt is shorter than the loop).

Rejected: a seed keyboard; a "true random" contrast on the same panel (trng_vs_prng already does it, secondary).

Evidence: source checks pass (gdparse, pathfinder 218/286 OK, token gate, final_tags, cite_gate, excerpts verbatim). Runtime probe written, NOT RUN (Godot occupied). Headset: not walked. Numeric keys `seed`, `offset`, `contrast_seed`, `octaves` added to the grid's CONFIG_PARAM_NAMES so `#offset:1` is a value in the standalone grid too.

Supporting texts: intent, blurb, summary, tutorial rewritten (they described a 5×17 corridor and a crank-machine build); technical.md's "possible artifact" seed_reproducibility_demo marked built with the real loop; critical.md kept.


## Astra source review - 2026-09-10

apply_grid_config now retains seed/comparison values before _ready, when the museum supplies them. +1 DRAW regroups RGB channels along the stream; no cube moves and no spatial one-third-cell shift is claimed. The global-RNG isolation assertion no longer yields a frame between its two observations.

All three pilots explicitly set `museum.artifact_placement: "map"`. This replaces the broad authored-map exemption: other rooms keep their existing necklace placement behaviour. Recovered wave geometry is unchanged.

Status: source corrections complete; museum runtime probes and tracked-hand verification pending. See `doc/book/handoffs/astra-wcn-pilot-review-2026-09-10.md`. Earlier evidence in this file describes the Fable handback before these corrections.


## 2026-09-10 — first museum runs (Fable)

`probe_wcn_random_definition.gd`, rendered under the watchdog, three runs. Observed: the seed demo is a table-top piece (cubes from 0.35 m, panel at 0.12 m above its origin) and stood on the deck with its panel at 0.16 m. Fixed in the artifact: a `stand` export (none | table), TABLE_HEIGHT 0.85, a column and a round top under the demo; the token is now `seed_replay_demo:0#comparison:replicas#stand:table` (the old −0.5 y offset was not applied by the museum lane and would sink the demo in the grid lane). The panel is at 1.01 m, the grids at eye level; the RANDOM button's slider follow finds the slider by name again (the panel node is named Panel now). The `dark_sphere` at (3,13) stood exactly where a body stands to use the panel; moved to (7,13). `museum.sculpture_clear_rects` [[1,10,6,14]] keeps dealt plinths off the demo's spot. 25 checks, 0 failures: built at (3,12), the platforms at 1 m, replicas equal, REPLAY / RANDOM / +1 DRAW through their own signals, the global RNG untouched. Capture: `probe_random_definition.png`. The `random_butterflies` swarm at (3,11) fills the whole hall with white spheres in the capture; left as the hall's character and noted for Astra.


## 2026-09-10 — the seed comparison leaves the entropy cloud (Fable, after Astra's runtime review)

The "swarm" over the seed demo in the first capture was not the butterflies (eight at most) but `entropy_axiom:0:1.5:0.9` at (3,6): a 10 × 10 × 40 point cloud at 0.2 m spacing, 1.8 × 1.8 × 7.2 m, running south from row 6 to row 13 through x 2.6–4.4, its disorder growing with z. The seed demo at (3,12) stood inside its chaotic end, as the pre-museum map had it at (2,11); the table only lifted the panel into the densest part of the cloud. The cloud is the hall's spine, order to chaos, and stays exactly where it is.

Staging: `seed_replay_demo:-90#comparison:replicas#stand:table` at (8,11), turned so its panel faces west. A visitor arrives down the empty east half (x 6–11 carried nothing but the moved dark sphere), stands at (7,11) and looks east at the grids with the east wall behind them; the cloud is behind the visitor, five metres off, and can be turned to. `dark_sphere` (7,13) → (10,15), out of that approach. `museum.sculpture_clear_rects` follows the demo: [[5,9,10,13]]. The cloud's own placement, the butterflies, the jar and the rest of the west column are untouched.

The comparison's evidence (replicas equal, REPLAY / RANDOM / +1 DRAW, RNG isolation) is re-run in the museum by `probe_wcn_random_definition.gd` at the new cell, and under project startup (`probe_live.tscn --probe=random_definition`) the project's desktop rig stands at (7,11), looks at RANDOM and left-clicks through the input pipeline — actual desktop input, recorded apart from the emitted signals. Approach and close captures: `probe_random_definition_desktop_approach.png`, `probe_random_definition_desktop_close.png`.


## 2026-09-10, evening — the re-staged comparison under project startup (Fable)

Run: `bash tools/run_wcn_probe.sh random live` (the probe ported to a Node, run as the project's main scene, autoloads present). 27 checks, 0 failures (`probe_random_definition_live.json`), no script errors: the comparison's evidence re-run at the new cell (8,11) — replicas equal, REPLAY / RANDOM / +1 DRAW through their signals, the global RNG untouched.

Actual desktop input, recorded apart from the emitted signals: the project's desktop rig stood at segment-local (7.4, 0, 11.5), 1.1 m west of the table with the demo turned to face it, looked at RANDOM and left-clicked through the input pipeline; its pointer reported `SeedReplayDemo/Panel/Btn_1/InteractableAreaButton` under the crosshair and the seed went 168 → 426 on both grids. Captures drawn by the rig's camera: `probe_random_definition_desktop_close_live.png` — the two grids under SAME SEED TWICE, SEED: 426 twice, the three buttons on the table, a plain wall behind, nothing between the visitor and the comparison — and `probe_random_definition_desktop_approach_live.png` — from (8.0, 5.5) looking south down the open east half: the table six metres ahead, the entropy cloud on the right, the dark sphere (10,15) on the left, the POINT POSITION board high on the far wall. The probe's own camera adds `probe_random_definition_live.png`, the comparison from 1.5 m. The cloud (`entropy_axiom`, the hall's order-to-chaos spine) is untouched, five metres behind a visitor at the table. Headset: pending.


## 2026-09-11, 07:37 — refreshed under the current probe sources (Fable, Astra's W2 completion brief, item 1)

`bash tools/run_wcn_probe.sh random live`, Godot free: 27 checks, 0 failures. Why the rerun: after this room's 20:50 run the shared probe sources changed (the capture settle moved from the render server's `frame_post_draw` to a timer; the driver's pose log and the guard flag were added), so the evidence is regenerated from the sources that now stand; the results are the same as the second pass. Captures refreshed in place. Headset: pending.

**2026-09-12 — the visual pass (Astra: "the small cream controller is washed out and its action names are much harder to read than the floating title").** The panel is scaled 1.5 for its labels, and a cased action line at its foot (a 0.50 × 0.075 m plate at the table's front edge, 55° to the eye) names the last action, the seed and whether the two grids agree cell for cell (`RANDOM · seed 454 · grids equal`; `+1 DRAW on · … · grids differ`). REPLAY, RANDOM and +1 DRAW each write it; the arrival draw writes RANDOM. Live: 29 checks / 0 failures.

**2026-09-12, later — after Astra's review of the pass ("controls remain washed out: finish contrast, not just size").** The panel's material is contrasted in place: every bare plate on it with a pale albedo (the rack's cream faces and frames) is given a dark matte override, and every Label3D on it is set light with a six-pixel black outline and its font scaled 1.35 (the seed's caption under each grid: font 20, outline 5). The rack's button names — REPLAY, RANDOM, +1 DRAW and the SEED tag — are baked-text tags, black lettering baked into an off-white albedo texture: darkening those would erase the lettering, so they are kept pale on purpose and the probe counts them apart (four lettered tags, no bare pale plate, eleven dark). A second contrast pass runs a frame after the panel enters the tree for parts built on entering. Probe: no bare pale plate, dark plates ≥ 1, lettered tags ≥ 3, every label light with an outline of at least 4 and none under 16 px (smallest 22). Live: 32 checks / 0 failures. Astra's acceptance, the headset: pending.


## 2026-09-12 — Astra continuation from Synthesis Lab

The existing patch-and-replay encounter now has its supporting text aligned with the real instrument. All 15 placements, the east table and west cloud remain. The slider receiver used an obsolete panel path; it now updates the integer seed and synchronizes the handle after programmatic changes and rebuild. Local panel backing and lettered tags are unshaded; the action readout is larger and contrast passes no longer repeatedly enlarge fonts.

Independent run 19:22:02–19:22:27 +02:00: 65 checks, zero assertion failures, exit 0. Exact colour bytes, independent RGB reconstruction, actual desktop drag/buttons and unload/rebuild pass. One ObjectDB/resource shutdown warning remains. Headset reach and small lettering await a later visit. The map changed only metadata after the run; its layers and museum settings are unchanged.

The book keeps the discovery that one discarded draw reassigns RGB while cells and seed stay still. It now notices the continuous gesture selecting integer seeds, allows RANDOM to repeat and distinguishes waiting from advancing this local stream. Nine production excerpts checked. Primary, book anchor and hero remain seed_replay_demo.

Illustrated review with actual captured colour values: /research/possible-bodies/random-definition.html. Full record: doc/space/random-definition-review-2026-09-12/README.md. Next: Random_Entropy, preserving its existing repairs while testing what a histogram loses when the arrangement changes.

## 2026-09-16 — central hero and supporting studies

Recover a seeded picture, then compare how other devices produce or retain a draw. Current placements and sizes are listed in artifacts.md. The staging manifest and desktop runtime evidence are in doc/space/randomness-staging-2026-09-16/. This pass supersedes older placement/count descriptions in these notes; tracked-hand reach, headset comfort and performance remain to be checked.
