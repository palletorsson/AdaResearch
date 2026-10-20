extends Node3D
## A finite map inside the shared XR viewing rig. Its scene defines the route.
const Course := preload("course.gd")
const Chunk := preload("chunk.gd")
@export var title := "POINT / LINE"
@export_range(0, 3) var chapter := 0
@export_range(1, 10) var sections := 3
@export var course_seed := 17
@export var start_speed := 5.5
var finish_gate: Node3D

func length_m() -> float:
	return sections * Course.LENGTH

func _ready() -> void:
	finish_gate = Node3D.new()
	finish_gate.name = "FinishGate"
	finish_gate.position.z = -length_m()
	add_child(finish_gate)
	var accent: Color = Chunk.ACCENTS[chapter]
	for x in [-3.6, 3.6]:
		finish_box(Vector3(x, 2.0, 0), Vector3(0.18, 4, 0.18), accent)
	finish_box(Vector3(0, 4, 0), Vector3(7.4, 0.18, 0.18), accent)
	# A visible threshold, with no collider to kill the ball at its destination.
	for tile in range(12):
		finish_box(Vector3(-3.025 + tile * 0.55, 0.012, 0), Vector3(0.55, 0.02, 0.8),
			Color("eee9df") if tile % 2 == 0 else Color("171a24"))
	var label := Label3D.new()
	label.text = "FINISH"
	label.position = Vector3(0, 3.35, 0.12)
	label.font_size = 80
	label.pixel_size = 0.008
	label.outline_size = 0
	label.modulate = accent
	finish_gate.add_child(label)

func finish_box(at: Vector3, size: Vector3, colour: Color) -> void:
	var mesh := Chunk.BoxBody.new(size)
	mesh.position = at
	mesh.material_override = Chunk.finish(colour, 0.4, 0.15)
	finish_gate.add_child(mesh)
