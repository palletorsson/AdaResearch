extends Node3D
## Supplies the room-grid dependency of the original non-spatial colourizer.
## The lesson, controls, palettes and write/overwrite logic remain in its scene.
const Source = preload("res://algorithms/color/gridcolorizer/gridcolorizer.tscn")
const DiscoScript = preload("res://commons/artifacts/disco_extravaganza/disco_extravaganza.gd")
var source: Node
var frame: Node3D
var grid: GridStructureComponent
var _game: Node
var _walk_address := Vector2i(-1, -1)
var _walk_direction := -1
var _last_feet := Vector3.ZERO
var _full_floor := false
var _direction_palettes := false
var _disco_stage := false
var _disco: Node3D

func _ready() -> void:
	frame = Node3D.new()
	frame.name = "RoomGrid"
	# Original controller token is at cell (6,5); its lesson uses room coordinates.
	var central_bay := bool(get_meta("config_central_bay", false))
	_full_floor = bool(get_meta("config_full_floor", false))
	_direction_palettes = bool(get_meta("config_direction_palettes", _full_floor))
	_disco_stage = bool(get_meta("config_disco_stage", false))
	var stage_h := 0.45 if _disco_stage else 0.0
	frame.position = Vector3(-10, stage_h, -10) if central_bay else Vector3(-6, stage_h, -5)
	if _full_floor:
		# Align the metre cells to both the slab edges and shaft edges.
		frame.position.x -= 0.5
	add_child(frame)
	grid = GridStructureComponent.new()
	grid.name = "GridStructureComponent"
	grid.parent_node = frame
	frame.add_child(grid)
	var transforms: Array[Transform3D] = []
	var game := get_tree().get_first_node_in_group("void_game")
	_game = game
	var spec: Dictionary = game.building.spec if game != null else preload("room_source.gd").read_layout()
	var xs := range(1, 18)
	var zs := range(1, 20)
	if _full_floor:
		var corner := frame.to_local(Vector3(-float(spec.width) / 2, frame.global_position.y, -float(spec.depth) / 2))
		xs = range(ceili(corner.x), ceili(corner.x + float(spec.width)))
		zs = range(ceili(corner.z), ceili(corner.z + float(spec.depth)))
	for z in zs:
		for x in xs:
			if not _full_floor:
				if central_bay and (x < 6 or x > 14 or z < 5 or z > 15): continue
				if not central_bay and Vector2i(x,z) in [Vector2i(11,7),Vector2i(13,15)]: continue
			var centre := Vector3(x,-0.49,z)
			if not _over_slab(frame.to_global(centre),spec): continue
			grid.cube_positions.append(Vector3i(x,0,z))
			transforms.append(Transform3D(Basis.IDENTITY,centre))
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	var cube := BoxMesh.new()
	# Keep original cell centres for the lesson's +0.515 marker calculation;
	# render only the colour skin above the existing structural slab.
	cube.size = Vector3(0.98,0.02,0.98)
	var arrays: Array = cube.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in vertices.size(): vertices[i].y += 0.49
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var surface := ArrayMesh.new()
	surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	batch.mesh = surface
	batch.instance_count = transforms.size()
	for i in transforms.size():
		batch.set_instance_transform(i,transforms[i])
		batch.set_instance_color(i,Color.WHITE)
	var mesh := MultiMeshInstance3D.new()
	mesh.name = "GridMultiMesh"
	mesh.multimesh = batch
	var finish := StandardMaterial3D.new()
	finish.vertex_color_use_as_albedo = true
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material_override = finish
	frame.add_child(mesh)
	grid.multimesh = batch
	grid.multimesh_instance = mesh
	source = Source.instantiate()
	source.name = "OriginalColorizer"
	for key in get_meta_list():
		if str(key).begins_with("config_"): source.set_meta(key,get_meta(key))
	# Bind locally before the source's asynchronous room-floor discovery.
	source.multimesh_path = NodePath("../GridMultiMesh")
	frame.add_child(source)
	# A Node3D below the scene's plain Node root does not inherit spatial parents.
	# Keep source references/signals but attach the lesson to the spatial frame.
	if is_instance_valid(source.address_lesson):
		source.address_lesson.reparent(frame,false)
		if central_bay:
			for part in source.address_lesson.get_children():
				if part is Node3D and part != source.address_lesson.marker:
					part.position.z += 1.5
					if _disco_stage:
						part.position.y -= stage_h
		if source.address_lesson.ready_for_input: source.address_lesson._refresh()
	if _disco_stage:
		_disco = DiscoScript.new()
		add_child(_disco)
		_disco.setup(self, frame, batch)
	if get_meta("config_walk_addresses", false):
		if _direction_palettes:
			_mark_directions()
		else:
			_mark_address_square()
	else:
		set_physics_process(false)

