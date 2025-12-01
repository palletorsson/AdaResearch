extends Node
class_name GraphSynth

# This version uses pre-baked samples for performance, 
# replacing the real-time DSP loop.

# Cache for baked notes: Frequency -> AudioStreamWAV
var _note_cache: Dictionary = {}

# Polyphony pool
var _players: Array[AudioStreamPlayer] = []
var _max_polyphony: int = 16

func _ready():
	# Create player pool
	for i in range(_max_polyphony):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
		
	# Pre-bake common notes (C3 to C6 chromatic)
	# This happens ONCE at startup, saving CPU later.
	_bake_notes()

func _bake_notes():
	var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	for octave in range(3, 6):
		for note_idx in range(12):
			var note_name = notes[note_idx] + str(octave)
			var freq = _note_to_freq(note_name)
			
			# Generate the sample
			var stream = GraphAudioGenerator.generate_note(freq, 2.0) # 2s duration
			_note_cache[note_name] = stream

func play_note(note_name: String):
	if not _note_cache.has(note_name):
		# Generate on demand if missing (and cache it)
		var freq = _note_to_freq(note_name)
		var stream = GraphAudioGenerator.generate_note(freq, 2.0)
		_note_cache[note_name] = stream
	
	var stream = _note_cache[note_name]
	_play_stream(stream)

func _play_stream(stream: AudioStream):
	# Find free player
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
			
	# Steal oldest (crudely, just steal index 0)
	var p = _players[0]
	p.stop()
	p.stream = stream
	p.play()
	# Move to end of list so it's last to be stolen next
	_players.pop_front()
	_players.append(p)

func _note_to_freq(note: String) -> float:
	var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	var octave = int(note.substr(note.length()-1))
	var key = note.substr(0, note.length()-1)
	var semi = notes.find(key)
	return 440.0 * pow(2.0, (semi - 9 + (octave - 4) * 12) / 12.0)
