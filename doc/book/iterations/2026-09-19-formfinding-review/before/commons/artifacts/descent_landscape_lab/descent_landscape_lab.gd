extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Two authored objective surfaces, sampled by one finite-difference optimiser.
## The plotted height is cost, not the player's walkable terrain or a rigid body.
const EPS := 0.03
const LIMIT := 160
const RATES := [0.2, 0.7, 2.5, 5.0]
const TOLS := [0.01, 0.08, 0.3]
const STARTS := [Vector2(-2.8,-2), Vector2(2.8,-2), Vector2(0,-2)]
var surface := 0
var rate_index := 1
var tolerance_index := 0
var start_index := 0
var point := STARTS[0]
var steps := 0
var running := false
var status := "READY"
var parts := false
var rule := false
var elapsed := 0.0
var samples: Array[Vector2] = []
var last_delta := 0.0
var terrain: MeshInstance3D
var marker: MeshInstance3D
var trail: MeshInstance3D
var slope: MeshInstance3D
var board: Label3D
var first_panel: Node3D
var second_panel: Node3D

func cost(p: Vector2) -> float:
	if surface == 0: return 0.25 * p.length_squared()
	return 0.08 * pow(p.x*p.x-4.0,2) + 0.25*p.y*p.y + 0.15*p.x

func gradient(p: Vector2) -> Vector2:
	return Vector2((cost(p+Vector2(EPS,0))-cost(p-Vector2(EPS,0)))/(2*EPS),
		(cost(p+Vector2(0,EPS))-cost(p-Vector2(0,EPS)))/(2*EPS))

func plot(p: Vector2) -> Vector3:
	return Vector3(p.x,0.40+0.22*cost(p),p.y)

func _ready() -> void:
	box(Vector3(0,0.08,0),Vector3(6.3,0.16,6.3),material("21363d"),true)
	for x in [-3.16,3.16]:box(Vector3(x,0.19,0),Vector3(0.05,0.06,6.35),material("cfa565"))
	for z in [-3.16,3.16]:box(Vector3(0,0.19,z),Vector3(6.35,0.06,0.05),material("cfa565"))
	terrain=MeshInstance3D.new();add_child(terrain)
	var mat=material("407a80");mat.cull_mode=BaseMaterial3D.CULL_DISABLED;terrain.material_override=mat
	marker=MeshInstance3D.new();var ball=SphereMesh.new();ball.radius=0.12;ball.height=0.24;marker.mesh=ball;marker.material_override=material("ffcf71",true);add_child(marker)
	trail=MeshInstance3D.new();trail.mesh=ImmediateMesh.new();trail.material_override=material("ffcf71",true);add_child(trail)
	slope=MeshInstance3D.new();slope.mesh=ImmediateMesh.new();slope.material_override=material("ed80aa",true);add_child(slope)
	box(Vector3(0,3.3,4.1),Vector3(6.4,1.75,0.07),material("172a35"))
	for x in [-3.0,3.0]:box(Vector3(x,1.6,4.1),Vector3(0.1,3.2,0.1),material("263a44"),true)
	board=label("",Vector3(0,3.3,4.04),0.0032);board.rotation.y=PI
	first_panel=load("res://commons/artifacts/timing_machines/machine_stage.gd").new();add_child(first_panel)
	first_panel.position.z=-4.3;first_panel.rotation.y=PI
	first_panel.console(["STEP","RUN","RESET","START","SURFACE"],0,"WHERE WILL THE NEXT STEP GO?")
	second_panel=load("res://commons/artifacts/timing_machines/machine_stage.gd").new();add_child(second_panel)
	second_panel.position=Vector3(4.4,0,0);second_panel.rotation.y=-PI/2
	second_panel.console(["RATE","STOP","PARTS","RULE"],0,"CHANGE HOW IT SEARCHES")
	for panel in [first_panel,second_panel]:
		for id in panel.buttons:
			buttons[id]=panel.buttons[id];panel.buttons[id].pressed.connect(act.bind(id))
	build_surface();reset()

