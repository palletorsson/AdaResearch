# Dini Surface

Parametric pseudospherical surface — a twisted horn with constant negative Gaussian curvature.

## QFEP Connection

The Dini surface embodies **non-Euclidean geometry made tangible**. Its constant negative curvature means parallel lines diverge — unlike flat (F) or spherical space. The surface twists infinitely (E tending toward singularity) while maintaining mathematical regularity (F in the equations). It's a visual proof that alternative geometries exist.

## How It Works

```
Side view:              Top view (spiral):
    ╭╮                       ╭───╮
   ╱  ╲                    ╱  ╭──╯
  ╱    ╲                  │  ╱
 │      │                 │ │
 │      │                 │  ╲
  ╲    ╱                   ╲  ╰──╮
   ╲  ╱                     ╰───╯
    ╰╯
   Twisted horn           Logarithmic spiral
```

## Parametric Equations

```
x(u, v) = a × cos(u) × sin(v)
y(u, v) = a × sin(u) × sin(v)
z(u, v) = a × (cos(v) + ln(tan(v/2))) + b × u
```

Where:
- `a` = radius parameter
- `b` = twist parameter
- `u` = angle around axis (0 to 4π typically)
- `v` = position along surface (avoid 0, singularity)

## Parameters

### Dini Parameters
| Export | Default | Description |
|--------|---------|-------------|
| `a` | 1.0 | Radius scale |
| `b` | 0.2 | Twist/helix spacing |

### Resolution
| Export | Default | Range | Description |
|--------|---------|-------|-------------|
| `u_segments` | 100 | 10-300 | Azimuthal resolution |
| `v_segments` | 50 | 10-100 | Radial resolution |

### Range
| Export | Default | Description |
|--------|---------|-------------|
| `u_min/max` | 0 / 4π | Angular extent |
| `v_min/max` | 0.1 / 2.0 | Radial extent (avoid 0) |

## Geometric Properties

- **Gaussian curvature**: K = -1/a² (constant negative)
- **Asymptotic lines**: Visible as parameter lines
- **Singularity**: At v = 0 (the horn's tip extends to infinity)
- **Ruled surface**: Can be swept by straight lines

## Files

| File | Purpose |
|------|---------|
| `dini_surface.gd` | Mesh generator |
| `*.tscn` | Scene file |

## Usage

```gdscript
var dini = preload("res://algorithms/wavefunctions/dini_surface/dini_surface.tscn").instantiate()
dini.a = 1.5  # Larger radius
dini.b = 0.3  # More twist
dini.u_max = 6 * PI  # More turns
add_child(dini)
```

## VR Experience

Walk around the Dini surface. Notice how it twists endlessly downward. The negative curvature means the surface curves away from itself in perpendicular directions — like a saddle at every point. Touch it and contemplate non-Euclidean space.

## Historical Note

Named after Ulisse Dini (1845-1918), Italian mathematician. The surface demonstrates that pseudospheres (constant negative curvature) can be embedded in 3D Euclidean space — proving hyperbolic geometry is as "real" as Euclidean.

## See Also

- `spherical_harmonics/` — Other mathematical surfaces
- `alternativegeometries/` — Non-standard spaces
- `transformation/` — Coordinate systems
