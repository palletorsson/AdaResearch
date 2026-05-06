extends RefCounted
class_name GraphAgent

# State
var current_node_id: String
var target_node_id: String = ""
var progress: float = 0.0 # 0.0 to 1.0 along the edge
var speed: float = 1.0

# Playback
var instrument_override: String = "" # If empty, use node's instrument
var velocity: float = 0.8
var octave_shift: int = 0

# Visuals
var color_override: Color = Color.WHITE

func _init(start_node: String):
	current_node_id = start_node
