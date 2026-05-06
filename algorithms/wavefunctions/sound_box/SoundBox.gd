extends Node3D

@export_file("*.json") var collection_path: String = "res://commons/audio/collections/synthetic_suite.json"
@export var button_scene: PackedScene = preload("res://algorithms/wavefunctions/sound_box/SoundTriggerButton.tscn")
@export var spacing: float = 0.5

@onready var grid_container = $GridContainer
@onready var title_label: Label3D = $TitleLabel

var _active_players: Array[AudioStreamPlayer3D] = []

func _ready() -> void:
	if collection_path:
		load_collection(collection_path)

# Integration with the Map JSON system (e.g., soundboxes#collections:synthetic)
func configure(data: Dictionary) -> void:
	print("SoundBox: Configuring from Grid JSON: ", data)
	
	# Handle "collections" shorthand (matches user request)
	if data.has("collections"):
		var coll = str(data["collections"]).to_lower()
		var path = ""
		match coll:
			"synthetic": path = "res://commons/audio/collections/synthetic_suite.json"
			"retro", "fx": path = "res://commons/audio/collections/audio_synthesizer.json"
			"sci_fi", "lab": path = "res://commons/audio/collections/sci_fi_lab.json"
			"legends": path = "res://commons/audio/collections/synth_legends.json"
			"drums", "dnb": path = "res://commons/audio/collections/drum_and_bass.json"
			"body": path = "res://commons/audio/collections/body_sounds.json"
			"machine", "tech": path = "res://commons/audio/collections/machine_sounds.json"
			"synth", "chips": path = "res://commons/audio/collections/synth_history.json"
			"sacred", "church": path = "res://commons/audio/collections/sacred_sounds.json"
			"noir", "blade": path = "res://commons/audio/collections/metropolis_noir.json"
			"weather", "city": path = "res://commons/audio/collections/weather_and_urban.json"
			"game": path = "res://commons/audio/collections/game_world.json"
			_:
				# Try direct path if it looks like one
				if coll.begins_with("res://"):
					path = coll
				# Try to find it in collections folder directly
				elif FileAccess.file_exists("res://commons/audio/collections/" + coll + ".json"):
					path = "res://commons/audio/collections/" + coll + ".json"
				else:
					print("SoundBox: Unknown collection shorthand: ", coll)
		
		if not path.is_empty():
			load_collection(path)
			
	# Handle direct property overrides
	if data.has("collection_path"):
		load_collection(str(data["collection_path"]))
	
	if data.has("spacing"):
		spacing = float(data["spacing"])
		if collection_path:
			load_collection(collection_path) # Reload to apply spacing
			
	# Handle advanced spatial configuration
	if data.has("translation") or data.has("position"):
		var val = data.get("translation", data.get("position"))
		position += _parse_vector3(val)
		
	if data.has("rotation") or data.has("rotation_degrees"):
		var val = data.get("rotation", data.get("rotation_degrees"))
		rotation_degrees += _parse_vector3(val)
		
	if data.has("scale"):
		var val = data["scale"]
		scale *= _parse_vector3(val, Vector3.ONE)

func _parse_vector3(val: Variant, default: Vector3 = Vector3.ZERO) -> Vector3:
	if val is Vector3:
		return val
	if val is String:
		var parts = val.split(",")
		if parts.size() >= 3:
			return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
		elif parts.size() == 1 and parts[0].is_valid_float():
			var f = float(parts[0])
			return Vector3(f, f, f) # Uniform scale/offset if single value
	return default

func load_collection(path: String) -> void:
	collection_path = path
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("SoundBox: Could not open collection file: ", path)
		return
		
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		print("SoundBox: JSON parse error in collection: ", path)
		return
		
	var data = json.data
	_populate_grid(data)

func _populate_grid(data: Dictionary) -> void:
	# Clear existing buttons
	for child in grid_container.get_children():
		child.queue_free()
		
	if title_label:
		title_label.text = data.get("collection_name", "Sound Box")
		
	# Since GridContainer in 3D is usually a custom node (like the one in XRTools)
	# or just a Node3D with manual positioning, let's assume manual positioning 
	# if it's not a native UI GridContainer (which it won't be in 3D space usually).
	# However, looking at the previous code, it just connected signals.
	# I'll implement manual 3D grid layout on the Node3D for the buttons.
	
	var index = 0
	var items = data.get("items", data.get("sounds", []))
	var cols = data.get("layout_columns", 3)
	
	for item in items:
		var btn = button_scene.instantiate()
		grid_container.add_child(btn)
		
		# Position in 3D grid
		var row = floor(index / int(cols))
		var col = index % int(cols)
		btn.position = Vector3(col * spacing, -row * spacing, 0)
		
		# Setup button
		var sound_id = item.get("id", item.get("sound_id", "UNKNOWN"))
		var label = item.get("label", sound_id.split(":")[-1]) # Use ID as label if missing
		var color_raw = item.get("color", [0.5, 0.5, 0.5])
		var color = Color(color_raw[0], color_raw[1], color_raw[2]) if color_raw is Array else Color(color_raw)
		
		if btn.has_method("setup"):
			btn.setup(sound_id, label, color)
		
		# Connect signal
		if btn.has_signal("triggered"):
			btn.triggered.connect(_on_button_triggered)
			
		index += 1

func _on_button_triggered(sound_id: String) -> void:
	if sound_id == "STOP_ALL":
		_stop_all_sounds()
		return
		
	print("SoundBox: Triggering ", sound_id)
	if has_node("/root/SoundBank"):
		var sound_bank = get_node("/root/SoundBank")
		if sound_bank.has_method("get_sound"):
			var stream = sound_bank.get_sound(sound_id)
			if stream:
				_play_sound(stream)

func _play_sound(stream: AudioStream) -> void:
	var player = AudioStreamPlayer3D.new()
	add_child(player)
	player.stream = stream
	player.unit_size = 10.0
	player.max_db = 0.0
	
	_active_players.append(player)
	player.finished.connect(func(): _on_player_finished(player))
	player.play()

func _on_player_finished(player: AudioStreamPlayer3D) -> void:
	if player in _active_players:
		_active_players.erase(player)
	player.queue_free()

func _stop_all_sounds() -> void:
	print("SoundBox: Stopping all sounds")
	for player in _active_players:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_active_players.clear()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
