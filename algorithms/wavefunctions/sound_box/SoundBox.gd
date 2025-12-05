extends Node3D

@onready var grid_container = $GridContainer

var _active_players: Array[AudioStreamPlayer3D] = []

func _ready() -> void:
	# Connect all trigger buttons
	for child in grid_container.get_children():
		if child.has_signal("triggered"):
			child.triggered.connect(_on_button_triggered)

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
	# Create a temporary player for polyphony (stacking sounds)
	var player = AudioStreamPlayer3D.new()
	add_child(player)
	player.stream = stream
	player.unit_size = 10.0
	player.max_db = 0.0
	
	_active_players.append(player)
	
	# Connect finished signal to cleanup using a callable to capture the player instance safely
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
