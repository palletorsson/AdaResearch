extends Node

# Player ensuring we can listen to the Ambience
# Run this scene to test the Ambient Works Song generator

@onready var player = $AudioStreamPlayer
@onready var label = $Label

func _ready():
	print("AmbientWorksPlayer: Requesting song...")
	label.text = "Requesting Ambient Works Song..."
	
	# Connect to async generation signal
	if not SoundBank.is_connected("sound_generated", _on_sound_generated):
		SoundBank.sound_generated.connect(_on_sound_generated)
	
	# Request the song
	# Note: get_sound returns null for async songs and triggers generation
	var stream = SoundBank.get_sound("AudioSynthesizer.AMBIENT_WORKS_SONG")
	
	if stream:
		print("AmbientWorksPlayer: Stream returned immediately (Cached?)")
		_play_stream(stream)
	else:
		print("AmbientWorksPlayer: Waiting for async generation...")
		label.text = "Generating... (Subjective Time Dilation Active)"

func _on_sound_generated(sound_id: String):
	if sound_id == "AudioSynthesizer.AMBIENT_WORKS_SONG":
		print("AmbientWorksPlayer: Song Generated!")
		var stream = SoundBank.get_sound(sound_id)
		_play_stream(stream)

func _play_stream(stream: AudioStream):
	player.stream = stream
	player.play()
	label.text = "Now Playing: Aphex Twin Style Ambient\nSection: Intro (Crossfading...)"
	print("AmbientWorksPlayer: Playing.")

var acc_time = 0.0
var bpm = 90.0
var bar_duration = (240.0 / bpm) * 2.0 # 5.333s per bar (Double bars)
var progression = [1, 5, 6, 4] # I - V - VI - IV

func _process(delta):
	if player.playing:
		acc_time += delta
		
		# Calculate musical state
		var current_bar := int(acc_time / bar_duration)
		@warning_ignore("integer_division")
		var current_section_idx := current_bar / 4 # 4 bars per section
		var section_names = ["Intro", "Build", "Main", "Outro"]
		var section_name = section_names[current_section_idx] if current_section_idx < section_names.size() else "Looping/End"
		
		var bar_in_section = current_bar % 4
		var chord_degree = progression[bar_in_section]
		
		# Format Label
		var txt = "Now Playing: Ambient Works (Debug Mode)\n"
		txt += "Time: %.2f s\n" % acc_time
		txt += "Section: %s (Bar %d)\n" % [section_name, bar_in_section + 1]
		txt += "Chord: %d (Am Scale)\n" % chord_degree
		txt += "Global Bar: %d\n" % (current_bar + 1)
		
		if current_bar >= 16: # 4 sections * 4 bars
			txt += "STATUS: Song Finished (Should loop/end)"
			
		label.text = txt
	else:
		acc_time = 0.0
