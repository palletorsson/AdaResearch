extends Node3D
## Freestanding, extruded roof lettering. One editable artifact in the lab.
const FONT = preload("res://commons/font/static/Roboto_Condensed-Bold.ttf")

func _ready() -> void:
	var letters := MeshInstance3D.new()
	letters.name = "ADA_RESEARCH"
	var text := TextMesh.new()
	text.font = FONT; text.text = "ADA RESEARCH"
	text.font_size = 160; text.pixel_size = .01; text.depth = .18
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letters.mesh = text
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("f9e8ef")
	finish.metallic = .25; finish.roughness = .3
	finish.emission_enabled = true; finish.emission = Color("d88eaf")
	finish.emission_energy_multiplier = .3
	letters.material_override = finish
	letters.position.y = 6.0
	var factor := 9.6 / text.get_aabb().size.x
	letters.scale = Vector3.ONE * factor
	add_child(letters)
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("242331"); steel.metallic = .65; steel.roughness = .55
	for x in [-4.1,4.1]: box(Vector3(x,2.8,-.22),Vector3(.09,5.6,.12),steel)
	for y in [5.45,6.55]: box(Vector3(0,y,-.22),Vector3(9.8,.06,.12),steel)
	var caption := Label3D.new()
	caption.text = "always another room"
	caption.font = FONT; caption.font_size = 64; caption.pixel_size = .005
	caption.position = Vector3(0,5.05,.03)
	caption.outline_size = 0; caption.modulate = Color("f7dce9")
	add_child(caption)

func box(at: Vector3, size: Vector3, finish: Material) -> void:
	var node := MeshInstance3D.new(); var mesh := BoxMesh.new()
	mesh.size = size; node.mesh = mesh; node.position = at; node.material_override = finish
	add_child(node)
