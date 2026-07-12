# marching_squares.gd — DETAIL FINER THAN THE SPACING IS GONE.
#
# The isosurfaces seam. A circle is a smooth implicit surface: the set of
# points where a field equals zero. The machine cannot render the set — it
# samples the field on a grid and guesses the surface between the samples.
# Left: the true circle. Right: the same circle read on a coarse grid, every
# cell either in or out — a blocky disc, lego. Coarsen the grid and the curve
# degrades to a staircase; refine it and the staircase only gets smaller, never
# gone. The surface between the samples was never seen.
extends Node3D
class_name MarchingSquares

@export var radius: float = 0.19
@export var grid_h: float = 0.046
@export var color_true: Color = Color(1.0, 0.62, 0.18)
@export var color_cell: Color = Color(0.3, 0.7, 1.0)
@export var color_grid: Color = Color(0.20, 0.22, 0.28)


func _ready() -> void:
	_backing()
	# LEFT — the true smooth circle
	var lc: Vector3 = Vector3(-0.28, 0.02, 0.0)
	var steps: int = 96
	var prev: Vector3 = lc + Vector3(radius, 0.0, 0.0)
	for i in range(1, steps + 1):
		var a: float = TAU * float(i) / float(steps)
		var p: Vector3 = lc + Vector3(cos(a) * radius, sin(a) * radius, 0.0)
		_seg(prev, p, color_true, 0.005)
		prev = p
	_tag("the surface", lc + Vector3(0.0, -radius - 0.05, 0.0), color_true)
	# RIGHT — the same circle sampled on a grid: a blocky disc
	var rc: Vector3 = Vector3(0.30, 0.02, 0.0)
	var reach: int = int(ceil(radius / grid_h)) + 1
	for gy in range(-reach, reach + 1):
		for gx in range(-reach, reach + 1):
			var cx: float = float(gx) * grid_h
			var cy: float = float(gy) * grid_h
			# faint grid dot
			_grid_dot(rc + Vector3(cx, cy, 0.0))
			if cx * cx + cy * cy <= radius * radius:
				_quad(rc + Vector3(cx, cy, 0.0), grid_h * 0.94, color_cell)
	_tag("the samples", rc + Vector3(0.0, -radius - 0.05, 0.0), color_cell)
	_plate("MARCHING SQUARES",
		"a smooth surface, read on a grid: every cell in or out\ncoarsen it and the circle turns to lego —\nthe surface between the samples was never seen",
		Vector3(0.0, 0.32, 0.0), color_cell)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_grid_h"):
		grid_h = float(str(get_meta("config_grid_h")))


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.92, 0.5, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.02, -0.014)
	add_child(mi)


func _quad(pos: Vector3, s: float, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(s, s, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.25
	mi.material_override = mat
	mi.position = pos
	add_child(mi)


func _grid_dot(pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.003
	sm.height = 0.006
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_grid
	mi.material_override = mat
	mi.position = pos + Vector3(0.0, 0.0, -0.004)
	add_child(mi)


func _seg(a: Vector3, b: Vector3, color: Color, thick: float) -> void:
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
	mi.position = (a + b) * 0.5
	mi.rotation = Vector3(0.0, 0.0, atan2(b.y - a.y, b.x - a.x))
	add_child(mi)


func _tag(text: String, pos: Vector3, color: Color) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = 30
	t.pixel_size = 0.00045
	t.modulate = color
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos
	add_child(t)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.82, 0.13, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.82, 0.01, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = true
	smat.emission = accent
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.072, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 32
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
