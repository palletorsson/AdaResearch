# lattice_walk.gd — YOU CAN BE AT CELL 2, OR CELL 3 — NEVER 2.5.
#
# The array seam. An array is a lattice: integer addresses, no cells between.
# The amber line is the continuous path you want across the grid — a straight
# diagonal from one corner to another. The blue staircase is the path you can
# actually occupy: whole cells, chosen by rounding the line to the nearest
# lattice point. Reach for element 2.5 and you snap to 2 or 3. The smooth
# intention survives only as a stair of held cells — the same sample-and-hold
# that turns every continuous thing in here into a grid of dots.
extends Node3D
class_name LatticeWalk

@export var cols: int = 13
@export var rows: int = 9
@export var cell: float = 0.05
@export var color_true: Color = Color(1.0, 0.62, 0.18)
@export var color_step: Color = Color(0.3, 0.7, 1.0)


func _ready() -> void:
	var w: float = float(cols) * cell
	var h: float = float(rows) * cell
	var ox: float = -w * 0.5
	var oy: float = -h * 0.5
	_backing(w, h)
	# grid lines
	for c in range(cols + 1):
		_seg(Vector2(ox + float(c) * cell, oy), Vector2(ox + float(c) * cell, oy + h), Color(0.22, 0.25, 0.30), 0.002)
	for r in range(rows + 1):
		_seg(Vector2(ox, oy + float(r) * cell), Vector2(ox + w, oy + float(r) * cell), Color(0.22, 0.25, 0.30), 0.002)
	# the continuous desire — straight diagonal across cell centres
	var a: Vector2 = Vector2(ox + cell * 0.5, oy + cell * 0.5)
	var b: Vector2 = Vector2(ox + (float(cols) - 0.5) * cell, oy + (float(rows) - 0.5) * cell)
	# blue staircase: for each column, round the line's row to nearest integer cell
	for cx in range(cols):
		var fx: float = (float(cx) + 0.5) / float(cols)
		var line_row: float = fx * float(rows - 1)
		var ry: int = int(round(line_row))
		_fill_cell(ox + float(cx) * cell, oy + float(ry) * cell)
	_seg(a, b, color_true, 0.006)
	_dot(a, color_true, 0.009)
	_dot(b, color_true, 0.009)
	_tag("the array is a lattice — integer addresses only", Vector2(0.0, oy - 0.05), color_step)
	_plate("WALK THE GRID",
		"the amber line is the path you want\nthe blue stair is the path you can occupy — whole cells\nreach for element 2.5 and you snap to 2 or 3",
		Vector3(0.0, oy + h + 0.14, 0.0), color_step)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_cols"):
		cols = int(str(get_meta("config_cols")))


func _backing(w: float, h: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w + 0.08, h + 0.08, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.0, -0.016)
	add_child(mi)


func _fill_cell(x: float, y: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(cell * 0.86, cell * 0.86, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_step
	mat.emission_enabled = true
	mat.emission = color_step
	mat.emission_energy_multiplier = 0.35
	mi.material_override = mat
	mi.position = Vector3(x + cell * 0.5, y + cell * 0.5, -0.004)
	add_child(mi)


func _seg(a: Vector2, b: Vector2, color: Color, thick: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var d: float = a.distance_to(b)
	bm.size = Vector3(maxf(d, 0.001), thick, thick)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mi.material_override = mat
	mi.position = Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.0)
	mi.rotation = Vector3(0.0, 0.0, atan2(b.y - a.y, b.x - a.x))
	add_child(mi)


func _dot(p: Vector2, color: Color, r: float) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mi.material_override = mat
	mi.position = Vector3(p.x, p.y, 0.008)
	add_child(mi)


func _tag(text: String, pos: Vector2, color: Color) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = 28
	t.pixel_size = 0.00044
	t.modulate = color
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector3(pos.x, pos.y, 0.0)
	add_child(t)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.84, 0.15, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.84, 0.01, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = true
	smat.emission = accent
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.083, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 30
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
