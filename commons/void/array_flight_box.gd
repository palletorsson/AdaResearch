extends "res://commons/movement/museum_flight_box.gd"
## The noise exhibit's bounded flight, applied to a collectible indexed volume.
## The envelope is permeable: leaving any face restores the player's gravity.
const Cube := preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
var config: Dictionary = {}
var values: Array = []
var cells: Dictionary = {}
var cubes: Dictionary = {}
var labels: Dictionary = {}
var collected := 0
var size_x := 6
var size_y := 6
var size_z := 6
var spacing := 0.8
var cube_size := 0.34
var count_label: Label3D

func _ready() -> void:
	size_x = clampi(int(config.get("size_x",6)),2,6)
	size_y = clampi(int(config.get("size_y",6)),2,6)
	size_z = clampi(int(config.get("size_z",6)),2,6)
	spacing = float(config.get("spacing",0.8))
	cube_size = float(config.get("cube_size",0.34))
	edge_length = float(config.get("box_size",5.0))
	var offset: Array = config.get("shaft_offset",[0,-4.7,-4.4])
	position = Vector3(offset[0],offset[1],offset[2])
	super._ready()
	add_to_group("void_floor_extension")
	_build_array()

func contains_visitor(at: Vector3) -> bool:
	# Keep this lesson active while its visitor flies below the authored floor.
	return contains_point(at)

func cell_position(cell: Vector3i) -> Vector3:
	return Vector3((cell.x-(size_x-1)*0.5)*spacing,
		edge_length-0.5-cell.y*spacing,(cell.z-(size_z-1)*0.5)*spacing)

func _build_array() -> void:
	for x in size_x:
		var layers: Array = []
		for y in size_y:
			var row: Array = []
			for z in size_z:
				var cell := Vector3i(x,y,z)
				row.append(1)
				var slot := Node3D.new()
				slot.name = "Address_%d_%d_%d"%[x,y,z]
				slot.position = cell_position(cell)
				slot.set_meta("array_index",cell)
				add_child(slot)
				cells[cell] = slot
				var cube: Node3D = Cube.instantiate()
				cube.name = "Cube"
				cube.hold = "collect"
				cube.motion = "still"
				# Align the original pickup's detector with its visible body.
				var mesh: MeshInstance3D = cube.get_node("CubeBaseMesh")
				mesh.position = Vector3.ZERO
				mesh.scale = Vector3.ONE*cube_size
				var area: Area3D = cube.get_node("DetectionArea")
				area.position = Vector3.ZERO
				var shape: CollisionShape3D = area.get_node("CollisionShape3D")
				shape.position = Vector3.ZERO
				shape.shape = BoxShape3D.new()
				shape.shape.size = Vector3.ONE*cube_size
				slot.add_child(cube)
				cubes[cell] = cube
				cube.tree_exiting.connect(_cube_leaves.bind(cell,cube))
				var address := Label3D.new()
				address.text = "[%d,%d,%d]"%[x,y,z]
				address.font_size = 24
				address.pixel_size = 0.0014
				address.position.y = cube_size*0.5+0.06
				address.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				address.no_depth_test = false
				slot.add_child(address)
				labels[cell] = address
			layers.append(row)
		values.append(layers)
	_update_count()

func _cube_leaves(cell: Vector3i, cube: Node3D) -> void:
	if not is_inside_tree() or not cube.has_been_collected or values[cell.x][cell.y][cell.z]==0:
		return
	values[cell.x][cell.y][cell.z] = 0
	cubes.erase(cell)
	collected += 1
	labels[cell].text = "[%d,%d,%d] = 0"%[cell.x,cell.y,cell.z]
	labels[cell].modulate = Color("8198a4")
	_update_count()

func _update_count() -> void:
	count_label.text = "%d × %d × %d / FLY THROUGH THE ARRAY\n%d / %d CUBES COLLECTED\nInside: flight. Outside: gravity.\nWASD + look / Space up / Ctrl down\nVR: aim left hand + left stick"%[size_x,size_y,size_z,collected,size_x*size_y*size_z]

func _build_enclosure() -> void:
	var h := edge_length*0.5
	var glass := _material(Color(0.3,0.7,0.85,0.035))
	var edge := _material(Color(0.3,0.85,1.0),true)
	# The frame marks a locomotion boundary, not an invisible collision wall.
	for side in [-1,1]:
		_box("GlassX",Vector3(side*h,h,0),Vector3(.006,edge_length,edge_length),glass,false)
		_box("GlassZ",Vector3(0,h,side*h),Vector3(edge_length,edge_length,.006),glass,false)
		for y in [0.0,edge_length]:
			_box("EdgeX",Vector3(0,y,side*h),Vector3(edge_length,.025,.025),edge,false)
			_box("EdgeZ",Vector3(side*h,y,0),Vector3(.025,.025,edge_length),edge,false)
		for end in [-1,1]:
			_box("Upright",Vector3(side*h,h,end*h),Vector3(.025,edge_length,.025),edge,false)
	for y in [0.0,edge_length]:
		_box("GlassY",Vector3(0,y,0),Vector3(edge_length,.006,edge_length),glass,false)
	count_label = Label3D.new()
	count_label.name = "FlightInstructions"
	count_label.position = Vector3(-h-0.4,edge_length+0.01,0)
	count_label.rotation_degrees = Vector3(-90,-90,0)
	count_label.font_size = 28
	count_label.pixel_size = .0017
	add_child(count_label)
