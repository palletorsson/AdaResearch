extends Node3D
## Supplies the room-grid dependency of the original non-spatial colourizer.
## The lesson, controls, palettes and write/overwrite logic remain in its scene.
const Source = preload("res://algorithms/color/gridcolorizer/gridcolorizer.tscn")
var source: Node
var frame: Node3D
var grid: GridStructureComponent

func _ready() -> void:
	frame = Node3D.new()
	frame.name = "RoomGrid"
	# Original controller token is at cell (6,5); its lesson uses room coordinates.
	frame.position = Vector3(-6,0,-5)
	add_child(frame)
	grid = GridStructureComponent.new()
	grid.name = "GridStructureComponent"
	grid.parent_node = frame
	frame.add_child(grid)
	var transforms: Array[Transform3D] = []
	var game := get_tree().get_first_node_in_group("void_game")
	for z in range(1,20):
		for x in range(1,18):
			if Vector2i(x,z) in [Vector2i(11,7),Vector2i(13,15)]: continue
			var centre := Vector3(x,-0.49,z)
			if not _over_slab(frame.to_global(centre),game): continue
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
		if source.address_lesson.ready_for_input: source.address_lesson._refresh()

func _over_slab(at: Vector3, game: Node) -> bool:
	# In exports there may be no player/game. Standard dimensions are the fallback.
	var spec: Dictionary = game.building.spec if game != null else {"width":42,"depth":32,"shaft_width":5,"shaft_depth":6,"shafts":[{"x":-10},{"x":10}]}
	if absf(at.x)+0.5>float(spec.width)/2 or absf(at.z)+0.5>float(spec.depth)/2: return false
	for shaft in spec.shafts:
		if absf(at.x-float(shaft.x))<float(spec.shaft_width)/2+0.5 and absf(at.z)<float(spec.shaft_depth)/2+0.5: return false
	return true
