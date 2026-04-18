extends XRToolsPickable
class_name GrabbableLine

# @identity
# essence: a line segment you hold as one object — grab anywhere along its length to move it through space
# desire: learner feels the line as a single entity, not two separate points — unity before decomposition
# critical_parameter: line_length — the fixed distance between endpoints, shown on the label
# triggers: grab the body to move; resistance glitch fires when position crosses integer grid lines
# emerges: a line is one thing made of two points — holding it whole precedes understanding it as parts
# needs: XRToolsPickable [has]; CylinderMesh [has]; endpoint spheres [has]; Label3D [has]
# relationships: complement to line.tscn (endpoints-first); precedes line in sequence for whole→parts arc
# truth: you can hold a line before you know it has endpoints

## Whole-line grabbable — pick up anywhere along the cylinder to move the entire line.
## Endpoints are visible but not independently grabbable. Fixed length.
## Includes the integer-resistance glitch from line.gd.

@export_group("Line Properties")
@export var line_length: float = 0.24:
	set(value):
		line_length = clamp(value, 0.05, 5.0)
		if is_inside_tree():
			_rebuild()
@export var line_thickness: float = 0.008
@export var line_color: Color = Color(0.788, 0.463, 0.996)  # purple, matching line.gd
@export var endpoint_radius: float = 0.018

@export_group("Display")
@export var show_length_label: bool = true
@export var show_endpoints: bool = true

@export_group("Resistance Glitch")
@export var enable_resistance: bool = true
@export var resistance_threshold: float = 0.08
@export var max_jitter: float = 0.015
@export var haptic_intensity_max: float = 0.8
@export var glitch_sound_volume_db: float = -12.0

# Internal
var _line_mesh: MeshInstance3D
var _cylinder: CylinderMesh
var _line_material: StandardMaterial3D
var _endpoint_a: MeshInstance3D
var _endpoint_b: MeshInstance3D
var _length_label: Label3D
var _glitch_player: AudioStreamPlayer3D
var _glitch_stream: AudioStreamWAV
var _is_held := false
var _current_controller: XRController3D


func _ready() -> void:
	super()
	_build_collision()
	_build_line_mesh()
	_build_endpoints()
	if show_length_label:
		_build_label()
	_setup_glitch_audio()
	_rebuild()

	picked_up.connect(_on_line_picked_up)
	dropped.connect(_on_line_dropped)


func _process(_delta: float) -> void:
	if enable_resistance and _is_held:
		_process_position_resistance()


# ── Build ────────────────────────────────────────────────────────────

func _build_collision() -> void:
	# Capsule collision along the line body so you can grab anywhere
	var col := CollisionShape3D.new()
	col.name = "LineCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = max(line_thickness * 3.0, 0.025)  # wide enough to grab
	capsule.height = line_length + capsule.radius * 2.0
	col.shape = capsule
	# Capsule aligns along Y by default — line extends along X, so rotate
	col.rotation_degrees.z = 90.0
	add_child(col)


func _build_line_mesh() -> void:
	_line_mesh = MeshInstance3D.new()
	_line_mesh.name = "LineMesh"
	_line_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_line_mesh)

	_cylinder = CylinderMesh.new()
	_cylinder.top_radius = line_thickness
	_cylinder.bottom_radius = line_thickness
	_cylinder.radial_segments = 8
	_cylinder.rings = 0
	_line_mesh.mesh = _cylinder

	_line_material = StandardMaterial3D.new()
	_line_material.albedo_color = line_color
	_line_material.metallic = 0.8
	_line_material.roughness = 0.1
	_line_material.emission_enabled = true
	_line_material.emission = line_color
	_line_material.emission_energy_multiplier = 0.8
	_line_mesh.material_override = _line_material

	# Line extends along X axis — rotate cylinder (default Y) to lie along X
	_line_mesh.rotation_degrees.z = 90.0


func _build_endpoints() -> void:
	if not show_endpoints:
		return

	var mat := StandardMaterial3D.new()
	mat.albedo_color = line_color.lightened(0.3)
	mat.metallic = 0.7
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = line_color
	mat.emission_energy_multiplier = 1.0

	var sphere := SphereMesh.new()
	sphere.radius = endpoint_radius
	sphere.height = endpoint_radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6

	_endpoint_a = MeshInstance3D.new()
	_endpoint_a.name = "EndpointA"
	_endpoint_a.mesh = sphere
	_endpoint_a.material_override = mat
	_endpoint_a.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_endpoint_a)

	_endpoint_b = MeshInstance3D.new()
	_endpoint_b.name = "EndpointB"
	_endpoint_b.mesh = sphere.duplicate()
	_endpoint_b.material_override = mat
	_endpoint_b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_endpoint_b)


func _build_label() -> void:
	_length_label = Label3D.new()
	_length_label.name = "LengthLabel"
	_length_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_length_label.font_size = 28
	_length_label.modulate = Color(1.0, 1.0, 1.0, 0.8)
	_length_label.outline_size = 4
	_length_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	_length_label.pixel_size = 0.001
	add_child(_length_label)


