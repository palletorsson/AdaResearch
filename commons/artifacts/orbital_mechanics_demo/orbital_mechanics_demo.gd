# orbital_mechanics_demo.gd
# Planet + satellite orbital mechanics
# Shows Kepler's laws, gravitational orbits
#
# QFEP: Orbit as dynamic equilibrium — perpetual falling, never landing

extends Node3D

class_name OrbitalMechanicsDemo

## @identity
## name: "The orbit is a fall that keeps missing"
## tier: medium
## lineage: A satellite circles a central mass under an inverse-distance gravitational pull,
##   integrated frame by frame from initial radius and tangent velocity. Tune the velocity and
##   the perpetual fall closes into an ellipse; Kepler's laws emerge from F = ma alone.
## truth: "AN ORBIT IS PERPETUAL FALLING THAT NEVER LANDS — EQUILIBRIUM AS UNRESOLVED MOTION"
## applications: Kepler's laws, gravitational dynamics, dynamic equilibrium, conic-section orbits,
##   the difference between a stable state and a settled one.

## Orbital parameters
@export var central_mass: float = 1.0  # Arbitrary units
@export var gravitational_constant: float = 0.5

## Initial satellite conditions
@export var initial_radius: float = 0.3
@export var initial_velocity: float = 0.0  # Tangent velocity, <= 0 means auto-circular

## Display
@export var planet_radius: float = 0.08
@export var satellite_radius: float = 0.02
@export var trail_length: int = 200

## Time
@export var time_scale: float = 1.0:
	set(value):
		time_scale = clampf(value, 0.1, 5.0)

## Colors
@export var color_planet: Color = Color(0.3, 0.5, 1.0)  # Blue
@export var color_satellite: Color = Color(1.0, 0.8, 0.3)  # Yellow
@export var color_orbit: Color = Color(0.4, 0.4, 0.5, 0.5)  # Gray trail
@export var color_velocity: Color = Color(0.3, 1.0, 0.4)  # Green

# State
var _satellite_pos: Vector3
var _satellite_vel: Vector3
var _trail: PackedVector3Array

# Visuals
var _planet: MeshInstance3D
var _satellite: MeshInstance3D
var _velocity_arrow: Node3D
var _trail_mesh: MeshInstance3D
var _trail_immediate: ImmediateMesh
var _trail_mat: StandardMaterial3D
var _info_label: Label3D
var _time_slider: Node

# Throttle info updates
var _info_update_timer: float = 0.0
const INFO_UPDATE_INTERVAL: float = 0.1


func _ready():
	_create_planet()
	_create_satellite()
	_create_velocity_arrow()
	_create_trail()
	_create_labels()
	_create_vr_controls()
	_reset_orbit()

func _create_planet():
	_planet = MeshInstance3D.new()
	_planet.name = "Planet"
	var sphere = SphereMesh.new()
	sphere.radius = planet_radius
	sphere.height = planet_radius * 2
	_planet.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_planet
	mat.emission_enabled = true
	mat.emission = color_planet
	mat.emission_energy_multiplier = 0.4
	_planet.material_override = mat
	add_child(_planet)

	# Add rings for reference
	var ring = MeshInstance3D.new()
	ring.name = "ReferenceRing"
	var torus = TorusMesh.new()
	torus.inner_radius = initial_radius - 0.005
	torus.outer_radius = initial_radius + 0.005
	ring.mesh = torus
	ring.rotation_degrees.x = 90

	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.3, 0.3, 0.4, 0.3)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = ring_mat
	add_child(ring)

func _create_satellite():
	_satellite = MeshInstance3D.new()
	_satellite.name = "Satellite"
	var sphere = SphereMesh.new()
	sphere.radius = satellite_radius
	sphere.height = satellite_radius * 2
	_satellite.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_satellite
	mat.emission_enabled = true
	mat.emission = color_satellite
	mat.emission_energy_multiplier = 0.5
	_satellite.material_override = mat
	add_child(_satellite)

