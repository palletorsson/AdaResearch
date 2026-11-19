extends "res://commons/void/columns_pipe_slide.gd"
## A route is an installation spanning two actual floors, not a teleport effect.
## Forces retain gravity and jumps; only the wave chutes opt into guided sliding.
var settings: Dictionary = {}
var kind := "jump_terraces"
var vertical_drop := 6.0
var destination_floor := -1
var batches: Dictionary = {}
var materials: Dictionary = {}
var hole_z := -1.5
var entrance := Vector3.ZERO
var exit := Vector3.ZERO
var stair_path := PackedVector3Array()

func apply_grid_config(config: Dictionary) -> void:
	settings = config.duplicate(true)
	if is_node_ready():
		for child in get_children(): child.free()
		_build()

func _ready() -> void:
	add_to_group("void_exterior_walk")
	_build()
	get_tree().node_added.connect(_node_added)

func _node_added(node: Node) -> void:
	if kind.begins_with("wave_"): super._node_added(node)

func _build() -> void:
	batches.clear(); materials.clear(); deck_path.clear(); lengths.clear(); stair_path.clear(); riders.clear()
	kind = str(settings.get("kind", "jump_terraces"))
	vertical_drop = clampf(float(settings.get("drop", 6.0)), 3.0, 12.0)
	destination_floor = int(settings.get("destination_floor", -1))
	if kind == "boolean_drop":
		_build_drop()
	else:
		entrance = Vector3(0, 0, -5.5)
		exit = Vector3(0, -vertical_drop, 5.5)
		_bridge(-5.5, 0.0, false)
		_bridge(5.5, -vertical_drop, true)
		if kind == "jump_terraces": _build_jumps()
		elif kind == "maximal_stairs": _build_spiral()
		else: _build_wave()
		if kind != "maximal_stairs": _build_side_stairs()
		_label(str(settings.get("label", "DESCEND")), Vector3(-6.7, 1.6, -5.5), 90)
		_label(str(settings.get("destination", "NEXT FLOOR")), Vector3(-6.7, -vertical_drop+1.6, 5.5), 90)
	_flush_batches()
	if not deck_path.is_empty():
		lengths.append(0.0)
		for i in range(1, deck_path.size()): lengths.append(lengths[-1]+deck_path[i].distance_to(deck_path[i-1]))
	for group in ["ada_museum_carry", "ada_pipe_slide"]:
		if kind.begins_with("wave_"): add_to_group(group)
		elif is_in_group(group): remove_from_group(group)
	if kind.begins_with("wave_"): _install_adapter.call_deferred()

func _material(key: String) -> StandardMaterial3D:
	if materials.has(key): return materials[key]
	var m := StandardMaterial3D.new()
	var palette := {"blue":"2888df", "cream":"fff0c1", "coral":"f36b54", "steel":"405364", "gold":"f9bc37"}
	m.albedo_color = Color(palette.get(key,key))
	m.roughness = .44
	m.metallic = .25 if key == "steel" else .06
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	materials[key] = m
	return m

func _box(title: String, at: Vector3, size: Vector3, colour: String, solid := true, yaw := 0.0, landing := false) -> void:
	var pose := Transform3D(Basis(Vector3.UP,yaw),at)
	if not batches.has(colour): batches[colour] = []
	batches[colour].append(pose.scaled_local(size))
	if not solid: return
	var body := StaticBody3D.new()
	body.name = title
	body.transform = pose
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new(); shape.size = size
	collision.shape = shape; body.add_child(collision); add_child(body)
	if landing and destination_floor >= 0:
		body.set_meta("void_floor_index", destination_floor)
		body.set_meta("floor_index", destination_floor)
		body.set_meta("void_landing_pad", true)

func _flush_batches() -> void:
	for colour in batches:
		var visual := MultiMeshInstance3D.new()
		visual.name = "Parts_"+colour
		var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = BoxMesh.new(); mm.instance_count = batches[colour].size()
		for i in mm.instance_count: mm.set_instance_transform(i,batches[colour][i])
		visual.multimesh = mm; visual.material_override = _material(colour); add_child(visual)

func _label(words: String, at: Vector3, yaw := 0.0) -> void:
	var label := Label3D.new(); label.text = words
	label.position = at; label.rotation_degrees.y = yaw
	label.font_size = 42; label.pixel_size = .005; label.modulate = Color("fff0c1")
	add_child(label)

