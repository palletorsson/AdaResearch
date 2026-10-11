extends Node3D
## Optional launch-hall comparison; no changes to the engine physics clock.
const Model = preload("res://algorithms/forces/euler_drift/step_model.gd")
const Point = preload("res://algorithms/forces/euler_drift/display_point.gd")
const Console = preload("res://commons/ui/control_console.gd")
var model = Model.new()
var points: Array = []
var buttons := {}
var slider: Node3D
var console: Node3D
var status: Label3D
var trace: MeshInstance3D
var reference_path: MeshInstance3D
var running := false
var syncing := false
var last_tick := -1

func _ready() -> void:
	name="StepStudy"
	box(Vector3(0,2.10,-.12),Vector3(5.3,4.15,.16),material("243440"),true)
	box(Vector3(0,1.95,-.025),Vector3(4.9,2.8,.025),material("ede7db"))
	for x in range(-2,3): box(Vector3(x,1.95,0),Vector3(.008,2.8,.008),material("b9b3aa"))
	for y in range(1,4): box(Vector3(0,y,0),Vector3(4.9,.008,.008),material("b9b3aa"))
	label("THE SAME THROW / DIFFERENT STEPS",Vector3(0,3.93,.02),.0020)
	status=label("",Vector3(0,3.48,.03),.0018)
	label("AMBER: formula   BLUE: position first, then velocity\n1 square = 1 metre / both stop at 1 second",Vector3(0,2.98,.04),.0015).modulate=Color("243440")
	trace=MeshInstance3D.new(); add_child(trace)
	reference_path=MeshInstance3D.new(); add_child(reference_path)
	for i in 2:
		var point=Point.new(); point.name="FormulaPoint" if i==0 else "SteppedPoint"
		point.apparatus=self; point.lane=i
		point.enabled=false; point.collision_layer=0; point.collision_mask=0
		point.add_to_group("no_gravity_gun"); add_child(point)
		point.get_child(0).material_override=material("c47b22" if i==0 else "207890")
		points.append(point)
	console=Console.new(); console.auto_demo=false; console.face_to_origin=false
	console.body_height=.6; console.board_width=2.4; console.position=Vector3(0,0,1.25)
	add_child(console); console.set_title("KEEP THE THROW / CHANGE THE INTERVAL")
	slider=console.add_slider("STEPS PER SECOND: 10 / 20 / 40","steps")
	slider.slider_moved.connect(_step_changed)
	for id in ["FIRE / PAUSE","ONE STEP","REPLAY","OTHER THROW","RESET"]:
		var button=console.add_button(id); buttons[id]=button; button.pressed.connect(act.bind(id))
	process_physics_priority=100
	restart(false); sync_slider()

func display(p: Vector3, _lane: int) -> Vector3:
	# Both paths share one plane, preserving their difference from every angle.
	return Vector3(p.x,p.y,.16)
func _physics_process(delta: float) -> void:
	if running:
		model.advance(delta)
		if model.finished(): running=false
	for lane in 2:
		var p: Vector3=model.reference_at(model.time()) if lane==0 else model.position
		points[lane].global_position=to_global(display(p,lane))
		points[lane].linear_velocity=Vector3.ZERO; points[lane].angular_velocity=Vector3.ZERO
	draw_state()
func restart(play: bool) -> void:
	model.reset(); running=play; last_tick=-1
	var samples: Array[Vector3]=[]
	for i in 81: samples.append(display(model.reference_at(float(i)/80),0))
	reference_path.mesh=path_mesh(samples,material("c47b22"))
	draw_state()
func sync_slider() -> void:
	syncing=true; slider.set_normalized_value(float(Model.COUNTS.find(model.count))/2); syncing=false
func _step_changed(_value: Variant) -> void:
	if syncing: return
	var i:=clampi(roundi(slider.get_normalized_value()*2),0,2)
	model.choose_steps(Model.COUNTS[i]); restart(false)
func act(id: String) -> void:
	match id:
		"FIRE / PAUSE":
			if model.finished(): restart(true)
			else: running=not running
		"ONE STEP": running=false; model.credit=0; model.step()
		"REPLAY": restart(true)
		"OTHER THROW":
			model.initial_velocity=Vector3(3,6,0) if model.initial_velocity.x==4 else Vector3(4,4.9,0)
			restart(false)
		"RESET":
			model.initial_velocity=Vector3(4,4.9,0); model.choose_steps(10); restart(false); sync_slider()
	draw_state()
func draw_state() -> void:
	if status==null: return
	status.text="h = %.3f s / %d steps    t = %.3f / 1.000 s\nv0 = (%.1f, %.1f) m/s    Δy = %+.4f m    %s"%[model.h(),model.count,model.time(),model.initial_velocity.x,model.initial_velocity.y,model.difference().y,"RUNNING" if running else ("FINISHED" if model.finished() else "READY / PAUSED")]
	if last_tick==model.tick: return
	last_tick=model.tick
	var samples: Array[Vector3]=[]
	for row in model.history(): samples.append(display(row.position,1))
	trace.mesh=path_mesh(samples,material("207890"),true)
func path_mesh(samples: Array[Vector3],mat: Material,marks:=false) -> ImmediateMesh:
	var mesh:=ImmediateMesh.new()
	if samples.size()<2: return mesh
	# A flat trace must remain visible from both sides of its display plane.
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES,mat)
	for i in range(1,samples.size()):
		var a:=samples[i-1];var b:=samples[i]
		var side:=Vector3(-(b-a).y,(b-a).x,0).normalized()*.009
		for v in [a-side,b-side,b+side,a-side,b+side,a+side]:mesh.surface_add_vertex(v)
		if marks:
			for v in [b+Vector3(-.025,-.025,0),b+Vector3(.025,-.025,0),b+Vector3(.025,.025,0),b+Vector3(-.025,-.025,0),b+Vector3(.025,.025,0),b+Vector3(-.025,.025,0)]:mesh.surface_add_vertex(v)
	mesh.surface_end(); return mesh
func material(hex: String) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new(); m.albedo_color=Color(hex); m.roughness=.35
	m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; return m
func box(at: Vector3,size: Vector3,mat: Material,solid:=false) -> void:
	var v:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size
	v.mesh=mesh; v.material_override=mat; v.position=at; add_child(v)
	if solid:
		var body:=StaticBody3D.new(); body.position=at; add_child(body)
		var c:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=size; c.shape=shape; body.add_child(c)
func label(text: String,at: Vector3,pixels: float) -> Label3D:
	var l:=Label3D.new(); l.text=text; l.position=at; l.font_size=40; l.pixel_size=pixels
	l.outline_size=0; l.modulate=Color("f3eddf"); add_child(l); return l
