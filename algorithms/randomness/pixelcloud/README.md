# Pixel Cloud

3D self-avoiding random walk creating voxel cloud formations — upward-biased procedural sculpture.

## QFEP Connection

Self-avoiding walks are **constrained randomness**. The walker can't revisit cells (F, constraint) but chooses direction randomly (E, chance). The `upward_bias` parameter skews probability toward rising — order (tendency) meeting chaos (path). Result: organic cloud-like forms.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `grid_size` | 16 | 3D grid bounds |
| `num_cubes` | 23 | Walk length |
| `cube_spacing` | 1.0 | Voxel size |
| `upward_bias` | 3.0 | Vertical preference |

## Algorithm

```
1. Start at bottom center
2. Choose random direction (biased up)
3. If cell empty, place cube and move
4. If blocked, try other directions
5. Repeat until num_cubes placed
```

## Directions

6-connected 3D movement:
- Up, Down (Y axis)
- Left, Right (X axis)
- Forward, Back (Z axis)

## Files

| File | Purpose |
|------|---------|
| `pixel_cloud.gd` | Walk generator |
| `*.tscn` | Scene file |

## Usage

```gdscript
var cloud = preload("res://algorithms/randomness/pixelcloud/pixel_cloud.tscn").instantiate()
cloud.num_cubes = 50  # Longer walk
cloud.upward_bias = 5.0  # More vertical
add_child(cloud)
```

## See Also

- `randomness/` — Other stochastic algorithms
- `cellularautomata/` — Grid-based growth