func _physics_process(_delta: float) -> void:
	var lesson: Node = source.address_lesson
	if not is_instance_valid(_game) or not is_instance_valid(_game.body) or not is_instance_valid(lesson) or not lesson.ready_for_input:
		return
	var feet := frame.to_local(_game.body.global_position)
	var motion := feet - _last_feet
	_last_feet = feet
	var address := Vector2i(roundi(feet.x), roundi(feet.z))
	var inside: bool = lesson.cells.has(address) if _direction_palettes else Rect2i(8, 8, 5, 5).has_point(address)
	var y_tol := 0.28 if _disco_stage else 0.15
	if not inside or absf(feet.y) > y_tol or not _game.body.is_on_floor():
		_walk_address = Vector2i(-1, -1)
		return
	if address == _walk_address: return
	var previous := _walk_address
	_walk_address = address
	lesson.select_address(address)
	if _direction_palettes and lesson.cells.has(previous) and (address - previous).length_squared() <= 2:
		_update_direction_palette(lesson, motion)

func _update_direction_palette(lesson: Node, motion: Vector3) -> void:
	var x := absf(motion.x)
	var z := absf(motion.z)
	# A diagonal near 45 degrees keeps its current palette across tile edges.
	if maxf(x, z) < 0.001 or (_walk_direction >= 0 and absf(x - z) < maxf(x, z) * 0.15):
		return
	var direction := 0 if motion.x > 0 else 1
	if z > x:
		direction = 2 if motion.z > 0 else 3
	if direction == _walk_direction: return
	_walk_direction = direction
	lesson.use_palette(direction)

func _mark_directions() -> void:
	var cap_y := 0.044 if _disco_stage else 0.036
	var north_z := 6.0 if _disco_stage else 5.0
	_address_caption("+X / STONEWALL", Vector3(14, cap_y, 10), 34)
	_address_caption("-X / STARRY NIGHT", Vector3(6, cap_y, 10), 34)
	_address_caption("+Z / MONDRIAN", Vector3(10, cap_y, 15), 34)
	_address_caption("-Z / DESERT SUNSET", Vector3(10, cap_y, north_z), 34)

func _mark_address_square() -> void:
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("171c29")
	finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for side in [7.5, 12.5]:
		_address_line(Vector3(side, 0.019, 10), Vector3(0.045, 0.01, 5), finish)
		_address_line(Vector3(10, 0.019, side), Vector3(5, 0.01, 0.045), finish)
	for index in range(8, 13):
		_address_caption("X %d" % index, Vector3(index, 0.036, 12.8), 28)
		_address_caption("Z %d" % index, Vector3(7.15, 0.036, index), 28)
	_address_caption("STEP ON A TILE TO SELECT ITS ADDRESS", Vector3(10, 0.036, 13.55), 37)

func _address_line(at: Vector3, size: Vector3, finish: Material) -> void:
	var line := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	line.mesh = mesh
	line.position = at
	line.material_override = finish
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	frame.add_child(line)

func _address_caption(caption: String, at: Vector3, font_size: int) -> void:
	var label := Label3D.new()
	label.text = caption
	label.font_size = font_size
	label.pixel_size = 0.004
	label.rotation.x = -PI * 0.5
	label.position = at
	frame.add_child(label)

func _over_slab(at: Vector3, spec: Dictionary) -> bool:
	if absf(at.x)+0.5>float(spec.width)/2 or absf(at.z)+0.5>float(spec.depth)/2: return false
	for shaft in spec.shafts:
		if absf(at.x-float(shaft.x))<float(spec.shaft_width)/2+0.5 and absf(at.z)<float(spec.shaft_depth)/2+0.5: return false
	return true
