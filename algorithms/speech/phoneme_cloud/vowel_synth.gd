extends Node3D

# Vowel Field Implementation (Minimal Model)
# Based on "Vowel as Field" Theory.
# Parameters:
#  - F1 (Vertical / Openness)
#  - Delta (F2 - F1) (Horizontal / Identity Axis)
# Logic: F2 = F1 + Delta
# Topology: Parallel BPF x2
# Source: Harmonic Oscillator

var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 44100.0
var phase: float = 0.0
var pulse_hz: float = 130.0 

# The Two Field Parameters
var f1: float = 500.0
var delta: float = 1000.0

# Fixed Q (Resonance Shape)
var q_factor: float = 12.0

# Anchors (Hardcoded)
# i: 240, 2160
# e: 390, 1910
# a: 850, 760
# o: 360, 280
# u: 250, 345
const ANCHORS = {
	"i": Vector2(240, 2160),
	"e": Vector2(390, 1910),
	"a": Vector2(850, 760),
	"o": Vector2(360, 280),
	"u": Vector2(250, 345)
}

# Filter State Class
class FilterState:
	var x1: float = 0.0
	var x2: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0

var filter1_state = FilterState.new()
var filter2_state = FilterState.new()

# Volume / Envelopes
var intensity: float = 0.0 
var target_intensity: float = 0.0 
var is_speaking: bool = false
var time_accum: float = 0.0

@onready var player: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready():
	if not player:
		player = AudioStreamPlayer3D.new()
		add_child(player)
	
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.05
	player.stream = generator
	player.play()
	playback = player.get_stream_playback()

func _process(delta_time):
	# Parameter Drift (Life)
	time_accum += delta_time
	var drift_f1 = sin(time_accum * 1.5) * 3.0
	var drift_delta = sin(time_accum * 2.1) * 5.0
	
	# Envelope Smoothing
	intensity = lerp(intensity, target_intensity, delta_time * 15.0)
	
	_fill_buffer(drift_f1, drift_delta)

func set_vowel(key: String):
	if key in ANCHORS:
		var anchor = ANCHORS[key]
		# anchor.x = F1, anchor.y = Delta
		move_to(anchor.x, anchor.y, 0.15)

func move_to(t_f1: float, t_delta: float, duration: float = 0.1):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "f1", t_f1, duration)
	tween.tween_property(self, "delta", t_delta, duration)

func speak_vowel(key: String, burst_intensity: float = 1.0):
	if key in ANCHORS:
		var anchor = ANCHORS[key]
		f1 = anchor.x
		delta = anchor.y
	is_speaking = true
	target_intensity = burst_intensity

func stop():
	is_speaking = false
	target_intensity = 0.0

func _fill_buffer(drift_f1: float, drift_delta: float):
	if not playback:
		return
		
	var to_fill = playback.get_frames_available()
	while to_fill > 0:
		var frame_count = min(to_fill, 512)
		var buffer = PackedVector2Array()
		buffer.resize(frame_count)
		
		# 1. Resolve Targets
		# F1 is direct
		var curr_f1 = f1 + drift_f1
		# F2 is Derived (F1 + Delta)
		var curr_f2 = (f1 + drift_f1) + (delta + drift_delta)
		
		# 2. Calculate Coeffs (Parallel, Fixed Q)
		var c1 = _calculate_coefficients(curr_f1, q_factor)
		var c2 = _calculate_coefficients(curr_f2, q_factor)
		
		# Gain Compensation
		# Lower frequencies naturally have higher energy in this source.
		# Boost F2 to maintain presence.
		var g1 = 1.0
		var g2 = 1.5
		
		for i in range(frame_count):
			# Oscillator (Sawtooth)
			phase += pulse_hz / sample_rate
			if phase >= 1.0:
				phase -= 1.0
			var sample = (phase * 2.0) - 1.0 
			
			# Parallel Filters
			var out1 = _process_filter(sample, filter1_state, c1) * g1
			var out2 = _process_filter(sample, filter2_state, c2) * g2
			
			# Sum
			var final_val = (out1 + out2) * 0.15 * intensity
			buffer[i] = Vector2(final_val, final_val)
			
		playback.push_buffer(buffer)
		to_fill -= frame_count

func _calculate_coefficients(freq: float, q: float) -> Array:
	var w0 = TAU * freq / sample_rate
	var alpha = sin(w0) / (2.0 * q)
	
	var b0 = alpha
	var b1 = 0.0
	var b2 = -alpha
	var a0 = 1.0 + alpha
	var a1 = -2.0 * cos(w0)
	var a2 = 1.0 - alpha
	return [b0/a0, b1/a0, b2/a0, a1/a0, a2/a0]

func _process_filter(input: float, s: FilterState, c: Array) -> float:
	var output = c[0]*input + c[1]*s.x1 + c[2]*s.x2 - c[3]*s.y1 - c[4]*s.y2
	if is_nan(output) or is_inf(output):
		output = 0.0
		s.x1 = 0; s.x2 = 0; s.y1 = 0; s.y2 = 0;
	s.x2 = s.x1
	s.x1 = input
	s.y2 = s.y1
	s.y1 = output
	return output
