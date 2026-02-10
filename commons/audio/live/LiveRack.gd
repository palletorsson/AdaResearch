# LiveRack.gd
# The decks. Wire synth elements together, perform live, see the signal flow.
# This is where the 4am happens.

extends Node
class_name LiveRack

const SAMPLE_RATE = 44100.0

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# THE RACK - What's loaded and playing
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

var channels: Dictionary = {
	"kick": null,
	"hats": null,
	"clap": null,
	"bass": null,
	"acid": null,
	"pad": null
}

var channel_levels: Dictionary = {
	"kick": 1.0,
	"hats": 0.7,
	"clap": 0.8,
	"bass": 0.9,
	"acid": 0.0,  # Bring it in slow
	"pad": 0.3
}

var channel_mutes: Dictionary = {}

# Master state
var bpm: float = 132.0
var playing: bool = false
var beat: float = 0.0
var bar: int = 0
var phrase: int = 0  # 4 bars = 1 phrase

# The key we're in
var root_note: int = 33  # A1
var scale: Array = [0, 2, 3, 5, 7, 8, 10]  # Natural minor

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# LIVE PARAMETERS - The knobs you reach for
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

# 303 acid line
var acid_cutoff: float = 400.0
var acid_cutoff_target: float = 400.0
var acid_resonance: float = 0.7
var acid_env_mod: float = 0.6
var acid_accent: float = 0.5
var acid_pattern_intensity: float = 0.5  # How wild the pattern gets
var slide_time: float = 0.06  # Portamento time for slides (seconds)

# 909 kick
var kick_punch: float = 0.5
var kick_decay: float = 0.25
var kick_pitch: float = 55.0

# Hats
var hat_decay: float = 0.05
var hat_pattern: int = 0  # 0=straight, 1=offbeat, 2=rolling

# Master FX
var master_filter: float = 1.0  # 0=closed, 1=open
var master_filter_target: float = 1.0
var master_drive: float = 0.1
var reverb_send: float = 0.2

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# SEQUENCER STATE
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

var step: int = 0  # 0-15 (16th notes)
var steps_per_beat: int = 4
var total_steps: int = 16

# Pattern memory
var acid_pattern: Array = []
var acid_slides: Array = []
var acid_accents: Array = []

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# FILTER STATES (per-channel)
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

var acid_filter_state: Array = [0.0, 0.0, 0.0]  # 3-pole for 303
var master_filter_state: Array = [0.0, 0.0, 0.0, 0.0]  # 4-pole

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# SIGNALS
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

signal beat_hit(beat_num: int)
signal bar_hit(bar_num: int)
signal phrase_hit(phrase_num: int)
signal step_hit(step_num: int)
signal parameter_changed(param: String, value: float)
signal pattern_changed(channel: String)


func _ready():
	_init_patterns()
	for ch in channels.keys():
		channel_mutes[ch] = false


func _init_patterns():
	# Classic acid pattern - simple but effective
	acid_pattern = [
		root_note, -1, root_note, root_note + 12,
		root_note, -1, root_note, root_note,
		root_note + 12, -1, root_note, root_note,
		root_note, root_note + 12, -1, root_note
	]
	acid_slides = [
		false, false, false, true,
		false, false, false, false,
		true, false, false, false,
		false, true, false, false
	]
	acid_accents = [
		true, false, false, true,
		true, false, false, true,
		false, false, true, false,
		true, false, true, false
	]


# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# TRANSPORT
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func start():
	playing = true
	beat = 0.0
	step = 0
	bar = 0
	phrase = 0
	print("LiveRack: Started at %d BPM" % bpm)


func stop():
	playing = false
	print("LiveRack: Stopped")


func set_bpm(new_bpm: float):
	bpm = clamp(new_bpm, 60.0, 200.0)
	print("LiveRack: BPM = %.1f" % bpm)


# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# THE CLOCK - Called from audio thread or timer
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func advance(delta: float):
	if not playing:
		return
	
	var beats_per_second = bpm / 60.0
	var old_step = step
	
	beat += delta * beats_per_second
	
	# Calculate current step (16th note)
	var new_step = int(beat * steps_per_beat) % total_steps
	
	if new_step != old_step:
		step = new_step
		step_hit.emit(step)
		
		# Beat (every 4 steps)
		if step % 4 == 0:
			var beat_num = step / 4
			beat_hit.emit(beat_num)
			
			# Bar (every 16 steps)
			if step == 0:
				bar += 1
				bar_hit.emit(bar)
				
				# Phrase (every 4 bars)
				if bar % 4 == 0:
					phrase += 1
					phrase_hit.emit(phrase)
					_on_phrase()
	
	# Smooth parameter interpolation
	_interpolate_params(delta)


func _interpolate_params(delta: float):
	# Filter sweeps - slow and deliberate
	var filter_speed = 0.5  # Takes 2 seconds to fully sweep
	acid_cutoff = lerp(acid_cutoff, acid_cutoff_target, delta * filter_speed)
	master_filter = lerp(master_filter, master_filter_target, delta * filter_speed)


func _on_phrase():
	# Every 4 bars, maybe evolve the pattern
	if randf() < acid_pattern_intensity * 0.3:
		_mutate_acid_pattern()


# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# PATTERN GENERATION - The 303 brain
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _mutate_acid_pattern():
	# Small changes, keep the groove
	var change_count = int(acid_pattern_intensity * 3) + 1
	
	for _i in range(change_count):
		var idx = randi() % 16
		var mutation = randi() % 4
		
		match mutation:
			0:  # Change note
				if randf() < 0.5:
					acid_pattern[idx] = root_note + scale[randi() % scale.size()]
				else:
					acid_pattern[idx] = root_note + 12 + scale[randi() % scale.size()]
			1:  # Toggle rest
				acid_pattern[idx] = -1 if acid_pattern[idx] != -1 else root_note
			2:  # Toggle slide
				acid_slides[idx] = not acid_slides[idx]
			3:  # Toggle accent
				acid_accents[idx] = not acid_accents[idx]
	
	pattern_changed.emit("acid")


func generate_acid_pattern(intensity: float):
	# Generate a fresh pattern based on intensity
	# 0.0 = minimal, sparse
	# 1.0 = dense, wild
	
	var note_density = 0.4 + intensity * 0.5  # 40-90% notes
	var octave_jump_chance = 0.1 + intensity * 0.3
	var slide_chance = 0.1 + intensity * 0.2
	var accent_chance = 0.2 + intensity * 0.3
	
	for i in range(16):
		# Note or rest?
		if randf() < note_density:
			# Pick a note from scale
			var scale_degree = randi() % scale.size()
			var octave = 0 if randf() > octave_jump_chance else 12
			acid_pattern[i] = root_note + scale[scale_degree] + octave
		else:
			acid_pattern[i] = -1  # Rest
		
		# Slides on strong beats going into notes
		acid_slides[i] = randf() < slide_chance and i > 0 and acid_pattern[i] != -1
		
		# Accents
		acid_accents[i] = randf() < accent_chance and acid_pattern[i] != -1
	
	# Always have note on beat 1
	if acid_pattern[0] == -1:
		acid_pattern[0] = root_note
	acid_accents[0] = true
	
	pattern_changed.emit("acid")


# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# LIVE CONTROL - The knobs
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func set_acid_cutoff(value: float):
	acid_cutoff_target = clamp(value, 100.0, 4000.0)
	parameter_changed.emit("acid_cutoff", acid_cutoff_target)


func set_acid_resonance(value: float):
	acid_resonance = clamp(value, 0.0, 0.98)
	parameter_changed.emit("acid_resonance", acid_resonance)


func set_acid_env_mod(value: float):
	acid_env_mod = clamp(value, 0.0, 1.0)
	parameter_changed.emit("acid_env_mod", acid_env_mod)


func set_acid_accent(value: float):
	acid_accent = clamp(value, 0.0, 1.0)
	parameter_changed.emit("acid_accent", acid_accent)


