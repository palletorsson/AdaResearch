extends RefCounted
## Plain museum furniture and geometry shared by the three Ignorance encounters.
const WHITE := Color(0.88,0.865,0.82)
const BLACK := Color(0.065,0.069,0.075)
const Plinth = preload("res://commons/artifacts/station/station_plinth.gd")

static func material(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color=colour; m.roughness=0.78
	return m

static func label(parent: Node3D, words: String, at: Vector3, size: float=0.002, yaw: float=0) -> Label3D:
	var n := Label3D.new();n.text=words;n.position=at;n.rotation.y=yaw
	n.font_size=40;n.pixel_size=size;n.outline_size=0;n.modulate=BLACK
	parent.add_child(n);return n

static func exhibit(parent: Node3D, mesh: Mesh, at: Vector3, colour: Color, title: String="", solid: bool=false) -> MeshInstance3D:
	var n := MeshInstance3D.new();n.mesh=mesh;n.position=at;n.material_override=material(colour)
	if not title.is_empty(): n.name=title
	parent.add_child(n)
	if solid:
		var body := StaticBody3D.new();body.collision_layer=1;body.collision_mask=0
		var c := CollisionShape3D.new();c.shape=mesh.create_convex_shape();body.add_child(c);n.add_child(body)
	return n

static func block(parent: Node3D, size: Vector3, at: Vector3, colour: Color=WHITE, solid: bool=true) -> MeshInstance3D:
	var mesh := BoxMesh.new();mesh.size=size;return exhibit(parent,mesh,at,colour,"",solid)

static func pedestal(parent: Node3D, at: Vector3, height: float, width: float) -> Node3D:
	var p := Plinth.new();p.top_height=height;p.cap_meters=width;p.position=at
	parent.add_child(p);return p

static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, segments: int, colour: Color=WHITE) -> MeshInstance3D:
	var mesh := CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius
	mesh.height=height;mesh.radial_segments=segments;mesh.rings=1
	var n := exhibit(parent,mesh,at,colour,"Resolution_%d"%segments,true)
	n.set_meta("radial_segments",segments);return n

static func lamp(parent: Node3D, at: Vector3, energy: float=1.0, reach: float=9.0) -> void:
	var n := OmniLight3D.new();n.position=at;n.light_color=Color(1,0.96,0.9)
	n.light_energy=energy;n.omni_range=reach;n.shadow_enabled=false;parent.add_child(n)

static func pickable_mesh(parent: Node3D, mesh: Mesh, at: Vector3, colour: Color, target: float=0.8) -> XRToolsPickable:
	var box := mesh.get_aabb();var factor := target/maxf(box.size.x,maxf(box.size.y,box.size.z))
	var body := XRToolsPickable.new();body.freeze=true;body.collision_layer=6;body.collision_mask=7
	body.release_mode=XRToolsPickable.ReleaseMode.UNFROZEN;body.mass=0.4;body.continuous_cd=true
	var mi := MeshInstance3D.new();mi.mesh=mesh;mi.scale=Vector3.ONE*factor
	mi.position=-box.get_center()*factor;mi.material_override=material(colour);body.add_child(mi)
	var c := CollisionShape3D.new();var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for surface in mesh.get_surface_count():
		for v: Vector3 in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:points.append((v-box.get_center())*factor)
	shape.points=points;c.shape=shape;body.add_child(c)
	parent.add_child(body);body.position=at+Vector3.UP*(box.size.y*factor*0.5)
	return body
