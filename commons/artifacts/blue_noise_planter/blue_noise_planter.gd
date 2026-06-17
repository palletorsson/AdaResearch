extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BlueNoisePlanter
## @identity
## lineage: best-candidate sampling → planter nozzle scattering evenly-spaced trees
## essence: a tool placing trees so none crowd another — blue noise doing real work
## truth: a forest looks natural only when nothing was allowed to clump.

@export var plot_span: float = 1.1
@export var max_trees: int = 26
@export var candidates: int = 14

var _trees: Array = []
var _grove: Node3D
var _accum: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	# The plot of soil.
	add_child(_box(Vector3(0, 0.03, 0), Vector3(plot_span, 0.06, plot_span), _matte_mat(Color(0.28, 0.2, 0.14), 0.95)))
	# The planter tool: body + arm + dispensing nozzle over the plot, mid-planting.
	add_child(_box(Vector3(-0.65, 0.45, -0.4), Vector3(0.28, 0.8, 0.28), _matte_mat(Color(0.2, 0.5, 0.3))))
	add_child(_cylinder_between(Vector3(-0.6, 0.8, -0.4), Vector3(0.0, 0.7, 0.0), 0.04, _steel_mat(Color(0.5, 0.52, 0.55))))
	add_child(_cylinder(Vector3(0.0, 0.62, 0.0), 0.06, 0.18, _steel_mat(Color(0.4, 0.42, 0.46))))
	add_child(_cylinder(Vector3(0.0, 0.5, 0.0), 0.03, 0.06, _glow_mat(Color(0.5, 1.0, 0.5), 3.0)))
	_grove = Node3D.new()
	add_child(_grove)
	_trees.clear()
	# Plant a full representative grove immediately.
	for i in range(max_trees):
		_plant_one()
	_render()
	add_child(_billboard_label("even scatter: no clumps", Vector3(0, 1.05, 0), 24, Color(0.6, 1.0, 0.6)))


func _best_candidate() -> Vector2:
	var half: float = plot_span * 0.44
	var best := Vector2.ZERO
	var best_d: float = -1.0
	for i in range(candidates):
		var p := Vector2(_rng.randf_range(-half, half), _rng.randf_range(-half, half))
		var nearest: float = 1e9
		for q in _trees:
			nearest = minf(nearest, p.distance_to(q))
		if _trees.is_empty():
			nearest = 1e9
		if nearest > best_d:
			best_d = nearest
			best = p
	return best


func _plant_one() -> void:
	_trees.append(_best_candidate())


func _render() -> void:
	for c in _grove.get_children(): _grove.remove_child(c); c.queue_free()
	var stem_mat := _matte_mat(Color(0.45, 0.3, 0.18), 0.9)
	for p in _trees:
		var base := Vector3(p.x, 0.06, p.y)
		_grove.add_child(_cylinder(base + Vector3(0, 0.05, 0), 0.008, 0.1, stem_mat))
		var h: float = _rng.randf_range(0.12, 0.2)
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.05
		cone.height = h
		var mi := MeshInstance3D.new()
		mi.mesh = cone
		mi.material_override = _matte_mat(Color(0.2, 0.55, 0.25).lerp(Color(0.35, 0.7, 0.3), _rng.randf()), 0.85)
		mi.position = base + Vector3(0, 0.1 + h * 0.5, 0)
		_grove.add_child(mi)


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_accum += delta
	if _accum < 0.6:
		return
	_accum = 0.0
	if _trees.size() >= max_trees:
		_trees.clear()
	else:
		_plant_one()
	_render()
