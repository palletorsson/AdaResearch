# Mirror and Rotor

Two moves join translation: reflect across a line, turn about a point. Before them, the lattice must already repeat.

Mirror one axis.

```gdscript
RepeatMode.MIRROR_X:
    var tile_x: int = px / tile_size
    tx = px % tile_size
    if tile_x % 2 == 1:
        tx = tile_size - 1 - tx
    ty = py % tile_size
```

Odd columns of tiles read the domain backwards. Paint half the tile and the other half arrives.

Mirror both.

```gdscript
RepeatMode.MIRROR_XY:
    var tile_x: int = px / tile_size
    var tile_y: int = py / tile_size
    tx = px % tile_size
    ty = py % tile_size
    if tile_x % 2 == 1:
        tx = tile_size - 1 - tx
    if tile_y % 2 == 1:
        ty = tile_size - 1 - ty
```

Fourfold from a quarter. `pattern_tile_mirror` is not a separate artifact — it is the same scene with `repeat_mode` set to 3 in the registry.

Rotate instead of reflecting.

```gdscript
RepeatMode.ROTATE_90:
    var tile_idx: int = (px / tile_size + py / tile_size) % 4
    tx = px % tile_size
    ty = py % tile_size
    for i in range(tile_idx):
        var new_tx: int = tile_size - 1 - ty
        var new_ty: int = tx
        tx = new_tx
        ty = new_ty
```

A quarter turn is one swap and one flip. Applied `tile_idx` times, it is the rotor.

Ask a group how many blades its rotor has.

```gdscript
func _rotor_fold_for_group(gi: int) -> int:
    var gname: String = GROUP_NAMES[gi]
    if gname.begins_with("p6"):
        return 6
    if gname.begins_with("p4"):
        return 4
    if gname.begins_with("p3"):
        return 3
    return 2
```

The mill reads its own program off the group name. `mill_persian_p4` delegates `group = "p4"` and gets four.

Build that many mirror wedges.

```gdscript
var fold: int = _rotor_fold_for_group(_group_index)
for i in range(fold):
    var wedge := MeshInstance3D.new()
    var pm := PrismMesh.new()
    pm.size = Vector3(0.06, 0.30, 0.02)
    wedge.mesh = pm
    wedge.material_override = wedge_mat
    wedge.rotation.y = TAU * float(i) / float(fold)
    pivot.add_child(wedge)
```

The rotational order is not printed on a label. It is the number of objects in the scene. Cycle the group and the machine re-geometries.

Do the same with mirrors instead of tiles.

```gdscript
@export_range(2, 8) var mirror_count: int = 3
@export_range(2, 24) var pattern_segments: int = 6

func _wedge_angle(i: int, n_seg: int) -> float:
    return TAU * float(i) / float(n_seg)
```

`mirror_count` is the dihedral order. The wedge is the fundamental domain, the disc is its orbit, and the kaleidoscope has obeyed this for two centuries without naming it.

Now collect every rotation the seventeen groups allow.

```gdscript
func permitted_folds() -> Array:
    var found: Array = []
    for g in WallpaperGroups.GROUP_INFO:
        for deg in WallpaperGroups.GROUP_INFO[g]["rotations"]:
            if not found.has(deg):
                found.append(deg)
    found.sort()
    return found
```

The answer is `[60, 90, 120, 180]` — 6-, 4-, 3- and 2-fold. There is no 72 in the table and none can be added. This is the crystallographic restriction, and the mill will not let you build a fivefold rosette that also tiles.

You can now mirror one axis or both, rotate a tile by quarter turns, drive a machine's geometry from its symmetry group, and read the four permitted folds straight out of the table. Fivefold exists — Penrose found it — but it cannot repeat. Symmetry_Glide adds the move that hides.
