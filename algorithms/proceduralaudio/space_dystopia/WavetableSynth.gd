extends Node
class_name WavetableSynth

# Wavetable Synth Node Wrapper
# Manages a WavetableGenerator instance and handles Note On/Off logic.

@onready var generator: WavetableGenerator = WavetableGenerator.new()

@export var output_bus: String = "Master"
@export var gain: float = 0.5

func _ready() -> void:
	add_child(generator)
	generator.output_bus = output_bus
	# Wait for generator ready? It happens automatically on add_child

func play_note(freq: float, vel: float, pos: float = 0.0) -> void:
	# Simple monophonic handling for now
	generator.play_note(freq, vel * gain, pos)

func stop_note() -> void:
	generator.stop_note()

func set_shape_pos(pos: float) -> void:
	generator.table_pos = pos

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

