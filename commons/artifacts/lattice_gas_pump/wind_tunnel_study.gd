extends "res://commons/artifacts/lattice_gas_pump/lattice_gas_pump.gd"
## @identity
## essence: turn a boundary in the original four-direction lattice gas
## desire: make the obstacle and the consequences of its angle worth approaching
## needs: a reachable pink wheel; the visible plate and the actual solid mask agree
## truth: a boundary changes which local exchanges can happen. This is a discrete
## lattice-gas toy; the bounce counter is not a calibrated aerodynamic force.
## Original injection, head-on collision and bounce/stream methods are inherited.
const Mount = preload("res://commons/void/ceiling_display_mount.gd")
const Wheel = preload("res://commons/artifacts/sine_yoke/hand_wheel.gd")
const Block = preload("res://commons/artifacts/primitive_encounters/platform_block.tscn")
const Finish = preload("res://commons/artifacts/machine_finish.gd")
const FIELD_BOTTOM := .65
const SEED := 24108
const CENTRE := Vector2(14,10.5)
var wheel: Node3D
var blade: Node3D
var console: Node3D
var direction_marks: MultiMesh
var lower_pulley: Node3D
var upper_pulley: Node3D
var angle_degrees := 0.0
var initial_angle := 0.0
var running := true
var ticks := 0
var mask_revision := 0
var _installed := false
var _synchronizing := false
signal state_changed(state: Dictionary)

func _ready() -> void:
	cols = 44;rows = 22;cell = .16
	initial_angle = clampf(float(get_meta("config_initial_angle",0)),-80,80)
	angle_degrees = initial_angle
	_build();_installed = true
	wheel.set_angle_degrees(initial_angle)
	reset_flow()
	set_meta("void_preview_kind","Original 44 by 22 four-direction lattice gas, enlarged to a 7-metre field. The pink handwheel rotates the visible obstacle and its actual blocking cells. Editor geometry is a snapshot; live collision/streaming runs in Godot.")

func apply_grid_config(config: Dictionary) -> void:
	if not _installed:return
	if config.has("initial_angle"):
		initial_angle = clampf(float(config.initial_angle),-80,80)
		wheel.set_angle_degrees(initial_angle)
	if config.has("running"):running = bool(config.running)
	_update_reading()

