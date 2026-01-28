# SubtitleTrigger - Shows Portal 2-style subtitle when player enters
# Use in grid: sub:map, sub:welcome, sub:Welcome_to_the_lab, sub:tt:point_axioms
#
# Parameters:
#   sub:map              - Shows blurb.md or JSON description
#   sub:intro            - Looks up "intro" in map_data.json "subtitles" section
#   sub:Welcome_text     - Direct text (underscores become spaces) if not found in subtitles
#   sub:tt:key           - Looks up key in tutorial_text.json
#   sub:key:speaker      - Text with custom speaker name
#   sub:key:speaker:1    - Text + speaker + level (1=essential, 2=info, 3=verbose)
#
# Map-specific subtitles in map_data.json:
#   "subtitles": {
#     "intro": "Welcome to this map!",
#     "hint1": {"text": "Try jumping here", "speaker": "Guide"}
#   }

extends Area3D

signal subtitle_shown(text: String)

@export var subtitle_key: String = "map"  # What subtitle to show
@export var speaker_name: String = ""      # Optional speaker override
@export var duration: float = 8.0          # How long to show
@export var text_level: int = 2            # 1=essential, 2=info, 3=verbose
@export var one_shot: bool = true          # Only trigger once
@export var show_visual: bool = false      # Show trigger area (debug)
@export var show_info_sphere: bool = true  # Show info sphere indicator

@export_group("Visual")
@export var trigger_color: Color = Color(0.4, 0.8, 1.0, 0.2)
@export var trigger_size: Vector3 = Vector3(1.2, 1.2, 1.2)  # Small box - must walk over it (like pickup cube)
@export var sphere_color: Color = Color(0.3, 0.7, 1.0, 0.15)  # Very transparent cyan
@export var sphere_radius: float = 0.15  # Slightly smaller sphere

var _has_triggered: bool = false
var _startup_complete: bool = false  # Prevent triggering during scene load
var _mesh_instance: MeshInstance3D
var _audio_player: AudioStreamPlayer
var _info_sphere: MeshInstance3D
var _info_text: Label3D

func _ready():
	# Setup notification sound
	_setup_audio()
	# Setup collision - match pick_up_cube's collision settings
	collision_layer = 0
	collision_mask = 524288  # Layer 20 - player body (same as pick_up_cube)

	# Create collision shape if not exists
	if not has_node("CollisionShape3D"):
		var collision = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = trigger_size
		collision.shape = box
		# Position collision at player body height (torso level)
		# Adjust to match player center of mass around 0.9-1.0m
		collision.position.y = 1.0
		add_child(collision)

	# Create visual indicator (for debug)
	if show_visual:
		_create_visual()

	# Create info sphere indicator
	if show_info_sphere:
		_create_info_sphere()

	# Connect signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Delay activation to prevent triggering during scene load/player spawn
	_startup_complete = false
	get_tree().create_timer(1.5).timeout.connect(_on_startup_complete)

	print("SubtitleTrigger: Ready - key='%s', speaker='%s' (will activate in 1.5s)" % [subtitle_key, speaker_name])

func _on_startup_complete():
	_startup_complete = true
	print("SubtitleTrigger: Now active - key='%s'" % subtitle_key)

func _setup_audio():
	# Create AudioStreamPlayer for notification sound (2D - not positional)
	_audio_player = AudioStreamPlayer.new()
	_audio_player.volume_db = -8.0  # Soft notification
	_audio_player.stream = _generate_pling_sound()
	add_child(_audio_player)

func _generate_pling_sound() -> AudioStreamWAV:
	"""Generate a soft bell/pling notification sound"""
	const SAMPLE_RATE = 44100
	const DURATION = 0.3  # Short notification sound

	var sample_count = int(SAMPLE_RATE * DURATION)
	var data = PackedByteArray()

	# Bell-like frequencies (fundamental + harmonics)
	var freq1 = 880.0   # A5 - main tone
	var freq2 = 1320.0  # E6 - fifth harmonic
	var freq3 = 1760.0  # A6 - octave

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count

		# Quick attack, smooth exponential decay (bell envelope)
		var attack = min(1.0, t * 50.0)  # 20ms attack
		var decay = exp(-progress * 8.0)  # Exponential decay
		var envelope = attack * decay

		# Mix sine waves for bell-like timbre
		var sample = sin(2.0 * PI * freq1 * t) * 0.5
		sample += sin(2.0 * PI * freq2 * t) * 0.3
		sample += sin(2.0 * PI * freq3 * t) * 0.2

		# Apply envelope and convert to 16-bit
		sample = sample * envelope * 0.8
		var sample_int = int(clamp(sample * 32767.0, -32768.0, 32767.0))

		# Little-endian 16-bit
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)

	var audio_stream = AudioStreamWAV.new()
	audio_stream.format = AudioStreamWAV.FORMAT_16_BITS
	audio_stream.mix_rate = SAMPLE_RATE
	audio_stream.stereo = false
	audio_stream.data = data

	return audio_stream

