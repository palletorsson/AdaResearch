extends Node
class_name GraphSynth

# Cache for baked notes: Instrument -> Note -> AudioStreamWAV
var _note_cache: Dictionary = {
	"synth": {},
	"piano": {}
}

# Polyphony pool
var _players: Array[AudioStreamPlayer] = []
var _max_polyphony: int = 32 # Increased for chords

func _ready():
	# Create player pool
	for i in range(_max_polyphony):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
		
	# Pre-bake notes
	_bake_notes()

func _bake_notes():
	var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	
	# Bake common octaves
	for instrument in ["synth", "piano"]:
		var octaves = range(3, 7) if instrument == "piano" else range(2, 6)
		
		for octave in octaves:
			for note_idx in range(12):
				var note_name = notes[note_idx] + str(octave)
				var freq = _note_to_freq(note_name)
				
				var stream: AudioStreamWAV
				if instrument == "piano":
					stream = FMPianoGenerator.generate_note(freq, 0.8, 2.5)
				else:
					stream = GraphAudioGenerator.generate_note(freq, 2.0)
					
				_note_cache[instrument][note_name] = stream

func play_notes(note_names: Array, instrument: String = "synth"):
	if not _note_cache.has(instrument):
		instrument = "synth" # Fallback
		
	for note_name in note_names:
		if not _note_cache[instrument].has(note_name):
			# Generate on demand
			var freq = _note_to_freq(note_name)
			var stream: AudioStreamWAV
			if instrument == "piano":
				stream = FMPianoGenerator.generate_note(freq, 0.8, 2.5)
			else:
				stream = GraphAudioGenerator.generate_note(freq, 2.0)
			_note_cache[instrument][note_name] = stream
		
		var stream = _note_cache[instrument][note_name]
		_play_stream(stream)

func _play_stream(stream: AudioStream):
	# Find free player
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
			
	# Steal oldest
	var p = _players[0]
	p.stop()
	p.stream = stream
	p.play()
	_players.pop_front()
	_players.append(p)

func _note_to_freq(note: String) -> float:
	var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	# Handle flats if necessary, but we stick to sharps for simplicity
	if "b" in note:
		# Simple hack: replace common flats
		note = note.replace("Db", "C#").replace("Eb", "D#").replace("Gb", "F#").replace("Ab", "G#").replace("Bb", "A#")
	
	var octave_idx = note.length() - 1
	var octave = int(note.substr(octave_idx))
	var key = note.substr(0, octave_idx)
	
	var semi = notes.find(key)
	if semi == -1: return 440.0 # Error fallback
	return 440.0 * pow(2.0, (semi - 9 + (octave - 4) * 12) / 12.0)
