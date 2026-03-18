extends Node3D
class_name BuildEnv

## BuildEnv — a reinforcement-learning environment for constructing stable structures.
## An agent places primitives (cubes, beams, pyramids, pillars, wedges, arches) and is
## rewarded for height, span, stability, symmetry, and motif reuse. Includes automatic
## grammar discovery that identifies recurring stable sub-structures as reusable motifs.

# ──────────────────────────────────────────────
# Arena & physics configuration
# ──────────────────────────────────────────────
@export_range(2.0, 50.0) var arena_size_x: float = 10.0
@export_range(2.0, 50.0) var arena_size_z: float = 10.0
@export_range(0.05, 1.0) var grid_res: float = 0.25
@export_range(0.1, 5.0) var settle_time: float = 0.8
@export_range(4, 64) var yaw_bins: int = 16
@export var enable_motif_discovery: bool = true
@export_range(0.1, 5.0) var stability_threshold: float = 0.5
@export_range(2, 10) var min_motif_pieces: int = 2
@export_range(3, 20) var max_motif_pieces: int = 5

const DENSITY := 1.0
const GROUND_Y := 0.0

var rng := RandomNumberGenerator.new()
var bodies: Array[RigidBody3D] = []
var step_count := 0
var episode_count := 0

# Grammar discovery
var motif_library: Array[Dictionary] = []  # Discovered stable patterns
var current_structure_graph: Array[Dictionary] = []  # Connectivity graph
var success_episodes: Array[Dictionary] = []  # High-reward configurations
var piece_placements: Array[Dictionary] = []  # History of placements this episode

# Scene objects
var ground_plane: StaticBody3D = null
var _status_label: Label3D = null

func _ready() -> void:
	_setup_environment()
	_create_status_label()
	print("BuildEnv: Ready! Waiting for step() calls to place geometry...")

func _setup_environment() -> void:
	"""Create ground plane and lighting"""
	# Create ground plane
	ground_plane = StaticBody3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(arena_size_x * 2, 0.2, arena_size_z * 2)
	var ground_cs := CollisionShape3D.new()
	ground_cs.shape = ground_shape
	ground_cs.position = Vector3(0, -0.1, 0)
	ground_plane.add_child(ground_cs)

	# Visual ground mesh
	var ground_mesh_instance := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(arena_size_x * 2, 0.2, arena_size_z * 2)
	ground_mesh_instance.mesh = ground_mesh
	ground_mesh_instance.position = Vector3(0, -0.1, 0)

	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.25, 0.28, 0.25)
	ground_material.roughness = 0.9
	ground_material.metallic = 0.05
	ground_mesh_instance.material_override = ground_material

	ground_plane.add_child(ground_mesh_instance)
	add_child(ground_plane)

	print("BuildEnv: Environment setup complete (ground: %.1fx%.1f)" % [arena_size_x * 2, arena_size_z * 2])

func _create_status_label() -> void:
	"""Floating 3D label showing build stats"""
	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 36
	_status_label.modulate = Color(1.0, 0.85, 0.2)
	_status_label.outline_modulate = Color(0, 0, 0, 0.5)
	_status_label.outline_size = 4
	_status_label.position = Vector3(0, 5, 0)
	_status_label.text = "BuildEnv — Ep %d | Step 0" % episode_count
	add_child(_status_label)

func _create_material(primitive_id: int) -> StandardMaterial3D:
	"""Create a coloured material based on primitive type with subtle emission and metallic finish"""
	var material := StandardMaterial3D.new()

	match primitive_id:
		0:  # Small cube
			material.albedo_color = Color(0.7, 0.5, 0.3)
		1:  # Long beam
			material.albedo_color = Color(0.6, 0.4, 0.2)
		2:  # Pyramid — gold with emission
			material.albedo_color = Color(1.0, 0.85, 0.2)
			material.emission_enabled = true
			material.emission = Color(1.0, 0.85, 0.2) * 0.1
		3:  # Pillar — stone with slight metallic
			material.albedo_color = Color(0.5, 0.5, 0.6)
			material.metallic = 0.2
		4:  # Short beam
			material.albedo_color = Color(0.65, 0.45, 0.25)
		5:  # Wedge
			material.albedo_color = Color(0.6, 0.4, 0.3)
		6:  # Plate
			material.albedo_color = Color(0.75, 0.55, 0.35)
		7:  # Arch — white/limestone with glow
			material.albedo_color = Color(0.9, 0.9, 0.95)
			material.emission_enabled = true
			material.emission = Color(0.9, 0.9, 0.95) * 0.08
			material.metallic = 0.1
		_:
			material.albedo_color = Color(0.5, 0.5, 0.5)

	material.roughness = 0.75
	return material

