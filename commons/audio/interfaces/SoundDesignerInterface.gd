# SoundDesignerInterface.gd
# Enhanced interface with sliders and real-time audio updates
# Educational Sound Synthesis Learning Platform

extends Control
class_name SoundDesignerInterface

# UI References - will be assigned during setup
var sound_type_option: OptionButton
var preview_button: Button
var stop_button: Button
var save_button: Button
var load_button: Button
var export_button: Button
var realtime_toggle: CheckBox
var parameters_container: VBoxContainer

# Educational UI elements
var theory_panel: Panel
var theory_label: RichTextLabel
var tutorial_mode_toggle: CheckBox
var lesson_progress_bar: ProgressBar
var interactive_exercises_container: VBoxContainer

# Audio Player for previewing sounds
var audio_player: AudioStreamPlayer
var current_sound_key: String = "basic_sine_wave"

# Real-time update system
var realtime_enabled: bool = true
var update_timer: Timer
var needs_audio_update: bool = false

# Educational system
var tutorial_mode: bool = false
var current_lesson: int = 0
var lessons_completed: Dictionary = {}

# Sound Parameters Structure with enhanced ranges and defaults
var sound_parameters = {
	"basic_sine_wave": {
		"duration": {"value": 2.0, "min": 0.5, "max": 10.0, "step": 0.1},
		"frequency": {"value": 440.0, "min": 20.0, "max": 2000.0, "step": 1.0},
		"amplitude": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
		"fade_in_time": {"value": 0.05, "min": 0.0, "max": 1.0, "step": 0.01},
		"fade_out_time": {"value": 0.05, "min": 0.0, "max": 1.0, "step": 0.01}
	},
	"pickup_mario": {
		"duration": {"value": 0.5, "min": 0.1, "max": 3.0, "step": 0.01},
		"start_freq": {"value": 440.0, "min": 100.0, "max": 1000.0, "step": 5.0},
		"end_freq": {"value": 880.0, "min": 200.0, "max": 2000.0, "step": 5.0},
		"decay_rate": {"value": 8.0, "min": 1.0, "max": 20.0, "step": 0.1},
		"amplitude": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
		"wave_type": {"value": "square", "options": ["sine", "square", "sawtooth"]}
	},
	"teleport_drone": {
		"duration": {"value": 3.0, "min": 1.0, "max": 10.0, "step": 0.1},
		"base_freq": {"value": 220.0, "min": 50.0, "max": 500.0, "step": 5.0},
		"mod_freq": {"value": 0.5, "min": 0.1, "max": 5.0, "step": 0.1},
		"mod_depth": {"value": 30.0, "min": 0.0, "max": 100.0, "step": 1.0},
		"noise_amount": {"value": 0.2, "min": 0.0, "max": 1.0, "step": 0.01},
		"amplitude": {"value": 0.2, "min": 0.0, "max": 1.0, "step": 0.01},
		"fade_in_time": {"value": 0.05, "min": 0.0, "max": 0.5, "step": 0.01},
		"fade_out_time": {"value": 0.08, "min": 0.0, "max": 0.5, "step": 0.01},
		"wave_type": {"value": "sawtooth", "options": ["sine", "square", "sawtooth"]}
	},
	"lift_bass_pulse": {
		"duration": {"value": 2.0, "min": 0.5, "max": 5.0, "step": 0.1},
		"base_freq": {"value": 120.0, "min": 60.0, "max": 200.0, "step": 1.0},
		"pulse_rate": {"value": 2.0, "min": 0.5, "max": 10.0, "step": 0.1},
		"decay_rate": {"value": 2.0, "min": 0.5, "max": 10.0, "step": 0.1},
		"amplitude": {"value": 0.6, "min": 0.0, "max": 1.0, "step": 0.01},
		"wave_type": {"value": "sine", "options": ["sine", "square", "sawtooth"]}
	},
	"ghost_drone": {
		"duration": {"value": 4.0, "min": 2.0, "max": 10.0, "step": 0.1},
		"freq1": {"value": 110.0, "min": 50.0, "max": 300.0, "step": 5.0},
		"freq2": {"value": 165.0, "min": 80.0, "max": 400.0, "step": 5.0},
		"freq3": {"value": 220.0, "min": 100.0, "max": 500.0, "step": 5.0},
		"mod_cycles": {"value": 2.0, "min": 0.5, "max": 8.0, "step": 0.1},
		"amplitude1": {"value": 0.4, "min": 0.0, "max": 1.0, "step": 0.01},
		"amplitude2": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
		"amplitude3": {"value": 0.2, "min": 0.0, "max": 1.0, "step": 0.01},
		"overall_amplitude": {"value": 0.35, "min": 0.0, "max": 1.0, "step": 0.01}
	},
	"melodic_drone": {
		"duration": {"value": 5.0, "min": 2.0, "max": 10.0, "step": 0.1},
		"fundamental": {"value": 220.0, "min": 100.0, "max": 500.0, "step": 5.0},
		"tremolo_rate": {"value": 4.0, "min": 0.5, "max": 15.0, "step": 0.1},
		"tremolo_depth": {"value": 0.1, "min": 0.0, "max": 0.5, "step": 0.01},
		"harmonic1_mult": {"value": 1.0, "min": 0.5, "max": 3.0, "step": 0.1},
		"harmonic2_mult": {"value": 1.5, "min": 0.5, "max": 3.0, "step": 0.1},
		"harmonic3_mult": {"value": 2.0, "min": 0.5, "max": 4.0, "step": 0.1},
		"harmonic4_mult": {"value": 3.0, "min": 0.5, "max": 5.0, "step": 0.1},
		"harmonic1_amp": {"value": 0.4, "min": 0.0, "max": 1.0, "step": 0.01},
		"harmonic2_amp": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
		"harmonic3_amp": {"value": 0.2, "min": 0.0, "max": 1.0, "step": 0.01},
		"harmonic4_amp": {"value": 0.1, "min": 0.0, "max": 1.0, "step": 0.01},
		"overall_amplitude": {"value": 0.2, "min": 0.0, "max": 1.0, "step": 0.01}
	},
	"laser_shot": {
		"duration": {"value": 0.8, "min": 0.2, "max": 3.0, "step": 0.1},
		"start_freq": {"value": 2000.0, "min": 500.0, "max": 5000.0, "step": 10.0},
		"end_freq": {"value": 100.0, "min": 50.0, "max": 1000.0, "step": 5.0},
		"attack_time": {"value": 0.05, "min": 0.01, "max": 0.2, "step": 0.01},
		"decay_rate": {"value": 12.0, "min": 3.0, "max": 30.0, "step": 0.5},
		"harmonic_amount": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
		"amplitude": {"value": 0.4, "min": 0.0, "max": 1.0, "step": 0.01},
		"wave_type": {"value": "sawtooth", "options": ["sine", "square", "sawtooth"]}
	},
	"power_up_jingle": {
		"duration": {"value": 1.5, "min": 0.5, "max": 4.0, "step": 0.1},
		"root_note": {"value": 262.0, "min": 130.0, "max": 520.0, "step": 1.0},
		"note_count": {"value": 4, "min": 2, "max": 8, "step": 1},
		"note_decay": {"value": 3.0, "min": 1.0, "max": 8.0, "step": 0.1},
		"harmony_amount": {"value": 0.2, "min": 0.0, "max": 0.8, "step": 0.01},
		"bell_character": {"value": 0.8, "min": 0.0, "max": 1.0, "step": 0.01},
		"amplitude": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
		"scale_type": {"value": "major", "options": ["major", "minor", "pentatonic"]}
	},
	"explosion": {
		"duration": {"value": 2.5, "min": 1.0, "max": 5.0, "step": 0.1},
		"low_rumble_freq": {"value": 30.0, "min": 20.0, "max": 100.0, "step": 1.0},
		"mid_crack_freq": {"value": 400.0, "min": 200.0, "max": 800.0, "step": 10.0},
		"high_sizzle_freq": {"value": 4000.0, "min": 1000.0, "max": 8000.0, "step": 50.0},
		"low_decay": {"value": 1.5, "min": 0.5, "max": 3.0, "step": 0.1},
		"mid_decay": {"value": 8.0, "min": 3.0, "max": 15.0, "step": 0.5},
		"high_decay": {"value": 15.0, "min": 5.0, "max": 30.0, "step": 0.5},
		"low_amount": {"value": 0.6, "min": 0.0, "max": 1.0, "step": 0.01},
		"mid_amount": {"value": 0.4, "min": 0.0, "max": 1.0, "step": 0.01},
		"high_amount": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01},
		"amplitude": {"value": 0.5, "min": 0.0, "max": 1.0, "step": 0.01}
	},
	"retro_jump": {
		"duration": {"value": 0.6, "min": 0.1, "max": 2.0, "step": 0.05},
		"start_freq": {"value": 150.0, "min": 80.0, "max": 300.0, "step": 5.0},
		"peak_freq": {"value": 400.0, "min": 200.0, "max": 800.0, "step": 5.0},
		"curve_amount": {"value": 0.7, "min": 0.3, "max": 1.0, "step": 0.05},
		"attack_time": {"value": 0.05, "min": 0.01, "max": 0.2, "step": 0.01},
		"decay_rate": {"value": 4.0, "min": 1.0, "max": 10.0, "step": 0.1},
		"duty_cycle": {"value": 0.5, "min": 0.1, "max": 0.9, "step": 0.05},
		"duty_mod_rate": {"value": 2.0, "min": 0.5, "max": 8.0, "step": 0.1},
		"amplitude": {"value": 0.35, "min": 0.0, "max": 1.0, "step": 0.01},
		"wave_type": {"value": "square", "options": ["sine", "square", "sawtooth"]}
	},
	"shield_hit": {
		"duration": {"value": 1.2, "min": 0.3, "max": 3.0, "step": 0.1},
		"main_freq": {"value": 800.0, "min": 300.0, "max": 1500.0, "step": 10.0},
		"ring_freq": {"value": 60.0, "min": 20.0, "max": 200.0, "step": 1.0},
		"impact_freq": {"value": 1200.0, "min": 800.0, "max": 2000.0, "step": 10.0},
		"decay_rate": {"value": 6.0, "min": 2.0, "max": 15.0, "step": 0.1},
		"ring_amount": {"value": 0.5, "min": 0.0, "max": 1.0, "step": 0.01},
		"harmonic_amount": {"value": 0.4, "min": 0.0, "max": 1.0, "step": 0.01},
		"impact_amount": {"value": 0.8, "min": 0.0, "max": 1.0, "step": 0.01},
		"amplitude": {"value": 0.3, "min": 0.0, "max": 1.0, "step": 0.01}
	},
	"ambient_wind": {
		"duration": {"value": 8.0, "min": 3.0, "max": 15.0, "step": 0.5},
		"noise_density": {"value": 4, "min": 2, "max": 8, "step": 1},
		"filter_cutoff": {"value": 0.7, "min": 0.3, "max": 1.0, "step": 0.05},
		"gust_rate1": {"value": 0.2, "min": 0.05, "max": 1.0, "step": 0.05},
		"gust_rate2": {"value": 0.07, "min": 0.02, "max": 0.5, "step": 0.01},
		"tonal_freq1": {"value": 80.0, "min": 40.0, "max": 200.0, "step": 2.0},
		"tonal_freq2": {"value": 120.0, "min": 60.0, "max": 300.0, "step": 2.0},
		"tonal_amount": {"value": 0.1, "min": 0.0, "max": 0.5, "step": 0.01},
		"amplitude": {"value": 0.2, "min": 0.0, "max": 1.0, "step": 0.01}
	}
}