func _build() -> void:
	var steel := Finish.steel();var ivory := Finish.ivory();var pink := Finish.pink()
	var back := _matte_mat(Color("0b1724"))
	# Body-scale output, independently of the original handwheel's comfortable size.
	var structure := Node3D.new();structure.name = "TunnelStructure";add_child(structure)
	for x in [-3.35,3.35]:
		var foot: Node3D = Block.instantiate();foot.name = "ConcreteFoot";foot.platform_size = Vector3(.85,.65,1.1)
		structure.add_child(foot);foot.position = Vector3(x,0,-.22)
		box(structure,"SteelLeg",Vector3(x,.85,-.22),Vector3(.16,.55,.3),steel,true)
		for z in [-.62,.18]:box(structure,"Anchor",Vector3(x,.68,z),Vector3(.08,.06,.08),ivory)
	box(structure,"SolidCabinet",Vector3(0,2.43,-.27),Vector3(7.3,3.88,.45),steel,true)
	box(structure,"DarkFieldBacking",Vector3(0,2.33,-.032),Vector3(7.08,3.58,.04),back)
	for x in [-3.62,3.62]:box(structure,"FrontSideRail",Vector3(x,2.43,.11),Vector3(.12,3.96,.24),steel)
	for y in [.49,4.37]:box(structure,"FrontCrossRail",Vector3(0,y,.11),Vector3(7.36,.12,.24),steel)
	box(structure,"PinkLowerInlay",Vector3(0,.38,.18),Vector3(7.3,.035,.035),pink)
	for x in [-3.57,3.57]:
		for y in [.7,2.4,4.16]:box(structure,"CaptiveFastener",Vector3(x,y,.25),Vector3(.045,.045,.025),ivory)
	# A single pane avoids double transparency. The original field is behind it.
	var glass := MeshInstance3D.new();glass.name = "GlassFront"
	var pane := QuadMesh.new();pane.size = Vector2(7.04,3.68);glass.mesh = pane
	glass.material_override = _glass_mat(Color("bed9e2"),.035);glass.position = Vector3(0,2.43,.31)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;structure.add_child(glass)
	solid(structure,Vector3(0,2.43,.31),Vector3(7.04,3.68,.018))
	# Short duct ends keep the object recognisable as an installed apparatus.
	for x in [-3.88,3.88]:
		var duct := _cylinder(Vector3(x,2.33,-.1),.34,.48,steel);duct.name = "DuctEnd";duct.rotation.z = PI/2;structure.add_child(duct)
		for k in [-1,0,1]:box(structure,"DuctSlat",Vector3(x,2.33+k*.14,.25),Vector3(.35,.035,.035),ivory)
	# One MultiMesh for the actual state, one for its four occupancy directions.
	_field = _make_field(cols,rows,cell,true);_field.name = "OriginalGasCells"
	# A thin tiled backing leaves each directional mark legible in front of it.
	_field.multimesh.mesh.size = Vector3(cell*.88,cell*.88,.012)
	_field.position = Vector3(-(cols-1)*cell*.5,FIELD_BOTTOM,.06);add_child(_field)
	var field_finish := StandardMaterial3D.new();field_finish.vertex_color_use_as_albedo = true
	field_finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;_field.material_override = field_finish
	direction_marks = MultiMesh.new();direction_marks.transform_format = MultiMesh.TRANSFORM_3D
	direction_marks.use_colors = true;direction_marks.instance_count = cols*rows*4
	var arrows := SurfaceTool.new();arrows.begin(Mesh.PRIMITIVE_TRIANGLES);arrows.set_color(Color.WHITE)
	for v in [Vector3(.036,0,0),Vector3(-.026,.019,0),Vector3(-.012,0,0),Vector3(.036,0,0),Vector3(-.012,0,0),Vector3(-.026,-.019,0)]:arrows.add_vertex(v)
	arrows.generate_normals();direction_marks.mesh = arrows.commit()
	var directions := MultiMeshInstance3D.new();directions.name = "ActualOccupancyBits";directions.multimesh = direction_marks
	var mark_finish := field_finish.duplicate();mark_finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	directions.material_override = mark_finish;directions.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	directions.position = _field.position+Vector3(0,0,.1);add_child(directions)
	blade = Node3D.new();blade.name = "ObstacleAtTheSameAngle"
	blade.position = _field.position+Vector3(CENTRE.x*cell,CENTRE.y*cell,.13);add_child(blade)
	box(blade,"OffWhitePlate",Vector3.ZERO,Vector3(1.28,.30,.12),ivory)
	for x in [-.64,.64]:
		var end := _cylinder(Vector3(x,0,0),.15,.12,ivory);end.rotation.x = PI/2;blade.add_child(end)
	box(blade,"PinkCentreIndex",Vector3(0,0,.075),Vector3(.045,.23,.02),pink)
	_build_drive(steel,ivory,pink)
	_build_controls()
	var n := cols*rows;_state.resize(n);_solid.resize(n)

