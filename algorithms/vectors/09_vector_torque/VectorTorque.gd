extends "res://algorithms/vectors/shared/vector_scene_base.gd"

var radius_vector: Node3D
var force_vector: Node3D
var torque_vector: Node3D
var moment_arm_vector: Node3D
var info_label: Label3D
var _wheel_mesh: MeshInstance3D

var _cached_radius_nodes: Dictionary = {}
var _cached_force_nodes: Dictionary = {}
var _cached_torque_nodes: Dictionary = {}
var _cached_moment_arm_nodes: Dictionary = {}
var _time_since_last_text_update := 0.0

func _ready():
	super._ready()
	create_axes(3.5)
	
	# Add a visual wheel to represent what we are torquing
	_create_wheel()
	
	# Initial positions scaled by base class logic
	radius_vector = spawn_vector(Vector3.ZERO, Vector3(1.4, 0.8, 0.0), Color(1.0, 0.6, 0.2, 1.0), "r")
	force_vector = spawn_vector(Vector3.ZERO, Vector3(0.0, 1.4, 1.0), Color(0.2, 0.8, 1.0, 1.0), "F")
	torque_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.9, 0.6, 1.0, 1.0), "tau", false)
	moment_arm_vector = spawn_vector(Vector3.ZERO, Vector3.ZERO, Color(0.7, 1.0, 0.4, 1.0), "r_perp", false)
	
	var force_start = force_vector.get_node_or_null("lineContainer/GrabSphere")
	if force_start:
		_disable_grab_sphere(force_start)
		
	info_label = create_info_panel("Torque", Vector3(-3.0, 2.2, 0.0))
	
	# Cache nodes
	_cache_vector_nodes(radius_vector, _cached_radius_nodes)
	_cache_vector_nodes(force_vector, _cached_force_nodes)
	_cache_vector_nodes(torque_vector, _cached_torque_nodes)
	_cache_vector_nodes(moment_arm_vector, _cached_moment_arm_nodes)

func _process(delta):
	var r = _get_vector_fast(radius_vector, _cached_radius_nodes)
	var f = _get_vector_fast(force_vector, _cached_force_nodes)
	
	# Update wheel orientation to match 'r' being a point on it?
	# No, 'r' is the lever arm. The wheel is at origin.
	# We can scale the wheel to match r's length if we want, or keep it static.
	# Let's just rotate the wheel slightly based on torque magnitude for effect? 
	# No, this is a static diagram.
	
	# Update force position to tip of r
	var r_end_local = to_local(get_arrow_end_position(radius_vector))
	force_vector.position = r_end_local
	
	var torque = r.cross(f)
	
	_update_vector_fast(torque_vector, torque, _cached_torque_nodes)
	_update_moment_arm(r, f)
	
	_time_since_last_text_update += delta
	if _time_since_last_text_update > 0.1:
		_update_info(r, f, torque)
		_time_since_last_text_update = 0.0

func _create_wheel():
	_wheel_mesh = MeshInstance3D.new()
	# Use shared cylinder but flatten it
	var mesh = CylinderMesh.new()
	mesh.top_radius = 1.0 * SCENE_SCALE
	mesh.bottom_radius = 1.0 * SCENE_SCALE
	mesh.height = 0.1 * SCENE_SCALE
	mesh.radial_segments = 32
	_wheel_mesh.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.5, 0.5, 0.3) # Transparent grey
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_wheel_mesh.material_override = mat
	
	# Orient flat on XZ plane (rotate 90 around X? No, Cylinder is upright Y)
	# Torque usually rotates around the axis perpendicular to r and F.
	# If r and F are in arbitrary planes, the "wheel" plane is defined by r and F?
	# Or we just put a reference disk on the ground.
	# Let's orient it along the Torque vector? That would be cool.
	environment_root.add_child(_wheel_mesh)

func _update_moment_arm(r: Vector3, f: Vector3):
	if f.length() < 0.001:
		_update_vector_fast(moment_arm_vector, Vector3.ZERO, _cached_moment_arm_nodes)
		return
		
	var f_dir = f.normalized()
	var perpendicular = r - f_dir * r.dot(f_dir)
	
	moment_arm_vector.position = Vector3.ZERO # Start at origin
	_update_vector_fast(moment_arm_vector, perpendicular, _cached_moment_arm_nodes)
	
	# Update wheel orientation to face the Torque vector
	# The wheel spins around the torque axis.
	# Cylinder aligns with Y. We want Y to align with Torque.
	var torque = r.cross(f)
	if torque.length_squared() > 0.01:
		var up = Vector3.UP
		var target = torque.normalized()
		var axis = up.cross(target).normalized()
		var angle = acos(clamp(up.dot(target), -1.0, 1.0))
		
		if axis.length_squared() > 0.001:
			_wheel_mesh.global_transform.basis = Basis(axis, angle)
			# Scale radius to match r length roughly
			var r_len = r.length() * SCENE_SCALE
			_wheel_mesh.scale = Vector3(r_len, 1.0, r_len) 
		else:
			# Parallel to up, just sign flip maybe
			if up.dot(target) < 0:
				_wheel_mesh.scale.y = -1.0 

func _update_info(r: Vector3, f: Vector3, torque: Vector3):
	var builder := []
	builder.append("r = (%.2f, %.2f, %.2f)" % [r.x, r.y, r.z])
	builder.append("F = (%.2f, %.2f, %.2f)" % [f.x, f.y, f.z])
	builder.append("tau = r x F")
	builder.append("|tau| = %.2f" % torque.length())
	if r.length() > 0.001 and f.length() > 0.001:
		var sin_theta = torque.length() / (r.length() * f.length())
		builder.append("Efficiency: %.0f%%" % (clamp(sin_theta, 0.0, 1.0) * 100.0))
	info_label.text = "\n".join(builder)

# Cache Helpers (Copy from VectorSceneBase or similar)
func _cache_vector_nodes(arrow_root: Node3D, cache_dict: Dictionary):
	if not arrow_root: return
	cache_dict["start"] = arrow_root.get_node_or_null("lineContainer/GrabSphere")
	cache_dict["end"] = arrow_root.get_node_or_null("lineContainer/GrabSphere2")
	cache_dict["line"] = arrow_root.get_node_or_null("lineContainer")

func _get_vector_fast(arrow_root: Node3D, cache_dict: Dictionary) -> Vector3:
	if not arrow_root: return Vector3.ZERO
	var start = cache_dict.get("start")
	var end = cache_dict.get("end")
	if start and end:
		return (end.global_position - start.global_position) / SCENE_SCALE
	return Vector3.ZERO

func _update_vector_fast(arrow_root: Node3D, vector: Vector3, cache_dict: Dictionary):
	if not arrow_root: return
	var end = cache_dict.get("end")
	if end:
		end.position = vector * SCENE_SCALE
	var line = cache_dict.get("line")
	if line and line.has_method("refresh_connections"):
		line.refresh_connections()