# Sound theory database - educational content for each sound type
var sound_theory = {
	"basic_sine_wave": {
		"title": "🌊 Basic Sine Wave - The Pure Tone",
		"difficulty": "Beginner",
		"duration": "5-10 minutes",
		"description": "The fundamental building block of all sound. A sine wave represents pure frequency with no harmonics.",
		"theory": """
<b>Mathematical Foundation:</b>
A sine wave is described by: amplitude × sin(2π × frequency × time)

<b>Key Concepts:</b>
• <b>Frequency</b>: How many cycles per second (Hz). 440Hz = Musical note A4
• <b>Amplitude</b>: Volume/loudness of the sound (0.0 to 1.0)
• <b>Duration</b>: How long the sound plays
• <b>Fade In/Out</b>: Smooth transitions to prevent audio clicks

<b>Real-World Applications:</b>
• Tuning forks create nearly pure sine waves
• Musical instruments combine multiple sine waves (harmonics)
• Test tones for audio equipment calibration
• Basic building block for synthesizers

<b>Interactive Challenge:</b>
Try changing frequency from 220Hz to 880Hz - notice how pitch rises by octaves!
		""",
		"exercises": [
			{"task": "Set frequency to 440Hz (Musical A)", "params": {"frequency": 440.0}},
			{"task": "Create a low bass tone (60Hz)", "params": {"frequency": 60.0}},
			{"task": "Make a high whistle (2000Hz)", "params": {"frequency": 2000.0}},
			{"task": "Add a 0.5 second fade-in", "params": {"fade_in_time": 0.5}}
		]
	},
	"pickup_mario": {
		"title": "🪙 Mario Pickup - The Rising Frequency Sweep",
		"difficulty": "Beginner-Intermediate", 
		"duration": "10-15 minutes",
		"description": "Classic video game pickup sound using frequency modulation and envelope shaping.",
		"theory": """
<b>Synthesis Technique: Frequency Sweep + Exponential Decay</b>

<b>Key Concepts:</b>
• <b>Start/End Frequency</b>: Creates the characteristic "rising" sound
• <b>Decay Rate</b>: How quickly the sound fades (exponential curve)
• <b>Wave Type</b>: Square/sawtooth for retro "8-bit" character
• <b>Envelope</b>: Sharp attack, quick decay = percussive sound

<b>Audio Engineering Principles:</b>
• Frequency modulation creates excitement and energy
• Square waves contain odd harmonics (1st, 3rd, 5th...)
• Exponential decay mimics natural sound behavior
• Short duration prevents ear fatigue in games

<b>Game Audio Psychology:</b>
• Rising pitch = positive reward feeling
• Quick decay = doesn't interfere with gameplay
• Recognizable retro character = nostalgic appeal

<b>Try This:</b>
Reverse the frequencies (start high, end low) - notice how it feels negative!
		""",
		"exercises": [
			{"task": "Classic Mario sound (440→880Hz)", "params": {"start_freq": 440.0, "end_freq": 880.0}},
			{"task": "Modern game pickup (higher range)", "params": {"start_freq": 800.0, "end_freq": 1600.0}},
			{"task": "Sad pickup (descending)", "params": {"start_freq": 880.0, "end_freq": 440.0}},
			{"task": "Quick arcade blip (fast decay)", "params": {"decay_rate": 15.0}}
		]
	},
	"teleport_drone": {
		"title": "⚡ Teleport Drone - Modulated Synthesis",
		"difficulty": "Intermediate",
		"duration": "15-20 minutes", 
		"description": "Complex synthetic drone using frequency modulation, noise, and dynamic envelopes.",
		"theory": """
<b>Advanced Synthesis: Frequency Modulation + Noise Generation</b>

<b>Technical Components:</b>
• <b>Base Frequency</b>: The fundamental tone (carrier)
• <b>Modulation</b>: LFO (Low Frequency Oscillator) creates wobble
• <b>Modulation Depth</b>: How extreme the frequency changes
• <b>Noise Amount</b>: Adds texture and "electricity" feeling
• <b>Complex Envelope</b>: Fade in → sustain → fade out → silence

<b>Sound Design Principles:</b>
• Sawtooth waves = harsh, synthetic character
• Frequency modulation = movement and life
• Noise = unpredictability and energy
• Envelope prevents audio clicks and smooths transitions

<b>Science Fiction Audio:</b>
• Teleportation needs to sound "otherworldly"
• Modulation suggests energy/power fluctuation
• Noise implies electrical interference
• Duration long enough to convey "process happening"

<b>Advanced Technique:</b>
The envelope uses smoothstep function for professional-quality fades.
		""",
		"exercises": [
			{"task": "Slow energy buildup (0.5Hz mod)", "params": {"mod_freq": 0.5}},
			{"task": "Fast electrical buzz (3.0Hz mod)", "params": {"mod_freq": 3.0}},
			{"task": "Clean sci-fi tone (no noise)", "params": {"noise_amount": 0.0}},
			{"task": "Chaotic energy (high noise)", "params": {"noise_amount": 0.5}}
		]
	},
	"lift_bass_pulse": {
		"title": "🎵 Bass Pulse - Rhythm and Low Frequency",
		"difficulty": "Intermediate",
		"duration": "10-15 minutes",
		"description": "Mechanical pulse using low-frequency oscillation and rhythmic modulation.",
		"theory": """
<b>Mechanical Audio Design: Rhythm + Low Frequency Response</b>

<b>Bass Frequency Science:</b>
• <b>Base Frequency</b>: 20-100Hz range felt more than heard
• <b>Pulse Rate</b>: Creates rhythmic pattern (like heartbeat/engine)
• <b>Decay Rate</b>: How mechanical energy dissipates
• <b>Psychoacoustic Effect</b>: Low frequencies create physical sensations

<b>Pulse Modulation:</b>
• Uses absolute value of sine wave: abs(sin(x))
• Creates rhythmic on/off pattern
• Mimics mechanical systems (pistons, engines, pumps)
• Exponential decay simulates energy loss over time

<b>Game Audio Applications:</b>
• Elevator/lift machinery sounds
• Mechanical ambience
• Industrial environments
• Low-frequency UI feedback

<b>Audio Engineering:</b>
• Low frequencies require more power to produce
• Sub-bass content can overload small speakers
• Always test on different playback systems
		""",
		"exercises": [
			{"task": "Slow machinery (1Hz pulse)", "params": {"pulse_rate": 1.0}},
			{"task": "Fast engine (4Hz pulse)", "params": {"pulse_rate": 4.0}},
			{"task": "Deep sub-bass (40Hz)", "params": {"base_freq": 40.0}},
			{"task": "Quick mechanical tap", "params": {"decay_rate": 5.0}}
		]
	},
	"ghost_drone": {
		"title": "👻 Ghost Drone - Harmonic Layering",
		"difficulty": "Intermediate-Advanced",
		"duration": "15-20 minutes",
		"description": "Atmospheric drone using multiple harmonic layers and tremolo modulation.",
		"theory": """
<b>Advanced Harmonic Synthesis: Multiple Oscillator Layering</b>

<b>Harmonic Theory:</b>
• <b>Multiple Frequencies</b>: Creates rich, complex timbres
• <b>Frequency Relationships</b>: 110Hz, 165Hz, 220Hz (musical intervals)
• <b>Amplitude Control</b>: Each layer has independent volume
• <b>Tremolo Modulation</b>: Overall amplitude variation creates "ghostly" effect

<b>Musical Mathematics:</b>
• 110Hz = A2 (fundamental)
• 165Hz = E3 (perfect fifth above)
• 220Hz = A3 (octave above fundamental)
• These create a harmonious, ethereal chord

<b>Atmospheric Sound Design:</b>
• Multiple layers = depth and complexity
• Slow modulation = organic, breathing quality
• Harmonic relationships = musical pleasantness
• Moderate amplitude = background ambience

<b>Advanced Concepts:</b>
• Additive synthesis (combining pure tones)
• Harmonic series and musical intervals
• Tremolo vs. vibrato (amplitude vs. frequency modulation)
		""",
		"exercises": [
			{"task": "Simple harmonic (equal amplitudes)", "params": {"amplitude1": 0.3, "amplitude2": 0.3, "amplitude3": 0.3}},
			{"task": "Fundamental emphasis", "params": {"amplitude1": 0.5, "amplitude2": 0.2, "amplitude3": 0.1}},
			{"task": "Fast breathing (6 cycles)", "params": {"mod_cycles": 6.0}},
			{"task": "Slow meditation (1 cycle)", "params": {"mod_cycles": 1.0}}
		]
	},
	"melodic_drone": {
		"title": "🎶 Melodic Drone - Complex Harmonic Synthesis",
		"difficulty": "Advanced",
		"duration": "20-30 minutes",
		"description": "Professional-grade synthesis with harmonic control, tremolo, and musical tuning.",
		"theory": """
<b>Professional Synthesizer Design: Full Harmonic Control</b>

<b>Advanced Harmonic Series:</b>
• <b>Fundamental</b>: Base frequency (220Hz = A3)
• <b>Harmonic Multipliers</b>: 1.0, 1.5, 2.0, 3.0 (musical ratios)
• <b>Individual Amplitudes</b>: Precise control over each harmonic
• <b>Tremolo System</b>: Rate and depth for organic modulation

<b>Music Theory Integration:</b>
• Harmonic ratios create musical intervals
• 1.5 = Perfect Fifth (musical consonance)
• 2.0 = Octave (frequency doubling)
• 3.0 = Perfect Fifth + Octave
• Complex timbres from simple mathematical relationships

<b>Professional Synthesis Concepts:</b>
• Additive synthesis with harmonic control
• Tremolo modulation for musical expression
• Amplitude envelope shaping
• Harmonic balance for timbral design

<b>Real-World Applications:</b>
• Synthesizer programming
• Music composition and sound design
• Understanding acoustic instrument harmonic content
• Electronic music production techniques
		""",
		"exercises": [
			{"task": "Organ-like tone (strong harmonics)", "params": {"harmonic2_amp": 0.4, "harmonic3_amp": 0.3}},
			{"task": "Flute-like (fundamental only)", "params": {"harmonic1_amp": 0.8, "harmonic2_amp": 0.1}},
			{"task": "String-like (rich harmonics)", "params": {"harmonic1_amp": 0.4, "harmonic2_amp": 0.3, "harmonic3_amp": 0.2, "harmonic4_amp": 0.1}},
			{"task": "Slow vibrato (musical tremolo)", "params": {"tremolo_rate": 6.0, "tremolo_depth": 0.2}}
		]
	}
}

