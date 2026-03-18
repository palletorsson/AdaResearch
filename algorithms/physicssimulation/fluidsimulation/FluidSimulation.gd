# ===========================================================================
# SPH Fluid Simulation — Optimized for Godot 4 VR
# MultiMesh rendering, spatial hashing, pre-allocated arrays
# Tilt/shake the container in VR to slosh fluid around
# ===========================================================================

extends Node3D

# --- Tuning ---
@export_category("Fluid Parameters")
@export var particle_count: int = 150          ## Total particles (100-200 for VR)
@export var smoothing_radius: float = 0.45     ## SPH kernel radius
@export var rest_density: float = 80.0         ## Target density
@export var pressure_stiffness: float = 200.0  ## Pressure response
@export var viscosity: float = 0.8             ## Viscosity coefficient
@export var gravity_strength: float = 9.8

@export_category("Container")
@export var container_half_size: Vector3 = Vector3(1.0, 1.2, 1.0)
@export var wall_restitution: float = 0.3

@export_category("Rendering")
@export var particle_radius: float = 0.06
@export var color_low_speed: Color = Color(0.15, 0.45, 0.95, 0.85)
@export var color_high_speed: Color = Color(0.95, 0.35, 0.15, 0.85)
@export var speed_color_range: float = 3.0

# --- VR ---
var left_controller: XRController3D
var right_controller: XRController3D
var grabbed: bool = false
var grab_anchor: StaticBody3D
var grab_joint: Generic6DOFJoint3D

# --- Simulation state (pre-allocated) ---
var pos: PackedVector3Array      # particle positions
var vel: PackedVector3Array      # particle velocities
var acc: PackedVector3Array      # accumulated acceleration
var density: PackedFloat32Array  # per-particle density
var pressure: PackedFloat32Array # per-particle pressure

# --- Spatial hash ---
var grid: Dictionary = {}        # Vector3i -> PackedInt32Array
var cell_size: float = 0.45      # = smoothing_radius

# --- Rendering ---
var multimesh_instance: MultiMeshInstance3D
var multimesh: MultiMesh

# --- SPH kernel constants (computed once) ---
var h: float
var h2: float
var h6: float
var h9: float
var poly6_coeff: float
var spiky_coeff: float
var visc_coeff: float

# --- Container body (for VR grab) ---
var container_body: RigidBody3D

func _ready() -> void:
	# Scale for VR reachability
	scale = Vector3(0.8, 0.8, 0.8)

	_precompute_kernels()
	_allocate_arrays()
	_init_particle_positions()
	_create_multimesh()
	_create_container()
	_setup_vr()
	_create_ui()

	print("Fluid Simulation: %d particles | MultiMesh | spatial hash" % particle_count)

# ===========================================================================
# INITIALIZATION
# ===========================================================================

func _precompute_kernels() -> void:
	h = smoothing_radius
	h2 = h * h
	h6 = h2 * h2 * h2
	h9 = h6 * h2 * h
	cell_size = h
	# Poly6 kernel (density)
	poly6_coeff = 315.0 / (64.0 * PI * h9)
	# Spiky gradient (pressure)
	spiky_coeff = -45.0 / (PI * h6)
	# Viscosity Laplacian
	visc_coeff = 45.0 / (PI * h6)

func _allocate_arrays() -> void:
	pos.resize(particle_count)
	vel.resize(particle_count)
	acc.resize(particle_count)
	density.resize(particle_count)
	pressure.resize(particle_count)
	for i in particle_count:
		pos[i] = Vector3.ZERO
		vel[i] = Vector3.ZERO
		acc[i] = Vector3.ZERO
		density[i] = 0.0
		pressure[i] = 0.0

func _init_particle_positions() -> void:
	# Pack particles into a small cube inside the container
	var spacing: float = h * 0.55
	var side: int = ceili(pow(float(particle_count), 1.0 / 3.0))
	var offset: Vector3 = Vector3(-side * spacing * 0.5, 0.2, -side * spacing * 0.5)
	var idx: int = 0
	for x in side:
		for y in side:
			for z in side:
				if idx >= particle_count:
					break
				pos[idx] = offset + Vector3(x * spacing, y * spacing, z * spacing)
				# Small random jitter to break symmetry
				pos[idx] += Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * spacing * 0.1
				idx += 1

func _create_multimesh() -> void:
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = particle_count

	# Shared sphere mesh for ALL particles
	var sphere := SphereMesh.new()
	sphere.radius = particle_radius
	sphere.height = particle_radius * 2.0
	sphere.radial_segments = 8
	sphere.rings = 4

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_low_speed
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color_low_speed * 0.4
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.15
	mat.roughness = 0.35
	sphere.material = mat

	multimesh.mesh = sphere

	multimesh_instance = MultiMeshInstance3D.new()
	multimesh_instance.multimesh = multimesh
	add_child(multimesh_instance)

	# Initial transforms
	for i in particle_count:
		multimesh.set_instance_transform(i, Transform3D(Basis(), pos[i]))
		multimesh.set_instance_color(i, color_low_speed)

