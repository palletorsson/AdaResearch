extends Node

var disco_floor = SimpleDiscoFloor.new()
var disco_music = SimpleDiscoMusic.new()
var music_on = false
func _ready():
	# Add visual disco floor
	
	disco_floor.name = "DiscoFloor"
	disco_floor.floor_height = -0.5
	add_child(disco_floor)
	
	# Add disco music (separate node)
	if music_on: 
		disco_music.name = "DiscoMusic"
		disco_music.set_educational_mode(true)  # Quiet for classroom
		add_child(disco_music)

	print("🎉 Disco floor and music ready as separate systems!")

# Control them independently:
func toggle_visuals():
	disco_floor.toggle_disco()

func toggle_audio():
	disco_music.toggle_music()

func set_music_volume(vol: float):
	disco_music.set_volume(vol)
