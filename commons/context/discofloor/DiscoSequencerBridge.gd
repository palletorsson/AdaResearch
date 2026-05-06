# DiscoSequencerBridge.gd
# Connects a StepSequencer's beat to a StandaloneDiscoFloor.
# On each sequencer step: pulse tiles to the beat.
# On kick (track 0): advance disco pattern.
# Attach as child of either the disco floor or sequencer — finds the other automatically.
extends Node

class_name DiscoSequencerBridge

var disco_floor: StandaloneDiscoFloor
var step_sequencer: StepSequencer
var _beat_step: int = 0

func _ready() -> void:
	await get_tree().process_frame
	_find_references()
	if not disco_floor or not step_sequencer:
		push_warning("DiscoSequencerBridge: Could not find both disco floor and step sequencer")
		return
	step_sequencer.step_triggered.connect(_on_step_triggered)
	print("DiscoSequencerBridge: Wired sequencer → disco floor")

func _find_references() -> void:
	# Check parent chain first
	var node := get_parent()
	while node:
		if node is StandaloneDiscoFloor:
			disco_floor = node
		if node is StepSequencer:
			step_sequencer = node
		node = node.get_parent() if node.get_parent() != node else null

	# Search scene tree for missing refs
	if not disco_floor:
		disco_floor = _find_type(get_tree().current_scene, "StandaloneDiscoFloor") as StandaloneDiscoFloor
	if not step_sequencer:
		step_sequencer = _find_type(get_tree().current_scene, "StepSequencer") as StepSequencer

func _find_type(root: Node, class_str: String) -> Node:
	if root.get_class() == class_str or root.script and root.get_script().get_global_name() == class_str:
		return root
	# Also check by class_name matching
	if root is StandaloneDiscoFloor and class_str == "StandaloneDiscoFloor":
		return root
	if root is StepSequencer and class_str == "StepSequencer":
		return root
	for child in root.get_children():
		var found := _find_type(child, class_str)
		if found:
			return found
	return null

func _on_step_triggered(track: int, step: int) -> void:
	_beat_step = step

	# Every beat: pulse brightness on the current step column
	if disco_floor and disco_floor.is_running:
		_pulse_column(step % disco_floor.grid_width)

	# Kick (track 0) on beat 0: advance pattern every 4 bars (16 steps × 4)
	if track == 0 and step == 0:
		_beat_step = 0
		# Advance pattern every time we loop back to step 0
		if disco_floor:
			disco_floor.next_pattern()

func _pulse_column(col: int) -> void:
	# Brief white flash on one column to visualize the beat
	for z in range(disco_floor.grid_depth):
		var current := disco_floor.tile_colors[z * disco_floor.grid_width + col]
		var flashed := current.lerp(Color.WHITE, 0.4)
		disco_floor._set_tile(col, z, flashed)
