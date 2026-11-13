extends RefCounted
## Local studio finishes. Never edits source scenes or shared materials.
static var _materials: Dictionary = {}
static var _palette: Dictionary = {}

static func material(role: String) -> StandardMaterial3D:
	if _materials.has(role):return _materials[role]
	if _palette.is_empty():_palette=JSON.parse_string(FileAccess.get_file_as_string("res://commons/modular/fractal_studio.json")).palette
	var finish: Dictionary=_palette[role]
	var result:=StandardMaterial3D.new()
	result.albedo_color=Color(str(finish.color))
	result.metallic=float(finish.metallic)
	result.roughness=float(finish.roughness)
	_materials[role]=result
	return result

static func apply(node: Node,role: String) -> void:
	for child in node.find_children("*","MeshInstance3D",true,false):
		child.material_override=material(role)
