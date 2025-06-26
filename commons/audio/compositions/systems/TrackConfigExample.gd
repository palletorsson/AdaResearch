# TrackConfigExample.gd
# Example demonstrating JSON configuration loading and usage
extends Node

var track_system: EnhancedTrackSystem

func _ready():
	print("🎛️ JSON Configuration System Example")
	print("=====================================")
	
	# Create the track system
	track_system = EnhancedTrackSystem.new()
	add_child(track_system)
	
	# Example 1: Load the dark game track configuration
	print("\n📁 Loading Dark Game Track Configuration")
	load_and_apply_config("commons/audio/configs/dark_game_track.json")
	
	# Wait a moment, then show some live modifications
	await get_tree().create_timer(8.0).timeout
	
	print("\n🎛️ Demonstrating live effects...")
	demonstrate_realtime_modifications()
	
	# Wait, then demonstrate saving current config
	await get_tree().create_timer(5.0).timeout
	
	print("\n💾 Example 3: Saving Current Configuration")
	save_current_config()
	
	# Demonstrate real-time config modifications
	await get_tree().create_timer(2.0).timeout
	
	print("\n🎚️ Example 4: Real-time Configuration Modifications")
	demonstrate_realtime_modifications()

func load_and_apply_config(config_path: String):
	"""Load and apply a JSON configuration"""
	
	print("   Loading config: %s" % config_path)
	
	# Load the configuration
	var config = TrackConfigLoader.load_track_config(config_path)
	if config.is_empty():
		print("   ❌ Failed to load configuration")
		return
	
	# Apply it to the track system
	TrackConfigLoader.apply_config_to_track(track_system, config)
	
	# Start playing
	track_system.play()
	
	print("   ✅ Configuration loaded and playing!")

func save_current_config():
	"""Save the current track configuration to JSON"""
	
	# Modify some settings first
	track_system.set_layer_volume("drums", "kick", -6.0)
	track_system.set_layer_volume("bass", "sub", -3.0)
	
	if track_system.effects_rack:
		track_system.effects_rack.set_master_reverb(0.7, 0.4, 0.3)
	
	# Save the configuration
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	var save_path = "commons/audio/configs/exported_track_%s.json" % timestamp
	
	TrackConfigLoader.save_track_config(track_system, save_path, "My Custom Track")
	print("   💾 Configuration saved to: %s" % save_path)

func demonstrate_realtime_modifications():
	"""Show how to modify configs in real-time"""
	
	print("   🎚️ Starting real-time modifications...")
	
	# Create a configuration for live modifications
	var live_config = {
		"layers": {
			"drums": {
				"kick": {
					"effects": {
						"filter": {
							"cutoff": 400.0,
							"resonance": 2.0
						}
					},
					"lfo": {
						"target": "filter_cutoff",
						"rate": 0.5,
						"depth": 300.0
					}
				}
			}
		},
		"automation": {
			"filter_sweeps": [
				{
					"delay": 2.0,
					"target": "Layer_bass_sub",
					"start_freq": 200.0,
					"end_freq": 1500.0,
					"duration": 4.0
				}
			]
		}
	}
	
	# Apply the live modifications
	TrackConfigLoader.apply_config_to_track(track_system, live_config)
	
	print("   ✅ Real-time modifications applied!")

func _input(event):
	"""Handle keyboard input for live configuration changes"""
	
	if not track_system:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			# Number keys 1-6: Toggle layers
			KEY_1:
				toggle_layer_from_config("drums", "kick")
			KEY_2:
				toggle_layer_from_config("drums", "snare")
			KEY_3:
				toggle_layer_from_config("drums", "hihat")
			KEY_4:
				toggle_layer_from_config("bass", "sub")
			KEY_5:
				toggle_layer_from_config("synths", "lead")
			KEY_6:
				toggle_layer_from_config("synths", "pad")
			
			# Effect keys
			KEY_F:
				apply_filter_sweep_config()
			KEY_R:
				apply_reverb_config()
			KEY_C:
				apply_compression_config()
			
			# Save/Load keys
			KEY_S:
				if event.ctrl_pressed:
					quick_save_config()
			KEY_L:
				if event.ctrl_pressed:
					quick_load_config()
			
			# Pattern modification keys
			KEY_P:
				generate_random_pattern_config()

func toggle_layer_from_config(category: String, layer_name: String):
	"""Toggle a layer using configuration format"""
	
	var layer = track_system.get_layer(category, layer_name)
	if layer:
		var new_enabled = not layer.enabled
		track_system.set_layer_enabled(category, layer_name, new_enabled)
		print("   🎛️ %s/%s: %s" % [category, layer_name, "ON" if new_enabled else "OFF"])

