extends Node3D
## Shared metre-module recipe; the editor reads this same JSON.
const RECIPE := "res://commons/void/steel_modules.json"
var kind := "truss"

func _ready() -> void:
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RECIPE))[kind]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new()
	add_child(body)
	for part in recipe.parts:
		var mesh := BoxMesh.new()
		mesh.size = _v(part.size)
		var pose := Transform3D(Basis(Vector3.FORWARD, -deg_to_rad(float(part.get("angle", 0)))), _v(part.position))
		surface.append_from(mesh, 0, pose)
		if part.get("collision", true):
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = mesh.size
			shape.shape = box
			shape.transform = pose
			body.add_child(shape)
	var visual := MeshInstance3D.new()
	visual.name = kind.capitalize()
	visual.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(recipe.color)
	material.roughness = .72
	material.metallic = .25
	visual.material_override = material
	add_child(visual)

func _v(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))
