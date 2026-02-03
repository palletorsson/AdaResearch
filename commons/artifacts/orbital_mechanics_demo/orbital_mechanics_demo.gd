# orbital_mechanics_demo.gd
# Planet + satellite orbital mechanics
# Shows Kepler's laws, gravitational orbits
#
# QFEP: Orbit as dynamic equilibrium — perpetual falling, never landing

extends Node3D

class_name OrbitalMechanicsDemo

## Orbital parameters
@export var central_mass: float = 5.0  # Arbitrary units
@export var gravitational_constant: float = 0.5

## Initial satellite conditions
@export var initial_radius: float = 0.3
@export var initial_velocity: float = 1.2  # Tangent velocity

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
var _info_label: Label3D
var _control_panel: Node3D

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

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
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.1, 0.35)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	# Panel
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.4, 0.14, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Orbit preset buttons
	var presets = [
		["CIRCULAR", 0.3, 1.29],  # v = sqrt(GM/r)
		["ELLIPSE", 0.2, 1.5],
		["ESCAPE", 0.25, 2.0],
		["DECAY", 0.35, 0.9]
	]
	
	for i in range(presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % i
		btn.position = Vector3(-0.12 + i * 0.08, 0.03, 0)
		btn.scale = Vector3(0.65, 0.65, 0.65)
		_control_panel.add_child(btn)
		_add_button_label(btn, presets[i][0])
		
		var r = presets[i][1]
		var v = presets[i][2]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(): _set_orbit(r, v))
	
	# Time scale slider
	var time_slider = SLIDER_HORIZONTAL.instantiate()
	time_slider.name = "TimeSlider"
	time_slider.position = Vector3(0, -0.03, 0)
	time_slider.rotation_degrees.x = -30
	time_slider.scale = Vector3(0.8, 0.8, 0.8)
	var time_label = time_slider.get_node_or_null("Frame/LabelName")
	if time_label:
		time_label.text = "SPEED"
	_control_panel.add_child(time_slider)
	time_slider.slider_moved.connect(func(_pos):
		if time_slider.has_method("get_normalized_value"):
			time_scale = 0.1 + time_slider.get_normalized_value() * 4.9
	)

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)

func _set_orbit(r: float, v: float):
	initial_radius = r
	initial_velocity = v
	_reset_orbit()

func _reset_orbit():
	_satellite_pos = Vector3(initial_radius, 0, 0)
	_satellite_vel = Vector3(0, 0, initial_velocity)
	_trail.clear()

func _physics_process(delta):
	var dt = delta * time_scale
	
	# Gravitational acceleration: a = -GM/r² * r̂
	var r = _satellite_pos.length()
	if r < planet_radius:
		_reset_orbit()  # Crashed
		return
	
	var r_hat = _satellite_pos.normalized()
	var accel = -gravitational_constant * central_mass / (r * r) * r_hat
	
	# Velocity Verlet integration
	var new_pos = _satellite_pos + _satellite_vel * dt + 0.5 * accel * dt * dt
	
	var new_r = new_pos.length()
	var new_r_hat = new_pos.normalized()
	var new_accel = -gravitational_constant * central_mass / (new_r * new_r) * new_r_hat
	
	_satellite_vel += 0.5 * (accel + new_accel) * dt
	_satellite_pos = new_pos
	
	# Escape detection
	if r > 2.0:
		# Reset if too far
		pass
	
	# Update visuals
	_satellite.position = _satellite_pos
	_update_velocity_arrow()
	_update_trail()
	_update_info()

func _update_velocity_arrow():
	_velocity_arrow.position = _satellite_pos
	
	var vel_mag = _satellite_vel.length()
	var scale = clampf(vel_mag * 0.08, 0.05, 0.2)
	_velocity_arrow.scale = Vector3(1, scale / 0.1, 1)
	
	# Orient along velocity
	if vel_mag > 0.001:
		var up = Vector3.UP
		if abs(_satellite_vel.normalized().dot(up)) > 0.99:
			up = Vector3.FORWARD
		_velocity_arrow.look_at(_velocity_arrow.global_position + _satellite_vel, up)
		_velocity_arrow.rotate_object_local(Vector3.RIGHT, -PI/2)

func _update_trail():
	_trail.append(_satellite_pos)
	while _trail.size() > trail_length:
		_trail.remove_at(0)
	
	if _trail.size() < 2:
		return
	
	# Build trail mesh
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(_trail.size()):
		var alpha = float(i) / float(_trail.size())
		immediate_mesh.surface_set_color(Color(color_orbit.r, color_orbit.g, color_orbit.b, alpha * 0.6))
		immediate_mesh.surface_add_vertex(_trail[i])
	
	immediate_mesh.surface_end()
	_trail_mesh.mesh = immediate_mesh
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mesh.material_override = mat

func _update_info():
	var r = _satellite_pos.length()
	var v = _satellite_vel.length()
	
	# Specific orbital energy: E = v²/2 - GM/r
	var energy = 0.5 * v * v - gravitational_constant * central_mass / r
	var orbit_type = "ELLIPSE" if energy < 0 else ("PARABOLA" if energy < 0.01 else "HYPERBOLA")
	
	# Angular momentum
	var h = _satellite_pos.cross(_satellite_vel).length()
	
	_info_label.text = "ORBITAL MECHANICS\nr=%.3f v=%.3f E=%.3f\n%s  L=%.3f" % [r, v, energy, orbit_type, h]

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _set_orbit(0.3, 1.29)
			KEY_2: _set_orbit(0.2, 1.5)
			KEY_3: _set_orbit(0.25, 2.0)
			KEY_4: _set_orbit(0.35, 0.9)
			KEY_R: _reset_orbit()
			KEY_UP: time_scale = minf(time_scale + 0.2, 5.0)
			KEY_DOWN: time_scale = maxf(time_scale - 0.2, 0.1)

func set_time_scale(s: float):
	time_scale = s

func reset():
	_reset_orbit()