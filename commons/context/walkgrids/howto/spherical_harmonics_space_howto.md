# SphericalHarmonicsSpace — How to Use in Maps

## What It Is
Spherical harmonics Y_l^m projected flat — the same math that describes electron orbitals, gravitational fields, and audio spatialization. Walk across quantum mechanical probability distributions.

## Scene Path
```
res://commons/context/walkgrids/spherical_harmonics_space.tscn
```

## Drop Into a Map Scene

```gdscript
var sh = preload("res://commons/context/walkgrids/spherical_harmonics_space.tscn").instantiate()
sh.degree_l = 3
sh.order_m = 2
sh.space_size = Vector2(25, 25)
sh.resolution = 80
sh.height_scale = 2.0
add_child(sh)
```

## Key Parameters

| Parameter | Default | What It Does |
|-----------|---------|-------------|
| `degree_l` | 3 | Degree (0-8 practical). Higher = more complex patterns |
| `order_m` | 2 | Order (-l to l). Controls angular structure |
| `combination_mode` | SINGLE | SINGLE, SUM_ALL_ORDERS, SUPERPOSITION, ORBITAL_HYBRID |
| `components` | [(2,0,1), (3,2,0.7), (4,-3,0.5)] | Weighted (l,m,weight) for SUPERPOSITION mode |

## Combination Modes

| Mode | What It Does |
|------|-------------|
| SINGLE | Just Y_l^m — one harmonic |
| SUM_ALL_ORDERS | Sum all m for given l — rotationally averaged |
| SUPERPOSITION | Weighted mix of multiple (l,m) — custom wavefunctions |
| ORBITAL_HYBRID | sp3-like combination of s and p orbitals |

## Notable (l, m) Pairs

| l | m | Shape | Physical Analogy |
|---|---|-------|-----------------|
| 0 | 0 | Uniform dome | s orbital |
| 1 | 0 | North-south dipole | pz orbital |
| 1 | 1 | East-west dipole | px orbital |
| 2 | 0 | Clover leaf | dz² orbital |
| 2 | 2 | Four-fold symmetry | dxy orbital |
| 3 | 0 | Six lobes | f orbital |
| 4 | 3 | Complex multi-lobe | g orbital |

## Map Integration Examples

### Quantum Mechanics Map
```gdscript
func _ready():
    var sh = SphericalHarmonicsSpace.new()
    sh.degree_l = 2
    sh.order_m = 0
    sh.space_size = Vector2(25, 25)
    sh.height_scale = 3.0
    add_child(sh)
```

### Orbital Gallery — Walk Through s, p, d, f
```gdscript
var harmonics = [
    Vector2i(0, 0),  # s
    Vector2i(1, 0),  # p
    Vector2i(2, 0),  # d
    Vector2i(3, 0),  # f
    Vector2i(4, 0),  # g
]
for i in range(harmonics.size()):
    var sh = SphericalHarmonicsSpace.new()
    sh.position.x = i * 28.0
    sh.degree_l = harmonics[i].x
    sh.order_m = harmonics[i].y
    sh.space_size = Vector2(24, 24)
    add_child(sh)
```

### Order Progression for Fixed Degree
```gdscript
# Show all m for l=3: m = -3, -2, -1, 0, 1, 2, 3
var l = 3
for m in range(-l, l + 1):
    var sh = SphericalHarmonicsSpace.new()
    sh.position.x = (m + l) * 25.0
    sh.degree_l = l
    sh.order_m = m
    sh.space_size = Vector2(20, 20)
    add_child(sh)
```

### Superposition — Custom Wavefunction
```gdscript
var sh = SphericalHarmonicsSpace.new()
sh.combination_mode = SphericalHarmonicsSpace.CombineMode.SUPERPOSITION
sh.components = [
    Vector3(1, 0, 1.0),    # p_z
    Vector3(2, 1, 0.5),    # d_xz
    Vector3(3, -2, 0.3),   # f component
]
sh.height_scale = 2.5
add_child(sh)
```

### sp3 Hybrid Orbital
```gdscript
var sh = SphericalHarmonicsSpace.new()
sh.combination_mode = SphericalHarmonicsSpace.CombineMode.ORBITAL_HYBRID
sh.height_scale = 3.0
add_child(sh)
```

## Teaching Suggestions
- l=0 is a smooth dome (s orbital) — the simplest
- Increase l to add more "lobes" — show how complexity builds
- m controls angular structure: m=0 is always azimuthally symmetric
- SUPERPOSITION mode shows how orbitals combine (bonding!)
- The height IS probability density — taller = more likely to find the electron

## Performance Notes
- Associated Legendre polynomials computed per vertex — fast for l ≤ 8
- SUPERPOSITION with many components: linear in number of components
- Purely static — no per-frame cost
