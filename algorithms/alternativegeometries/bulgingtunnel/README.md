# Bulging Tunnel

Procedural tunnel generation with organic bulges — CSG-based geometry for explorable cave-like spaces.

## QFEP Connection

A regular cylinder is pure F (uniform, predictable). Adding bulges introduces E (variation, surprise). The `num_bulges` and `bulge_max_radius` parameters control how organic vs geometric the space feels. This is λ applied to architecture: how much chaos do you let into your structure?

## How It Works

```
Side view:
    ╭──────╮   ╭────╮
───╱        ╲─╱      ╲───
───╲        ╱─╲      ╱───
    ╰──────╯   ╰────╯

Cross-section at bulge:
      ╭───╮
     ╱     ╲
    │   ·   │  ← Expanded radius
     ╲     ╱
      ╰───╯
```

Algorithm:
1. Create base cylinder (tunnel)
2. Place spherical bulges along length
3. CSG union merges them into single mesh
4. Enable collision for walkability

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `tunnel_length` | 10.0 | Total tunnel length |
| `tunnel_radius` | 1.0 | Base tunnel radius |
| `num_bulges` | 5 | Number of expansions |
| `bulge_max_radius` | 2.0 | Maximum bulge size |
| `tunnel_segments` | 32 | Cylinder smoothness |
| `use_random_bulges` | true | Randomize placement |
| `bulge_seed` | 42 | Random seed |
| `tunnel_color` | Brown | Base color |
| `metallic` | 0.1 | Surface metallic |
| `roughness` | 0.7 | Surface roughness |

## CSG Construction

```
CSGCombiner3D (root)
├── CSGCylinder3D (base tunnel)
├── CSGSphere3D (bulge 1)
├── CSGSphere3D (bulge 2)
└── ... (more bulges)
```

All shapes unioned together with automatic collision.

## Files

| File | Purpose |
|------|---------|
| `bulging_tunnel.gd` | Generation script |

## Usage

```gdscript
var tunnel = preload("res://algorithms/alternativegeometries/bulgingtunnel/bulging_tunnel.tscn").instantiate()
tunnel.tunnel_length = 20.0
tunnel.num_bulges = 10
tunnel.bulge_max_radius = 3.0
add_child(tunnel)
```

## VR Experience

Walk through the tunnel. The bulges create natural gathering spaces — wider areas where you can pause. The organic variation makes the space feel carved rather than constructed. Useful for cave environments, biological passages, or surreal architecture.

## Applications

- **Cave systems**: Natural-looking caverns
- **Biological environments**: Blood vessels, intestines
- **Surreal architecture**: Dream-like spaces
- **Level design**: Interesting corridor variation

## Material Notes

Default material is earthy brown with:
- Low metallic (organic feel)
- High roughness (matte, stone-like)

Override with `material` export for different aesthetics (metal ducts, flesh tunnels, etc.).

## See Also

- `organicspace/` — More organic environments
- `proceduralgeneration/` — Other procedural methods
- `cellularautomata/caves/` — Alternative cave generation
