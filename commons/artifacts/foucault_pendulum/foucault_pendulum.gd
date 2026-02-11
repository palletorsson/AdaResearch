# foucault_pendulum.gd
# Foucault Pendulum - demonstrates Earth's rotation through precessing swing plane
# Draws rosette patterns on a horizontal canvas below

extends Node3D

class_name FoucaultPendulum

@export_category("Pendulum")
@export var pendulum_length: float = 8.0  # Height above canvas
@export var cone_radius: float = 0.08
@export var cone_height: float = 0.25
@export var wire_thickness: float = 0.008
@export var initial_amplitude: float = 0.4  # Initial swing angle (radians)
@export var initial_direction: float = 0.0  # Initial swing direction (radians)
@export var tip_hover_height: float = 0.02  # How close tip gets to canvas

@export_category("Physics")
@export var gravity: float = 9.81
@export var damping: float = 0.0002  # Very light damping
@export var earth_rotation_rate: float = 0.05  # Earth rotation speed (radians/sec, exaggerated)
@export var latitude: float = 45.0  # Degrees - affects precession rate (90=pole, 0=equator)
@export var drive_enabled: bool = true  # Electromagnetic drive to maintain swing
@export var target_amplitude: float = 0.4  # Target swing amplitude (radians)
@export var drive_strength: float = 0.02  # How strongly drive corrects amplitude

@export_category("Gravity Spheres")
@export var gravity_spheres_enabled: bool = true
@export var num_gravity_spheres: int = 8
@export var sphere_gravity_strength: float = 0.5  # How strongly spheres pull the pendulum
@export var sphere_radius: float = 0.25  # Bigger spheres
@export var sphere_influence_radius: float = 2.0  # Max distance for gravity effect
@export var sphere_color: Color = Color(0.6, 0.3, 0.9)  # Purple

@export_category("Canvas")
@export var canvas_size: float = 6.0
@export var canvas_color: Color = Color(0.95, 0.93, 0.88)  # Cream paper
@export var show_frame: bool = true  # Toggle frame visibility

@export_category("Sine Modulation")
@export var sine_modulation_enabled: bool = false
@export var sine_modulation_amplitude: float = 0.08  # Subtle variation
@export var sine_modulation_frequency: float = 0.3  # Slow oscillation

@export_category("Drawing")
@export var marker_color: Color = Color(0.08, 0.06, 0.04)  # Dark ink
@export var marker_width: float = 0.02
@export var max_trail_points: int = 8000
@export var draw_height: float = 0.01  # Slightly above canvas

# State
var theta: float = 0.0  # Swing angle
var omega: float = 0.0  # Angular velocity
var swing_direction: float = 0.0  # Fixed swing plane (inertial frame)
var earth_angle: float = 0.0  # Earth's rotation angle
var trail_points: PackedVector3Array = PackedVector3Array()

# Nodes
var _pivot: Node3D
var _wire: MeshInstance3D
var _cone: MeshInstance3D
var _canvas: MeshInstance3D
var _canvas_body: StaticBody3D
var _trail_mesh: MeshInstance3D
var _ceiling_mount: MeshInstance3D
var _title_label: Label3D
var _ray: RayCast3D
var _debug_line: MeshInstance3D
var _debug_tip: MeshInstance3D
var _earth_ring: Node3D  # Rotating reference frame
var _compass_markers: Array[Node3D] = []
var _gravity_spheres: Array[Node3D] = []  # Grabbable attractors

func _ready():
	# Initialize state
	theta = initial_amplitude
	omega = 0.0
	swing_direction = initial_direction
	earth_angle = 0.0
	
	_create_podium()
	_create_ceiling_mount()
	_create_pivot()
	_create_wire()
	_create_cone()
	_create_raycast()
	_create_canvas()
	_create_earth_ring()
	_create_gravity_spheres()
	_create_trail_mesh()
	_create_labels()
	_create_debug_visuals()
	_update_pendulum_visual()
	
	print("FoucaultPendulum ready - latitude: ", latitude, "° | precession = Earth × sin(lat)")