# UI Control References
var parameter_controls: Dictionary = {}
var value_labels: Dictionary = {}

# Visualization components
var waveform_display: Control
var spectrum_display: Control
var visualization_container: HBoxContainer

# Visualization data
var current_waveform_data: PackedFloat32Array
var current_spectrum_data: PackedFloat32Array
var visualization_sample_count: int = 256
var spectrum_bands: int = 64

func _ready():
	setup_ui()
	setup_audio_player()
	setup_realtime_timer()
	load_parameters_from_files()  # Load from JSON files
	populate_sound_types()
	connect_signals()  # Connect signals before creating parameter controls
	create_parameter_controls()
	
	# Initialize visualization data
	initialize_visualizations()

func connect_signals():
	# Connect signals after UI is created
	print("🔌 Connecting signals...")
	
	if sound_type_option:
		sound_type_option.item_selected.connect(_on_sound_type_changed)
		print("✅ Sound type option connected")
	else:
		print("❌ Sound type option not found")
		
	if preview_button:
		preview_button.pressed.connect(_on_preview_pressed)
		print("✅ Preview button connected")
	else:
		print("❌ Preview button not found")
		
	if stop_button:
		stop_button.pressed.connect(_on_stop_pressed)
		print("✅ Stop button connected")
	else:
		print("❌ Stop button not found")
		
	if save_button:
		save_button.pressed.connect(_on_save_pressed)
		print("✅ Save button connected")
	else:
		print("❌ Save button not found")
		
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
		print("✅ Load button connected")
	else:
		print("❌ Load button not found")
		
	if export_button:
		export_button.pressed.connect(_on_export_pressed)
		print("✅ Export button connected")
	else:
		print("❌ Export button not found")
		
	if realtime_toggle:
		realtime_toggle.toggled.connect(_on_realtime_toggled)
		print("✅ Realtime toggle connected")
	else:
		print("❌ Realtime toggle not found")
		
	# Connect copy JSON button
	var copy_json_button = get_node_or_null("VBox/Controls/CopyJsonButton")
	if copy_json_button:
		copy_json_button.pressed.connect(_show_json_popup)
		print("✅ Copy JSON button connected")
	else:
		print("❌ Copy JSON button not found")

func setup_ui():
	custom_minimum_size = Vector2(900, 700)
	
	# Create main layout with margins
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 15)
	# Add margins to the main container
	vbox.offset_left = 20
	vbox.offset_top = 20
	vbox.offset_right = -20
	vbox.offset_bottom = -20
	add_child(vbox)
	
	# Title with background (smaller size)
	var title = Label.new()
	title.text = "🎵 Sound Designer Interface"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.WHITE)
	# Add background to title
	var title_bg = StyleBoxFlat.new()
	title_bg.bg_color = Color(0.2, 0.2, 0.3, 1.0)
	title_bg.corner_radius_top_left = 8
	title_bg.corner_radius_top_right = 8
	title_bg.corner_radius_bottom_left = 8
	title_bg.corner_radius_bottom_right = 8
	title_bg.content_margin_top = 6
	title_bg.content_margin_bottom = 6
	title.add_theme_stylebox_override("normal", title_bg)
	vbox.add_child(title)
	
	# Sound Selection Section with background
	var sound_selection = HBoxContainer.new()
	sound_selection.name = "SoundSelection"
	sound_selection.add_theme_constant_override("separation", 10)
	# Add background panel
	var selection_bg = StyleBoxFlat.new()
	selection_bg.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	selection_bg.corner_radius_top_left = 5
	selection_bg.corner_radius_top_right = 5
	selection_bg.corner_radius_bottom_left = 5
	selection_bg.corner_radius_bottom_right = 5
	selection_bg.content_margin_left = 10
	selection_bg.content_margin_right = 10
	selection_bg.content_margin_top = 10
	selection_bg.content_margin_bottom = 10
	sound_selection.add_theme_stylebox_override("panel", selection_bg)
	vbox.add_child(sound_selection)
	
	var label = Label.new()
	label.text = "Sound Type:"
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.custom_minimum_size.x = 100
	sound_selection.add_child(label)
	
	sound_type_option = OptionButton.new()
	sound_type_option.name = "SoundTypeOption"
	sound_type_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sound_type_option.custom_minimum_size = Vector2(200, 30)
	sound_selection.add_child(sound_type_option)
	
	preview_button = Button.new()
	preview_button.name = "PreviewButton"
	preview_button.text = "🔊 Preview"
	preview_button.custom_minimum_size = Vector2(100, 30)
	# Style the preview button
	var preview_style = StyleBoxFlat.new()
	preview_style.bg_color = Color(0.2, 0.6, 0.2, 1.0)
	preview_style.corner_radius_top_left = 5
	preview_style.corner_radius_top_right = 5
	preview_style.corner_radius_bottom_left = 5
	preview_style.corner_radius_bottom_right = 5
	preview_button.add_theme_stylebox_override("normal", preview_style)
	sound_selection.add_child(preview_button)
	
	stop_button = Button.new()
	stop_button.name = "StopButton"
	stop_button.text = "⏹️ Stop"
	stop_button.custom_minimum_size = Vector2(80, 30)
	# Style the stop button
	var stop_style = StyleBoxFlat.new()
	stop_style.bg_color = Color(0.6, 0.2, 0.2, 1.0)
	stop_style.corner_radius_top_left = 5
	stop_style.corner_radius_top_right = 5
	stop_style.corner_radius_bottom_left = 5
	stop_style.corner_radius_bottom_right = 5
	stop_button.add_theme_stylebox_override("normal", stop_style)
	sound_selection.add_child(stop_button)
	
	# Controls Section with background
	var controls = HBoxContainer.new()
	controls.name = "Controls"
	controls.add_theme_constant_override("separation", 10)
	# Add background panel
	var controls_bg = StyleBoxFlat.new()
	controls_bg.bg_color = Color(0.15, 0.15, 0.2, 1.0)
	controls_bg.corner_radius_top_left = 5
	controls_bg.corner_radius_top_right = 5
	controls_bg.corner_radius_bottom_left = 5
	controls_bg.corner_radius_bottom_right = 5
	controls_bg.content_margin_left = 10
	controls_bg.content_margin_right = 10
	controls_bg.content_margin_top = 10
	controls_bg.content_margin_bottom = 10
	controls.add_theme_stylebox_override("panel", controls_bg)
	vbox.add_child(controls)
	
	realtime_toggle = CheckBox.new()
	realtime_toggle.name = "RealtimeToggle"
	realtime_toggle.text = "Real-time Updates"
	realtime_toggle.button_pressed = true
	realtime_toggle.add_theme_color_override("font_color", Color.WHITE)
	controls.add_child(realtime_toggle)
	
	var separator = VSeparator.new()
	separator.custom_minimum_size.x = 2
	controls.add_child(separator)
	
	save_button = Button.new()
	save_button.name = "SaveButton"
	save_button.text = "💾 Save Preset"
	save_button.custom_minimum_size = Vector2(120, 30)
	controls.add_child(save_button)
	
	load_button = Button.new()
	load_button.name = "LoadButton"
	load_button.text = "📂 Load Preset"
	load_button.custom_minimum_size = Vector2(120, 30)
	controls.add_child(load_button)
	
	export_button = Button.new()
	export_button.name = "ExportButton"
	export_button.text = "📤 Export Sound"
	export_button.custom_minimum_size = Vector2(130, 30)
	controls.add_child(export_button)
	
	var copy_json_button = Button.new()
	copy_json_button.name = "CopyJsonButton"
	copy_json_button.text = "📋 Copy JSON"
	copy_json_button.custom_minimum_size = Vector2(100, 30)
	# Style the copy JSON button
	var copy_style = StyleBoxFlat.new()
	copy_style.bg_color = Color(0.4, 0.3, 0.6, 1.0)  # Purple
	copy_style.corner_radius_top_left = 5
	copy_style.corner_radius_top_right = 5
	copy_style.corner_radius_bottom_left = 5
	copy_style.corner_radius_bottom_right = 5
	copy_json_button.add_theme_stylebox_override("normal", copy_style)
	controls.add_child(copy_json_button)
	
	# Visualization Section
	var viz_section = create_visualization_section()
	vbox.add_child(viz_section)
	
	# Scrollable Parameters Container
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 300)  # Reduced height to make room for visualizations
	# Style the scroll container
	var scroll_bg = StyleBoxFlat.new()
	scroll_bg.bg_color = Color(0.1, 0.1, 0.15, 1.0)
	scroll_bg.corner_radius_top_left = 5
	scroll_bg.corner_radius_top_right = 5
	scroll_bg.corner_radius_bottom_left = 5
	scroll_bg.corner_radius_bottom_right = 5
	scroll.add_theme_stylebox_override("panel", scroll_bg)
	vbox.add_child(scroll)
	
	parameters_container = VBoxContainer.new()
	parameters_container.name = "ParametersContainer"
	parameters_container.add_theme_constant_override("separation", 12)
	parameters_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(parameters_container)
	
	print("✅ UI setup complete - all elements created")

