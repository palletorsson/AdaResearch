extends RefCounted
## Metre-scale parts shared by movable site props. Collision follows each solid.

static func finish(hex: String, roughness := .7, metallic := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(hex)
	material.roughness = roughness
	material.metallic = metallic
	return material

static func box(host: Node3D, title: String, at: Vector3, size: Vector3, material: Material, solid := true) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = mesh
	node.material_override = material
	node.position = at
	host.add_child(node)
	if solid:
		var shape := BoxShape3D.new()
		shape.size = size
		collision(node, shape)
	return node

static func tube(host: Node3D, title: String, start: Vector3, end: Vector3, radius: float, material: Material, solid := true) -> MeshInstance3D:
	var length := start.distance_to(end)
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 12
	mesh.rings = 1
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = mesh
	node.material_override = material
	node.position = (start + end) / 2.0
	node.quaternion = Quaternion(Vector3.UP, (end-start).normalized())
	host.add_child(node)
	if solid:
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = length
		collision(node, shape)
	return node

static func collision(host: Node3D, shape: Shape3D) -> void:
	var body := StaticBody3D.new()
	body.name = "Solid"
	host.add_child(body)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)

static func bolt(host: Node3D, at: Vector3, material: Material) -> void:
	tube(host, "Bolt", at, at+Vector3(0,0,.012), .012, material, false)

static func batch_static(host: Node3D) -> void:
	# Bake by shared material: bolts and rails need not cost one draw apiece in VR.
	# Keep original transforms for their colliders; animated cloth remains separate.
	var batches := {}
	for node in host.find_children("*", "MeshInstance3D", true, false):
		if node.mesh == null or node.material_override is ShaderMaterial: continue
		var material: Material = node.material_override
		if not batches.has(material):
			var builder := SurfaceTool.new()
			builder.begin(Mesh.PRIMITIVE_TRIANGLES)
			batches[material] = builder
		var transform: Transform3D = host.global_transform.affine_inverse() * node.global_transform
		batches[material].append_from(node.mesh, 0, transform)
		node.mesh = null
	for material in batches:
		var instance := MeshInstance3D.new()
		instance.name = "BatchedSurface"
		instance.mesh = batches[material].commit()
		instance.material_override = material
		host.add_child(instance)
