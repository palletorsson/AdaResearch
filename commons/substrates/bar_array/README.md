# BarArray Substrate

> The 1D workhorse. Sorting, spectra, sequences. One object.

Universal 1D array visualization for algorithm education. MultiMesh bars with per-instance emission, smooth transitions, and swappable algorithm cartridges.

## Architecture

```
bar_array_cartridge.gd    — Base class (RefCounted): initialize(), step(), get_bar_color()
bar_array_renderer.gd     — MultiMesh rendering with smooth height/color interpolation
bar_array_substrate.gd    — Manager: cartridge lifecycle, play/pause/step, touch, config
bar_array_cell.gdshader   — Per-instance emission, idle pulse via INSTANCE_CUSTOM
bar_array_substrate.tscn  — Scene: dark glass base, translucent rim, touch area
```

### Scene Tree

```
BarArraySubstrate (Node3D) [bar_array_substrate.gd]
├── Renderer (Node3D) [bar_array_renderer.gd]
│   └── BarMultiMesh (MultiMeshInstance3D) — created at runtime
├── BasePlate (MeshInstance3D) — dark glass, metallic 0.3, roughness 0.1
├── Rim (MeshInstance3D) — translucent edge, subtle emission
├── Label3D — algorithm display name
└── TouchArea (Area3D)
    └── CollisionShape3D (BoxShape3D)
```

### Rendering Pipeline

1. Cartridge produces `PackedFloat32Array` of normalized values (0.0–1.0)
2. Renderer maps values to bar heights: `MIN_BAR_HEIGHT + value * MAX_BAR_HEIGHT`
3. Per-bar color from `cartridge.get_bar_color(index, value, total)`
4. Smooth LERP interpolation on height and color (LERP_SPEED = 8.0)
5. Swap flash via `_flash_energy` decaying from 1.5 → 0.0
6. Shader adds idle breathing: `sin(TIME + instance_offset) * 0.03`

### Bar Dimensions

- Width: 0.035m per bar
- Depth: 0.025m
- Max height: 0.3m
- Gap: 15% of bar width
- 32 bars ≈ 1.3m total width (arm's reach in VR)

## 9 Cartridges

### Sorting (6)

| Cartridge | Algorithm | Complexity | Visual Signature |
|-----------|-----------|------------|-----------------|
| `bubble_sort` | Adjacent compare & swap | O(n²) | Yellow comparisons, sorted-green boundary creeps right |
| `insertion_sort` | Slide into position | O(n²)/O(n) | Cyan element slides left through sorted region |
| `selection_sort` | Find min, swap to front | O(n²) | Magenta minimum marker scanning right |
| `merge_sort` | Bottom-up merge | O(n log n) | Cyan/orange halves merging in widening passes |
| `quicksort` | Pivot partition | O(n log n) avg | Magenta pivot, Lomuto partition sweep |
| `heap_sort` | Build heap, extract max | O(n log n) | Orange build phase → cyan extract phase |

### Non-sorting (3)

| Cartridge | What it does | Visual Signature |
|-----------|-------------|-----------------|
| `histogram` | Bins Gaussian samples | Blue bars growing into bell curve shape |
| `fibonacci` | Builds F(n) sequence | Golden amber bars with exponential growth |
| `prime_sieve` | Eratosthenes elimination | Cyan primes survive, composites go dark |

## Map Placement

```
"bar_array_bubble_sort"                        # Named variant
"bar_array#algorithm:quicksort"                # Config syntax
"bar_array#algorithm:merge_sort#size:16"       # With size override
"bar_array#algorithm:histogram#interval:0.01"  # Fast histogram
"bar_array_fibonacci"                          # Named variant
```

## Config Parameters

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `algorithm` | string | `bubble_sort` | Cartridge name |
| `size` | int | `32` | Number of bars |
| `width` | int | `32` | Alias for size |
| `interval` | float | `0.08` | Seconds between steps |
| `auto_play` | bool | `true` | Start stepping immediately |

## Cartridge Interface

```gdscript
class_name BarArrayCartridge extends RefCounted

func get_name() -> String
func get_category() -> String
func get_bar_color(index: int, value: float, total: int) -> Color
func get_bar_emission(index: int, value: float, total: int) -> float
func initialize(size: int) -> PackedFloat32Array
func step(arr: PackedFloat32Array) -> Dictionary  # {array, comparisons, swaps, highlights, done, description}
func on_bar_touch(arr: PackedFloat32Array, index: int) -> PackedFloat32Array
func is_complete(arr: PackedFloat32Array) -> bool
func get_preferred_size() -> int
func get_preferred_interval() -> float
func get_warmup_steps() -> int
```

### Step Result Dictionary

```gdscript
{
    "array": PackedFloat32Array,     # updated values
    "comparisons": [[i, j], ...],    # pairs compared (→ yellow highlight)
    "swaps": [[i, j], ...],          # pairs swapped (→ white flash)
    "highlights": {index: Color},    # custom per-bar colors
    "done": bool,                    # algorithm finished
    "description": String            # optional status text
}
```

## Creating a New Cartridge

1. Create `cartridges/cartridge_<name>.gd`
2. Extend `BarArrayCartridge`, override methods
3. Add enum value to `BarArraySubstrate.Algorithm`
4. Add match arm in `_create_cartridge()`
5. Add entries in `_resolve_algorithm_from_lookup_name()` and `apply_grid_config()` algo_maps
6. Add entry in `commons/artifacts/registry/bar_array.json`

## VR Design

- Bars have physical depth (0.025m) for parallax
- Emission + bloom on all active bars
- Smooth LERP on height changes (no snapping)
- Swap flash: emission 1.5 → decays to 0 (FLASH_DECAY = 4.0)
- Idle breathing: subtle sine pulse in shader
- Comparison: yellow highlight
- Sort complete: all bars turn green
- Touch a bar to interact (cartridge-specific)

## Registry

`commons/artifacts/registry/bar_array.json` — 10 entries (1 generic + 9 named variants)