func load_parameters_from_files():
	"""Load sound parameters from JSON files in the restructured directories"""
	print("📂 Loading sound parameters from JSON files...")
	
	# Use the enhanced parameter loader to get all parameters
	var loaded_params = EnhancedParameterLoader.load_all_parameters()
	
	if loaded_params.size() > 0:
		# Replace the hardcoded parameters with loaded ones
		sound_parameters = loaded_params
		print("✅ Loaded %d sound parameter sets from JSON files" % sound_parameters.size())
	else:
		print("⚠️ No parameters loaded from JSON, keeping hardcoded defaults")

func create_visualization_section() -> VBoxContainer:
	"""Create the waveform and spectrum visualization section"""
	var section = VBoxContainer.new()
	section.name = "VisualizationSection"
	section.add_theme_constant_override("separation", 10)
	
	# No header - visualization speaks for itself
	
	# Visualization container
	visualization_container = HBoxContainer.new()
	visualization_container.add_theme_constant_override("separation", 15)
	visualization_container.custom_minimum_size = Vector2(0, 200)
	section.add_child(visualization_container)
	
	# Waveform display
	waveform_display = create_waveform_display()
	visualization_container.add_child(waveform_display)
	
	# Spectrum display
	spectrum_display = create_spectrum_display()
	visualization_container.add_child(spectrum_display)
	
	return section

func create_waveform_display() -> Control:
	"""Create the waveform (time domain) display"""
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 5)
	
	# Title
	var title = Label.new()
	title.text = "🌊 Waveform (Time Domain)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.CYAN)
	container.add_child(title)
	
	# Waveform canvas
	var canvas = Control.new()
	canvas.name = "WaveformCanvas"
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.custom_minimum_size = Vector2(300, 150)
	
	# Style the canvas
	var canvas_bg = StyleBoxFlat.new()
	canvas_bg.bg_color = Color(0.05, 0.05, 0.1, 1.0)
	canvas_bg.corner_radius_top_left = 5
	canvas_bg.corner_radius_top_right = 5
	canvas_bg.corner_radius_bottom_left = 5
	canvas_bg.corner_radius_bottom_right = 5
	canvas_bg.border_color = Color.CYAN
	canvas_bg.border_width_top = 1
	canvas_bg.border_width_bottom = 1
	canvas_bg.border_width_left = 1
	canvas_bg.border_width_right = 1
	canvas.add_theme_stylebox_override("panel", canvas_bg)
	
	container.add_child(canvas)
	
	# Connect drawing signal
	canvas.draw.connect(_draw_waveform.bind(canvas))
	
	return container

func create_spectrum_display() -> Control:
	"""Create the spectrum (frequency domain) display"""
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 5)
	
	# Title
	var title = Label.new()
	title.text = "📡 Spectrum (Frequency Domain)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.GREEN)
	container.add_child(title)
	
	# Spectrum canvas
	var canvas = Control.new()
	canvas.name = "SpectrumCanvas"
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.custom_minimum_size = Vector2(300, 150)
	
	# Style the canvas
	var canvas_bg = StyleBoxFlat.new()
	canvas_bg.bg_color = Color(0.05, 0.1, 0.05, 1.0)
	canvas_bg.corner_radius_top_left = 5
	canvas_bg.corner_radius_top_right = 5
	canvas_bg.corner_radius_bottom_left = 5
	canvas_bg.corner_radius_bottom_right = 5
	canvas_bg.border_color = Color.GREEN
	canvas_bg.border_width_top = 1
	canvas_bg.border_width_bottom = 1
	canvas_bg.border_width_left = 1
	canvas_bg.border_width_right = 1
	canvas.add_theme_stylebox_override("panel", canvas_bg)
	
	container.add_child(canvas)
	
	# Connect drawing signal
	canvas.draw.connect(_draw_spectrum.bind(canvas))
	
	return container

func setup_audio_player():
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "AudioPlayer"
	add_child(audio_player)
	# Connect the finished signal to loop the audio in real-time mode
	audio_player.finished.connect(_on_audio_finished)

func setup_realtime_timer():
	update_timer = Timer.new()
	update_timer.wait_time = 0.05  # Faster updates - every 50ms
	update_timer.timeout.connect(_on_realtime_update)
	update_timer.one_shot = false  # Continuous timer
	add_child(update_timer)
	update_timer.start()
	print("⏰ Real-time timer started (50ms intervals)")

func populate_sound_types():
	if not sound_type_option:
		print("❌ Sound type option not ready yet")
		return
		
	sound_type_option.clear()
	
	# Create display names with emojis for all loaded sounds
	for sound_key in sound_parameters.keys():
		var display_name = _create_display_name_with_emoji(sound_key)
		sound_type_option.add_item(display_name)
	
	print("🎵 Populated %d sound types from loaded parameters" % sound_parameters.size())

func _create_display_name_with_emoji(sound_key: String) -> String:
	"""Create a display name with emoji for a sound key"""
	var display_name = sound_key.capitalize().replace("_", " ")
	
	# Add emoji based on sound type keywords
	var emoji_map = {
		"kick": "🥁", "808": "🥁", "drum": "🥁", "909": "🥁", "linn": "🥁",
		"hihat": "🔥", "hat": "🔥", "606": "🔥",
		"bass": "🎵", "sub": "🎵",
		"drone": "🌌", "ambient": "🌌", "amiga": "🌌",
		"laser": "🔫", "shot": "🔫",
		"pickup": "🪙", "mario": "🪙",
		"explosion": "💥", "bomb": "💥",
		"jump": "🟢", "retro": "🟢",
		"shield": "🛡️", "hit": "🛡️",
		"wind": "🌬️", "atmospheric": "🌬️",
		"sine": "〰️", "basic": "〰️",
		"disco": "🕺", "tom": "🥁", "synare": "🥁",
		"cosmic": "🛸", "fx": "🌌", "ufo": "🛸", "space": "🚀",
		"moog": "🎹", "kraftwerk": "🤖", "sequencer": "🎼", "analog": "🎛️",
		"herbie": "🎺", "hancock": "🎹", "fusion": "🌟", "jazz": "🎷",
		"aphex": "🔬", "twin": "🎛️", "modular": "🔧", "experimental": "⚗️",
		"flying": "🚁", "lotus": "🪷", "sampler": "🎛️", "beats": "🥁",
		"dx7": "⚡", "electric": "⚡", "piano": "🎹",
		"tb303": "🔊", "acid": "🔊",
		"c64": "💾", "sid": "💾", "gameboy": "🎮", "dmg": "🎮",
		"jupiter": "🪐", "strings": "🎻",
		"arp": "⚡", "2600": "⚡", "lead": "🎤",
		"ppg": "🌊", "wave": "🌊", "pad": "🌊",
		"teleport": "⚡", "power": "⭐", "melodic": "🎶", "ghost": "👻", "lift": "🔄"
	}
	
	for keyword in emoji_map.keys():
		if sound_key.to_lower().contains(keyword):
			display_name = emoji_map[keyword] + " " + display_name
			break
	
	return display_name

