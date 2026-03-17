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


## Path to the facade plan JSON file (exported from the web editor).
@export_file("*.json") var plan_path: String = "":
	set(v):
		plan_path = v
		if auto_rebuild and is_inside_tree():
			_rebuild()

## Automatically rebuild when properties change.
@export var auto_rebuild: bool = true:
	set(v):
		auto_rebuild = v
		if v and is_inside_tree() and plan_path != "":
			_rebuild()

## Override the primary wall color (empty = use JSON value).
@export var color_override: Color = Color(0, 0, 0, 0):
	set(v):
		color_override = v
		if auto_rebuild and is_inside_tree():
			_rebuild()

## Scale multiplier for the entire facade.
@export var facade_scale: float = 1.0:
	set(v):
		facade_scale = v
		if _facade_root:
			_facade_root.scale = Vector3.ONE * facade_scale

## Signal emitted after a successful rebuild.
signal facade_rebuilt()

## Internal reference to the generated facade subtree.
var _facade_root: Node3D = null


func _ready() -> void:
	if plan_path != "":
		_rebuild()


func _rebuild() -> void:
	# Remove old facade
	if _facade_root and is_instance_valid(_facade_root):
		_facade_root.queue_free()
		_facade_root = null

	if plan_path == "":
		return

	# Load and build
	_facade_root = FacadePlanImporter.import_plan(plan_path)
	if not _facade_root:
		push_warning("FacadePlanNode: Failed to build facade from '%s'" % plan_path)
		return

	_facade_root.name = "GeneratedFacade"
	_facade_root.scale = Vector3.ONE * facade_scale
	add_child(_facade_root)

	# Apply color override if set (alpha > 0 means it's been set)
	if color_override.a > 0:
		_apply_color_override(_facade_root, color_override)

	# In editor, set owner so the subtree is visible in the scene tree
	if Engine.is_editor_hint():
		_set_owner_recursive(_facade_root, get_tree().edited_scene_root)

	facade_rebuilt.emit()
	print("FacadePlanNode: Facade rebuilt from '%s'" % plan_path)


## Force a manual rebuild (useful from scripts).
func rebuild() -> void:
	_rebuild()


## Get the generated facade root node.
func get_facade_root() -> Node3D:
	return _facade_root


## Apply a color override to all stone materials in the subtree.
func _apply_color_override(node: Node, color: Color) -> void:
	if node is CSGShape3D:
		var csg := node as CSGShape3D
		if csg.material is StandardMaterial3D:
			var mat := csg.material as StandardMaterial3D
			# Tint the existing color towards the override
			mat.albedo_color = mat.albedo_color.lerp(color, 0.5)

	for child in node.get_children():
		_apply_color_override(child, color)


## Set owner recursively so nodes appear in the editor scene tree.
func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	if node != self:
		node.owner = owner_node
	for child in node.get_children():
		_set_owner_recursive(child, owner_node)
