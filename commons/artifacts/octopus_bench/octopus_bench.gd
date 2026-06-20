extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name OctopusBench

## @identity
## name: "Tentacle & octopus"
## tier: medium
## lineage: A single octopus arm on a bench — a tapered chain of segments that curls and coils,
##   a sine wave running down its length, suckers along the underside. No bone anywhere; the
##   shape is the muscle and the muscle is the shape.
## truth: "DISTRIBUTED SOFT COGNITION; NO BONE — THE ARM THINKS WHERE IT TOUCHES"
## applications: soft robot arms, continuum manipulators, octopus muscular hydrostats — limbs
##   that bend anywhere because they bend everywhere.

@export var segments: int = 16
@export var arm_len: float = 0.9
@export var coil_rate: float = 0.5
@export var arm_col: Color = Color(0.80, 0.35, 0.55)
@export var sucker_col: Color = Color(0.95, 0.78, 0.82)
@export var bench_col: Color = Color(0.16, 0.17, 0.20)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _seg_nodes: Array = []     # MeshInstance3D per segment
var _sucker_mm: MultiMesh = null
var _base := Vector3(0.0, 0.86, -0.25)   # bench top, arm rises and reaches +Z


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("segments"):
		segments = int(clampf(float(config["segments"]), 8, 24))
	if config.has("arm_len"):
		arm_len = clampf(float(config["arm_len"]), 0.6, 1.2)
	if config.has("arm_col"):
		arm_col = _parse_color(config["arm_col"], arm_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_seg_nodes.clear()
	_sucker_mm = null
	_build()


func _build() -> void:
	# Bench.
	add_child(_box(Vector3(0.0, 0.42, 0.0), Vector3(1.2, 0.84, 0.7), _matte_mat(bench_col, 0.85)))
	# Mount stub the arm grows from.
	add_child(_cylinder(Vector3(_base.x, _base.y + 0.02, _base.z), 0.07, 0.06, _steel_mat(Color(0.4, 0.4, 0.45))))

	var arm_mat := _glow_mat(arm_col, 0.4)
	# Build tapered segments as spheres; positions set each frame.
	for i in range(segments):
		var f: float = float(i) / float(segments - 1)
		var r: float = lerpf(0.06, 0.012, f)   # tapers to a tip
		var seg := _sphere(Vector3.ZERO, r, arm_mat)
		add_child(seg)
		_seg_nodes.append(seg)

	# Suckers: one MultiMesh, two per segment along the underside.
	var n: int = segments * 2
	_sucker_mm = MultiMesh.new()
	_sucker_mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 1.4
	sm.radial_segments = 6
	sm.rings = 3
	_sucker_mm.mesh = sm
	_sucker_mm.instance_count = n
	var smi := MultiMeshInstance3D.new()
	smi.multimesh = _sucker_mm
	smi.material_override = _glow_mat(sucker_col, 0.6)
	add_child(smi)

	_update_arm(0.0)

	add_child(_billboard_label("DISTRIBUTED SOFT COGNITION; NO BONE", Vector3(0.0, 1.6, 0.0), 17, label_col))


func _arm_point(f: float, tt: float) -> Vector3:
	# f in [0,1] along the arm. A sine running down the length curls it; the whole arm
	# also coils gently in Z over time.
	var along: float = f * arm_len
	var bend: float = sin(f * PI * 2.2 - tt * TAU * coil_rate) * (0.18 + f * 0.22)
	var rise: float = sin(f * PI) * 0.25 + f * 0.15
	var sway: float = cos(f * PI * 1.5 - tt * coil_rate) * f * 0.12
	return _base + Vector3(bend + sway, rise, along)


func _update_arm(tt: float) -> void:
	for i in range(_seg_nodes.size()):
		var f: float = float(i) / float(segments - 1)
		var seg: MeshInstance3D = _seg_nodes[i]
		seg.position = _arm_point(f, tt)
	# Place suckers just beneath each segment, facing down.
	if _sucker_mm != null:
		for i in range(segments):
			var f2: float = float(i) / float(segments - 1)
			var p: Vector3 = _arm_point(f2, tt)
			var rr: float = lerpf(0.018, 0.005, f2)
			for k in range(2):
				var idx: int = i * 2 + k
				var offx: float = (-0.02 if k == 0 else 0.02) * (1.0 - f2)
				var pos := p + Vector3(offx, -lerpf(0.05, 0.012, f2), 0.0)
				_sucker_mm.set_instance_transform(idx, Transform3D(Basis().scaled(Vector3(rr, rr * 0.6, rr)), pos))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	_update_arm(_t)
