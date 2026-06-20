extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BecomingToy

## @identity
## name: "Matter that finds its shape"
## tier: small
## lineage: A held bit of matter self-organizing. A scatter of particles drifts apart into noise,
##   then draws back together into a coherent little form — a sphere of order condensing out of
##   disorder — and dissolves again, over and over. Nobody stamps the shape on; it finds itself.
## truth: "FORM IS NOT IMPOSED — IT EMERGES; THE SAME MATTER FINDS ITS OWN SHAPE OUT OF NOISE"
## applications: self-assembly, crystallization, morphogenesis, flocking, diffusion-limited
##   aggregation — order that condenses from below rather than being printed from above.

const N: int = 80

@export var radius: float = 0.13
@export var part_col: Color = Color(0.55, 0.92, 0.78)
@export var noise_col: Color = Color(0.55, 0.60, 0.92)
@export var label_col: Color = Color(0.90, 0.95, 0.92)
@export var cycle_rate: float = 0.16

var _t: float = 0.0
var _mm: MultiMesh = null
var _mi: MultiMeshInstance3D = null
var _targets: Array = []       # ordered shape positions (a sphere)
var _noise: Array = []         # scattered noise positions
var _mid_y: float = 0.18


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("radius"):
		radius = clampf(float(config["radius"]), 0.08, 0.2)
	if config.has("part_col"):
		part_col = _parse_color(config["part_col"], part_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_mm = null
	_mi = null
	_targets.clear()
	_noise.clear()
	_build()


func _build() -> void:
	# Held cradle — no table.
	add_child(_cylinder(Vector3(0.0, 0.02, 0.0), radius * 1.3, 0.025, _matte_mat(Color(0.16, 0.17, 0.2), 0.7)))

	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 6
	sm.rings = 3
	_mm.mesh = sm
	_mm.instance_count = N
	_mi = MultiMeshInstance3D.new()
	_mi.multimesh = _mm
	_mi.material_override = _glow_mat(part_col, 0.7)
	add_child(_mi)

	# The ORDERED target — a fibonacci sphere shell, the coherent form.
	var golden: float = PI * (3.0 - sqrt(5.0))
	var center := Vector3(0.0, _mid_y, 0.0)
	for i in range(N):
		var y: float = 1.0 - 2.0 * (float(i) + 0.5) / float(N)
		var rad: float = sqrt(maxf(0.0, 1.0 - y * y))
		var th: float = golden * float(i)
		_targets.append(center + Vector3(cos(th) * rad, y, sin(th) * rad) * radius)
		# The DISORDERED noise position — random cloud.
		_noise.append(center + Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0),
		) * radius * 1.6)
	_refresh(0.0)

	add_child(_billboard_label("FORM IS NOT IMPOSED — IT EMERGES", Vector3(0.0, _mid_y + radius + 0.16, 0.0), 13, label_col))


func _refresh(order: float) -> void:
	if _mm == null:
		return
	var stud: float = radius * 0.08
	for i in range(N):
		var noise: Vector3 = _noise[i]
		var target: Vector3 = _targets[i]
		# Add a little per-particle jitter that fades as order rises.
		var jit := Vector3(
			sin(_t * 1.7 + float(i) * 1.1),
			cos(_t * 1.3 + float(i) * 0.7),
			sin(_t * 1.9 + float(i) * 1.7),
		) * radius * 0.12 * (1.0 - order)
		var p: Vector3 = noise.lerp(target, order) + jit
		_mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(stud, stud, stud)), p))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# order swings 0 -> 1 -> 0 : noise condenses into form and dissolves back.
	var order: float = sin(_t * TAU * cycle_rate) * 0.5 + 0.5
	# Ease so it lingers at both fully-formed and fully-scattered.
	order = smoothstep(0.0, 1.0, order)
	_refresh(order)
	# Recolor toward noise-blue when scattered, order-green when coherent.
	if _mi != null:
		_mi.material_override = _glow_mat(noise_col.lerp(part_col, order), 0.7)
