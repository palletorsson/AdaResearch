# flow_field_painter.gd
# Particles flowing through a Perlin noise field
# Creates organic, paint-like patterns
#
# QFEP: Noise as structured randomness — not chaos, not order, but λ-edge

extends Node3D

class_name FlowFieldPainter

## Canvas size
@export var canvas_size: Vector2 = Vector2(0.6, 0.4)

## Particle parameters
@export var num_particles: int = 500
@export var particle_speed: float = 0.1
@export var trail_length: int = 50
@export var trail_fade: bool = true

## Noise parameters
@export var noise_scale: float = 3.0:
	set(value):
		noise_scale = clampf(value, 0.5, 10.0)
		_update_noise()

@export var noise_speed: float = 0.1

## Colors
@export var palette: Array[Color] = [
	Color(0.9, 0.2, 0.3),
	Color(0.9, 0.5, 0.1),
	Color(0.2, 0.7, 0.9),
	Color(0.3, 0.9, 0.4),
	Color(0.8, 0.3, 0.9)
]

# State
var _noise: FastNoiseLite
var _particles: Array[Dictionary] = []
var _time: float = 0.0

# Visuals
var _canvas_mesh: MeshInstance3D
var _trail_mesh: MeshInstance3D
var _info_label: Label3D
var _control_panel: Node3D

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")
const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")

func _ready():
	_setup_noise()
	_create_canvas()
	_create_particles()
	_create_labels()
	_create_vr_controls()

func _setup_noise():
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = 0.01
	_noise.seed = randi()

func _update_noise():
	if _noise:
		_noise.frequency = 0.01 * noise_scale

func _create_canvas():
	_canvas_mesh = MeshInstance3D.new()
	_canvas_mesh.name = "Canvas"
	var plane = PlaneMesh.new()
	plane.size = canvas_size
	_canvas_mesh.mesh = plane
	_canvas_mesh.rotation_degrees.x = -90
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.02, 0.02, 0.03)
	_canvas_mesh.material_override = mat
	add_child(_canvas_mesh)
	
	# Frame
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.15, 0.15, 0.18)
	
	for i in range(4):
		var edge = MeshInstance3D.new()
		var is_horizontal = i < 2
		var box = BoxMesh.new()
		if is_horizontal:
			box.size = Vector3(canvas_size.x + 0.02, 0.01, 0.01)
		else:
			box.size = Vector3(0.01, 0.01, canvas_size.y + 0.02)
		edge.mesh = box
		edge.material_override = frame_mat
		
		var offset = 0.5 if i % 2 == 0 else -0.5
		if is_horizontal:
			edge.position = Vector3(0, 0.005, offset * canvas_size.y)
		else:
			edge.position = Vector3(offset * canvas_size.x, 0.005, 0)
		add_child(edge)
	
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "Trails"
	add_child(_trail_mesh)

