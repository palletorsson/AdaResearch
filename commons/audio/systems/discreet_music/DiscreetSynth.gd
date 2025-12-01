extends Node
class_name DiscreetSynth

# Cached AudioStreamWAVs
var _sample_cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _max_polyphony: int = 8

var gain: float = 0.5:
	set(value):
		gain = value
		_update_gain()

func _update_gain():
	var db = linear_to_db(gain)
	for p in _players:
		p.volume_db = db

func _ready():
	for i in range(_max_polyphony):
		var p = AudioStreamPlayer.new()
		p.bus = "DiscreetMusic" # Route to tape delay bus
		add_child(p)
		_players.append(p)
	_update_gain()

func trigger_note(freq: float, duration: float = 1.0):
	# Quantize parameters for caching
	var q_freq = snapped(freq, 0.01)
	var q_dur = snapped(duration, 0.1)
	
	var key = "%s_%s" % [q_freq, q_dur]
	
	if not _sample_cache.has(key):
		var stream = DiscreetAudioGenerator.generate_note(q_freq, q_dur)
		_sample_cache[key] = stream
		
	_play_stream(_sample_cache[key])

func _play_stream(stream: AudioStream):
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.play()
			return
			
	var p = _players[0]
	p.stop()
	p.stream = stream
	p.play()
	_players.pop_front()
	_players.append(p)

# Compatibility methods
func set_note(freq: float):
	pass # Not supported in baked version

func release_all():
	for p in _players:
		p.stop()
