# flow_field_painter.gd
## Implements Perlin noise flow-field advection to visualize particle dynamics.
## Particles follow the gradient of a 2D+time noise field, leaving colored trails
## that create organic, paint-like patterns. The noise field evolves continuously,
## producing ever-changing flow structures.
## Key parameters: noise_scale controls field frequency, particle_speed sets advection rate.
##
## QFEP: Noise as structured randomness — not chaos, not order, but λ-edge

# @identity
# essence: a small canvas across which hundreds of particles drift, each one
#   blindly obeying the local angle of a Perlin noise field and dragging a
#   colored trail behind it. No particle is told where to go; it only reads the
#   field beneath its feet and steps. The image is the AGGREGATE of those steps
#   — paint laid down by a crowd that never agreed on a destination.
# desire: to make an invisible vector field visible by letting things FALL
#   through it. The field has no color, no shape, no edge; only when bodies
#   advect along it do its grain and swirls appear. It wants to show that
#   structure can be felt before it can be seen.
# critical_parameter: noise_scale — the spatial frequency of the field. Low and
#   the particles sweep in broad laminar rivers; high and the field shatters
#   into tight turbulent eddies. It is the dial between calm and chaos without
#   ever touching the particles themselves. (noise_speed evolves the field in
#   time so no frame's flow is the last word.)
# triggers: _ready() builds the canvas and seeds particles; _process(dt)
#   advances _time, samples the noise gradient at each particle, advects it by
#   particle_speed, and redraws fading trails into an ImmediateMesh
# emerges: large scale reads CURRENT / RIVER; small scale reads TURBULENCE /
#   STORM. Same particles, the field's frequency IS the difference between flow
#   that reads as ordered and flow that reads as chaotic — the λ-edge made paint
# relationships: sibling to other noise artifacts (all turn structured
#   randomness into form); cousin to forces/flocking artifacts (both move bodies
#   by a field rather than by command); peer to barnsley_fern (both fill a plane
#   from many cheap iterations, but the fern's points CONVERGE while these flow)
# truth: noise is not the absence of order but order at a length scale you have
#   not yet named. The painter is that thesis enacted — randomness given a
#   frequency becomes a current, and a current given bodies becomes a picture.

extends Node3D

class_name FlowFieldPainter

## Canvas dimensions in meters (width, height)
@export var canvas_size: Vector2 = Vector2(0.6, 0.4)

## Number of particles flowing through the field (1–2000)
@export_range(1, 2000) var num_particles: int = 500
## Particle movement speed in meters per second
@export_range(0.01, 1.0, 0.01) var particle_speed: float = 0.1
## Maximum trail length in samples per particle
@export_range(1, 200) var trail_length: int = 50
## Whether trails fade from transparent to opaque
@export var trail_fade: bool = true

## Noise field frequency multiplier — higher values create tighter flow patterns
@export_range(0.5, 10.0, 0.1) var noise_scale: float = 3.0:
	set(value):
		noise_scale = clampf(value, 0.5, 10.0)
		_update_noise()

## How fast the noise field evolves over time
@export_range(0.0, 1.0, 0.01) var noise_speed: float = 0.1

## Color palette cycled across particles
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
var _im: ImmediateMesh
var _trail_mat: StandardMaterial3D
var _info_label: Label3D
var _control_panel: Node3D
var _grid_config: Dictionary = {}

# Node cleanup tracking
var _created_nodes: Array[Node] = []

# VR control references (for signal disconnect)
var _scale_slider: Node
var _speed_slider: Node
var _reset_area: Node
var _seed_area: Node


const NOISE_BASE_FREQ := 0.01
const NOISE_SAMPLE_SCALE := 100.0
const NOISE_TIME_SCALE := 50.0
const FRAME_ELEVATION := 0.005
const FRAME_MARGIN := 0.02
const TRAIL_ELEVATION := 0.002
const TRAIL_ALPHA_SCALE := 0.6

## Initialize noise, canvas, particles, labels, and VR controls.
func _ready():
	_setup_noise()
	_create_canvas()
	_create_particles()
	_create_labels()
	_create_vr_controls()

	# Pre-create reusable ImmediateMesh and material for trails
	_im = ImmediateMesh.new()
	_trail_mat = StandardMaterial3D.new()
	_trail_mat.vertex_color_use_as_albedo = true
	_trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mesh.mesh = _im
	_trail_mesh.material_override = _trail_mat

## Configure the Perlin noise generator.
func _setup_noise():
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	_noise.frequency = NOISE_BASE_FREQ
	_noise.seed = randi()

## Update noise frequency when noise_scale changes.
func _update_noise():
	if _noise:
		_noise.frequency = NOISE_BASE_FREQ * noise_scale

