extends Node3D
## Paired angular model; each hand point sets a common release, never a throw.
const Model = preload("res://commons/artifacts/pendulum_noise/pendulum_pair.gd")
const Point = preload("res://commons/artifacts/pendulum_noise/angle_point.gd")
const Console = preload("res://commons/ui/control_console.gd")
const HEIGHT := 2.35
var model = Model.new()
var points: Array = []
var pivots: Array[Node3D] = []
var arrows: Array[MeshInstance3D] = []
var arrowheads: Array[MeshInstance3D] = []
var buttons := {}
var sliders := {}
var console: Node3D
var readout: Label3D
var lane_labels: Array[Label3D] = []
var trace: MeshInstance3D
var input_trace: MeshInstance3D
var running := false
var held_lane := -1
var accumulator := 0.0
var discarded_wall_seconds := 0.0
var _ui_clock := 0.0
var _synchronizing := false
var _plot_key := ""
var log_entries: Array[Dictionary] = []

func _ready() -> void:
	name = "PendulumNoise"
	var black := material("171b23")
	black.metallic = 0.25; black.roughness = 0.18
	box(Vector3(0,.025,0),Vector3(6.6,.035,2.5),material("dbd7d0"))
	for x in [-3.1,3.1]: box(Vector3(x,1.22,0),Vector3(.065,2.44,.08),black)
	box(Vector3(0,2.44,0),Vector3(6.25,.07,.08),black)
	for lane in 2:
		var pivot := Node3D.new(); pivot.position = anchor(lane); add_child(pivot); pivots.append(pivot)
		var rod := MeshInstance3D.new(); var mesh := CylinderMesh.new()
		mesh.top_radius = .008; mesh.bottom_radius = .008; mesh.height = Model.LENGTH
		rod.mesh = mesh; rod.material_override = black; rod.position.y = -Model.LENGTH/2
		pivot.add_child(rod)
		var point = Point.new(); point.apparatus = self; point.lane = lane
		point.name = "PointA" if lane == 0 else "PointB"
		point.gravity_scale = 0; point.collision_layer = 4; point.collision_mask = 0
		point.add_to_group("no_gravity_gun"); add_child(point); points.append(point)
		point.get_child(0).material_override = black
		point.picked_up.connect(_picked.bind(lane)); point.dropped.connect(_dropped.bind(lane))
		var arrow := box(Vector3.ZERO,Vector3(1,.022,.022),material("d770ab" if lane else "318897",true))
		arrows.append(arrow)
		var head := MeshInstance3D.new(); var cone := CylinderMesh.new()
		cone.top_radius=0; cone.bottom_radius=.045; cone.height=.12
		head.mesh=cone; head.material_override=arrow.material_override; add_child(head); arrowheads.append(head)
		lane_labels.append(plate("",Vector3((lane*2-1)*2.12,.90,.25),Vector2(1.85,.48),36,.0023))
	plate("THE SAME RELEASE / A RECORDED PUSH",Vector3(0,3.18,-.2),Vector2(6.3,.35),60,.0026)
	readout = plate("",Vector3(0,2.77,-.2),Vector2(6.3,.46),42,.0025)
	plate("PULL EITHER POINT · RELEASE BOTH\nAngular model / 1 kg / 1.1 m / no contacts",Vector3(0,.40,.25),Vector2(4.8,.34),38,.0024)
	box(Vector3(0,.075,-1.35),Vector3(6.2,.06,2.0),material("1e2936",true))
	trace = MeshInstance3D.new(); add_child(trace)
	input_trace = MeshInstance3D.new(); input_trace.material_override = material("f0d5a5",true); add_child(input_trace)
	plate("A BLUE / B ROSE · ANGLE 0–20 s, ±π\nGOLD: INPUT 0–4 s, ±12 N · plots clip, model does not",Vector3(0,.30,-2.2),Vector2(6.1,.3),32,.0023)
	console = Console.new(); console.auto_demo = false; console.face_to_origin = false
	console.body_height = .8; console.board_width = 2.25; console.position = Vector3(0,0,1.8)
	add_child(console); console.set_title("ONE COMPARISON AT A TIME")
	for spec in [["FORCE σ / 0–6 N","force"],["B DRAG / 0–3 kg/s","drag"]]:
		var slider = console.add_slider(spec[0],spec[1]); sliders[spec[1]] = slider
		slider.slider_moved.connect(_slider_changed.bind(spec[1]))
	for id in ["RUN / PAUSE","REPLAY","MODE","NEXT SEED","RESET"]:
		var button = console.add_button(id); buttons[id] = button; button.pressed.connect(act.bind(id))
	_sync_sliders(); draw_state(); draw_records(); _receipt("initial")

