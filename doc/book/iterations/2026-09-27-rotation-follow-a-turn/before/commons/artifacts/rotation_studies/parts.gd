extends RefCounted
## Small shared construction helpers; the two studies keep separate geometry.

static func box(parent: Node3D, name: String, size: Vector3, at: Vector3, color: Color, solid: bool = true) -> Node3D:
	var part := Node3D.new()
	part.name = name
	part.position = at
	parent.add_child(part)
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	mesh.material_override = material
	part.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.name = "Body"
		var collision := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		collision.shape = bounds
		body.add_child(collision)
		part.add_child(body)
	return part

static func label(parent: Node3D, text: String, at: Vector3, size: int = 38) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = at
	# Visitors approach from negative z; show the front of the text to them.
	label.rotation_degrees.y = 180
	label.font_size = size
	label.pixel_size = 0.008
	label.outline_size = 7
	label.modulate = Color(0.9,0.94,1)
	label.no_depth_test = false
	parent.add_child(label)
	return label

static func axis(parent: Node3D, at: Vector3, direction: Vector3, color: Color, length: float) -> void:
	var rod := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.018
	mesh.bottom_radius = 0.018
	mesh.height = length
	mesh.radial_segments = 8
	rod.mesh = mesh
	rod.position = at
	rod.quaternion = Quaternion(Vector3.UP, direction.normalized())
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rod.material_override = material
	parent.add_child(rod)

static func cycle_angle(time: float) -> float:
	# Four seconds to inspect the start; three to turn; six to cross; three back.
	var phase := fposmod(time,16.0)
	if phase < 4.0: return 0.0
	if phase < 7.0: return (phase-4.0)*30.0
	if phase < 13.0: return 90.0
	return (16.0-phase)*30.0
