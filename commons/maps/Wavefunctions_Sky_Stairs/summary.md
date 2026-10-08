# Current hall: what a curve needs from a stair

The primary `sine_cylinder_staircase` builds one helix of eighty treads. With the shipped scene parameters, the tread top rises by 0.11 per sample while the radius is `2.5 + 0.45 * sin(2 * angle)`. The angle completes two turns. This is radial modulation with uniform rise, not three parallel staircases or a sine-shaped height profile.

The default `membrane` provision joins neighbouring tread edges with visible quads and matching colliders, lifted by the configured 0.3 offset. Other source options are `none`, `rail` and `posts`; they change the provision around the same sampled path. The chapter begins with three visible treads inspected from the surrounding floor. Treads and colliders alone do not establish a complete ascent, suitable headroom or headset comfort. `math_objects`, `cube_scene` and `dark_sphere` remain in the hall; their presence does not implement the floating wave-density field described in the earlier proposal. See [the chapter](final.md) and `algorithms/wavefunctions/sine_cylinder_staircase/sine_cylinder_staircase.gd`.

## Archived design proposal

The text below is preserved from an earlier design. Its three staircases, variable-rise climb, altitude chart and wave-density cube fields are proposals, not descriptions of the current hall. Its code is illustrative, not an extract from the shipped artifact. Full walking and headset claims remain unverified.

---

# Wavefunctions Sky Stairs — Summary

Climbing a staircase is already tracing a waveform: each step is a sample, the tread is the period, the height is the amplitude. This map takes that metaphor literally. A tall vertical amphitheatre launches the learner up through open space. Stairs spiral around the central column in a helix whose step heights follow a sine curve.

Three staircases climb in parallel, each bound to a different function. One follows sin, another cos, a third a higher-frequency harmonic. The three diverge and converge at predictable intervals, so the phase relationship is visible as a spatial gap between the treads.

Floating cube fields drift at different altitudes around the tower, sampling the wave equation at that height. Their density thins with elevation and thickens at the nodes. A reference panel at the landing reads out your current height as a value of sin(angle), where angle is the distance traveled around the helix.

Within the sequence, Sky Stairs returns to embodied wave experience after the conceptual pause of Cage and AirMusic. Where Sine_Space put the wave under your feet horizontally, this map puts it under your feet vertically and asks you to climb it.
