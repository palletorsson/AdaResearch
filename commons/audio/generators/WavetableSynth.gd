extends Node
class_name WavetableSynth

# Wavetable Synth Node Wrapper
# Manages a WavetableGenerator instance and handles Note On/Off logic.
# Port from algorithms/proceduralaudio/space_dystopia/WavetableSynth.gd

@onready var generator: WavetableGenerator = WavetableGenerator.new()

@export var output_bus: String = "Master"
@export var gain: float = 0.5

func _ready():
	add_child(generator)
	generator.output_bus = output_bus

func play_note(freq: float, vel: float, pos: float = 0.0):
	# Simple monophonic handling for now
	generator.play_note(freq, vel * gain, pos)

func stop_note():
	generator.stop_note()

func set_shape_pos(pos: float):
	generator.table_pos = pos