func _play_notification_sound():
	if _audio_player and _audio_player.stream:
		_audio_player.play()

func _create_visual():
	_mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = trigger_size
	_mesh_instance.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = trigger_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh_instance.material_override = mat

	add_child(_mesh_instance)

func _create_info_sphere():
	# Create transparent sphere
	_info_sphere = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = sphere_radius
	sphere.height = sphere_radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	_info_sphere.mesh = sphere

	# Very transparent material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = sphere_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_info_sphere.material_override = mat

	# Position sphere at eye level (slightly above center)
	_info_sphere.position.y = 0.5
	add_child(_info_sphere)

	# Create "i" text inside sphere
	_info_text = Label3D.new()
	_info_text.text = "i"
	_info_text.font_size = 32
	_info_text.pixel_size = 0.003
	_info_text.modulate = Color(0.4, 0.85, 1.0, 0.8)  # Cyan-ish, slightly transparent
	_info_text.outline_modulate = Color(0.1, 0.3, 0.5, 0.5)
	_info_text.outline_size = 4
	_info_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # Always face player
	_info_text.no_depth_test = true  # Visible through sphere
	_info_text.position.y = 0.5  # Same height as sphere
	add_child(_info_text)

func _on_body_entered(body: Node3D):
	if not _startup_complete:
		return  # Ignore during scene initialization
	if one_shot and _has_triggered:
		return

	if not _is_player(body):
		return

	# Distance check - player must be within 0.75m of trigger (not just collision overlap)
	var trigger_pos = global_position + Vector3(0, 0.5, 0)  # Collision center
	var player_pos = body.global_position
	var distance = Vector2(trigger_pos.x, trigger_pos.z).distance_to(Vector2(player_pos.x, player_pos.z))
	if distance > 0.75:
		return  # Too far, ignore

	_show_subtitle()

func _on_area_entered(area: Area3D):
	if not _startup_complete:
		return  # Ignore during scene initialization
	if one_shot and _has_triggered:
		return

	# Check if area belongs to player (hands, etc.)
	if area.name.contains("Hand") or area.name.contains("Player"):
		_show_subtitle()

func _is_player(body: Node3D) -> bool:
	if body.is_in_group("player"):
		return true
	if body.is_in_group("player_body"):
		return true
	if body.name.contains("Player") or body.name.contains("XR"):
		return true
	return false

func _show_subtitle():
	print("SubtitleTrigger._show_subtitle() called - subtitle_key='%s'" % subtitle_key)
	_has_triggered = true

	# Get subtitle text based on key
	var text = _resolve_subtitle_text()
	var speaker = _resolve_speaker()
	print("SubtitleTrigger: text='%s' (len=%d), speaker='%s'" % [text.substr(0, 50) if not text.is_empty() else "(empty)", text.length(), speaker])

	if text.is_empty():
		print("SubtitleTrigger: No text for key '%s'" % subtitle_key)
		return

	# Use Subtitles autoload
	var subtitles = get_node_or_null("/root/Subtitles")
	if subtitles:
		subtitles.show(text, speaker, duration, text_level)
		_play_notification_sound()  # Play pling sound
		print("SubtitleTrigger: Showing subtitle - speaker='%s', level=%d" % [speaker, text_level])
	else:
		push_warning("SubtitleTrigger: Subtitles autoload not found!")

	subtitle_shown.emit(text)

	# Hide visuals after trigger
	if show_visual and _mesh_instance:
		_mesh_instance.visible = false
	if show_info_sphere:
		if _info_sphere:
			_info_sphere.visible = false
		if _info_text:
			_info_text.visible = false

func _resolve_subtitle_text() -> String:
	var key = subtitle_key.strip_edges()

	# Check for map description
	if key == "map":
		return _get_map_description()

	# Check for tutorial text reference (tt:key)
	if key.begins_with("tt:"):
		var tt_key = key.substr(3)
		return _get_tutorial_text(tt_key)

	# Check map's own subtitles section first (sub:keyname)
	var map_text = _get_map_subtitle_text(key)
	if not map_text.is_empty():
		return map_text

	# Direct text - convert underscores to spaces
	return key.replace("_", " ")

func _get_map_subtitle_text(key: String) -> String:
	"""Look up subtitle text from map_data.json 'subtitles' section"""
	var grid_system = _find_grid_system()
	if not grid_system:
		return ""

	var data_component = grid_system.get_data_component() if grid_system.has_method("get_data_component") else null
	if not data_component:
		return ""

	# Try to get subtitles from map data via json_loader
	if "json_loader" in data_component and data_component.json_loader:
		var map_data = data_component.json_loader.map_data
		if map_data and map_data.has("subtitles"):
			var subtitles = map_data["subtitles"]
			if subtitles.has(key):
				var entry = subtitles[key]
				# Support both string and dict format
				if entry is String:
					return entry
				elif entry is Dictionary and entry.has("text"):
					return entry["text"]
				elif entry is Dictionary and entry.has("content"):
					return entry["content"]

	return ""

