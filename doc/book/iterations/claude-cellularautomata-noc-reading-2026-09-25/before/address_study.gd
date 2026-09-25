extends Node3D
## A present plane, fixed addresses, and explicit output to three museum lamps.
const SIZE := 24
const LIMIT := 48
const SITES := [Vector2i(10,10),Vector2i(13,13),Vector2i(16,16)]
const FLOOR_CELL := 0.2
const FLOOR_Z := 3.6
var work: Node3D
var running: bool = false
var elapsed: float = 0.0
var preset: String = "GLIDER"
var linked: bool = true
var reading: Label3D
var console: Node3D
var floor_view: MultiMeshInstance3D
var receivers: Array[Node3D] = []
var changed: int = 0
var last_step_usec: int = 0

func _ready() -> void:
	work = get_parent()
	for name_ in ["Dish","Rim","CellMultiMesh"]:
		work.get_node(name_).position += Vector3(0,1.02,-1.55)
	_build_furniture()
	_build_floor()
	_build_receivers()
	replay()

func choose_glider() -> void:
	preset = "GLIDER";replay()

func choose_blinker() -> void:
	preset = "BLINKER";replay()

func choose_meeting() -> void:
	preset = "MEET";replay()

func replay() -> void:
	running = false;elapsed = 0.0;changed = 0
	work._generation_timer = 0.0
	work._clear_grid()
	# Both buffers are empty before a new experiment; _advance then fills the next.
	for row in work._next_grid: row.fill(false)
	if preset == "BLINKER":
		work._spawn_pattern("blinker",10,10)
	else:
		work._spawn_pattern("glider",7,7)
		if preset == "MEET":
			for y in [10,11]:
				for x in [10,11]: work._grid[y][x] = true
	work._update_display()
	for receiver in receivers: receiver.reset_events()
	_refresh(false)

func step_once() -> void:
	running = false;elapsed = 0.0
	_advance()

func _advance() -> void:
	if work._generation >= LIMIT:
		running = false;_readout();return
	var began: int = Time.get_ticks_usec()
	work._advance()
	changed = 0
	# After the base solver swaps, next_grid is the old present.
	for y in range(SIZE):
		for x in range(SIZE): changed += int(work._grid[y][x] != work._next_grid[y][x])
	if work._generation == LIMIT: running = false
	_refresh()
	last_step_usec = Time.get_ticks_usec()-began

func toggle_run() -> void:
	if work._generation < LIMIT: running = not running
	elapsed = 0.0;_readout()

func toggle_link() -> void:
	linked = not linked
	# Reconnecting a wire is not counted as a new birth at that address.
	_refresh(false)

func _process(delta: float) -> void:
	if not running: return
	elapsed += delta
	if elapsed >= 0.5:
		elapsed = 0.0;_advance()

func floor_position(site: Vector2i) -> Vector3:
	return Vector3((site.x-11.5)*FLOOR_CELL,0.016,FLOOR_Z+(site.y-11.5)*FLOOR_CELL)

func _refresh(count_event: bool = true) -> void:
	for y in range(SIZE):
		for x in range(SIZE):
			var on: bool = work._grid[y][x]
			floor_view.multimesh.set_instance_color(y*SIZE+x,Color("90ebca") if on else Color("273e49"))
	for receiver in receivers:
		var site: Vector2i = receiver.site
		var occupied: bool = work._grid[site.y][site.x]
		receiver.receive(occupied,linked,count_event)
	_readout()

func _readout() -> void:
	var status: String = "RUN" if running else "HELD"
	if work._generation == LIMIT:status = "LIMIT / REPLAY"
	reading.text = "A PATTERN TRAVELS\n%s / GEN %d / %s\nB3/S23 / 24 x 24 / WRAP\nPOP %d / CHANGED %d\nLAMPS %s" % [preset,work._generation,status,work._population,changed,"LINKED" if linked else "UNLINKED"]

func readback() -> Dictionary:
	var values: Array = []
	for r in receivers:values.append({"site":[r.site.x,r.site.y],"occupied":r.occupied,"lit":r.light.light_energy>0,"onsets":r.rises,"position":str(r.position)})
	return {"generation":work._generation,"population":work._population,"changed":changed,"preset":preset,"running":running,"linked":linked,"cells":work._grid.duplicate(true),"receivers":values,"step_usec":last_step_usec}

func _build_floor() -> void:
	# The coloured present is a finish on a continuous museum floor, not moving support.
	_box("FloorInset",Vector3(4.94,0.012,4.94),Vector3(0,0.004,FLOOR_Z),Color("927653"))
	floor_view = MultiMeshInstance3D.new()
	floor_view.name = "PresentPlane"
	var mm := MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true
	var mesh := BoxMesh.new();mesh.size=Vector3(0.185,0.012,0.185)
	var mat := StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=0.55
	mesh.material=mat;mm.mesh=mesh;mm.instance_count=SIZE*SIZE;floor_view.multimesh=mm;add_child(floor_view)
	for y in range(SIZE):
		for x in range(SIZE):mm.set_instance_transform(y*SIZE+x,Transform3D(Basis.IDENTITY,floor_position(Vector2i(x,y))))
	var axis := _label("FloorAxes","X: ACROSS / Y: ALONG / ONE PRESENT",30)
	axis.position=Vector3(0,0.03,FLOOR_Z-2.65);axis.rotation_degrees=Vector3(-90,0,0);add_child(axis)

