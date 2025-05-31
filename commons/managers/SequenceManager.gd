# SequenceManager.gd
# Manages execution of thematic sequences (like array tutorial, randomness exploration)
# Handles transitions between maps within a sequence without changing scenes
extends Node
class_name SequenceManager

# Current sequence state
var current_sequence: String = ""
var current_sequence_def: Dictionary = {}
var current_step: int = 0
var total_steps: int = 0
var staging_ref: XRToolsStaging
var grid_system: Node3D

# Sequence progress
var sequence_history: Array[String] = []

# Signals
signal sequence_started(sequence_name: String)
signal sequence_step_completed(sequence_name: String, step: int, map_name: String)
signal sequence_completed(sequence_name: String)
signal sequence_failed(sequence_name: String, reason: String)

func _ready():
	print("SequenceManager: Ready")

func start_sequence(sequence_name: String, sequence_def: Dictionary, staging: XRToolsStaging):
	if not current_sequence.is_empty():
		print("SequenceManager: WARNING - Already running sequence '%s', aborting" % current_sequence)
		return
	
	current_sequence = sequence_name
	current_sequence_def = sequence_def
	current_step = 0
	total_steps = sequence_def.maps.size()
	staging_ref = staging
	
	print("SequenceManager: Starting sequence '%s' with %d steps" % [sequence_name, total_steps])
	print("  Maps: %s" % sequence_def.maps)
	
	# Find grid system
	_find_grid_system()
	
	if not grid_system:
		sequence_failed.emit(sequence_name, "Grid system not found")
		_reset_sequence_state()
		return
	
	# Start first step
	_advance_to_next_step()
	sequence_started.emit(sequence_name)

func _find_grid_system():
	# Find the grid system in the current scene
	var current_scene = staging_ref.current_scene
	if current_scene:
		grid_system = current_scene.find_child("multiLayerGrid", true, false)
		if not grid_system:
			# Try other common names
			grid_system = current_scene.find_child("GridSystem", true, false)
		if not grid_system:
			grid_system = current_scene.find_child("GridSystemEnhanced", true, false)
	
	if grid_system:
		print("SequenceManager: Found grid system: %s" % grid_system.name)
		
		# Connect to grid system completion signals if available
		if grid_system.has_signal("map_completed"):
			if not grid_system.map_completed.is_connected(_on_map_completed):
				grid_system.map_completed.connect(_on_map_completed)
		elif grid_system.has_signal("teleporter_activated"):
			if not grid_system.teleporter_activated.is_connected(_on_teleporter_activated):
				grid_system.teleporter_activated.connect(_on_teleporter_activated)
	else:
		print("SequenceManager: ERROR - Grid system not found!")

func _advance_to_next_step():
	if current_step >= total_steps:
		_complete_sequence()
		return
	
	var map_name = current_sequence_def.maps[current_step]
	print("SequenceManager: Step %d/%d - Loading map '%s'" % [current_step + 1, total_steps, map_name])
	
	# Load the map in the grid system
	_load_map_in_grid_system(map_name)
	
	current_step += 1

func _load_map_in_grid_system(map_name: String):
	if not grid_system:
		print("SequenceManager: ERROR - No grid system available")
		return
	
	# Store map name in history
	sequence_history.append(map_name)
	
	# Load map using grid system
	if grid_system.has_method("load_map"):
		grid_system.load_map(map_name)
	elif grid_system.has_method("set") and "map_name" in grid_system:
		grid_system.set("map_name", map_name)
		if grid_system.has_method("load_map_data"):
			grid_system.load_map_data()
	else:
		print("SequenceManager: ERROR - Grid system doesn't support map loading")
		sequence_failed.emit(current_sequence, "Grid system doesn't support map loading")
		_reset_sequence_state()

func _on_map_completed(map_name: String):
	print("SequenceManager: Map '%s' completed in sequence '%s'" % [map_name, current_sequence])
	
	# Emit step completion
	sequence_step_completed.emit(current_sequence, current_step - 1, map_name)
	
	# Add small delay before advancing to next step
	await get_tree().create_timer(1.0).timeout
	_advance_to_next_step()