func sweep_filter_up(_duration: float = 4.0):
	# Classic filter sweep over N beats
	acid_cutoff_target = 3000.0
	parameter_changed.emit("acid_cutoff", acid_cutoff_target)


func sweep_filter_down(_duration: float = 4.0):
	acid_cutoff_target = 200.0
	parameter_changed.emit("acid_cutoff", acid_cutoff_target)


func set_master_filter(value: float):
	master_filter_target = clamp(value, 0.0, 1.0)
	parameter_changed.emit("master_filter", master_filter_target)


func set_channel_level(channel: String, level: float):
	if channel_levels.has(channel):
		channel_levels[channel] = clamp(level, 0.0, 1.0)
		parameter_changed.emit(channel + "_level", level)


func mute_channel(channel: String, muted: bool):
	if channel_mutes.has(channel):
		channel_mutes[channel] = muted


func fade_in(_channel: String, bars: int = 4):
	# Gradual fade in over N bars
	# This would be handled by the render loop
	pass


func fade_out(_channel: String, bars: int = 4):
	pass


# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# DJ MOVES - Pre-programmed transitions
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func build_tension():
	# Pull back, build energy
	acid_cutoff_target = 200.0
	acid_pattern_intensity = 0.8
	master_filter_target = 0.4
	print("LiveRack: Building tension...")


func drop():
	# Release the tension
	acid_cutoff_target = 2500.0
	master_filter_target = 1.0
	acid_accent = 0.8
	print("LiveRack: DROP")


func breakdown():
	# Strip it back
	channel_mutes["kick"] = true
	channel_mutes["hats"] = true
	acid_cutoff_target = 600.0
	master_filter_target = 0.7
	print("LiveRack: Breakdown")


func bring_it_back():
	# Rebuild from breakdown
	channel_mutes["kick"] = false
	channel_mutes["hats"] = false
	acid_cutoff_target = 1500.0
	master_filter_target = 1.0
	print("LiveRack: Bringing it back")


# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# RENDER - Generate audio for current step
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func render_step(step_idx: int, samples_per_step: int) -> PackedFloat32Array:
	var output = PackedFloat32Array()
	output.resize(samples_per_step)
	
	# Render each channel
	var kick_out = _render_kick(step_idx, samples_per_step)
	var hat_out = _render_hats(step_idx, samples_per_step)
	var acid_out = _render_acid(step_idx, samples_per_step)
	
	# Mix
	for i in range(samples_per_step):
		var sample = 0.0
		
		if not channel_mutes.get("kick", false):
			sample += kick_out[i] * channel_levels["kick"]
		if not channel_mutes.get("hats", false):
			sample += hat_out[i] * channel_levels["hats"]
		if not channel_mutes.get("acid", false):
			sample += acid_out[i] * channel_levels["acid"]
		
		# Master filter
		sample = _apply_master_filter(sample)
		
		# Master drive
		sample = tanh(sample * (1.0 + master_drive * 2.0))
		
		output[i] = sample * 0.7  # Headroom
	
	return output


func _render_kick(step_idx: int, sample_count: int) -> PackedFloat32Array:
	var out = PackedFloat32Array()
	out.resize(sample_count)
	
	# Kick on beats 0, 4, 8, 12 (four on the floor)
	if step_idx % 4 != 0:
		return out
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# 909 kick
		var pitch_env = exp(-t / 0.02)
		var freq = kick_pitch + (150.0 - kick_pitch) * pitch_env
		
		var body = sin(TAU * freq * t)
		var click = sin(TAU * 3000.0 * t) * exp(-t * 50.0) * 0.3
		
		var env = exp(-t / kick_decay)
		var punch_env = 1.0 + kick_punch * exp(-t * 100.0)
		
		out[i] = (body + click) * env * punch_env
	
	return out


