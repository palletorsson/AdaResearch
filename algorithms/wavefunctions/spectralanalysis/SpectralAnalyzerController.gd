# SpectralAnalyzerController.gd - Interactive spectral analyzer for grid system
extends Node3D
class_name SpectralAnalyzerController

@export var activation_distance: float = 3.0
@export var auto_activate: bool = true
@export var display_enabled: bool = true

# Node references
var game_sound_meter: GameSoundMeter
var spectral_meter: SpectralMeter
var interaction_area: Area3D
var display_viewport: SubViewport
var label_3d: Label3D
var display_material: MeshInstance3D

# State
var is_active: bool = false
var player_in_range: bool = false
var current_audio_target: AudioStreamPlayer3D

signal analyzer_activated
signal analyzer_deactivated

func _ready():
	_setup_references()
	_setup_interaction()
	_setup_display()
	
	if auto_activate:
		activate_analyzer()

func _setup_references():
	"""Get references to child nodes"""
	game_sound_meter = $AudioDisplay/GameSoundMeter
	spectral_meter = $AudioDisplay/SpectralDisplay
	interaction_area = $InteractionArea
	display_viewport = $AudioDisplay
	label_3d = $Label3D
	display_material = $DisplayMaterial
	
	if not game_sound_meter:
		print("SpectralAnalyzerController: Warning - GameSoundMeter not found")
	if not spectral_meter:
		print("SpectralAnalyzerController: Warning - SpectralMeter not found")

func _setup_interaction():
	"""Setup interaction area for player detection"""
	if interaction_area:
		# Create collision shape if it doesn't exist
		var collision_shape = interaction_area.get_child(0) as CollisionShape3D
		if collision_shape and not collision_shape.shape:
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(4, 4, 4)  # Large interaction area
			collision_shape.shape = box_shape
		
		# Connect signals
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

func _setup_display():
	"""Setup the display material and viewport"""
	if display_viewport and display_material:
		# Create a material that shows the viewport texture
		var material = StandardMaterial3D.new()
		material.albedo_texture = display_viewport.get_texture()
		material.emission_enabled = true
		material.emission_texture = display_viewport.get_texture()
		material.emission_energy = 0.8
		material.unshaded = true
		
		display_material.material_override = material

func _process(delta: float):
	"""Main update loop"""
	if is_active and display_enabled:
		_update_audio_detection()
		_update_display_visibility()

func _update_audio_detection():
	"""Automatically detect and connect to nearby audio sources"""
	if not current_audio_target:
		var audio_players = get_tree().get_nodes_in_group("audio_sources")
		if audio_players.is_empty():
			# Look for any AudioStreamPlayer3D in the scene
			audio_players = []
			_find_audio_players_recursive(get_tree().current_scene, audio_players)
		
		if not audio_players.is_empty():
			var closest_player = _find_closest_audio_player(audio_players)
			if closest_player:
				set_audio_target(closest_player)

func _find_audio_players_recursive(node: Node, players: Array):
	"""Recursively find all AudioStreamPlayer3D nodes"""
	if node is AudioStreamPlayer3D and node.stream:
		players.append(node)
	
	for child in node.get_children():
		_find_audio_players_recursive(child, players)

func _find_closest_audio_player(players: Array) -> AudioStreamPlayer3D:
	"""Find the closest audio player to this analyzer"""
	var closest_player: AudioStreamPlayer3D = null
	var closest_distance: float = INF
	
	for player in players:
		if player is AudioStreamPlayer3D:
			var distance = global_position.distance_to(player.global_position)
			if distance < closest_distance and distance < 20.0:  # Within 20 units
				closest_distance = distance
				closest_player = player
	
	return closest_player

func _update_display_visibility():
	"""Update display based on player proximity"""
	var should_show = player_in_range or auto_activate
	
	if game_sound_meter:
		game_sound_meter.enabled = should_show
	if spectral_meter:
		spectral_meter.enabled = should_show
	
	# Update label transparency
	if label_3d:
		var alpha = 1.0 if should_show else 0.3
		label_3d.modulate = Color(1, 1, 1, alpha)

func _on_body_entered(body: Node3D):
	"""Player entered interaction area"""
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		player_in_range = true
		if not is_active:
			activate_analyzer()

func _on_body_exited(body: Node3D):
	"""Player left interaction area"""
	if body.is_in_group("player") or body.name.to_lower().contains("player"):
		player_in_range = false

# Public API
func activate_analyzer():
	"""Activate the spectral analyzer"""
	if is_active:
		return
	
	is_active = true
	
	if game_sound_meter:
		game_sound_meter.enabled = true
	if spectral_meter:
		spectral_meter.enabled = true
	
	analyzer_activated.emit()
	print("SpectralAnalyzer: Activated")

func deactivate_analyzer():
	"""Deactivate the spectral analyzer"""
	if not is_active:
		return
	
	is_active = false
	
	if game_sound_meter:
		game_sound_meter.enabled = false
	if spectral_meter:
		spectral_meter.enabled = false
	
	analyzer_deactivated.emit()
	print("SpectralAnalyzer: Deactivated")

func set_audio_target(audio_player: AudioStreamPlayer3D):
	"""Set the target audio player for analysis"""
	current_audio_target = audio_player
	
	if game_sound_meter:
		game_sound_meter.target_audio_player = audio_player
	if spectral_meter:
		spectral_meter.set_target_audio_player(audio_player)
	
	if label_3d:
		label_3d.text = "Spectral Analyzer\nAnalyzing: %s" % audio_player.name
	
	print("SpectralAnalyzer: Connected to audio source - %s" % audio_player.name)

func toggle_display_style():
	"""Toggle between different display styles"""
	if game_sound_meter:
		var current_style = game_sound_meter.display_style
		var new_style = (current_style + 1) % 5  # Cycle through all display styles
		game_sound_meter.display_style = new_style
		print("SpectralAnalyzer: Display style changed to %d" % new_style) 
