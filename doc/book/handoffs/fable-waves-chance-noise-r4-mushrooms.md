# Handoff — Waves, Randomness and Noise, batch R4: Random_Mushrooms (Fable 5.1, 2026-09-12)

Status: **implemented and run in both lanes on desktop — bare 75 / 0, live 81 / 0, both exit 0; the panel through the push buttons' own signal path and the desktop rig's pointer; handback `ada_run/waves_chance_noise/2026-09-12-r4-mushrooms-batch.md` — awaiting Astra's acceptance, a person at the table and a headset walk.** Committed with this handoff (the hash is in the commit that carries it).

Read first: `doc/research/waves-chance-noise/maps/Random_Mushrooms.md` (the card), the handback, the guide's `runtime-captures.html` (every hall's probe captures), `ada_run/waves_chance_noise/Random_Mushrooms/report.md`, `commons/maps/Random_Mushrooms/field_notes.md` (the ruling, the survey, the runtime findings, the rejected ideas).

## What was built

- `mushrooms.gd`: every draw of the build routed through `_rf()` / `_ri()` — with `population_seed` −1 they fall through to the global stream, same call, same order (the shipped meadow unchanged); under a seed a private generator makes them all and the ground's generator takes seed + 1. Bookkeeping on every path (candidates requested, rejected positions, `template` / `kind` / `group` metadata, ring and cluster records, lit lights); a real `apply_grid_config` (`size`, `count`, `density`, `seed`, `stand`); `regrow`, `new_seed`, `set_population_seed`, `set_size_variation`, `show_template`, `cycle_show`, `set_kind`, `cycle_kind`, `instances`, `ground_signature`, `readout_lines`, `get_specimen_state`; the templates freed at exit (fifty-one objects leaked before).
- The opt-in `stand:specimen`: the bed lifted by the ground's amplitude and kerbed; a 1.5 m table at the bed's door-side edge carrying the six templates on numbered discs, a housed six-line plate, SHOW · KIND · SIZE / REGROW · NEW SEED, and a highlight of ring outlines and pins under one template or one kind (scattered, rings, clusters, rejected candidates). Lights capped at twelve.
- Map: `mushrooms:180#stand:specimen#size:6` at (6,7); the dark sphere, the bubbles, the RAND pages and the reaction-diffusion display to the east and south margins; `artifact_placement: map`; `sculpture_clear_rects [[3,1,10,12]]`; `floor_cells [[8,12]]`. Texts revised; final.md in the discovery voice with five excerpts verified; the handoff to Random_Game.
- `commons/testing/probe_wcn_mushrooms.gd` + live port; runner name `mush`; the hall's views on the captures page.

## Pick up here

1. Astra: the room and its texts; the bed's size (six metres: one ring and two clusters by the shipped arithmetic) and the pins' size; the book's hero for the pearl (`reaction_diffusion_intro` now; the map's primary is the meadow) and the pearl's `mushrooms` line ("noise filtered through ecology"), which the card asks the room not to imply.
2. A person: SHOW round the six, KIND round the five, SIZE off and on, REGROW, NEW SEED, REGROW; read the plate after each.
3. A headset walk: the door to the table, the west and south margins, the plate at 0.77 m from a standing eye, the pins across the bed.
4. The next hall on the route: Random_Game — a draw that decides an outcome.

## The next hall's handover — Random_Game

The card (batch R2 in Astra's plan) asks what turns a draw into an event a visitor has to live with: the hall after the arrangement. What R4 hands it: the pattern of a named five-digit seed from a private generator with a REPLAY / NEW SEED pair (R1b, R2, R3, R4 all carry it; a fifth use should extract a shared helper rather than copy the block again); the plate-and-highlight pattern for an arrangement's bookkeeping (above, "one reusable improvement"); the museum's lessons that apply to any hall on this route — the map is the placement authority (`artifact_placement: map` plus rects, and a teleporter's void floored by `museum.floor_cells`), a `0` cell is a hole to the museum, the museum configures a token before `_ready` (store, then build once), any collider seals its footprint and slides a dealt body unless the map holds authority, a push button's `button_pressed` carries one argument, and a readout must be photographed from the visitor's eye. What to survey first in Random_Game: what the dealt lane does to its bodies, whether its primary has any draw a visitor can name and repeat, and whether an outcome, once drawn, is kept anywhere the visitor can read.

## Files

Changed: `algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.gd`, `commons/maps/Random_Mushrooms/{map_data.json, blurb.md, intent.md, summary.md, critical.md, technical.md, tutorial.md}`, `tools/run_wcn_probe.sh`, `tools/port_wcn_probes_live.py`, `tools/check_wcn_w1_source_review.py`, `tools/build_wcn_captures_page.py`, the guide's `runtime-captures.html`. New: `commons/maps/Random_Mushrooms/final.md` (untracked before), `commons/maps/Random_Mushrooms/field_notes.md`, `commons/testing/probe_wcn_mushrooms.gd`, `commons/testing/probe_wcn_mushrooms_live.gd`, `ada_run/waves_chance_noise/Random_Mushrooms/{report.md, probe_mushrooms.json, probe_mushrooms_live.json}`, `ada_run/waves_chance_noise/2026-09-12-r4-mushrooms-batch.md`, the guide's `images/Random_Mushrooms*.jpg`, `doc/space/waves-chance-noise-r4-mushrooms-2026-09-12/` (before-copies, hashes, README; not tracked).