# ---- PRIMITIVE FACTORIES ----
func _make_box(size: Vector3) -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.mass = size.x * size.y * size.z * DENSITY

	# Collision shape
	var shape := BoxShape3D.new()
	shape.size = size
	var cs := CollisionShape3D.new()
	cs.shape = shape
	rb.add_child(cs)

	# Visual mesh
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh

	# Material for visibility
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.5, 0.3)  # Tan/brown
	material.roughness = 0.8
	mesh_instance.material_override = material

	rb.add_child(mesh_instance)
	return rb

func _make_beam(length: float, thickness: float) -> RigidBody3D:
	return _make_box(Vector3(length, thickness, thickness))

func _make_pyramid(base: float, height: float) -> RigidBody3D:
	# Approximate with ConvexPolygonShape3D (square pyramid)
	var rb := RigidBody3D.new()
	var verts := PackedVector3Array()
	var h := height
	var b := base * 0.5
	verts.push_back(Vector3(-b, 0, -b))
	verts.push_back(Vector3( b, 0, -b))
	verts.push_back(Vector3( b, 0,  b))
	verts.push_back(Vector3(-b, 0,  b))
	verts.push_back(Vector3( 0, h,  0))

	# Collision shape
	var hull := ConvexPolygonShape3D.new()
	hull.points = verts
	var cs := CollisionShape3D.new()
	cs.shape = hull
	rb.add_child(cs)

	# Visual mesh
	var mesh_instance := MeshInstance3D.new()
	var array_mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts

	# Generate indices for triangles
	var indices := PackedInt32Array()
	# Base
	indices.append_array([0, 2, 1, 0, 3, 2])
	# Sides
	indices.append_array([0, 1, 4])
	indices.append_array([1, 2, 4])
	indices.append_array([2, 3, 4])
	indices.append_array([3, 0, 4])
	arrays[Mesh.ARRAY_INDEX] = indices

	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.6, 0.2)  # Gold
	material.roughness = 0.7
	mesh_instance.material_override = material

	rb.add_child(mesh_instance)
	rb.mass = base * base * height * (DENSITY * 0.33)
	return rb

func _make_cylinder(radius: float, height: float) -> RigidBody3D:
	var rb := RigidBody3D.new()

	# Collision shape
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	var cs := CollisionShape3D.new()
	cs.shape = shape
	rb.add_child(cs)

	# Visual mesh
	var mesh_instance := MeshInstance3D.new()
	var cylinder_mesh := CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = height
	mesh_instance.mesh = cylinder_mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 0.6)  # Gray/stone
	material.roughness = 0.9
	mesh_instance.material_override = material

	rb.add_child(mesh_instance)
	rb.mass = PI * radius * radius * height * DENSITY
	return rb