## Build the canvas plane, frame edges (MultiMesh), and trail mesh node.
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
	_created_nodes.append(_canvas_mesh)

	# Frame — 4 edges via MultiMesh (2 horizontal, 2 vertical)
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.15, 0.15, 0.18)

	var box := BoxMesh.new()
	box.size = Vector3(1.0, 1.0, 1.0)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = false
	mm.mesh = box
	mm.instance_count = 4

	for i in range(4):
		var is_horizontal = i < 2
		var scale_vec: Vector3
		if is_horizontal:
			scale_vec = Vector3(canvas_size.x + FRAME_MARGIN, 0.01, 0.01)
		else:
			scale_vec = Vector3(0.01, 0.01, canvas_size.y + FRAME_MARGIN)

		var offset = 0.5 if i % 2 == 0 else -0.5
		var pos: Vector3
		if is_horizontal:
			pos = Vector3(0, FRAME_ELEVATION, offset * canvas_size.y)
		else:
			pos = Vector3(offset * canvas_size.x, FRAME_ELEVATION, 0)

		var xf := Transform3D(Basis().scaled(scale_vec), pos)
		mm.set_instance_transform(i, xf)

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = frame_mat
	mmi.name = "Frame"
	add_child(mmi)
	_created_nodes.append(mmi)

	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "Trails"
	add_child(_trail_mesh)
	_created_nodes.append(_trail_mesh)

## Spawn particles with random positions and assign palette colors.
func _create_particles():
	_particles.resize(num_particles)
	for i in range(num_particles):
		_particles[i] = {
			"x": randf() * canvas_size.x - canvas_size.x / 2.0,
			"y": randf() * canvas_size.y - canvas_size.y / 2.0,
			"trail": PackedVector2Array(),
			"color": palette[i % maxi(palette.size(), 1)],
			"hue_offset": randf() * 0.1 - 0.05
		}

## Create the title label above the canvas.
func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 16
	_info_label.position = Vector3(0, 0.08, -canvas_size.y / 2.0 - 0.05)
	_info_label.text = "FLOW FIELD"
	add_child(_info_label)
	_created_nodes.append(_info_label)

## Build the VR control panel with sliders and buttons.
func _create_vr_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var mount: String = str(_grid_config.get("mount", ""))
	var use_csg := mount in ["shelf", "wall", "floor"]

	var panel: Node3D = RackTpl.create_panel("FLOW FIELD", [
		[
			{"type": "slider_h", "label": "SCALE", "default": (noise_scale - 0.5) / 9.5},
			{"type": "slider_h", "label": "SPEED", "default": (particle_speed - 0.02) / 0.28},
		],
		[
			{"type": "button", "label": "RESET"},
			{"type": "button", "label": "SEED"},
		],
	], use_csg)

	if use_csg:
		var tilt := 35.0
		var color := Color(0.12, 0.12, 0.12)
		if mount == "wall":
			tilt = 0.0
		_control_panel = RackTpl.create_csg_case(0.28, 0.18, 0.16, tilt, panel, color)
		_control_panel.position = Vector3(0, -0.05, canvas_size.y / 2.0 + 0.12)
	else:
		_control_panel = panel
		_control_panel.position = Vector3(0, -0.05, canvas_size.y / 2.0 + 0.12)
		_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	_created_nodes.append(_control_panel)

	_scale_slider = _control_panel.find_child("Param_0", true, false)
	_speed_slider = _control_panel.find_child("Param_1", true, false)

	if _scale_slider and _scale_slider.has_signal("slider_moved"):
		_scale_slider.slider_moved.connect(_on_scale_slider_moved)
	if _speed_slider and _speed_slider.has_signal("slider_moved"):
		_speed_slider.slider_moved.connect(_on_speed_slider_moved)

	# Reset button
	var reset_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if reset_btn:
		_reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
		if _reset_area:
			_reset_area.button_pressed.connect(_reset_particles)

	# Seed button
	var seed_btn: Node = _control_panel.find_child("Btn_1", true, false)
	if seed_btn:
		_seed_area = seed_btn.get_node_or_null("InteractableAreaButton")
		if _seed_area:
			_seed_area.button_pressed.connect(_new_seed)

## Handle scale slider movement.
func _on_scale_slider_moved(_pos) -> void:
	if _scale_slider and _scale_slider.has_method("get_normalized_value"):
		noise_scale = 0.5 + _scale_slider.get_normalized_value() * 9.5

## Handle speed slider movement.
func _on_speed_slider_moved(_pos) -> void:
	if _speed_slider and _speed_slider.has_method("get_normalized_value"):
		particle_speed = 0.02 + _speed_slider.get_normalized_value() * 0.28

## Randomize all particle positions and clear their trails.
func _reset_particles(_button = null):  # Accept optional button arg
	for p in _particles:
		p.x = randf() * canvas_size.x - canvas_size.x / 2.0
		p.y = randf() * canvas_size.y - canvas_size.y / 2.0
		p.trail.clear()