func _bridge(z: float, y: float, landing: bool) -> void:
	# The inner end overlaps the tower edge at x=21 by two metres.
	_box("Arrival" if landing else "Departure", Vector3(-3.5,y-.12,z),Vector3(9,.24,1.8),"cream",true,0,landing)
	for side in [-1.0,1.0]:
		_box("BridgeRail",Vector3(-4.9,y+.85,z+side*.88),Vector3(6.2,.10,.10),"steel")
		for x in [-7.8,-5.0,-2.2]:
			_box("BridgePost",Vector3(x,y+.45,z+side*.88),Vector3(.10,.9,.10),"blue")
	# A broad end apron connects the chute and its separate stair lane.
	_box("Apron",Vector3(.8,y-.12,z),Vector3(4.5,.24,1.8),"cream",true,0,landing)

func _surface(title: String, points: PackedVector3Array, width: float, colour: String) -> void:
	var tool := SurfaceTool.new(); tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size()-1:
		var side := Vector3.UP.cross(points[i+1]-points[i]).normalized()*width*.5
		for p in [points[i]-side,points[i]+side,points[i+1]-side,points[i]+side,points[i+1]+side,points[i+1]-side]: tool.add_vertex(p)
	tool.generate_normals()
	var mesh := tool.commit()
	var visual := MeshInstance3D.new(); visual.name=title; visual.mesh=mesh
	visual.material_override=_material(colour); add_child(visual)
	var body := StaticBody3D.new(); var collision := CollisionShape3D.new()
	var shape := mesh.create_trimesh_shape(); shape.backface_collision=true
	collision.shape=shape; body.add_child(collision); visual.add_child(body)

func _rail(points: PackedVector3Array, colour: String, radius := .055) -> void:
	var mesh: ArrayMesh = Tube.build(points,radius,8).mesh
	var visual := MeshInstance3D.new(); visual.mesh=mesh; visual.material_override=_material(colour); add_child(visual)
	var body := StaticBody3D.new(); var collider := CollisionShape3D.new()
	collider.shape=mesh.create_trimesh_shape(); body.add_child(collider); visual.add_child(body)

func _build_jumps() -> void:
	# Four broad inclined plates with a real 45 cm step-off after each plate.
	# The last ramp reaches the landing; there is no forced camera or body motion.
	for i in 4:
		var z0 := -4.6+i*2.3
		var y0 := -vertical_drop*i/4.0
		var y1 := -vertical_drop*(i+1)/4.0 + (.45 if i<3 else 0.0)
		_surface("JumpPlate%d"%i,PackedVector3Array([Vector3(0,y0,z0),Vector3(0,y1,z0+2.3)]),2.8,"blue" if i%2==0 else "coral")
		_box("PlateLip",Vector3(0,y1+.018,z0+2.24),Vector3(2.8,.035,.12),"gold",false)
		for side in [-1.0,1.0]:
			_surface("PlateSide",PackedVector3Array([Vector3(side*1.42,y0+.4,z0),Vector3(side*1.42,y1+.4,z0+2.3)]),.12,"steel")
		deck_path.append(Vector3(0,y0,z0)); deck_path.append(Vector3(0,y1,z0+2.3))
	# Actual gravity drops between plates; an adjacent stair remains climbable.
	_box("StartPlate",Vector3(0,-.09,-5.05),Vector3(2.8,.18,.9),"blue")
	_box("EndPlate",Vector3(0,-vertical_drop-.09,5.05),Vector3(2.8,.18,.9),"blue",true,0,true)

func _build_side_stairs() -> void:
	var count := ceili(vertical_drop/.16)
	for i in count:
		var y := -vertical_drop*float(i+1)/count
		var z := -4.6+(i+.5)*9.2/count
		_box("StairTread",Vector3(2.25,y-.09,z),Vector3(1.35,.18,9.2/count+.015),"cream" if i%2==0 else "gold")
		stair_path.append(Vector3(2.25,y,z))
	var rail := PackedVector3Array([Vector3(2.93,.95,-4.6),Vector3(2.93,-vertical_drop+.95,4.6)])
	_rail(rail,"steel")
	for i in 10:
		var t := i/9.0
		_box("StairBaluster",Vector3(2.93,-vertical_drop*t+.44,lerpf(-4.6,4.6,t)),Vector3(.08,.9,.08),"blue")

