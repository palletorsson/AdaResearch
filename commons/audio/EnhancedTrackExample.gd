# EnhancedTrackExample.gd
# Example usage of the Enhanced Track System
extends Node

var enhanced_track: EnhancedDarkTrack

func _ready():
	print("🎵 Enhanced Track System Example 🎵")
	setup_enhanced_track()

func setup_enhanced_track():
	"""Setup and configure the enhanced track system"""
	
	# Create the enhanced track
	enhanced_track = EnhancedDarkTrack.new()
	enhanced_track.name = "EnhancedDarkTrack"
	add_child(enhanced_track)
	
	# Wait for initialization
	await enhanced_track.track_started
	
	# Configure layer volumes
	enhanced_track.set_layer_volume("drums", "kick", 0.0)
	enhanced_track.set_layer_volume("drums", "snare", -3.0)
	enhanced_track.set_layer_volume("drums", "hihat", -6.0)
	enhanced_track.set_layer_volume("bass", "sub", -2.0)
	enhanced_track.set_layer_volume("bass", "acid", -4.0)
	enhanced_track.set_layer_volume("synths", "pad", -8.0)
	enhanced_track.set_layer_volume("fx", "ambient", -12.0)
	
	# Enable initial layers (intro setup)
	enhanced_track.set_layer_enabled("drums", "kick", true)
	enhanced_track.set_layer_enabled("drums", "snare", false)
	enhanced_track.set_layer_enabled("drums", "hihat", false)
	enhanced_track.set_layer_enabled("bass", "sub", false)
	enhanced_track.set_layer_enabled("bass", "acid", false)
	enhanced_track.set_layer_enabled("synths", "pad", true)
	enhanced_track.set_layer_enabled("fx", "ambient", true)
	
	# Setup LFO modulation
	var bass_layer = enhanced_track.get_layer("bass", "sub")
	if bass_layer:
		bass_layer.setup_lfo("filter_cutoff", 0.25, 0.7)  # Slow filter sweep
	
	var pad_layer = enhanced_track.get_layer("synths", "pad")
	if pad_layer:
		pad_layer.setup_lfo("volume", 0.1, 0.3)  # Gentle volume modulation
	
	# Create custom patterns using the sequencer
	_create_custom_patterns()
	
	# Setup automation
	_setup_automation()
	
	# Connect to events
	enhanced_track.section_changed.connect(_on_section_changed)
	enhanced_track.beat_triggered.connect(_on_beat_triggered)
	
	# Start the track
	enhanced_track.start_track()
	
	print("✅ Enhanced track setup complete!")

func _create_custom_patterns():
	"""Create custom patterns using the advanced sequencer"""
	
	# Create a complex kick pattern using Euclidean rhythm
	var euclidean_kick = enhanced_track.sequencer.create_pattern("euclidean_kick", 16)
	enhanced_track.sequencer.generate_euclidean_rhythm(euclidean_kick, 5, 16)  # 5 hits in 16 steps
	
	# Create a trap-style hi-hat pattern
	var trap_hats = enhanced_track.sequencer.create_pattern("trap_hats", 16)
	enhanced_track.sequencer.generate_hihat_pattern(trap_hats, "trap")
	
	# Apply humanization
	enhanced_track.sequencer.apply_velocity_humanization(trap_hats, 0.2)
	enhanced_track.sequencer.apply_swing(trap_hats, 0.1)
	
	# Create an acid bass line
	var acid_bass = enhanced_track.sequencer.create_pattern("acid_bass", 32)
	enhanced_track.sequencer.generate_bass_line(acid_bass, "Am", "acid")
	
	# Apply probability for variation
	enhanced_track.sequencer.apply_probability(acid_bass, 0.8)
	
	print("   ✨ Custom patterns created")

func _setup_automation():
	"""Setup automated effects and transitions"""
	
	# Setup filter sweeps that trigger periodically
	var sweep_timer = Timer.new()
	sweep_timer.wait_time = 16.0  # Every 16 seconds
	sweep_timer.one_shot = false
	sweep_timer.timeout.connect(_trigger_filter_sweep)
	add_child(sweep_timer)
	sweep_timer.start()
	
	# Setup periodic bass drops
	var drop_timer = Timer.new()
	drop_timer.wait_time = 32.0  # Every 32 seconds
	drop_timer.one_shot = false
	drop_timer.timeout.connect(_trigger_bass_drop)
	add_child(drop_timer)
	drop_timer.start()

