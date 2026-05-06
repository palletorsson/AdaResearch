# Lissajous Curves

3D parametric curves from perpendicular harmonic motions — the visual signature of frequency ratios.

## QFEP Connection

Lissajous curves make **frequency relationships visible**. Rational ratios (3:2, 5:4) produce closed, repeating patterns (F); irrational ratios produce space-filling chaos (E). The phase shift rotates the figure — same frequencies, different form. λ as harmonic relationship.

## Equations

```
X(t) = A × sin(a×t + δ)
Y(t) = B × sin(b×t)
Z(t) = C × sin(c×t)
```

Where a:b:c are frequency ratios and δ is phase shift.

## Parameters

### Frequencies
| Export | Default | Description |
|--------|---------|-------------|
| `freq_ratio_x` | 3.0 | X frequency (a) |
| `freq_ratio_y` | 2.0 | Y frequency (b) |
| `freq_ratio_z` | 1.0 | Z frequency (c) |

### Amplitudes
| Export | Default | Description |
|--------|---------|-------------|
| `amplitude_x/y/z` | 1.0/1.0/0.5 | Axis amplitudes |

### Phase
| Export | Default | Description |
|--------|---------|-------------|
| `phase_shift` | 0.0 | δ in radians |
| `animate_phase` | true | Evolve phase over time |
| `phase_speed` | 0.5 | Animation rate |

### Visualization
| Export | Default | Description |
|--------|---------|-------------|
| `num_points` | 500 | Curve resolution |
| `line_width` | 0.02 | Trail thickness |
| `rainbow_gradient` | true | Color by position |

## Famous Ratios

| Ratio | Pattern |
|-------|---------|
| 1:1 | Ellipse/circle |
| 2:1 | Figure-8 |
| 3:2 | Trefoil |
| 5:4 | Complex knot |

## Files

| File | Purpose |
|------|---------|
| `lissajous_curves.gd` | Curve generator |
| `*.tscn` | Scene |

## See Also

- `oscillation/` — Harmonic motion
- `fouriertransformshape/` — Frequency decomposition
