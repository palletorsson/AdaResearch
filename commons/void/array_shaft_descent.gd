extends Node3D
## Optional architectural arrangement of grid_3d_4x4x4.
## Array[x][layer][z] uses increasing layer indices downwards. These cubes
## retain their addresses and become solid support; empty addresses stay empty.
const Cube := preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
var config: Dictionary = {}
var values: Array = []
var cells: Dictionary = {}
var solids: Dictionary = {}
var size_x := 3
var size_y := 3
var size_z := 3
var spacing := 2.0
var layer_drop := 2.7
var cube_size := 0.7
var centre := Vector3(0,0,-4.4)
var route: Array[Vector3i] = [Vector3i(0,0,0),Vector3i(1,1,0),Vector3i(2,2,0)]

func _ready() -> void:
	size_x = clampi(int(config.get("size_x",3)),2,6)
	size_y = clampi(int(config.get("size_y",3)),2,6)
	size_z = clampi(int(config.get("size_z",3)),2,6)
	spacing = maxf(float(config.get("spacing",2.0)),0.8)
	layer_drop = maxf(float(config.get("layer_drop",2.7)),2.4)
	cube_size = clampf(float(config.get("cube_size",0.7)),0.5,spacing-0.1)
	var offset: Array = config.get("shaft_offset",[0,0,-4.4])
	centre = Vector3(offset[0],offset[1],offset[2])
	if config.has("route_cells"):
		route.clear()
		for address in config.route_cells:
			if address is Array and address.size()==3:
				var cell := Vector3i(int(address[0]),int(address[1]),int(address[2]))
				if cell.x>=0 and cell.x<size_x and cell.y>=0 and cell.y<size_y and cell.z>=0 and cell.z<size_z:
					route.append(cell)
	var holes: Array = config.get("empty_cells",[[1,0,0],[2,0,0],[2,1,0]])
	var empty: Dictionary = {}
	# JSON numbers arrive as floats; convert addresses before dictionary lookup.
	for address in holes:
		if address is Array and address.size()==3:
			empty[Vector3i(int(address[0]),int(address[1]),int(address[2]))] = true
	var dark := material(Color("242f36"))
	var pink := material(Color("eea9c9"),0.22)
	var ghost := material(Color("637e87"),0.08)
	for x in size_x:
		var layers: Array = []
		for y in size_y:
			var row: Array = []
			for z in size_z:
				var cell := Vector3i(x,y,z)
				var present := not empty.has(cell)
				row.append(1 if present else 0)
				var at := cell_top(cell)
				var slot := Node3D.new()
				slot.name = "Address_%d_%d_%d" % [x,y,z]
				slot.position = at
				slot.set_meta("array_index",cell)
				add_child(slot)
				cells[cell] = slot
				if present:
					# Use the existing cube's stationary demonstration mode.
					# Its visual geometry and solid support share the same bounds.
					var cube: Node3D = Cube.instantiate()
					cube.name = "Cube"
					cube.hold = "demo"
					cube.motion = "still"
					slot.add_child(cube)
					var mesh: MeshInstance3D = cube.get_node("CubeBaseMesh")
					mesh.position = Vector3(0,-cube_size/2.0,0)
					mesh.scale = Vector3.ONE*cube_size
					var body := StaticBody3D.new()
					body.name = "Support"
					body.position.y = -cube_size/2.0
					body.set_meta("array_index",cell)
					body.set_meta("void_floor_surface",true)
					slot.add_child(body)
					var collision := CollisionShape3D.new()
					var shape := BoxShape3D.new()
					shape.size = Vector3.ONE*cube_size
					collision.shape = shape
					body.add_child(collision)
					solids[cell] = body
				else:
					# An outlined address is a hole, not an invisible platform.
					for side in [-1,1]:
						box(slot,"EmptyX",Vector3(side*cube_size/2.0,0,0),Vector3(.008,.008,cube_size),ghost)
						box(slot,"EmptyZ",Vector3(0,0,side*cube_size/2.0),Vector3(cube_size,.008,.008),ghost)
				var text := label(slot,"[%d,%d,%d]"%[x,y,z]+("" if present else " / EMPTY"),Vector3(0,.018,0),.0013)
				text.rotation_degrees.x = -90
				if route.has(cell):
					box(slot,"LandingStripe",Vector3(0,.007,cube_size*.35),Vector3(cube_size*.8,.009,.045),pink)
			layers.append(row)
		values.append(layers)
	build_suspension(dark)
	var instructions := label(self,"3D ARRAY / [x, layer, z]\nPINK EDGES: LAND HERE",Vector3(-2.95,.025,-4.4),.0014)
	instructions.rotation_degrees = Vector3(-90,-90,0)

func cell_top(cell: Vector3i) -> Vector3:
	return centre+Vector3((cell.x-(size_x-1)*.5)*spacing,-cell.y*layer_drop,(cell.z-(size_z-1)*.5)*spacing)

func build_suspension(finish: Material) -> void:
	var half_x := (size_x-1)*spacing/2.0+cube_size/2.0+.06
	var half_z := (size_z-1)*spacing/2.0+cube_size/2.0+.06
	var bottom := -(size_y-1)*layer_drop-cube_size-.04
	for side in [-1,1]:
		for end in [-1,1]:
			var corner := centre+Vector3(side*half_x,0,end*half_z)
			box(self,"TensionRod",corner+Vector3(0,bottom/2.0,0),Vector3(.025,-bottom,.025),finish)
			# The shoes sit outside the shaft, bolted onto its structural rim.
			box(self,"RimShoe",corner+Vector3(side*.3,.025,0),Vector3(.34,.05,.30),finish)
			box(self,"RimCleat",corner+Vector3(side*.12,-.04,0),Vector3(.46,.08,.06),finish)
	for y in size_y:
		var level := centre+Vector3(0,-y*layer_drop-cube_size-.025,0)
		for side in [-1,1]:
			box(self,"FrameX",level+Vector3(0,0,side*half_z),Vector3(half_x*2,.04,.04),finish)
			box(self,"FrameZ",level+Vector3(side*half_x,0,0),Vector3(.04,.04,half_z*2),finish)
		for z in size_z:
			box(self,"CellStringer",level+Vector3(0,0,(z-(size_z-1)*.5)*spacing),Vector3(half_x*2,.035,.035),finish)

func label(host: Node3D, words: String, at: Vector3, pixels: float) -> Label3D:
	var result := Label3D.new()
	result.text = words
	result.font_size = 32
	result.pixel_size = pixels
	result.outline_size = 0
	result.modulate = Color("e2ebed")
	result.position = at
	host.add_child(result)
	return result

func material(colour: Color, glow := 0.0) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = colour
	result.roughness = .75
	result.emission_enabled = glow>0
	result.emission = colour
	result.emission_energy_multiplier = glow
	return result

func box(host: Node3D, title: String, at: Vector3, size: Vector3, finish: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = title
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = finish
	node.position = at
	host.add_child(node)
