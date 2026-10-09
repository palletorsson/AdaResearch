@tool
extends Node3D

# Agent-WhiteNoise: 3D White Noise Spectrum Visualization
# Generates a field of thin lines where height represents random values.

enum NoiseType {
    WHITE,
    PINK,
    BROWN,
    BLUE,
    VIOLET
}

@export var grid_size: Vector2i = Vector2i(50, 50)
@export var spacing: float = 0.2
@export var max_height: float = 2.0
@export var line_thickness: float = 0.02
@export var seed_value: int = 0:
    set(value):
        seed_value = value
        if is_inside_tree():
            generate_spectrum()

@export var color_gradient: Gradient

@export var audio_gain: float = 0.16
@export var audio_mix_rate: int = 44100
@export var audio_buffer_length: float = 0.2

var _rng = RandomNumberGenerator.new()
var _audio_rng = RandomNumberGenerator.new()
var _multi_mesh_instance: MultiMeshInstance3D

var _control_panel: Node3D
var _status_label: Label3D
var _audio_player: AudioStreamPlayer3D
var _audio_generator: AudioStreamGenerator
var _audio_stream: AudioStreamGeneratorPlayback
var _audio_playing := false
var _current_audio_noise: NoiseType = NoiseType.WHITE

# Colored noise filter states
var _pink_b0 := 0.0
var _pink_b1 := 0.0
var _pink_b2 := 0.0
var _pink_b3 := 0.0
var _pink_b4 := 0.0
var _pink_b5 := 0.0
var _pink_b6 := 0.0
var _brown_state := 0.0
var _blue_lowpass := 0.0
var _previous_white := 0.0

var _rack_panel: Node3D

func _ready() -> void:
    _setup_multimesh()
    generate_spectrum()
    if Engine.is_editor_hint():
        return
    _setup_audio_player()
    _create_vr_controls()

func _process(_delta):
    if Engine.is_editor_hint():
        return
    _fill_audio_buffer()

func _setup_multimesh() -> void:
    if _multi_mesh_instance:
        _multi_mesh_instance.queue_free()
    
    _multi_mesh_instance = MultiMeshInstance3D.new()
    add_child(_multi_mesh_instance)
    
    var mesh = BoxMesh.new()
    mesh.size = Vector3(line_thickness, 1.0, line_thickness) # Unit height, scaled later
    
    var material = StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mesh.material = material
    
    _multi_mesh_instance.multimesh = MultiMesh.new()
    _multi_mesh_instance.multimesh.mesh = mesh
    _multi_mesh_instance.multimesh.transform_format = MultiMesh.TRANSFORM_3D
    _multi_mesh_instance.multimesh.use_colors = true

func generate_spectrum() -> void:
    if not _multi_mesh_instance:
        return

    _apply_seed_state()
        
    var count = grid_size.x * grid_size.y
    _multi_mesh_instance.multimesh.instance_count = count
    
    var idx = 0
    var offset_x = (grid_size.x * spacing) / 2.0
    var offset_z = (grid_size.y * spacing) / 2.0
    
    for x in range(grid_size.x):
        for z in range(grid_size.y):
            var random_val = _rng.randf() # 0.0 to 1.0
            var height = random_val * max_height
            
            # Position: Centered on XZ, Y based on height (growing up from 0)
            var pos = Vector3(x * spacing - offset_x, height / 2.0, z * spacing - offset_z)
            
            # Transform: Scale Y to match height
            var basis = Basis()
            basis = basis.scaled(Vector3(1.0, height, 1.0))
            var transform = Transform3D(basis, pos)
            
            _multi_mesh_instance.multimesh.set_instance_transform(idx, transform)
            
            # Color: Map random value to gradient or grayscale
            var color = Color.WHITE
            if color_gradient:
                color = color_gradient.sample(random_val)
            else:
                color = Color(random_val, random_val, random_val)
            
            _multi_mesh_instance.multimesh.set_instance_color(idx, color)
            idx += 1

func _apply_seed_state() -> void:
    if seed_value == 0:
        _rng.randomize()
        _audio_rng.randomize()
        return
    _rng.seed = seed_value
    _audio_rng.seed = seed_value + 13579

func _setup_audio_player() -> void:
    _audio_player = AudioStreamPlayer3D.new()
    _audio_player.name = "NoisePreviewPlayer3D"
    _audio_player.unit_size = 2.5
    _audio_player.max_distance = 24.0
    _audio_player.position = Vector3(0, 1.0, 0)
    add_child(_audio_player)

    _audio_generator = AudioStreamGenerator.new()
    _audio_generator.mix_rate = audio_mix_rate
    _audio_generator.buffer_length = audio_buffer_length
    _audio_player.stream = _audio_generator

