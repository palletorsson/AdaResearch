# foucault_pendulum.gd
## Simulates a Foucault pendulum demonstrating Earth's rotation via precessing swing plane.
## Uses simple pendulum physics (θ'' = -(g/L)sin(θ)) combined with Coriolis-driven
## precession at rate Ω×sin(latitude). Draws rosette trail patterns on a horizontal canvas.
## Optional gravity spheres provide interactive perturbation via inverse-square attraction.

extends Node3D

class_name FoucaultPendulum


# @identity
# essence: swing_plane(t) = initial_azimuth, earth_angle(t) += omega_earth * sin(latitude) * dt
# desire: Watch a pendulum draw rosette patterns as the Earth rotates beneath its fixed swing plane
# critical_parameter: earth_rotation_rate — controls precession speed (normally 360 deg/sidereal day * sin(lat))
# triggers: time drives both pendulum swing and Earth rotation; trail accumulates on canvas
# emerges: spirograph-like rosettes from the interaction of two independent rotational periods
# needs: VR observation of canvas [has], latitude control [missing]
# relationships: depends on inertial frame physics; contrasts with WavePaintings (inertial vs chaotic trace); unlocks rotating reference frame intuition
# truth: The pendulum does not rotate — the Earth rotates beneath it, and the trail is proof.

@export_category("Pendulum")
## Length of the pendulum wire from pivot to bob (meters)
@export_range(1.0, 20.0, 0.1) var pendulum_length: float = 8.0
## Radius of the conical bob at its widest point
@export_range(0.02, 0.5, 0.01) var cone_radius: float = 0.08
## Height of the conical bob
@export_range(0.05, 1.0, 0.01) var cone_height: float = 0.25
## Thickness of the pendulum wire
@export_range(0.002, 0.05, 0.001) var wire_thickness: float = 0.008
## Starting swing angle in radians (0 = vertical)
@export_range(0.01, 1.0, 0.01) var initial_amplitude: float = 0.4
## Starting swing direction in radians
@export_range(0.0, 6.28, 0.01) var initial_direction: float = 0.0
## Gap between cone tip and canvas at rest position
@export_range(0.0, 0.2, 0.005) var tip_hover_height: float = 0.02

@export_category("Physics")
## Gravitational acceleration (m/s²)
@export_range(0.1, 20.0, 0.1) var gravity: float = 9.81
## Damping factor applied per physics frame
@export_range(0.0, 0.01, 0.0001) var damping: float = 0.0002
## Earth rotation speed in radians/sec (exaggerated for visibility)
@export_range(0.0, 1.0, 0.001) var earth_rotation_rate: float = 0.05
## Observer latitude in degrees — affects precession rate (90=pole, 0=equator)
@export_range(0.0, 90.0, 1.0) var latitude: float = 45.0
## Whether electromagnetic drive maintains swing amplitude
@export var drive_enabled: bool = true
## Target swing amplitude for the electromagnetic drive (radians)
@export_range(0.01, 1.5, 0.01) var target_amplitude: float = 0.4
## Strength of the electromagnetic drive correction
@export_range(0.001, 0.2, 0.001) var drive_strength: float = 0.02

@export_category("Gravity Spheres")
## Whether interactive gravity spheres are enabled
@export var gravity_spheres_enabled: bool = true
## Number of interactive gravity spheres placed around the canvas
@export_range(1, 24) var num_gravity_spheres: int = 8
## Pull strength of each gravity sphere on the pendulum
@export_range(0.0, 5.0, 0.1) var sphere_gravity_strength: float = 0.5
## Visual/collision radius of each gravity sphere
@export_range(0.05, 1.0, 0.05) var sphere_radius: float = 0.25
## Maximum distance at which a sphere exerts gravitational pull
@export_range(0.5, 10.0, 0.1) var sphere_influence_radius: float = 2.0
## Color of the gravity spheres
@export var sphere_color: Color = Color(0.6, 0.3, 0.9)

@export_category("Canvas")
## Side length of the square drawing canvas
@export_range(1.0, 20.0, 0.5) var canvas_size: float = 6.0
## Color of the canvas surface
@export var canvas_color: Color = Color(0.95, 0.93, 0.88)
## Whether to show the frame around the canvas
@export var show_frame: bool = true

@export_category("Sine Modulation")
## Whether sine-wave perturbation is applied to the swing
@export var sine_modulation_enabled: bool = false
## Amplitude of sine-wave perturbation added to swing
@export_range(0.0, 0.5, 0.01) var sine_modulation_amplitude: float = 0.08
## Frequency of sine-wave perturbation (Hz)
@export_range(0.01, 5.0, 0.01) var sine_modulation_frequency: float = 0.3

