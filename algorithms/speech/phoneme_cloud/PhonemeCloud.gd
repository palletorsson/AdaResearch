extends Node3D
class_name PhonemeCloud

# Phoneme Cloud Prototype
# Speech emerges as movement through a continuous phonetic space.

@export var influence_radius := 1.5
@export var fade_curve := 2.0
@export var base_volume_db := -6.0

@onready var cursor = $Cursor

# Define the phoneme manifold (positions are conceptual, not literal IPA)
var phonemes := {
	"a": { "pos": Vector3( 0.8,  0.2,  0.0), "player": null },
	"i": { "pos": Vector3( 0.1,  0.9,  0.0), "player": null },
	"u": { "pos": Vector3( 0.1,  0.1,  0.0), "player": null },
	"s": { "pos": Vector3( 0.6,  0.6,  0.0), "player": null },
	"t": { "pos": Vector3( 0.5,  0.5,  0.0), "player": null }
}

var _is_xr_active = false
var _right_controller_path = "/root/Main/XROrigin3D/RightHand" # Adjust based on actual scene structure

func _ready():
	_check_xr()
	_initialize_players()
	_start_all()
	
	# Setup Cursor visual if using GrabSphere
	if cursor and cursor.has_method("set_mode"):
		# If it's the grab sphere, we might want to set a visual mode
		pass

func _check_xr():
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		_is_xr_active = true
	
	# Try to find controller if in a standard XR scene
	# This might need to be assigned externally or found via groups in a real integration

func _process(delta):
	_update_cursor()
	_update_phoneme_weights()

# --------------------------------------------------

func _initialize_players():
	# Generate streams first
	print("PhonemeCloud: Synthesizing phonemes...")
	
	for key in phonemes.keys():
		var node_name: String = key.to_upper()
		var p
		
		# Allow for procedural creation if nodes don't exist
		if $Phonemes.has_node(node_name):
			p = $Phonemes.get_node(node_name)
		else:
			p = AudioStreamPlayer3D.new()
			p.name = node_name
			$Phonemes.add_child(p)
			# Position 3D sound at conceptual location (flat Z for now, but in vector space)
			# Mapping normalized 2D coordinates to 3D world space (e.g. 2x2m area)
			var data = phonemes[key]
			p.position = (data.pos - Vector3(0.5, 0.5, 0)) * 2.0 
			
		phonemes[key].player = p
		
		# Assign generated stream
		p.stream = PhonemeGenerator.generate_phoneme_stream(key)
		p.volume_db = -80.0
		p.pitch_scale = 1.0
		p.unit_size = 2.0 # Spatial blend size
		p.max_distance = 10.0

func _start_all():
	for data in phonemes.values():
		if data.player:
			data.player.play()

# --------------------------------------------------

func _update_cursor():
	if _is_xr_active:
		# TODO: Implement XR hand tracking logic
		pass
		
	# MOUSE INPUT (Debug - Only if no XR)
	if not _is_xr_active:
		var m: Vector2 = get_viewport().get_mouse_position()
		var viewport_rect: Rect2 = get_viewport().get_visible_rect()
		var size: Vector2 = viewport_rect.size

		var x: float = clampf(m.x / size.x, 0.0, 1.0)
		var y: float = clampf(m.y / size.y, 0.0, 1.0)
		
		# Map 0..1 to -1..1 world space
		var world_x = (x - 0.5) * 2.0
		var world_y = (1.0 - y - 0.5) * 2.0 # Inverted Y for screen to world
		
		# Only update if using mouse to debug, otherwise let physics/grab handle it
		cursor.position = Vector3(world_x, world_y, 0.0)

func _update_phoneme_weights():
	# Logic space cursor (0..1)
	var logic_cursor = (cursor.position / 2.0) + Vector3(0.5, 0.5, 0.0)
	
	for data in phonemes.values():
		# Calculate distance in LOGIC space (normalized 0-1) 
		# OR World space? Let's stick to Logic space as defined in the prototype script
		
		var d = logic_cursor.distance_to(data.pos)
		var w = _falloff(d)

		data.player.volume_db = lerp(-80.0, base_volume_db, w)
		data.player.pitch_scale = lerp(0.95, 1.05, w)

func _falloff(distance: float) -> float:
	if distance > influence_radius:
		return 0.0

	var n := 1.0 - (distance / influence_radius)
	return pow(n, fade_curve)