func _build_receivers() -> void:
	for i in range(SITES.size()):
		var site: Vector2i = SITES[i]
		var receiver: Node3D = load("res://commons/artifacts/game_of_life_petri/life_address_receiver.gd").new()
		receiver.name = "Receiver%s" % ["A","B","C"][i]
		receiver.letter = ["A","B","C"][i]
		receiver.site = site
		receiver.position=Vector3(3.35,0,2.5+i*1.45)
		add_child(receiver);receivers.append(receiver)
		var at: Vector3 = floor_position(site)
		_marker("FloorAddress"+receiver.letter,at,0.205)
		# The small dish and full-size floor retain the same x/y orientation.
		var desk_at := Vector3((site.x-11.5)*work._cell_size,1.041,-1.55+(site.y-11.5)*work._cell_size)
		_marker("DishAddress"+receiver.letter,desk_at,work._cell_size*1.02)
		var span: float = 3.1-at.x
		_box("AddressWire"+receiver.letter,Vector3(span,0.009,0.012),Vector3(at.x+span/2,0.03,at.z),Color("d0a571"))
		_box("WireElbow"+receiver.letter,Vector3(0.012,0.009,absf(receiver.position.z-at.z)+0.02),Vector3(3.1,0.03,(receiver.position.z+at.z)/2),Color("d0a571"))
		var tag := _label("AddressLabel"+receiver.letter,"%s (%d,%d)"%[receiver.letter,site.x,site.y],30)
		tag.position=at+Vector3(-0.38,0.023,0);tag.rotation_degrees=Vector3(-90,0,0);add_child(tag)

func _marker(label: String,at: Vector3,size: float) -> void:
	var line: float = 0.008 if size>0.1 else 0.003
	for sign_ in [-1,1]:
		_box(label,Vector3(size,line,line),at+Vector3(0,0.014,sign_*size/2),Color("ffcc70"))
		_box(label,Vector3(line,line,size),at+Vector3(sign_*size/2,0.014,0),Color("ffcc70"))

func _build_furniture() -> void:
	_box("DishTable",Vector3(1.75,0.09,1.65),Vector3(0,0.96,-1.55),Color("365159"),true)
	_box("TableStem",Vector3(0.16,0.9,0.16),Vector3(0,0.45,-1.55),Color("b39470"),true)
	_box("TableFoot",Vector3(1.35,0.1,0.9),Vector3(0,0.05,-1.55),Color("6a5951"),true)
	var readout := Node3D.new();readout.name="ReadoutHousing";readout.position=Vector3(-1.55,1.55,-1.5);readout.rotation_degrees.y=180;add_child(readout)
	var casing: MeshInstance3D=_box("ReadoutCase",Vector3(1.25,0.68,0.075),Vector3.ZERO,Color("153237"));casing.reparent(readout,false)
	(casing.material_override as StandardMaterial3D).shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	_box("ReadoutStem",Vector3(0.07,1.20,0.07),Vector3(-1.55,0.6,-1.42),Color("b39470"),true)
	reading=_label("Readout","",34);reading.position=Vector3(0,0,0.043);readout.add_child(reading)
	console=Node3D.new();console.name="AddressConsole";console.position=Vector3(0,1.06,-2.3);console.rotation_degrees=Vector3(-35,180,0);add_child(console)
	var rack: GDScript=load("res://commons/audio/rack_templates/RackTemplates.gd")
	var buttons: Node3D=rack.create_panel("FOLLOW THE CELL / FOLLOW THE PATTERN",[
		[{"type":"button","label":"STEP"},{"type":"button","label":"RUN"},{"type":"button","label":"REPLAY"}],
		[{"type":"button","label":"GLIDER"},{"type":"button","label":"BLINKER"},{"type":"button","label":"MEET"},{"type":"button","label":"LINK"}]],false)
	buttons.name="AddressControls";buttons.scale=Vector3.ONE*2.0;console.add_child(buttons)
	var callbacks: Array[Callable]=[step_once,toggle_run,replay,choose_glider,choose_blinker,choose_meeting,toggle_link]
	for i in range(callbacks.size()):
		var callback: Callable=callbacks[i]
		buttons.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b):callback.call())

func _label(label: String,words: String,font: int) -> Label3D:
	var n:=Label3D.new();n.name=label;n.text=words;n.font_size=font;n.pixel_size=0.0014;n.outline_size=0;n.modulate=Color("ffe3c2");return n

func _box(label: String,size: Vector3,at: Vector3,colour: Color,solid: bool=false) -> MeshInstance3D:
	var n:=MeshInstance3D.new();n.name=label;n.position=at
	var mesh:=BoxMesh.new();mesh.size=size;n.mesh=mesh
	var mat:=StandardMaterial3D.new();mat.albedo_color=colour;mat.roughness=0.65;n.material_override=mat;add_child(n)
	if solid:
		var body:=StaticBody3D.new();var shape:=CollisionShape3D.new();var bounds:=BoxShape3D.new();bounds.size=size;shape.shape=bounds;n.add_child(body);body.add_child(shape)
	return n
