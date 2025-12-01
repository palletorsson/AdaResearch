extends Node
class_name FMPianoSynth

## FMPianoSynth (Baked Version)
## Uses pre-generated FM samples for performance.
## Manages a pool of AudioStreamPlayers.

@export var gain: float = 0.4

# Cache: "freq_velocity_sustain" -> AudioStreamWAV
var _sample_cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _max_polyphony: int = 12

func _ready():
	_setup_reverb()
	
	# Create player pool
	for i in range(_max_polyphony):
		var p = AudioStreamPlayer.new()
		p.bus = "FMPianoReverb" # Route to reverb bus
		p.volume_db = linear_to_db(gain)
		add_child(p)
		_players.append(p)

func _setup_reverb():
	# Add Reverb Bus for "Air"
	var bus_name = "FMPianoReverb"
	var idx = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		idx = AudioServer.get_bus_count()
		AudioServer.add_bus()
		AudioServer.set_bus_name(idx, bus_name)
		
		var reverb = AudioEffectReverb.new()
		reverb.room_size = 0.95 # Massive "Eno" Hall
		reverb.damping = 0.1 # Minimal damping
		reverb.spread = 1.0
		reverb.dry = 0.6
		reverb.wet = 0.7 # Air wash
		
		AudioServer.add_bus_effect(idx, reverb)
		
		# Route to Master
		AudioServer.set_bus_send(idx, "Master")

func play_note(freq: float, vel: float, sustain_time: float = 1.5):
	# Quantize params to reduce cache size
	# Round freq to 2 decimals, vel to 1 decimal, sustain to 1 decimal
	var q_freq = snapped(freq, 0.01)
	var q_vel = snapped(vel, 0.1) 
	var q_sustain = snapped(sustain_time, 0.1)
	
	var cache_key = "%s_%s_%s" % [q_freq, q_vel, q_sustain]
	
	if not _sample_cache.has(cache_key):
		# Generate on demand
		var stream = FMPianoGenerator.generate_note(q_freq, q_vel, q_sustain)
		_sample_cache[cache_key] = stream
		
	var stream = _sample_cache[cache_key]
	_play_stream(stream)

func _play_stream(stream: AudioStream):
	# Find free player
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
			
	# Steal oldest (index 0)
	var p = _players[0]
	p.stop()
	p.stream = stream
	p.play()
	_players.pop_front()
	_players.append(p)

# Helper for Linear -> DB conversion
func linear_to_db(lin: float) -> float:
	if lin <= 0: return -80.0
	return 20.0 * log(lin) / log(10.0)
