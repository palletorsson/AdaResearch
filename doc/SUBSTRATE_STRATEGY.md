# Substrate Strategy — 13 Formats to Carry 1430 Artifacts

## The Discovery

We classified 1700 artifacts by structural fingerprint — what they actually ARE, not what algorithm they teach. The result: most artifacts that look unique are structurally identical. 274 artifacts build geometry in `_ready()` with no interaction. 86 run a stepped simulation with label readouts. 43 put a ShaderMaterial on a mesh.

These aren't 1700 unique formats. They're ~13 substrates with algorithms plugged in.

## What Is a Substrate?

A substrate is a reusable display format. It handles:
- Environment (lighting, background, ground plane)
- Camera (capture angle, VR viewing position)
- Interaction (grab zones, buttons, sliders)
- Display (mesh, particles, lines, labels)
- Configuration (`apply_grid_config` for map placement)

The algorithm is a cartridge that plugs into the substrate. Living Paper is the proof: one scene file, 34 algorithms, each a different `SortMode` or `WalkMode` enum.

## Existing Substrates (7)

| Substrate | Scene | Artifacts | Algorithm interface |
|---|---|---|---|
| **living_paper** | `commons/substrates/living_paper/living_paper.tscn` | 34 | Grab to run, algorithm enum selects cartridge |
| **mesh_grammar** | `commons/mesh_grammar/mesh_grammar_node.tscn` | 21 | Growth rules as grammar, different rule sets |
| **profile_curve** | `commons/substrates/profile/profile_substrate.tscn` | 17 | 1D function generates extruded edge shape |
| **step_sequencer** | `commons/audio/sequencer/step_sequencer.tscn` | 15 | Grid pattern selects audio sequence |
| **grid2d** | `commons/substrates/grid2d/grid2d_substrate.tscn` | 11 | 2D CA rules as step function |
| **bar_array** | `commons/substrates/bar_array/bar_array_substrate.tscn` | 10 | Sort/histogram algorithm as comparator |
| **grid3d** | `commons/substrates/grid3d/grid3d_substrate.tscn` | 9 | 3D graph algorithm as traversal function |

**Total: 117 artifacts on 7 substrates.**

## Proposed New Substrates (6)

### 1. procedural_builder (would cover ~274 artifacts)
**What:** Node3D that builds geometry in `_ready()`. No interaction, no labels, just procedural construction.
**Standard additions:** Environment scaffold, capture camera hint, optional ground plane, `@identity` block template.
**Algorithm interface:** Override `_build()` method. Return mesh/node tree.
**Examples:** Most Nature of Code translations, many geometry demos, floor patterns.

### 2. scene_composition (would cover ~133 artifacts)
**What:** .tscn-only artifacts — no GDScript, composed in Godot editor.
**Standard additions:** Consistent WorldEnvironment, standard lighting rig, CaptureCamera node.
**Algorithm interface:** None — these are spatial arrangements of existing nodes.
**Examples:** GPU particle presets, transform demos, gallery arrangements.

### 3. stepped_algorithm_viz (would cover ~86 artifacts)
**What:** Step button advances algorithm one iteration. Label3D shows state. Visualization updates.
**Standard additions:** Step button (push_button.tscn), iteration counter label, state readout, reset button.
**Algorithm interface:** Override `_step()` -> returns new state. Override `_visualize(state)` -> updates display.
**Examples:** Sorting algorithms, graph traversals, CA steps, pathfinding.

### 4. shader_canvas (would cover ~86 artifacts)
**What:** ShaderMaterial on a mesh surface. May be static or animated.
**Standard additions:** Standard mesh (plane or cube), lighting rig, parameter pass-through via `set_shader_parameter()`.
**Algorithm interface:** Provide a `.gdshader` file. Parameters exposed as uniforms.
**Examples:** Noise visualizations, Gaussian effects, reaction-diffusion, book-of-shaders translations.

### 5. control_station (would cover ~42 artifacts)
**What:** Full interactive panel — sliders control parameters, buttons trigger actions, labels show state.
**Standard additions:** Slider rack (from `slider_horizontal.tscn`), button panel, readout labels, visualization area.
**Algorithm interface:** Override `_on_parameter_changed(name, value)`. Override `_get_readouts() -> Dictionary`.
**Examples:** Force-directed layout, noise mixer, distribution sampler, terrain editors.

### 6. line_trail_viz (would cover ~31 artifacts)
**What:** ImmediateMesh line drawing with Label3D annotations. For graph algorithms and traced paths.
**Standard additions:** ImmediateMesh setup, trail material (emissive, alpha-fading), node markers, edge labels.
**Algorithm interface:** Override `_compute_nodes() -> Array[Vector3]`. Override `_compute_edges() -> Array[Edge]`.
**Examples:** Graph algorithms, pendulum trails, orbit paths, force vectors.

**Total: ~652 artifacts on 6 new substrates.**

## Combined: 13 Substrates, 1430 Artifacts

| Substrate | Artifacts | % of project |
|---|---|---|
| procedural_builder | 274 | 16.1% |
| scene_composition | 133 | 7.8% |
| living_paper | 34 | 2.0% |
| stepped_algorithm_viz | 86 | 5.1% |
| shader_canvas | 86 | 5.1% |
| continuous_animation | 124 | 7.3% |
| control_station | 42 | 2.5% |
| mesh_grammar | 21 | 1.2% |
| profile_curve | 17 | 1.0% |
| step_sequencer | 15 | 0.9% |
| grid2d | 11 | 0.6% |
| bar_array | 10 | 0.6% |
| grid3d | 9 | 0.5% |
| line_trail_viz | 31 | 1.8% |
| has_labels (static) | 108 | 6.4% |
| tiny/minimal | 46 | 2.7% |
| **SUBTOTAL** | **1047** | **61.6%** |
| Remaining unique | 653 | 38.4% |

## Implementation Priority

1. **procedural_builder** — highest coverage, simplest to build (just a standard environment wrapper)
2. **stepped_algorithm_viz** — highest teaching value (the "textbook figure" format)
3. **control_station** — highest interactivity (the "lab bench")
4. **shader_canvas** — highest visual impact (living materials)
5. **line_trail_viz** — already proven pattern (from joint demo trails)
6. **scene_composition** — just needs standardized .tscn template

## How This Changes the Work

Before substrates: improve 1700 artifacts one by one.
After substrates: build 6 substrate templates, then migrate artifacts into them.

Migration for each artifact:
1. Classify its structural fingerprint
2. Match to substrate
3. Extract the algorithm code (the cartridge)
4. Plug into substrate with standard config
5. Verify screenshot shows the algorithm clearly

The substrate handles visual quality (glow, labels, interaction, capture). The algorithm just needs to compute.