func _trigger_filter_sweep():
	"""Trigger a dramatic filter sweep"""
	# Apply sweep to bass layer
	enhanced_track.apply_filter_sweep("bass", "sub", 2.0)
	
	# Also apply to the effects rack
	enhanced_track.effects_rack.apply_filter_sweep("Layer_bass_sub", 100.0, 2000.0, 2.0)
	
	print("   🌊 Filter sweep triggered")

func _trigger_bass_drop():
	"""Trigger a bass drop effect"""
	# Temporarily duck the volume and bring it back
	enhanced_track.effects_rack.apply_volume_fade("Layer_bass_sub", -2.0, -20.0, 0.5, "bass_drop")
	
	# Add delay throw effect
	enhanced_track.effects_rack.apply_delay_throw("Layer_bass_sub", 1.5, 0.6)
	
	await get_tree().create_timer(1.0).timeout
	
	# Bring bass back with impact
	enhanced_track.effects_rack.apply_volume_fade("Layer_bass_sub", -20.0, 0.0, 0.3, "bass_return")
	
	print("   💥 Bass drop triggered")

func _on_section_changed(new_section: String, old_section: String):
	"""Handle section changes"""
	print("   🎭 Section changed: %s -> %s" % [old_section, new_section])
	
	match new_section:
		"intro":
			_setup_intro_automation()
		"buildup":
			_setup_buildup_automation()
		"drop":
			_setup_drop_automation()
		"breakdown":
			_setup_breakdown_automation()
		"outro":
			_setup_outro_automation()

func _setup_intro_automation():
	"""Setup automation for intro section"""
	# Gradually fade in the pad
	enhanced_track.effects_rack.apply_volume_fade("Layer_synths_pad", -30.0, -8.0, 4.0)
	
	# Add gentle reverb
	enhanced_track.effects_rack.set_master_reverb(0.6, 0.7, 0.3)

func _setup_buildup_automation():
	"""Setup automation for buildup section"""
	# Enable more layers
	enhanced_track.set_layer_enabled("drums", "snare", true)
	enhanced_track.set_layer_enabled("drums", "hihat", true)
	enhanced_track.set_layer_enabled("bass", "sub", true)
	
	# Increase filter cutoff gradually
	var bass_layer = enhanced_track.get_layer("bass", "sub")
	if bass_layer:
		bass_layer.modulate_filter_sweep(200.0, 1500.0, 8.0)
	
	# Add tension with delay
	enhanced_track.effects_rack.set_master_delay_time(375.0, true, enhanced_track.bpm)

func _setup_drop_automation():
	"""Setup automation for drop section"""
	# Full energy configuration
	enhanced_track.set_layer_enabled("bass", "acid", true)
	enhanced_track.set_layer_volume("drums", "kick", 2.0)  # Boost kick
	
	# Apply sidechain-style ducking
	_setup_sidechain_effect()
	
	# Reduce reverb for tightness
	enhanced_track.effects_rack.set_master_reverb(0.3, 0.5, 0.15)

func _setup_breakdown_automation():
	"""Setup automation for breakdown section"""
	# Reduce to minimal elements
	enhanced_track.set_layer_enabled("drums", "snare", false)
	enhanced_track.set_layer_enabled("drums", "hihat", false)
	enhanced_track.set_layer_enabled("bass", "acid", false)
	
	# Bring back atmospheric elements
	enhanced_track.set_layer_enabled("fx", "ambient", true)
	enhanced_track.effects_rack.apply_volume_fade("Layer_fx_ambient", -30.0, -10.0, 2.0)

func _setup_outro_automation():
	"""Setup automation for outro section"""
	# Gradual fadeout of all elements
	enhanced_track.effects_rack.apply_volume_fade("Layer_drums_kick", 0.0, -30.0, 8.0)
	enhanced_track.effects_rack.apply_volume_fade("Layer_bass_sub", -2.0, -30.0, 10.0)
	enhanced_track.effects_rack.apply_volume_fade("Layer_synths_pad", -8.0, -40.0, 12.0)

func _setup_sidechain_effect():
	"""Simulate sidechain compression using the kick"""
	var kick_layer = enhanced_track.get_layer("drums", "kick")
	var bass_layer = enhanced_track.get_layer("bass", "sub")
	
	if kick_layer and bass_layer:
		kick_layer.audio_played.connect(func():
			# Duck the bass when kick hits
			var tween = create_tween()
			var original_vol = bass_layer.layer_volume
			tween.tween_property(bass_layer, "layer_volume", original_vol - 6.0, 0.05)
			tween.tween_property(bass_layer, "layer_volume", original_vol, 0.15)
		)
		print("   🔗 Sidechain effect setup")

