# Waves, Randomness and Noise — batch W3 archive (2026-09-11)

Fable 5.1, from the "What comes next" of `doc/book/handoffs/fable-wcn-w2-completion.md`, on Palle's word to continue. One hall: **WaveFunctions_AirMusic**.

## What is here

- `before/` — byte copies taken before the first edit: `ResonatingMetallophone.gd`, `ResonatingBar.gd`, `CombinedWaveVisualizer.gd`, the two resonance scenes (unchanged in the end), `commons/audio/systems/air_points/FMPianoSynth.gd` (from HEAD), the map and its nine texts.
- `before_sha256.txt` / `after_sha256.txt` — hashes before and after; the after list adds the field notes, the two probes and the port, and the three tools.
- `.gdignore` — so the archived scripts never compete with the live ones for a class name.

## Structure

No structure or utility cell was moved. The map keeps the recovery contract (interior `2` = 1 m platform, perimeter `w`, `museum.wall_height` 3, `gate_depth_rows` 0). Added under `map_info.museum`: `sculpture_clear_rects` [[3,8,8,10]] and `artifact_placement: "map"`.

## Placement

`resonating_metallophone` → `resonating_metallophone:0#stand:table`, still at (5,9). Nothing else moved.

## Repairs to shipped artifacts (every placement changed; for Astra)

The striker recognised by ancestry and a strike zone (`ResonatingBar.gd`); the note 2.5 decays long, ending with the glow; the visualiser finding its bars; `FMPianoSynth` joining its worker tasks at exit.

## Reversal

Copy the `before/` files back over their originals; delete `field_notes.md`, the two probes and the port, the report and the W3 batch file; remove the `air` line from `tools/run_wcn_probe.sh`, `air_music` from `tools/port_wcn_probes_live.py` and the AirMusic row from `tools/check_wcn_w1_source_review.py`.

## Runtime

Both lanes ran on 2026-09-11, 08:20–08:41 (bare 52 / 0, live 55 / 0 at the end of six attempts). Open: a nondeterministic signal 11 at application quit after this hall has been built (`probe_wcn_air_shutdown.gd` bisect: two clean of six), never during the museum's own free and rebuild.
