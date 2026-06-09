extends Node3D
class_name GridBrushDemo

# @identity
# essence: what a VR grid stroke actually is — small + local. A 16x16 floor with
#          a handful of strokes, each at most 4x4 cells, centred where you point.
# truth: in VR you tend what you can reach; the brush is capped at 4x4 so editing
#        stays local, legible, and around-you — never a whole-grid chunk.

const GridOpsLib := preload("res://commons/modifiers/grid_ops.gd")
const N := 16

# Each entry is ONE stroke: op, centre cell, brush size (1..4), params.
var _strokes: Array = [
	{"op": "raise",     "c": Vector2i(3, 3),   "s": 4, "p": {"value": 5}},
	{"op": "randomize", "c": Vector2i(4, 11),  "s": 3, "p": {"min": 1, "max": 5}, "seed": 7},
	{"op": "fill",      "c": Vector2i(11, 4),  "s": 2, "p": {"value": 4}},
	{"op": "add",       "c": Vector2i(8, 8),   "s": 1, "p": {"amount": 4}},
	{"op": "checker",   "c": Vector2i(11, 12), "s": 4, "p": {"value": 3}},
	{"op": "erase",     "c": Vector2i(13, 8),  "s": 2, "p": {}},
]


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	for c in get_children():
		c.queue_free()
	call_deferred("_build")


func _build() -> void:
	var grid: Dictionary = {}
	for r in range(N):
		for c in range(N):
			grid[Vector2i(r, c)] = 1

	for st in _strokes:
		var center: Vector2i = st["c"]
		var size: int = int(st["s"])
		grid = GridOpsLib.stroke(grid, str(st["op"]), center, size, st.get("p", {}), int(st.get("seed", 0)))

	var off: float = -float(N - 1) * 0.5
	for k in grid.keys():
		var h: int = int(grid[k])
		var hh: float = maxf(0.12, 0.32 * float(h))
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.92, hh, 0.92)
		mi.mesh = bm
		mi.position = Vector3(off + float(k.y), hh * 0.5, off + float(k.x))
		var col: Color = _height_color(h)
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 0.25
		m.roughness = 0.6
		mi.material_override = m
		add_child(mi)

	# Glowing 4x4 brush footprint at the first stroke — the max stroke size.
	_draw_brush_outline(Vector2i(3, 3), 4, off)

	# Small labels marking each stroke's scope.
	for st in _strokes:
		var center2: Vector2i = st["c"]
		var lbl := Label3D.new()
		lbl.text = "%s %dx%d" % [str(st["op"]), int(st["s"]), int(st["s"])]
		lbl.font_size = 30
		lbl.pixel_size = 0.0032
		lbl.position = Vector3(off + float(center2.y), 2.2, off + float(center2.x))
		lbl.modulate = Color(0.96, 0.97, 1.0)
		lbl.outline_size = 5
		lbl.outline_modulate = Color(0, 0, 0, 0.7)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(lbl)

	var title := Label3D.new()
	title.text = "VR STROKES — each ≤ 4×4, local"
	title.font_size = 52
	title.pixel_size = 0.005
	title.position = Vector3(0, 4.0, off - 1.5)
	title.modulate = Color(1.0, 0.9, 0.5)
	title.outline_size = 7
	title.outline_modulate = Color(0, 0, 0, 0.75)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(title)


func _draw_brush_outline(center: Vector2i, size: int, off: float) -> void:
	var cells: Array = GridOpsLib.brush_cells(center, size)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.2)
	mat.emission_energy_multiplier = 2.5
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for rc in cells:
		var frame := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.98, 0.04, 0.98)
		frame.mesh = bm
		frame.position = Vector3(off + float(rc[1]), 2.2, off + float(rc[0]))
		frame.material_override = mat
		add_child(frame)


func _height_color(h: int) -> Color:
	var t: float = float(h) / float(GridOpsLib.MAX_H)
	return Color.from_hsv(lerpf(0.58, 0.02, t), 0.6, 0.45 + 0.12 * float(h))
