# swarm_creatures.gd
# Seq 14: swarmintelligence. A small flock orbiting the map — visual stub for
# Reynolds-rules swarming. Loose circular paths with phase offsets.
#
# RENDERING: one MultiMeshInstance3D for the whole flock, per-frame orbit update.

extends Node3D

var _mmi: MultiMeshInstance3D = null
var _boids: Array = []  # each: {phase: float, y_phase: float, speed: float}
var _center: Vector3 = Vector3.ZERO
var _radius: float = 10.0


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var flock_min: int = int(params.get("flock_size_range", [6, 14])[0])
	var flock_max: int = int(params.get("flock_size_range", [6, 14])[1])

	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	_center = grid_center
	_radius = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.6 + 6.0

	var rng := RandomNumberGenerator.new()
	rng.seed = int(ctx.get("rng_seed", 0)) + 14
	var n: int = rng.randi_range(flock_min, flock_max)
	# Phase 5: scale the flock size by the population budget (1.0 = unchanged).
	n = maxi(1, int(round(float(n) * float(ctx.get("budget_scale", 1.0)))))

	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.18, 0.1, 0.32)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var col := Color(0.9, 0.7, 0.3)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.8
	mesh.surface_set_material(0, mat)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = n

	for i in n:
		_boids.append({
			"phase": float(i) / float(n) * TAU,
			"y_phase": rng.randf() * TAU,
			"speed": 0.4 + rng.randf_range(-0.05, 0.05),
		})

	_mmi = MultiMeshInstance3D.new()
	_mmi.name = "Swarm"
	_mmi.multimesh = mm
	_mmi.custom_aabb = AABB(Vector3(-30, -2, -30), Vector3(60, 15, 60))
	_mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(_mmi)


func _process(_delta: float) -> void:
	if _mmi == null:
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	var mm := _mmi.multimesh
	for i in _boids.size():
		var b: Dictionary = _boids[i]
		var angle: float = b.phase + t * b.speed
		var y: float = 3.0 + sin(t * 1.2 + b.y_phase) * 1.5
		var r: float = _radius + sin(t * 0.7 + b.phase) * 1.0
		var pos: Vector3 = _center + Vector3(cos(angle) * r, y, sin(angle) * r)
		var look_target: Vector3 = _center + Vector3(cos(angle + 0.3) * r, y, sin(angle + 0.3) * r)
		# Build a transform that faces from pos toward look_target
		var forward: Vector3 = (look_target - pos).normalized()
		if forward.length_squared() < 0.0001:
			forward = Vector3.FORWARD
		var basis := _basis_facing(forward)
		mm.set_instance_transform(i, Transform3D(basis, pos))


## Construct a basis whose -Z points along `forward`, aligned upright.
func _basis_facing(forward: Vector3) -> Basis:
	var right: Vector3 = Vector3.UP.cross(forward).normalized()
	if right.length_squared() < 0.0001:
		right = Vector3.RIGHT
	var up: Vector3 = forward.cross(right).normalized()
	return Basis(right, up, -forward)