func _create_podium():
	"""Create a podium/pedestal underneath the pendulum visualization"""
	var podium = Node3D.new()
	podium.name = "Podium"
	
	# Main podium cylinder
	var base = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = canvas_size / 2.0 + 0.5
	cyl.bottom_radius = canvas_size / 2.0 + 0.7
	cyl.height = 0.8
	base.mesh = cyl
	base.position = Vector3(0, -0.4, 0)
	
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.2, 0.18, 0.16)
	base_mat.metallic = 0.1
	base_mat.roughness = 0.8
	base.material_override = base_mat
	podium.add_child(base)
	
	# Decorative rim at top
	var rim = MeshInstance3D.new()
	var rim_torus = TorusMesh.new()
	rim_torus.inner_radius = canvas_size / 2.0 + 0.35
	rim_torus.outer_radius = canvas_size / 2.0 + 0.55
	rim_torus.rings = 32
	rim_torus.ring_segments = 8
	rim.mesh = rim_torus
	rim.position = Vector3(0, -0.02, 0)
	rim.rotation.x = PI / 2
	
	var rim_mat = StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.6, 0.5, 0.35)
	rim_mat.metallic = 0.6
	rim_mat.roughness = 0.4
	rim.material_override = rim_mat
	podium.add_child(rim)
	
	# Lower stepped base
	var lower_base = MeshInstance3D.new()
	var lower_cyl = CylinderMesh.new()
	lower_cyl.top_radius = canvas_size / 2.0 + 0.7
	lower_cyl.bottom_radius = canvas_size / 2.0 + 0.9
	lower_cyl.height = 0.3
	lower_base.mesh = lower_cyl
	lower_base.position = Vector3(0, -0.95, 0)
	lower_base.material_override = base_mat
	podium.add_child(lower_base)
	
	add_child(podium)


func _create_ceiling_mount():
	_ceiling_mount = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.15
	cyl.height = 0.1
	_ceiling_mount.mesh = cyl
	_ceiling_mount.position = Vector3(0, pendulum_length + 0.05, 0)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.22, 0.2)
	mat.metallic = 0.7
	mat.roughness = 0.3
	_ceiling_mount.material_override = mat
	add_child(_ceiling_mount)


func _create_pivot():
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	_pivot.position = Vector3(0, pendulum_length, 0)
	add_child(_pivot)


func _create_wire():
	_wire = MeshInstance3D.new()
	_wire.name = "Wire"
	
	var cyl = CylinderMesh.new()
	cyl.top_radius = wire_thickness
	cyl.bottom_radius = wire_thickness
	cyl.height = pendulum_length
	_wire.mesh = cyl
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.32)
	mat.metallic = 0.8
	mat.roughness = 0.2
	_wire.material_override = mat
	
	_pivot.add_child(_wire)


func _create_cone():
	_cone = MeshInstance3D.new()
	_cone.name = "Cone"
	
	# Cone pointing downward (tip at bottom)
	var cone_mesh = CylinderMesh.new()
	cone_mesh.top_radius = cone_radius
	cone_mesh.bottom_radius = 0.0  # Point at bottom
	cone_mesh.height = cone_height
	cone_mesh.radial_segments = 24
	_cone.mesh = cone_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.6, 0.15)  # Brass
	mat.metallic = 0.9
	mat.roughness = 0.2
	_cone.material_override = mat
	
	_pivot.add_child(_cone)


func _create_raycast():
	_ray = RayCast3D.new()
	_ray.name = "TipRay"
	_ray.target_position = Vector3(0, -0.5, 0)  # Point straight down
	_ray.enabled = true
	_ray.exclude_parent = true
	_ray.collide_with_areas = false
	_ray.collide_with_bodies = true
	_ray.collision_mask = 1  # Default layer
	# Position ray at the tip of the cone
	_ray.position = Vector3(0, -cone_height / 2.0, 0)
	_cone.add_child(_ray)


