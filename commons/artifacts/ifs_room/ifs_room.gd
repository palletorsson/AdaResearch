extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name IfsRoom

## @identity
## Iterated function systems (IFS) — LARGE, a room of attractors.
## Truth: a point, folded, forever. Three different rule-sets stand on the floor
## — a fern, a Sierpinski triangle (chaos game), a fractal tree — each a single
## point thrown through a handful of affine folds until a shape no one drew
## settles out of the repetition. Same machine, different folds, different worlds.

@export var fern_points: int = 5000
@export var sierp_points: int = 5000
@export var tree_points: int = 5000
@export var dot: float = 0.012


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _field(n: int, box: bool = false) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = (BoxMesh.new() if box else SphereMesh.new())
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.22 if emissive else 0.0
	mi.material_override = mat
	return mi


func _build() -> void:
	# Room floor.
	var floor_mat := _matte_mat(Color(0.08, 0.09, 0.11), 0.95)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), floor_mat))

	# Three pedestals + attractors arranged across the floor.
	_make_pedestal(Vector3(-2.2, 0.0, 0.0))
	_make_pedestal(Vector3(0.0, 0.0, -1.6))
	_make_pedestal(Vector3(2.2, 0.0, 0.0))

	var fern := _field(fern_points)
	add_child(fern)
	_plot_fern(fern, Vector3(-2.2, 0.45, 0.0), 2.6)

	var sierp := _field(sierp_points)
	add_child(sierp)
	_plot_sierpinski(sierp, Vector3(0.0, 0.45, -1.6), 2.4)

	var tree := _field(tree_points)
	add_child(tree)
	_plot_tree(tree, Vector3(2.2, 0.45, 0.0), 2.6)

	add_child(_billboard_label("A POINT, FOLDED, FOREVER", Vector3(0.0, 3.6, 0.0), 40, Color(0.85, 0.9, 1.0)))


func _make_pedestal(at: Vector3) -> void:
	var m := _steel_mat(Color(0.22, 0.24, 0.28))
	add_child(_cylinder(at + Vector3(0.0, 0.2, 0.0), 0.35, 0.4, m))


func _plot_fern(field: MultiMeshInstance3D, origin: Vector3, h: float) -> void:
	var mm: MultiMesh = field.multimesh
	var sx: float = (h * 0.45) / 5.0
	var sy: float = h / 10.0
	var px: float = 0.0
	var py: float = 0.0
	var base := Color(0.25, 0.85, 0.32)
	for i in range(mm.instance_count):
		var r: float = _rng.randf()
		var nx: float = 0.0
		var ny: float = 0.0
		if r < 0.01:
			nx = 0.0
			ny = 0.16 * py
		elif r < 0.86:
			nx = 0.85 * px + 0.04 * py
			ny = -0.04 * px + 0.85 * py + 1.6
		elif r < 0.93:
			nx = 0.20 * px - 0.26 * py
			ny = 0.23 * px + 0.22 * py + 1.6
		else:
			nx = -0.15 * px + 0.28 * py
			ny = 0.26 * px + 0.24 * py + 0.44
		px = nx
		py = ny
		if i < 20:
			_park(mm, i, origin)
			continue
		var pos := origin + Vector3(px * sx, py * sy, 0.0)
		_set_dot(mm, i, pos, base.lerp(Color(0.6, 1.0, 0.5), clampf(py / 10.0, 0.0, 1.0) * 0.6))


func _plot_sierpinski(field: MultiMeshInstance3D, origin: Vector3, h: float) -> void:
	var mm: MultiMesh = field.multimesh
	# 3 vertices of an upright triangle in the XY plane.
	var v0 := Vector3(0.0, h, 0.0)
	var v1 := Vector3(-h * 0.55, 0.0, 0.0)
	var v2 := Vector3(h * 0.55, 0.0, 0.0)
	var verts: Array[Vector3] = [v0, v1, v2]
	var cols: Array[Color] = [Color(1.0, 0.45, 0.35), Color(0.4, 0.7, 1.0), Color(1.0, 0.85, 0.35)]
	var p := Vector3(0.0, h * 0.4, 0.0)
	for i in range(mm.instance_count):
		var k: int = _rng.randi() % 3
		p = p.lerp(verts[k], 0.5)
		if i < 20:
			_park(mm, i, origin)
			continue
		_set_dot(mm, i, origin + p, cols[k])


func _plot_tree(field: MultiMeshInstance3D, origin: Vector3, h: float) -> void:
	# A self-similar fractal tree (4 affine maps).
	var mm: MultiMesh = field.multimesh
	var sx: float = (h * 0.45)
	var sy: float = h * 0.85
	var px: float = 0.0
	var py: float = 0.0
	var base := Color(0.7, 0.5, 0.85)
	for i in range(mm.instance_count):
		var r: float = _rng.randf()
		var nx: float = 0.0
		var ny: float = 0.0
		if r < 0.10:
			# trunk
			nx = 0.0
			ny = 0.6 * py
		elif r < 0.20:
			# trunk extend
			nx = 0.0
			ny = 0.5 * py + 1.0
		elif r < 0.60:
			# left branch
			nx = 0.42 * px - 0.42 * py
			ny = 0.42 * px + 0.42 * py + 0.4
		else:
			# right branch
			nx = 0.42 * px + 0.42 * py
			ny = -0.42 * px + 0.42 * py + 0.4
		px = nx
		py = ny
		if i < 20:
			_park(mm, i, origin)
			continue
		var pos := origin + Vector3(px * sx, py * sy, 0.0)
		_set_dot(mm, i, pos, base.lerp(Color(0.9, 0.8, 1.0), clampf(py, 0.0, 1.0)))


func _set_dot(mm: MultiMesh, i: int, pos: Vector3, col: Color) -> void:
	mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(dot, dot, dot)), pos))
	mm.set_instance_color(i, col)


func _park(mm: MultiMesh, i: int, origin: Vector3) -> void:
	mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(0.0001, 0.0001, 0.0001)), origin))
	mm.set_instance_color(i, Color(0, 0, 0, 0))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var sway: float = sin(Time.get_ticks_msec() * 0.0003) * 0.04
	for c in get_children():
		if c is MultiMeshInstance3D:
			(c as MultiMeshInstance3D).rotation.y = sway
