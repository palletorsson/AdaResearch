# Noise Columns — a driver needs a recipient

This follows Random_Noise_Types' spatial samples, height/colour mapping and temporal filters. Noise_One follows with two surfaces reading one field as relief and colour. The room contains three authored artifacts: MeltingBerniniScene, dark_sphere, and synthesis_stand configured with the dark-sphere family. All three have primary book passages.

## One scalar, a whole shaft

The placed MeltingBerniniScene uses `stand:trio`, `speed:0.9` and `seed:31415`. The three drivers are dealt among the slots from the seed and stay unnamed until REVEAL. BASELINE is a constant 0.10; PERIODIC returns `sin(t * melt_speed) * 0.5 + 0.5`; FIELD remaps and clamps `_noise.get_noise_2d(t * 0.55, 0.0)`. The field is FastNoiseLite TYPE_SIMPLEX at frequency 0.35, with the resource's existing fractal settings. It is not a per-vertex 3D Perlin erosion process.

The sine has period TAU/0.9, approximately 6.98 seconds. A finite trace can show unequal intervals between the sampled field's peaks; it cannot prove that noise never repeats. Given unchanged seed, settings and coordinates, the implementation repeats its samples. The seed also fixes the slot assignment, so the assignment can be learned across visits.

All three shafts use the same mesh function. With 40 vertical segments and 16 radial segments, it creates 697 vertex entries and 1,280 triangles. Each longitudinal value v receives:

```gdscript
var melt_factor = pow(v, 0.5) * melt_strength * melt_phase
var height = v * column_height - melt_factor * 2.0
```

The top, v=1, is lowered by twice melt_strength times phase: 0.70 metres at phase 1. The phase also changes a sinusoidal bulge. Other spiral, rib and offset terms already shape the baseline. A common phase yields an identical shaft mesh, but an instantaneous shape alone does not identify which driver supplied it. Matching individual scalar samples is not matching whole histories.

Rebuilding from saved parameters is not an inverse deformation. The code does not establish a bijection or preserved embedded topology. For example, the square-root height rule can pull an early ring below the base at larger phases. Triangle indices remain the same while a surface can fold or intersect. No load-bearing column collision is implemented.

## Clocks and materials

FREEZE holds the trio's time and stops scheduled shaft rebuilding. SPIN uses frame delta independently, so a frozen shape can still be turned deliberately. Moving shafts rebuild at most 12 times per second; the held shaft is not rebuilt after construction. The readout now reports the phase stored with the displayed mesh, rather than evaluating a newer phase between rebuilds. Frame cost is a measurement of the review machine, not a Quest performance guarantee.

The shaft marble shader already takes `u_time`. Bases and capitals use `displacement.gdshader`, which previously read global shader TIME and kept moving under FREEZE. That shared shader now offers opt-in `use_local_time` and `local_time` uniforms. Default consumers continue to use TIME. Only the trio opts in: the held column uses zero, and the other two use the trio clock. The accessory vertex displacement remains present and participates in the local pause.

MARBLE swaps the shaft's veined fragment material for a matte material. It does not remove the bases' and capitals' separate shaders. The shaft marble shader performs no vertex displacement, so that swap leaves its geometry intact. FREEZE therefore holds all these clock inputs; MARBLE isolates the shaft's appearance specifically.

## Two existing dark-sphere bodies

The standalone orb retains its witness/orb settings. Its own `_time_elapsed` advances independently of the trio, driving rotation, a small angular wobble, emission and albedo pulses, a widening kin ring, and halo opacity. The sine drives appearance; it does not deform sphere vertices. In this hall `_gest_stage()` is empty, so the book promises no catalyst hatching interaction.

The synthesis stand reads the saved dark_sphere verdict: presence=hush, body=swarm. It sets both exports before adding the scene to the tree. The swarm constructor creates six small orbs, with alternating heights, inside a rotating parent. There is no neighbour sensing or agent steering here. The saved score is selection metadata; it is not an objective measure of artistic worth.

The stand moved from (2,9) to (3,4), facing the entrance, with a reserved approach so an automatically placed sculpture cannot conceal it. The three authored works and recovered structure remain. A straight three-metre-wide local passage declaration addresses the earlier route mismatch without changing other halls' passage code.

## Evidence and limits

See `doc/space/columns-review-2026-09-13/README.md` for the accepted run, failed first run, captures, source hashes, pointer checks, full vertex-array comparison and passage check. The online review plots values sampled from the actual Godot driver functions. Its slider is a browser review tool, not an invented in-game control. Headset reach, comfort and Quest performance remain deferred.