func _build_drive(steel: Material, ivory: Material, pink: Material) -> void:
	var cx: float = blade.position.x
	wheel = Wheel.new();wheel.name = "ObstacleHandWheel";wheel.assemble()
	wheel.get_node("HingeOrigin/InteractableHinge").hinge_limit_min = -80
	wheel.get_node("HingeOrigin/InteractableHinge").hinge_limit_max = 80
	wheel.position = Vector3(cx,1.25,.88)
	var rotor: Node3D = wheel.get_node("HingeOrigin/InteractableHinge")
	var rim := MeshInstance3D.new();rim.name = "BlackSteelRim"
	var ring := TorusMesh.new();ring.inner_radius = .435;ring.outer_radius = .485;ring.rings = 64;ring.ring_segments = 12
	rim.mesh = ring;rim.rotation.z = PI/2;rim.material_override = steel;rotor.add_child(rim)
	for i in 4:
		var a := i*TAU/4
		rotor.add_child(_cylinder_between(Vector3.ZERO,Vector3(0,sin(a)*.46,-cos(a)*.46),.021,ivory))
	rotor.add_child(_cylinder_between(Vector3(-.3,0,0),Vector3(.16,0,0),.075,steel))
	rotor.add_child(_cylinder_between(Vector3(.03,0,-.48),Vector3(.29,0,-.48),.025,ivory))
	var grip := _cylinder_between(Vector3(.23,0,-.48),Vector3(.35,0,-.48),.047,pink);grip.name = "PinkGrip";rotor.add_child(grip)
	add_child(wheel);wheel.hinge_moved.connect(_turn_obstacle)
	box(self,"WheelBearing",Vector3(cx,1.25,.56),Vector3(.28,.28,.25),steel)
	box(self,"WheelPedestal",Vector3(cx,.43,.60),Vector3(.24,.86,.30),steel,true)
	box(self,"WheelFoot",Vector3(cx,.07,.65),Vector3(.65,.14,.7),steel,true)
	# An ideal 1:1 belt relays the low handwheel angle to the high plate axle.
	# Both witness pulleys and the plate read that one input; no effort model.
	for y in [1.25,blade.position.y]:
		var hub := Node3D.new();hub.position = Vector3(cx,y,.46);hub.name = "LowerPulley" if y==1.25 else "UpperPulley";add_child(hub)
		var disk := _cylinder(Vector3.ZERO,.125,.055,steel);disk.rotation.x = PI/2;hub.add_child(disk)
		box(hub,"OneTurnIndex",Vector3(.064,0,.04),Vector3(.10,.023,.015),pink)
		if y==1.25:lower_pulley = hub
		else:upper_pulley = hub
		add_child(_cylinder_between(Vector3(cx,y,.15),Vector3(cx,y,.96 if y==1.25 else .49),.045,ivory))
	var belt_points := PackedVector3Array()
	for i in 25:
		var a := float(i)/24*PI;belt_points.append(Vector3(cx+cos(a)*.145,blade.position.y+sin(a)*.145,.48))
	for i in 25:
		var a := PI+float(i)/24*PI;belt_points.append(Vector3(cx+cos(a)*.145,1.25+sin(a)*.145,.48))
	belt_points.append(belt_points[0])
	for i in range(belt_points.size()-1):add_child(_cylinder_between(belt_points[i],belt_points[i+1],.018,_matte_mat(Color("10121a"))))

func _build_controls() -> void:
	box(self,"ReadingCase",Vector3(1.0,1.55,.73),Vector3(2.25,.75,.12),Finish.steel())
	_readout = Label3D.new();_readout.name = "LiveReadout";_readout.position = Vector3(1.0,1.55,.802)
	_readout.font_size = 40;_readout.pixel_size = .0015;_readout.outline_size = 0;_readout.modulate = Color("f3f0e5");add_child(_readout)
	box(self,"ControlStem",Vector3(1.0,.55,.65),Vector3(.15,1.1,.25),Finish.steel(),true)
	var rack: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	console = rack.create_panel("TURN THE OBSTACLE",[[{"type":"button","label":"STEP"},{"type":"button","label":"RUN"},{"type":"button","label":"RESET"}]],false)
	console.name = "TunnelControls";console.scale = Vector3.ONE*1.75;console.position = Vector3(1.0,.93,.85);console.rotation.x = deg_to_rad(-25);add_child(console)
	var calls: Array[Callable] = [step_once,toggle_run,reset_flow]
	for i in calls.size():
		var call: Callable = calls[i]
		console.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b):call.call())
	var title := Label3D.new();title.name = "TunnelTitle";title.text = "WIND / TURN A BOUNDARY"
	title.position = Vector3(0,4.62,.18);title.font_size = 58;title.pixel_size = .003;title.outline_size = 0;title.modulate = Color("ffe6f1");add_child(title)

func _turn_obstacle(value: float) -> void:
	angle_degrees = clampf(value,-80,80)
	if is_instance_valid(blade):blade.rotation.z = deg_to_rad(angle_degrees)
	if is_instance_valid(lower_pulley):lower_pulley.rotation.z = deg_to_rad(angle_degrees);upper_pulley.rotation.z = deg_to_rad(angle_degrees)
	if _solid.size()==cols*rows:
		_update_mask();_paint();_update_reading()
	state_changed.emit({"angle":angle_degrees,"mask_revision":mask_revision})

