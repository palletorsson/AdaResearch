extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name VoronoiBench

## @identity
## name: Voronoi Bench
## tier: medium
## truth: every point claims the territory nearest it
##
## A Voronoi diagram on a bench. A dozen sites are scattered across a plate; an
## ~40x40 grid of flat tiles is coloured by whichever site is nearest. The
## boundaries are not drawn — they emerge where two claims meet. Small bright
## spheres mark the sites themselves so you can see the seeds of each cell.

@export var grid_size: int = 40
@export var site_count: int = 12
@export var plate: float = 0.9

const BENCH_TOP: float = 0.85
var _cell: float = 0.0
var _sites: Array[Vector2] = []
var _site_colors: Array[Color] = []


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


func _build() -> void:
	_cell = plate / float(grid_size)
	# housing — bench + plate
	add_child(_box(Vector3(0.0, BENCH_TOP * 0.5, 0.0), Vector3(1.05, BENCH_TOP, 0.7), _matte_mat(Color(0.2, 0.18, 0.22))))
	add_child(_box(Vector3(0.0, BENCH_TOP + 0.01, 0.0), Vector3(plate + 0.05, 0.03, plate + 0.05), _matte_mat(Color(0.06, 0.05, 0.07))))
	add_child(_billboard_label("VORONOI", Vector3(0.0, 1.6, 0.0), 32, Color(1.0, 0.85, 0.55)))

	_scatter_sites()
	add_child(_make_field())
	_mark_sites()


func _scatter_sites() -> void:
	_sites.clear()
	_site_colors.clear()
	var half: float = plate * 0.5
	var margin: float = plate * 0.08
	for i in range(site_count):
		var sx: float = _rng.randf_range(-half + margin, half - margin)
		var sz: float = _rng.randf_range(-half + margin, half - margin)
		_sites.append(Vector2(sx, sz))
		var hue: float = float(i) / float(site_count)
		_site_colors.append(Color.from_hsv(hue, 0.65, 0.95))


func _nearest_site(p: Vector2) -> int:
	var best: int = 0
	var best_d: float = INF
	for i in range(_sites.size()):
		var d: float = p.distance_squared_to(_sites[i])
		if d < best_d:
			best_d = d
			best = i
	return best


func _field(n: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = BoxMesh.new()
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.16 if emissive else 0.0
	mi.material_override = mat
	return mi


func _make_field() -> MultiMeshInstance3D:
	var n: int = grid_size * grid_size
	var mi := _field(n)
	var mm: MultiMesh = mi.multimesh
	var box := mm.mesh as BoxMesh
	box.size = Vector3(_cell * 0.96, 0.012, _cell * 0.96)
	var top: float = BENCH_TOP + 0.035
	var half: float = plate * 0.5
	for gy in range(grid_size):
		for gx in range(grid_size):
			var idx: int = gy * grid_size + gx
			var px: float = -half + (float(gx) + 0.5) * _cell
			var pz: float = -half + (float(gy) + 0.5) * _cell
			var owner: int = _nearest_site(Vector2(px, pz))
			mm.set_instance_transform(idx, Transform3D(Basis(), Vector3(px, top, pz)))
			mm.set_instance_color(idx, _site_colors[owner])
	return mi


func _mark_sites() -> void:
	var top: float = BENCH_TOP + 0.05
	for i in range(_sites.size()):
		var s: Vector2 = _sites[i]
		var mat := _glow_mat(_site_colors[i].lightened(0.3), 1.4)
		add_child(_sphere(Vector3(s.x, top + 0.02, s.y), 0.018, mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# static diagram — a barely-there sway so it feels alive on the bench
	rotation.y = sin(Time.get_ticks_msec() * 0.0004) * 0.02