func _create_canvas():
	# StaticBody for raycast collision
	_canvas_body = StaticBody3D.new()
	_canvas_body.name = "CanvasBody"
	_canvas_body.collision_layer = 1
	_canvas_body.collision_mask = 1
	add_child(_canvas_body)
	
	# Collision shape - thicker and centered at y=0
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(canvas_size, 0.1, canvas_size)
	collision.shape = box_shape
	collision.position = Vector3(0, -0.05, 0)  # Top surface at y=0
	_canvas_body.add_child(collision)
	
	# Visual mesh
	_canvas = MeshInstance3D.new()
	_canvas.name = "CanvasSurface"
	
	var plane = PlaneMesh.new()
	plane.size = Vector2(canvas_size, canvas_size)
	_canvas.mesh = plane
	_canvas.position = Vector3(0, 0, 0)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = canvas_color
	mat.roughness = 0.95
	mat.metallic = 0.0
	_canvas.material_override = mat
	_canvas_body.add_child(_canvas)
	
	# Frame (optional)
	if show_frame:
		_add_canvas_frame()


func _add_canvas_frame():
	var frame_thickness = 0.15  # Thicker for better collision
	var frame_height = 0.4  # Taller to contain spheres
	var half = canvas_size / 2.0
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.12, 0.1)
	mat.roughness = 0.8
	
	# Four sides: [size, position]
	var sides = [
		[Vector3(canvas_size + frame_thickness * 2, frame_height, frame_thickness), Vector3(0, frame_height/2, half + frame_thickness/2)],
		[Vector3(canvas_size + frame_thickness * 2, frame_height, frame_thickness), Vector3(0, frame_height/2, -half - frame_thickness/2)],
		[Vector3(frame_thickness, frame_height, canvas_size), Vector3(-half - frame_thickness/2, frame_height/2, 0)],
		[Vector3(frame_thickness, frame_height, canvas_size), Vector3(half + frame_thickness/2, frame_height/2, 0)],
	]
	
	for i in range(sides.size()):
		var side = sides[i]
		
		# StaticBody for collision
		var body = StaticBody3D.new()
		body.name = "FrameWall_%d" % i
		body.position = side[1]
		add_child(body)
		
		# Collision shape
		var collision = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = side[0]
		collision.shape = box_shape
		body.add_child(collision)
		
		# Visual mesh
		var mesh = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = side[0]
		mesh.mesh = box
		mesh.material_override = mat
		body.add_child(mesh)


func _create_earth_ring():
	# Rotating ring representing Earth's reference frame
	_earth_ring = Node3D.new()
	_earth_ring.name = "EarthRing"
	add_child(_earth_ring)
	
	var ring_radius = canvas_size / 2.0 + 0.3
	var ring_height = 0.02
	
	# Ring mesh (torus approximated with segments)
	var ring_mesh = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = ring_radius - 0.04
	torus.outer_radius = ring_radius + 0.04
	torus.rings = 32
	torus.ring_segments = 12
	ring_mesh.mesh = torus
	ring_mesh.position.y = ring_height
	ring_mesh.rotation.x = PI / 2  # Lay flat
	
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.4, 0.35, 0.3)
	ring_mat.metallic = 0.3
	ring_mat.roughness = 0.7
	ring_mesh.material_override = ring_mat
	_earth_ring.add_child(ring_mesh)
	
	# Compass markers removed - cleaner visualization


