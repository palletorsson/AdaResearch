extends RefCounted
## Museum plaster and a pink curtain. The curtain is one inexpensive surface,
## not a second camera rendering a hall that has not loaded yet.

static func build(frame: Node3D, title: String, direction: int, wall_material: Material = null, floor_material: Material = null, exit_sign := false) -> void:
	# Local +Z is the approach side. Navigation may turn this frame towards
	# the clear approach to an authored t marker after it is built.
	frame.rotation.y = PI if direction > 0 else 0.0
	var accent := Color(1.0, 0.025, 0.34)
	var plaster := wall_material if wall_material != null else _material(Color(0.885,0.875,0.85),0,0.92)
	# A plain rectangular plaster reveal, continuous with the hall palette.
	# The safe anchor is 5 cm above the floor; the threshold stays flush.
	var body := StaticBody3D.new()
	body.name = "FrameCollision"
	frame.add_child(body)
	for x: float in [-0.955,0.955]:
		var size := Vector3(0.19,2.39,0.30)
		var centre := Vector3(x,1.145,0)
		_box(frame,size,centre,plaster,"PlasterJamb")
		_collider(body,size,centre)
	var lintel_size := Vector3(2.1,0.36,0.30)
	var lintel_centre := Vector3(0,2.52,0)
	_box(frame,lintel_size,lintel_centre,plaster,"PlasterLintel")
	_collider(body,lintel_size,lintel_centre)
	# One opaque, animated curtain hides the unloaded world. No collider,
	# second camera, lamps or particles are needed for the crossing.
	var st := _surface()
	_quad(st,Vector3(-0.86,-0.045,-0.10),Vector3(0.86,-0.045,-0.10),Vector3(0.86,2.34,-0.10),Vector3(-0.86,2.34,-0.10))
	var veil := ShaderMaterial.new()
	veil.shader = load("res://commons/scenes/em/em_portal_veil.gdshader")
	veil.set_shader_parameter("accent", Vector3(accent.r,accent.g,accent.b))
	_mesh(frame,st,veil,"PortalVeil")
	var destination := title.replace("_"," ").strip_edges()
	var pixel := minf(0.0019,1.65/maxf(1.0,destination.length()*32.0))
	if exit_sign:
		# Mount the existing illuminated sign on the actual exit lintel.
		# The destination stays below it, clear of both the sign and curtain.
		var sign: Node3D = load("res://commons/artifacts/exit_sign/exit_sign.tscn").instantiate()
		sign.name = "ExitSign"
		sign.position = Vector3(0,2.60,0.15)
		frame.add_child(sign)
		_text(frame,destination,Vector3(0,2.425,0.157),64,minf(pixel,0.0015),Color(0.13,0.12,0.14))
	else:
		_text(frame,destination,Vector3(0,2.48,0.157),64,pixel,Color(0.13,0.12,0.14))
		_text(frame,"NEXT HALL" if direction > 0 else "PREVIOUS HALL",Vector3(0,2.61,0.157),32,0.0017,Color(0.36,0.32,0.35))
	build_landing(frame, accent, floor_material)

static func build_landing(frame: Node3D, _accent: Color, floor_material: Material = null) -> void:
	# Anchor is 5 cm above the measured floor. A 28 cm solid slab reaches
	# under the doorway and 2.15 m into the room, flush with the existing deck.
	# Local +Z is always the hall side, including the return doorway.
	var size := Vector3(2.2,0.28,3.0)
	var centre := Vector3(0,-0.19,0.65)
	var body := StaticBody3D.new()
	body.name = "LandingCollision"
	frame.add_child(body)
	_collider(body,size,centre)
	var stone := floor_material if floor_material != null else _material(Color(0.30,0.29,0.28),0,0.88)
	_box(frame,size,centre,stone,"LandingSlab")
	# A thin cap avoids z fighting at the join with the existing gallery deck.
	_box(frame,Vector3(2.18,0.008,2.98),Vector3(0,-0.046,0.65),stone,"LandingSurface")

static func build_entry_room(frame: Node3D, title: String, wall_material: Material = null, floor_material: Material = null) -> void:
	# Enclose the supported landing outside the boundary spawn. The pink
	# return curtain stays behind; a roofed link opens into the first cell.
	var body := StaticBody3D.new()
	body.name = "EntryRoomCollision"
	frame.add_child(body)
	var plaster := wall_material if wall_material != null else _material(Color(0.885,0.875,0.85),0,0.92)
	var stone := floor_material if floor_material != null else _material(Color(0.30,0.29,0.28),0,0.88)
	var pieces: Array = [
		[Vector3(0.12,2.75,3.06),Vector3(-1.16,1.325,0.65),"EntryLeftWall"],
		[Vector3(0.12,2.75,3.06),Vector3(1.16,1.325,0.65),"EntryRightWall"],
		[Vector3(2.44,2.75,0.12),Vector3(0,1.325,-0.82),"EntryBackWall"],
		[Vector3(2.44,0.12,3.12),Vector3(0,2.76,0.65),"EntryCeiling"],
		# Full-height front wall around a 1.12 m clear doorway.
		[Vector3(0.60,2.75,0.12),Vector3(-0.86,1.325,2.12),"EntryFrontLeft"],
		[Vector3(0.60,2.75,0.12),Vector3(0.86,1.325,2.12),"EntryFrontRight"],
		[Vector3(1.12,0.40,0.12),Vector3(0,2.50,2.12),"EntryDoorLintel"],
		[Vector3(0.12,2.75,1.48),Vector3(-0.62,1.325,2.86),"EntryLinkLeft"],
		[Vector3(0.12,2.75,1.48),Vector3(0.62,1.325,2.86),"EntryLinkRight"],
		[Vector3(1.36,0.12,1.48),Vector3(0,2.76,2.86),"EntryLinkCeiling"],
	]
	for piece: Array in pieces:
		_collider(body,piece[0],piece[1])
		_box(frame,piece[0],piece[1],plaster,piece[2])
	var link_size := Vector3(1.12,0.28,1.55)
	var link_centre := Vector3(0,-0.19,2.775)
	_collider(body,link_size,link_centre)
	_box(frame,link_size,link_centre,stone,"EntryLink")
	# A diffuse ceiling fitting adds no dynamic light or shadow pass.
	_box(frame,Vector3(1.10,0.012,1.0),Vector3(0,2.694,0.70),
		_material(Color(0.96,0.88,0.83),0,0.9,true),"EntryCeilingPanel")
	var sign := Node3D.new()
	sign.name = "EntryHallLabel"
	frame.add_child(sign)
	sign.position = Vector3(0,2.49,2.052)
	sign.rotation.y = PI
	var destination := title.replace("_"," ").strip_edges()
	var pixel := minf(0.0015,1.0/maxf(1.0,destination.length()*22.0))
	_text(sign,destination,Vector3.ZERO,44,pixel,Color(0.16,0.14,0.16))

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
