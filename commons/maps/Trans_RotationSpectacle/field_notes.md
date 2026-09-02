# Trans_RotationSpectacle — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The tunnel

Palle (2026-09-02): "I want the tunnel in the scene now, to the side, in the
wall." Moved from r4 c11 to r4 c12 (the east edge) through
`/api/maps/cell-edit`, which refused nothing. `booleanTunnel.gd`: 18 segments,
spacing 3.0, rotation_per_segment 10° about z (the corridor axis), accrual
default `ramp`; the run is 17 × 3 = 51 m along z from the placement, in a hall
54 rows deep, so it ends about a metre short of the far end. Placed at
y −1.05. Whether "in the wall" means embedded in the museum wall beyond the
map edge is a hall ruling.

## Exactness decisions

- **carousel_cake**: 8 layers, `layer_speed = base × 1.2^i` (line 208/268), so
  the top turns 1.2^7 = 3.58× the base (probe item 8). "A fifth faster than
  the layer below" is the multiplier.
- **baggage_grammar**: lap 12 s, customs_scale 0.55 (scaled down and
  restored), per exports and header.
- **two_cakes**: R·T ≠ T·R, "candles at two addresses", from its header.
- **righttriangle** default proportion isoceles, reading uniform.
- **boolean cubes**: the tunnel's `cube_scene` preload is from
  `algorithms/primitives/booleans/`, hence "hollowed cubes".