## Generate a new noise seed and reset particles.
func _new_seed(_button = null):  # Accept optional button arg
	_noise.seed = randi()
	_reset_particles()

## Advect particles through the noise field and update trails each frame.
func _process(delta):
	_time = wrapf(_time + delta * noise_speed, 0.0, 1000.0)

	var half_cx := canvas_size.x / 2.0
	var half_cy := canvas_size.y / 2.0
	var inv_cx := 1.0 / maxf(canvas_size.x, 0.0001)
	var inv_cy := 1.0 / maxf(canvas_size.y, 0.0001)

	for p in _particles:
		# Get flow angle from noise
		var nx = (p.x + half_cx) * inv_cx * NOISE_SAMPLE_SCALE
		var ny = (p.y + half_cy) * inv_cy * NOISE_SAMPLE_SCALE
		var angle = _noise.get_noise_3d(nx * noise_scale, ny * noise_scale, _time * NOISE_TIME_SCALE) * TAU * 2.0

		# Move particle
		p.x += cos(angle) * particle_speed * delta
		p.y += sin(angle) * particle_speed * delta

		# Wrap around
		if p.x < -half_cx: p.x += canvas_size.x
		if p.x > half_cx: p.x -= canvas_size.x
		if p.y < -half_cy: p.y += canvas_size.y
		if p.y > half_cy: p.y -= canvas_size.y

		# Record trail
		p.trail.append(Vector2(p.x, p.y))
		if p.trail.size() > trail_length:
			p.trail.remove_at(0)

	_update_trail_mesh()

## Rebuild trail line geometry from particle trails using the cached ImmediateMesh.
func _update_trail_mesh():
	_im.clear_surfaces()
	# Nothing to draw until a particle has at least 2 trail points — calling
	# surface_end() on an empty surface errors. Bail early on those first frames.
	var _has_trail := false
	for p in _particles:
		if p.trail.size() >= 2:
			_has_trail = true
			break
	if not _has_trail:
		return
	_im.surface_begin(Mesh.PRIMITIVE_LINES)

	for p in _particles:
		if p.trail.size() < 2:
			continue

		var base_color = p.color
		var inv_trail_size := 1.0 / float(p.trail.size())

		for i in range(p.trail.size() - 1):
			var alpha = float(i) * inv_trail_size if trail_fade else 1.0
			var color = Color(base_color.r, base_color.g, base_color.b, alpha * TRAIL_ALPHA_SCALE)

			_im.surface_set_color(color)
			_im.surface_add_vertex(Vector3(p.trail[i].x, TRAIL_ELEVATION, p.trail[i].y))
			_im.surface_set_color(color)
			_im.surface_add_vertex(Vector3(p.trail[i + 1].x, TRAIL_ELEVATION, p.trail[i + 1].y))

	_im.surface_end()

## Disconnect signals and free created nodes on cleanup.
func _exit_tree():
	if _scale_slider and _scale_slider.slider_moved.is_connected(_on_scale_slider_moved):
		_scale_slider.slider_moved.disconnect(_on_scale_slider_moved)
	if _speed_slider and _speed_slider.slider_moved.is_connected(_on_speed_slider_moved):
		_speed_slider.slider_moved.disconnect(_on_speed_slider_moved)
	if _reset_area and _reset_area.button_pressed.is_connected(_reset_particles):
		_reset_area.button_pressed.disconnect(_reset_particles)
	if _seed_area and _seed_area.button_pressed.is_connected(_new_seed):
		_seed_area.button_pressed.disconnect(_new_seed)
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R: _reset_particles()
			KEY_N: _new_seed()
			KEY_UP: noise_scale = minf(noise_scale + 0.5, 10.0)
			KEY_DOWN: noise_scale = maxf(noise_scale - 0.5, 0.5)

func set_noise_scale(s: float) -> void:
	noise_scale = s

func reset() -> void:
	_reset_particles()

## Grid system integration hook.
func apply_grid_config(config_data: Dictionary) -> void:
	_grid_config = config_data
	if config_data.has("noise_scale"):
		noise_scale = config_data["noise_scale"]
	if config_data.has("particle_speed"):
		particle_speed = clampf(config_data["particle_speed"], 0.01, 1.0)
	if config_data.has("num_particles"):
		num_particles = clampi(int(config_data["num_particles"]), 1, 2000)
		_create_particles()
	if config_data.has("trail_length"):
		trail_length = clampi(int(config_data["trail_length"]), 1, 200)
	if config_data.has("noise_speed"):
		noise_speed = clampf(config_data["noise_speed"], 0.0, 1.0)
	if config_data.has("trail_fade"):
		trail_fade = config_data["trail_fade"]
