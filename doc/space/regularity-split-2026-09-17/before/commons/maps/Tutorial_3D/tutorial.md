# 3D

Three indices address a volume. Stepped platforms lift the learner to each layer.

Build the 4×4×4 volume.

```gdscript
const VOLUME_SIZE := Vector3i(4, 4, 4)

func build_volume() -> void:
    for x in VOLUME_SIZE.x:
        for y in VOLUME_SIZE.y:
            for z in VOLUME_SIZE.z:
                var cell := CELL_SCENE.instantiate()
                cell.position = Vector3(x, y, z)
                cell.set_meta("coords", Vector3i(x, y, z))
                add_child(cell)
```

Sixty-four cells. Each addressed by three indices.

Read the volume by three indices.

```gdscript
func cell_at(coords: Vector3i) -> Node3D:
    for child in get_children():
        if child.has_meta("coords") and child.get_meta("coords") == coords:
            return child
    return null
```

Metadata lookup. For larger volumes, a direct array indexing scheme would be faster.

Make cells transparent.

```gdscript
func apply_transparency() -> void:
    for child in get_children():
        if child.has_meta("coords"):
            var mat := StandardMaterial3D.new()
            mat.albedo_color = Color(0.5, 0.7, 1.0, 0.4)
            mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
            child.get_node("Mesh").material_override = mat
```

Transparent cells let the learner see through the volume to layers beyond. Alpha of 0.4 is legible without occluding.

Three sliders for highlighting.

```gdscript
var highlight_coords: Vector3i = Vector3i.ZERO

func _on_slider_changed(axis: String, value: float) -> void:
    match axis:
        "x": highlight_coords.x = int(round(value))
        "y": highlight_coords.y = int(round(value))
        "z": highlight_coords.z = int(round(value))
    refresh_highlight()
```

Each slider drives one axis. Together they select a single cell.

Refresh the highlighted cell.

```gdscript
func refresh_highlight() -> void:
    for child in get_children():
        if child.has_meta("coords"):
            var c: Vector3i = child.get_meta("coords")
            var is_selected: bool = c == highlight_coords
            child.scale = Vector3.ONE * (1.1 if is_selected else 1.0)
            child.modulate = Color.YELLOW if is_selected else Color.WHITE
```

Selected cell scales up slightly and changes colour. The rest dim back to base state.

Build stepped platforms.

```gdscript
func build_platforms() -> void:
    for layer in VOLUME_SIZE.y:
        var platform := PLATFORM_SCENE.instantiate()
        platform.position = Vector3(-1, layer, layer)
        platform.scale = Vector3(1, 0.1, 1)
        add_child(platform)
```

Each platform sits one unit to the side and one unit deeper. The staircase rises as the learner climbs.

Show the code for the current cell.

```gdscript
func update_code_display() -> void:
    code_label.text = "grid[%d][%d][%d]" % [highlight_coords.x, highlight_coords.y, highlight_coords.z]
```

The code runs in parallel with the spatial highlight. Three bracket indices match the three slider positions.

You can now build a 4×4×4 volume, render it with transparency, drive highlighting via three sliders, climb stepped platforms to reach each layer, and see the three-index code for each selected cell. Tutorial_Disco extends the array into a temporal dance floor.
