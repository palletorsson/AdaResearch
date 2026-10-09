# SineWallCorridor: what changes between two walls

This chapter describes the primary `algorithms/wavefunctions/sine_wall/SineWallCorridor.gd` and its placed scene. The map puts the corridor at (6,10), rotated 90 degrees, along the antechamber. The scene is 7 m long, 2 m wide and 4 m tall, with 200 columns and eight rows per wall. Its AMP and PHASE sliders change amplitude and the offset between walls; FREEZE toggles running phase and RESET restores the declared settings.

## A coordinate produces a displacement

```gdscript
offset += base_amplitude * amp_multiplier * amp_mul * sin((base_frequency * freq_multiplier * freq_mul) * z_norm * PI + phase_shift + phase_layer)
```

This is the contribution of one layer in `_wave_displacement`. `z_norm` spans -1 to 1 along the corridor. The fundamental makes 4.5 spatial cycles in 7 m (8 m and 5.2 until the first museum run on 2026-09-10, when the east mouth stood in the bridge head's cell), giving a wavelength of about 1.56 m. The other layers multiply spatial frequency by 1.8 and 2.6, amplitude by 0.35 and 0.18, and add their own phase offsets. Spatial wavelength is length divided by the number of cycles; it is not a rate in hertz.

The caller supplies `phase` as `phase_shift` for the left wall and `phase + phase_offset_between_walls` for the right. The running phase contributes once. At 0.35 rad/s, the sum repeats at a fixed position after `TAU / 0.35`, about 17.95 s. Each layer's spatial velocity differs because the same temporal phase rate acts on a different spatial frequency. The moving sum is not a rigid translation of the frozen sum.

## Two displacement fields make a passage

```gdscript
var base_x: float = side * half_width
var x_pos: float = base_x - side * displacement
```

The left wall has side -1 and the right side +1, so positive displacement moves either inward. This scene gives both walls equal frequency and amplitude multipliers. At PHASE zero their inward displacements agree. At PHASE π, every right-wall sine changes sign, and the two displacements cancel in the gap calculation:

```gdscript
return corridor_width - float(d[0]) - float(d[1])
```

`gap_at` measures separation along local X between matching Z positions. `gap_range` samples the same columns as the mesh. At π it returns the declared 2 m width everywhere, even as the corridor bends. This does not establish constant shortest or normal clearance between the walls, or physical traversability for a particular body.

AMP ranges from zero to 0.45 m. At zero the displacement vanishes; the colour calculation guards its denominator so a flat wall has finite colours. At maximum amplitude and zero offset the sampled crosswise gap reaches its narrowest, 0.725 m, at running phase zero: measured across all 720 states the panel can reach (five amplitudes, nine offsets, sixteen running phases), and at that state the true shortest distance between the two wall curves is the same 0.725 m. The readout prints `x-gap` to name its measurement.

## Rendering and collision are separate operations

The script emits triangles between sampled columns, generates normals and assigns material. Eight rows are sufficient to sample the unchanged vertical profile more economically than the former 64; their actual visual and frame-time quality has not been measured in this review. Fabric variants skin, ribs, strata and lattice choose which quads survive. They do not change the displacement equation.

```gdscript
if not enable_collision:
	shape_node.shape = null
	return
```

The placed scene leaves collision off. The corridor floor includes a 24 mm colliding slab above the museum deck; it supplies physical support. Crossing a visible crest is therefore part of the current experiment. Collision-enabled variants would require a deliberate room-placement and walk-planning review. No dynamic collidable corridor is claimed here.

The entrance panel is marked `em_local_instrument`. Standalone camera, directional light and environment are removed when embedded; the local fill light remains. RESET restores amplitude, offset, phase, animation state and slider handles. The panel is opt-in for uses of the script, and enabled in this placed scene.

The separate sine_space artifact remains in the basin. Its product of two sine terms samples a surface: equal-sign factors produce positive height, opposite signs negative height. Its topology variants and animation are implemented in its own script; the corridor's controls do not control that floor. The one remaining explanation case in the west nook provides a further comparison.

The physical probe checks the actual museum placement, controls, phase identity, zero amplitude, gap values and routes. The generated live probe tests desktop input and route geometry; that evidence should not be mistaken for a completed headset test.

### Measured on 2026-09-13

**Clearance across the exposed range.** Every combination of AMP (0 to 0.45 m in five steps), PHASE offset (0 to π in nine) and running phase (sixteen through a turn) was evaluated on the script's own displacement function. Two numbers came from each state: the local-X gap the readout prints, and the true shortest distance between the two wall curves, which can be smaller wherever the walls slope. The search window was sized per state so the result is exact. Both minima are 0.725 m, at full AMP with the walls in step and running phase zero. A 0.44 m body fits between the surfaces it sees at every state the panel can reach.

**The actual player collider.** The desktop rig's own CharacterBody3D was walked through the passage at the narrowest setting the panel reaches. It went 7.5 m east, and every slide contact was recorded: 79 against the corridor's FloorBody and 8 against the hall's floor, all with an upward normal. Nothing of the corridor pushed it sideways.

**Changes reach the mesh and leave no collider.** AMP and PHASE were dragged, and FREEZE and RESET pressed, through the desktop pointer. After each, both wall meshes were fingerprinted and every live collision shape under the corridor was counted:
- frozen, neither mesh changed over twenty frames;
- AMP (0.20 to 0.34 m) changed both meshes;
- PHASE (0.60 to 1.89 rad) changed the right wall's mesh and left the left wall's exactly as it was;
- the collider census was `FloorBody/FloorShape:BoxShape3D` before, after the changes and after RESET, with no wall shape at any point.

**The running animation's cost.** While running, `_process` rebuilds both walls through SurfaceTool every frame, about 8,400 vertices each. On this desktop that took 9 to 12.5 ms a frame across runs, roughly 55 to 75% of a 60 Hz frame. A headset's mobile CPU is several times slower, so this is a likely frame-budget problem there. It has not been measured on a headset, and nothing about it was changed: the scene is placed in eight maps, and a throttle or a vertex-shader version would change how the walls move in all of them.


## The forecourt: give the sine a collision surface

Start with `sine_flow_tray` at (3,4). Predict what leaves, press RELEASE, then change only SIZE and repeat. RESET before changing RELIEF. RULE comes after the observation. This is a separate artifact from the recorded four-tray article apparatus; it has one stationary surface and a smaller control set.

```gdscript
samples.append(sin(TAU*0.9*x) * sin(TAU*0.9*z))
```

This expression fills a 21 by 33 vertex array across 2 by 3.2 metres. Min/max normalisation maps it into [0, relief]. Each of the 20 by 32 cells becomes two triangles. The collision shape is constructed from the resulting mesh:

```gdscript
collision.shape = mesh.create_trimesh_shape()
```

The surface is fixed at twenty degrees about local X. Every release creates 32 spheres in the same four-column, eight-row arrangement at local height 1.1 m. Radii are 0.045/0.075/0.105 m; mass remains 0.1 kg, so scaling does not preserve density. Explicit linear/angular damping is 0.05, sphere/terrain friction 0.45, bounce zero, gravity inherited from the project (9.8 m/s² in the checked run). Spheres collide with one another.

An outlet crossing occurs when a sphere centre passes local z=1.6 by more than its radius. Side, back and below-tray exits are classified separately before this test. Departed bodies freeze, stop colliding, and move to the collection display. At 12*physics_ticks_per_second the remaining bodies freeze too. The declared counter includes the activation tick; this is a finite observation window, not a settling detector. The full source is `commons/artifacts/sine_flow_tray/sine_flow_tray.gd`.

SIZE resets the batch without changing any height sample. RELIEF rebuilds the heightfield and resets the batch. RESET restores the declared middle radius/relief and hides RULE. RELEASE always replaces the previous batch, so at most 32 trial spheres are active. The side console sits at standing hand height; its tilted readout and transparent side guards keep the surface visible.