func _create_gravity_spheres():
	if not gravity_spheres_enabled:
		return
	
	var SIMPLE_GRAB_SPHERE = load("res://commons/primitives/point/simple_grab_sphere.tscn")
	var ring_radius = canvas_size / 2.0 + 0.8
	
	for i in range(num_gravity_spheres):
		var angle = i * TAU / num_gravity_spheres
		var sphere: Node3D
		
		if SIMPLE_GRAB_SPHERE:
			sphere = SIMPLE_GRAB_SPHERE.instantiate()
			
			# Modify collision shape size (don't scale the node!)
			var collision = sphere.get_node_or_null("CollisionShape3D")
			if collision and collision.shape is SphereShape3D:
				collision.shape.radius = sphere_radius
			
			# Modify mesh size
			var mesh = sphere.get_node_or_null("MeshInstance3D")
			if mesh and mesh.mesh is SphereMesh:
				mesh.mesh.radius = sphere_radius
				mesh.mesh.height = sphere_radius * 2.0
			
			# Set color
			if mesh:
				var mat = StandardMaterial3D.new()
				mat.albedo_color = sphere_color
				mat.emission_enabled = true
				mat.emission = sphere_color
				mat.emission_energy_multiplier = 1.0
				mat.metallic = 0.3
				mat.roughness = 0.4
				mesh.material_override = mat
		else:
			# Fallback
			sphere = _create_simple_gravity_sphere(sphere_color)
		
		sphere.name = "GravitySphere_%d" % i
		
		# Position around the canvas
		add_child(sphere)
		sphere.global_position = global_position + Vector3(
			cos(angle) * ring_radius,
			0.3,
			sin(angle) * ring_radius
		)
		
		# Store metadata
		sphere.set_meta("gravity_strength", sphere_gravity_strength)
		sphere.set_meta("sphere_index", i)
		
		_gravity_spheres.append(sphere)
	
	print("Created %d gravity spheres" % _gravity_spheres.size())


func _create_simple_gravity_sphere(color: Color) -> Node3D:
	# Fallback if grab_sphere_point.tscn not available
	var root = Node3D.new()
	
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = sphere_radius
	sphere.height = sphere_radius * 2
	mesh.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	mat.metallic = 0.3
	mat.roughness = 0.4
	mesh.material_override = mat
	
	root.add_child(mesh)
	return root


func _create_trail_mesh():
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "Trail"
	# Trail points already have draw_height baked in
	add_child(_trail_mesh)


func _create_debug_visuals():
	# Debug sphere at tip position
	_debug_tip = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	_debug_tip.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	mat.emission_enabled = true
	mat.emission = Color.RED
	mat.emission_energy_multiplier = 2.0
	_debug_tip.material_override = mat
	add_child(_debug_tip)
	
	# Debug line from tip to canvas
	_debug_line = MeshInstance3D.new()
	_debug_line.name = "DebugRay"
	add_child(_debug_line)


func _create_labels():
	_title_label = Label3D.new()
	_title_label.text = "Foucault Pendulum"
	_title_label.font_size = 64
	_title_label.position = Vector3(0, pendulum_length + 0.5, 0)
	_title_label.modulate = Color(0.2, 0.18, 0.15)
	_title_label.outline_size = 4
	add_child(_title_label)
	
	var precession_factor = sin(deg_to_rad(latitude))
	var info = Label3D.new()
	info.text = "Latitude: %.0fÂ° | Precession = Î© Ã— sin(%.0fÂ°) = %.2fÃ—Î©" % [latitude, latitude, precession_factor]
	info.font_size = 28
	info.position = Vector3(0, pendulum_length + 0.2, 0)
	info.modulate = Color(0.4, 0.35, 0.3)
	add_child(info)
	
	var info2 = Label3D.new()
	info2.text = "Ring rotates with Earth â€” pendulum swings in fixed plane"
	info2.font_size = 24
	info2.position = Vector3(0, pendulum_length - 0.05, 0)
	info2.modulate = Color(0.5, 0.45, 0.4)
	add_child(info2)


