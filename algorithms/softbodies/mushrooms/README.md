# Soft Body Mushrooms

Procedurally scattered soft body mushrooms — deformable fungi with randomized proportions.

## QFEP Connection

Mushrooms embody **soft structure**. Their caps and stems have form (F) but yield to touch (E). The randomized proportions create variety within constraint — no two mushrooms identical, yet all recognizably mushroom. λ as biological variation.

## Parameters

| Export | Default | Description |
|--------|---------|-------------|
| `mushroom_count` | 15 | Number to spawn |
| `spawn_area_size` | (20, 20) | Scatter area |
| `stem_height_range` | (0.5, 1.5) | Height variation |
| `stem_radius` | 0.2 | Stem thickness |
| `cap_radius_range` | (0.6, 1.2) | Cap size variation |

## Generation

```
For each mushroom:
1. Random position in spawn area
2. Random stem height (within range)
3. Random cap radius (within range)
4. Create soft body mesh
```

## Files

| File | Purpose |
|------|---------|
| `mushrooms.gd` | Mushroom generator |
| `*.tscn` | Scene file |

## Usage

```gdscript
var mushrooms = preload("res://algorithms/softbodies/mushrooms/mushrooms.tscn").instantiate()
mushrooms.mushroom_count = 30
add_child(mushrooms)
```

## See Also

- `softbodies/` — Other soft body demos
- `lsystems/` — Plant generation
