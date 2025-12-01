extends Node
class_name IntensityController

## IntensityController
## Oscillates a global intensity value (0.0 - 1.0) over time
## and applies it to a target system.

enum WaveShape { SINE, TRIANGLE }

@export var target_node_path: NodePath
@export var min_intensity: float = 0.01
@export var max_intensity: float = 0.3
@export var period: float = 60.0 # Seconds for full cycle
@export var shape: WaveShape = WaveShape.SINE
@export var active: bool = true

var _time: float = 0.0
var _target_node: Node

func _ready():
	if target_node_path:
		_target_node = get_node(target_node_path)

func _process(delta):
	if not active or not _target_node: return
	
	_time += delta
	var phase = fmod(_time, period) / period
	var wave_val = 0.0
	
	match shape:
		WaveShape.SINE:
			# -1 to 1 -> 0 to 1
			wave_val = (sin(phase * TAU) * 0.5) + 0.5
		WaveShape.TRIANGLE:
			# 0 -> 1 -> 0
			if phase < 0.5:
				wave_val = phase * 2.0
			else:
				wave_val = 1.0 - (phase - 0.5) * 2.0
	
	var intensity = lerp(min_intensity, max_intensity, wave_val)
	
	if _target_node.has_method("set_intensity"):
		_target_node.set_intensity(intensity)
		
	# Debug visual?
	# print("Intensity: %.2f" % intensity)
