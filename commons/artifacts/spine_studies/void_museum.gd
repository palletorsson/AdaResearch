extends "res://commons/artifacts/kapoor_void_studies/kapoor_void_studies.gd"
## Keep the museum's sky/player. Lift the deep bowl above the shared solid floor.
## The three displays are approached from outside their plinth footprints.
func _build_gallery() -> void:
	_add_backdrop()
	_build_descent_study(Vector3(-5.4,0.75,0))
	_build_void_field_study(Vector3(0,0,0))
	_build_wall_study(Vector3(5.6,0,0))
	_add_lights()
	# Local lamps light this bay; the museum alone owns directional illumination.
	for lamp in _studio_lights:
		if lamp is DirectionalLight3D: lamp.visible = false
	# A visible base supports the raised aperture; its full envelope excludes feet.
	var base := _box("RaisedApertureBase",Vector3(3.55,0.75,3.55),Vector3(-5.4,0.375,0),_wall_material)
	add_child(base)
	for part in [[Vector3(-5.4,0.70,0),Vector3(3.55,1.4,3.55)],[Vector3(0,0.23,0),Vector3(5.25,0.46,3.18)],[Vector3(5.6,2.35,0),Vector3(4.05,4.5,1.15)]]:
		var body := StaticBody3D.new(); body.position = part[0]
		var shape := BoxShape3D.new(); shape.size = part[1]
		var collision := CollisionShape3D.new(); collision.shape = shape; body.add_child(collision); add_child(body)
