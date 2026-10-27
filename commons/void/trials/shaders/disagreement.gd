extends "res://commons/artifacts/model_disagreement/model_disagreement.gd"
## Relocate the museum's distant furniture, retaining model-space calculations.

func _ready() -> void:
	super._ready()
	panel.position.z = 3.5
	reference.position = Vector3(-2.5,.8,2)
	for child in get_children():
		if child is Node3D and child != reference and child != panel and child != body and child != installation_sign:
			if child.position.z >= 7.5:
				child.position += Vector3(2.5,0,-6)
	caption.position = Vector3(2,2.9,2.5)

func apply_installation() -> void:
	var existed := installation_sign != null
	super.apply_installation()
	if not existed and installation_sign != null:
		for child in installation_sign.get_children():
			if child is Node3D:
				if child.position.x > 10:
					child.position += Vector3(-16,0,15)
				else:
					child.position += Vector3(2.5,0,-6)