@export_category("Drawing")
## Color of the trail line drawn on the canvas
@export var marker_color: Color = Color(0.08, 0.06, 0.04)
## Width of the trail line
@export_range(0.005, 0.1, 0.005) var marker_width: float = 0.02
## Maximum number of trail points before oldest are removed
@export_range(100, 50000) var max_trail_points: int = 8000
## Height of the trail line above the canvas surface
@export_range(0.001, 0.1, 0.001) var draw_height: float = 0.01

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

# Shared materials (allocated once, reused)
var _debug_line_mat: StandardMaterial3D
var _trail_mat: StandardMaterial3D
var _gravity_sphere_mat: StandardMaterial3D

func _ready() -> void:
	# Initialize state
	theta = initial_amplitude
	omega = 0.0
	swing_direction = initial_direction
	earth_angle = 0.0

	# Pre-allocate shared materials
	_debug_line_mat = StandardMaterial3D.new()
	_debug_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_debug_line_mat.vertex_color_use_as_albedo = true

	_trail_mat = StandardMaterial3D.new()
	_trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mat.vertex_color_use_as_albedo = true
	_trail_mat.albedo_color = marker_color

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


func _create_podium() -> void:
	"""Create a square podium/pedestal underneath the pendulum visualization"""
	var podium = Node3D.new()
	podium.name = "Podium"

	var base_size = canvas_size + 1.0

	# Shared podium material
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.2, 0.18, 0.16)
	base_mat.metallic = 0.1
	base_mat.roughness = 0.8

	# Main podium box (square)
	var base = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(base_size, 0.8, base_size)
	base.mesh = box
	base.position = Vector3(0, -0.4, 0)
	base.material_override = base_mat
	podium.add_child(base)

	# Decorative rim at top — MultiMesh for 4 rim segments
	var rim_thickness = 0.2
	var rim_height = 0.06
	var rim_mat = StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.6, 0.5, 0.35)
	rim_mat.metallic = 0.6
	rim_mat.roughness = 0.4

	var rim_outer = base_size + 0.1
	var rim_sides = [
		[Vector3(rim_outer, rim_height, rim_thickness), Vector3(0, -0.02, base_size / 2.0)],
		[Vector3(rim_outer, rim_height, rim_thickness), Vector3(0, -0.02, -base_size / 2.0)],
		[Vector3(rim_thickness, rim_height, rim_outer), Vector3(base_size / 2.0, -0.02, 0)],
		[Vector3(rim_thickness, rim_height, rim_outer), Vector3(-base_size / 2.0, -0.02, 0)],
	]

	var unit_box := BoxMesh.new()
	unit_box.size = Vector3(1, 1, 1)

	var rim_mm := MultiMesh.new()
	rim_mm.transform_format = MultiMesh.TRANSFORM_3D
	rim_mm.mesh = unit_box
	rim_mm.instance_count = rim_sides.size()

	for i in rim_sides.size():
		var s: Vector3 = rim_sides[i][0]
		var p: Vector3 = rim_sides[i][1]
		var xf := Transform3D(
			Basis(Vector3(s.x, 0, 0), Vector3(0, s.y, 0), Vector3(0, 0, s.z)), p)
		rim_mm.set_instance_transform(i, xf)

	var rim_mmi := MultiMeshInstance3D.new()
	rim_mmi.multimesh = rim_mm
	rim_mmi.material_override = rim_mat
	podium.add_child(rim_mmi)

	# Lower stepped base (square)
	var lower_base = MeshInstance3D.new()
	var lower_box = BoxMesh.new()
	var lower_size = canvas_size + 1.6
	lower_box.size = Vector3(lower_size, 0.3, lower_size)
	lower_base.mesh = lower_box
	lower_base.position = Vector3(0, -0.95, 0)
	lower_base.material_override = base_mat
	podium.add_child(lower_base)

	add_child(podium)


func _create_ceiling_mount() -> void:
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


func _create_pivot() -> void:
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	_pivot.position = Vector3(0, pendulum_length, 0)
	add_child(_pivot)


func _create_wire() -> void:
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


func _create_cone() -> void:
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


func _create_raycast() -> void:
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


