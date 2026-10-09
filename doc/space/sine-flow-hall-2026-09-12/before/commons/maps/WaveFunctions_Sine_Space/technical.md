# SineWallCorridor: what changes between two walls

This chapter describes the primary `algorithms/wavefunctions/sine_wall/SineWallCorridor.gd` and its placed scene. The map puts the corridor at (6,4), rotated 90 degrees, along the antechamber. The scene is 8 m long, 2 m wide and 4 m tall, with 200 columns and eight rows per wall. Its AMP and PHASE sliders change amplitude and the offset between walls; FREEZE toggles running phase and RESET restores the declared settings.

## A coordinate produces a displacement

```gdscript
offset += base_amplitude * amp_multiplier * amp_mul * sin((base_frequency * freq_multiplier * freq_mul) * z_norm * PI + phase_shift + phase_layer)
```

This is the contribution of one layer in `_wave_displacement`. `z_norm` spans -1 to 1 along the corridor. The fundamental makes 4.5 spatial cycles in 7 m (8 m and 5.2 until the first museum run on 2026-09-10, when the east mouth stood in the bridge head's cell), giving a wavelength of about 1.54 m. The other layers multiply spatial frequency by 1.8 and 2.6, amplitude by 0.35 and 0.18, and add their own phase offsets. Spatial wavelength is length divided by the number of cycles; it is not a rate in hertz.

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

AMP ranges from zero to 0.45 m. At zero the displacement vanishes; the colour calculation guards its denominator so a flat wall has finite colours. At maximum amplitude and zero offset the sampled crosswise gap is roughly 0.7 m at its narrowest, depending on running phase. The readout prints `x-gap` to name its measurement.

## Rendering and collision are separate operations

The script emits triangles between sampled columns, generates normals and assigns material. Eight rows are sufficient to sample the unchanged vertical profile more economically than the former 64; their actual visual and frame-time quality has not been measured in this review. Fabric variants skin, ribs, strata and lattice choose which quads survive. They do not change the displacement equation.

```gdscript
if not enable_collision:
	shape_node.shape = null
	return
```

The placed scene leaves collision off. The corridor floor is a visual plane; the museum deck supplies physical support. Crossing a visible crest is therefore part of the current experiment. Collision-enabled variants would require a deliberate room-placement and walk-planning review. No dynamic collidable corridor is claimed here.

The entrance panel is marked `em_local_instrument`. Standalone camera, directional light and environment are removed when embedded; the local fill light remains. RESET restores amplitude, offset, phase, animation state and slider handles. The panel is opt-in for uses of the script, and enabled in this placed scene.

The separate sine_space artifact remains in the basin. Its product of two sine terms samples a surface: equal-sign factors produce positive height, opposite signs negative height. Its topology variants and animation are implemented in its own script; the corridor's controls do not control that floor. The two smaller explanation cases provide further comparisons.

The physical probe checks the actual museum placement, controls, phase identity, zero amplitude, gap values and routes. It remains unrun, so source geometry and the visible-only contract should not be mistaken for a completed headset test.
