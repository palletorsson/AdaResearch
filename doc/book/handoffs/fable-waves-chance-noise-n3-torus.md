# N3 — Noise_One: the pair (Fable, 12 September 2026)

Astra's card asked for a matched colour-only and relief reading of the same field on the same support; a local time freeze and a sample marker revealing coordinate and value, with both the displacement sampling and the independent hue motion frozen; relief amplitude exposed separately from frequency; the ring opening preserved over the beginner range; and a disclosure of whether extreme deformation changes only appearance or actual collision.

## What was there

`noisetorus.gd` had already had a careful pass: a `readout` axis (relief / plate / none), both speeds exported as instruments, a `stray_planet` switch for the debris prism floating 7 m above the ring, and a documented legacy early return. What it did not have was a comparison. One ring showed both readings at once, so nothing in the room could separate the field from the reading of it. The ring also stood at (5,5), in the middle of the hall's own five-by-five hole, where no visitor can stand near it, and the hall's description promised octave summation and a VR brush that this room does not contain.

## What it is now

`#stand:pair` builds two rings on one bench at (5,2), turned to face the hall's door:

- **Same field, two spendings.** Same size, same shader, same noise scale; `show_relief` and `show_colour` (new uniforms, both 1.0 by default, so the shipped picture is unchanged) let each ring show one reading and only one.
- **A marker on the same coordinate of both**, and a plate naming the coordinate, the field's value there, the relief in metres and the colour's brightness.
- **The finding.** The field runs from −1 to +1. The relief spends all of it; the colour clamps the negative half to black, because `ALBEDO` has no negative. Half the field is invisible in colour and legible in relief. Measured at a sampled coordinate: value −0.562 → relief −0.011 m, colour 0.000.
- **FREEZE stops both clocks**, which is the point: one slides the sample coordinate, the other rotates the hue.
- **AMPLITUDE against FREQUENCY.** One is a reading and leaves the value alone; the other is the field and changes which value is at the coordinate. The plate names which was touched last, in those words.
- **No collider on either ring.** The corrugation is in the vertex stage. The plate says so.

## Evidence

| lane | result |
|---|---|
| bare (`run_wcn_probe.sh torus`) | 32 checks, 0 failures |
| live (`run_wcn_probe.sh torus live`) | 37 checks, 0 failures, exit 0 |

The claim that both readings use one value is a fact about the shader, so the probe reads the shader source: the vertex and the fragment build the noise input from the same expression, both spend the same `noise_value`, and every `TIME` reaches an output only through one of the two speed uniforms. That last check was wrong on its first pass — it required the speed on the same line, which called the shipped `wrapped_time = mod(TIME, 3600.0)` unfrozen when its only use is `wrapped_time * noise_speed`. It follows the variable now. With both speeds zeroed the sampled value holds across 1.2 s, measured; amplitude changes the relief with the value unmoved; frequency moves the value.

## Map changes

- `noisetorus` from (5,5) to (5,2) as `noisetorus:180#stand:pair` — out of the hall's hole and onto the north strip.
- `museum.artifact_placement: "map"` and `sculpture_clear_rects [[3,1,8,4]]`.
- The description rewritten. The probe does not check this one (it checks the shader instead), but the old text named things this room does not contain.

## Three sizes are the pair's own

The shipped `height_multiplier` 0.2 and `noise_scale` 3.575 are for a torus of radius 1.8. At 0.46 m that amplitude is a third of the tube radius (the surface folds through itself and photographs as crumpled paper) and that frequency puts one noise cell across the whole ring. It took three iterations: scale the amplitude, widen the tube from 0.10 to 0.14, then lower the frequency again because the relief is sampled per vertex and a field finer than the mesh aliases into spikes. The mesh is 96 × 40 now. This is the same fault Noise_Columns paid a run for, in different units, and it is now written down in both rooms' field notes.

## Not done, said plainly

- No headset walk. The one thing a probe cannot do for this room is step sideways, which is how a visitor separates a change of viewpoint from a change of field.
- The plate's value is the room's own port of the shader's hash, computed in 64-bit where the card computes in 32-bit; the last digits of a very chaotic hash differ. What the plate claims is the field's value at a coordinate, a definition rather than a screenshot.
- The hall's other two artifacts (`noiselayers`, `dark_sphere`) still stand over the hole; not this pass's to move.
- Astra's review.

## Files

`algorithms/randomness/noisetorus/noisetorus.gd`, `commons/resourses/shaders/noiseTorus.gdshader`, `commons/maps/Noise_One/map_data.json`, `commons/maps/Noise_One/{final,summary,technical,tutorial,field_notes}.md`, `commons/testing/probe_wcn_torus.gd` and its live port, `tools/run_wcn_probe.sh` and `tools/port_wcn_probes_live.py` (the `torus` case), `tools/build_wcn_captures_page.py` (N3's views), and the captures page rebuilt and published. Forum: 260912-wenml.