func _create_canvas() -> void:
	# StaticBody for raycast collision
	_canvas_body = StaticBody3D.new()
	_canvas_body.name = "CanvasBody"
	_canvas_body.collision_layer = 1
	_canvas_body.collision_mask = 1
	add_child(_canvas_body)

	# Collision shape - sits on top of podium
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(canvas_size, 0.1, canvas_size)
	collision.shape = box_shape
	collision.position = Vector3(0, 0.05, 0)  # Top surface at y=0.1
	_canvas_body.add_child(collision)

	# Visual mesh - raised above podium top
	_canvas = MeshInstance3D.new()
	_canvas.name = "CanvasSurface"

	var plane = PlaneMesh.new()
	plane.size = Vector2(canvas_size, canvas_size)
	_canvas.mesh = plane
	_canvas.position = Vector3(0, 0.1, 0)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = canvas_color
	mat.roughness = 0.95
	mat.metallic = 0.0
	_canvas.material_override = mat
	_canvas_body.add_child(_canvas)

	# Frame (optional)
	if show_frame:
		_add_canvas_frame()


func _add_canvas_frame() -> void:
	var frame_thickness = 0.15  # Thicker for better collision
	var frame_height = 0.4  # Taller to contain spheres
	var half = canvas_size / 2.0

	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.15, 0.12, 0.1)
	frame_mat.roughness = 0.8

	# Four sides: [size, position] — raised to match canvas at y=0.1
	var base_y = 0.1 + frame_height / 2.0
	var sides = [
		[Vector3(canvas_size + frame_thickness * 2, frame_height, frame_thickness), Vector3(0, base_y, half + frame_thickness/2)],
		[Vector3(canvas_size + frame_thickness * 2, frame_height, frame_thickness), Vector3(0, base_y, -half - frame_thickness/2)],
		[Vector3(frame_thickness, frame_height, canvas_size), Vector3(-half - frame_thickness/2, base_y, 0)],
		[Vector3(frame_thickness, frame_height, canvas_size), Vector3(half + frame_thickness/2, base_y, 0)],
	]

	# MultiMesh for frame wall visuals (one draw call for all 4 walls)
	var unit_box := BoxMesh.new()
	unit_box.size = Vector3(1, 1, 1)

	var wall_mm := MultiMesh.new()
	wall_mm.transform_format = MultiMesh.TRANSFORM_3D
	wall_mm.mesh = unit_box
	wall_mm.instance_count = sides.size()

	for i in range(sides.size()):
		var side = sides[i]

		# StaticBody for collision (kept as individual nodes)
		var body = StaticBody3D.new()
		body.name = "FrameWall_%d" % i
		body.position = side[1]
		add_child(body)

		var collision = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = side[0]
		collision.shape = box_shape
		body.add_child(collision)

		# MultiMesh transform (scaled unit box)
		var s: Vector3 = side[0]
		var p: Vector3 = side[1]
		var xf := Transform3D(
			Basis(Vector3(s.x, 0, 0), Vector3(0, s.y, 0), Vector3(0, 0, s.z)), p)
		wall_mm.set_instance_transform(i, xf)

	var wall_mmi := MultiMeshInstance3D.new()
	wall_mmi.multimesh = wall_mm
	wall_mmi.material_override = frame_mat
	add_child(wall_mmi)


func _create_earth_ring() -> void:
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


func _create_gravity_spheres() -> void:
	if not gravity_spheres_enabled:
		return

	var SIMPLE_GRAB_SPHERE = load("res://commons/primitives/point/simple_grab_sphere.tscn")
	var ring_radius = canvas_size / 2.0 + 0.8

	# Shared material for all gravity sphere visuals
	_gravity_sphere_mat = StandardMaterial3D.new()
	_gravity_sphere_mat.albedo_color = sphere_color
	_gravity_sphere_mat.emission_enabled = true
	_gravity_sphere_mat.emission = sphere_color
	_gravity_sphere_mat.emission_energy_multiplier = 1.0
	_gravity_sphere_mat.metallic = 0.3
	_gravity_sphere_mat.roughness = 0.4

	# Pre-size array
	_gravity_spheres.resize(num_gravity_spheres)

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

			# Apply shared material
			if mesh:
				mesh.material_override = _gravity_sphere_mat
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

		_gravity_spheres[i] = sphere

	print("Created %d gravity spheres" % _gravity_spheres.size())


func _create_simple_gravity_sphere(color: Color) -> Node3D:
	# Fallback if grab_sphere_point.tscn not available
	var root = Node3D.new()

	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = sphere_radius
	sphere.height = sphere_radius * 2
	mesh.mesh = sphere

	# Use shared material if available, otherwise create one
	if _gravity_sphere_mat:
		mesh.material_override = _gravity_sphere_mat
	else:
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