func _render_hats(step_idx: int, sample_count: int) -> PackedFloat32Array:
	var out = PackedFloat32Array()
	out.resize(sample_count)
	
	# Hat patterns
	var should_play = false
	match hat_pattern:
		0:  # Straight 8ths
			should_play = step_idx % 2 == 0
		1:  # Offbeat
			should_play = step_idx % 2 == 1
		2:  # Rolling 16ths
			should_play = true
	
	if not should_play:
		return out
	
	# Open hat on offbeats
	var is_open = step_idx % 4 == 2
	var decay = 0.3 if is_open else hat_decay
	
	# 909 metallic hats
	var freqs = [204.0, 298.0, 366.0, 522.0, 540.0, 598.0]
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		var metallic = 0.0
		for f in freqs:
			metallic += 1.0 if fmod(f * t, 1.0) < 0.5 else -1.0
		metallic /= freqs.size()
		
		var noise = randf_range(-1, 1) * 0.3
		var env = exp(-t / decay)
		
		out[i] = (metallic * 0.7 + noise) * env * 0.4
	
	return out


func _render_acid(step_idx: int, sample_count: int) -> PackedFloat32Array:
	var out = PackedFloat32Array()
	out.resize(sample_count)
	
	var note = acid_pattern[step_idx]
	if note == -1:
		return out  # Rest
	
	var freq = 440.0 * pow(2.0, (note - 69) / 12.0)
	var is_accent = acid_accents[step_idx]
	var is_slide = acid_slides[step_idx]
	
	# Accent boosts
	var env_mod_actual = acid_env_mod * (1.4 if is_accent else 1.0)
	var res_actual = min(acid_resonance + (0.2 if is_accent else 0.0), 0.98)
	var decay = 0.2 * (0.5 if is_accent else 1.0)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Sawtooth oscillator
		var osc = fmod(freq * t, 1.0) * 2.0 - 1.0
		
		# Filter envelope
		var env = exp(-t / decay)
		var filter_freq = acid_cutoff + env * env_mod_actual * 2500.0
		
		# 3-pole 303 filter
		var fc = clamp(filter_freq / SAMPLE_RATE, 0.001, 0.49)
		var g = tan(PI * fc)
		
		var feedback = acid_filter_state[2] * res_actual * 4.0
		var x = osc - feedback
		x = _diode_clip(x)
		
		acid_filter_state[0] += g * (x - acid_filter_state[0])
		acid_filter_state[1] += g * (acid_filter_state[0] - acid_filter_state[1])
		acid_filter_state[2] += g * (acid_filter_state[1] - acid_filter_state[2])
		
		var filtered = acid_filter_state[2]
		
		# Amp envelope
		var amp_env = exp(-t / 0.3)
		var accent_boost = 1.2 if is_accent else 1.0
		
		out[i] = tanh(filtered * 1.5) * amp_env * accent_boost * 0.6
	
	return out


func _diode_clip(x: float) -> float:
	if x > 0:
		return 1.0 - exp(-x)
	else:
		return -1.0 + exp(x)


func _apply_master_filter(sample: float) -> float:
	var cutoff = 200.0 + master_filter * 10000.0
	var fc = clamp(cutoff / SAMPLE_RATE, 0.001, 0.49)
	var g = tan(PI * fc)
	
	var x = sample
	for i in range(4):
		master_filter_state[i] += g * (x - master_filter_state[i])
		x = master_filter_state[i]
	
	return master_filter_state[3]


# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# STATE INSPECTION - For visualization
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func get_state() -> Dictionary:
	return {
		"playing": playing,
		"bpm": bpm,
		"bar": bar,
		"phrase": phrase,
		"step": step,
		"acid_cutoff": acid_cutoff,
		"acid_resonance": acid_resonance,
		"acid_env_mod": acid_env_mod,
		"acid_accent": acid_accent,
		"acid_pattern": acid_pattern.duplicate(),
		"acid_accents": acid_accents.duplicate(),
		"acid_slides": acid_slides.duplicate(),
		"master_filter": master_filter,
		"channel_levels": channel_levels.duplicate(),
		"channel_mutes": channel_mutes.duplicate()
	}
