extends Resource
class_name MusicGraphNode

@export var id: String
@export var chord_notes: Array = ["C4"] # Renamed from notes to avoid collisions/cache
@export var instrument: String = "synth" # "synth", "piano", "bass"
@export var duration: float = 1.0
@export var position: Vector3 = Vector3.ZERO
@export var color: Color = Color(0.2, 0.4, 0.8)

# Logic properties
@export var probability_mod: float = 1.0 # 1.0 = normal, 0.0 = skip?

# Edges: Array of dictionaries { "target_id": "ID", "type": "next"|"fork"|"loop", "chance": 1.0 }
@export var edges: Array[Dictionary] = []

func add_edge(target_id: String, type: String = "next", chance: float = 1.0):
	edges.append({
		"target_id": target_id,
		"type": type,
		"chance": chance
	})

# Helper to get formatted string
func get_label() -> String:
	if chord_notes.size() == 1:
		return chord_notes[0]
	elif chord_notes.size() > 1:
		return chord_notes[0] + "+" # Indicate chord
	return ""
