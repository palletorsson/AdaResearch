# queer_morphology_specimen.gd
# The synthesis artifact — form that refuses fixed categories
# Soft body + fluid + QFEP responsiveness in a specimen jar
#
# λ (lambda) = edge of chaos: how close to phase transition
# φ (phi) = becoming: embracing vs resisting transformation
#
# "Queer morphology" — not a fixed thing but a process of becoming

extends Node3D

class_name QueerMorphologySpecimen

## Jar dimensions
@export var jar_height: float = 0.4
@export var jar_radius: float = 0.15

## QFEP Parameters
@export_group("QFEP")
@export_range(0.0, 1.0) var lambda: float = 0.5:  # Edge of chaos
	set(value):
		lambda = clampf(value, 0.0, 1.0)
		_apply_lambda()
		_sync_lambda_slider()

@export_range(-1.0, 1.0) var phi: float = 0.0:  # Becoming
	set(value):
		phi = clampf(value, -1.0, 1.0)
		_apply_phi()
		_sync_phi_slider()

## Specimen properties
@export_group("Specimen")
@export var base_stiffness: float = 0.5
@export var base_pressure: float = 1.0
@export var base_damping: float = 0.05
@export var specimen_color: Color = Color(0.4, 0.2, 0.6, 0.85)

## Fluid properties
@export_group("Fluid")
@export var fluid_color: Color = Color(0.6, 0.8, 0.7, 0.3)
@export var fluid_turbulence: float = 0.5

var _jar_mesh: MeshInstance3D
var _fluid_mesh: MeshInstance3D
var _fluid_material: ShaderMaterial
var _soft_body: SoftBody3D
var _specimen_material: StandardMaterial3D
var _info_label: Label3D
var _state_label: Label3D

# VR Controls
var _lambda_slider: Node
var _phi_slider: Node
var _control_panel: Node3D

# State descriptions for different parameter regions
const STATES = {
	"crystalline": "CRYSTALLINE\nRigid structure\nResisting change",
	"stable": "STABLE\nOrdered equilibrium\nMaintaining form",
	"edge": "EDGE OF CHAOS\nMaximal complexity\nWhere life emerges",
	"fluid": "FLUID\nDissipative flow\nContinuous becoming",
	"dissolving": "DISSOLVING\nEntropy wins\nForm releasing"
}

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

const FLUID_SHADER = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

uniform vec4 fluid_color : source_color = vec4(0.6, 0.8, 0.7, 0.3);
uniform float turbulence = 0.5;
uniform float time_scale = 1.0;
uniform float lambda = 0.5;
uniform float phi = 0.0;

float noise3d(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
}