func _create_velocity_arrow():
	_velocity_arrow = Node3D.new()
	_velocity_arrow.name = "VelocityArrow"

	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.004
	cylinder.bottom_radius = 0.004
	cylinder.height = 0.1
	shaft.mesh = cylinder

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_velocity
	mat.emission_enabled = true
	mat.emission = color_velocity
	mat.emission_energy_multiplier = 0.3
	shaft.material_override = mat
	shaft.position = Vector3(0, 0.05, 0)
	_velocity_arrow.add_child(shaft)

	var head = MeshInstance3D.new()
	head.name = "Head"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.012
	cone.height = 0.025
	head.mesh = cone
	head.material_override = mat
	head.position = Vector3(0, 0.1125, 0)
	_velocity_arrow.add_child(head)

	add_child(_velocity_arrow)

func _create_trail():
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "OrbitTrail"

	# Pre-create reusable mesh and material
	_trail_immediate = ImmediateMesh.new()
	_trail_mesh.mesh = _trail_immediate

	_trail_mat = StandardMaterial3D.new()
	_trail_mat.vertex_color_use_as_albedo = true
	_trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mesh.material_override = _trail_mat

	add_child(_trail_mesh)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 14
	_info_label.position = Vector3(0, 0.35, 0)
	_info_label.text = "ORBITAL MECHANICS"
	add_child(_info_label)

func _create_vr_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("ORBITAL MECHANICS", [
		[{"type": "slider_h", "label": "SPEED", "default": 0.18}],
		[
			{"type": "button", "label": "CIRCULAR"},
			{"type": "button", "label": "ELLIPSE"},
		],
		[
			{"type": "button", "label": "ESCAPE"},
			{"type": "button", "label": "DECAY"},
		],
	])
	panel.position = Vector3(0, -0.1, 0.35)
	panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(panel)

	_time_slider = panel.find_child("Param_0", true, false)
	if _time_slider and _time_slider.has_signal("slider_moved"):
		_time_slider.slider_moved.connect(_on_time_slider_changed)

	var preset_speed_factors: Array[float] = [1.0, 0.88, 1.42, 0.72]
	for i in range(4):
		var btn: Node = panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var area: Node = btn.get_node_or_null("InteractableAreaButton")
			if area:
				var factor: float = preset_speed_factors[i]
				area.button_pressed.connect(func(_b): _set_orbit_preset(0.3, factor))

func _on_time_slider_changed(_pos) -> void:
	if _time_slider and _time_slider.has_method("get_normalized_value"):
		time_scale = lerpf(0.1, 5.0, _time_slider.get_normalized_value())

func _set_orbit_preset(radius: float, speed_factor: float):
	var circular_speed = _circular_velocity(radius)
	_set_orbit(radius, circular_speed * speed_factor)

func _set_orbit(r: float, v: float):
	initial_radius = maxf(r, planet_radius + satellite_radius + 0.02)
	initial_velocity = v
	_reset_orbit()

func _reset_orbit():
	var start_radius = maxf(initial_radius, planet_radius + satellite_radius + 0.02)
	var start_speed = initial_velocity
	if start_speed <= 0.0:
		start_speed = _circular_velocity(start_radius)

	_satellite_pos = Vector3(start_radius, 0, 0)
	_satellite_vel = Vector3(0, 0, start_speed)
	_trail.clear()

func _circular_velocity(radius: float) -> float:
	var safe_radius = maxf(radius, 0.001)
	return sqrt(maxf(gravitational_constant * central_mass / safe_radius, 0.0))

