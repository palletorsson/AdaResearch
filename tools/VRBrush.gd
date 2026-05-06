extends Node3D
class_name VRBrush
## A VR brush that raycasts, subdivides, and rounds geometry interactively.

@export var ray_length: float = 5.0
@export var brush_radius: float = 1.0
@export var max_edge_length: float = 0.6
@export var smooth_strength: float = 0.3
@export var subdivide_interval: float = 1.0

var mesh_instance: MeshInstance3D
var mesh: ArrayMesh
var st: SurfaceTool
var vertices: PackedVector3Array = []
var indices: PackedInt32Array = []
var last_action_time: float = 0.0

var raycast: RayCast3D
var rng := RandomNumberGenerator.new()
var grab_stick: Node3D
var grab_stick_area: Area3D
var mesh_static_body: StaticBody3D
var is_touching_mesh: bool = false
var last_touch_position: Vector3
var brush_indicator: MeshInstance3D


# ---------------------------------------------------------------------
# SETUP
# ---------------------------------------------------------------------
func _ready() -> void:
	rng.randomize()
	_setup_scene()

func _setup_scene() -> void:
	# Get the EditableMesh from scene (should already exist in VRBrush.tscn)
	mesh_instance = get_node_or_null("EditableMesh")

	if mesh_instance == null:
		# Create a base mesh if it doesn't exist
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "EditableMesh"
		mesh_instance.mesh = ArrayMesh.new()
		add_child(mesh_instance)

		var base := BoxMesh.new()
		base.size = Vector3(4, 1, 4)
		st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.create_from(base, 0)
		st.generate_normals()
		mesh = st.commit()
		mesh_instance.mesh = mesh
	else:
		# Use existing mesh from scene
		mesh = mesh_instance.mesh as ArrayMesh
		if mesh == null:
			# Convert to ArrayMesh if needed
			var original_mesh = mesh_instance.mesh
			st = SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.create_from(original_mesh, 0)
			st.generate_normals()
			mesh = st.commit()
			mesh_instance.mesh = mesh

	# Store arrays for dynamic editing
	if mesh and mesh.get_surface_count() > 0:
		var surface_arrays: Array = mesh.surface_get_arrays(0)
		vertices = surface_arrays[Mesh.ARRAY_VERTEX]
		indices = surface_arrays[Mesh.ARRAY_INDEX]
		_ensure_indices_from_vertices()

	# Get TheGrabStick from scene
	grab_stick = get_node_or_null("TheGrabStick")
	if grab_stick:
		_setup_grab_stick_collision()
	else:
		print("⚠️ VRBrush: TheGrabStick not found in scene!")

	# Create raycast for brush hit
	raycast = RayCast3D.new()
	raycast.enabled = true
	add_child(raycast)

	# Create brush radius indicator
	_create_brush_indicator()

