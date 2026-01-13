extends Node3D

@export var snap_distance: float = 0.15
@export var connections_required_for_gravity: int = 3
@export var auto_find_triangles: bool = true
@export var add_floor: bool = true

var triangles: Array = []
var all_spheres: Array = []
var gravity_enabled: bool = false
var connection_count: int = 0

func _ready():
	if add_floor:
		_create_floor()
		
	if auto_find_triangles:
		find_triangles()
	
	# Delay collection to ensure triangles have finished _ready
	call_deferred("_initialize_unified_space")

func _create_floor():
	var floor_body = StaticBody3D.new()
	floor_body.name = "Floor"
	add_child(floor_body)
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(10, 0.1, 10)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position.y = -2.0 # Standard floor height for experiments

func _initialize_unified_space():
	# This is the "Fix in one go" logic:
	# 1. Reparent all spheres to this Manager
	# 2. Reset triangles to Identity transform
	# 3. Ensure they all speak the same local coordinate language
	
	for tri in triangles:
		var tri_original_global_pos = tri.global_position
		
		var drag_points = tri.get_node_or_null("DragPoints")
		if drag_points and drag_points.has_method("get_spheres"):
			var spheres = drag_points.get_spheres()
			for i in range(spheres.size()):
				var sphere = spheres[i]
				# Calculate its global position before we move anything
				var gpos = sphere.global_position
				
				# Move sphere to Manager (self)
				sphere.get_parent().remove_child(sphere)
				add_child(sphere)
				
				# Update its position relative to the Manager
				sphere.global_position = gpos
				
				# Tell the triangle's set to use this reparented node
				drag_points.replace_sphere(i, sphere)
		
		# Now that spheres are safe, reset the triangle itself to identity
		tri.transform = Transform3D.IDENTITY
		
		# Robust update call (handles both InteractiveTriangle and basic Triangle)
		if tri.has_method("update_triangle_meshes"):
			tri.update_triangle_meshes()
		elif tri.has_method("update_triangle_mesh"):
			tri.update_triangle_mesh()
		
	collect_spheres()

func find_triangles():
	triangles.clear()
	for child in get_children():
		if child.has_method("update_sphere_positions"):
			triangles.append(child)
	print("TriangleConnectionManager: Found %d triangles" % triangles.size())

func collect_spheres():
	all_spheres.clear()
	for tri in triangles:
		var drag_points = tri.get_node_or_null("DragPoints")
		if drag_points and drag_points.has_method("get_spheres"):
			var spheres = drag_points.get_spheres()
			for i in range(spheres.size()):
				var sphere = spheres[i]
				all_spheres.append({
					"node": sphere,
					"triangle": tri,
					"index": i
				})

func _process(_delta):
	_check_for_snaps()

func _check_for_snaps():
	for i in range(all_spheres.size()):
		var s1_data = all_spheres[i]
		var s1 = s1_data.node
		if not is_instance_valid(s1): continue
		
		for j in range(i + 1, all_spheres.size()):
			var s2_data = all_spheres[j]
			var s2 = s2_data.node
			if not is_instance_valid(s2): continue
			
			if s1_data.triangle == s2_data.triangle:
				continue
				
			# Check distance (now in shared Manager space)
			var dist = s1.position.distance_to(s2.position)
			if dist < snap_distance:
				_create_connection(s1_data, s2_data)

func _create_connection(s1_data, s2_data):
	var s1 = s1_data.node
	var s2 = s2_data.node
	if s1 == s2: return
	
	print("TriangleConnectionManager: Merging %s into shared vertex" % s2.name)
	
	# Move s2 to s1
	s2.global_position = s1.global_position
	
	# MERGE: Tell s2's triangle to use s1's node
	var tri2 = s2_data.triangle
	var drag_points2 = tri2.get_node_or_null("DragPoints")
	if drag_points2 and drag_points2.has_method("replace_sphere"):
		drag_points2.replace_sphere(s2_data.index, s1)
		
		# Update tracking
		s2_data.node = s1
		s2.queue_free()
		
		connection_count += 1
		print("TriangleConnectionManager: Connections: %d" % connection_count)

# Gravity activation disabled per user request
# func _check_gravity_condition():
# 	if not gravity_enabled and connection_count >= connections_required_for_gravity:
# 		activate_gravity()

# func activate_gravity():
# 	print("TriangleConnectionManager: GRAVITY ON")
# 	gravity_enabled = true
# 	
# 	for tri in triangles:
# 		var drag_points = tri.get_node_or_null("DragPoints")
# 		if drag_points:
# 			drag_points.freeze_on_drop = false
# 			drag_points.unfreeze_on_pickup = false
# 			
# 			var spheres = drag_points.get_spheres()
# 			for sphere in spheres:
# 				if is_instance_valid(sphere) and sphere is RigidBody3D:
# 					sphere.freeze = false
# 					sphere.sleeping = false
# 					sphere.gravity_scale = 1.0
# 					sphere.apply_central_impulse(Vector3(randf()-0.5, -0.2, randf()-0.5) * 0.2)