func apply_filter_sweep_config():
	"""Apply a filter sweep using configuration format"""
	
	var sweep_config = {
		"automation": {
			"filter_sweeps": [
				{
					"delay": 0.0,
					"target": "Layer_bass_sub",
					"start_freq": 200.0,
					"end_freq": 2000.0,
					"duration": 3.0
				}
			]
		}
	}
	
	TrackConfigLoader.apply_config_to_track(track_system, sweep_config)
	print("   🌊 Filter sweep applied!")

func apply_reverb_config():
	"""Apply reverb settings using configuration format"""
	
	var reverb_config = {
		"effects": {
			"reverb": {
				"room_size": randf_range(0.3, 0.9),
				"damping": randf_range(0.2, 0.8),
				"wet": randf_range(0.1, 0.4)
			}
		}
	}
	
	TrackConfigLoader.apply_config_to_track(track_system, reverb_config)
	print("   🏛️ Reverb settings updated!")

func apply_compression_config():
	"""Apply compression settings using configuration format"""
	
	var comp_config = {
		"effects": {
			"compressor": {
				"threshold": randf_range(-12.0, -3.0),
				"ratio": randf_range(2.0, 6.0),
				"attack": randf_range(5.0, 20.0),
				"release": randf_range(50.0, 200.0)
			}
		}
	}
	
	TrackConfigLoader.apply_config_to_track(track_system, comp_config)
	print("   🗜️ Compression settings updated!")

func quick_save_config():
	"""Quick save current configuration"""
	
	var save_path = "commons/audio/configs/quick_save.json"
	TrackConfigLoader.save_track_config(track_system, save_path, "Quick Save")
	print("   💾 Quick saved to: %s" % save_path)

func quick_load_config():
	"""Quick load the quick save configuration"""
	
	var load_path = "commons/audio/configs/quick_save.json"
	if FileAccess.file_exists(load_path):
		var config = TrackConfigLoader.load_track_config(load_path)
		TrackConfigLoader.apply_config_to_track(track_system, config)
		print("   📁 Quick loaded from: %s" % load_path)
	else:
		print("   ❌ No quick save found")

func generate_random_pattern_config():
	"""Generate a random pattern using configuration format"""
	
	var pattern_types = ["kick", "snare", "hihat", "bass", "arp"]
	var selected_type = pattern_types[randi() % pattern_types.size()]
	
	var pattern_config = {
		"patterns": {
			"random_pattern": {
				"length": [16, 32, 64][randi() % 3],
				"type": selected_type,
				"style": get_random_style_for_type(selected_type),
				"swing": randf_range(0.0, 0.2),
				"humanization": randf_range(0.0, 0.3),
				"probability": randf_range(0.7, 1.0)
			}
		}
	}
	
	# Apply pattern and assign to a random layer
	TrackConfigLoader.apply_config_to_track(track_system, pattern_config)
	
	# Get a random layer to assign the pattern to
	var categories = ["drums", "bass", "synths"]
	var category = categories[randi() % categories.size()]
	var layers = track_system.layers.get(category, {})
	
	if not layers.is_empty():
		var layer_names = layers.keys()
		var layer_name = layer_names[randi() % layer_names.size()]
		var layer = layers[layer_name]
		
		if layer:
			var pattern = track_system.sequencer.get_pattern("random_pattern")
			if pattern:
				layer.pattern = pattern.steps
				layer.pattern_length = pattern.length
				print("   🎲 Random %s pattern applied to %s/%s" % [selected_type, category, layer_name])

func get_random_style_for_type(pattern_type: String) -> String:
	"""Get a random style for the given pattern type"""
	
	match pattern_type:
		"kick":
			return ["four_on_floor", "breakbeat", "trap"][randi() % 3]
		"snare":
			return ["backbeat", "syncopated", "breaks"][randi() % 3]
		"hihat":
			return ["steady", "offbeat", "rolls"][randi() % 3]
		"bass":
			return ["steady", "rolling", "syncopated"][randi() % 3]
		"arp":
			return ["up", "down", "up_down", "random"][randi() % 4]
		_:
			return "default"

func _exit_tree():
	"""Cleanup when exiting"""
	
	if track_system:
		track_system.stop()
		print("🛑 Track system stopped")

# ===== CONSOLE COMMANDS =====

func print_config_status():
	"""Print current configuration status"""
	
	print("\n📊 Current Configuration Status:")
	print("================================")
	
	if not track_system:
		print("❌ No track system loaded")
		return
	
	print("🎵 BPM: %d" % track_system.bpm)
	print("🎛️ Active Layers:")
	
	for category in track_system.layers.keys():
		print("   %s:" % category.capitalize())
		for layer_name in track_system.layers[category].keys():
			var layer = track_system.layers[category][layer_name]
			if layer and layer.enabled:
				print("     ✅ %s (Volume: %.1fdB)" % [layer_name, layer.layer_volume])
			elif layer:
				print("     ❌ %s (Disabled)" % layer_name)
	
	print("🎹 Patterns: %d loaded" % track_system.sequencer.patterns.size())
	print("🎚️ Effects: %s" % ("Active" if track_system.effects_rack else "None")) 