func build_surface() -> void:
	var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in 48:
		for x in 48:
			var a=plot(Vector2(-3+x*0.125,-3+z*0.125));var b=plot(Vector2(-3+(x+1)*0.125,-3+z*0.125))
			var c=plot(Vector2(-3+(x+1)*0.125,-3+(z+1)*0.125));var d=plot(Vector2(-3+x*0.125,-3+(z+1)*0.125))
			for v in [a,c,b,a,d,c]:st.add_vertex(v)
	st.generate_normals();terrain.mesh=st.commit()

func reset() -> void:
	point=STARTS[start_index];steps=0;running=false;elapsed=0;status="READY";last_delta=0;samples=[point];refresh()

func step_once() -> void:
	if status in ["SMALL SLOPE","LEFT FRAME","STEP LIMIT"]:return
	if steps>=LIMIT:status="STEP LIMIT";running=false;refresh();return
	var g=gradient(point)
	if g.length()<TOLS[tolerance_index]:status="SMALL SLOPE";running=false;refresh();return
	var proposed=point-RATES[rate_index]*g
	if absf(proposed.x)>3 or absf(proposed.y)>3:
		status="LEFT FRAME";running=false;refresh();return
	last_delta=cost(proposed)-cost(point)
	point=proposed;steps+=1;samples.append(point);status="STEPPING";refresh()

func _process(delta: float) -> void:
	if not running:return
	elapsed+=delta
	# Presentation clock, not physical elapsed time; one discrete step per interval.
	if elapsed>=0.22:elapsed=0;step_once()

func act(id: String) -> void:
	match id:
		"STEP":running=false;step_once()
		"RUN":
			if status not in ["SMALL SLOPE","LEFT FRAME","STEP LIMIT"]:running=not running;elapsed=0
		"RESET":reset()
		"START":start_index=(start_index+1)%STARTS.size();reset()
		"SURFACE":surface=1-surface;build_surface();reset()
		"RATE":rate_index=(rate_index+1)%RATES.size();reset()
		"STOP":tolerance_index=(tolerance_index+1)%TOLS.size();reset()
		"PARTS":parts=not parts
		"RULE":rule=not rule
	refresh()

func refresh() -> void:
	if marker==null:return
	marker.position=plot(point)+Vector3.UP*0.13
	var mesh: ImmediateMesh=trail.mesh;mesh.clear_surfaces()
	if samples.size()>1:
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for p in samples:mesh.surface_add_vertex(plot(p)+Vector3.UP*0.035)
		mesh.surface_end()
	var g=gradient(point);var arrow: ImmediateMesh=slope.mesh;arrow.clear_surfaces();slope.visible=parts
	if parts and g.length()>0.0001:
		var a=marker.position;var dir=Vector3(-g.x,0,-g.y).normalized();var b=a+dir*minf(g.length(),1.0);var side=dir.cross(Vector3.UP)*0.1
		arrow.surface_begin(Mesh.PRIMITIVE_LINES)
		for p in [a,b,b,b-dir*0.18+side,b,b-dir*0.18-side]:arrow.surface_add_vertex(p)
		arrow.surface_end()
	first_panel.readout.text="%s / %s\nstep %d   cost %.4f   change %+.4f"%["RUN" if running else "PAUSED",status,steps,cost(point),last_delta]
	second_panel.readout.text="RATE %.2f   STOP %.2f\n%s / start %d"%[RATES[rate_index],TOLS[tolerance_index],"BOWL" if surface==0 else "TWO VALLEYS",start_index+1]
	board.text="WHERE DOES DOWNHILL TAKE YOU?\nOne surface. One local update. Try another beginning."
	if parts:board.text+="\n(x,z) = (%.3f, %.3f)   |gradient| = %.4f\n48 x 48 drawn cells / slope samples +/- 0.03\nPink: negative gradient, horizontal, capped at 1 m"%[point.x,point.y,g.length()]
	if rule:board.text+="\np_next = p - rate * gradient(p)\nSMALL SLOPE is a tolerance, not a global answer.\nCost is authored; height = 0.40 + 0.22 * cost. No momentum."
