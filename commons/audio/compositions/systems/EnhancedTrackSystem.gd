# EnhancedTrackSystem.gd
# Advanced modular track system with layered architecture
extends Node
class_name EnhancedTrackSystem

# Track layers - each can be enabled/disabled
var layers: Dictionary = {
	"drums": {
		"kick": null,
		"snare": null, 
		"hihat": null,
		"percussion": null
	},
	"bass": {
		"sub": null,
		"mid": null,
		"acid": null
	},
	"synths": {
		"lead": null,
		"pad": null,
		"arp": null
	},
	"fx": {
		"sweeps": null,
		"impacts": null,
		"ambient": null
	}
}

# Pattern lengths (not limited to 8 beats)
var pattern_lengths: Dictionary = {
	"drums": 16,      # 16-beat drum patterns
	"bass": 32,       # 32-beat bass progression
	"synths": 64,     # 64-beat melodic progression
	"fx": 128         # Long ambient cycles
}

# System components
var sequencer: PatternSequencer
var effects_rack: EffectsRack

# Timing system
const SAMPLE_RATE = 44100
var bpm: float = 120.0
var beat_timer: Timer
var global_beat: int = 0
var is_playing: bool = false

# Events
signal track_started()
signal beat_triggered(beat_number: int)
signal section_changed(new_section: String)

func _ready():
	print("🎛️ ENHANCED TRACK SYSTEM 🎛️")
	print("Initializing modular architecture...")
	
	_setup_core_systems()
	_create_track_layers()

func _setup_core_systems():
	"""Initialize core system components"""
	
	# Create sequencer
	sequencer = PatternSequencer.new()
	sequencer.name = "PatternSequencer"
	add_child(sequencer)
	
	# Create effects rack
	effects_rack = EffectsRack.new()
	effects_rack.name = "EffectsRack"
	add_child(effects_rack)
	
	# Setup timing
	beat_timer = Timer.new()
	beat_timer.name = "GlobalBeatTimer"
	beat_timer.wait_time = 60.0 / bpm / 4.0  # 16th note resolution
	beat_timer.one_shot = false
	beat_timer.timeout.connect(_on_global_beat)
	add_child(beat_timer)
	
	print("   ✅ Core systems initialized")

func _create_track_layers():
	"""Create all track layer instances"""
	
	for category in layers.keys():
		for layer_name in layers[category].keys():
			var layer = TrackLayer.new()
			layer.layer_name = "%s_%s" % [category, layer_name]
			layer.name = layer.layer_name
			layer.pattern_length = pattern_lengths.get(category, 16)
			add_child(layer)
			layers[category][layer_name] = layer
	
	print("   ✅ Track layers created")

func _on_global_beat():
	"""Handle global beat timing"""
	if not is_playing:
		return
	
	# Process all layers
	for category in layers.keys():
		for layer_name in layers[category].keys():
			var layer = layers[category][layer_name]
			if layer and layer.enabled:
				layer.process_beat(global_beat)
	
	# Emit beat signal
	beat_triggered.emit(global_beat)
	
	global_beat += 1

# ===== PUBLIC API =====

func start_track():
	"""Start the enhanced track system"""
	if is_playing:
		return
	
	print("🎵 Starting enhanced track...")
	is_playing = true
	global_beat = 0
	
	# Start ambient layers first
	_start_ambient_layers()
	
	# Start timing
	beat_timer.start()
	
	track_started.emit()
	print("   🎵 Enhanced track playing at %.1f BPM" % bpm)

func stop_track():
	"""Stop the track system"""
	if not is_playing:
		return
	
	print("⏸️ Stopping enhanced track...")
	is_playing = false
	beat_timer.stop()
	
	# Stop all layers
	for category in layers.keys():
		for layer_name in layers[category].keys():
			var layer = layers[category][layer_name]
			if layer:
				layer.stop()

