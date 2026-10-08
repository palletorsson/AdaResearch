extends "res://commons/artifacts/force_play/play_space.gd"
## A room-size ballistic diagram. Only this exhibit's clock pauses.
const G := 9.8
const APEX_TIME := 0.85
var simulation_time := 0.0
var hold_time := 0.0
var automatic := true
var manual_pause := false
var paused_this_cycle := false
var sparks: Array[MeshInstance3D] = []
var velocities: Array[Vector3] = []
var tails: MeshInstance3D
var velocity_arrow: Node3D

func build() -> void:
	extent=Vector2(16,16);kind="fountain"
	floor_patch(extent,ink)
	title("A THROW / HELD IN TIME","Forty-eight launch velocities. One gravity. The pause belongs to this fountain.",6.9)
	box(Vector3(0,0.18,0),Vector3(1.2,0.36,1.2),pale,true)
	var mesh=SphereMesh.new();mesh.radius=0.085;mesh.height=0.17;mesh.radial_segments=12;mesh.rings=6
	var palette: Array=[]
	for i in range(8):
		var m=StandardMaterial3D.new();m.albedo_color=Color.from_hsv(float(i)/8,0.7,1)
		m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.emission_enabled=true;m.emission=m.albedo_color
		palette.append(m)
	for i in range(48):
		var phi=TAU*float(i)/48;var angle=0.12+0.47*float(i%6)/5
		var speed=8.5+2.0*float(i%7)/6
		velocities.append(Vector3(cos(phi)*sin(angle),cos(angle),sin(phi)*sin(angle))*speed)
		var spark=MeshInstance3D.new();spark.mesh=mesh;spark.material_override=palette[i%8];add_child(spark);sparks.append(spark)
	tails=MeshInstance3D.new();add_child(tails)
	var lines=StandardMaterial3D.new();lines.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;lines.vertex_color_use_as_albedo=true;tails.material_override=lines
	velocity_arrow=rod(Vector3.ZERO,Vector3.UP,blue,0.024,true)
	control("FREEZE / RESUME",Vector3(-1.1,0,-6.3));control("AUTO",Vector3(1.1,0,-6.3))
	update_picture()

func position_at(i: int,t: float) -> Vector3:
	return Vector3(0,0.45,0)+velocities[i]*t-Vector3.UP*0.5*G*t*t

func velocity_at(i: int,t: float) -> Vector3:
	return velocities[i]-Vector3.UP*G*t

func step(dt: float) -> void:
	if manual_pause:status.text="HELD / press FREEZE / RESUME to continue";return
	if hold_time>0:
		hold_time=maxf(0,hold_time-dt);status.text="TIME HELD / positions and velocities retained";return
	var next=simulation_time+dt
	if automatic and not paused_this_cycle and next>=APEX_TIME:
		next=APEX_TIME;hold_time=2.4;paused_this_cycle=true
	simulation_time=next
	if simulation_time>2.65:simulation_time=0;paused_this_cycle=false
	update_picture()
	status.text="t %.2f s   /   g %.1f m/s²   /   cyan = one velocity"%[simulation_time,G]

func update_picture() -> void:
	var line=ImmediateMesh.new();var started=false
	for i in sparks.size():
		var p=position_at(i,simulation_time);sparks[i].position=p;sparks[i].visible=p.y>=0.12
		for j in range(1,9):
			var a=maxf(0,simulation_time-float(j)*0.045);var b=maxf(0,simulation_time-float(j-1)*0.045)
			var pa=position_at(i,a);var pb=position_at(i,b)
			if pa.y<0.12 or pb.y<0.12:continue
			if not started:line.surface_begin(Mesh.PRIMITIVE_LINES);started=true
			line.surface_set_color(Color.from_hsv(float(i%8)/8,0.6,1-float(j)*0.065))
			line.surface_add_vertex(pa);line.surface_add_vertex(pb)
	if started:line.surface_end();tails.mesh=line
	else:tails.mesh=null
	velocity_arrow.set_ends(position_at(0,simulation_time),position_at(0,simulation_time)+velocity_at(0,simulation_time)*0.22)

func action(id: String) -> void:
	if id=="FREEZE / RESUME":
		manual_pause=not manual_pause;hold_time=0
	if id=="AUTO":automatic=not automatic;hold_time=0

func after_reset() -> void:
	simulation_time=0;hold_time=0;manual_pause=false;paused_this_cycle=false;update_picture()
