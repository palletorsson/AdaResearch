extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name JitterBench
## @identity
## lineage: random transforms across a grid — order dissolving into noise
## essence: a jitter dial perturbs a tidy lattice; left holds its rank, right melts into chaos
## truth: regularity and randomness are two ends of the same dial

@export var cols: int = 8
@export var rows: int = 4
@export var jitter: float = 0.6

var _grid_group: Node3D
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("jitter"): jitter = clampf(float(config["jitter"]), 0.0, 1.0)
	for c in get_children(): remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	add_child(_box(Vector3(0, 0.75, 0), Vector3(1.1, 0.2, 0.5), _matte_mat(Color(0.2, 0.22, 0.26))))
	add_child(_cylinder(Vector3(0, 0.42, 0), 0.07, 0.66, _steel_mat(Color(0.4, 0.43, 0.5))))
	add_child(_billboard_label("RANDOM TRANSFORMS / perturb the regular", Vector3(0, 1.6, -0.22), 20, Color(0.9, 0.95, 1.0)))
	# Jitter dial.
	add_child(_torus(Vector3(-0.46, 1.16, 0), 0.07, 0.014, _steel_mat(Color(0.55, 0.6, 0.7))))
	var ang: float = jitter * 4.4 - 2.2
	add_child(_cylinder_between(Vector3(-0.46, 1.16, 0), Vector3(-0.46 + sin(ang) * 0.06, 1.16 + cos(ang) * 0.06, 0), 0.008, _glow_mat(Color(1.0, 0.75, 0.2), 2.2)))
	add_child(_billboard_label("jitter", Vector3(-0.46, 1.28, 0), 14, Color(0.8, 0.85, 0.9)))
	_grid_group = Node3D.new()
	add_child(_grid_group)
	_draw_grid()


func _draw_grid() -> void:
	# Tidy lattice of cubes; jitter rises with column index so the right side melts.
	for c in _grid_group.get_children(): _grid_group.remove_child(c); c.queue_free()
	var g := RandomNumberGenerator.new()
	g.seed = 1337
	var x0: float = -0.44
	var z0: float = -0.16
	var dx: float = 0.88 / float(maxi(cols - 1, 1))
	var dz: float = 0.32 / float(maxi(rows - 1, 1))
	for col in range(cols):
		var col_j: float = jitter * (float(col) / float(maxi(cols - 1, 1)))
		var hue: float = 0.55 - col_j * 0.45
		var mat := _glow_mat(Color.from_hsv(hue, 0.7, 1.0), 1.5)
		for row in range(rows):
			var px: float = x0 + float(col) * dx + (g.randf() - 0.5) * col_j * dx * 1.2
			var pz: float = z0 + float(row) * dz + (g.randf() - 0.5) * col_j * dz * 1.2
			var py: float = 0.95 + (g.randf() - 0.5) * col_j * 0.12
			var cube := _box(Vector3(px, py, pz), Vector3(0.05, 0.05, 0.05), mat)
			var rot: float = (g.randf() - 0.5) * col_j * 3.0
			cube.rotation = Vector3(rot * 0.6, rot, rot * 0.4)
			var s: float = 1.0 + (g.randf() - 0.5) * col_j * 0.8
			cube.scale = Vector3.ONE * clampf(s, 0.4, 1.8)
			_grid_group.add_child(cube)


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_t += delta * 0.5
	# Oscillate the global jitter amount and rebuild the perturbations.
	jitter = 0.5 + 0.45 * sin(_t)
	_draw_grid()
