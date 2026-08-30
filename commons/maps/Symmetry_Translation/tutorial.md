# Translation

Shift the motif by one cell-width and lay it down again. Before it, the motif must already be painted.

Tile the domain across a preview.

```gdscript
func _update_preview() -> void:
    var w: int = preview_repeats.x * tile_size
    var h: int = preview_repeats.y * tile_size
    var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
    for py in range(h):
        for px in range(w):
            var idx: int = _get_tiled_color(px, py)
            image.set_pixel(px, py, palette[idx])
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = ImageTexture.create_from_image(image)
    mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    _preview_mesh.material_override = mat
```

The image grows with `preview_repeats`. `_grid_data` does not. Infinite surface, finite storage.

Name the group that does only this.

```gdscript
const GROUPS: Array = [
    "p1", "p2", "pm", "pg", "cm", "pmm", "pmg", "pgg", "cmm",
    "p4", "p4m", "p4g", "p3", "p3m1", "p31m", "p6", "p6m"
]
```

`p1` comes first because it does least. Translation and nothing else — the floor of the list, not an absence of symmetry.

Run p1 through the engine every other group is built on.

```gdscript
static func get_symmetric_color(px: int, py: int, tile_size: int,
        grid_data: Array, group: Group) -> int:
    match group:
        Group.P1:
            var tx: int = px % tile_size
            var ty: int = py % tile_size
            return grid_data[ty][tx]
```

Two modulos. Every one of the other sixteen adds operations to this line; none removes it. Translation is the lattice they all stand on.

Manufacture a bolt of it.

```gdscript
func _render_pattern() -> void:
    var cfg := {
        "group": group, "palette": palette, "motif_seed": motif_seed,
        "tile_size": 16, "canvas_size": 256, "density": density,
    }
    var img: Image = PatternSim.render_to_image(cfg)
    if _carpet_tex:
        _carpet_tex.update(img)
    else:
        _carpet_tex = ImageTexture.create_from_image(img)
```

One texture, shared by the carpet, the drum, the banner and every repeat of the cloth. Updating it in place repaints the whole machine at once.

Feed the loom's cloth forward.

```gdscript
func _process(delta: float) -> void:
    if _carpet_mat:
        var o: Vector3 = _carpet_mat.uv1_offset
        o.y = fposmod(o.y + scroll_speed * delta, 1.0)
        _carpet_mat.uv1_offset = o
```

Nothing is actually woven. The UV offset wraps at 1.0 and the carpet appears to run forever. Repetition is what makes the illusion cost nothing.

Now put one coin inside the machine.

```gdscript
func _weave_row(y: float) -> Array:
    var threads: Array = []
    var sx: float = 1.0 / float(cols)
    for c in range(cols):
        var cx: float = -0.5 + (float(c) + 0.5) * sx
        var slash: bool = _rng.randf() < odds
        var hue: float = (0.07 if slash else 0.58) + _rng.randf() * 0.05
        var mat: Material = _glow_mat(Color.from_hsv(hue, 0.6, 0.95), 1.8)
        threads.append(_mark(cx, y, sx, slash, mat))
    return threads
```

`odds` is 0.5 — a fair flip. At 0.0 or 1.0 the cloth stops being a maze and becomes a rib. The pattern exists only because the coin is fair.

Let the flip choose between two marks.

```gdscript
func _mark(cx: float, y: float, sx: float, slash: bool, mat: Material) -> MeshInstance3D:
    var bar: MeshInstance3D = _box(Vector3(cx, y, 0.02),
        Vector3(sx * 0.9, _row_h * 0.42, 0.03), mat)
    bar.rotation.z = (PI * 0.25) if slash else (-PI * 0.25)
    return bar
```

`10 PRINT CHR$(205.5+RND(1))` in three dimensions. One bit picks one of two rotations. The alphabet is two glyphs wide and the bolt never repeats.

Scroll the textile's bolt down and weave a fresh row at the top.

```gdscript
func _process(delta: float) -> void:
    _step += delta
    if _step < 0.18:
        return
    _step = 0.0
    for row in _woven:
        for bar in row:
            bar.position.y -= _row_h
    if _woven[0][0].position.y < _bottom_y:
        for bar in _woven.pop_front():
            bar.queue_free()
        _woven.append(_weave_row(_top_y - _row_h * 0.5))
```

The lattice holds every row in the same places. The flip decides what stands in them. Order and difference are collaborators here, not opponents.

You can now tile a domain by modulo, run it through p1, feed the result off a machine, and thread one random bit into the weave. Symmetry_Mirror_Rotor adds the two moves that fold the tile back onto itself.