func _physics_process(delta):
	var dt = minf(delta * time_scale, 0.05)

	# Gravitational acceleration: a = -GM/r² * r̂
	var r = _satellite_pos.length()
	if r < planet_radius:
		_reset_orbit()  # Crashed into planet
		return

	var r_hat = _satellite_pos.normalized()
	var accel = -gravitational_constant * central_mass / (r * r) * r_hat

	# Velocity Verlet integration
	var new_pos = _satellite_pos + _satellite_vel * dt + 0.5 * accel * dt * dt

	var new_r = new_pos.length()
	if new_r < 0.001:
		_reset_orbit()
		return
	var new_r_hat = new_pos.normalized()
	var new_accel = -gravitational_constant * central_mass / (new_r * new_r) * new_r_hat

	_satellite_vel += 0.5 * (accel + new_accel) * dt
	_satellite_pos = new_pos

	# Escape detection — reset if satellite flies too far away
	if new_r > 2.0:
		_reset_orbit()
		return

	# Update visuals
	_satellite.position = _satellite_pos
	_update_velocity_arrow()
	_update_trail()

	# Throttle info label updates
	_info_update_timer += delta
	if _info_update_timer >= INFO_UPDATE_INTERVAL:
		_info_update_timer = 0.0
		_update_info()

func _update_velocity_arrow():
	_velocity_arrow.position = _satellite_pos

	var vel_dir = _satellite_vel.normalized()
	var vel_mag = _satellite_vel.length()
	var arrow_scale = clampf(vel_mag * 0.08, 0.05, 0.2)
	_velocity_arrow.scale = Vector3(1, arrow_scale / 0.1, 1)

	# Orient arrow along velocity direction using basis
	if vel_mag > 0.001:
		var up = Vector3.UP
		if absf(vel_dir.dot(up)) > 0.99:
			up = Vector3.FORWARD
		var basis = Basis.looking_at(vel_dir, up)
		# CylinderMesh points along +Y, so rotate from -Z (looking_at forward) to +Y
		_velocity_arrow.basis = basis * Basis(Vector3.RIGHT, PI / 2.0)

func _update_trail():
	_trail.append(_satellite_pos)
	while _trail.size() > trail_length:
		_trail.remove_at(0)

	if _trail.size() < 2:
		return

	# Reuse the existing ImmediateMesh — clear and rebuild
	_trail_immediate.clear_surfaces()
	_trail_immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(_trail.size()):
		var alpha = float(i) / float(_trail.size())
		_trail_immediate.surface_set_color(Color(color_orbit.r, color_orbit.g, color_orbit.b, alpha * 0.6))
		_trail_immediate.surface_add_vertex(_trail[i])

	_trail_immediate.surface_end()

func _update_info():
	var r = _satellite_pos.length()
	var v = _satellite_vel.length()

	# Specific orbital energy: E = v²/2 - GM/r
	var energy = 0.5 * v * v - gravitational_constant * central_mass / maxf(r, 0.001)
	var orbit_type = "ELLIPSE" if energy < 0 else ("PARABOLA" if energy < 0.01 else "HYPERBOLA")

	# Angular momentum
	var h = _satellite_pos.cross(_satellite_vel).length()
	var circular_speed = _circular_velocity(r)
	var speed_ratio = v / maxf(circular_speed, 0.001)

	_info_label.text = "ORBITAL MECHANICS\nr=%.3f v=%.3f vc=%.3f (x%.2f)\nE=%.3f  %s  L=%.3f" % [
		r,
		v,
		circular_speed,
		speed_ratio,
		energy,
		orbit_type,
		h
	]

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _set_orbit_preset(0.3, 1.0)
			KEY_2: _set_orbit_preset(0.3, 0.88)
			KEY_3: _set_orbit_preset(0.3, 1.42)
			KEY_4: _set_orbit_preset(0.3, 0.72)
			KEY_R: _reset_orbit()
			KEY_UP: time_scale = minf(time_scale + 0.2, 5.0)
			KEY_DOWN: time_scale = maxf(time_scale - 0.2, 0.1)

func set_time_scale(s: float):
	time_scale = s

func reset():
	_reset_orbit()

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