func _resolve_speaker() -> String:
	# Use explicit speaker if set
	if not speaker_name.is_empty():
		return speaker_name

	# Default speaker based on context
	if subtitle_key == "map":
		return _get_map_name()

	# Check if map subtitles has a speaker for this key
	var map_speaker = _get_map_subtitle_speaker(subtitle_key)
	if not map_speaker.is_empty():
		return map_speaker

	return ""

func _get_map_subtitle_speaker(key: String) -> String:
	"""Get speaker from map_data.json subtitles entry if it's a dictionary"""
	var grid_system = _find_grid_system()
	if not grid_system:
		return ""

	var data_component = grid_system.get_data_component() if grid_system.has_method("get_data_component") else null
	if not data_component:
		return ""

	if "json_loader" in data_component and data_component.json_loader:
		var map_data = data_component.json_loader.map_data
		if map_data and map_data.has("subtitles"):
			var subtitles = map_data["subtitles"]
			if subtitles.has(key):
				var entry = subtitles[key]
				if entry is Dictionary and entry.has("speaker"):
					return entry["speaker"]

	return ""

func _get_map_description() -> String:
	# Try to find GridSystem to get map info
	var grid_system = _find_grid_system()
	print("SubtitleTrigger: _get_map_description - grid_system=%s" % (grid_system.name if grid_system else "null"))

	if grid_system:
		var data_component = grid_system.get_data_component() if grid_system.has_method("get_data_component") else null
		print("SubtitleTrigger: data_component=%s" % (data_component != null))

		if data_component:
			# Get folder name for blurb.md lookup (not display name)
			var folder_name = ""
			if data_component.has_method("get_current_map_name"):
				folder_name = data_component.get_current_map_name()
			print("SubtitleTrigger: folder_name='%s'" % folder_name)

			# Try blurb.md first (like AnnotationInfoBoard)
			if not folder_name.is_empty():
				var blurb_path = "res://commons/maps/%s/blurb.md" % folder_name
				var file_exists = FileAccess.file_exists(blurb_path)
				print("SubtitleTrigger: blurb_path='%s', exists=%s" % [blurb_path, file_exists])

				if file_exists:
					var file = FileAccess.open(blurb_path, FileAccess.READ)
					if file:
						var content = file.get_as_text().strip_edges()
						file.close()
						if not content.is_empty():
							print("SubtitleTrigger: Loaded blurb.md content (length=%d)" % content.length())
							return content

			# Fallback to JSON description
			if data_component.has_method("get_description"):
				var desc = data_component.get_description()
				print("SubtitleTrigger: Fallback to JSON description: '%s'" % desc.substr(0, 50))
				return desc
	else:
		print("SubtitleTrigger: ERROR - No GridSystem found!")

	return ""

func _get_map_name() -> String:
	var grid_system = _find_grid_system()
	if grid_system:
		var data_component = grid_system.get_data_component()
		if data_component and data_component.has_method("get_map_name"):
			var name = data_component.get_map_name()
			return name.replace("_", " ")

	return ""

func _find_grid_system() -> Node:
	# Search up the tree for GridSystem
	var current = get_parent()
	while current:
		if current.name == "GridSystem" or current.has_method("get_data_component"):
			return current
		var grid = current.get_node_or_null("GridSystem")
		if grid:
			return grid
		current = current.get_parent()

	# Search from root
	var root = get_tree().current_scene
	if root:
		var grid = root.find_child("GridSystem", true, false)
		if grid:
			return grid

	return null

func _get_tutorial_text(key: String) -> String:
	# Try to load from TutorialTextLibrary if available
	if ClassDB.class_exists("TutorialTextLibrary"):
		var lib = load("res://commons/context/clipboard/tutorial_text_library.gd")
		if lib:
			var instance = lib.new()
			if instance.has_method("get_text"):
				return instance.get_text(key)

	# Fallback: try to load JSON directly
	var json_path = "res://commons/context/clipboard/tutorial_text.json"
	if FileAccess.file_exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var data = json.data
				if data.has(key):
					var entry = data[key]
					if entry.has("content"):
						return entry["content"]

	return key.replace("_", " ")

# Called by GridUtilitiesComponent to configure from parameters
func configure(params: Array):
	if params.size() > 0:
		subtitle_key = params[0]

	if params.size() > 1:
		speaker_name = params[1]

	if params.size() > 2:
		# Check if it's a number (level) or duration
		var param2 = params[2]
		if param2 in ["1", "2", "3"]:
			text_level = int(param2)
		else:
			duration = float(param2)

	if params.size() > 3:
		# Fourth param is always duration if present
		duration = float(params[3])

	print("SubtitleTrigger: Configured - key='%s', speaker='%s', level=%d, duration=%s" % [subtitle_key, speaker_name, text_level, duration])

# Reset trigger (for testing)
func reset_trigger():
	_has_triggered = false
	if _mesh_instance:
		_mesh_instance.visible = show_visual
	if _info_sphere:
		_info_sphere.visible = show_info_sphere
	if _info_text:
		_info_text.visible = show_info_sphere