func _physics_process(delta: float):
	# Simple pendulum physics: Î¸'' = -(g/L) * sin(Î¸)
	var angular_acceleration = -(gravity / pendulum_length) * sin(theta)
	
	# Apply subtle sine-wave modulation (Foucault-inspired variation)
	if sine_modulation_enabled:
		var sine_mod = sin(Time.get_ticks_msec() * 0.001 * sine_modulation_frequency * TAU)
		angular_acceleration += sine_mod * sine_modulation_amplitude * 0.1
	
	omega += angular_acceleration * delta
	omega *= (1.0 - damping)  # Apply damping
	theta += omega * delta
	
	# Apply gravity sphere forces
	if gravity_spheres_enabled and _gravity_spheres.size() > 0:
		_apply_gravity_sphere_forces(delta)
	
	# Electromagnetic drive - adds energy when amplitude drops below target
	# Real Foucault pendulums use this to run indefinitely
	if drive_enabled:
		_apply_drive(delta)
	
	# Earth rotates beneath the pendulum
	# Precession rate = Earth rotation Ã— sin(latitude)
	# At poles (90Â°): full rotation; at equator (0Â°): no precession
	var precession_rate = earth_rotation_rate * sin(deg_to_rad(latitude))
	earth_angle += earth_rotation_rate * delta
	
	# The pendulum appears to precess because we're in Earth's rotating frame
	# Swing direction changes relative to Earth at precession_rate
	swing_direction += precession_rate * delta
	
	# Rotate the Earth reference ring
	if _earth_ring:
		_earth_ring.rotation.y = earth_angle
	
	_update_pendulum_visual()
	_update_debug_visuals()
	_record_trail_point()
	_update_trail_mesh()


func _apply_gravity_sphere_forces(delta: float):
	if not _cone:
		return
	
	# Get pendulum bob position (in local coordinates relative to our root)
	var bob_world = _cone.global_position
	var bob_local = bob_world - global_position
	var bob_xz = Vector2(bob_local.x, bob_local.z)
	
	# Accumulate force from all gravity spheres
	var total_force = Vector2.ZERO
	
	for sphere in _gravity_spheres:
		if not is_instance_valid(sphere):
			continue
		
		# Sphere position (local to our root)
		var sphere_world = sphere.global_position
		var sphere_local = sphere_world - global_position
		var sphere_xz = Vector2(sphere_local.x, sphere_local.z)
		
		# Direction and distance from bob to sphere
		var to_sphere = sphere_xz - bob_xz
		var distance = to_sphere.length()
		
		# Skip if too far or too close
		if distance > sphere_influence_radius or distance < 0.1:
			continue
		
		# Gravity falls off with distance squared (inverse square law)
		var strength = sphere.get_meta("gravity_strength", sphere_gravity_strength)
		var force_magnitude = strength / (distance * distance)
		
		# Clamp to avoid extreme forces when very close
		force_magnitude = min(force_magnitude, strength * 10.0)
		
		# Add force toward sphere
		total_force += to_sphere.normalized() * force_magnitude
	
	# Convert XZ force to pendulum perturbation
	# Force affects swing angle and direction
	if total_force.length() > 0.001:
		# Component along current swing direction adds/subtracts from omega
		var swing_vec = Vector2(cos(swing_direction), sin(swing_direction))
		var parallel_force = total_force.dot(swing_vec)
		omega += parallel_force * delta * 0.5
		
		# Component perpendicular to swing shifts the swing direction
		var perp_vec = Vector2(-sin(swing_direction), cos(swing_direction))
		var perp_force = total_force.dot(perp_vec)
		swing_direction += perp_force * delta * 0.1


func _apply_drive(_delta: float):
	# Estimate current amplitude from max theta reached
	# Drive kicks in near the center (theta â‰ˆ 0) when velocity is highest
	
	# Only apply drive near center of swing (where real EM drives work)
	if abs(theta) > 0.05:
		return
	
	# Check if we need more energy (amplitude too low)
	# Use omega to estimate amplitude: at center, omega â‰ˆ sqrt(g/L) * amplitude
	var estimated_amplitude = abs(omega) * sqrt(pendulum_length / gravity)
	
	if estimated_amplitude < target_amplitude:
		# Add energy in the direction of motion
		var boost = drive_strength * sign(omega)
		omega += boost


