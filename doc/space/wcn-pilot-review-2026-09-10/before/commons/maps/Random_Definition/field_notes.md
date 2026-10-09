## 2026-09-10 — the Random_Definition pilot (doc/research/waves-chance-noise)

Ruling followed: the map is the placement authority. This hall was live-claimed by a 15-bead bench stamp from 2026-08-21 (`randomness|random definition` in ada_run/necklace_hand.json, hall stamp true): the pack report showed every body built off its map cell, seed_replay_demo at [9,9] instead of its cell. The transplant's hand lookup in endless_museum.gd (line ~10898) now carries the same authored exemption the peek at 8204 already had, so map-authored halls build from their maps as map_authored.json's readme says. The stamp itself is untouched; commons/testing/probe_wcn_random_definition.gd loads the REAL hand file on purpose and asserts the demo stands at its map cell.

Structure: the interior 2-cells at x=1,5 z=14–18 are the pre-museum map's raised platforms (a36f33c9 shows them; summary.md called them raised platforms); under the default wall threshold the museum read them as walls. The wave recovery's contract is applied here in the same form — `museum.wall_height: 3, gate_depth_rows: 0` — and nothing else in the layers moved. Perimeter was already `w`.

Placement: `seed_replay_demo:0:-0.5` → `seed_replay_demo:0:-0.5#comparison:replicas`. The catalyst's label `CHAOS CATALYST` → `RANDOMNESS CATALYST` (its behaviour is a sequence catalyst; the room says random ≠ chaos).

Artifact: seed_replay_demo.gd gains comparison=offset, `extra_draws` (#offset:N), a +1 DRAW button that toggles the extra draw on the last grid live, the draw count under the headline, and a local RandomNumberGenerator for RANDOM (the shipped code advanced the global randi()). Defaults untouched: single with the extra draw off prints exactly the shipped headline. Registry dna.axes.comparison re-derived from code (now includes offset).

Exactness: the final quotes `_regenerate`'s seeding/colouring lines and the extra-draw guard verbatim (reduced: the material cast line is omitted and the excerpt is shorter than the loop).

Rejected: a seed keyboard; a "true random" contrast on the same panel (trng_vs_prng already does it, secondary).

Evidence: source checks pass (gdparse, pathfinder 218/286 OK, token gate, final_tags, cite_gate, excerpts verbatim). Runtime probe written, NOT RUN (Godot occupied). Headset: not walked. Numeric keys `seed`, `offset`, `contrast_seed`, `octaves` added to the grid's CONFIG_PARAM_NAMES so `#offset:1` is a value in the standalone grid too.

Supporting texts: intent, blurb, summary, tutorial rewritten (they described a 5×17 corridor and a crank-machine build); technical.md's "possible artifact" seed_reproducibility_demo marked built with the real loop; critical.md kept.
