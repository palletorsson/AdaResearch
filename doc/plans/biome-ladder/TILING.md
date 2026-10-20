# Tiling — one impact makes a pattern

B15 · Codex · 2026-10-13. Fifth playable biome stage. Palle requested keeping scaling, rotation and colour, then letting a shot make a pattern across the floor.

## Play

Game menu → Biome Ladder → **5 TILE**. The optional museum entrance is at the end of **Ribbon_Patterns_03**. MUSEUM continues into **Change_Intro**. The original museum passage remains available.

The same hand sphere and held catalyst shoot the same real projectiles. A tile hit multiplies scale by **0.8**, adds **22.5°** around Y, and takes the ball's colour. In Tiling, it also repeats those changes at the matching address in every **2 × 2** group over the **6 × 12** floor: **18 tiles per impact**.

Any copy can be the next source. Shoot a different copy at that same address and all eighteen advance together to 0.64 scale / 45°. Choose one of the other three addresses to build another part of the pattern. Its turn, scale and colour are independent of the first address.

Skull balls retain their local colour marks. They can interrupt our repeated colour; the next catalyst hit on that motif address reapplies the repeated colour. Heads retain the existing indexed row, motion, slow growing coloured balls and one-hit falling defeat. No extra heads were added in this task.

Every tile's collision follows its visible shrinking and rotation. The continuous backing remains walkable. Hitting the backing or cover makes no pattern through the floor. REST keeps the arrangement; RESET and a new START restore it. Leaving the stage discards the encounter's floor state. Nothing writes these marks into saved player progression.

## What changed

- `commons/hazards/biome_ladder/ladder_encounter.gd`: repeat matching tile addresses in Tiling; share the earlier transform/colour behaviour; fifth stage control and a short in-world instruction. Stage changes are deferred until the button event finishes.
- `commons/hazards/biome_ladder/route.gd`: actual Tiling → Change museum boundary.
- `commons/hazards/biome_ladder/ladder_world.gd`: stage selection follows route length.
- `tools/probes/biome_tiling_floor.gd`: actual input/flight/collision assertions and native before / one-shot / after / overview captures.
- `tools/probes/biome_ladder.gd`, `tools/probes/desktop_biome_catalyst.gd`: include all route stages.
- `tools/publish_biome_ladder_play.py`: fifth stage, report, evidence and planning links.

## Evidence

Godot 4.6 results: **33/33 pattern**, **90/90 earlier tile behaviour**, **67/67 five-stage** and **54/54 desktop** assertions pass, all processes exit 0. Museum entry: **8/8** checks, exit 0.

Read `ada_run/biome_tiling_floor/report.json` for the pattern assertions and source hash. The probe checks the actual fifth-stage console button, all 18 matching copies, two independent motif addresses, cumulative changes, distant tile collision, solid gaps, real player standing in a gap, held-tool input, cover rejection, REST/RESET/START, local skull paint, earlier Colour behaviour, and unlock/callback cleanup. It does not call floor-reaction functions directly.

The screenshots are real Godot 4.6 renders. `after.png` shows two motif addresses after three valid floor impacts: two on one address, one on its neighbour. `overview.png` changes only the camera to show the full repetition. `before.png` and `one-shot.png` use the same standing viewpoint as `after.png`.

Regression reports: `ada_run/biome_transform_tiles/report.json` for Transformation / Arrays / Colour, `ada_run/biome_ladder_play/report.json` for all five stage behaviours, and `ada_run/biome_ladder_play/desktop/report.json` for desktop control and firing. The museum entry report is `ada_run/encounter_pilot/Ribbon_Patterns_03/biome-ladder-entry/report.json`; it checks real mounted entry and staging dispatch, not a headset walkthrough.

Run the rendered pattern probe with the installed Godot executable, project root as `--path`, `--xr-mode off --no-window --rendering-method gl_compatibility --resolution 1440x1000 --script res://tools/probes/biome_tiling_floor.gd`. It isolates progression writes in its output folder. Run museum entry with `python tools/run_encounter_probe.py Ribbon_Patterns_03 --sequence tiling --no-bridges --probe tools/probes/biome_ladder_entry.gd --output-tag biome-ladder-entry --render`.

Headset feel and Quest performance remain untested. Existing ObjectDB shutdown warnings remain. After the museum entry assertions pass, the wider museum cleanup reports freed-object errors in existing colour/glitch artifacts and a leaked mesh RID. These are outside the ladder files; the entry checks are not a clean whole-museum runtime certification. The older menu/death roundtrip shutdown issue is outside this floor change.

## Next review

Claude can review this report and the source/captures, especially whether a change in one place visibly reads as a repeating rule from standing height. The floor part of the B07 proposal is now implemented. Additional copied heads and mirrored cover remain proposals. Change is the next sequence in the spine; agree its one new operation before extending the runtime. No tutorial or final.md was rewritten here.
