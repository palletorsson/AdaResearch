extends RefCounted
## Local studio finishes. Never edits source scenes or shared materials.
static var _materials: Dictionary = {}

static func material(role: String) -> StandardMaterial3D:
	if _materials.has(role):return _materials[role]
	var result:=StandardMaterial3D.new()
	result.albedo_color=Color("eee8dc" if role=="ivory" else "e64b91" if role=="pink" else "171c26")
	result.metallic=.12 if role=="ivory" else .42 if role=="pink" else .65
	result.roughness=.42 if role=="ivory" else .26 if role=="pink" else .24
	_materials[role]=result
	return result

static func apply(node: Node,role: String) -> void:
	for child in node.find_children("*","MeshInstance3D",true,false):
		child.material_override=material(role)
