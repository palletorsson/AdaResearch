extends RefCounted
## A light, opaque architectural threshold. No extra lights, particles,
## screen textures or per-frame animation: the space beyond remains visible.

static func build(frame: Node3D, title: String, direction: int) -> void:
	# Local +Z is the approach side. The room's forward direction is +Z.
	frame.rotation.y = PI if direction > 0 else 0.0
	var accent := Color(0.38, 0.86, 0.75) if direction > 0 else Color(0.69, 0.57, 0.91)
	var shell := _material(Color(0.10,0.13,0.15),0.65,0.45)
	var enamel := _material(Color(0.65,0.64,0.57),0.25,0.42)
	var bevel := _material(Color(0.36,0.36,0.32),0.65,0.35)
	var recess := _material(Color(0.065,0.085,0.10),0.25,0.7)
	var light := _material(accent,0,0.6,true)
	var floor_mat := _material(Color(0.12,0.16,0.18),0.15,0.85)
	var lettering := Color(0.96,0.93,0.82)
	# The safe landing anchor is 5 cm above the measured floor; extend the
	# jambs down to that floor while keeping the inlay just above its surface.
	var outer: Array[Vector2] = [Vector2(-1.05,-0.05),Vector2(-1.05,2.50),Vector2(-0.83,2.72),Vector2(0.83,2.72),Vector2(1.05,2.50),Vector2(1.05,-0.05)]
	var face: Array[Vector2] = [Vector2(-1.02,-0.05),Vector2(-1.02,2.48),Vector2(-0.81,2.68),Vector2(0.81,2.68),Vector2(1.02,2.48),Vector2(1.02,-0.05)]
	var inset: Array[Vector2] = [Vector2(-0.90,-0.05),Vector2(-0.90,2.23),Vector2(-0.75,2.38),Vector2(0.75,2.38),Vector2(0.90,2.23),Vector2(0.90,-0.05)]
	var opening: Array[Vector2] = [Vector2(-0.86,-0.05),Vector2(-0.86,2.21),Vector2(-0.73,2.34),Vector2(0.73,2.34),Vector2(0.86,2.21),Vector2(0.86,-0.05)]
	var seam: Array[Vector2] = [Vector2(-0.878,-0.05),Vector2(-0.878,2.22),Vector2(-0.74,2.357),Vector2(0.74,2.357),Vector2(0.878,2.22),Vector2(0.878,-0.05)]
	# Extruded sides and a back face give the frame weight from oblique angles.
	var st := _surface()
	_band(st,outer,opening,-0.14,-0.14)
	_band(st,outer,outer,-0.14,0.10)
	_band(st,opening,opening,-0.14,0.045)
	_mesh(frame,st,shell,"FrameShell")
	st = _surface()
	_band(st,outer,face,0.10,0.17)
	_band(st,inset,opening,0.17,0.045)
	_mesh(frame,st,bevel,"ChamferedEdges")
	st = _surface()
	_band(st,face,inset,0.17,0.17)
	_mesh(frame,st,enamel,"EnamelFace")
	st = _surface()
	_band(st,seam,opening,0.10,0.10)
	_mesh(frame,st,light,"RecessedLight")
	# Collision stays on the jambs and lintel. Nothing spans the walking floor.
	var body := StaticBody3D.new()
	body.name = "FrameCollision"
	frame.add_child(body)
	for x: float in [-0.955,0.955]:
		_collider(body,Vector3(0.19,2.32,0.31),Vector3(x,1.11,0.015))
	_collider(body,Vector3(1.82,0.34,0.31),Vector3(0,2.55,0.015))
	for side: int in [-1,1]:
		var shoulder := _collider(body,Vector3(0.20,0.31,0.31),Vector3(side*0.89,2.35,0.015))
		shoulder.rotation.z = side*PI/4.0
	# The name belongs to the architecture rather than floating above it.
	_box(frame,Vector3(1.57,0.285,0.035),Vector3(0,2.535,0.19),recess,"DestinationPlaque")
	var destination := title.replace("_"," ").strip_edges()
	var pixel := minf(0.00225,1.44/maxf(1.0,destination.length()*32.0))
	_text(frame,destination,Vector3(0,2.50,0.213),64,pixel,lettering)
	_text(frame,"NEXT HALL" if direction > 0 else "PREVIOUS HALL",Vector3(0,2.625,0.213),40,0.0018,accent)
	# A flush dark threshold with a thin border and three small walking arrows.
	_box(frame,Vector3(1.72,0.012,1.15),Vector3(0,-0.04,0.33),floor_mat,"ThresholdInlay")
	st = _surface()
	for side: int in [-1,1]:
		_floor_quad(st,side*0.78-0.01,side*0.78+0.01,-0.18,0.85)
	_floor_quad(st,-0.78,0.78,0.83,0.85)
	for z: float in [0.22,0.43,0.64]:
		# Point towards the opening (local -Z), away from the approach side.
		_quad(st,Vector3(-0.16,-0.032,z+0.08),Vector3(0,-0.032,z-0.015),Vector3(0,-0.032,z+0.02),Vector3(-0.16,-0.032,z+0.115))
		_quad(st,Vector3(0,-0.032,z-0.015),Vector3(0.16,-0.032,z+0.08),Vector3(0.16,-0.032,z+0.115),Vector3(0,-0.032,z+0.02))
	_mesh(frame,st,light,"WalkingInlay")

static func _material(color: Color, metallic: float, roughness: float, luminous := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8 if luminous else 0.12
	if luminous:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

static func _surface() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st

static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v: Vector3 in [a,b,c,a,c,d]:
		st.add_vertex(v)

static func _band(st: SurfaceTool, a: Array[Vector2], b: Array[Vector2], za: float, zb: float) -> void:
	for i in range(a.size()-1):
		_quad(st,Vector3(a[i].x,a[i].y,za),Vector3(a[i+1].x,a[i+1].y,za),Vector3(b[i+1].x,b[i+1].y,zb),Vector3(b[i].x,b[i].y,zb))

static func _floor_quad(st: SurfaceTool, x0: float, x1: float, z0: float, z1: float) -> void:
	_quad(st,Vector3(x0,-0.032,z0),Vector3(x1,-0.032,z0),Vector3(x1,-0.032,z1),Vector3(x0,-0.032,z1))

static func _mesh(parent: Node3D, st: SurfaceTool, material: Material, mesh_name: String) -> MeshInstance3D:
	st.generate_normals()
	st.index()
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = st.commit()
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi

static func _box(parent: Node3D, size: Vector3, pos: Vector3, material: Material, mesh_name: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.position = pos
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)

static func _collider(body: StaticBody3D, size: Vector3, pos: Vector3) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = pos
	body.add_child(collision)
	return collision

static func _text(parent: Node3D, value: String, pos: Vector3, font_size: int, pixel: float, color: Color) -> void:
	var label := Label3D.new()
	label.text = value
	label.position = pos
	label.font_size = font_size
	label.pixel_size = pixel
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	parent.add_child(label)
