extends VectorSceneBase

var vector_a: Node3D
var unit_vector: Node3D
var component_vectors := {
	"x": null,
	"y": null,
	"z": null
}
var info_label: Label3D

func _ready():
	super._ready()
	create_axes(3.0)
	create_floor(8.0)
	vector_a = spawn_vector(Vector3.ZERO, Vector3(1.5, 1.0, 0.5), Color(0.95, 0.85, 0.2, 1.0), "Vector a")
	unit_vector = spawn_vector(Vector3.ZERO, Vector3(1, 0, 0), Color(1.0, 0.4, 0.9, 1.0), "Unit a", false)
	component_vectors["x"] = spawn_vector(Vector3.ZERO, Vector3(1.5, 0, 0), Color(1.0, 0.3, 0.3, 1.0), "a_x", false)
	component_vectors["y"] = spawn_vector(Vector3.ZERO, Vector3(0, 1.0, 0), Color(0.3, 1.0, 0.3, 1.0), "a_y", false)
	component_vectors["z"] = spawn_vector(Vector3.ZERO, Vector3(0, 0, 0.5), Color(0.3, 0.5, 1.0, 1.0), "a_z", false)
	info_label = create_info_panel("Vector a", Vector3(-2.2, 2.0, 0.0))

func _process(_delta):
	var vec = get_vector(vector_a)
	_update_unit_vector(vec)
	_update_components(vec)
	_update_info(vec)

func _update_unit_vector(vec: Vector3):
	var magnitude = vec.length()
	if magnitude > 0.001:
		var hat = vec / magnitude
		update_vector(unit_vector, hat)
	else:
		update_vector(unit_vector, Vector3.ZERO)

func _update_components(vec: Vector3):
	update_vector(component_vectors["x"], Vector3(vec.x, 0.0, 0.0))
	update_vector(component_vectors["y"], Vector3(0.0, vec.y, 0.0))
	update_vector(component_vectors["z"], Vector3(0.0, 0.0, vec.z))

func _update_info(vec: Vector3):
	var magnitude = vec.length()
	var hat = vec / magnitude if magnitude > 0.001 else Vector3.ZERO
	var builder := []
	builder.append("Vector a = (%.2f, %.2f, %.2f)" % [vec.x, vec.y, vec.z])
	builder.append("|a| = %.2f" % magnitude)
	builder.append("Unit a = (%.2f, %.2f, %.2f)" % [hat.x, hat.y, hat.z])
	builder.append("Components -> x: %.2f, y: %.2f, z: %.2f" % [vec.x, vec.y, vec.z])
	info_label.text = "\n".join(builder)
