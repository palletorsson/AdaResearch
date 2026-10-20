extends "res://commons/hazards/catalyst_counterpart/head_ball.gd"
## Early shots are slow and small. Growth changes BOTH visible and collision radii.
var stage := 0
var tint := Color(0.85, 0.85, 0.85)
var age := 0.0
var radius_factor := 1.0
var trail: CPUParticles3D
var waypoints := PackedVector3Array()
var waypoint_index := 1
var arena_frame: Node3D
const ArrayPath := preload("res://commons/hazards/biome_ladder/array_path.gd")

func _ready() -> void:
	speed = 1.8; lifetime = 14.0
	super()
	get_child(1).material_override.albedo_color = tint
	get_child(2).material_override.set_shader_parameter("glow_colour", tint)
	if waypoints.size() > 1:
		var drawing := ArrayPath.drawing(waypoints, false)
		add_child(drawing); drawing.global_transform = Transform3D.IDENTITY
	if stage >= 3:
		trail = CPUParticles3D.new()
		trail.amount = 18; trail.lifetime = 0.45; trail.local_coords = false
		trail.gravity = Vector3.ZERO; trail.initial_velocity_min = 0.01; trail.initial_velocity_max = 0.08
		trail.scale_amount_min = 0.018; trail.scale_amount_max = 0.04
		var mote := SphereMesh.new(); mote.radius = 1; mote.height = 2; mote.radial_segments = 6; mote.rings = 2
		trail.mesh = mote
		var material := StandardMaterial3D.new()
		material.albedo_color = tint; material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		trail.material_override = material
		add_child(trail)

func _physics_process(delta: float) -> void:
	if spent: return
	if _outside_arena():
		_finish(); return
	age += delta
	radius_factor = minf(2.2, 1.0 + age * 0.22) if stage >= 1 else 1.0
	get_child(0).shape.radius = 0.09 * radius_factor
	get_child(1).scale = Vector3.ONE * radius_factor
	get_child(2).scale = Vector3.ONE * radius_factor
	_advance_motion(delta)
	if not spent and _outside_arena(): _finish()

func _outside_arena() -> bool:
	if not is_instance_valid(arena_frame): return false
	var local := arena_frame.to_local(global_position)
	return absf(local.x) > 6.5 or absf(local.z) > 12.5 or local.y < -1.0

func _finish() -> void:
	spent = true
	queue_free() # The shot owns its drawing; both leave together.

func _advance_motion(delta: float) -> void:
	if waypoints.size() > 1:
		_advance_path(delta)
	else:
		super._physics_process(delta)

func _advance_path(delta: float) -> void:
	if spent: return
	lifetime -= delta
	if lifetime <= 0: queue_free(); return
	var remaining := speed * delta
	# Clamp to each waypoint, then spend the rest of this frame on the next edge.
	# Sweeping every edge prevents cutting across a corner or skipping cover.
	while remaining > 0.00001:
		if waypoint_index >= waypoints.size():
			_finish(); return
		var distance := remaining
		if waypoint_index < waypoints.size():
			var offset := waypoints[waypoint_index] - global_position
			if offset.length() < 0.00001:
				waypoint_index += 1; continue
			direction = offset.normalized()
			distance = minf(remaining, offset.length())
		var collision := move_and_collide(direction.normalized() * distance)
		remaining -= distance
		if collision == null: continue
		spent = true
		var body: Node = collision.get_collider()
		if body is Node3D: surface_hit.emit(body, collision.get_position())
		if body != null and (body.is_in_group("player_body") or body.is_in_group("player")):
			player_hit.emit(body)
		queue_free(); return
