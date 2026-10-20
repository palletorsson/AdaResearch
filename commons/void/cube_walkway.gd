extends "res://commons/void/lines_area.gd"
## One construction recipe, shared by Cube, the editor palette and Transformation.
## Every member remains a separately editable part with a stable name.
const Cube = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn")
const Wedge = preload("res://commons/artifacts/primitive_encounters/wedge_blocker.tscn")
const RECIPE_PATH := "res://commons/void/cube_walkway.json"
@export_file("*.json") var recipe_path := RECIPE_PATH
var recipe: Dictionary = {}

func _ready() -> void:
	recipe=JSON.parse_string(FileAccess.get_file_as_string(recipe_path))
	set_meta("construction_definition",recipe.id)
	set_meta("construction_recipe",recipe_path)
	for member in recipe.members:
		var piece := (Cube if member.kind=="cube" else Wedge).instantiate() as Node3D
		piece.name=member.id
		piece.position=Vector3(member.position[0],member.position[1],member.position[2])
		piece.rotation_degrees.y=float(member.facing)
		piece.set_meta("construction_member",member.kind)
		add_child(piece)
	for entry in recipe.signs:
		var sign := words(entry.text,Vector3(entry.position[0],entry.position[1],entry.position[2]),true,.0014)
		sign.name=entry.id
		sign.modulate=Color("eee6df")
	for child in get_children():
		if child is Node3D:
			var bounds := _mesh_bounds(child,child)
			part_defaults[str(child.name)]={"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z],"bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z]}