func _build_wave() -> void:
	deck_path.append(entrance)
	for i in 97:
		var t := i/96.0
		var x := 0.0
		var y := -vertical_drop*t
		if kind == "wave_s": x=.65*sin(TAU*t)
		elif kind == "wave_eased": y=-vertical_drop*(t-sin(TAU*t)/TAU)
		elif kind == "wave_ripple": y=-vertical_drop*t+.14*sin(TAU*3*t)
		deck_path.append(Vector3(x,y,lerpf(-4.6,4.6,t)))
	deck_path.append(exit)
	_surface("SlideBed",deck_path,1.44,"coral")
	# Keep both turning aprons open: the shell and cheek rails start after them.
	var chute := deck_path.slice(1,deck_path.size()-1)
	if kind == "wave_tube":
		var axis := PackedVector3Array()
		for p in chute: axis.append(p+Vector3.UP)
		_add_surface("TubeShell",Tube.build(axis,1.39,16,.06).mesh,Color("2888df"),.2,true)
	else:
		for side in [-1.0,1.0]:
			var wall := PackedVector3Array(); var rail := PackedVector3Array()
			for p in chute:
				wall.append(p+Vector3(side*.8,.24,0)); rail.append(p+Vector3(side*.8,.55,0))
			_surface("ChuteSide",wall,.15,"blue")
			_rail(rail,"gold",.075)

func _build_spiral() -> void:
	var count := ceili(vertical_drop/.125)
	var rail := PackedVector3Array()
	for i in count:
		var t := float(i)/count
		var angle := -PI*.5+3*PI*t
		var y := -vertical_drop*float(i+1)/count
		var centre := Vector3(cos(angle)*2.1,y,sin(angle)*2.1)
		var width := 1.5+.35*sin(6*PI*t)
		_box("FanTread",centre-Vector3.UP*.07,Vector3(width,.14,.49),"coral" if i%3==0 else "cream",true,-angle)
		stair_path.append(centre)
		var outer := Vector3(cos(angle)*3.05,y+.95,sin(angle)*3.05)
		rail.append(outer)
		_box("FanBaluster",outer-Vector3.UP*.47,Vector3(.075,.95,.075),"gold")
	_rail(rail,"blue",.09)
	# Meet the radial edge of the first tread, not its centre. Extending this
	# flat deck over the first two treads traps the wider XR body's ground probe.
	_box("StairEntry",Vector3(0,-.06,-4.175),Vector3(1.6,.12,2.65),"cream")
	_box("StairExit",Vector3(0,-vertical_drop-.06,4.05),Vector3(1.6,.12,2.9),"cream",true,0,true)
	# Opposing inner and outer rails make the helix a visible, generous volume.
	var inner := PackedVector3Array()
	for p in stair_path: inner.append(Vector3(p.x*.51,p.y+.85,p.z*.51))
	_rail(inner,"gold")

func _build_drop() -> void:
	hole_z = float(settings.get("hole_z",-1.5))
	entrance=Vector3(0,0,hole_z); exit=Vector3(0,-vertical_drop,hole_z)
	# Fit a deck within the existing six-metre shaft, subtracting a two-metre square.
	_box("LeftRemainder",Vector3(-2,-.10,0),Vector3(2,.2,6),"cream")
	_box("RightRemainder",Vector3(2,-.10,0),Vector3(2,.2,6),"cream")
	for interval in [Vector2(-3,hole_z-1),Vector2(hole_z+1,3)]:
		if interval.y>interval.x: _box("EndRemainder",Vector3(0,-.10,(interval.x+interval.y)/2),Vector3(2,.2,interval.y-interval.x),"cream")
	for x in [-1.05,1.05]:
		_box("HoleLip",Vector3(x,.025,hole_z),Vector3(.10,.05,2.2),"coral",false)
		_box("DropSide",Vector3(x,-vertical_drop*.5,hole_z),Vector3(.10,vertical_drop-1.6,2.1),"blue")
	for z in [hole_z-1.05,hole_z+1.05]: _box("HoleLip",Vector3(0,.025,z),Vector3(2.2,.05,.1),"coral",false)
	_box("CatchPad",Vector3(0,-vertical_drop+.025-.1,hole_z),Vector3(2,.2,3),"gold",true,0,true)
	_label("SUBTRACT\nSTEP INTO THE OPENING",Vector3(1.8,1.4,hole_z),-90)
	_label(str(settings.get("destination","NEXT FLOOR")),Vector3(1.8,-vertical_drop+1.4,hole_z),-90)

func _point_inside(world_point: Vector3) -> bool:
	return kind.begins_with("wave_") and super._point_inside(world_point)
