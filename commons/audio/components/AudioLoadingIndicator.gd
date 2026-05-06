# AudioLoadingIndicator.gd
# Shows a 3D loading label when audio is being generated
# Automatically connects to SciFiLoFiSoundscape signals

extends Node3D
class_name AudioLoadingIndicator

@export var label_offset: Vector3 = Vector3(0, 1.5, -2)  # Position relative to camera
@export var label_font_size: int = 32
@export var show_progress: bool = true

var loading_label: Label3D
var is_loading: bool = false
var current_progress: float = 0.0
var current_layer: String = ""

func _ready():
	# Create the 3D label
	_create_loading_label()
	
	# Try to find and connect to soundscape generators
	call_deferred("_connect_to_generators")

func _create_loading_label():
	loading_label = Label3D.new()
	loading_label.name = "LoadingLabel"
	loading_label.text = "Loading Audio..."
	loading_label.font_size = label_font_size
	loading_label.outline_size = 4
	loading_label.modulate = Color(1, 1, 1, 0.9)
	loading_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	loading_label.no_depth_test = true
	loading_label.render_priority = 100
	loading_label.visible = false
	
	add_child(loading_label)
	print("AudioLoadingIndicator: Created loading label")

func _connect_to_generators():
	# Find any SciFiLoFiSoundscape in the scene tree
	var soundscapes = _find_all_soundscapes(get_tree().root)
	
	for soundscape in soundscapes:
		_connect_to_soundscape(soundscape)
	
	# Also connect to SoundBank if it has generation signals
	var sound_bank = get_node_or_null("/root/SoundBank")
	if sound_bank:
		if sound_bank.has_signal("generation_started"):
			sound_bank.generation_started.connect(_on_generation_started)
		if sound_bank.has_signal("generation_complete"):
			sound_bank.generation_complete.connect(_on_generation_complete)
	
	print("AudioLoadingIndicator: Connected to %d soundscape(s)" % soundscapes.size())

func _find_all_soundscapes(node: Node) -> Array:
	var result = []
	
	if node is SciFiLoFiSoundscape:
		result.append(node)
	
	for child in node.get_children():
		result.append_array(_find_all_soundscapes(child))
	
	return result

func _connect_to_soundscape(soundscape: SciFiLoFiSoundscape):
	if not soundscape.generation_started.is_connected(_on_generation_started):
		soundscape.generation_started.connect(_on_generation_started)
	if not soundscape.generation_progress.is_connected(_on_generation_progress):
		soundscape.generation_progress.connect(_on_generation_progress)
	if not soundscape.generation_complete.is_connected(_on_generation_complete):
		soundscape.generation_complete.connect(_on_generation_complete)
	
	print("AudioLoadingIndicator: Connected to soundscape: %s" % soundscape.name)

func _on_generation_started():
	is_loading = true
	current_progress = 0.0
	current_layer = ""
	_update_label()
	loading_label.visible = true
	print("AudioLoadingIndicator: Audio generation started")

func _on_generation_progress(progress: float, layer_name: String):
	current_progress = progress
	current_layer = layer_name
	_update_label()

func _on_generation_complete():
	is_loading = false
	loading_label.visible = false
	print("AudioLoadingIndicator: Audio generation complete")

func _update_label():
	if not loading_label:
		return
	
	if show_progress and current_progress > 0:
		var percent = int(current_progress * 100)
		if not current_layer.is_empty():
			loading_label.text = "Loading Audio: %s\n%d%%" % [current_layer, percent]
		else:
			loading_label.text = "Loading Audio... %d%%" % percent
	else:
		loading_label.text = "Loading Audio..."

func _process(_delta):
	# Position label in front of camera
	if loading_label and loading_label.visible:
		var camera = get_viewport().get_camera_3d()
		if camera:
			loading_label.global_position = camera.global_position + camera.global_transform.basis * label_offset

# Manual control methods
func show_loading(message: String = "Loading Audio..."):
	is_loading = true
	loading_label.text = message
	loading_label.visible = true

func hide_loading():
	is_loading = false
	loading_label.visible = false

func update_loading(message: String, progress: float = -1.0):
	if progress >= 0:
		loading_label.text = "%s\n%d%%" % [message, int(progress * 100)]
	else:
		loading_label.text = message