func _make_wedge(length: float, width: float, height: float) -> RigidBody3D:
	# Triangular prism / ramp
	var rb := RigidBody3D.new()
	var verts := PackedVector3Array()
	var l := length * 0.5
	var w := width * 0.5
	# Bottom face
	verts.push_back(Vector3(-l, 0, -w))
	verts.push_back(Vector3( l, 0, -w))
	verts.push_back(Vector3( l, 0,  w))
	verts.push_back(Vector3(-l, 0,  w))
	# Top edge (collapsed to form wedge)
	verts.push_back(Vector3(-l, height,  w))
	verts.push_back(Vector3( l, height,  w))

	# Collision shape
	var hull := ConvexPolygonShape3D.new()
	hull.points = verts
	var cs := CollisionShape3D.new()
	cs.shape = hull
	rb.add_child(cs)

	# Visual mesh
	var mesh_instance := MeshInstance3D.new()
	var array_mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts

	var indices := PackedInt32Array()
	# Bottom
	indices.append_array([0, 2, 1, 0, 3, 2])
	# Front
	indices.append_array([0, 1, 5, 0, 5, 4])
	# Back (triangular)
	indices.append_array([2, 3, 4, 2, 4, 5])
	# Left side
	indices.append_array([0, 4, 3])
	# Right side
	indices.append_array([1, 2, 5])
	arrays[Mesh.ARRAY_INDEX] = indices

	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = array_mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.4, 0.3)  # Brown
	material.roughness = 0.85
	mesh_instance.material_override = material

	rb.add_child(mesh_instance)
	rb.mass = 0.5 * length * width * height * DENSITY
	return rb

func _make_arch_segment(radius: float, thickness: float, arc_angle: float) -> RigidBody3D:
	# Simplified curved segment using capsule
	var rb := RigidBody3D.new()

	# Collision shape
	var shape := CapsuleShape3D.new()
	shape.radius = thickness * 0.5
	shape.height = radius * arc_angle  # Approximation
	var cs := CollisionShape3D.new()
	cs.shape = shape
	rb.add_child(cs)

	# Visual mesh
	var mesh_instance := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = thickness * 0.5
	capsule_mesh.height = radius * arc_angle
	mesh_instance.mesh = capsule_mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.9, 0.95)  # Light gray/white
	material.roughness = 0.6
	mesh_instance.material_override = material

	rb.add_child(mesh_instance)
	rb.mass = radius * arc_angle * thickness * thickness * DENSITY
	return rb

# ---- ENV API ----
func reset() -> void:
	# Save successful episodes before clearing
	if enable_motif_discovery and step_count > 0:
		var final_obs = obs()
		var final_reward = _reward(final_obs, true)
		if final_reward > 2.0:  # Threshold for "success"
			_save_success_episode(final_reward, final_obs)

	for b in bodies:
		b.queue_free()
	bodies.clear()
	piece_placements.clear()
	current_structure_graph.clear()
	step_count = 0
	episode_count += 1

func obs() -> Dictionary:
	var aabb := _global_aabb()
	var height := aabb.position.y + aabb.size.y if bodies.size() > 0 else 0.0
	var span_x := aabb.size.x
	var span_z := aabb.size.z
	var ke := _total_ke()
	var com_margin := _support_margin()

	# Enhanced observations for structure discovery
	var contact_graph := _build_contact_graph()
	var symmetry_score := _calculate_symmetry()
	var span_efficiency: float = (span_x + span_z) / max(1.0, float(bodies.size()))
	var height_efficiency: float = height / max(1.0, float(bodies.size()))

	return {
		"n": bodies.size(),
		"height": height,
		"span_x": span_x,
		"span_z": span_z,
		"ke": ke,
		"com_margin": com_margin,
		"is_stable": ke < stability_threshold,
		"connectivity": contact_graph.size(),
		"symmetry": symmetry_score,
		"span_efficiency": span_efficiency,
		"height_efficiency": height_efficiency,
		"motif_count": _count_active_motifs(),
		"structural_integrity": _calculate_integrity()
	}

func step(action: Dictionary) -> Dictionary:
	# action: { primitive_id:int, x:float, z:float, yaw_bin:int, motif_id:int? }
	var pre_obs := obs()
	var placed := _place_action(action)

	_physics_settle(settle_time)

	var post_obs := obs()
	var reward := _reward(post_obs, placed, pre_obs)
	var done := _is_done(post_obs)

	# Track structure changes for motif discovery
	if enable_motif_discovery and placed:
		_update_structure_graph()
		_detect_and_reward_motifs()

	step_count += 1
	return {"obs": post_obs, "reward": reward, "done": done, "info": _get_debug_info()}