func _create_container() -> void:
	# RigidBody3D container — can be grabbed and tilted in VR
	container_body = RigidBody3D.new()
	container_body.mass = 10.0
	container_body.gravity_scale = 0.0
	container_body.freeze = true  # Kinematic until grabbed
	add_child(container_body)

	var hs := container_half_size
	var wall_thickness: float = 0.05

	# Transparent container visual
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.4, 0.5, 0.65, 0.12)
	wall_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# 5 walls: floor + 4 sides (open top)
	var wall_defs := [
		# [pos, size]
		[Vector3(0, -hs.y, 0), Vector3(hs.x * 2, wall_thickness, hs.z * 2)],       # Floor
		[Vector3(-hs.x, 0, 0), Vector3(wall_thickness, hs.y * 2, hs.z * 2)],        # Left
		[Vector3(hs.x, 0, 0),  Vector3(wall_thickness, hs.y * 2, hs.z * 2)],        # Right
		[Vector3(0, 0, -hs.z), Vector3(hs.x * 2, hs.y * 2, wall_thickness)],        # Back
		[Vector3(0, 0, hs.z),  Vector3(hs.x * 2, hs.y * 2, wall_thickness)],        # Front
	]

	for def in wall_defs:
		var sb := StaticBody3D.new()
		sb.position = def[0]
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = def[1]
		cs.shape = shape
		sb.add_child(cs)

		# Visible mesh
		var mesh_inst := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = def[1]
		mesh_inst.mesh = box_mesh
		mesh_inst.material_override = wall_mat
		sb.add_child(mesh_inst)

		container_body.add_child(sb)

# ===========================================================================
# VR SETUP
# ===========================================================================

func _setup_vr() -> void:
	var xr_origin = get_tree().get_first_node_in_group("XROrigin")
	if not xr_origin:
		return
	left_controller = xr_origin.get_node_or_null("LeftController")
	right_controller = xr_origin.get_node_or_null("RightController")
	if left_controller:
		left_controller.button_pressed.connect(_on_button_pressed.bind(left_controller))
		left_controller.button_released.connect(_on_button_released.bind(left_controller))
	if right_controller:
		right_controller.button_pressed.connect(_on_button_pressed.bind(right_controller))
		right_controller.button_released.connect(_on_button_released.bind(right_controller))

func _on_button_pressed(button: String, controller: XRController3D) -> void:
	if button != "grip_click" and button != "trigger_click":
		return
	if grabbed:
		return
	# Check proximity to container
	var dist := controller.global_position.distance_to(container_body.global_position)
	if dist < container_half_size.length() + 0.5:
		grabbed = true
		container_body.freeze = false
		container_body.gravity_scale = 0.0
		# Create kinematic anchor at controller
		grab_anchor = StaticBody3D.new()
		grab_anchor.global_position = controller.global_position
		add_child(grab_anchor)
		# Joint
		grab_joint = Generic6DOFJoint3D.new()
		grab_joint.node_a = grab_anchor.get_path()
		grab_joint.node_b = container_body.get_path()
		for flag in [Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING]:
			grab_joint.set_flag_x(flag, true)
			grab_joint.set_flag_y(flag, true)
			grab_joint.set_flag_z(flag, true)
		grab_joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 200.0)
		grab_joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 200.0)
		grab_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 200.0)
		add_child(grab_joint)

func _on_button_released(button: String, _controller: XRController3D) -> void:
	if button != "grip_click" and button != "trigger_click":
		return
	_release_grab()

func _release_grab() -> void:
	if not grabbed:
		return
	grabbed = false
	container_body.freeze = true
	if grab_joint:
		grab_joint.queue_free()
		grab_joint = null
	if grab_anchor:
		grab_anchor.queue_free()
		grab_anchor = null

# ===========================================================================
# PHYSICS — runs at fixed timestep
# ===========================================================================

func _physics_process(delta: float) -> void:
	_build_spatial_hash()
	_compute_density_pressure()
	_compute_forces(delta)
	_integrate(delta)
	_enforce_boundaries()
	_update_multimesh()

# --- Spatial hash ---
func _build_spatial_hash() -> void:
	grid.clear()
	var inv_cell := 1.0 / cell_size
	for i in particle_count:
		var cell := Vector3i(
			floori(pos[i].x * inv_cell),
			floori(pos[i].y * inv_cell),
			floori(pos[i].z * inv_cell)
		)
		if not grid.has(cell):
			grid[cell] = PackedInt32Array()
		grid[cell].append(i)