float fbm(vec3 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise3d(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * time_scale;
	
	// Fluid motion influenced by lambda (chaos) and phi (becoming)
	float chaos_factor = lambda * 2.0;
	float flow_factor = (phi + 1.0) / 2.0;
	
	vec3 flow = vec3(
		sin(t * 0.5 + world_pos.y * 3.0) * chaos_factor,
		cos(t * 0.3 + world_pos.x * 2.0) * flow_factor,
		sin(t * 0.4 + world_pos.z * 2.5) * turbulence
	);
	
	float noise = fbm(world_pos * 5.0 + flow + t * 0.2);
	
	// Color shifts with phi (negative = cold/rigid, positive = warm/fluid)
	vec3 color_shift = vec3(
		phi * 0.2,
		-abs(phi) * 0.1,
		-phi * 0.15
	);
	
	ALBEDO = fluid_color.rgb + color_shift + noise * 0.1;
	ALPHA = fluid_color.a * (0.8 + noise * 0.4);
	EMISSION = ALBEDO * lambda * 0.3;
}
"""

func _ready():
	_create_jar()
	_create_fluid()
	_create_specimen()
	_create_labels()
	_create_vr_controls()
	_apply_lambda()
	_apply_phi()

func _create_jar():
	# Glass jar (cylinder with transparent material)
	_jar_mesh = MeshInstance3D.new()
	_jar_mesh.name = "JarGlass"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = jar_radius
	cylinder.bottom_radius = jar_radius * 1.05
	cylinder.height = jar_height
	cylinder.radial_segments = 32
	_jar_mesh.mesh = cylinder
	
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.9, 0.95, 1.0, 0.15)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_mat.metallic = 0.1
	glass_mat.roughness = 0.05
	glass_mat.refraction_enabled = true
	glass_mat.refraction_scale = 0.02
	_jar_mesh.material_override = glass_mat
	
	_jar_mesh.position = Vector3(0, jar_height / 2, 0)
	add_child(_jar_mesh)
	
	# Jar lid
	var lid = MeshInstance3D.new()
	lid.name = "JarLid"
	var lid_cyl = CylinderMesh.new()
	lid_cyl.top_radius = jar_radius * 1.1
	lid_cyl.bottom_radius = jar_radius * 1.15
	lid_cyl.height = 0.03
	lid.mesh = lid_cyl
	
	var lid_mat = StandardMaterial3D.new()
	lid_mat.albedo_color = Color(0.25, 0.22, 0.2)
	lid_mat.metallic = 0.8
	lid_mat.roughness = 0.4
	lid.material_override = lid_mat
	lid.position = Vector3(0, jar_height + 0.015, 0)
	add_child(lid)
	
	# Jar base
	var base = MeshInstance3D.new()
	base.name = "JarBase"
	var base_cyl = CylinderMesh.new()
	base_cyl.top_radius = jar_radius * 1.2
	base_cyl.bottom_radius = jar_radius * 1.3
	base_cyl.height = 0.025
	base.mesh = base_cyl
	base.material_override = lid_mat
	base.position = Vector3(0, -0.0125, 0)
	add_child(base)
	
	# Museum pedestal
	var pedestal = MeshInstance3D.new()
	pedestal.name = "Pedestal"
	var ped_box = BoxMesh.new()
	ped_box.size = Vector3(jar_radius * 3, 0.08, jar_radius * 3)
	pedestal.mesh = ped_box
	
	var ped_mat = StandardMaterial3D.new()
	ped_mat.albedo_color = Color(0.12, 0.12, 0.14)
	ped_mat.metallic = 0.5
	ped_mat.roughness = 0.6
	pedestal.material_override = ped_mat
	pedestal.position = Vector3(0, -0.065, 0)
	add_child(pedestal)

func _create_fluid():
	# Inner fluid volume (slightly smaller than jar)
	_fluid_mesh = MeshInstance3D.new()
	_fluid_mesh.name = "FluidVolume"
	
	var fluid_cyl = CylinderMesh.new()
	fluid_cyl.top_radius = jar_radius * 0.9
	fluid_cyl.bottom_radius = jar_radius * 0.9
	fluid_cyl.height = jar_height * 0.85
	_fluid_mesh.mesh = fluid_cyl
	
	_fluid_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = FLUID_SHADER
	_fluid_material.shader = shader
	_fluid_material.set_shader_parameter("fluid_color", fluid_color)
	_fluid_material.set_shader_parameter("turbulence", fluid_turbulence)
	_fluid_material.set_shader_parameter("lambda", lambda)
	_fluid_material.set_shader_parameter("phi", phi)
	
	_fluid_mesh.material_override = _fluid_material
	_fluid_mesh.position = Vector3(0, jar_height / 2, 0)
	add_child(_fluid_mesh)

func _create_specimen():
	# The morphing creature — a soft body sphere that deforms
	_soft_body = SoftBody3D.new()
	_soft_body.name = "Specimen"
	
	# Use subdivided sphere for organic deformation
	var sphere = SphereMesh.new()
	sphere.radius = jar_radius * 0.4
	sphere.height = jar_radius * 0.8
	sphere.radial_segments = 16
	sphere.rings = 12
	_soft_body.mesh = sphere
	
	# Physics
	_soft_body.simulation_precision = 8
	_soft_body.total_mass = 0.5
	_soft_body.linear_stiffness = base_stiffness
	_soft_body.pressure_coefficient = base_pressure
	_soft_body.damping_coefficient = base_damping
	_soft_body.drag_coefficient = 0.1
	
	# Collision
	_soft_body.collision_layer = 1
	_soft_body.collision_mask = 1
	
	# Material
	_specimen_material = StandardMaterial3D.new()
	_specimen_material.albedo_color = specimen_color
	_specimen_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_specimen_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_specimen_material.emission_enabled = true
	_specimen_material.emission = specimen_color
	_specimen_material.emission_energy_multiplier = 0.2
	_specimen_material.roughness = 0.3
	_specimen_material.metallic = 0.1
	_specimen_material.subsurf_scatter_enabled = true
	_specimen_material.subsurf_scatter_strength = 0.5
	
	_soft_body.material_override = _specimen_material
	_soft_body.position = Vector3(0, jar_height * 0.5, 0)
	
	add_child(_soft_body)
	
	# Invisible boundary to keep specimen in jar
	_create_jar_collision()

func _create_jar_collision():
	# Cylinder collision to contain soft body
	var area = Area3D.new()
	area.name = "JarBoundary"
	
	# Bottom
	var bottom = StaticBody3D.new()
	var bottom_shape = CollisionShape3D.new()
	var bottom_box = BoxShape3D.new()
	bottom_box.size = Vector3(jar_radius * 2, 0.02, jar_radius * 2)
	bottom_shape.shape = bottom_box
	bottom.add_child(bottom_shape)
	bottom.position = Vector3(0, 0.01, 0)
	add_child(bottom)

func _create_labels():
	# Title
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 20
	_info_label.position = Vector3(0, jar_height + 0.12, 0)
	_info_label.text = "QUEER MORPHOLOGY\nSPECIMEN"
	add_child(_info_label)
	
	# State description (changes with parameters)
	_state_label = Label3D.new()
	_state_label.name = "StateLabel"
	_state_label.pixel_size = 0.0015
	_state_label.font_size = 16
	_state_label.position = Vector3(0, -0.15, jar_radius + 0.08)
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_state_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.05, jar_radius + 0.2)
	_control_panel.rotation_degrees = Vector3(20, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.35, 0.15, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.06, 0.06, 0.08)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	_control_panel.add_child(panel_back)
	
	# Lambda slider (edge of chaos: 0-1)
	_lambda_slider = SLIDER_HORIZONTAL.instantiate()
	_lambda_slider.name = "LambdaSlider"
	_lambda_slider.position = Vector3(-0.08, 0.025, 0.015)
	var lambda_label = _lambda_slider.get_node_or_null("Frame/LabelName")
	if lambda_label:
		lambda_label.text = "λ EDGE"
	_control_panel.add_child(_lambda_slider)
	_lambda_slider.slider_moved.connect(_on_lambda_slider_moved)
	
	# Phi slider (becoming: -1 to 1)
	_phi_slider = SLIDER_HORIZONTAL.instantiate()
	_phi_slider.name = "PhiSlider"
	_phi_slider.position = Vector3(0.08, 0.025, 0.015)
	var phi_label = _phi_slider.get_node_or_null("Frame/LabelName")
	if phi_label:
		phi_label.text = "φ BECOME"
	_control_panel.add_child(_phi_slider)
	_phi_slider.slider_moved.connect(_on_phi_slider_moved)
	
	# Preset buttons
	var presets = [
		["CRYST", 0.1, -0.8],  # Crystalline
		["EDGE", 0.5, 0.0],    # Edge of chaos
		["FLUID", 0.8, 0.6],   # Fluid becoming
	]
	
	for i in range(presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % i
		btn.position = Vector3(-0.1 + i * 0.1, -0.04, 0.015)
		_control_panel.add_child(btn)
		_add_button_label(btn, presets[i][0])
		
		var l = presets[i][1]
		var p = presets[i][2]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(): _apply_preset(l, p))
	
	call_deferred("_sync_sliders_deferred")

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 9
	lbl.position = Vector3(0, -0.025, 0.01)
	btn.add_child(lbl)

func _sync_sliders_deferred():
	_sync_lambda_slider()
	_sync_phi_slider()

func _sync_lambda_slider():
	if _lambda_slider and _lambda_slider.has_method("set_normalized_value"):
		_lambda_slider.set_normalized_value(lambda)

func _sync_phi_slider():
	if _phi_slider and _phi_slider.has_method("set_normalized_value"):
		_phi_slider.set_normalized_value((phi + 1.0) / 2.0)

func _on_lambda_slider_moved(_position):
	if _lambda_slider and _lambda_slider.has_method("get_normalized_value"):
		lambda = _lambda_slider.get_normalized_value()

func _on_phi_slider_moved(_position):
	if _phi_slider and _phi_slider.has_method("get_normalized_value"):
		var norm = _phi_slider.get_normalized_value()
		phi = norm * 2.0 - 1.0

func _apply_preset(l: float, p: float):
	lambda = l
	phi = p

func _apply_lambda():
	if not _soft_body:
		return
	
	# Low lambda: rigid, crystalline structure
	# High lambda: fluid, chaotic, near phase transition
	
	# Stiffness: high when ordered, low when chaotic
	_soft_body.linear_stiffness = lerpf(0.9, 0.1, lambda)
	
	# Pressure: increases at edge, specimen "breathes"
	var edge_boost = 1.0 - abs(lambda - 0.5) * 2.0  # Peaks at 0.5
	_soft_body.pressure_coefficient = base_pressure * (1.0 + edge_boost * 0.5)
	
	# Update fluid shader
	if _fluid_material:
		_fluid_material.set_shader_parameter("lambda", lambda)
	
	# Color shift: blue/cold when ordered, warm when chaotic
	if _specimen_material:
		var hue_shift = lambda * 0.15  # Shift toward warm
		var color = specimen_color
		color.h = fmod(color.h + hue_shift, 1.0)
		color.s = lerpf(0.3, 0.8, lambda)
		_specimen_material.albedo_color = color
		_specimen_material.emission = color
		_specimen_material.emission_energy_multiplier = lerpf(0.1, 0.4, lambda)
	
	_update_state_label()

func _apply_phi():
	if not _soft_body:
		return
	
	# Negative phi: resists change, high damping
	# Positive phi: embraces transformation, low damping
	
	# Damping: high when resisting, low when flowing
	_soft_body.damping_coefficient = lerpf(0.2, 0.001, (phi + 1.0) / 2.0)
	
	# Drag: resisting = more drag
	_soft_body.drag_coefficient = lerpf(0.3, 0.0, (phi + 1.0) / 2.0)
	
	# Update fluid shader
	if _fluid_material:
		_fluid_material.set_shader_parameter("phi", phi)
	
	# Subsurface scatter: more when becoming
	if _specimen_material:
		_specimen_material.subsurf_scatter_strength = lerpf(0.2, 0.8, (phi + 1.0) / 2.0)
	
	_update_state_label()

func _update_state_label():
	if not _state_label:
		return
	
	var state: String
	
	if lambda < 0.2:
		state = "crystalline" if phi < 0 else "stable"
	elif lambda < 0.4:
		state = "stable"
	elif lambda < 0.6:
		state = "edge"
	elif lambda < 0.8:
		state = "fluid"
	else:
		state = "dissolving" if phi > 0 else "fluid"
	
	_state_label.text = STATES.get(state, "")
	
	# Also update title with current values
	_info_label.text = "QUEER MORPHOLOGY\nλ=%.2f φ=%+.2f" % [lambda, phi]

func _process(_delta):
	# Gentle oscillation to keep specimen alive
	if _soft_body and is_inside_tree():
		# Breathing motion influenced by lambda
		var breathe_speed = lerpf(0.5, 2.0, lambda)
		var breathe_amp = lerpf(0.02, 0.1, lambda)
		var breathe = sin(Time.get_ticks_msec() * 0.001 * breathe_speed) * breathe_amp
		
		# Apply subtle force (only when at edge of chaos)
		if lambda > 0.3 and lambda < 0.7:
			_soft_body.pressure_coefficient = base_pressure * (1.0 + breathe)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				lambda = maxf(0, lambda - 0.05)
			KEY_RIGHT:
				lambda = minf(1, lambda + 0.05)
			KEY_DOWN:
				phi = maxf(-1, phi - 0.1)
			KEY_UP:
				phi = minf(1, phi + 0.1)
			KEY_1:
				_apply_preset(0.1, -0.8)  # Crystalline
			KEY_2:
				_apply_preset(0.5, 0.0)   # Edge
			KEY_3:
				_apply_preset(0.8, 0.6)   # Fluid

## External API
func set_lambda(value: float):
	lambda = value

func set_phi(value: float):
	phi = value

func get_state() -> String:
	if lambda < 0.3:
		return "ordered"
	elif lambda < 0.7:
		return "edge"
	else:
		return "chaotic"