# ---- ACTION DECODING ----
func _place_action(a: Dictionary) -> bool:
	var pid: int = a.get("primitive_id", 0)
	var motif_id: int = a.get("motif_id", -1)

	# If using a learned motif, place that instead
	if motif_id >= 0 and motif_id < motif_library.size():
		return _place_motif(motif_id, a)

	var x = clamp(_snap(a.get("x", 0.0)), -arena_size_x / 2.0, arena_size_x / 2.0)
	var z = clamp(_snap(a.get("z", 0.0)), -arena_size_z / 2.0, arena_size_z / 2.0)
	var yaw_bin: int = a.get("yaw_bin", 0) % max(1, yaw_bins)
	var yaw := TAU * float(yaw_bin) / float(max(1, yaw_bins))

	var y_top := _top_height_at(Vector2(x, z)) + 0.02

	var rb: RigidBody3D = null
	var primitive_name := ""

	# Expanded primitive library
	match pid:
		0:  # Small cube
			rb = _make_box(Vector3(0.5, 0.25, 0.5))
			primitive_name = "cube_small"
		1:  # Long beam
			rb = _make_beam(1.5, 0.15)
			primitive_name = "beam_long"
		2:  # Pyramid
			rb = _make_pyramid(0.6, 0.4)
			primitive_name = "pyramid"
		3:  # Pillar (tall cylinder)
			rb = _make_cylinder(0.15, 1.0)
			primitive_name = "pillar"
		4:  # Short beam
			rb = _make_beam(0.8, 0.12)
			primitive_name = "beam_short"
		5:  # Wedge/ramp
			rb = _make_wedge(0.8, 0.5, 0.3)
			primitive_name = "wedge"
		6:  # Flat plate
			rb = _make_box(Vector3(1.0, 0.1, 1.0))
			primitive_name = "plate"
		7:  # Arch segment
			rb = _make_arch_segment(0.5, 0.15, 1.57)  # ~90 degree arc
			primitive_name = "arch"
		_:  # Default cube
			rb = _make_box(Vector3(0.4, 0.2, 0.4))
			primitive_name = "cube_default"

	if rb == null:
		return false

	add_child(rb)
	rb.global_transform = Transform3D(Basis().rotated(Vector3.UP, yaw), Vector3(x, y_top, z))
	rb.set_meta("primitive_id", pid)
	rb.set_meta("primitive_name", primitive_name)
	rb.set_meta("placement_step", step_count)
	bodies.append(rb)

	# Apply typed material
	var typed_mat = _create_material(pid)
	for child in rb.get_children():
		if child is MeshInstance3D:
			child.material_override = typed_mat
	
	# Debug output
	print("BuildEnv: Placed %s (ID:%d) at (%.1f, %.1f, %.1f) - Total bodies: %d" % [
		primitive_name, pid, x, y_top, z, bodies.size()
	])
	
	# Update status label
	if _status_label:
		_status_label.text = "Ep %d | Step %d | Pieces %d" % [episode_count, step_count, bodies.size()]

	# Record placement for motif discovery
	piece_placements.append({
		"primitive_id": pid,
		"primitive_name": primitive_name,
		"position": Vector3(x, y_top, z),
		"yaw": yaw,
		"step": step_count,
		"body_index": bodies.size() - 1
	})

	return true


# ---- METRICS / HELPERS ----
func _snap(v: float) -> float:
	return round(v / grid_res) * grid_res

func _physics_settle(seconds: float) -> void:
	var target := Engine.get_physics_ticks_per_second() * seconds
	for i in range(int(target)):
		await get_tree().physics_frame

func _global_aabb() -> AABB:
	var first := true
	var aabb := AABB(Vector3.ZERO, Vector3.ZERO)
	for b in bodies:
		var baabb = _get_body_aabb(b)
		if first:
			aabb = baabb
			first = false
		else:
			aabb = aabb.merge(baabb)
	return aabb

