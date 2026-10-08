extends "res://commons/artifacts/concept_monitor/preview.gd"
## The real tetrahedron scene supplies its geometry. Freeze only this preview copy.
var body: Node3D

func _ready() -> void:
	super()
	body = load("res://commons/primitives/tetrahedron/grab_tetrahedron.tscn").instantiate()
	body.name = "TetrahedronPreview"
	add_child(body)
	body.set("freeze", true)
	body.position = Vector3(20, 1, 0)
	body.set_process(false)
	body.set_physics_process(false)
	monitor.set("body_path", monitor.get_path_to(body))
	monitor.call("discover_source")
	monitor.call("observe", 0.25)
