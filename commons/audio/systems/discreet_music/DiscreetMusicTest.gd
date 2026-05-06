extends Node3D

func _ready():
	_setup_audio_buses()

func _setup_audio_buses():
	# Create Bus if it doesn't exist
	_create_bus("DiscreetMusic", "Master")
	
	# Add Effects to Music Bus
	var idx = AudioServer.get_bus_index("DiscreetMusic")
	
	# Clear existing effects to avoid stacking on reload
	for i in range(AudioServer.get_bus_effect_count(idx)):
		AudioServer.remove_bus_effect(idx, 0)
	
	# 1. EQ (Approximate Tone.js EQ)
	var eq = AudioEffectEQ21.new()
	AudioServer.add_bus_effect(idx, eq)
	
	# 2. Delay (Frippertronics Simulation)
	# 3000ms is roughly the max usually allowed, we simulate the loop.
	var delay = AudioEffectDelay.new()
	delay.tap1_active = true
	delay.tap1_delay_ms = 3000.0 
	delay.tap1_level_db = -3.0
	
	delay.tap2_active = true
	delay.tap2_delay_ms = 1500.0 # Texture tap
	delay.tap2_level_db = -6.0
	
	delay.feedback_active = true
	delay.feedback_delay_ms = 3000.0
	delay.feedback_level_db = -4.0 # Decay
	
	AudioServer.add_bus_effect(idx, delay)
	
	# Route Synths
	$LeftSynth.bus = "DiscreetMusic"
	$RightSynth.bus = "DiscreetMusic"

func _create_bus(name, send_to="Master"):
	if AudioServer.get_bus_index(name) == -1:
		var idx = AudioServer.get_bus_count()
		AudioServer.add_bus()
		AudioServer.set_bus_name(idx, name)
		AudioServer.set_bus_send(idx, send_to)
