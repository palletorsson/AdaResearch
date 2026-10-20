extends Node3D
## Exposed supply connection. Place its back against a wall/pillar in the editor.
const Supply := preload("hardware_supply.gd")
const Zone := preload("electric_zone.gd")
const Ink := preload("res://commons/utils/baked_text_albedo.gd")
var zone: Area3D
func _ready() -> void:
	var cabinet := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.55,0.7,0.2)
	cabinet.mesh = box
	cabinet.position = Vector3(0,1.1,0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("53594e")
	mat.roughness = 0.8
	cabinet.material_override = mat
	add_child(cabinet)
	var label := MeshInstance3D.new()
	var face := QuadMesh.new()
	face.size = Vector2(0.48,0.085)
	label.mesh = face
	label.position = Vector3(0,1.39,0.105)
	var printing := StandardMaterial3D.new()
	printing.albedo_texture = Ink.generate_text_image("LIVE / DISCHARGE",Color("f7c869"),Vector2i(768,128),58,"medium")
	printing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	label.material_override = printing
	add_child(label)
	for x in [-0.13,0.13]:
		var terminal := MeshInstance3D.new()
		var contact := BoxMesh.new()
		contact.size = Vector3(0.06,0.28,0.12)
		terminal.mesh = contact
		terminal.position = Vector3(x,1.08,0.16)
		var copper := StandardMaterial3D.new()
		copper.albedo_color = Color("c4a36b")
		copper.metallic = 0.6
		terminal.material_override = copper
		add_child(terminal)
	Supply.connect_unit(self,Vector3(0,1.5,-0.1))
	zone = Zone.new()
	zone.name = "ExposedContact"
	zone.position = Vector3(0,0.9,0.45)
	var collider := CollisionShape3D.new()
	collider.name = "CollisionShape3D"
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(0.65,1.6,0.7)
	collider.shape = bounds
	zone.add_child(collider)
	add_child(zone)