func _get_body_aabb(body: RigidBody3D) -> AABB:
	"""Get AABB for a RigidBody3D (Godot 4.x compatible)"""
	if body.get_child_count() == 0:
		return AABB(body.global_position, Vector3(0.1, 0.1, 0.1))

	# Find CollisionShape3D child
	var collision_shape: CollisionShape3D = null
	for child in body.get_children():
		if child is CollisionShape3D:
			collision_shape = child
			break

	if not collision_shape or not collision_shape.shape:
		return AABB(body.global_position, Vector3(0.1, 0.1, 0.1))

	# Get shape and calculate AABB based on type
	var shape = collision_shape.shape
	var local_aabb: AABB

	if shape is BoxShape3D:
		var box = shape as BoxShape3D
		local_aabb = AABB(-box.size / 2.0, box.size)
	elif shape is CylinderShape3D:
		var cyl = shape as CylinderShape3D
		var r = cyl.radius
		var h = cyl.height
		local_aabb = AABB(Vector3(-r, -h/2.0, -r), Vector3(r*2, h, r*2))
	elif shape is SphereShape3D:
		var sphere = shape as SphereShape3D
		var r = sphere.radius
		local_aabb = AABB(Vector3(-r, -r, -r), Vector3(r*2, r*2, r*2))
	elif shape is CapsuleShape3D:
		var capsule = shape as CapsuleShape3D
		var r = capsule.radius
		var h = capsule.height
		local_aabb = AABB(Vector3(-r, -h/2.0, -r), Vector3(r*2, h, r*2))
	elif shape is ConvexPolygonShape3D:
		# For convex shapes, estimate from points
		var convex = shape as ConvexPolygonShape3D
		if convex.points.size() > 0:
			var min_point = convex.points[0]
			var max_point = convex.points[0]
			for point in convex.points:
				min_point = min_point.min(point)
				max_point = max_point.max(point)
			local_aabb = AABB(min_point, max_point - min_point)
		else:
			local_aabb = AABB(Vector3.ZERO, Vector3(0.1, 0.1, 0.1))
	else:
		# Fallback for unknown shapes
		local_aabb = AABB(Vector3(-0.5, -0.5, -0.5), Vector3(1, 1, 1))

	# Transform AABB to global space
	var transform = body.global_transform * collision_shape.transform
	return local_aabb.abs().grow(0.0) * transform

func _total_ke() -> float:
	var ke := 0.0
	for b in bodies:
		var v := b.linear_velocity.length()
		var w := b.angular_velocity.length()
		ke += 0.5 * b.mass * v*v + 0.5 * (b.mass) * w*w * 0.1
	return ke

func _support_contacts() -> PackedVector3Array:
	var pts := PackedVector3Array()
	for b in bodies:
		for i in range(b.get_contact_count()):
			var p = b.get_contact_local_position(i)
			var wp := b.to_global(p)
			if wp.y <= GROUND_Y + 0.01:
				pts.push_back(wp)
	return pts

func _support_margin() -> float:
	var pts := _support_contacts()
	if pts.is_empty():
		return -1.0
	# Quick bounding box support (swap with convex hull for precision)
	var minx := INF; var maxx := -INF
	var minz := INF; var maxz := -INF
	for p in pts:
		minx = min(minx, p.x); maxx = max(maxx, p.x)
		minz = min(minz, p.z); maxz = max(maxz, p.z)
	var com := _center_of_mass()
	var margin_x = min(com.x - minx, maxx - com.x)
	var margin_z = min(com.z - minz, maxz - com.z)
	return min(margin_x, margin_z)

func _center_of_mass() -> Vector3:
	if bodies.is_empty(): return Vector3.ZERO
	var sum := Vector3.ZERO
	var m := 0.0
	for b in bodies:
		sum += b.global_transform.origin * b.mass
		m += b.mass
	return sum / max(0.0001, m)

func _top_height_at(xz: Vector2) -> float:
	var y := GROUND_Y
	for b in bodies:
		var aabb = _get_body_aabb(b)
		if xz.x >= aabb.position.x and xz.x <= aabb.position.x + aabb.size.x \
		and xz.y >= aabb.position.z and xz.y <= aabb.position.z + aabb.size.z:
			y = max(y, aabb.position.y + aabb.size.y)
	return y

