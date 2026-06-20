extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GoldenSpiralBench

## @identity
## Golden spiral & phyllotaxis — MEDIUM, sunflower seed packing on a bench.
## Truth: 137.5° packs the seeds. Place each new seed one golden angle around
## from the last, at radius sqrt(i), and the parastichies — the spiral arms you
## see in a sunflower head or a pinecone — appear on their own. No spiral was
## drawn; the angle alone forbids the seeds from ever lining up.

@export var seed_count: int = 400
@export var golden_angle_deg: float = 137.5
@export var pack_radius: float = 0.34
@export var seed_dot: float = 0.012

var _seeds: MultiMeshInstance3D


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
	# Bench base.
	var base_mat := _matte_mat(Color(0.15, 0.14, 0.12), 0.85)
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.2, 0.7), base_mat))
	var pillar_mat := _steel_mat(Color(0.34, 0.3, 0.26))
	add_child(_cylinder(Vector3(0.0, 0.45, 0.0), 0.07, 0.9, pillar_mat))

	# Seed head laid flat on the bench top, facing +Z (slight upward tilt later via sway).
	_seeds = _field(seed_count)
	add_child(_seeds)
	_pack_seeds()

	add_child(_billboard_label("137.5° — THE GOLDEN ANGLE", Vector3(0.0, 1.6, 0.0), 26, Color(1.0, 0.85, 0.45)))


func _pack_seeds() -> void:
	var mm: MultiMesh = _seeds.multimesh
	var origin := Vector3(0.0, 0.97, 0.0)
	var ga: float = deg_to_rad(golden_angle_deg)
	var k: float = pack_radius / sqrt(float(maxi(seed_count, 1)))
	var inner := Color(1.0, 0.55, 0.15)
	var outer := Color(1.0, 0.9, 0.4)
	for i in range(seed_count):
		var angle: float = float(i) * ga
		var radius: float = k * sqrt(float(i))
		# Lay flat on bench top: x across, z toward +Z, y is up.
		var pos := origin + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		# Seeds grow slightly larger toward the rim.
		var t: float = clampf(radius / pack_radius, 0.0, 1.0)
		var s: float = seed_dot * (0.7 + 0.6 * t)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, s)), pos))
		mm.set_instance_color(i, inner.lerp(outer, t))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _seeds:
		_seeds.rotation.y = Time.get_ticks_msec() * 0.00018
