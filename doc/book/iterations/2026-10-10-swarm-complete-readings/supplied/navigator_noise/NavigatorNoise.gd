extends Node3D
## Two views of the same small course; bottom A point sets both starting heights.
const Model = preload("res://commons/artifacts/navigator_noise/navigation_pair.gd")
const StartPoint = preload("res://commons/artifacts/navigator_noise/start_point.gd")
const Console = preload("res://commons/ui/control_console.gd")
var model = Model.new()
var points: Array = []
var labels: Array[Label3D] = []
var commands: Array[MeshInstance3D] = []
var heads: Array[MeshInstance3D] = []
var status: Label3D
var trace: MeshInstance3D
var buttons := {}
var slider: Node3D
var console: Node3D
var running := false
var held := false
var accumulator := 0.0
var omitted_wall_seconds := 0.0
var synchronizing := false
var plot_tick := -1
var plot_clock := 0.0

func _ready() -> void:
	name="NavigatorNoise"
	var black := material("151b25"); black.roughness=.16; black.metallic=.25
	box(Vector3(0,2.28,-.13),Vector3(4.35,4.46,.16),material("253340",true))
	for lane in 2:
		var base := base_height(lane)
		box(Vector3(0,base+.20,-.025),Vector3(4.08,1.20,.03),material("e5e0d6"))
		var obstacle := MeshInstance3D.new(); var mesh := CylinderMesh.new()
		mesh.top_radius=Model.OBSTACLE_RADIUS; mesh.bottom_radius=Model.OBSTACLE_RADIUS; mesh.height=.22
		obstacle.mesh=mesh; obstacle.material_override=material("4c5664"); obstacle.rotation.x=PI/2
		obstacle.position=display(Vector2.ZERO,lane); add_child(obstacle)
		var goal := MeshInstance3D.new(); var ring := TorusMesh.new()
		ring.inner_radius=.10; ring.outer_radius=.15; ring.rings=24; ring.ring_segments=8
		goal.mesh=ring; goal.material_override=material("328370",true); goal.rotation.x=PI/2
		goal.position=display(Model.GOAL,lane); add_child(goal)
		var point = StartPoint.new(); point.apparatus=self; point.lane=lane
		point.name="ReferencePoint" if lane==0 else "ObservedPoint"
		point.collision_mask=0; point.enabled=lane==0; point.add_to_group("no_gravity_gun")
		add_child(point); point.get_child(0).material_override=black; points.append(point)
		if lane==0:
			point.picked_up.connect(_picked); point.dropped.connect(_dropped)
		labels.append(plate("",Vector3(0,base-.40,.04),Vector2(4.08,.40),34,.0022))
		commands.append(box(Vector3.ZERO,Vector3(.3,.025,.025),material("328370",true)))
		var head:=MeshInstance3D.new(); var cone:=CylinderMesh.new()
		cone.top_radius=0; cone.bottom_radius=.045; cone.height=.10
		head.mesh=cone; head.material_override=commands[-1].material_override; add_child(head); heads.append(head)
		# The authored detour is visible from the beginning, not discovered by the agent.
		for p in Model.WAYPOINTS.slice(0,2):
			box(display(p,lane),Vector3(.035,.035,.035),material("328370",true))
		for y in [Model.COURSE_MIN.y,Model.COURSE_MAX.y]: box(display(Vector2(0,y),lane),Vector3(3.70,.007,.008),material("7d827c",true))
		for x in [Model.COURSE_MIN.x,Model.COURSE_MAX.x]: box(display(Vector2(x,.31),lane),Vector3(.007,.98,.008),material("7d827c",true))
	plate("THE OBSTACLE / THE READING / THE COMMAND",Vector3(0,4.30,0),Vector2(4.22,.32),44,.0020)
	status=plate("",Vector3(0,3.98,.04),Vector2(4.22,.30),32,.0021)
	plate("A LOWER · ACCURATE     B UPPER · INTERVENED\nPull A up/down, release both · same goal and detour",Vector3(0,.28,.03),Vector2(4.22,.34),32,.0020)
	trace=MeshInstance3D.new(); add_child(trace)
	console=Console.new(); console.auto_demo=false; console.face_to_origin=false
	console.body_height=.60; console.board_width=2.3; console.position=Vector3(0,0,1.0)
	add_child(console); console.set_title("COMPARE WHAT THE POINT RECEIVES")
	slider=console.add_slider("STRENGTH: σ METRES / MISSING FRACTION","strength")
	slider.slider_moved.connect(_strength_changed)
	for id in ["RUN / PAUSE","REPLAY","MODE","FALLBACK","NEXT SEED","RESET"]:
		var b=console.add_button(id); buttons[id]=b; b.pressed.connect(act.bind(id))
	_sync(); draw_state()

func base_height(lane: int) -> float: return 1.45+lane*1.40
func display(p: Vector2,lane: int) -> Vector3: return Vector3(p.x,p.y+base_height(lane),.16)
func agent_world(lane: int) -> Vector3: return to_global(display(model.positions[lane],lane))

func _picked(_point: Node3D) -> void:
	held=true; running=false; accumulator=0
	model.reset(); plot_tick=-1

