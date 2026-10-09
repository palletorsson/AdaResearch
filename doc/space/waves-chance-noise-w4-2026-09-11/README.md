# Waves, Randomness and Noise — batch W4 archive (2026-09-11)

Fable 5.1, on Palle's word to "continue with the Synthesis Lab in the same way" after W3. One hall: **WaveFunctions_Synthesis_Lab**.

## What is here

- `before/` — byte copies taken before the first edit: `additive_wave_demo.gd` and `.tscn`, `slider_horizontal.gd` and `.tscn` (all four scenes/scripts except the artifact's script unchanged in the end), the map (the working tree's, HEAD's as `map_data.HEAD.json`, and the pre-museum layout from c47be1717 as `map_data.c47be1717.pre-museum.json`), its nine texts and `nature_layer.json`.
- `before_sha256.txt` / `after_sha256.txt` — hashes before and after; the after list adds the field notes, the two probes, the driver, the three tools, the report, the handback and the handoff.
- `.gdignore` — so the archived script never competes with the live one for its class name.

## Structure

No structure or utility cell was moved. The map keeps the recovery contract (interior `2` = one-metre platform, perimeter `w`, `museum.wall_height` 3, `gate_depth_rows` 0). Added under `map_info.museum`: `sculpture_clear_rects` [[2,2,6,4],[6,0,8,3],[7,3,7,11],[5,10,8,13]], `props_deny: ["bench"]`, `artifact_placement: "map"`.

## Placement

`additive_wave_demo:0:0.5#waveform:sawtooth` at (2,6) → `additive_wave_demo:0#stand:bench#waveform:sawtooth` at (4,2). `lissajous_curves:0:1:0.1` (5,2) → (2,6); `seismograph` (6,2) → (2,8); `record_room:0:0` (6,3) → `record_room:-90:0` (12,2); `GlassRack:0:0.8#config:spiral_tube` (8,2) → (2,4). Nothing else moved.

## The artifact

`additive_wave_demo.gd` gained an opt-in `stand` axis (`bench`); `none` shows what it showed. The draw loops now pass through one emitter (`_emit_strip`), a line strip at half-thickness 0 — identical output, a shared refactor flagged for Astra. No repair to any shipped behaviour.

## Reversal

Copy the `before/` files back over their originals (the `.gd`, the map, the texts); delete `field_notes.md`, the two probes, the report, the W4 batch file and the handoff; remove the `synth` line from `tools/run_wcn_probe.sh`, `synthesis_lab` from `tools/port_wcn_probes_live.py`, the Synthesis Lab row from `tools/check_wcn_w1_source_review.py`, and `press_down`/`release`/`drag`/`ray_report`/`inspect_control` and the camera-iterated aim from `commons/testing/wcn_desktop_driver.gd`.

## Runtime

Both lanes ran on 2026-09-11, 09:20–09:52, in the gaps between another session's museum autopilot runs (the runner refused beside each; nothing terminated): bare 84 / 0 (five attempts), live 93 / 0 (five attempts). Open: Godot exits 127 at application quit after the JSON is written (AirMusic's class).
