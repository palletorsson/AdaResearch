# Seventeen

There are exactly seventeen ways a flat pattern can repeat. Before this room, the four moves and the idea of closure must already be yours.

Count them.

```gdscript
enum Group {
    P1, P2, PM, PG, CM, PMM, PMG, PGG, CMM,
    P4, P4M, P4G, P3, P3M1, P31M, P6, P6M
}

func census() -> int:
    return Group.size()
```

Seventeen. Not roughly, not so far. Fedorov proved in 1891 that there is no eighteenth.

Partition them by lattice.

```gdscript
const GROUPS_BY_LATTICE: Dictionary = {
    "oblique":     [Group.P1, Group.P2],
    "rectangular": [Group.PM, Group.PG, Group.PMM, Group.PMG, Group.PGG],
    "rhombic":     [Group.CM, Group.CMM],
    "square":      [Group.P4, Group.P4M, Group.P4G],
    "hexagonal":   [Group.P3, Group.P3M1, Group.P31M, Group.P6, Group.P6M]
}
```

Two, five, two, three, five. Five lattices, and the parts sum to the whole with nothing left over. In the headset B and Y cycle the lattice; A and X cycle within it.

Deal the list onto the walls.

```gdscript
func _census_limit() -> int:
    match census:
        "one":   return 1
        "pair":  return 2
        "triad": return 3
        _:       return GROUP_NAMES.size()

var group_id: int = cluster_index % _census_limit()
```

`wall_pattern_gallery` finds the map's wall cubes, buckets them by Z, and gives each cluster the next group. At `chorus` the walk through the room is the whole list.

Read the richest of them.

```gdscript
Group.P6M: {
    "name": "p6m",
    "description": "60° rotation + all mirrors (highest symmetry)",
    "rotations": [60, 120, 180],
    "reflections": true,
    "glides": true,
    "lattice": "hexagonal"
}
```

Everything a plane pattern can carry, all at once. `loom_alhambra_p6m` weaves it and `mill_alhambra_p6m` turns it — the group the Alhambra's artisans used most.

Author a tile and stand on the result.

```gdscript
func _on_cell_changed(_x: int, _y: int, _color_index: int) -> void:
    _update_carpet_texture()
```

`vr_tile_editor` wires the puzzle's signal straight to the floor. `carpet_repeats` is `Vector2i(8, 8)` — one edit, sixty-four copies, one frame.

Now ask the floor what you made.

```gdscript
var analyzer := TilingAnalyzer.new()
var result: Dictionary = analyzer.analyze(grid, tile_size, tile_size)
print(WallpaperGroups.get_group_name(result["group"]))
print(result["rotation_order"], " ", result["confidence"])
```

The analyser finds the translation period first, then the highest rotation order, then reflections and glides. It reads back what a pattern has, whether or not the painter meant it.

Follow the decision tree to its end.

```gdscript
func _classify(rot6: bool, rot4: bool, rot3: bool, rot2: bool,
        mirror_x: bool, mirror_y: bool, mirror_diag: bool,
        glide_x: bool, glide_y: bool) -> WallpaperGroups.Group:
    var has_mirror: bool = mirror_x or mirror_y
    var has_glide: bool = glide_x or glide_y
    if rot6:
        return WallpaperGroups.Group.P6M if has_mirror else WallpaperGroups.Group.P6
    if rot4:
        if has_mirror and mirror_diag:
            return WallpaperGroups.Group.P4M
        return WallpaperGroups.Group.P4G if has_mirror else WallpaperGroups.Group.P4
    if rot3:
        if has_mirror and mirror_diag:
            return WallpaperGroups.Group.P31M
        return WallpaperGroups.Group.P3M1 if has_mirror else WallpaperGroups.Group.P3
    if rot2:
        if mirror_x and mirror_y:
            return WallpaperGroups.Group.CMM if has_glide else WallpaperGroups.Group.PMM
        if has_mirror and has_glide:
            return WallpaperGroups.Group.PMG
        return WallpaperGroups.Group.PGG if has_glide else WallpaperGroups.Group.P2
    if has_mirror:
        return WallpaperGroups.Group.CM if has_glide else WallpaperGroups.Group.PM
    return WallpaperGroups.Group.PG if has_glide else WallpaperGroups.Group.P1
```

Every branch returns a group. There is no fall-through to "unclassified", because there is nowhere for a plane pattern to fall.

Name the hands the rules came from.

```gdscript
const PLATES := [
    {"shader": "atlas_zellige", "title": "ZELLIGE",
     "makers": "tile-cutters (maalem) · al-Andalus / Maghreb"},
    {"shader": "atlas_meander", "title": "MEANDER",
     "makers": "mosaic workshops · Pompeii"},
    {"shader": "atlas_kente", "title": "KENTE",
     "makers": "Ashanti & Ewe strip-weavers · Ghana"},
]

@export_enum("named", "title_only", "redacted", "anonymous")
var credit: String = "named"
```

Each plate runs the rule as a shader, not a photograph of a cloth. `credit` can strip the lower tag to the style alone, black it out, or remove the boards entirely — the enclosure, built so it can be walked rather than argued.

You can now count the seventeen, sort them into five lattices, paint a corridor with the whole census, author a tile and have the analyser name which of the seventeen you made. This is the one classification in the book that finishes, and the tile-cutters of Granada exhausted it by hand centuries before the theorem counted it. You leave this room past their names, not past a wall of mathematics.