func _reward(o: Dictionary, placed: bool, pre_obs: Dictionary = {}) -> float:
	# === Core structural objectives ===
	var wH := 1.0    # Height reward
	var wS := 0.5    # Span reward
	var wN := 0.1    # Piece efficiency penalty
	var wK := 0.3    # Kinetic energy penalty (instability)
	var wM := 0.6    # Margin/stability penalty

	# === Grammar discovery bonuses ===
	var wSym := 0.3  # Symmetry bonus
	var wCon := 0.2  # Connectivity bonus
	var wInt := 0.4  # Structural integrity bonus
	var wMot := 0.8  # Motif reuse bonus

	# Normalize metrics
	var height = clamp(o["height"] / 10.0, 0.0, 1.0)
	var span = clamp(max(o["span_x"], o["span_z"]) / 10.0, 0.0, 1.0)
	var pieces := float(o["n"]) / 200.0
	var ke = clamp(o["ke"] / 50.0, 0.0, 1.0)

	# BUGFIX: Correct ternary syntax
	var margin = o.get("com_margin", 0.0)
	var margin_pen = 1.0 if margin < 0.02 else 0.0

	# Stability bonus (low KE = stable)
	var stability_bonus = 0.5 if o.get("is_stable", false) else 0.0

	# Efficiency bonuses
	var height_eff = clamp(o.get("height_efficiency", 0.0), 0.0, 2.0)
	var span_eff = clamp(o.get("span_efficiency", 0.0), 0.0, 2.0)

	# Grammar discovery bonuses
	var symmetry = clamp(o.get("symmetry", 0.0), 0.0, 1.0)
	var connectivity = clamp(o.get("connectivity", 0) / 20.0, 0.0, 1.0)
	var integrity = clamp(o.get("structural_integrity", 0.0), 0.0, 1.0)
	var motif_bonus = float(o.get("motif_count", 0)) * 0.2

	# Delta rewards (progress-based shaping)
	var delta_height = 0.0
	var delta_span = 0.0
	if not pre_obs.is_empty():
		delta_height = max(0.0, o["height"] - pre_obs.get("height", 0.0)) / 10.0
		var pre_span = max(pre_obs.get("span_x", 0.0), pre_obs.get("span_z", 0.0))
		var cur_span = max(o["span_x"], o["span_z"])
		delta_span = max(0.0, cur_span - pre_span) / 10.0

	# Combined reward
	var base_reward = wH * (height + delta_height * 0.5) + \
					  wS * (span + delta_span * 0.5) - \
					  wN * pieces - \
					  wK * ke - \
					  wM * margin_pen

	var bonus_reward = wSym * symmetry + \
					   wCon * connectivity + \
					   wInt * integrity + \
					   wMot * motif_bonus + \
					   stability_bonus + \
					   0.2 * (height_eff + span_eff)

	return base_reward + bonus_reward

func _is_done(o: Dictionary) -> bool:
	if o["ke"] > 30.0: return true  # Catastrophic collapse
	if step_count >= 128: return true  # Episode length limit
	# Early termination if structure falls apart
	if bodies.size() > 3 and o.get("structural_integrity", 1.0) < 0.1:
		return true
	return false

# ========== GRAMMAR DISCOVERY FUNCTIONS ==========

func _save_success_episode(reward: float, final_obs: Dictionary) -> void:
	"""Save successful build episodes for analysis and replay"""
	var episode_data = {
		"reward": reward,
		"obs": final_obs,
		"placements": piece_placements.duplicate(true),
		"motifs_used": _extract_motifs_from_structure(),
		"episode": episode_count,
		"timestamp": Time.get_ticks_msec()
	}
	success_episodes.append(episode_data)
	# Keep only top N episodes
	if success_episodes.size() > 50:
		success_episodes.sort_custom(func(a, b): return a["reward"] > b["reward"])
		success_episodes.resize(50)
	print("BuildEnv: Saved success episode #%d (reward: %.2f)" % [episode_count, reward])

