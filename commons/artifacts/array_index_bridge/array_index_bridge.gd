extends Node3D
## One occupancy array, read twice at different physical scales.
## The carried point chooses an address; writing that address changes real support.
signal state_changed(state: Dictionary)
const Kit = preload("res://commons/artifacts/regularity/room_tools.gd")
const Point = preload("res://commons/artifacts/abm_state_table/lesson/point_body.gd")
const COUNT := 7
const SMALL := 0.12
const LARGE := 0.68 # 4.76 m fits the fixed five-metre shaft.
const BOARD := Vector3(0,1.04,0)
const TARGET := Vector3(0,-0.18,-3.9)
var values: Array = []
var selected := Vector2i(3,3)
var point: XRToolsPickable
var small_mesh: MultiMeshInstance3D
var large_mesh: MultiMeshInstance3D
var colliders: Dictionary = {}
var small_cursor: Node3D
var large_cursor: Node3D
var address: Label3D
var readout: Label
var add_button: Node3D
var remove_button: Node3D
var restore_button: Node3D
var pending: Array[Vector2i] = []
var writes := 0
var restore_clock := 0.0
var control_panel: Node3D
var _hardware_requested := false

func _ready() -> void:
	process_physics_priority = 100
	for x in COUNT:
		var row: Array = []
		for z in COUNT: row.append(1)
		values.append(row)
	Kit.box(self,"ControlTable",Vector3(0,.48,0),Vector3(1.08,.96,1.08),Color("252b32"))
	small_mesh = collection("SmallGrid",SMALL,BOARD,0.025)
	large_mesh = collection("ShaftGrid",LARGE,TARGET,0.16)
	var shape := BoxShape3D.new()
	shape.size = Vector3(LARGE-.012,.16,LARGE-.012)
	for x in COUNT:
		for z in COUNT:
			var cell := Vector2i(x,z)
			var body := StaticBody3D.new()
			body.name = "Support_%d_%d" % [x,z]
			body.position = cell_position(cell,LARGE,TARGET)
			body.set_meta("array_index",cell)
			add_child(body)
			var collision := CollisionShape3D.new()
			collision.shape = shape
			body.add_child(collision)
			colliders[cell] = collision
			refresh_cell(cell)
	# Edges remain visible when a value is zero. They have no collision.
	for i in range(COUNT+1):
		var offset: float = (i-COUNT*.5)*LARGE
		Kit.box(self,"GridX%d"%i,TARGET+Vector3(offset,.083,0),Vector3(.009,.008,COUNT*LARGE),Color("718b96"),false)
		Kit.box(self,"GridZ%d"%i,TARGET+Vector3(0,.083,offset),Vector3(COUNT*LARGE,.008,.009),Color("718b96"),false)
	for i in COUNT:
		var at := (i-3)*SMALL
		var a := Kit.label(self,str(i),BOARD+Vector3(at,.025,.49))
		a.rotation_degrees.x=-90;a.font_size=24;a.pixel_size=.0015
		var b := Kit.label(self,str(i),BOARD+Vector3(-.49,.025,at))
		b.rotation_degrees.x=-90;b.font_size=24;b.pixel_size=.0015
	small_cursor = cursor("SelectedSmall",SMALL)
	large_cursor = cursor("SelectedLarge",LARGE)
	point = Point.new()
	point.name = "IndexPoint"
	point.tint = Color("ee86bd")
	# A small point keeps adjacent cells visible; use the same proven pickup body.
	point.scale = Vector3.ONE*.55
	add_child(point)
	point.action_pressed.connect(func(_body): write_selected(1-int(values[selected.x][selected.y])))
	address = Kit.label(self,"",Vector3(0,1.85,-.45))
	address.font_size=38;address.pixel_size=.002
	var instruction:=Kit.label(self,"GRIP THE POINT / MOVE ACROSS THE GRID\nTRIGGER: ADD OR REMOVE THIS CELL",Vector3(0,.82,.55))
	instruction.name="GripInstructions"
	instruction.font_size=28;instruction.pixel_size=.0012
	var panel := Kit.panel(self,"WRITE SELECTED CELL",Vector3(1.65,1.2,0),0)
	control_panel=panel
	add_button=panel.add_button("ADD [x,z]")
	remove_button=panel.add_button("REMOVE [x,z]")
	restore_button=panel.add_button("RESTORE ALL")
	add_button.pressed.connect(write_selected.bind(1))
	remove_button.pressed.connect(write_selected.bind(0))
	restore_button.pressed.connect(restore_all)
	readout=panel.add_readout("")
	var shaft_notice:=Kit.label(self,"7 x 7 / THE SAME ADDRESS\nREMOVING A TILE OPENS THE SHAFT",Vector3(0,1.7,-6.55))
	shaft_notice.name="ShaftNotice"
	shaft_notice.pixel_size=.002
	select_cell(selected)
	park_point()
	if _hardware_requested:
		preload("res://commons/void/array_control_hardware.gd").attach(self)

