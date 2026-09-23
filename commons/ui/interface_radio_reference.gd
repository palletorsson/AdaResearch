extends Node3D
## The actual radio mounted at an operating height, with its original face choices.
var radio: Node3D
func _ready() -> void:
	radio = preload("res://commons/audio/rack_configs/SoundscapeRadioRack.tscn").instantiate()
	radio.position = Vector3(0,1.20,0)
	radio.rotation_degrees.x = -15
	add_child(radio)
	var stand := MeshInstance3D.new()
	stand.name = "RadioPlinth"
	stand.mesh = BoxMesh.new()
	stand.mesh.size = Vector3(.62,.86,.35)
	stand.position = Vector3(0,.43,-.04)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(.14,.19,.20)
	material.roughness = .8
	stand.material_override = material
	add_child(stand)