func _get_neighbors(idx: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	var inv_cell := 1.0 / cell_size
	var cx: int = floori(pos[idx].x * inv_cell)
	var cy: int = floori(pos[idx].y * inv_cell)
	var cz: int = floori(pos[idx].z * inv_cell)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			for dz in range(-1, 2):
				var cell := Vector3i(cx + dx, cy + dy, cz + dz)
				if grid.has(cell):
					var arr: PackedInt32Array = grid[cell]
					for j in arr:
						if j != idx:
							result.append(j)
	return result

# --- Density & Pressure ---
func _compute_density_pressure() -> void:
	for i in particle_count:
		var rho: float = 0.0
		var neighbors := _get_neighbors(i)
		for j in neighbors:
			var diff := pos[i] - pos[j]
			var r2 := diff.length_squared()
			if r2 < h2:
				# Poly6 kernel
				var w := h2 - r2
				rho += w * w * w
		rho *= poly6_coeff
		density[i] = maxf(rho, 0.001)
		# Equation of state
		pressure[i] = pressure_stiffness * (density[i] - rest_density)

# --- Forces ---
func _compute_forces(delta: float) -> void:
	# Gravity in container's local space (allows tilting to slosh!)
	var grav_world := Vector3(0, -gravity_strength, 0)
	var container_basis := container_body.global_transform.basis
	var grav_local := container_basis.inverse() * grav_world

	for i in particle_count:
		var f_pressure := Vector3.ZERO
		var f_viscosity := Vector3.ZERO
		var neighbors := _get_neighbors(i)

		for j in neighbors:
			var diff := pos[i] - pos[j]
			var r := diff.length()
			if r < h and r > 0.0001:
				var dir := diff / r
				# Spiky gradient (pressure)
				var w_pressure := (h - r) * (h - r)
				var p_avg := (pressure[i] + pressure[j]) * 0.5
				f_pressure += dir * p_avg * w_pressure * spiky_coeff / maxf(density[j], 0.001)
				# Viscosity Laplacian
				var w_visc := h - r
				f_viscosity += (vel[j] - vel[i]) * w_visc * visc_coeff / maxf(density[j], 0.001)

		acc[i] = grav_local + f_pressure / maxf(density[i], 0.001) + f_viscosity * viscosity / maxf(density[i], 0.001)

# --- Integration ---
func _integrate(delta: float) -> void:
	for i in particle_count:
		vel[i] += acc[i] * delta
		vel[i] *= 0.998  # Tiny damping
		pos[i] += vel[i] * delta

# --- Boundaries (container-local) ---
func _enforce_boundaries() -> void:
	var hs := container_half_size
	var r := particle_radius
	for i in particle_count:
		# Floor
		if pos[i].y < -hs.y + r:
			pos[i].y = -hs.y + r
			vel[i].y *= -wall_restitution
		# Ceiling (open top, but cap at 2x height)
		if pos[i].y > hs.y * 2.0:
			pos[i].y = hs.y * 2.0
			vel[i].y *= -wall_restitution
		# X walls
		if pos[i].x < -hs.x + r:
			pos[i].x = -hs.x + r
			vel[i].x *= -wall_restitution
		elif pos[i].x > hs.x - r:
			pos[i].x = hs.x - r
			vel[i].x *= -wall_restitution
		# Z walls
		if pos[i].z < -hs.z + r:
			pos[i].z = -hs.z + r
			vel[i].z *= -wall_restitution
		elif pos[i].z > hs.z - r:
			pos[i].z = hs.z - r
			vel[i].z *= -wall_restitution

# --- MultiMesh update ---
func _update_multimesh() -> void:
	var container_xform := container_body.global_transform
	var inv_range := 1.0 / maxf(speed_color_range, 0.01)
	for i in particle_count:
		# Transform particle from container-local to world
		var world_pos := container_xform * pos[i]
		multimesh.set_instance_transform(i, Transform3D(Basis(), world_pos))
		# Color by speed
		var spd := vel[i].length() * inv_range
		var t := clampf(spd, 0.0, 1.0)
		multimesh.set_instance_color(i, color_low_speed.lerp(color_high_speed, t))

# ===========================================================================
# UI
# ===========================================================================

func _create_ui() -> void:
	var title := Label3D.new()
	title.text = "SPH FLUID SIMULATION"
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.font_size = 28
	title.outline_size = 4
	title.position = Vector3(0, container_half_size.y * 2.0 + 0.3, 0)
	add_child(title)

	var info := Label3D.new()
	info.text = "[Grab container] Tilt to slosh | [R] Reset"
	info.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info.font_size = 16
	info.outline_size = 3
	info.position = Vector3(0, container_half_size.y * 2.0, 0)
	add_child(info)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_reset()

func _reset() -> void:
	_init_particle_positions()
	for i in particle_count:
		vel[i] = Vector3.ZERO
		acc[i] = Vector3.ZERO
		density[i] = 0.0
		pressure[i] = 0.0
	container_body.position = Vector3.ZERO
	container_body.rotation = Vector3.ZERO

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