func create_parameter_controls():
	if not parameters_container:
		print("❌ Parameters container not ready yet")
		return
		
	# Clear existing controls
	for child in parameters_container.get_children():
		child.queue_free()
	parameter_controls.clear()
	value_labels.clear()
	
	var params = sound_parameters[current_sound_key]
	
	# Create smaller title
	var title = Label.new()
	title.text = "🎛️ Parameters"
	title.add_theme_font_size_override("font_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parameters_container.add_child(title)
	
	# Create column container for better space usage
	var columns_container = HBoxContainer.new()
	columns_container.add_theme_constant_override("separation", 15)
	columns_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parameters_container.add_child(columns_container)
	
	# Create 3 columns for parameters
	var column1 = VBoxContainer.new()
	var column2 = VBoxContainer.new()
	var column3 = VBoxContainer.new()
	
	column1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	column1.add_theme_constant_override("separation", 8)
	column2.add_theme_constant_override("separation", 8)
	column3.add_theme_constant_override("separation", 8)
	
	columns_container.add_child(column1)
	columns_container.add_child(column2)
	columns_container.add_child(column3)
	
	# Wait a frame for UI to update, then create controls
	await get_tree().process_frame
	
	# Distribute parameters across columns
	var param_names = params.keys()
	var columns = [column1, column2, column3]
	
	for i in range(param_names.size()):
		var param_name = param_names[i]
		var param_config = params[param_name]
		var column_index = i % 3  # Distribute evenly across 3 columns
		create_parameter_control_in_column(columns[column_index], param_name, param_config)

func create_parameter_control_in_column(column: VBoxContainer, param_name: String, param_config: Dictionary):
	"""Create a parameter control in the specified column"""
	var main_container = VBoxContainer.new()
	main_container.add_theme_constant_override("separation", 3)
	
	# Add background to parameter group (smaller padding for compact layout)
	var param_bg = StyleBoxFlat.new()
	param_bg.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	param_bg.corner_radius_top_left = 4
	param_bg.corner_radius_top_right = 4
	param_bg.corner_radius_bottom_left = 4
	param_bg.corner_radius_bottom_right = 4
	param_bg.content_margin_left = 8
	param_bg.content_margin_right = 8
	param_bg.content_margin_top = 6
	param_bg.content_margin_bottom = 6
	main_container.add_theme_stylebox_override("panel", param_bg)
	
	column.add_child(main_container)
	
	# Header with name and value (more compact)
	var header_container = VBoxContainer.new()
	header_container.add_theme_constant_override("separation", 2)
	main_container.add_child(header_container)
	
	# Parameter label
	var label = Label.new()
	label.text = param_name.capitalize().replace("_", " ")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color.WHITE)
	header_container.add_child(label)
	
	# Value label
	var value_label = Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 10)
	value_label.add_theme_color_override("font_color", Color.CYAN)
	header_container.add_child(value_label)
	value_labels[param_name] = value_label
	
	# Control container
	var control_container = VBoxContainer.new()
	main_container.add_child(control_container)
	
	# Parameter control based on type
	if param_config.has("options"):
		create_option_control_compact(control_container, param_name, param_config)
	else:
		create_slider_control_compact(control_container, param_name, param_config)
	
	print("✅ Created compact parameter control for: %s" % param_name)

func create_parameter_control(param_name: String, param_config: Dictionary):
	# Legacy function - now redirects to column version
	print("⚠️ Legacy create_parameter_control called - use create_parameter_control_in_column instead")

