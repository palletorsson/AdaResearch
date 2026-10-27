extends Node3D
## Seat the existing score at hand height, with separate physical transport keys.
const Kit = preload("res://commons/artifacts/regularity/room_tools.gd")
var sequencer: Node3D
var play_button: Node3D
var stop_button: Node3D

func _ready() -> void:
	Kit.box(self,"Console",Vector3(0,.5,0),Vector3(1.45,1.0,.55),Color("444950"))
	sequencer = load("res://commons/audio/sequencer/step_sequencer.tscn").instantiate()
	sequencer.name = "OriginalSequencer"
	sequencer.position = Vector3(0,1.4,0)
	sequencer.scale = Vector3.ONE * 1.8
	sequencer.sound_preset = "90s_house"
	sequencer.auto_play = false
	add_child(sequencer)
	var panel := Kit.panel(self,"SOUND / ITS OWN CLOCK",Vector3(0,1.0,.42),0)
	play_button = panel.add_button("PLAY")
	stop_button = panel.add_button("STOP")
	play_button.pressed.connect(sequencer.play)
	stop_button.pressed.connect(stop_sound)

func stop_sound() -> void:
	sequencer.stop()
	# Stop also ends any sounding tail, rather than only preventing the next beat.
	for player in sequencer._audio_players: player.stop()