func _setup_grab_stick_collision() -> void:
	"""Setup collision detection on TheGrabStick"""
	if not grab_stick:
		return

	# Find the TrackBall node (tip of the long stick)
	var track_ball = grab_stick.get_node_or_null("Blade/Top/TrackBall")
	if not track_ball:
		print("⚠️ VRBrush: TrackBall not found, using stick root")
		track_ball = grab_stick

	# Check if TrackBall already has a StaticBody3D
	var existing_static_body = track_ball.get_node_or_null("StaticBody3D")
	if existing_static_body:
		print("VRBrush: Found existing StaticBody3D at TrackBall")
		# StaticBody3D can't detect collisions with signals, so add Area3D to it
		grab_stick_area = Area3D.new()
		grab_stick_area.name = "TouchDetector"
		grab_stick_area.monitoring = true
		grab_stick_area.monitorable = false
		grab_stick_area.collision_layer = 0
		grab_stick_area.collision_mask = 1
		existing_static_body.add_child(grab_stick_area)

		# Try to use existing collision shape or create new one
		var existing_collision_shape = existing_static_body.get_node_or_null("CollisionShape3D")
		if existing_collision_shape and existing_collision_shape.shape:
			# Clone the existing shape for the Area3D
			var area_collision = CollisionShape3D.new()
			area_collision.shape = existing_collision_shape.shape.duplicate()
			grab_stick_area.add_child(area_collision)
			print("VRBrush: Reusing TrackBall collision shape")
		else:
			# Create new sphere shape
			var collision_shape = CollisionShape3D.new()
			var shape = SphereShape3D.new()
			shape.radius = brush_radius
			collision_shape.shape = shape
			grab_stick_area.add_child(collision_shape)

		# Connect signals from Area3D
		grab_stick_area.body_entered.connect(_on_grab_stick_touch_start)
		grab_stick_area.body_exited.connect(_on_grab_stick_touch_end)
		grab_stick_area.area_entered.connect(_on_grab_stick_area_entered)
	else:
		# Create Area3D for touch detection at TrackBall location
		print("VRBrush: No existing StaticBody3D, creating new Area3D at TrackBall")
		grab_stick_area = Area3D.new()
		grab_stick_area.name = "TouchDetector"
		grab_stick_area.monitoring = true
		grab_stick_area.monitorable = false
		grab_stick_area.collision_layer = 0
		grab_stick_area.collision_mask = 1
		track_ball.add_child(grab_stick_area)

		# Add collision shape to the area
		var collision_shape = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = brush_radius
		collision_shape.shape = shape
		grab_stick_area.add_child(collision_shape)

		# Connect signals
		grab_stick_area.body_entered.connect(_on_grab_stick_touch_start)
		grab_stick_area.body_exited.connect(_on_grab_stick_touch_end)
		grab_stick_area.area_entered.connect(_on_grab_stick_area_entered)

	# Ensure the EditableMesh's StaticBody is on layer 1
	mesh_static_body = mesh_instance.get_node_or_null("StaticBody3D") as StaticBody3D
	if mesh_static_body:
		mesh_static_body.collision_layer = 1
		mesh_static_body.collision_mask = 2  # Can detect stick on layer 2

	print("VRBrush: TheGrabStick collision detection setup complete")

func _on_grab_stick_touch_start(body: Node3D) -> void:
	"""Called when TheGrabStick touches a body"""
	# Check if it's touching the EditableMesh's StaticBody
	if body.get_parent() == mesh_instance or body.name == "StaticBody3D":
		is_touching_mesh = true
		print("VRBrush: TheGrabStick is touching the mesh!")

func _on_grab_stick_touch_end(body: Node3D) -> void:
	"""Called when TheGrabStick stops touching a body"""
	if body.get_parent() == mesh_instance or body.name == "StaticBody3D":
		is_touching_mesh = false
		print("VRBrush: TheGrabStick stopped touching the mesh")

func _on_grab_stick_area_entered(area: Area3D) -> void:
	"""Alternative collision detection for areas"""
	print("VRBrush: TheGrabStick area detected: ", area.name)

func _update_collision_shape() -> void:
	"""Update the collision shape to match the updated mesh"""
	var static_body = mesh_instance.get_node_or_null("StaticBody3D")
	if not static_body or not mesh_instance.mesh:
		return

	var collision_shape_node = static_body.get_node_or_null("CollisionShape3D")
	if not collision_shape_node:
		return

	# Create new collision shape from the updated mesh
	var shape = mesh_instance.mesh.create_trimesh_shape()
	if shape:
		collision_shape_node.shape = shape
		print("VRBrush: Collision shape updated")

func _create_brush_indicator() -> void:
	"""Create a visual indicator showing the brush radius"""
	brush_indicator = MeshInstance3D.new()
	brush_indicator.name = "BrushIndicator"

	# Create a sphere mesh for the indicator
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = brush_radius
	sphere_mesh.height = brush_radius * 2.0
	sphere_mesh.radial_segments = 16
	sphere_mesh.rings = 8
	brush_indicator.mesh = sphere_mesh

	# Create a semi-transparent material
	var indicator_material = StandardMaterial3D.new()
	indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	indicator_material.albedo_color = Color(1.0, 0.5, 0.0, 0.3)  # Orange, semi-transparent
	indicator_material.emission_enabled = true
	indicator_material.emission = Color(1.0, 0.5, 0.0)
	indicator_material.emission_energy_multiplier = 0.5
	indicator_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	brush_indicator.material_override = indicator_material

	brush_indicator.visible = false  # Hidden by default
	add_child(brush_indicator)


