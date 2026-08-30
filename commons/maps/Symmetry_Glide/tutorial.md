# The Glide

Reflect, then slide. Before it, the mirror and the lattice must both already work.

Compose the two into one move.

```gdscript
Group.PG:
    var tile_x: int = px / tile_size
    tx = px % tile_size
    ty = py % tile_size
    if tile_x % 2 == 1:
        tx = tile_size - 1 - tx
        ty = (ty + tile_size / 2) % tile_size
```

A reflection and a half-period shift, applied together. Neither alone leaves the pattern unchanged. The pair does.

Test for a plain mirror.

```gdscript
func _check_mirror_x(data: Array, w: int, h: int, period: Vector2i) -> bool:
    var pw: int = period.x
    var matches: int = 0
    var total: int = 0
    for y in range(period.y):
        for x in range(pw / 2):
            var mx: int = pw - 1 - x
            total += 1
            if data[y % h][x % w] == data[y % h][mx % w]:
                matches += 1
    return total > 0 and float(matches) / float(total) >= match_tolerance
```

Same row on both sides of the comparison. Run this on a `pg` pattern and it fails everywhere — no mirror line survives to point at.

Now test for the glide.

```gdscript
func _check_glide_x(data: Array, w: int, h: int, period: Vector2i) -> bool:
    var pw: int = period.x
    var ph: int = period.y
    var half_y: int = ph / 2
    var matches: int = 0
    var total: int = 0
    for y in range(ph):
        for x in range(pw / 2):
            var mx: int = pw - 1 - x
            var my: int = (y + half_y) % ph
            total += 1
            if data[y % h][x % w] == data[my % h][mx % w]:
                matches += 1
    return total > 0 and float(matches) / float(total) >= match_tolerance
```

One index changed: `data[y]` became `data[my]`. That single shift is the difference between a symmetry anyone can see and one almost nobody can name. `match_tolerance` is 0.9, because the analyser is built to read patterns laid by hand.

Lay a brick course.

```gdscript
RepeatMode.BRICK_X:
    var tile_y: int = py / tile_size
    var offset: int = (tile_size / 2) * (tile_y % 2)
    tx = (px + offset) % tile_size
    ty = py % tile_size
```

Every second row shifts half a tile. This is why masonry joints never line up into a weak seam — the structural rule and the glide reflection are the same two lines of arithmetic.

Cross two of them.

```gdscript
RepeatMode.HERRINGBONE:
    var block_x: int = px / tile_size
    var block_y: int = py / tile_size
    tx = px % tile_size
    ty = py % tile_size
    if (block_x + block_y) % 2 == 1:
        var temp: int = tx
        tx = ty
        ty = temp
```

Alternating blocks swap x and y. The woven diagonal of a parquet floor is one transposition read on a checkerboard.

Put off-centre mirrors inside a rotating group.

```gdscript
Group.P4G:
    var tile_x: int = px / tile_size
    var tile_y: int = py / tile_size
    tx = px % tile_size
    ty = py % tile_size
    var rot: int = (tile_x + tile_y) % 4
    for i in range(rot):
        var new_tx: int = tile_size - 1 - ty
        var new_ty: int = tx
        tx = new_tx
        ty = new_ty
    if (tile_x + tile_y) % 2 == 1:
        tx = tile_size - 1 - tx
        ty = tile_size - 1 - ty
```

`p4g` is what `mill_escher_p4g` mills: fourfold rotation whose mirrors miss the rotation centres. The interlock happens off-axis or not at all.

Weave a pattern against its own reflection.

```gdscript
var escher_mirror := {
    "group": "p6", "palette": "escher",
    "loom_style": "mirror", "motif_seed": 9,
}
_loom.apply_grid_config(escher_mirror)
```

`loom_escher_mirror` is not a scene. It is four values delegated to `pattern_loom`, which is how this chapter ships a dozen machines from one body.

You can now build a glide out of a mirror and a half-shift, tell it apart from a mirror by one index, and recognise it in brick, parquet and p4g. Escher found it in the Alhambra floor and taught the crystallographers to see it — but the tile-cutters of Granada had put it there four hundred years first. Symmetry_Group closes the four moves into one object.