func anchor(lane: int) -> Vector3:
	return Vector3((lane*2-1)*1.55,HEIGHT,0)

func bob_world(lane: int) -> Vector3:
	return to_global(anchor(lane)+model.offset(lane))

func _picked(_point: Node3D, lane: int) -> void:
	held_lane = lane; running = false; accumulator = 0
	points[1-lane].enabled = false
	model.initial_angle = clampf(model.angle[lane],-Model.ANGLE_LIMIT,Model.ANGLE_LIMIT)
	model.reset(); draw_state()

func set_release_from_hand(lane: int, world: Vector3) -> void:
	if held_lane != lane: return
	var p := to_local(world)-anchor(lane)
	if Vector2(p.x,p.y).length()<.01: return
	model.initial_angle = clampf(atan2(p.x,-p.y),-Model.ANGLE_LIMIT,Model.ANGLE_LIMIT)
	model.reset()

func _dropped(_point: Node3D, lane: int) -> void:
	if lane != held_lane: return
	held_lane = -1; points[1-lane].enabled = true
	model.reset(); accumulator = 0; running = true
	_receipt("hand release; throw speed discarded")

func _physics_process(delta: float) -> void:
	if not running or held_lane >= 0: return
	if not is_finite(delta) or delta <= 0: return
	# At most .1 model seconds per callback; report dropped wall time, never jump state.
	discarded_wall_seconds += maxf(0,delta-.1)
	accumulator += minf(delta,.1)
	while accumulator >= Model.DT:
		accumulator -= Model.DT
		if not model.step():
			running = false; accumulator = 0; _receipt("finished"); break

func _process(delta: float) -> void:
	draw_state()
	_ui_clock += delta
	if _ui_clock >= .1:
		_ui_clock = 0; draw_records()

func _sync_sliders() -> void:
	_synchronizing = true
	sliders.force.set_normalized_value(model.sigma_n/6)
	sliders.drag.set_normalized_value(model.changed_drag/3)
	_synchronizing = false

func _slider_changed(_value: Variant, id: String) -> void:
	if _synchronizing or held_lane >= 0: return
	var value: float = sliders[id].get_normalized_value()
	if not is_finite(value): return
	if id == "force": model.sigma_n = clampf(value,0,1)*6
	else:
		model.changed_drag = clampf(value,0,1)*3
		model.compare_damping = true # A labelled comparison, not a hidden second change.
	restart(false); _receipt("parameter "+id)

func restart(play: bool) -> void:
	model.reset(); accumulator = 0; discarded_wall_seconds = 0; running = play
	draw_state(); draw_records()

func act(id: String) -> void:
	if held_lane >= 0: return
	match id:
		"RUN / PAUSE":
			if model.tick >= Model.LAST_TICK: restart(true)
			else: running = not running
		"REPLAY": restart(true)
		"MODE": model.compare_damping = not model.compare_damping; restart(false)
		"NEXT SEED":
			model.resample(0 if model.noise_seed == 9223372036854775807 else model.noise_seed+1)
			restart(false)
		"RESET":
			model.sigma_n=2; model.changed_drag=1.2; model.compare_damping=false; model.initial_angle=.6
			model.resample(1847); _sync_sliders(); restart(false)
	_receipt(id)