func _start_ambient_layers():
	"""Start continuous ambient layers"""
	if layers["fx"]["ambient"]:
		layers["fx"]["ambient"].enabled = true
	if layers["synths"]["pad"]:
		layers["synths"]["pad"].enabled = true

func set_bpm(new_bpm: float):
	"""Change the track BPM"""
	bpm = new_bpm
	beat_timer.wait_time = 60.0 / bpm / 4.0
	print("🎵 BPM changed to %.1f" % bpm)

# ===== LAYER CONTROL API =====

func set_layer_enabled(category: String, layer: String, enabled: bool):
	"""Enable/disable a specific layer"""
	if layers.has(category) and layers[category].has(layer):
		var layer_obj = layers[category][layer]
		if layer_obj:
			layer_obj.enabled = enabled
			print("Track: %s/%s = %s" % [category, layer, enabled])

func set_layer_volume(category: String, layer: String, volume_db: float):
	"""Set layer volume"""
	if layers.has(category) and layers[category].has(layer):
		var layer_obj = layers[category][layer]
		if layer_obj:
			layer_obj.layer_volume = volume_db

func set_layer_solo(category: String, layer: String, solo: bool):
	"""Solo a layer (mute all others)"""
	if layers.has(category) and layers[category].has(layer):
		var layer_obj = layers[category][layer]
		if layer_obj:
			layer_obj.solo = solo
			
			# Mute all other layers if soloing
			if solo:
				for cat in layers.keys():
					for lyr in layers[cat].keys():
						var other_layer = layers[cat][lyr]
						if other_layer and other_layer != layer_obj:
							other_layer.muted_by_solo = true
			else:
				# Unmute if no other layers are solo
				var any_solo = false
				for cat in layers.keys():
					for lyr in layers[cat].keys():
						var other_layer = layers[cat][lyr]
						if other_layer and other_layer.solo:
							any_solo = true
							break
				
				if not any_solo:
					for cat in layers.keys():
						for lyr in layers[cat].keys():
							var other_layer = layers[cat][lyr]
							if other_layer:
								other_layer.muted_by_solo = false

func get_layer(category: String, layer: String) -> TrackLayer:
	"""Get a specific layer object"""
	if layers.has(category) and layers[category].has(layer):
		return layers[category][layer]
	return null

# ===== PATTERN CONTROL =====

func set_pattern_length(category: String, length: int):
	"""Set pattern length for a category"""
	pattern_lengths[category] = length
	
	# Update all layers in category
	if layers.has(category):
		for layer_name in layers[category].keys():
			var layer = layers[category][layer_name]
			if layer:
				layer.pattern_length = length

func get_track_info() -> Dictionary:
	"""Get comprehensive track information"""
	var layer_info = {}
	
	for category in layers.keys():
		layer_info[category] = {}
		for layer_name in layers[category].keys():
			var layer = layers[category][layer_name]
			if layer:
				layer_info[category][layer_name] = {
					"enabled": layer.enabled,
					"solo": layer.solo,
					"volume": layer.layer_volume,
					"pattern_length": layer.pattern_length
				}
	
	return {
		"is_playing": is_playing,
		"global_beat": global_beat,
		"bpm": bpm,
		"layers": layer_info,
		"pattern_lengths": pattern_lengths
	}

# ===== CONSOLE COMMANDS =====

func info():
	"""Show detailed track information"""
	var track_info = get_track_info()
	print("🎛️ ENHANCED TRACK INFO 🎛️")
	print("   Playing: %s | Beat: %d | BPM: %.1f" % [track_info.is_playing, track_info.global_beat, track_info.bpm])
	
	for category in track_info.layers.keys():
		print("   [%s]:" % category.to_upper())
		for layer_name in track_info.layers[category].keys():
			var layer_data = track_info.layers[category][layer_name]
			print("     %s: %s | Vol: %.1fdB | Solo: %s" % [
				layer_name, 
				"ON" if layer_data.enabled else "OFF",
				layer_data.volume,
				"YES" if layer_data.solo else "NO"
			]) 