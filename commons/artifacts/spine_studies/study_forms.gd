extends Node3D
## Small fabrication helpers. Meaning and state remain in each study.
func material(colour: Color, unlit := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 0.78
	if unlit: m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func block(at: Vector3, size: Vector3, colour: Color, solid := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new(); shape.size = size; mesh.mesh = shape
	mesh.material_override = material(colour); mesh.position = at; add_child(mesh)
	if solid:
		var body := StaticBody3D.new(); var collision := CollisionShape3D.new()
		var box := BoxShape3D.new(); box.size = size; collision.shape = box
		body.add_child(collision); mesh.add_child(body)
	return mesh

func inscription(words: String, at: Vector3, size := 0.004, colour := Color("25222a")) -> Label3D:
	var label := Label3D.new(); label.text = words; label.position = at
	label.font_size = 48; label.pixel_size = size; label.outline_size = 0
	label.modulate = colour; label.no_depth_test = false; add_child(label)
	return label

func stroke(points: PackedVector3Array, colour: Color, radius := 0.014) -> MultiMeshInstance3D:
	var m := MultiMesh.new(); m.transform_format = MultiMesh.TRANSFORM_3D
	var rod := CylinderMesh.new(); rod.top_radius = radius; rod.bottom_radius = radius
	rod.height = 1.0; rod.radial_segments = 6; rod.rings = 1; m.mesh = rod
	m.instance_count = maxi(0,points.size()-1)
	for i in m.instance_count:
		var a := points[i]; var b := points[i+1]; var direction := b-a
		var up := direction.normalized()
		var right := up.cross(Vector3.FORWARD).normalized()
		if right.length_squared() < 0.01: right = up.cross(Vector3.RIGHT).normalized()
		m.set_instance_transform(i,Transform3D(Basis(right,up*direction.length(),right.cross(up)),(a+b)*0.5))
	var result := MultiMeshInstance3D.new(); result.multimesh = m
	result.material_override = material(colour,true); add_child(result); return result