# ---------------------------------------------------------------------
# PROCESS LOOP
# ---------------------------------------------------------------------
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	last_action_time += delta

	var touch_fallback_active: bool = _is_trackball_touching_mesh()
	var touching_mesh_now: bool = is_touching_mesh or touch_fallback_active

	# Update brush indicator position to TrackBall location
	if touching_mesh_now and grab_stick:
		brush_indicator.visible = true
		# Try to use TrackBall position for more accurate brush location
		var track_ball = grab_stick.get_node_or_null("Blade/Top/TrackBall")
		if track_ball:
			brush_indicator.global_position = track_ball.global_position
		else:
			brush_indicator.global_position = grab_stick.global_position
	else:
		brush_indicator.visible = false

	# If TheGrabStick is touching the mesh, apply brush effect
	if touching_mesh_now and last_action_time >= subdivide_interval:
		last_action_time = 0.0
		_perform_grab_stick_brush_action()
	elif not touching_mesh_now and last_action_time >= subdivide_interval:
		# Use raycast method when not touching
		last_action_time = 0.0
		_perform_brush_action()


# ---------------------------------------------------------------------
# BRUSH ACTION
# ---------------------------------------------------------------------
func _perform_brush_action() -> void:
	# Update ray
	raycast.target_position = Vector3(0, 0, -ray_length)
	raycast.force_raycast_update()
	if not raycast.is_colliding():
		return

	var hit_pos: Vector3 = raycast.get_collision_point()
	_subdivide_region(hit_pos, brush_radius, max_edge_length)
	_round_region(hit_pos, brush_radius, smooth_strength)
	_commit_mesh()

func _perform_grab_stick_brush_action() -> void:
	"""Apply brush effect at TheGrabStick TrackBall position when touching mesh"""
	if not grab_stick:
		return

	# Use TrackBall position (tip of stick) for more precise brush effect
	var track_ball = grab_stick.get_node_or_null("Blade/Top/TrackBall")
	var touch_pos: Vector3
	if track_ball:
		touch_pos = track_ball.global_position
	else:
		touch_pos = grab_stick.global_position

	last_touch_position = touch_pos

	# Apply subdivision and rounding at touch point
	_subdivide_region(touch_pos, brush_radius, max_edge_length)
	_round_region(touch_pos, brush_radius, smooth_strength)
	_commit_mesh()

	print("VRBrush: Applied brush effect at TrackBall position: ", touch_pos)


# ---------------------------------------------------------------------
# SUBDIVISION
# ---------------------------------------------------------------------
func _subdivide_region(center: Vector3, radius: float, max_len: float) -> void:
	if mesh_instance == null or mesh_instance.mesh == null:
		return

	var r2: float = radius * radius
	var new_tris: PackedInt32Array = PackedInt32Array()
	var new_verts: PackedVector3Array = vertices.duplicate()
	var midpoint_cache: Dictionary = {}  # key: "minIdx_maxIdx" -> vertex index

	# helper closures
	var key_for = func(_i: int, _j: int) -> String:
		return "%s_%s" % [min(_i, _j), max(_i, _j)]

	var midpoint_index = func(_i: int, _j: int) -> int:
		var k: String = key_for.call(_i, _j)  # Fixed: Explicit type to avoid Variant warning
		if midpoint_cache.has(k):
			return int(midpoint_cache[k])
		var m := (new_verts[_i] + new_verts[_j]) * 0.5
		var new_idx := new_verts.size()
		new_verts.append(m)
		midpoint_cache[k] = new_idx
		return new_idx

	# triangle loop
	for t in range(0, indices.size(), 3):
		var a: int = indices[t]
		var b: int = indices[t + 1]
		var c: int = indices[t + 2]
		var tri_center: Vector3 = (vertices[a] + vertices[b] + vertices[c]) / 3.0

		if tri_center.distance_squared_to(center) > r2:
			new_tris.append_array([a, b, c])
			continue

		var pa: Vector3 = vertices[a]
		var pb: Vector3 = vertices[b]
		var pc: Vector3 = vertices[c]
		var dab: float = pa.distance_to(pb)
		var dbc: float = pb.distance_to(pc)
		var dca: float = pc.distance_to(pa)

		var ab_mid: int = -1
		var bc_mid: int = -1
		var ca_mid: int = -1

		if dab > max_len:
			ab_mid = midpoint_index.call(a, b)
		if dbc > max_len:
			bc_mid = midpoint_index.call(b, c)
		if dca > max_len:
			ca_mid = midpoint_index.call(c, a)

		var splits := int(ab_mid != -1) + int(bc_mid != -1) + int(ca_mid != -1)

		# rebuild triangles
		if splits == 0:
			new_tris.append_array([a, b, c])
		elif splits == 1:
			if ab_mid != -1:
				new_tris.append_array([a, ab_mid, c, ab_mid, b, c])
			elif bc_mid != -1:
				new_tris.append_array([b, bc_mid, a, bc_mid, c, a])
			else:
				new_tris.append_array([c, ca_mid, b, ca_mid, a, b])
		elif splits == 2:
			if ab_mid == -1:
				new_tris.append_array([a, b, ca_mid, b, bc_mid, ca_mid, ca_mid, bc_mid, c])
			elif bc_mid == -1:
				new_tris.append_array([a, ab_mid, c, ab_mid, b, ca_mid, ca_mid, b, c])
			else:
				new_tris.append_array([a, ab_mid, c, ab_mid, b, bc_mid, ab_mid, bc_mid, c])
		else:
			new_tris.append_array([
				a, ab_mid, ca_mid,
				ab_mid, b, bc_mid,
				ca_mid, bc_mid, c,
				ab_mid, bc_mid, ca_mid
			])

	# write back
	vertices = new_verts
	indices = new_tris