func create_slider_control_compact(container: VBoxContainer, param_name: String, config: Dictionary):
	"""Create a compact slider control for column layout"""
	# Defensive check for parameter structure
	if not config is Dictionary:
		print("❌ Invalid config for %s: %s" % [param_name, config])
		return
	
	var slider = HSlider.new()
	slider.min_value = config.get("min", 0.0)
	slider.max_value = config.get("max", 1.0)
	slider.step = config.get("step", 0.01)
	slider.value = config.get("value", 0.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(150, 20)  # Smaller compact size
	
	# Style the slider with better visibility
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = Color(0.3, 0.3, 0.4, 1.0)
	slider_style.corner_radius_top_left = 3
	slider_style.corner_radius_top_right = 3
	slider_style.corner_radius_bottom_left = 3
	slider_style.corner_radius_bottom_right = 3
	slider.add_theme_stylebox_override("slider", slider_style)
	
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color(0.6, 0.8, 1.0, 1.0)
	grabber_style.corner_radius_top_left = 6
	grabber_style.corner_radius_top_right = 6
	grabber_style.corner_radius_bottom_left = 6
	grabber_style.corner_radius_bottom_right = 6
	slider.add_theme_stylebox_override("grabber_area", grabber_style)
	
	# Connect the signal with proper lambda function
	slider.value_changed.connect(func(value): _on_slider_changed(param_name, value))
	print("🎛️ Created compact slider for %s (%.2f to %.2f, current: %.2f)" % [param_name, slider.min_value, slider.max_value, slider.value])
	
	container.add_child(slider)
	parameter_controls[param_name] = slider
	
	# Update value label
	update_value_label(param_name, slider.value)

func create_option_control_compact(container: VBoxContainer, param_name: String, config: Dictionary):
	"""Create a compact option control for column layout"""
	var option_button = OptionButton.new()
	var options = config.get("options", [])
	var current_value = config.get("value", "")
	
	option_button.custom_minimum_size = Vector2(150, 25)  # Compact size
	
	for option in options:
		option_button.add_item(option)
	
	# Select current value
	for i in range(option_button.get_item_count()):
		if option_button.get_item_text(i) == current_value:
			option_button.selected = i
			break
	
	option_button.item_selected.connect(func(index): _on_option_changed(param_name, index))
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(option_button)
	parameter_controls[param_name] = option_button
	
	print("🎛️ Created compact option control for %s (options: %s, current: %s)" % [param_name, options, current_value])
	print("🔗 Signal connected for %s option control (FIXED LAMBDA)" % param_name)
	
	# Update value label
	update_value_label(param_name, current_value)

func create_slider_control(container: HBoxContainer, param_name: String, config: Dictionary):
	var slider = HSlider.new()
	slider.min_value = config.get("min", 0.0)
	slider.max_value = config.get("max", 1.0)
	slider.step = config.get("step", 0.01)
	slider.value = config.get("value", 0.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(250, 25)  # Ensure minimum size
	
	# Style the slider with better visibility
	var slider_style = StyleBoxFlat.new()
	slider_style.bg_color = Color(0.3, 0.3, 0.4, 1.0)
	slider_style.corner_radius_top_left = 3
	slider_style.corner_radius_top_right = 3
	slider_style.corner_radius_bottom_left = 3
	slider_style.corner_radius_bottom_right = 3
	slider.add_theme_stylebox_override("slider", slider_style)
	
	var grabber_style = StyleBoxFlat.new()
	grabber_style.bg_color = Color(0.6, 0.8, 1.0, 1.0)
	grabber_style.corner_radius_top_left = 8
	grabber_style.corner_radius_top_right = 8
	grabber_style.corner_radius_bottom_left = 8
	grabber_style.corner_radius_bottom_right = 8
	slider.add_theme_stylebox_override("grabber_area", grabber_style)
	
	# Connect the signal with proper lambda function
	slider.value_changed.connect(func(value): _on_slider_changed(param_name, value))
	print("🎛️ Created slider for %s (%.2f to %.2f, current: %.2f)" % [param_name, slider.min_value, slider.max_value, slider.value])
	print("🔗 Signal connected for %s slider" % param_name)
	
	container.add_child(slider)
	parameter_controls[param_name] = slider
	
	# Update value label
	update_value_label(param_name, slider.value)

func create_option_control(container: HBoxContainer, param_name: String, config: Dictionary):
	var option_button = OptionButton.new()
	var options = config.get("options", [])
	var current_value = config.get("value", "")
	
	for option in options:
		option_button.add_item(option)
	
	# Select current value
	for i in range(option_button.get_item_count()):
		if option_button.get_item_text(i) == current_value:
			option_button.selected = i
			break
	
	option_button.item_selected.connect(func(index): _on_option_changed(param_name, index))
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(option_button)
	parameter_controls[param_name] = option_button
	
	# Update value label
	update_value_label(param_name, current_value)

func update_value_label(param_name: String, value):
	print("📝 Updating value label for %s with value: %s" % [param_name, value])
	if value_labels.has(param_name):
		var label = value_labels[param_name]
		if value is float:
			label.text = "%.2f" % value
		else:
			label.text = str(value)
		print("✅ Updated %s = %s" % [param_name, label.text])  # Debug output
	else:
		print("❌ No value label found for parameter: %s" % param_name)
		print("🔍 Available value labels: %s" % value_labels.keys())

func get_sound_key_from_type(sound_type: AudioSynthesizer.SoundType) -> String:
	match sound_type:
		AudioSynthesizer.SoundType.BASIC_SINE_WAVE:
			return "basic_sine_wave"
		AudioSynthesizer.SoundType.PICKUP_MARIO:
			return "pickup_mario"
		AudioSynthesizer.SoundType.TELEPORT_DRONE:
			return "teleport_drone"
		AudioSynthesizer.SoundType.LIFT_BASS_PULSE:
			return "lift_bass_pulse"
		AudioSynthesizer.SoundType.GHOST_DRONE:
			return "ghost_drone"
		AudioSynthesizer.SoundType.MELODIC_DRONE:
			return "melodic_drone"
		AudioSynthesizer.SoundType.LASER_SHOT:
			return "laser_shot"
		AudioSynthesizer.SoundType.POWER_UP_JINGLE:
			return "power_up_jingle"
		AudioSynthesizer.SoundType.EXPLOSION:
			return "explosion"
		AudioSynthesizer.SoundType.RETRO_JUMP:
			return "retro_jump"
		AudioSynthesizer.SoundType.SHIELD_HIT:
			return "shield_hit"
		AudioSynthesizer.SoundType.AMBIENT_WIND:
			return "ambient_wind"
		_:
			return "basic_sine_wave"

func get_type_from_sound_key(sound_key: String) -> AudioSynthesizer.SoundType:
	match sound_key:
		"basic_sine_wave":
			return AudioSynthesizer.SoundType.BASIC_SINE_WAVE
		"pickup_mario":
			return AudioSynthesizer.SoundType.PICKUP_MARIO
		"teleport_drone":
			return AudioSynthesizer.SoundType.TELEPORT_DRONE
		"lift_bass_pulse":
			return AudioSynthesizer.SoundType.LIFT_BASS_PULSE
		"ghost_drone":
			return AudioSynthesizer.SoundType.GHOST_DRONE
		"melodic_drone":
			return AudioSynthesizer.SoundType.MELODIC_DRONE
		"laser_shot":
			return AudioSynthesizer.SoundType.LASER_SHOT
		"power_up_jingle":
			return AudioSynthesizer.SoundType.POWER_UP_JINGLE
		"explosion":
			return AudioSynthesizer.SoundType.EXPLOSION
		"retro_jump":
			return AudioSynthesizer.SoundType.RETRO_JUMP
		"shield_hit":
			return AudioSynthesizer.SoundType.SHIELD_HIT
		"ambient_wind":
			return AudioSynthesizer.SoundType.AMBIENT_WIND
		_:
			return AudioSynthesizer.SoundType.BASIC_SINE_WAVE

func get_sound_name_from_type(type: AudioSynthesizer.SoundType) -> String:
	match type:
		AudioSynthesizer.SoundType.BASIC_SINE_WAVE:
			return "Basic Sine Wave"
		AudioSynthesizer.SoundType.PICKUP_MARIO:
			return "Mario Pickup"
		AudioSynthesizer.SoundType.TELEPORT_DRONE:
			return "Teleport Drone"
		AudioSynthesizer.SoundType.LIFT_BASS_PULSE:
			return "Bass Pulse"
		AudioSynthesizer.SoundType.GHOST_DRONE:
			return "Ghost Drone"
		AudioSynthesizer.SoundType.MELODIC_DRONE:
			return "Melodic Drone"
		AudioSynthesizer.SoundType.LASER_SHOT:
			return "Laser Shot"
		AudioSynthesizer.SoundType.POWER_UP_JINGLE:
			return "Power-Up Jingle"
		AudioSynthesizer.SoundType.EXPLOSION:
			return "Explosion"
		AudioSynthesizer.SoundType.RETRO_JUMP:
			return "Retro Jump"
		AudioSynthesizer.SoundType.SHIELD_HIT:
			return "Shield Hit"
		AudioSynthesizer.SoundType.AMBIENT_WIND:
			return "Ambient Wind"
		_:
			return "Unknown Sound"

# Signal handlers
func _on_sound_type_changed(index: int):
	var sound_keys = sound_parameters.keys()
	if index < sound_keys.size():
		current_sound_key = sound_keys[index]
		print("🎵 Changed to sound: %s" % current_sound_key)
		await create_parameter_controls()
		if realtime_enabled:
			trigger_audio_update()
	else:
		print("❌ Invalid sound index: %d" % index)

func _on_slider_changed(param_name: String, value: float):
	print("🎛️ SLIDER MOVED: %s changed to %.2f" % [param_name, value])  # Enhanced debug output
	print("🔑 Sound key: %s" % current_sound_key)
	
	sound_parameters[current_sound_key][param_name]["value"] = value
	update_value_label(param_name, value)
	print("Slider changed: %s = %.2f" % [param_name, value])  # Debug output
	
	# Force immediate audio update if real-time is enabled
	if realtime_enabled:
		print("🔄 Triggering real-time audio update...")
		# Cancel any pending update and do it immediately
		needs_audio_update = false
		update_audio_immediately()
	else:
		print("⏸️ Real-time disabled, no audio update")

func _on_option_changed(param_name: String, index: int):
	print("🎚️ OPTION CHANGED TRIGGERED: %s to index %d" % [param_name, index])
	var option_button = parameter_controls[param_name] as OptionButton
	var value = option_button.get_item_text(index)
	
	print("🔑 Sound key: %s" % current_sound_key)
	print("📝 Setting %s.%s = %s" % [current_sound_key, param_name, value])
	
	sound_parameters[current_sound_key][param_name]["value"] = value
	update_value_label(param_name, value)
	print("✅ Option changed: %s = %s" % [param_name, value])
	
	# Force immediate audio update if real-time is enabled
	if realtime_enabled:
		print("🔄 Real-time enabled, triggering immediate audio update...")
		# Cancel any pending update and do it immediately
		needs_audio_update = false
		update_audio_immediately()
	else:
		print("⏸️ Real-time disabled, no audio update")

func _on_realtime_toggled(enabled: bool):
	realtime_enabled = enabled
	print("🔄 Real-time updates: %s" % ("ENABLED" if enabled else "DISABLED"))
	if enabled:
		# Start playing current sound when real-time is enabled
		update_audio_immediately()
	else:
		# Stop audio when real-time is disabled
		if audio_player and audio_player.playing:
			audio_player.stop()
			print("⏹️ Audio stopped (real-time disabled)")

func trigger_audio_update():
	needs_audio_update = true

func _on_realtime_update():
	if needs_audio_update and realtime_enabled:
		needs_audio_update = false
		update_audio()

func update_audio_immediately():
	"""Immediately update and play audio with current parameters"""
	print("🎵 Immediate audio update... (Real-time: %s)" % realtime_enabled)
	
	if not audio_player:
		print("❌ Audio player not found")
		return
		
	# Stop current audio
	if audio_player.playing:
		audio_player.stop()
		print("⏸️ Stopped previous audio")
	
	var params = get_current_parameter_values(current_sound_key)
	
	print("🎛️ Using parameters for %s: %s" % [current_sound_key, params])
	
	# Generate new audio with current parameters - need to get the enum type
	var sound_type = get_type_from_sound_key(current_sound_key)
	var audio_stream = CustomSoundGenerator.generate_custom_sound(sound_type, params)
	if audio_stream:
		audio_player.stream = audio_stream
		audio_player.play()
		print("▶️ Real-time audio started playing (Duration: %.2fs)" % params.get("duration", 0.0))
		
		# Update visualizations
		update_visualizations()
	else:
		print("❌ Failed to generate audio stream")

func update_audio():
	"""Standard audio update function"""
	update_audio_immediately()

func _on_audio_finished():
	"""Called when audio finishes playing - restart if real-time is enabled"""
	if realtime_enabled:
		# Small delay to prevent audio clicking, then restart
		await get_tree().create_timer(0.05).timeout
		update_audio_immediately()

func get_current_parameter_values(sound_key: String) -> Dictionary:
	var params = {}
	
	if not sound_parameters.has(sound_key):
		print("⚠️ No parameters found for sound key: %s" % sound_key)
		return params
	
	var sound_config = sound_parameters[sound_key]
	
	for param_name in sound_config.keys():
		var param_config = sound_config[param_name]
		
		# Defensive check for parameter structure
		if param_config is Dictionary and param_config.has("value"):
			params[param_name] = param_config["value"]
		else:
			print("⚠️ Invalid parameter structure for %s.%s: %s" % [sound_key, param_name, param_config])
			# Provide a safe default
			params[param_name] = 0.0
	
	print("📊 Current %s parameters: %s" % [sound_key, params])
	return params

func _on_preview_pressed():
	print("🔊 Preview button pressed!")
	update_audio()

func _on_stop_pressed():
	print("⏹️ Stop button pressed!")
	if audio_player and audio_player.playing:
		audio_player.stop()
		print("🛑 Audio stopped")
	else:
		print("🔇 No audio playing")

func _on_save_pressed():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.add_filter("*.json", "JSON Preset Files")
	file_dialog.current_file = "sound_preset.json"
	
	add_child(file_dialog)
	file_dialog.file_selected.connect(_save_to_file)
	file_dialog.close_requested.connect(_show_json_popup)  # Show JSON even if file dialog is cancelled
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_load_pressed():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.add_filter("*.json", "JSON Preset Files")
	
	add_child(file_dialog)
	file_dialog.file_selected.connect(_load_from_file)
	file_dialog.popup_centered(Vector2i(800, 600))

func _on_export_pressed():
	var file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.add_filter("*.tres", "Godot Resource Files")
	file_dialog.current_file = "custom_sound.tres"
	
	add_child(file_dialog)
	file_dialog.file_selected.connect(_export_to_tres)
	file_dialog.popup_centered(Vector2i(800, 600))

# Save/Load functionality
func _save_to_file(file_path: String):
	# Save the complete parameter structure with min/max/step for easy copy-paste
	var save_data = {}
	
	# Copy the entire sound_parameters structure with current values
	for sound_key in sound_parameters.keys():
		save_data[sound_key] = {}
		for param_name in sound_parameters[sound_key].keys():
			# Create a complete copy of the parameter definition
			save_data[sound_key][param_name] = sound_parameters[sound_key][param_name].duplicate()
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		print("✅ Complete sound parameters saved to: ", file_path)
		print("📋 Copy-paste ready format with min/max/step values!")
		
		# Also print to console for easy copying
		print("🎛️ JSON Output for copy-paste:")
		print("==================================================")
		print(json_string)
		print("==================================================")
	else:
		print("❌ Failed to save file: ", file_path)

func _load_from_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var loaded_data = json.data
			
			# Update sound parameters with loaded values
			for sound_key in loaded_data.keys():
				if sound_parameters.has(sound_key):
					for param_name in loaded_data[sound_key].keys():
						if sound_parameters[sound_key].has(param_name):
							sound_parameters[sound_key][param_name]["value"] = loaded_data[sound_key][param_name]
			
			create_parameter_controls()
			print("✅ Sound parameters loaded from: ", file_path)
		else:
			print("❌ Failed to parse JSON file: ", file_path)
	else:
		print("❌ Failed to open file: ", file_path)

func _export_to_tres(file_path: String):
	var params = get_current_parameter_values(current_sound_key)
	
	var sound_type = get_type_from_sound_key(current_sound_key)
	var audio_stream = CustomSoundGenerator.generate_custom_sound(sound_type, params)
	var save_result = ResourceSaver.save(audio_stream, file_path)
	
	if save_result == OK:
		print("✅ Sound exported to: ", file_path)
	else:
		print("❌ Failed to export sound: ", file_path)

func _show_json_popup():
	"""Show a popup with the current sound parameters in JSON format for easy copying"""
	var save_data = {}
	
	# Get only the current sound type parameters
	if sound_parameters.has(current_sound_key):
		save_data[current_sound_key] = {}
		for param_name in sound_parameters[current_sound_key].keys():
			save_data[current_sound_key][param_name] = sound_parameters[current_sound_key][param_name].duplicate()
	
	var json_string = JSON.stringify(save_data, "\t")
	
	# Create a popup dialog
	var popup = AcceptDialog.new()
	var sound_name = _create_display_name_with_emoji(current_sound_key)
	popup.title = "📋 JSON Parameters - " + sound_name
	popup.dialog_text = "Copy the JSON for " + sound_name + " and paste it into your code:"
	
	# Create a text area with the JSON
	var vbox = VBoxContainer.new()
	
	var instructions = Label.new()
	instructions.text = "Select all text (Ctrl+A) and copy (Ctrl+C):"
	instructions.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(instructions)
	
	var text_edit = TextEdit.new()
	text_edit.text = json_string
	text_edit.editable = true
	text_edit.custom_minimum_size = Vector2(700, 400)
	text_edit.placeholder_text = "JSON parameter structure..."
	
	# Style the text editor
	text_edit.add_theme_color_override("font_color", Color.WHITE)
	text_edit.add_theme_color_override("background_color", Color(0.1, 0.1, 0.15, 1.0))
	
	vbox.add_child(text_edit)
	
	# Add copy hint
	var hint = Label.new()
	hint.text = "💡 Tip: This contains only the current sound's parameters with your custom values!"
	hint.add_theme_color_override("font_color", Color.CYAN)
	hint.add_theme_font_size_override("font_size", 12)
	vbox.add_child(hint)
	
	popup.add_child(vbox)
	
	add_child(popup)
	popup.popup_centered(Vector2i(750, 500))
	
	# Auto-select all text for easy copying
	text_edit.select_all()
	text_edit.grab_focus()
	
	# Clean up when closed
	popup.close_requested.connect(popup.queue_free)
	
	print("📋 JSON popup displayed - ready for copying!")

# Visualization functions
func initialize_visualizations():
	"""Initialize visualization data arrays"""
	current_waveform_data.resize(visualization_sample_count)
	current_waveform_data.fill(0.0)
	current_spectrum_data.resize(spectrum_bands)
	current_spectrum_data.fill(0.0)
	
	print("📊 Visualizations initialized - Waveform: %d samples, Spectrum: %d bands" % [visualization_sample_count, spectrum_bands])

func update_visualizations():
	"""Update waveform and spectrum data from current audio parameters"""
	var params = get_current_parameter_values(current_sound_key)
	
	# Generate the audio data for analysis
	var duration = params.get("duration", 1.0)
	var sample_count = int(AudioSynthesizer.SAMPLE_RATE * duration)
	var audio_data = PackedFloat32Array()
	audio_data.resize(sample_count)
	
	# Generate using the same method as audio generation
	var sound_type = get_type_from_sound_key(current_sound_key)
	match sound_type:
		AudioSynthesizer.SoundType.BASIC_SINE_WAVE:
			CustomSoundGenerator.generate_custom_basic_sine_wave(audio_data, sample_count, params)
		AudioSynthesizer.SoundType.PICKUP_MARIO:
			CustomSoundGenerator.generate_custom_pickup_sound(audio_data, sample_count, params)
		AudioSynthesizer.SoundType.TELEPORT_DRONE:
			CustomSoundGenerator.generate_custom_teleport_drone(audio_data, sample_count, params)
		AudioSynthesizer.SoundType.LIFT_BASS_PULSE:
			CustomSoundGenerator.generate_custom_bass_pulse(audio_data, sample_count, params)
		AudioSynthesizer.SoundType.GHOST_DRONE:
			CustomSoundGenerator.generate_custom_ghost_drone(audio_data, sample_count, params)
		AudioSynthesizer.SoundType.MELODIC_DRONE:
			CustomSoundGenerator.generate_custom_melodic_drone(audio_data, sample_count, params)
	
	# Update waveform data (downsample for display)
	update_waveform_data(audio_data)
	
	# Update spectrum data (FFT analysis)
	update_spectrum_data(audio_data)
	
	# Trigger redraws
	refresh_visualizations()

func update_waveform_data(audio_data: PackedFloat32Array):
	"""Update waveform display data"""
	current_waveform_data.resize(visualization_sample_count)
	
	if audio_data.size() == 0:
		current_waveform_data.fill(0.0)
		return
	
	# Downsample the audio data for display
	var step = float(audio_data.size()) / float(visualization_sample_count)
	
	for i in range(visualization_sample_count):
		var audio_index = int(i * step)
		if audio_index < audio_data.size():
			current_waveform_data[i] = audio_data[audio_index]
		else:
			current_waveform_data[i] = 0.0

func update_spectrum_data(audio_data: PackedFloat32Array):
	"""Update spectrum display data using basic FFT-like analysis"""
	current_spectrum_data.resize(spectrum_bands)
	current_spectrum_data.fill(0.0)
	
	if audio_data.size() == 0:
		return
	
	# Simple frequency analysis - sample different frequency ranges
	var max_freq = AudioSynthesizer.SAMPLE_RATE / 2.0  # Nyquist frequency
	
	for band in range(spectrum_bands):
		var freq_ratio = float(band) / float(spectrum_bands - 1)
		var target_freq = freq_ratio * 8000.0  # Focus on 0-8kHz range
		
		# Calculate magnitude for this frequency band
		var magnitude = calculate_frequency_magnitude(audio_data, target_freq)
		current_spectrum_data[band] = magnitude

func calculate_frequency_magnitude(audio_data: PackedFloat32Array, freq: float) -> float:
	"""Calculate magnitude for a specific frequency using correlation"""
	if audio_data.size() == 0:
		return 0.0
	
	var real_sum = 0.0
	var imag_sum = 0.0
	var sample_rate = AudioSynthesizer.SAMPLE_RATE
	
	# Use a subset of samples for performance
	var analysis_samples = min(audio_data.size(), 2048)
	
	for i in range(analysis_samples):
		var t = float(i) / sample_rate
		var cos_component = cos(2.0 * PI * freq * t)
		var sin_component = sin(2.0 * PI * freq * t)
		
		real_sum += audio_data[i] * cos_component
		imag_sum += audio_data[i] * sin_component
	
	# Calculate magnitude
	var magnitude = sqrt(real_sum * real_sum + imag_sum * imag_sum) / analysis_samples
	return clamp(magnitude * 2.0, 0.0, 1.0)  # Normalize and boost

func refresh_visualizations():
	"""Trigger redraw of visualization canvases"""
	if waveform_display:
		var canvas = waveform_display.get_node("WaveformCanvas")
		if canvas:
			canvas.queue_redraw()
	
	if spectrum_display:
		var canvas = spectrum_display.get_node("SpectrumCanvas")
		if canvas:
			canvas.queue_redraw()

func _draw_waveform(canvas: Control):
	"""Draw the time domain waveform"""
	var rect = Rect2(Vector2.ZERO, canvas.size)
	var center_y = rect.size.y * 0.5
	var padding = 20.0
	
	# Draw grid
	_draw_waveform_grid(canvas, rect, padding)
	
	# Draw waveform if we have data
	if current_waveform_data.size() > 1:
		var points: PackedVector2Array = []
		
		for i in range(current_waveform_data.size()):
			var x = padding + (float(i) / float(current_waveform_data.size() - 1)) * (rect.size.x - padding * 2)
			var amplitude = current_waveform_data[i]
			var y = center_y - amplitude * (center_y - padding)
			points.append(Vector2(x, y))
		
		# Draw waveform with glow effect
		var line_color = Color.CYAN
		var line_width = 2.0
		
		# Glow passes
		for glow in range(2):
			var glow_width = line_width + glow * 2
			var glow_alpha = 0.3 - glow * 0.1
			var glow_color = Color(line_color.r, line_color.g, line_color.b, glow_alpha)
			
			for i in range(points.size() - 1):
				canvas.draw_line(points[i], points[i + 1], glow_color, glow_width)
		
		# Main line
		for i in range(points.size() - 1):
			canvas.draw_line(points[i], points[i + 1], line_color, line_width)

func _draw_spectrum(canvas: Control):
	"""Draw the frequency domain spectrum"""
	var rect = Rect2(Vector2.ZERO, canvas.size)
	var padding = 20.0
	
	# Draw grid
	_draw_spectrum_grid(canvas, rect, padding)
	
	# Draw spectrum if we have data
	if current_spectrum_data.size() > 0:
		var bar_width = (rect.size.x - padding * 2) / float(current_spectrum_data.size())
		var line_color = Color.GREEN
		
		# Draw spectrum bars
		for i in range(current_spectrum_data.size()):
			var x = padding + i * bar_width
			var amplitude = current_spectrum_data[i]
			var height = amplitude * (rect.size.y - padding * 2)
			var y = rect.size.y - padding - height
			
			var bar_rect = Rect2(x, y, bar_width * 0.8, height)
			canvas.draw_rect(bar_rect, line_color)

func _draw_waveform_grid(canvas: Control, rect: Rect2, padding: float):
	"""Draw grid for waveform display"""
	var grid_color = Color(0.3, 0.6, 0.6, 0.4)
	var text_color = Color.CYAN
	var center_y = rect.size.y * 0.5
	
	# Horizontal lines (amplitude)
	for i in range(3):
		var offset = (float(i + 1) / 4.0) * (center_y - padding)
		
		# Positive amplitude
		var y_pos = center_y - offset
		canvas.draw_line(Vector2(padding, y_pos), Vector2(rect.size.x - padding, y_pos), grid_color)
		
		# Negative amplitude
		var y_neg = center_y + offset
		canvas.draw_line(Vector2(padding, y_neg), Vector2(rect.size.x - padding, y_neg), grid_color)
	
	# Center line
	canvas.draw_line(Vector2(padding, center_y), Vector2(rect.size.x - padding, center_y), Color(0.5, 0.8, 0.8, 0.6), 2.0)
	
	# Vertical lines (time)
	for i in range(5):
		var x = padding + (float(i) / 4.0) * (rect.size.x - padding * 2)
		canvas.draw_line(Vector2(x, padding), Vector2(x, rect.size.y - padding), grid_color)
		
		# Time labels
		var time_text = "%.1fs" % (float(i) * 0.25)
		canvas.draw_string(get_theme_default_font(), Vector2(x + 2, rect.size.y - 5), time_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, text_color)

func _draw_spectrum_grid(canvas: Control, rect: Rect2, padding: float):
	"""Draw grid for spectrum display"""
	var grid_color = Color(0.3, 0.6, 0.3, 0.4)
	var text_color = Color.GREEN
	
	# Horizontal lines (amplitude)
	for i in range(4):
		var y = padding + (float(i + 1) / 5.0) * (rect.size.y - padding * 2)
		canvas.draw_line(Vector2(padding, y), Vector2(rect.size.x - padding, y), grid_color)
		
		# Amplitude labels
		var amp_text = "%.1f" % (1.0 - float(i + 1) / 5.0)
		canvas.draw_string(get_theme_default_font(), Vector2(5, y - 2), amp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, text_color)
	
	# Vertical lines (frequency)
	for i in range(5):
		var x = padding + (float(i) / 4.0) * (rect.size.x - padding * 2)
		canvas.draw_line(Vector2(x, padding), Vector2(x, rect.size.y - padding), grid_color)
		
		# Frequency labels
		var freq_hz = (float(i) / 4.0) * 8000.0
		var freq_text = ""
		if freq_hz < 1000:
			freq_text = "%d Hz" % int(freq_hz)
		else:
			freq_text = "%.1f kHz" % (freq_hz / 1000.0)
		canvas.draw_string(get_theme_default_font(), Vector2(x + 2, rect.size.y - 5), freq_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, text_color)

# Educational functions
func setup_educational_ui():
	"""Create educational interface elements"""
	# Theory panel (right side)
	theory_panel = Panel.new()
	theory_panel.custom_minimum_size = Vector2(350, 400)
	
	# Tutorial mode toggle
	tutorial_mode_toggle = CheckBox.new()
	tutorial_mode_toggle.text = "📚 Tutorial Mode"
	tutorial_mode_toggle.toggled.connect(_on_tutorial_mode_toggled)
	
	# Theory content area
	theory_label = RichTextLabel.new()
	theory_label.bbcode_enabled = true
	theory_label.fit_content = true
	theory_label.scroll_active = true
	
	# Lesson progress
	lesson_progress_bar = ProgressBar.new()
	lesson_progress_bar.max_value = 100
	lesson_progress_bar.value = 0
	
	# Interactive exercises container
	interactive_exercises_container = VBoxContainer.new()

func update_theory_display():
	"""Update the theory panel with current sound type information"""
	if not theory_label:
		return
		
	var theory_data = sound_theory.get(current_sound_key, {})
	
	if theory_data.is_empty():
		theory_label.text = "No educational content available for this sound type."
		return
	
	var content = """
<b><font size=16>{title}</font></b>

<b>Difficulty:</b> {difficulty}
<b>Estimated Time:</b> {duration}

<b>Description:</b>
{description}

{theory}
	""".format({
		"title": theory_data.get("title", "Unknown"),
		"difficulty": theory_data.get("difficulty", "Unknown"),
		"duration": theory_data.get("duration", "Unknown"),
		"description": theory_data.get("description", ""),
		"theory": theory_data.get("theory", "")
	})
	
	theory_label.text = content

func create_interactive_exercises():
	"""Create interactive exercise buttons for current sound type"""
	# Clear existing exercises
	for child in interactive_exercises_container.get_children():
		child.queue_free()
	
	var theory_data = sound_theory.get(current_sound_key, {})
	var exercises = theory_data.get("exercises", [])
	
	if exercises.is_empty():
		return
	
	var exercises_label = Label.new()
	exercises_label.text = "🎯 Interactive Exercises:"
	exercises_label.add_theme_font_size_override("font_size", 14)
	interactive_exercises_container.add_child(exercises_label)
	
	for i in range(exercises.size()):
		var exercise = exercises[i]
		var button = Button.new()
		button.text = str(i + 1) + ". " + exercise.get("task", "Unknown Exercise")
		button.custom_minimum_size = Vector2(300, 30)
		
		# Connect to exercise function with parameters
		var params = exercise.get("params", {})
		button.pressed.connect(func(): _execute_exercise(params))
		
		interactive_exercises_container.add_child(button)

func _execute_exercise(params: Dictionary):
	"""Execute an interactive exercise by setting parameters"""
	
	# Apply exercise parameters
	for param_name in params.keys():
		if sound_parameters[current_sound_key].has(param_name):
			sound_parameters[current_sound_key][param_name]["value"] = params[param_name]
	
	# Recreate UI controls to reflect new values
	create_parameter_controls()
	
	# Play the sound to demonstrate
	_on_preview_pressed()
	
	print("✅ Exercise completed! Parameters applied: ", params)

func _on_tutorial_mode_toggled(enabled: bool):
	"""Toggle tutorial mode on/off"""
	tutorial_mode = enabled
	
	if tutorial_mode:
		print("📚 Tutorial mode activated - Educational features enabled")
		theory_panel.visible = true
		update_theory_display()
		create_interactive_exercises()
	else:
		print("🎛️ Expert mode activated - Simplified interface")
		theory_panel.visible = false

func calculate_lesson_progress() -> float:
	"""Calculate overall learning progress"""
	var total_lessons = sound_theory.keys().size()
	var completed = lessons_completed.keys().size()
	return (float(completed) / float(total_lessons)) * 100.0

func mark_lesson_completed():
	"""Mark current lesson as completed"""
	lessons_completed[current_sound_key] = true
	lesson_progress_bar.value = calculate_lesson_progress()
	
	print("🎉 Lesson completed: ", sound_theory[current_sound_key]["title"])
	print("📊 Overall progress: ", int(lesson_progress_bar.value), "%")
