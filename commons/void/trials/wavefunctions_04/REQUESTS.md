# wavefunctions_04: shared-adapter requests (Claude Opus, batch 23)

**State (final).** Codex installed four trial-scoped adapters, and the native probe now
**requires** each of them. No source file was changed.

| Request | Adapter | Native proof |
|---|---|---|
| R1 | GlassRack `config_file` before ready | spiral_tube: 2 meshes; fractional_distillation: 40 meshes; no coffee-rack frame |
| R2 | `air_music_case_local.gd` | real VOLUME pointer drag, −12 → −40 dB on every voice |
| R6 | `metallophone_local.gd` | table bars frozen instead of the six axis locks Jolt rejects; held-tip strikes pass in both modes |
| R7 | `math_gallery_local.gd` | grab layer 3 for the twelve layer-1 source pickables; 33/33 on grab layers; aimed Trefoil and wrapped-surface grabs pass in both modes |

R6 and R7 were found during testing and fixed by Codex; they are not written up below.
R3–R5 stay open for curation. The text below is the original request, kept as written.

I edited no shared runtime. Both defects below are in the **source artifacts**, and the
source museum shows them too: they are not transfer regressions. Both requests are narrow
and scoped to the trial id. The probe adapts to either state (defect present or adapter
active), so they can land while tests run.

## R1. GlassRack: `#config:<name>` is never read

**Evidence (static, to be confirmed in native `checks.json`):**
- `GlassRackController.apply_grid_config` reads only `glass_color`, `liquid_color`,
  `show_liquid` and `admission`.
- `TurtlePipeBase.apply_grid_config` reads `segment_length`, `pipe_radius`, `path` and
  `config_file`.
- No reader takes `config`.
- `GlassRack.tscn` ships `auto_build = true` with
  `config_file = "breaking_bad_coffee.json"`. Both AirMusic racks therefore build the
  coffee rack: a 0.4 x 0.3 x 0.8 m frame with five vessels. They should build
  `spiral_tube.json` (`f1_GlassRack_3_12`) and `fractional_distillation.json`
  (`f1_GlassRack_14_12`). Neither of those has a frame.

**Exact request.** In `commons/void/floor_content.gd`, before `add_child`, with the other
pre-ready config stamping:

```gdscript
if trial_id == "wavefunctions_04" and item.artifact == "GlassRack" and item.get("config", {}).has("config"):
	artifact.config_file = str(item.config["config"]) + ".json"   # TurtlePipeBase._ready loads it
```

- **Why pre-ready.** `TurtlePipeBase._ready()` runs `load_config(config_file)` when
  `auto_build` is set, and `load_config` resolves bare names under
  `res://commons/glass_rack/configs/`. Setting the property also keeps the probe's
  detection simple: it compares `config_file` with the token.
- **Alternative.** After ready, call `artifact.load_config(name)`. That builds on top of
  the coffee rack unless its children are cleared first, so I do not recommend it.
- **Decision for you or Palle.** This makes the Void rack differ from the museum, which
  also shows the coffee rack, and match the token instead.

## R2. Display case VOLUME slider is dead

**Evidence (static, confirmed by introspection in the probe):**
- `air_music_display_case.gd` makes
  `_volume_slider.slider_moved.connect(_on_volume_changed)`, and `_on_volume_changed()`
  takes 0 arguments.
- `slider_horizontal.gd` emits `slider_moved.emit(position)` with 1 argument.
- A real drag would therefore print a call-arity error and never reach `FMPianoSynth`.
- The probe does **not** drag it, because the error line would fail the native wrapper.

**Exact request.** After the artifact's `_ready` (it creates `_volume_slider` there):

```gdscript
if trial_id == "wavefunctions_04" and item.artifact == "air_music_display_case":
	var s: Node = artifact.get("_volume_slider")
	if s != null and s.slider_moved.is_connected(artifact._on_volume_changed):
		s.slider_moved.disconnect(artifact._on_volume_changed)
		s.slider_moved.connect(artifact._on_volume_changed.unbind(1))
```

- **Better fix for the source owner.** Change the one source line to
  `func _on_volume_changed(_value = null) -> void:`. That fixes all nine placements, but
  it is a source edit, so I did not make it.
- **What the probe does once the adapter is active.** It drives the slider API to 0.25
  and expects `FMPianoSynth.volume_db == -30` (labelled API, not a drag).

## Not requested now (recorded for curation)

- **R3. Staircase vs the upper slab.**
  - `sine_cylinder_staircase` rises 8.69 m (80 treads x 0.11 m). The storey's clear
    height is 5.64 m.
  - Its upper treads pass through the floor-1 slab and stand up to 2.7 m into floor 1,
    in a ring footprint I kept clear of floor-1 placements.
  - A true two-storey stair needs a slab opening, which would be an architecture change.
    I did not shrink or cut the stair.
- **R4. Source plinths are not built.** These works sit on 1 m `structure` blocks in the
  source:
  - Sky Stairs `cube_scene` and `dark_sphere`.
  - Sky Stairs `math_objects`, on a 3 x 9 m platform.
  - AirMusic `dark_sphere`.

  Token heights are kept, as in earlier batches, so the math gallery's 33 pickables lie at
  floor level.
- **R5. Shared audio.** Both `FMPianoSynth` instances (the standalone work and the one in
  the display case) are non-positional `AudioStreamPlayer`s on an `FMPianoReverb` bus that
  the source creates at runtime. The drone rack adds its own dedicated bus too. That is
  source behaviour; I changed no audio settings.
