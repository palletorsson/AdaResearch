# DiscoFloorController.gd
# Simple controller that instantiates the DiscoGridAlgorithm
# Maintains the same interface as the old disco floor

extends Node3D

var disco_algorithm: DiscoGridAlgorithm
var disco_music = null  # Optional music component
var music_enabled: bool = false

func _ready():
	print("🎉 DiscoFloorController: Setting up grid-based disco system")
	
	# Create the disco grid algorithm
	disco_algorithm = DiscoGridAlgorithm.new()
	disco_algorithm.name = "DiscoGridAlgorithm"
	add_child(disco_algorithm)
	
	# Connect to algorithm signals for feedback
	disco_algorithm.lesson_changed.connect(_on_lesson_changed)
	disco_algorithm.algorithm_finished.connect(_on_algorithm_finished)
	
	# Optional: Add music (if desired)
	if music_enabled:
		_setup_music()
	
	print("🕺 DiscoFloorController: Grid disco system ready!")

func _setup_music():
	"""Setup optional disco music"""
	# You can add SimpleDiscoMusic here if desired
	# disco_music = SimpleDiscoMusic.new()
	# disco_music.name = "DiscoMusic"
	# disco_music.set_educational_mode(true)
	# add_child(disco_music)
	pass

func _on_lesson_changed(lesson_name: String):
	"""Handle lesson changes"""
	print("🎓 DiscoFloorController: Lesson changed to %s" % lesson_name)

func _on_algorithm_finished():
	"""Handle algorithm completion"""
	print("🎉 DiscoFloorController: All lessons completed!")

# === PUBLIC API (maintains compatibility with old disco floor) ===

func toggle_disco():
	"""Toggle disco visuals"""
	if disco_algorithm:
		disco_algorithm.toggle_disco()

func toggle_music():
	"""Toggle disco music (if available)"""
	if disco_music and disco_music.has_method("toggle_music"):
		disco_music.toggle_music()

func set_music_volume(vol: float):
	"""Set music volume (if available)"""
	if disco_music and disco_music.has_method("set_volume"):
		disco_music.set_volume(vol)

func next_lesson():
	"""Skip to next lesson"""
	if disco_algorithm:
		disco_algorithm.next_lesson()

func restart_lessons():
	"""Restart from first lesson"""
	if disco_algorithm:
		disco_algorithm.restart_lessons()

func start_disco():
	"""Start the disco algorithm"""
	if disco_algorithm:
		disco_algorithm.start_algorithm()

func stop_disco():
	"""Stop the disco algorithm"""
	if disco_algorithm:
		disco_algorithm.stop_algorithm()

func get_disco_info() -> Dictionary:
	"""Get disco information"""
	if disco_algorithm:
		return disco_algorithm.get_disco_info()
	return {"enabled": false, "error": "No algorithm"}

func print_disco_status():
	"""Print current disco status"""
	print("=== DISCO FLOOR STATUS ===")
	if disco_algorithm:
		var info = disco_algorithm.get_algorithm_info()
		print("Algorithm: %s" % info.get("name", "Unknown"))
		print("Current lesson: %s" % info.get("current_lesson", "None"))
		print("Disco cubes: %d" % info.get("disco_cubes", 0))
		print("Running: %s" % info.get("is_running", false))
		print("Region: %s" % str(info.get("region_bounds", {})))
	else:
		print("No disco algorithm found!")
	print("========================")