func apply_grid_config(config: Dictionary) -> void:
	if str(config.get("interface_style",""))!="architectural":return
	_hardware_requested=true
	if is_node_ready():
		preload("res://commons/void/array_control_hardware.gd").attach(self)

func collection(title: String, spacing: float, centre: Vector3, thickness: float) -> MultiMeshInstance3D:
	var result := MultiMeshInstance3D.new()
	result.name=title
	var mm := MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_colors=true
	var box := BoxMesh.new()
	box.size=Vector3(spacing-.012,thickness,spacing-.012)
	var material:=Kit.material(Color.WHITE)
	material.vertex_color_use_as_albedo=true
	mm.mesh=box;mm.instance_count=COUNT*COUNT
	result.multimesh=mm;result.material_override=material
	add_child(result)
	for x in COUNT:
		for z in COUNT:
			mm.set_instance_transform(x*COUNT+z,Transform3D(Basis.IDENTITY,cell_position(Vector2i(x,z),spacing,centre)))
	return result

func cell_position(cell: Vector2i, spacing: float, centre: Vector3) -> Vector3:
	return centre+Vector3((cell.x-3)*spacing,0,(cell.y-3)*spacing)

func cursor(title: String, size_: float) -> Node3D:
	var node:=Node3D.new();node.name=title;add_child(node)
	var colour:=Color("ff8dc8")
	var width:=.012 if size_<.2 else .035
	for side in [-1,1]:
		Kit.box(node,"X%d"%side,Vector3(side*size_*.5,0,0),Vector3(width,.012,size_),colour,false)
		Kit.box(node,"Z%d"%side,Vector3(0,0,side*size_*.5),Vector3(size_,.012,width),colour,false)
	return node

func index_at(local: Vector3) -> Vector2i:
	return Vector2i(clampi(floori(local.x/SMALL+3.5),0,6),clampi(floori(local.z/SMALL+3.5),0,6))

func select_cell(cell: Vector2i) -> void:
	selected=Vector2i(clampi(cell.x,0,6),clampi(cell.y,0,6))
	small_cursor.position=cell_position(selected,SMALL,BOARD)+Vector3.UP*.022
	large_cursor.position=cell_position(selected,LARGE,TARGET)+Vector3.UP*.09
	refresh_readout()

func _physics_process(delta: float) -> void:
	if point.held(): select_cell(index_at(to_local(point.global_position)-BOARD))
	else: park_point()
	if pending.is_empty():return
	restore_clock+=delta
	if restore_clock<.2:return
	restore_clock=0
	for cell in pending.duplicate():
		if not occupied(cell):
			set_cell(cell,1);pending.erase(cell)
	refresh_readout()

func park_point() -> void:
	point.position=cell_position(selected,SMALL,BOARD)+Vector3.UP*.1
	point.linear_velocity=Vector3.ZERO;point.angular_velocity=Vector3.ZERO

func occupied(cell: Vector2i) -> bool:
	var shape:=BoxShape3D.new()
	shape.size=Vector3(LARGE,.24,LARGE)
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.transform=global_transform*Transform3D(Basis.IDENTITY,cell_position(cell,LARGE,TARGET))
	for hit in get_world_3d().direct_space_state.intersect_shape(query,32):
		if hit.collider is CharacterBody3D:return true
	return false

func write_selected(value: int) -> void:
	if value==1 and values[selected.x][selected.y]==0 and occupied(selected):
		if not pending.has(selected):pending.append(selected)
		refresh_readout();return
	pending.erase(selected)
	set_cell(selected,value)
	refresh_readout()

func set_cell(cell: Vector2i, value: int) -> void:
	if values[cell.x][cell.y]==value:return
	values[cell.x][cell.y]=value;writes+=1
	refresh_cell(cell)
	state_changed.emit({"index":[cell.x,cell.y],"value":value,"writes":writes})

func refresh_cell(cell: Vector2i) -> void:
	var present: bool=int(values[cell.x][cell.y])==1
	var index:=cell.x*COUNT+cell.y
	small_mesh.multimesh.set_instance_color(index,Color("a3c4cd") if present else Color("20232d"))
	large_mesh.multimesh.set_instance_color(index,Color("98adb7"))
	large_mesh.multimesh.set_instance_transform(index,Transform3D(Basis.IDENTITY if present else Basis.IDENTITY.scaled(Vector3.ZERO),cell_position(cell,LARGE,TARGET)))
	colliders[cell].set_deferred("disabled",not present)

func restore_all() -> void:
	pending.clear()
	for x in COUNT:
		for z in COUNT:
			var cell:=Vector2i(x,z)
			if int(values[x][z])==0:
				if occupied(cell):pending.append(cell)
				else:set_cell(cell,1)
	refresh_readout()

func refresh_readout() -> void:
	if address==null:return
	var words:="[%d, %d] = %d" % [selected.x,selected.y,values[selected.x][selected.y]]
	address.text=words+"\nSMALL GRID  ->  SHAFT GRID"
	readout.text=words+(" / STEP CLEAR TO RESTORE" if not pending.is_empty() else "")

func prepare_editor_preview() -> void:
	set_physics_process(false)
