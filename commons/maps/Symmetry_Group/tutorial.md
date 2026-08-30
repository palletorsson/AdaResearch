# The Group

Compose any two moves that preserve a pattern and the result is another move that preserves it. Before this, all four moves must already be in your hands.

Write a symmetry as a function on the domain.

```gdscript
func _mirror_x() -> void:
    var new_data: Array = []
    for y in tile_size:
        var row: Array = []
        for x in tile_size:
            row.append(_grid_data[y][tile_size - 1 - x])
        new_data.append(row)
    _grid_data = new_data
    _refresh_grid_visuals()
    _update_carpet()
```

A move takes a domain and returns a domain. Same shape in, same shape out — which is the precondition for composing anything at all.

Write another.

```gdscript
func _rotate_cw() -> void:
    var new_data: Array = []
    for y in tile_size:
        var row: Array = []
        for x in tile_size:
            row.append(_grid_data[tile_size - 1 - x][y])
        new_data.append(row)
    _grid_data = new_data
    _refresh_grid_visuals()
    _update_carpet()
```

Transpose and reverse. With `_mirror_y` and the translation already inside `_update_carpet`, the station's four buttons are the chapter's four moves.

Do one, then the other, and name what you land on.

```gdscript
func _anti_transpose(g: Array) -> Array:
    var out: Array = []
    for y in tile_size:
        var row: Array = []
        for x in tile_size:
            row.append(g[tile_size - 1 - x][tile_size - 1 - y])
        out.append(row)
    return out
```

`_mirror_x` gives `g[y][N-1-x]`; `_rotate_cw` on that gives `g[N-1-x][N-1-y]`. That is reflection in the anti-diagonal, which was already a symmetry of the square. Try any two, in any order. The answer is always a third move already on the list.

Step through the programs the station can run.

```gdscript
func _cycle_group() -> void:
    _group_index = (_group_index + 1) % GROUP_ORDER.size()
    _current_group = GROUP_ORDER[_group_index]
    _set_group_tag(WallpaperGroups.get_group_name(_current_group).to_upper())
    _update_carpet()
```

`GROUP_ORDER.size()` is 17 and the modulus wraps. There is no eighteenth program to reach because there is not one to write.

Ask a group what it contains.

```gdscript
Group.P4M: {
    "name": "p4m",
    "description": "90° rotation + diagonal mirrors",
    "rotations": [90, 180],
    "reflections": true,
    "glides": true,
    "lattice": "square"
}
```

Rotations, reflections, glides, lattice. That entry is the group written out: the complete list of what leaves the pattern alone, and closed under doing any two of them in a row.

Run one group through two dye ranges.

```gdscript
const PALETTES: Dictionary = {
    "bauhaus": [[0.93, 0.92, 0.88], [0.76, 0.22, 0.18], [0.94, 0.77, 0.18],
                [0.14, 0.31, 0.44], [0.10, 0.12, 0.18]],
    "memphis": [[0.98, 0.95, 0.90], [0.95, 0.35, 0.40], [0.30, 0.55, 0.75],
                [0.95, 0.75, 0.30], [0.12, 0.12, 0.15]],
}

var bolt: Image = PatternSim.render_to_image({
    "group": "p4g", "palette": "memphis", "motif_seed": 33,
})
```

`loom_bolt_memphis_p4g` and a Bauhaus bolt call the same function with the same group. `get_symmetric_color` never reads the palette — it returns an index, and the colour is looked up afterwards. The mathematics cannot see the taste.

Store the group with the pattern.

```gdscript
@export_enum("unset", "p1", "p2", "pm", "pg", "cm", "pmm", "pmg", "pgg",
    "cmm", "p4", "p4m", "p4g", "p3", "p3m1", "p31m", "p6", "p6m")
var group: String = "unset"
```

`pattern_artifact` is a placeable quad that carries its classification as a field. The pattern and the name of its group travel together.

You can now write a symmetry as a function, compose two and land back inside the set, cycle a station through all seventeen programs, and separate the group from the palette. Closure is the first appearance of an idea that runs to the end of the book: the complete, finite, self-contained system. Symmetry_Seventeen counts them.