# ---------------------------------------------------------------------
# ROUNDING / SMOOTHING
# ---------------------------------------------------------------------
func _round_region(center: Vector3, radius: float, strength: float) -> void:
	var r2: float = radius * radius
	for i in range(vertices.size()):
		var v: Vector3 = vertices[i]
		var dist2: float = v.distance_squared_to(center)
		if dist2 > r2:
			continue
		var dir := (v - center).normalized()
		var factor: float = 1.0 - sqrt(dist2) / radius
		vertices[i] = v + dir * factor * strength * 0.1


# ---------------------------------------------------------------------
# COMMIT MESH
# ---------------------------------------------------------------------
func _commit_mesh() -> void:
	if vertices.is_empty() or indices.is_empty():
		return

	# Store the current material to preserve the shader
	var current_material = mesh_instance.material_override

	var st2 := SurfaceTool.new()
	st2.begin(Mesh.PRIMITIVE_TRIANGLES)
	for idx in indices:
		st2.add_vertex(vertices[idx])
	st2.generate_normals()

	var new_mesh := st2.commit()
	mesh_instance.mesh = new_mesh

	# Restore the material (including the SimpleGrid shader)
	if current_material:
		mesh_instance.material_override = current_material

	# Update collision shape to match new mesh
	_update_collision_shape()

func _ensure_indices_from_vertices() -> void:
	# SurfaceTool commits can produce non-indexed triangle arrays. Build a fallback.
	if not indices.is_empty():
		return

	if vertices.is_empty():
		return

	var vertex_count: int = vertices.size()
	if vertex_count < 3:
		return

	var triangle_vertex_count: int = vertex_count - (vertex_count % 3)
	if triangle_vertex_count < 3:
		return

	var rebuilt_indices: PackedInt32Array = PackedInt32Array()
	rebuilt_indices.resize(triangle_vertex_count)
	for i in range(triangle_vertex_count):
		rebuilt_indices[i] = i
	indices = rebuilt_indices

func _is_trackball_touching_mesh() -> bool:
	if grab_stick == null or mesh_static_body == null or mesh_instance == null:
		return false

	var track_ball: Node3D = grab_stick.get_node_or_null("Blade/Top/TrackBall") as Node3D
	var probe_origin: Vector3 = grab_stick.global_position
	if track_ball != null:
		probe_origin = track_ball.global_position

	var shape_query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	var probe_shape: SphereShape3D = SphereShape3D.new()
	probe_shape.radius = maxf(brush_radius * 0.6, 0.05)
	shape_query.shape = probe_shape
	shape_query.transform = Transform3D(Basis.IDENTITY, probe_origin)
	shape_query.collide_with_bodies = true
	shape_query.collide_with_areas = false
	shape_query.collision_mask = 1

	var world: World3D = get_world_3d()
	if world == null:
		return false

	var space_state: PhysicsDirectSpaceState3D = world.direct_space_state
	var hits: Array = space_state.intersect_shape(shape_query, 8)
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider == mesh_static_body:
			return true

	return false