func _update_mask() -> void:
	var a := deg_to_rad(angle_degrees);var ca := cos(a);var sa := sin(a)
	for y in rows:
		for x in cols:
			var p := Vector2(x,y)-CENTRE
			var local := Vector2(ca*p.x+sa*p.y,-sa*p.x+ca*p.y)
			var nearest := Vector2(clampf(local.x,-4,4),0)
			var blocked := y==0 or y==rows-1 or local.distance_to(nearest)<=1.0
			_solid[y*cols+x] = 1 if blocked else 0
			if blocked:_state[y*cols+x] = 0
	mask_revision += 1

func reset_flow() -> void:
	if _state.size()!=cols*rows:return
	_rng.seed = SEED
	# Retain the original source seeding distribution, then install this study's
	# rotated boundary. Fifty original updates settle the repeatable beginning.
	super._seed_gas();_update_mask()
	for i in 50:_step()
	ticks = 0;_accum = 0;_drag_smooth = 0
	_paint();_update_reading()

func step_once() -> void:running = false;advance_pair()
func toggle_run() -> void:running = not running;_accum = 0;_update_reading()
func advance_pair() -> void:
	var bounced := 0.0
	for i in 2:bounced += _step();ticks += 1
	_drag_smooth = lerpf(_drag_smooth,bounced,.25)
	_paint();_update_reading()
func _process(delta: float) -> void:
	if not running:return
	_accum += delta
	if _accum>=.12:_accum = 0;advance_pair()

func _paint() -> void:
	if not is_instance_valid(_field) or direction_marks==null:return
	var mm: MultiMesh = _field.multimesh
	var hues := [Color("a8f0df"),Color("f578bd"),Color("f1d096"),Color("b3b6ff")]
	for y in rows:
		for x in cols:
			var i := y*cols+x;var state: int = _state[i]
			var density := (state&1)+((state>>1)&1)+((state>>2)&1)+((state>>3)&1)
			var reverse: bool = (state&2)!=0
			var tint := Color("12202f").lerp(Color("448c97"),density/4.0)
			if reverse:tint = tint.lerp(Color("884d83"),.35)
			if _solid[i]==1:tint = Color("e7e3db")
			mm.set_instance_color(i,tint)
			for d in 4:
				var direction := Vector2(DX[d],DY[d])
				var basis := Basis(Vector3.BACK,atan2(direction.y,direction.x)) if _solid[i]==0 and (state&(1<<d))!=0 else Basis.IDENTITY.scaled(Vector3.ZERO)
				var at := Vector3(x*cell+direction.x*.035,y*cell+direction.y*.035,0)
				direction_marks.set_instance_transform(i*4+d,Transform3D(basis,at));direction_marks.set_instance_color(i*4+d,hues[d])

func _update_reading() -> void:
	if not is_instance_valid(_readout):return
	_readout.text = "OBSTACLE %+.0f°\nRIGHTWARD BOUNCES %.1f\n%s / %d UPDATES\nFOUR DIRECTIONS · SAME LOCAL RULE"%[angle_degrees,_drag_smooth,"RUN" if running else "HELD",ticks]

func box(host: Node3D, title: String, at: Vector3, size: Vector3, finish: Material, collision := false) -> void:
	Mount.box(host,title,at,size,finish)
	if collision:solid(host,at,size)
func solid(host: Node3D, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new();var shape := CollisionShape3D.new();var bounds := BoxShape3D.new();bounds.size = size
	shape.shape = bounds;shape.position = at;body.add_child(shape);host.add_child(body)
func readback() -> Dictionary:
	return {"angle":angle_degrees,"ticks":ticks,"running":running,"mask_revision":mask_revision,"state_hash":hash(_state),"mask_hash":hash(_solid),"bounces":_drag_smooth,"seed":SEED,"grid":[cols,rows],"cell_metres":cell,"warmup_updates":50}