func draw_state() -> void:
	if readout == null: return
	for lane in 2:
		pivots[lane].rotation.z = model.angle[lane]
		if not points[lane].is_picked_up(): points[lane].global_position = bob_world(lane)
		var f: float = model.force_at(model.tick,lane)
		arrows[lane].visible = absf(f)>.01
		arrows[lane].scale.x = maxf(absf(f)*.12,.001)
		arrows[lane].position = anchor(lane)+model.offset(lane)+Vector3(f*.06,0,.19)
		arrowheads[lane].visible=arrows[lane].visible
		arrowheads[lane].position=anchor(lane)+model.offset(lane)+Vector3(f*.12,0,.19)
		arrowheads[lane].rotation.z=-PI/2 if f>0 else PI/2
		var settle: float = model.settled_at(lane)
		lane_labels[lane].text = ("%s · θ %.1f° · ω %.2f rad/s\nF %.2f N · peak %.1f°\nsettle %s") % ["A" if lane==0 else "B",rad_to_deg(model.angle[lane]),model.omega[lane],f,rad_to_deg(model.peak[lane]),"pending" if model.tick<Model.LAST_TICK else ("not in 20 s" if settle<0 else "%.2f s"%settle)]
	var comparison := "A: NO PUSH / B: RECORDED PUSH · both drag 0.35 kg/s"
	if model.compare_damping: comparison = "SAME PUSH · A drag 0.35 / B drag %.2f kg/s"%model.changed_drag
	readout.text = "%s\n%.2f / 20 s · %s · seed %d · σ %.2f N · wall time omitted %.2f s" % [comparison,model.tick*Model.DT,"PULLING" if held_lane>=0 else ("COMPLETE" if model.tick>=Model.LAST_TICK else ("RUNNING" if running else "READY / PAUSED")),model.noise_seed,model.sigma_n,discarded_wall_seconds]

func draw_records() -> void:
	var key := str([model.tick,model.noise_seed,model.sigma_n,model.compare_damping,model.changed_drag,model.initial_angle])
	if key==_plot_key: return
	_plot_key=key
	var lines := ImmediateMesh.new()
	for lane in 2:
		if model.history.size()<2: continue
		lines.surface_begin(Mesh.PRIMITIVE_LINES,material("d770ab" if lane else "50b4c4",true))
		for i in range(1,model.history.size()):
			for j in [i-1,i]:
				var p: Dictionary = model.history[j]
				lines.surface_add_vertex(Vector3(-2.8+5.6*p.time/20,.12, -1.6-clampf(p.angles[lane],-PI,PI)*.17))
		lines.surface_end()
	trace.mesh = lines
	var force_lines := ImmediateMesh.new()
	force_lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in 40:
		var x := -2.8+float(i)*5.6/40
		force_lines.surface_add_vertex(Vector3(x,.14,-.7))
		force_lines.surface_add_vertex(Vector3(x,.14,-.7-clampf(model.unit_forces[i]*model.sigma_n,-12,12)*.018))
	force_lines.surface_end(); input_trace.mesh=force_lines

func _receipt(event: String) -> void:
	log_entries.append({"event":event,"seed":model.noise_seed,"sigma_n":model.sigma_n,
		"mode":"same input/different drag" if model.compare_damping else "off/on",
		"changed_drag":model.changed_drag,"initial_angle":model.initial_angle,"tick":model.tick,
		"peak":model.peak.duplicate(),"settled_at":[model.settled_at(0),model.settled_at(1)],
		"engine":Engine.get_version_info().string,"dropped_wall_seconds":discarded_wall_seconds})
	if log_entries.size()>64: log_entries.pop_front()

func material(hex: String, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color=Color(hex)
	if unshaded: m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func box(at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var v := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size=size
	v.mesh=mesh; v.material_override=mat; v.position=at; add_child(v); return v

func plate(text: String, at: Vector3, size: Vector2, font: int, pixels: float) -> Label3D:
	var backing := box(at,Vector3(size.x,size.y,.035),material("25303d",true))
	var label := Label3D.new(); label.text=text; label.font_size=font; label.pixel_size=pixels
	label.position.z=.02; label.outline_size=0; label.modulate=Color("f4ebdf")
	backing.add_child(label); return label
