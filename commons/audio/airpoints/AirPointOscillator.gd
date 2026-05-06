# SystemsMusicOscillator.gd
# Path: res://commons/audio/airpoints/SystemsMusicOscillator.gd
# Agent: Agent-SynthesisEngineer (Agent B)
# Task: 021 - Prototype Sound Generator
# Architecture: Designed by Agent-SoundArchitect (Agent A)
#
# Distance-modulated oscillator for Air Points
# Frequency: map(distance, 0-10m, 880-110 Hz)
# Amplitude: map(proximity, 0-1, 0-0.7)
# Part of the Audio_AirPoints system inspired by Teropa's Systems Music (2016)
# Renamed to avoid conflict with existing classes

extends AudioStreamPlayer
class_name SystemsMusicOscillator

## The SystemsMusicListener that provides modulation data
@export var listener: SystemsMusicListener

## Waveform type
enum Waveform { SINE, TRIANGLE, SAWTOOTH, SQUARE }
@export var waveform: Waveform = Waveform.SINE

## Frequency mapping (distance in meters → frequency in Hz)
@export var min_distance: float = 0.0
@export var max_distance: float = 10.0
@export var min_frequency: float = 110.0  # Low A
@export var max_frequency: float = 880.0  # High A (2 octaves)

## Amplitude mapping (proximity 0-1 → amplitude 0-0.7)
@export var max_amplitude: float = 0.7

## Smoothing factor for parameter changes (0-1, higher = smoother)
@export var smoothing: float = 0.95

## Enable/disable audio generation
@export var enabled: bool = true

# === AUDIO GENERATION ===

const SAMPLE_RATE = 44100
const BUFFER_SIZE = 2048

var _playback: AudioStreamGeneratorPlayback
var _phase: float = 0.0
var _current_frequency: float = 440.0
var _current_amplitude: float = 0.0
var _target_frequency: float = 440.0
var _target_amplitude: float = 0.0


func _ready() -> void:
	# Create AudioStreamGenerator
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 0.1  # 100ms buffer
	
	stream = generator
	autoplay = true
	bus = "Master"  # Will be changed to "AirPoints" bus when implemented
	
	# Connect to listener if set
	if listener:
		listener.modulation_updated.connect(_on_modulation_updated)
	
	# Set initial amplitude so we can hear something immediately
	_current_amplitude = 0.3
	_target_amplitude = 0.3
	
	play()
	_playback = get_stream_playback()
	
	print("SystemsMusicOscillator: Ready and playing")
	print("  Frequency: %.1f Hz" % _current_frequency)
	print("  Amplitude: %.2f" % _current_amplitude)
	print("  Waveform: ", waveform)
	print("  Listener connected: ", listener != null)


func _process(_delta: float) -> void:
	if not enabled or not _playback:
		return
	
	# Fill audio buffer
	_fill_buffer()


func _fill_buffer() -> void:
	if not _playback:
		return
	
	var frames_available = _playback.get_frames_available()
	if frames_available == 0:
		return
	
	# Limit frames to process
	var frames_to_fill = min(frames_available, BUFFER_SIZE)
	
	# Smooth parameter transitions (exponential moving average)
	_current_frequency = lerp(_current_frequency, _target_frequency, 1.0 - smoothing)
	_current_amplitude = lerp(_current_amplitude, _target_amplitude, 1.0 - smoothing)
	
	# Generate audio samples
	for i in range(frames_to_fill):
		var sample = _generate_sample()
		_playback.push_frame(Vector2(sample, sample))  # Mono → Stereo


func _generate_sample() -> float:
	# Generate waveform based on type
	var sample: float = 0.0
	
	match waveform:
		Waveform.SINE:
			sample = sin(_phase * TAU)
		
		Waveform.TRIANGLE:
			# Triangle wave: -1 to 1
			var t = fmod(_phase, 1.0)
			sample = abs(4.0 * t - 2.0) - 1.0
		
		Waveform.SAWTOOTH:
			# Sawtooth wave: -1 to 1
			sample = 2.0 * fmod(_phase, 1.0) - 1.0
		
		Waveform.SQUARE:
			# Square wave: -1 or 1
			sample = 1.0 if fmod(_phase, 1.0) < 0.5 else -1.0
	
	# Apply amplitude
	sample *= _current_amplitude
	
	# Advance phase
	_phase += _current_frequency / SAMPLE_RATE
	if _phase >= 1.0:
		_phase = fmod(_phase, 1.0)
	
	# Soft clipping to prevent distortion
	sample = tanh(sample * 1.5) * 0.7
	
	return sample


func _on_modulation_updated(params: Dictionary) -> void:
	if not enabled:
		return
	
	# Extract parameters
	var distance: float = params.get("distance", 5.0)
	var proximity: float = params.get("proximity_factor", 0.0)
	
	# Map distance to frequency (inverse relationship)
	# Close = high frequency, far = low frequency
	var distance_normalized = clamp(distance / max_distance, 0.0, 1.0)
	_target_frequency = lerp(max_frequency, min_frequency, distance_normalized)
	
	# Map proximity to amplitude
	# Close = loud, far = quiet
	_target_amplitude = proximity * max_amplitude
	
	# Optional: Add velocity-based modulation (future enhancement)
	# var speed: float = params.get("speed", 0.0)
	# Could modulate frequency or add tremolo based on speed


## Manually set frequency (for testing)
func set_frequency(freq: float) -> void:
	_target_frequency = clamp(freq, 20.0, 20000.0)


## Manually set amplitude (for testing)
func set_amplitude(amp: float) -> void:
	_target_amplitude = clamp(amp, 0.0, 1.0)


## Connect to a different listener
func set_listener(new_listener: SystemsMusicListener) -> void:
	# Disconnect from old listener
	if listener and listener.modulation_updated.is_connected(_on_modulation_updated):
		listener.modulation_updated.disconnect(_on_modulation_updated)
	
	# Connect to new listener
	listener = new_listener
	if listener:
		listener.modulation_updated.connect(_on_modulation_updated)