func _rebuild() -> void:
	var half := line_length / 2.0

	if _cylinder:
		_cylinder.height = line_length

	if _endpoint_a:
		_endpoint_a.position = Vector3(-half, 0, 0)
	if _endpoint_b:
		_endpoint_b.position = Vector3(half, 0, 0)

	if _length_label:
		_length_label.text = "%.2fm" % line_length
		_length_label.position = Vector3(0, 0.04, 0)

	# Update collision
	var col := get_node_or_null("LineCollision")
	if col and col.shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = col.shape
		capsule.height = line_length + capsule.radius * 2.0


# ── Pickup ───────────────────────────────────────────────────────────

func _on_line_picked_up(_pickable) -> void:
	_is_held = true
	_current_controller = get_picked_up_by_controller()
	if _current_controller:
		_current_controller.trigger_haptic_pulse("haptic", 100.0, 0.4, 0.08, 0)
	# Glow brighter when held
	if _line_material:
		_line_material.emission_energy_multiplier = 1.5


func _on_line_dropped(_pickable) -> void:
	_is_held = false
	if _current_controller:
		_current_controller.trigger_haptic_pulse("haptic", 100.0, 0.2, 0.05, 0)
		_current_controller = null
	# Restore normal glow
	if _line_material:
		_line_material.emission_energy_multiplier = 0.8
	# Reset jitter
	if _line_mesh:
		_line_mesh.position = Vector3.ZERO


# ── Resistance Glitch ────────────────────────────────────────────────

func _process_position_resistance() -> void:
	# Glitch when the line's CENTER crosses near integer world coordinates
	var pos := global_position
	var axes := [pos.x, pos.y, pos.z]
	var max_intensity := 0.0

	for val in axes:
		var remainder: float = fmod(abs(val), 1.0)
		var dist_to_int: float = minf(remainder, 1.0 - remainder)
		if dist_to_int < resistance_threshold:
			var t: float = 1.0 - (dist_to_int / resistance_threshold)
			max_intensity = maxf(max_intensity, pow(t, 2.0))

	if max_intensity > 0.01:
		# Visual jitter
		if _line_mesh:
			var jitter := Vector3(
				randf_range(-1, 1),
				randf_range(-1, 1),
				randf_range(-1, 1)
			) * max_jitter * max_intensity
			_line_mesh.position = jitter

			# Flash emission
			if randf() < max_intensity * 0.15:
				_line_material.emission_energy_multiplier = 4.0
			else:
				_line_material.emission_energy_multiplier = 1.5

		# Audio
		if _glitch_player:
			_glitch_player.volume_db = lerp(-40.0, glitch_sound_volume_db, max_intensity)
			_glitch_player.pitch_scale = 1.0 + (randf() - 0.5) * max_intensity

		# Haptic
		if _current_controller:
			var freq := 100.0 + max_intensity * 200.0
			_current_controller.trigger_haptic_pulse("haptic", freq, max_intensity * haptic_intensity_max, 0.05, 0)

		# Label glitch
		if _length_label and randf() < max_intensity * 0.2:
			_length_label.modulate = Color.RED
		elif _length_label:
			_length_label.modulate = Color(1.0, 1.0, 1.0, 0.8)
	else:
		# Reset
		if _line_mesh:
			_line_mesh.position = Vector3.ZERO
		if _glitch_player:
			_glitch_player.volume_db = -80.0
		if _length_label:
			_length_label.modulate = Color(1.0, 1.0, 1.0, 0.8)
		if _line_material:
			_line_material.emission_energy_multiplier = 1.5 if _is_held else 0.8


func _setup_glitch_audio() -> void:
	_glitch_stream = _generate_glitch_stream()
	_glitch_player = AudioStreamPlayer3D.new()
	_glitch_player.name = "GlitchPlayer"
	_glitch_player.stream = _glitch_stream
	_glitch_player.unit_size = 5.0
	_glitch_player.volume_db = -80.0
	_glitch_player.autoplay = true
	add_child(_glitch_player)


func _generate_glitch_stream() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var duration := 0.5
	var sample_count := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var sample: float = randf_range(-1.0, 1.0) * 0.8
		if randf() > 0.95:
			sample = sign(sample) * 1.0
		var int_sample: int = int(sample * 32767.0)
		data[2 * i] = int_sample & 0xFF
		data[2 * i + 1] = (int_sample >> 8) & 0xFF
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream


# ── Public API ───────────────────────────────────────────────────────

func get_endpoint_a_global() -> Vector3:
	return _endpoint_a.global_position if _endpoint_a else global_position

func get_endpoint_b_global() -> Vector3:
	return _endpoint_b.global_position if _endpoint_b else global_position

func set_line_color(color: Color) -> void:
	line_color = color
	if _line_material:
		_line_material.albedo_color = color
		_line_material.emission = color


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("line_length"):
		line_length = config_data["line_length"]
	if config_data.has("line_color"):
		set_line_color(config_data["line_color"])
	if config_data.has("enable_resistance"):
		enable_resistance = config_data["enable_resistance"]
