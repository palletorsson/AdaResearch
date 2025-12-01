extends Resource
class_name MusicGraphNode

@export var id: String
@export var note: String = "C4"
@export var duration: float = 1.0
@export var position: Vector3 = Vector3.ZERO
@export var color: Color = Color(0.2, 0.4, 0.8) # Default Blue

# Edges: Array of dictionaries { "target_id": "ID", "type": "next"|"fork"|"loop", "chance": 1.0 }
@export var edges: Array[Dictionary] = []

func add_edge(target_id: String, type: String = "next", chance: float = 1.0):
	edges.append({
		"target_id": target_id,
		"type": type,
		"chance": chance
	})
