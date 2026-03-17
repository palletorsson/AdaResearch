@tool
class_name FacadePlanNode
extends Node3D

## @tool Node3D that loads a facade plan JSON and builds a CSG facade.
## Complements FacadeGrammarNode: this uses CSG nodes for real-time editing,
## while FacadeGrammarNode uses MeshData for the procedural pipeline.
##
## Usage:
##   1. Add a FacadePlanNode to your scene
##   2. Set plan_path to a facade_plan.json file
##   3. The facade rebuilds automatically on property changes
##
## You can also call rebuild_from_dict() at runtime with a Dictionary.


## Path to the facade plan JSON file (exported from the web editor).
@export_file("*.json") var plan_path: String = "":
	set(v):
		plan_path = v
		if auto_rebuild and is_inside_tree():
			rebuild()

## Automatically rebuild when properties change.
@export var auto_rebuild: bool = true:
	set(v):
		auto_rebuild = v
		if v and is_inside_tree() and plan_path != "":
			rebuild()

## Override total facade width (0 = use JSON value).
@export var total_width_override: float = 0.0:
	set(v):
		total_width_override = v
		if auto_rebuild and is_inside_tree():
			rebuild()

## Override total facade height (0 = use JSON value).
@export var total_height_override: float = 0.0:
	set(v):
		total_height_override = v
		if auto_rebuild and is_inside_tree():
			rebuild()

@export_group("Appearance")

## Base wall color. Applied as an override tint (alpha > 0 = active).
@export var base_color: Color = Color(0.85, 0.8, 0.72, 0.0):
	set(v):
		base_color = v
		if auto_rebuild and is_inside_tree():
			rebuild()

## Surface roughness for stone materials (0 = mirror, 1 = matte).
@export var roughness: float = 0.8:
	set(v):
		roughness = v
		if auto_rebuild and is_inside_tree():
			rebuild()

## Scale multiplier for the entire facade.
@export var facade_scale: float = 1.0:
	set(v):
		facade_scale = v
		if _facade_root:
			_facade_root.scale = Vector3.ONE * facade_scale

## Signal emitted after a successful rebuild.
signal facade_built()

## Internal reference to the generated facade subtree.
var _facade_root: Node3D = null


func _ready() -> void:
	if plan_path != "":
		rebuild()


## Force a rebuild from the current plan_path.
func rebuild() -> void:
	_clear_facade()

	if plan_path == "":
		return

	# Load JSON
	var data := _load_json_file(plan_path)
	if data.is_empty():
		push_warning("FacadePlanNode: Failed to load '%s'" % plan_path)
		return

	_build_facade(data)


## Rebuild from a Dictionary (for runtime / programmatic use).
func rebuild_from_dict(data: Dictionary) -> void:
	_clear_facade()
	if data.is_empty():
		push_warning("FacadePlanNode: rebuild_from_dict called with empty data")
		return
	_build_facade(data)


## Get the generated facade root node (or null).
func get_facade_root() -> Node3D:
	return _facade_root


# ─── INTERNALS ─────────────────────────────────────────────────────────────


## Remove the old facade subtree.
func _clear_facade() -> void:
	if _facade_root and is_instance_valid(_facade_root):
		_facade_root.queue_free()
		_facade_root = null


## Apply dimension overrides to the data dict if non-zero.
func _apply_overrides(data: Dictionary) -> Dictionary:
	var d := data.duplicate(true)
	if not d.has("facade"):
		d["facade"] = {}
	if total_width_override > 0:
		d["facade"]["total_width"] = total_width_override
	if total_height_override > 0:
		d["facade"]["total_height"] = total_height_override
	return d


## Build the facade from (optionally overridden) data.
func _build_facade(data: Dictionary) -> void:
	var final_data := _apply_overrides(data)
	_facade_root = FacadePlanImporter.import_from_dict(final_data)
	if not _facade_root:
		push_warning("FacadePlanNode: Importer returned null")
		return

	_facade_root.name = "GeneratedFacade"
	_facade_root.scale = Vector3.ONE * facade_scale
	add_child(_facade_root)

	# Tint override (alpha > 0 means the user set a color)
	if base_color.a > 0:
		_apply_color_override(_facade_root, base_color)

	# Apply roughness override to all StandardMaterial3D in the subtree
	if roughness != 0.8:
		_apply_roughness(_facade_root, roughness)

	# In editor, set owner so the subtree appears in the scene tree
	if Engine.is_editor_hint():
		_set_owner_recursive(_facade_root, get_tree().edited_scene_root)

	facade_built.emit()
	print("FacadePlanNode: Facade rebuilt from '%s'" % plan_path)


## Load a JSON file and return a Dictionary.
func _load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("FacadePlanNode: File not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("FacadePlanNode: JSON parse error: %s" % json.get_error_message())
		return {}
	if json.data is Dictionary:
		return json.data
	return {}


## Tint all stone materials in the subtree towards the override color.
func _apply_color_override(node: Node, color: Color) -> void:
	if node is CSGShape3D:
		var csg := node as CSGShape3D
		if csg.material is StandardMaterial3D:
			var mat := csg.material as StandardMaterial3D
			mat.albedo_color = mat.albedo_color.lerp(color, 0.5)

	for child in node.get_children():
		_apply_color_override(child, color)


## Override roughness on all StandardMaterial3D in the subtree.
func _apply_roughness(node: Node, r: float) -> void:
	if node is CSGShape3D:
		var csg := node as CSGShape3D
		if csg.material is StandardMaterial3D:
			(csg.material as StandardMaterial3D).roughness = r

	for child in node.get_children():
		_apply_roughness(child, r)


## Set owner recursively so nodes appear in the editor scene tree.
func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	if node != self:
		node.owner = owner_node
	for child in node.get_children():
		_set_owner_recursive(child, owner_node)