func _create_particles():
	for i in range(num_particles):
		var particle = {
			"x": randf() * canvas_size.x - canvas_size.x/2,
			"y": randf() * canvas_size.y - canvas_size.y/2,
			"trail": PackedVector2Array(),
			"color": palette[i % palette.size()],
			"hue_offset": randf() * 0.1 - 0.05
		}
		_particles.append(particle)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 16
	_info_label.position = Vector3(0, 0.08, -canvas_size.y/2 - 0.05)
	_info_label.text = "FLOW FIELD"
	add_child(_info_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.05, canvas_size.y/2 + 0.12)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	# Panel
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.4, 0.12, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Scale slider
	var scale_slider = SLIDER_HORIZONTAL.instantiate()
	scale_slider.name = "ScaleSlider"
	scale_slider.position = Vector3(-0.08, 0.025, 0)
	scale_slider.scale = Vector3(0.8, 0.8, 0.8)
	var scale_label = scale_slider.get_node_or_null("Frame/LabelName")
	if scale_label:
		scale_label.text = "SCALE"
	_control_panel.add_child(scale_slider)
	scale_slider.slider_moved.connect(func(_pos):
		if scale_slider.has_method("get_normalized_value"):
			noise_scale = 0.5 + scale_slider.get_normalized_value() * 9.5
	)
	
	# Speed slider
	var speed_slider = SLIDER_HORIZONTAL.instantiate()
	speed_slider.name = "SpeedSlider"
	speed_slider.position = Vector3(0.08, 0.025, 0)
	speed_slider.scale = Vector3(0.8, 0.8, 0.8)
	var speed_label = speed_slider.get_node_or_null("Frame/LabelName")
	if speed_label:
		speed_label.text = "SPEED"
	_control_panel.add_child(speed_slider)
	speed_slider.slider_moved.connect(func(_pos):
		if speed_slider.has_method("get_normalized_value"):
			particle_speed = 0.02 + speed_slider.get_normalized_value() * 0.28
	)
	
	# Buttons
	var reset_btn = PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetBtn"
	reset_btn.position = Vector3(-0.08, -0.025, 0)
	reset_btn.scale = Vector3(0.7, 0.7, 0.7)
	_control_panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RESET")
	var reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(_reset_particles)
	
	var seed_btn = PUSH_BUTTON.instantiate()
	seed_btn.name = "SeedBtn"
	seed_btn.position = Vector3(0.08, -0.025, 0)
	seed_btn.scale = Vector3(0.7, 0.7, 0.7)
	_control_panel.add_child(seed_btn)
	_add_button_label(seed_btn, "NEW SEED")
	var seed_area = seed_btn.get_node_or_null("InteractableAreaButton")
	if seed_area:
		seed_area.button_pressed.connect(_new_seed)

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.0008
	lbl.font_size = 6
	lbl.position = Vector3(0, -0.02, 0)
	btn.add_child(lbl)

func _reset_particles():
	for p in _particles:
		p.x = randf() * canvas_size.x - canvas_size.x/2
		p.y = randf() * canvas_size.y - canvas_size.y/2
		p.trail.clear()

func _new_seed():
	_noise.seed = randi()
	_reset_particles()

func _process(delta):
	_time += delta * noise_speed
	
	for p in _particles:
		# Get flow angle from noise
		var nx = (p.x + canvas_size.x/2) / canvas_size.x * 100
		var ny = (p.y + canvas_size.y/2) / canvas_size.y * 100
		var angle = _noise.get_noise_3d(nx * noise_scale, ny * noise_scale, _time * 50) * TAU * 2
		
		# Move particle
		p.x += cos(angle) * particle_speed * delta
		p.y += sin(angle) * particle_speed * delta
		
		# Wrap around
		if p.x < -canvas_size.x/2: p.x += canvas_size.x
		if p.x > canvas_size.x/2: p.x -= canvas_size.x
		if p.y < -canvas_size.y/2: p.y += canvas_size.y
		if p.y > canvas_size.y/2: p.y -= canvas_size.y
		
		# Record trail
		p.trail.append(Vector2(p.x, p.y))
		if p.trail.size() > trail_length:
			p.trail = p.trail.slice(1)
	
	_update_trail_mesh()

func _update_trail_mesh():
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for p in _particles:
		if p.trail.size() < 2:
			continue
		
		var base_color = p.color
		
		for i in range(p.trail.size() - 1):
			var alpha = float(i) / float(p.trail.size()) if trail_fade else 1.0
			var color = Color(base_color.r, base_color.g, base_color.b, alpha * 0.6)
			
			immediate_mesh.surface_set_color(color)
			immediate_mesh.surface_add_vertex(Vector3(p.trail[i].x, 0.002, p.trail[i].y))
			immediate_mesh.surface_set_color(color)
			immediate_mesh.surface_add_vertex(Vector3(p.trail[i+1].x, 0.002, p.trail[i+1].y))
	
	immediate_mesh.surface_end()
	_trail_mesh.mesh = immediate_mesh
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mesh.material_override = mat

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R: _reset_particles()
			KEY_N: _new_seed()
			KEY_UP: noise_scale = minf(noise_scale + 0.5, 10.0)
			KEY_DOWN: noise_scale = maxf(noise_scale - 0.5, 0.5)

func set_scale(s: float):
	noise_scale = s

func reset():
	_reset_particles()
