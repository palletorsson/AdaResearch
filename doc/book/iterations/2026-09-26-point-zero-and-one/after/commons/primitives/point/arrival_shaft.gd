extends Node3D
## A hollow entrance shaft. The museum supplies gravity and arrival height.
## The shaft has no floor: falling reaches the hall's existing collision floor.
func _ready() -> void:
	for i in range(16):
		var angle := TAU * float(i) / 16.0
		var panel := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.50, 4.2, 0.09)
		panel.mesh = box
		panel.position = Vector3(sin(angle) * 1.22, 4.6, cos(angle) * 1.22)
		panel.rotation.y = angle
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.045, 0.04, 0.05)
		mat.roughness = 0.85
		panel.material_override = mat
		add_child(panel)
		panel.create_trimesh_collision()
