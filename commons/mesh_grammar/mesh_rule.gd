## MeshRule — Base class for all mesh grammar operations.
## Each rule selects elements via a MeshSelector, then applies its operation.
extends RefCounted
class_name MeshRule

var selector: MeshSelector = null
var params: Dictionary = {}

func _init(p_selector: MeshSelector = null, p_params: Dictionary = {}) -> void:
	if p_selector == null:
		selector = MeshSelector.all_faces()
	else:
		selector = p_selector
	params = p_params

## Apply this rule to a mesh. Returns the (mutated) mesh.
func apply(mesh: MeshData) -> MeshData:
	var selected: PackedInt32Array = selector.select(mesh)
	if selected.is_empty():
		return mesh
	_execute(mesh, selected)
	return mesh

## Override in subclasses to implement the operation.
func _execute(_mesh: MeshData, _selected: PackedInt32Array) -> void:
	pass
