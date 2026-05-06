extends AudioStreamPlayer
class_name AirPointSynth

## AirPointSynth (formerly Oscillator)
## Implements the full Teropa-inspired synthesis engine:
## 1. Distance Oscillator (FM Sine)
## 2. Velocity Granulator (Speed -> Grain Cloud)
## 3. Spatial Harmonics (Additive Synthesis)
## Part of Audio_AirPoints System Phase 1 & 2.

@export var listener_path: NodePath
@export var sample_rate: float = 44100.0

# --- Tuning Parameters ---
# Oscillator
@export_group("Oscillator")
@export var min_freq: float = 110.0
@export var max_freq: float = 880.0
@export var osc_vol: float = 0.5
@export var fm_depth: float = 2.0 # Frequency Modulation depth

# Granulator
@export_group("Granulator")
@export var grain_min_density: float = 1.0 # Grains/sec
@export var grain_max_density: float = 50.0
@export var grain_dur: float = 0.1 # Seconds
@export var grain_vol: float = 0.3

# Harmonics
@export_group("Harmonics")
@export var harmonics_count: int = 4
@export var harmonics_falloff: float = 0.5

# Effects
@export_group("Effects")
@export var delay_time: float = 0.3
@export var delay_feedback: float = 0.4

# --- Internal State ---
var listener: AirPointListener
var playback: AudioStreamGeneratorPlayback

# Oscillator State
var phase: float = 0.0
var fm_phase: float = 0.0
var current_freq: float = 440.0
var current_amp: float = 0.0
var current_pan: float = 0.0

# Granulator State
class Grain:
	var phase: float = 0.0
	var freq: float = 440.0
	var amp: float = 1.0
	var duration: float = 0.1
	var time_alive: float = 0.0
	var pan: float = 0.0
	
	func process(increment: float) -> float:
		time_alive += increment / freq # increment is freq/rate, so back calc? No.
		# We'll pass time_step (1/sample_rate)
		
		# Envelope (Sine window)
		var progress = time_alive / duration
		if progress >= 1.0: return 0.0
		
		var env = sin(progress * PI)
		var signal_val = sin(phase * TAU)
		
		phase += increment
		return signal_val * env * amp

var grains: Array[Grain] = []
var grain_timer: float = 0.0
var current_grain_rate: float = 0.0

# Delay State (Simple circular buffer)
var delay_buffer: PackedFloat32Array
var delay_idx: int = 0
var delay_samples: int = 0

func _ready():
	if listener_path:
		listener = get_node_or_null(listener_path)
	
	# Initialize generator
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.1 # 100ms
	stream = generator
	play()
	
	playback = get_stream_playback()
	
	# Init delay
	delay_samples = int(delay_time * sample_rate)
	delay_buffer.resize(delay_samples)
	delay_buffer.fill(0.0)

func _process(delta):
	if not playback: return
	
	if listener:
		_update_parameters(delta)
	
	_fill_buffer()

func _update_parameters(delta):
	# 1. Oscillator Param Mapping
	var target_freq = lerp(min_freq, max_freq, listener.proximity)
	current_freq = lerp(current_freq, target_freq, 0.1)
	
	var target_amp = lerp(0.0, osc_vol, listener.proximity)
	current_amp = lerp(current_amp, target_amp, 0.1)
	
	current_pan = clamp(listener.direction.x, -1.0, 1.0)
	
	# 2. Granulator Param Mapping
	# Map speed (0-5) to density (1-50)
	var normalized_speed = clamp(listener.speed / 5.0, 0.0, 1.0)
	current_grain_rate = lerp(grain_min_density, grain_max_density, normalized_speed)
	
	# Spawn grains
	if normalized_speed > 0.05:
		grain_timer += delta
		var interval = 1.0 / current_grain_rate
		while grain_timer >= interval:
			grain_timer -= interval
			_spawn_grain()

func _spawn_grain():
	var g = Grain.new()
	g.duration = grain_dur
	g.amp = grain_vol * (0.5 + randf() * 0.5)
	g.time_alive = 0.0
	
	# Pitch based on vertical direction (y)
	# map y (-1 to 1) to +/- 12 semitones
	var pitch_mod = listener.direction.y * 12.0
	var grain_base_freq = current_freq * pow(2.0, pitch_mod / 12.0)
	g.freq = grain_base_freq * (0.98 + randf() * 0.04) # Detune
	g.pan = clamp(listener.direction.x + (randf() - 0.5) * 0.5, -1.0, 1.0) # Scatter pan
	
	grains.append(g)

func _fill_buffer():
	var frames = playback.get_frames_available()
	if frames <= 0: return
	
	var buffer = PackedVector2Array()
	buffer.resize(frames)
	
	var dt = 1.0 / sample_rate
	var osc_inc = current_freq * dt
	
	for i in range(frames):
		var sample_l = 0.0
		var sample_r = 0.0
		
		# --- 1. Main Oscillator (FM Sine) ---
		# Modulator
		var mod = sin(fm_phase * TAU) * fm_depth
		fm_phase += osc_inc * 2.0 # Modulator at 2x ratio
		
		# Carrier
		var carrier = sin((phase + mod) * TAU)
		phase += osc_inc
		
		# Harmonics (Additive)
		var harmonics_sig = 0.0
		for h in range(1, harmonics_count + 1):
			var h_amp = pow(harmonics_falloff, h)
			harmonics_sig += sin(phase * (h + 1) * TAU) * h_amp
		
		var main_sig = (carrier + harmonics_sig * 0.5) * current_amp
		
		# Pan Main
		sample_l += main_sig * (0.5 - current_pan * 0.5)
		sample_r += main_sig * (0.5 + current_pan * 0.5)
		
		# --- 2. Granulator ---
		# Process grains in reverse to allow removal
		for j in range(grains.size() - 1, -1, -1):
			var g = grains[j]
			var g_inc = g.freq * dt
			g.time_alive += dt
			
			if g.time_alive >= g.duration:
				grains.remove_at(j)
				continue
				
			# Recalc envelope here or inside process? Doing it inline for speed
			var progress = g.time_alive / g.duration
			var env = sin(progress * PI)
			var g_sig = sin(g.phase * TAU) * env * g.amp
			g.phase += g_inc
			
			sample_l += g_sig * (0.5 - g.pan * 0.5)
			sample_r += g_sig * (0.5 + g.pan * 0.5)
			
		# --- 3. Delay Effect (Mono-ish mix) ---
		var mono_in = (sample_l + sample_r) * 0.5
		var delay_out = delay_buffer[delay_idx]
		
		# Write to delay
		delay_buffer[delay_idx] = mono_in + delay_out * delay_feedback
		delay_idx = (delay_idx + 1) % delay_samples
		
		# Mix delay
		sample_l += delay_out * 0.3
		sample_r += delay_out * 0.3
		
		buffer[i] = Vector2(sample_l, sample_r)
		
	playback.push_buffer(buffer)