func _build_contact_graph() -> Array[Dictionary]:
	"""Build graph of which pieces are in contact with each other"""
	var graph: Array[Dictionary] = []
	for i in range(bodies.size()):
		var contacts: Array[int] = []
		var body_i = bodies[i]
		for j in range(bodies.size()):
			if i == j:
				continue
			var body_j = bodies[j]
			# Check if bodies are in contact
			if _bodies_in_contact(body_i, body_j):
				contacts.append(j)
		if not contacts.is_empty():
			graph.append({"body": i, "contacts": contacts})
	return graph

func _bodies_in_contact(b1: RigidBody3D, b2: RigidBody3D, threshold: float = 0.15) -> bool:
	"""Check if two rigid bodies are touching"""
	var dist = b1.global_position.distance_to(b2.global_position)
	# Quick distance check (approximate)
	return dist < threshold * 2.0

func _calculate_symmetry() -> float:
	"""Measure bilateral symmetry of structure (0 to 1)"""
	if bodies.size() < 2:
		return 0.0

	var com = _center_of_mass()
	var symmetry_score = 0.0
	var count = 0

	# Check X-axis symmetry
	for b in bodies:
		var pos = b.global_position
		var mirrored_x = Vector3(-pos.x + 2 * com.x, pos.y, pos.z)
		var closest_dist = INF
		for b2 in bodies:
			var dist = b2.global_position.distance_to(mirrored_x)
			closest_dist = min(closest_dist, dist)
		# If there's a piece close to the mirrored position, increment symmetry
		if closest_dist < 0.5:
			symmetry_score += 1.0
		count += 1

	return symmetry_score / max(1.0, float(count))

func _count_active_motifs() -> int:
	"""Count recognized motifs in current structure"""
	var count = 0
	for motif in motif_library:
		if _motif_present_in_structure(motif):
			count += 1
	return count

func _motif_present_in_structure(motif: Dictionary) -> bool:
	"""Check if a specific motif pattern exists in current structure"""
	var pattern = motif.get("pattern", [])
	if pattern.is_empty() or pattern.size() > bodies.size():
		return false
	# Simplified pattern matching - check if primitive sequence exists
	for start_idx in range(bodies.size() - pattern.size() + 1):
		var match_found = true
		for i in range(pattern.size()):
			var expected_prim = pattern[i].get("primitive_id", -1)
			var actual_prim = bodies[start_idx + i].get_meta("primitive_id", -1)
			if expected_prim != actual_prim:
				match_found = false
				break
		if match_found:
			return true
	return false

func _calculate_integrity() -> float:
	"""Measure structural integrity (connectivity + stability)"""
	if bodies.is_empty():
		return 1.0

	var graph = _build_contact_graph()
	var connectivity_ratio = float(graph.size()) / max(1.0, float(bodies.size()))

	# Check if all pieces are part of one connected component
	var visited = []
	visited.resize(bodies.size())
	for i in range(bodies.size()):
		visited[i] = false

	if graph.is_empty():
		return 0.0

	# DFS to find connected components
	_dfs_visit(0, graph, visited)
	var connected_count = 0
	for v in visited:
		if v:
			connected_count += 1

	var connection_score = float(connected_count) / max(1.0, float(bodies.size()))

	# Combine with stability
	var ke = _total_ke()
	var stability_score = clamp(1.0 - ke / 30.0, 0.0, 1.0)

	return 0.6 * connection_score + 0.4 * stability_score

func _dfs_visit(node: int, graph: Array[Dictionary], visited: Array) -> void:
	"""Depth-first search for connectivity check"""
	if node < 0 or node >= visited.size():
		return
	if visited[node]:
		return
	visited[node] = true
	# Find neighbors
	for entry in graph:
		if entry["body"] == node:
			for neighbor in entry["contacts"]:
				_dfs_visit(neighbor, graph, visited)
		# Reverse edge
		if node in entry.get("contacts", []):
			_dfs_visit(entry["body"], graph, visited)

func _update_structure_graph() -> void:
	"""Update the connectivity graph after placement"""
	current_structure_graph = _build_contact_graph()

