extends RefCounted
## Small shared presentation helpers. No global materials or locomotion changes.

static func material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = 0.8
	return m

static func box(parent: Node3D, title: String, at: Vector3, size_: Vector3, colour: Color, solid: bool = true) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	var mesh := BoxMesh.new()
	mesh.size = size_
	n.mesh = mesh
	n.material_override = material(colour)
	n.position = at
	parent.add_child(n)
	if solid: n.create_trimesh_collision()
	return n

static func label(parent: Node3D, words: String, at: Vector3, yaw: float = 0.0) -> Label3D:
	var n := Label3D.new()
	n.text = words
	n.font_size = 40
	n.pixel_size = 0.004
	n.outline_size = 5
	n.modulate = Color.WHITE
	n.position = at
	n.rotation_degrees.y = yaw
	parent.add_child(n)
	return n

static func panel(parent: Node3D, title: String, at: Vector3, yaw: float = 180.0) -> Node3D:
	box(parent, title.replace(" ", "") + "Stand", at - Vector3(0,0.64,0), Vector3(1.35,1.0,0.5),Color(0.18,0.18,0.18))
	var p: Node3D = load("res://commons/ui/control_panel.gd").new()
	p.title = title
	p.spacing = 0.28
	p.panel_color = Color(0.8,0.8,0.8)
	p.frame_color = Color(0.4,0.4,0.4)
	p.accent_color = Color.WHITE
	p.position = at
	p.rotation_degrees.y = yaw
	parent.add_child(p)
	return p

static func room_root(node: Node) -> Node:
	var p := node.get_parent()
	while p != null:
		if p.has_meta("em_map"): return p
		if str(p.name).begins_with("SimGrid_"): return p
		p = p.get_parent()
	return node.get_parent()

static func textured_plane(parent: Node3D, title: String, size_: Vector2, at: Vector3, turn: Vector3, texture: Texture2D) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = title
	var mesh := QuadMesh.new()
	mesh.size = size_
	n.mesh = mesh
	n.position = at
	n.rotation_degrees = turn
	var m := material(Color.WHITE)
	m.albedo_texture = texture
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	n.material_override = m
	parent.add_child(n)
	return n