func _create_trail_mesh() -> void:
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "Trail"
	_trail_mesh.material_override = _trail_mat
	# Trail points already have draw_height baked in
	add_child(_trail_mesh)


func _create_debug_visuals() -> void:
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
	_debug_line.material_override = _debug_line_mat
	add_child(_debug_line)


func _create_labels() -> void:
	_title_label = Label3D.new()
	_title_label.text = "Foucault Pendulum"
	_title_label.font_size = 64
	_title_label.position = Vector3(0, pendulum_length + 0.5, 0)
	_title_label.modulate = Color(0.2, 0.18, 0.15)
	_title_label.outline_size = 4
	add_child(_title_label)

	var precession_factor = sin(deg_to_rad(latitude))
	var info = Label3D.new()
	info.text = "Latitude: %.0f° | Precession = Ω × sin(%.0f°) = %.2f×Ω" % [latitude, latitude, precession_factor]
	info.font_size = 28
	info.position = Vector3(0, pendulum_length + 0.2, 0)
	info.modulate = Color(0.4, 0.35, 0.3)
	add_child(info)

	var info2 = Label3D.new()
	info2.text = "Ring rotates with Earth — pendulum swings in fixed plane"
	info2.font_size = 24
	info2.position = Vector3(0, pendulum_length - 0.05, 0)
	info2.modulate = Color(0.5, 0.45, 0.4)
	add_child(info2)


func _physics_process(delta: float) -> void:
	# Simple pendulum physics: θ'' = -(g/L) * sin(θ)
	var angular_acceleration = -(gravity / maxf(pendulum_length, 0.0001)) * sin(theta)

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
	# Precession rate = Earth rotation × sin(latitude)
	# At poles (90°): full rotation; at equator (0°): no precession
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


func _apply_gravity_sphere_forces(delta: float) -> void:
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


func _apply_drive(_delta: float) -> void:
	# Estimate current amplitude from max theta reached
	# Drive kicks in near the center (θ ≈ 0) when velocity is highest

	# Only apply drive near center of swing (where real EM drives work)
	if abs(theta) > 0.05:
		return

	# Check if we need more energy (amplitude too low)
	# Use omega to estimate amplitude: at center, ω ≈ sqrt(g/L) * amplitude
	var estimated_amplitude = abs(omega) * sqrt(maxf(pendulum_length, 0.0001) / maxf(gravity, 0.0001))

	if estimated_amplitude < target_amplitude:
		# Add energy in the direction of motion
		var boost = drive_strength * sign(omega)
		omega += boost


func _update_debug_visuals() -> void:
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

	# Debug print every second
	if Engine.get_physics_frames() % 60 == 0:
		var half_canvas = canvas_size / 2.0
		# Check bounds relative to our local origin
		var local_x = tip_world.x - global_position.x
		var local_z = tip_world.z - global_position.z
		var in_bounds = abs(local_x) <= half_canvas and abs(local_z) <= half_canvas
		print("Tip local: (", local_x, ", ", local_z, ") | In bounds: ", in_bounds, " | Trail pts: ", trail_points.size())


func _update_pendulum_visual() -> void:
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


func _record_trail_point() -> void:
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

	# Project tip onto canvas plane (local coordinates, canvas at y=0.1)
	var trail_point = Vector3(tip_local.x, 0.1 + draw_height, tip_local.z)

	# Only record if moved enough from last point
	if trail_points.size() == 0 or trail_point.distance_to(trail_points[-1]) > 0.003:
		trail_points.append(trail_point)

		# Limit trail length
		while trail_points.size() > max_trail_points:
			trail_points.remove_at(0)


func _update_trail_mesh() -> void:
	if trail_points.size() < 2:
		return

	# Build line strip mesh
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)

	for point in trail_points:
		st.set_color(marker_color)
		st.add_vertex(point)

	_trail_mesh.mesh = st.commit()
	_trail_mat.albedo_color = marker_color


func _exit_tree() -> void:
	for sphere in _gravity_spheres:
		if is_instance_valid(sphere):
			sphere.queue_free()
	_gravity_spheres.clear()


# Public API

func reset() -> void:
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


func set_earth_rotation_rate(rate: float) -> void:
	earth_rotation_rate = rate


func set_amplitude(amp: float) -> void:
	# Restart with new amplitude
	theta = amp
	omega = 0.0


func clear_trail() -> void:
	trail_points.clear()
	if _trail_mesh:
		_trail_mesh.mesh = null


func apply_grid_config(config_data: Dictionary) -> void:
	pass