func _detect_and_reward_motifs() -> void:
	"""Detect repeating stable patterns and add to motif library"""
	if not enable_motif_discovery:
		return

	# Only detect motifs if structure is stable
	var ke = _total_ke()
	if ke > stability_threshold:
		return

	# Look for stable sub-structures (groups of connected pieces)
	var graph = current_structure_graph
	if graph.size() < min_motif_pieces:
		return

	# Extract potential motifs (connected sub-graphs)
	var potential_motifs = _extract_connected_subgraphs(graph)

	for motif_data in potential_motifs:
		if motif_data["size"] >= min_motif_pieces and motif_data["size"] <= max_motif_pieces:
			_try_add_motif(motif_data)

func _extract_connected_subgraphs(graph: Array[Dictionary]) -> Array[Dictionary]:
	"""Find all connected sub-structures in the graph"""
	var subgraphs: Array[Dictionary] = []
	# Simplified: just return groups of min-max size
	if graph.size() >= min_motif_pieces:
		for i in range(graph.size() - min_motif_pieces + 1):
			var size = min(max_motif_pieces, graph.size() - i)
			if size >= min_motif_pieces:
				var pattern = []
				for j in range(size):
					var body_idx = graph[i + j]["body"]
					if body_idx < piece_placements.size():
						pattern.append(piece_placements[body_idx].duplicate())
				subgraphs.append({"size": size, "pattern": pattern})
	return subgraphs

func _try_add_motif(motif_data: Dictionary) -> void:
	"""Try to add a new motif to the library if it's novel"""
	# Check if similar motif already exists
	for existing in motif_library:
		if _motifs_similar(existing, motif_data):
			existing["count"] = existing.get("count", 1) + 1
			return

	# Add new motif
	motif_data["count"] = 1
	motif_data["discovered_episode"] = episode_count
	motif_library.append(motif_data)
	print("BuildEnv: Discovered new motif #%d (size: %d)" % [motif_library.size(), motif_data["size"]])

func _motifs_similar(m1: Dictionary, m2: Dictionary, threshold: float = 0.8) -> bool:
	"""Check if two motifs are similar"""
	var p1 = m1.get("pattern", [])
	var p2 = m2.get("pattern", [])
	if p1.size() != p2.size():
		return false
	var matches = 0
	for i in range(p1.size()):
		if p1[i].get("primitive_id", -1) == p2[i].get("primitive_id", -2):
			matches += 1
	return float(matches) / max(1.0, float(p1.size())) >= threshold

func _extract_motifs_from_structure() -> Array:
	"""Extract all recognized motifs from current structure"""
	var found_motifs = []
	for motif in motif_library:
		if _motif_present_in_structure(motif):
			found_motifs.append(motif.get("discovered_episode", -1))
	return found_motifs

func _place_motif(motif_id: int, action: Dictionary) -> bool:
	"""Place a learned motif pattern as a compound action"""
	if motif_id < 0 or motif_id >= motif_library.size():
		return false

	var motif = motif_library[motif_id]
	var pattern = motif.get("pattern", [])
	if pattern.is_empty():
		return false

	var base_x = action.get("x", 0.0)
	var base_z = action.get("z", 0.0)
	var success_count = 0

	# Place each piece in the motif pattern
	for piece in pattern:
		var relative_pos = piece.get("position", Vector3.ZERO)
		var piece_action = {
			"primitive_id": piece.get("primitive_id", 0),
			"x": base_x + relative_pos.x,
			"z": base_z + relative_pos.z,
			"yaw_bin": int(piece.get("yaw", 0.0) / TAU * yaw_bins)
		}
		if _place_action(piece_action):
			success_count += 1

	print("BuildEnv: Placed motif #%d (%d/%d pieces)" % [motif_id, success_count, pattern.size()])
	return success_count > 0

func _get_debug_info() -> Dictionary:
	"""Return debug information for logging/visualization"""
	return {
		"step": step_count,
		"episode": episode_count,
		"bodies": bodies.size(),
		"motifs_library": motif_library.size(),
		"success_episodes": success_episodes.size(),
		"graph_edges": current_structure_graph.size()
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