func _on_teleporter_activated(teleporter_name: String, destination: String):
	print("SequenceManager: Teleporter '%s' activated with destination '%s'" % [teleporter_name, destination])
	
	# In sequence mode, we don't follow teleporter destinations
	# Instead, we advance to the next step in the sequence
	if destination == "next" or destination == "@next_in_progression":
		var current_map = ""
		if current_step > 0 and current_step <= current_sequence_def.maps.size():
			current_map = current_sequence_def.maps[current_step - 1]
		
		_on_map_completed(current_map)

func _complete_sequence():
	print("SequenceManager: Sequence '%s' completed!" % current_sequence)
	
	var completed_sequence = current_sequence
	sequence_completed.emit(completed_sequence)
	
	# Reset state
	_reset_sequence_state()
	
	# Return to lab by loading base lab map
	_return_to_lab()

func _return_to_lab():
	print("SequenceManager: Returning to lab")
	
	# Load the lab environment
	if grid_system and grid_system.has_method("load_map"):
		grid_system.load_map("Lab")  # We'll create this as the main lab map
	elif grid_system:
		# Clear current grid content and prepare for lab
		if grid_system.has_method("clear_grid"):
			grid_system.clear_grid()
		
		# Load minimal lab environment
		_setup_minimal_lab_environment()

func _setup_minimal_lab_environment():
	print("SequenceManager: Setting up minimal lab environment")
	
	# Create a simple lab environment if no dedicated lab map exists
	if grid_system and grid_system.has_method("load_map_data"):
		# Create minimal map data for lab
		var lab_map_data = {
			"dimensions": [3, 1, 3],
			"grid": [
				[[0, 0, 0],
				 [0, 1, 0],  # Center platform for table
				 [0, 0, 0]]
			],
			"utilities": [],
			"utility_definitions": {}
		}
		
		# Apply lab map data
		if grid_system.has_method("apply_map_data"):
			grid_system.apply_map_data(lab_map_data)

func _reset_sequence_state():
	current_sequence = ""
	current_sequence_def = {}
	current_step = 0
	total_steps = 0
	staging_ref = null
	sequence_history.clear()

# Handle teleporter behavior during sequences
func handle_sequence_teleporter(teleporter_name: String, original_destination: String) -> String:
	if current_sequence.is_empty():
		return original_destination
	
	print("SequenceManager: Handling teleporter '%s' during sequence '%s'" % [teleporter_name, current_sequence])
	
	# During a sequence, "next" always means next step in sequence
	if original_destination == "next" or original_destination == "@next_in_progression":
		if current_step < total_steps:
			var next_map = current_sequence_def.maps[current_step]
			print("  Redirecting to next step: %s" % next_map)
			
			# Trigger step advancement
			call_deferred("_advance_to_next_step")
			
			# Return empty string to prevent normal teleporter behavior
			return ""
		else:
			print("  Sequence completed, returning to lab")
			call_deferred("_complete_sequence")
			return ""
	
	# For other destinations, allow normal behavior
	return original_destination

# Public API
func is_sequence_active() -> bool:
	return not current_sequence.is_empty()

func get_current_sequence_info() -> Dictionary:
	if current_sequence.is_empty():
		return {}
	
	return {
		"sequence_name": current_sequence,
		"current_step": current_step,
		"total_steps": total_steps,
		"current_map": current_sequence_def.maps[current_step - 1] if current_step > 0 else "",
		"next_map": current_sequence_def.maps[current_step] if current_step < total_steps else "",
		"progress_percentage": float(current_step) / float(total_steps) * 100.0,
		"history": sequence_history
	}

func skip_to_step(step_number: int):
	if current_sequence.is_empty():
		print("SequenceManager: No active sequence to skip")
		return
	
	if step_number < 0 or step_number >= total_steps:
		print("SequenceManager: Invalid step number %d (max: %d)" % [step_number, total_steps - 1])
		return
	
	current_step = step_number
	print("SequenceManager: Skipping to step %d" % step_number)
	_advance_to_next_step()

func force_complete_sequence():
	if current_sequence.is_empty():
		print("SequenceManager: No active sequence to complete")
		return
	
	print("SequenceManager: Force completing sequence '%s'" % current_sequence)
	_complete_sequence()

func abort_sequence():
	if current_sequence.is_empty():
		print("SequenceManager: No active sequence to abort")
		return
	
	print("SequenceManager: Aborting sequence '%s'" % current_sequence)
	var aborted_sequence = current_sequence
	_reset_sequence_state()
	_return_to_lab()
	
	sequence_failed.emit(aborted_sequence, "Sequence aborted by user") 