func start_from_hand(world: Vector3) -> void:
	if not held: return
	model.start_y=clampf(to_local(world).y-base_height(0),-.15,.15)
	model.reset(); plot_tick=-1

func _dropped(_point: Node3D) -> void:
	held=false; restart(true)

func _physics_process(delta: float) -> void:
	if not running or held or not is_finite(delta) or delta<=0: return
	omitted_wall_seconds+=maxf(0,delta-.1); accumulator+=minf(delta,.1)
	while accumulator+1e-10>=Model.DT:
		accumulator-=Model.DT
		if not model.step() or model.finished(): running=false; accumulator=0; break

func _process(delta: float) -> void:
	draw_state(); plot_clock+=delta
	if plot_clock>=.1: plot_clock=0; draw_trace()

func restart(play: bool) -> void:
	model.reset(); accumulator=0; omitted_wall_seconds=0; running=play; plot_tick=-1
	draw_state(); draw_trace()

func _sync() -> void:
	synchronizing=true
	slider.set_normalized_value(model.dropout if model.missing_mode else model.sigma_m/.8)
	synchronizing=false

func _strength_changed(_value: Variant) -> void:
	if synchronizing: return
	var value: float=slider.get_normalized_value()
	if model.missing_mode: model.dropout=value
	else: model.sigma_m=value*.8
	restart(false)

func act(id: String) -> void:
	if held: return
	match id:
		"RUN / PAUSE":
			if model.finished(): restart(true)
			else: running=not running
		"REPLAY": restart(true)
		"MODE": model.missing_mode=not model.missing_mode; _sync(); restart(false)
		"FALLBACK": model.hold_command=not model.hold_command; model.missing_mode=true; _sync(); restart(false)
		"NEXT SEED": model.resample(0 if model.sample_seed==9223372036854775807 else model.sample_seed+1); restart(false)
		"RESET":
			model.sigma_m=.5; model.dropout=.65; model.missing_mode=false; model.hold_command=false; model.start_y=0
			model.resample(1847); _sync(); restart(false)

func draw_state() -> void:
	if status==null: return
	for lane in 2:
		if not points[lane].is_picked_up(): points[lane].global_position=agent_world(lane)
		var command: Vector2=model.commands[lane]
		commands[lane].visible=command.length()>.001 and not model.outcomes[lane] in Model.TERMINAL
		commands[lane].position=display(model.positions[lane]+command*.25,lane)+Vector3(0,0,.18)
		commands[lane].rotation.z=command.angle(); commands[lane].scale.x=maxf(.001,command.length()/.6)
		heads[lane].visible=commands[lane].visible
		heads[lane].position=display(model.positions[lane]+command*.5,lane)+Vector3(0,0,.18)
		heads[lane].rotation.z=command.angle()-PI/2
		var observed: String="not sampled" if model.tick==0 else ("MISSING" if model.observations[lane]==null else "%.2f m"%model.observations[lane])
		labels[lane].text="%s · sample true %.2f m / read %s\n%s · cmd (%.2f, %.2f) m/s · %.2f s / %.2f m"%["A" if lane==0 else "B",model.sensed_true[lane],observed,model.outcomes[lane],command.x,command.y,model.elapsed[lane],model.lengths[lane]]
	var mode: String="MISSING %.0f%% · %s"%[100*model.dropout,"HOLD command" if model.hold_command else "STOP"] if model.missing_mode else "RANGE NOISE σ %.2f m"%model.sigma_m
	status.text="%s · seed %d\n%s · %.2f/20 s · omitted wall time %.2f s"%[mode,model.sample_seed,"PULLING" if held else ("RUNNING" if running else ("FINISHED" if model.finished() else "READY / PAUSED")),model.tick*Model.DT,omitted_wall_seconds]

func draw_trace() -> void:
	if plot_tick==model.tick: return
	plot_tick=model.tick
	var mesh:=ImmediateMesh.new()
	for lane in 2:
		if model.history.is_empty(): continue
		mesh.surface_begin(Mesh.PRIMITIVE_LINES,material("cb728b" if lane else "258b9c",true))
		for row in model.history:
			var entry: Dictionary=row.lanes[lane]
			if entry.has("inactive"): continue
			mesh.surface_add_vertex(display(entry.from,lane)+Vector3(0,0,.015))
			mesh.surface_add_vertex(display(entry.to,lane)+Vector3(0,0,.015))
		mesh.surface_end()
	trace.mesh=mesh

func material(hex: String, unshaded := false) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=Color(hex)
	if unshaded: m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
func box(at: Vector3,size: Vector3,mat: Material) -> MeshInstance3D:
	var v:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size
	v.mesh=mesh; v.material_override=mat; v.position=at; add_child(v); return v
func plate(text: String,at: Vector3,size: Vector2,font: int,pixels: float) -> Label3D:
	var backing:=box(at,Vector3(size.x,size.y,.025),material("253340",true))
	var label:=Label3D.new(); label.text=text; label.font_size=font; label.pixel_size=pixels
	label.position.z=.02; label.outline_size=0; label.modulate=Color("f3eddf"); backing.add_child(label); return label