func _on_beat_triggered(beat_number: int):
	"""Handle beat events for real-time control"""
	
	# Every 32 beats, apply some variation
	if beat_number % 32 == 0:
		_apply_random_variation()
	
	# Every 64 beats, trigger special effects
	if beat_number % 64 == 0:
		_trigger_special_effects()

func _apply_random_variation():
	"""Apply random variations to keep the track interesting"""
	
	# Randomly adjust filter cutoffs
	var bass_layer = enhanced_track.get_layer("bass", "sub")
	if bass_layer and randf() < 0.3:
		var random_cutoff = randf_range(300.0, 1200.0)
		bass_layer.set_filter_cutoff(random_cutoff)
	
	# Randomly trigger delay throws
	if randf() < 0.2:
		enhanced_track.effects_rack.apply_delay_throw("Layer_bass_sub", randf_range(1.0, 3.0))
	
	print("   🎲 Random variation applied")

func _trigger_special_effects():
	"""Trigger special effects periodically"""
	
	# Choose a random special effect
	var effects = ["master_filter_sweep", "volume_duck", "reverb_burst"]
	var chosen_effect = effects[randi() % effects.size()]
	
	match chosen_effect:
		"master_filter_sweep":
			enhanced_track.effects_rack.apply_master_filter_sweep(50.0, 4000.0, 2.0)
			print("   🌊 Master filter sweep!")
		
		"volume_duck":
			enhanced_track.effects_rack.apply_master_volume_duck(8.0, 0.2, 0.8)
			print("   🦆 Master volume duck!")
		
		"reverb_burst":
			enhanced_track.effects_rack.set_master_reverb(0.9, 0.3, 0.6)
			await get_tree().create_timer(2.0).timeout
			enhanced_track.effects_rack.set_master_reverb(0.6, 0.5, 0.2)
			print("   🏢 Reverb burst!")

# ===== INPUT CONTROLS =====

func _input(event):
	"""Handle keyboard controls for real-time manipulation"""
	
	if not enhanced_track:
		return
	
	# Layer controls
	if event.is_action_pressed("ui_1"):
		_toggle_layer("drums", "kick")
	elif event.is_action_pressed("ui_2"):
		_toggle_layer("drums", "snare")
	elif event.is_action_pressed("ui_3"):
		_toggle_layer("drums", "hihat")
	elif event.is_action_pressed("ui_4"):
		_toggle_layer("bass", "sub")
	elif event.is_action_pressed("ui_5"):
		_toggle_layer("bass", "acid")
	elif event.is_action_pressed("ui_6"):
		_toggle_layer("synths", "pad")
	
	# Effect controls
	elif event.is_action_pressed("ui_f"):
		_trigger_filter_sweep()
	elif event.is_action_pressed("ui_d"):
		_trigger_bass_drop()
	elif event.is_action_pressed("ui_r"):
		enhanced_track.effects_rack.set_master_reverb(0.9, 0.3, 0.8)
	
	# Transport controls
	elif event.is_action_pressed("ui_accept"):  # Space
		if enhanced_track.is_playing:
			enhanced_track.stop_track()
		else:
			enhanced_track.start_track()
	elif event.is_action_pressed("ui_select"):  # Enter
		enhanced_track.info()

func _toggle_layer(category: String, layer: String):
	"""Toggle a layer on/off"""
	var layer_obj = enhanced_track.get_layer(category, layer)
	if layer_obj:
		enhanced_track.set_layer_enabled(category, layer, not layer_obj.enabled)
		print("   🎛️ Toggled %s/%s: %s" % [category, layer, "ON" if layer_obj.enabled else "OFF"])

# ===== CONSOLE COMMANDS =====

func show_status():
	"""Show comprehensive system status"""
	print("\n🎛️ ENHANCED TRACK STATUS 🎛️")
	enhanced_track.info()
	enhanced_track.section_info()
	enhanced_track.sequencer.list_patterns()
	enhanced_track.effects_rack.effects_info()

func show_help():
	"""Show control help"""
	print("\n🎹 ENHANCED TRACK CONTROLS 🎹")
	print("  [1-6] - Toggle layers (kick, snare, hihat, sub, acid, pad)")
	print("  [F] - Filter sweep")
	print("  [D] - Bass drop")
	print("  [R] - Reverb burst")
	print("  [Space] - Play/Stop")
	print("  [Enter] - Show info")
	print("\n  Console commands:")
	print("  show_status() - Show comprehensive status")
	print("  show_help() - Show this help") 