func _create_vr_controls() -> void:
    var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
    _rack_panel = RackTpl.create_panel("WHITE NOISE", [
        [
            {"type": "button", "label": "WHITE"},
            {"type": "button", "label": "PINK"},
            {"type": "button", "label": "BROWN"},
        ],
        [
            {"type": "button", "label": "BLUE"},
            {"type": "button", "label": "VIOLET"},
            {"type": "button", "label": "STOP"},
        ],
    ])
    _rack_panel.position = Vector3(0, 0.2, grid_size.y * spacing * 0.5 + 1.2)
    _rack_panel.rotation_degrees = Vector3(-25, 0, 0)
    add_child(_rack_panel)
    _control_panel = _rack_panel

    # Connect noise type buttons
    var noise_types = [NoiseType.WHITE, NoiseType.PINK, NoiseType.BROWN, NoiseType.BLUE, NoiseType.VIOLET]
    for i in range(noise_types.size()):
        var btn = _rack_panel.find_child("Btn_%d" % i, true, false)
        if btn:
            var selected_type: NoiseType = noise_types[i]
            var area = btn.get_node_or_null("InteractableAreaButton")
            if area:
                area.button_pressed.connect(func(_b): _play_noise_preview(selected_type))

    # Stop button (Btn_5)
    var stop_btn = _rack_panel.find_child("Btn_5", true, false)
    if stop_btn:
        var stop_area = stop_btn.get_node_or_null("InteractableAreaButton")
        if stop_area:
            stop_area.button_pressed.connect(func(_b): _stop_audio_preview())

    # Status label below the panel
    _status_label = Label3D.new()
    _status_label.text = "Audio: stopped"
    _status_label.pixel_size = 0.001
    _status_label.font_size = 7
    _status_label.modulate = Color(0.82, 0.86, 0.94)
    _status_label.position = Vector3(0, -0.12, 0.01)
    _rack_panel.add_child(_status_label)

func _play_noise_preview(type: NoiseType) -> void:
    if not _audio_player:
        return
    _current_audio_noise = type
    _reset_audio_filter_state()
    _audio_playing = true
    if not _audio_player.playing:
        _audio_player.play()
    _audio_stream = _audio_player.get_stream_playback()
    _update_status_label()

func _stop_audio_preview(_button = null) -> void:
    _audio_playing = false
    if _audio_player and _audio_player.playing:
        _audio_player.stop()
    _audio_stream = null
    _update_status_label("Audio: stopped")

func _fill_audio_buffer() -> void:
    if not _audio_playing or not _audio_player:
        return

    if _audio_stream == null:
        _audio_stream = _audio_player.get_stream_playback()
        if _audio_stream == null:
            return

    var frames_available = _audio_stream.get_frames_available()
    for i in range(frames_available):
        var sample = _generate_noise_sample(_current_audio_noise)
        _audio_stream.push_frame(Vector2(sample, sample))

func _generate_noise_sample(type: NoiseType) -> float:
    var white = _audio_rng.randf_range(-1.0, 1.0)
    var value = white

    match type:
        NoiseType.WHITE:
            value = white

        NoiseType.PINK:
            # Paul Kellet style filter approximation for 1/f spectrum.
            _pink_b0 = 0.99886 * _pink_b0 + white * 0.0555179
            _pink_b1 = 0.99332 * _pink_b1 + white * 0.0750759
            _pink_b2 = 0.96900 * _pink_b2 + white * 0.1538520
            _pink_b3 = 0.86650 * _pink_b3 + white * 0.3104856
            _pink_b4 = 0.55000 * _pink_b4 + white * 0.5329522
            _pink_b5 = -0.7616 * _pink_b5 - white * 0.0168980
            value = (_pink_b0 + _pink_b1 + _pink_b2 + _pink_b3 + _pink_b4 + _pink_b5 + _pink_b6 + white * 0.5362) * 0.11
            _pink_b6 = white * 0.115926

        NoiseType.BROWN:
            _brown_state = clampf(_brown_state + white * 0.02, -1.0, 1.0)
            value = _brown_state * 3.5

        NoiseType.BLUE:
            _blue_lowpass = lerpf(_blue_lowpass, white, 0.03)
            value = (white - _blue_lowpass) * 2.0

        NoiseType.VIOLET:
            value = (white - _previous_white) * 0.9
            _previous_white = white

    return clampf(value * audio_gain, -0.95, 0.95)

func _reset_audio_filter_state() -> void:
    _pink_b0 = 0.0
    _pink_b1 = 0.0
    _pink_b2 = 0.0
    _pink_b3 = 0.0
    _pink_b4 = 0.0
    _pink_b5 = 0.0
    _pink_b6 = 0.0
    _brown_state = 0.0
    _blue_lowpass = 0.0
    _previous_white = 0.0

func _noise_type_name(type: NoiseType) -> String:
    match type:
        NoiseType.WHITE:
            return "WHITE"
        NoiseType.PINK:
            return "PINK"
        NoiseType.BROWN:
            return "BROWN"
        NoiseType.BLUE:
            return "BLUE"
        NoiseType.VIOLET:
            return "VIOLET"
    return "WHITE"

func _update_status_label(forced_text: String = "") -> void:
    if not _status_label:
        return
    if forced_text != "":
        _status_label.text = forced_text
    elif _audio_playing:
        _status_label.text = "Audio: %s playing" % _noise_type_name(_current_audio_noise)
    else:
        _status_label.text = "Audio: stopped"

func _notification(what: int) -> void:
    if what == NOTIFICATION_EXIT_TREE:
        _stop_audio_preview()

func _exit_tree() -> void:
    for child in get_children():
        if not child.owner:
            child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
    pass