func _update_debug_visuals():
	if not _cone or not _debug_tip:
		return
	
	# Tip position in world space
	var tip_world = _cone.global_position + Vector3(0, -cone_height / 2.0, 0)
	_debug_tip.global_position = tip_world
	
	# Canvas point (y = our global y origin, i.e. where canvas sits)
	var canvas_y = global_position.y
	var canvas_point = Vector3(tip_world.x, canvas_y, tip_world.z)
	
	# Convert to local space for mesh vertices
	var local_tip = tip_world - global_position
	var local_canvas = canvas_point - global_position
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	st.set_color(Color.YELLOW)
	st.add_vertex(local_tip)
	st.set_color(Color.GREEN)
	st.add_vertex(local_canvas)
	_debug_line.mesh = st.commit()
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	_debug_line.material_override = mat
	
	# Debug print every second
	if Engine.get_physics_frames() % 60 == 0:
		var half_canvas = canvas_size / 2.0
		# Check bounds relative to our local origin
		var local_x = tip_world.x - global_position.x
		var local_z = tip_world.z - global_position.z
		var in_bounds = abs(local_x) <= half_canvas and abs(local_z) <= half_canvas
		print("Tip local: (", local_x, ", ", local_z, ") | In bounds: ", in_bounds, " | Trail pts: ", trail_points.size())


func _update_pendulum_visual():
	# Cone position in the rotating swing plane
	var swing_radius = pendulum_length * sin(theta)
	var cone_y_offset = pendulum_length * (1.0 - cos(theta))
	
	# Rotate by swing_direction (Foucault effect)
	var cone_x = swing_radius * cos(swing_direction)
	var cone_z = swing_radius * sin(swing_direction)
	
	# Position cone relative to pivot (which is at top)
	# Adjust so the tip hovers at tip_hover_height above canvas when at rest
	var cone_y = -pendulum_length + cone_y_offset + cone_height / 2.0 + tip_hover_height
	_cone.position = Vector3(cone_x, cone_y, cone_z)
	
	# Wire connects pivot to top of cone
	var cone_top = _cone.global_position + Vector3(0, cone_height / 2.0, 0)
	var pivot_world = _pivot.global_position
	var wire_center = (pivot_world + cone_top) / 2.0
	var wire_length = pivot_world.distance_to(cone_top)
	
	# Update wire
	var cyl = _wire.mesh as CylinderMesh
	cyl.height = wire_length
	
	# Position wire at midpoint and orient toward cone
	_wire.global_position = wire_center
	_wire.look_at(cone_top, Vector3.RIGHT)
	_wire.rotate_object_local(Vector3.RIGHT, PI/2)


func _record_trail_point():
	if not _cone:
		return
	# Get cone tip position (bottom of cone) in world space
	var tip_world = _cone.global_position + Vector3(0, -cone_height / 2.0, 0)
	
	# Convert to local coordinates (relative to our root)
	var tip_local = tip_world - global_position
	
	# Check if tip is within canvas bounds (canvas is centered at our local origin)
	var half_canvas = canvas_size / 2.0
	if abs(tip_local.x) > half_canvas or abs(tip_local.z) > half_canvas:
		return
	
	# Project tip onto canvas plane (local coordinates)
	var trail_point = Vector3(tip_local.x, draw_height, tip_local.z)
	
	# Only record if moved enough from last point
	if trail_points.size() == 0 or trail_point.distance_to(trail_points[-1]) > 0.003:
		trail_points.append(trail_point)
		
		# Limit trail length
		while trail_points.size() > max_trail_points:
			trail_points.remove_at(0)


func _update_trail_mesh():
	if trail_points.size() < 2:
		return
	
	# Build line strip mesh
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for point in trail_points:
		st.set_color(marker_color)
		st.add_vertex(point)
	
	_trail_mesh.mesh = st.commit()
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = marker_color
	_trail_mesh.material_override = mat


# Public API

func reset():
	theta = initial_amplitude
	omega = 0.0
	swing_direction = initial_direction
	earth_angle = 0.0
	trail_points.clear()
	_update_pendulum_visual()
	if _trail_mesh:
		_trail_mesh.mesh = null
	if _earth_ring:
		_earth_ring.rotation.y = 0.0


func set_earth_rotation_rate(rate: float):
	earth_rotation_rate = rate


func set_amplitude(amp: float):
	# Restart with new amplitude
	theta = amp
	omega = 0.0


func clear_trail():
	trail_points.clear()
	if _trail_mesh:
		_trail_mesh.mesh = null
