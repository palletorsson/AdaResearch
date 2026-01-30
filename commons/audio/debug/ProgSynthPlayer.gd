extends Node

# Player for 70s Prog Synth Song
# Run this scene to test the Prog Synth generator
# Features: Minimoog bass, ELP leads, Kraftwerk sequences, motorik drums

@onready var player = $AudioStreamPlayer
@onready var label = $Label

func _ready():
	print("ProgSynthPlayer: Generating 70s Prog Synth track...")
	label.text = "Generating 70s Prog Synth Track...\n(Warming up the Minimoog...)"
	
	# Generate directly (sync for simplicity)
	var stream = AudioSynthesizer.generate_prog_synth_song({})
	
	if stream:
		print("ProgSynthPlayer: Track ready!")
		_play_stream(stream)
	else:
		label.text = "ERROR: Failed to generate track"

func _play_stream(stream: AudioStream):
	player.stream = stream
	player.play()
	label.text = "Now Playing: 70s Prog Synth\nSection: Intro"
	print("ProgSynthPlayer: Playing.")

var acc_time = 0.0
var bpm = 110.0
var bar_duration = (240.0 / bpm) * 2.0  # Double bars for prog feel

func _process(delta):
	if player.playing:
		acc_time += delta
		
		var current_bar := int(acc_time / bar_duration)
		@warning_ignore("integer_division")
		var current_section_idx := current_bar / 4
		var section_names = ["Intro (Moog Pad)", "Verse (+ Bass + Drums)", "Build (+ Kraftwerk Seq)", "Solo (ELP Lead!)", "Outro"]
		var section_name = section_names[current_section_idx] if current_section_idx < section_names.size() else "Looping..."
		
		var bar_in_section = current_bar % 4
		
		var txt = "🎹 NOW PLAYING: 70s Prog Synth\n"
		txt += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
		txt += "Time: %.1f s | Bar: %d\n" % [acc_time, current_bar + 1]
		txt += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
		txt += "Section: %s\n" % section_name
		txt += "Bar in section: %d/4\n" % (bar_in_section + 1)
		txt += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
		
		match current_section_idx:
			0: txt += "🎵 Warm Moog pad fading in..."
			1: txt += "🎸 Minimoog bass + motorik drums"
			2: txt += "🤖 Kraftwerk 8-note sequence added"
			3: txt += "🔥 ELP SCREAMING MOOG SOLO!"
			4: txt += "🌙 Fading out to pad + sequence..."
			_: txt += "🔄 Track complete, looping..."
		
		label.text = txt
	else:
		if acc_time > 0:
			label.text = "Track finished. Press SPACE to replay."
		acc_time = 0.0

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if not player.playing:
			player.play()
			acc_time = 0.0
