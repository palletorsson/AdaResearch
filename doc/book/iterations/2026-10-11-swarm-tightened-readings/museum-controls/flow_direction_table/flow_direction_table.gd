extends "res://commons/artifacts/flow_museum/flow_museum.gd"
## The existing field/agents, with a hand that edits directions rather than traces.
const PointBody = preload("res://commons/artifacts/particle_swarm_walk/point_body.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const PAD := Vector3(0,1.0,2.15)
const HOME := Vector3(.78,1.13,2.95)
const PAD_SIZE := .9
const CAMERA_SPAN := 46.0
const MIN_STROKE := .012
const INK := Color("ffcf72")
const CYAN := Color("7adeef")
var point: XRToolsPickable
var pad: MeshInstance3D
var cursor: MeshInstance3D
var table_cursor: MeshInstance3D
var status: Label3D
var caps: Array[Node3D] = []
var direction_layer: Node3D
var shafts: MultiMesh
var tips: MultiMesh
var changed := PackedByteArray()
var drawing := false
var edit_mode := true
var playing := true
var previous := Vector2(-1,-1)
var time_since_sample := 0.0
var released := 0.0
var field_edits := 0
var returns := 0

func words(text: String, at: Vector3, size := 20) -> Label3D:
	var n := Label3D.new(); n.text=text; n.position=at; n.font_size=size
	n.pixel_size=.002; n.outline_size=5; n.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	add_child(n); return n

func _ready() -> void:
	super._ready()
	flow.set_process_unhandled_input(false)
	flow.apply_grid_config({"scenario":"wind"})
	flow.grid.generate_linear_field(Vector2.RIGHT)
	changed.resize(flow.grid.size); changed.fill(0)
	direction_layer=Node3D.new(); viewport.add_child(direction_layer)
	var stem:=CylinderMesh.new();stem.top_radius=.05;stem.bottom_radius=.05;stem.height=.55;stem.radial_segments=6
	var tip:=CylinderMesh.new();tip.top_radius=0;tip.bottom_radius=.16;tip.height=.26;tip.radial_segments=6
	shafts=make_instances(stem); tips=make_instances(tip)
	flow.visualizer.hide(); refresh_arrows()
	pad=MeshInstance3D.new(); var plane:=PlaneMesh.new();plane.size=Vector2.ONE*PAD_SIZE
	pad.mesh=plane;pad.position=PAD;pad.material_override=screen.material_override;add_child(pad)
	box(Vector3(1.0,.08,1.0),PAD-Vector3.UP*.05)
	box(Vector3(.3,.90,.3),Vector3(0,.45,PAD.z))
	box(Vector3(.32,1.0,.32),Vector3(HOME.x,.5,HOME.z))
	box(Vector3(.38,.08,1.35),Vector3(-.78,.96,PAD.z))
	box(Vector3(.24,.92,.24),Vector3(-.78,.46,PAD.z))
	point=PointBody.new();point.name="DirectionPoint";add_child(point);point.position=HOME
	point.action_pressed.connect(func(_p):drawing=point.held() and edit_mode)
	point.action_released.connect(func(_p):stop_stroke())
	cursor=make_cursor();table_cursor=make_cursor();table_cursor.scale=Vector3.ONE*(2.8/PAD_SIZE)
	add_button("PAUSE / PLAY",Vector3(-.78,1.03,1.72),toggle_play)
	add_button("RESET →",Vector3(-.78,1.03,2.15),reset_field)
	add_button("TOUR / DRAW",Vector3(-.78,1.03,2.58),toggle_mode)
	words("LEAVE A DIRECTION",Vector3(0,2.05,-1.1),32)
	words("Hold trigger. Draw a stroke.\nBodies read the arrows you leave.",Vector3(0,1.67,1.63),18)
	status=words("",Vector3(.15,1.43,1.68),15)
	update_status()

func make_instances(mesh: Mesh) -> MultiMesh:
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true
	mm.mesh=mesh;mm.instance_count=flow.grid.size
	var node:=MultiMeshInstance3D.new();node.multimesh=mm
	var m:=StandardMaterial3D.new();m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.vertex_color_use_as_albedo=true
	node.material_override=m;direction_layer.add_child(node);return mm

func refresh_arrows() -> void:
	for y in range(flow.grid.height):
		for x in range(flow.grid.width):
			var i: int=y*flow.grid.width+x
			var v: Vector2=flow.grid.vector_field[i]
			var d:=Vector3(v.x,0,v.y)
			var b:=Basis(Quaternion(Vector3.UP,d.normalized())) if d.length()>.001 else Basis.IDENTITY.scaled(Vector3.ONE*.0001)
			var at: Vector3=flow.grid.grid_to_world(x,y)+Vector3.UP*.22
			shafts.set_instance_transform(i,Transform3D(b,at-d*.08))
			tips.set_instance_transform(i,Transform3D(b,at+d*.325))
			var colour:=INK if changed[i]>0 else CYAN
			shafts.set_instance_color(i,colour);tips.set_instance_color(i,colour)

func make_cursor() -> MeshInstance3D:
	var n:=MeshInstance3D.new();var ring:=TorusMesh.new();ring.inner_radius=.026;ring.outer_radius=.034;ring.rings=24;ring.ring_segments=6
	n.mesh=ring;var m:=StandardMaterial3D.new();m.albedo_color=INK;m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	n.material_override=m;n.visible=false;add_child(n);return n

func add_button(title: String, at: Vector3, action: Callable) -> void:
	var b:=PushButton.instantiate();add_child(b);b.position=at;b.rotation=Vector3.ZERO;b.scale=Vector3.ONE*1.15
	b.pressed.connect(action);caps.append(b);words(title,at+Vector3.UP*.14,12)

func point_uv(p: Vector3) -> Vector2:
	var d:=p-PAD
	if d.y<.08 or d.y>.65:return Vector2(-1,-1)
	var uv:=Vector2(d.x,d.z)/PAD_SIZE+Vector2.ONE*.5
	var margin:float=(CAMERA_SPAN-40)/(2*CAMERA_SPAN)
	if uv.x<margin or uv.y<margin or uv.x>1-margin or uv.y>1-margin:return Vector2(-1,-1)
	return uv

func uv_to_cell(uv: Vector2) -> Vector2i:
	var p:Vector2=(uv-Vector2.ONE*.5)*CAMERA_SPAN
	return flow.grid.world_to_grid(Vector3(p.x,0,p.y))

func stop_stroke() -> void:
	drawing=false;previous=Vector2(-1,-1);time_since_sample=0

func paint_segment(a: Vector2, b: Vector2) -> void:
	var direction:Vector2=(b-a).normalized()
	var start:=uv_to_cell(a);var end:=uv_to_cell(b)
	var count:=maxi(absi(end.x-start.x),absi(end.y-start.y))
	for s in range(count+1):
		var center:=Vector2i(Vector2(start).lerp(Vector2(end),float(s)/maxi(count,1)).round())
		for y in range(-2,3):
			for x in range(-2,3):
				var c:=center+Vector2i(x,y)
				if x*x+y*y>4 or c.x<0 or c.y<0 or c.x>=40 or c.y>=40:continue
				var i:=c.y*40+c.x
				flow.grid.vector_field[i]=direction;changed[i]=1
	field_edits+=1;refresh_arrows()

func _physics_process(dt: float) -> void:
	if point.held():released=0
	else:
		stop_stroke();released+=dt
		if released>3 and (point.position.distance_to(HOME)>.001 or not point.rotation.is_zero_approx()):
			point.position=HOME;point.rotation=Vector3.ZERO;returns+=1
	var uv:=point_uv(to_local(point.global_position)) if point.held() and edit_mode else Vector2(-1,-1)
	var valid:=uv.x>=0
	cursor.visible=valid;table_cursor.visible=valid
	if valid:
		cursor.position=PAD+Vector3((uv.x-.5)*PAD_SIZE,.015,(uv.y-.5)*PAD_SIZE)
		table_cursor.position=Vector3((uv.x-.5)*2.8,.96,(uv.y-.5)*2.8)
	if not drawing or not valid:previous=Vector2(-1,-1);time_since_sample=0;return
	time_since_sample+=dt
	if time_since_sample<.05:return
	time_since_sample=fmod(time_since_sample,.05)
	if previous.x<0:previous=uv;return
	if previous.distance_to(uv)*PAD_SIZE<MIN_STROKE:return
	paint_segment(previous,uv);previous=uv

func _process(dt: float) -> void:
	super._process(dt)
	if edit_mode:
		caption.text="FLOW / DRAWN DIRECTIONS\n200 existing agents / gold cells were edited by hand"
	update_status()

func toggle_play() -> void:
	playing=not playing;flow.process_mode=Node.PROCESS_MODE_INHERIT if playing else Node.PROCESS_MODE_DISABLED
	update_status()

func reset_field() -> void:
	stop_stroke();edit_mode=true;flow.apply_grid_config({"scenario":"wind"})
	flow.grid.generate_linear_field(Vector2.RIGHT);changed.fill(0);field_edits=0
	flow.visualizer.hide();direction_layer.show();refresh_arrows();update_status()

func toggle_mode() -> void:
	stop_stroke()
	if not edit_mode:reset_field();return
	edit_mode=false;direction_layer.hide();flow.apply_grid_config({"scenario":"tour","field_display":"arrows"});flow.visualizer.show()
	update_status()

func update_status() -> void:
	if status==null:return
	status.text=("DRAW" if edit_mode else "TOUR: original scenarios")+ (" / running" if playing else " / paused")
	if edit_mode:status.text+="\n%d cells edited / arrows persist after release" % (changed.size()-changed.count(0))
	caps[0].set_selected(not playing);caps[2].set_selected(not edit_mode)

func get_museum_occupied_cells() -> Array[Vector2i]:
	var result:Array[Vector2i]=[]
	for rect in [Rect2(-1.5,-1.5,3,3),Rect2(-.5,1.65,1,1),Rect2(.60,2.77,.36,.36),Rect2(-.99,1.44,.42,1.42)]:
		for x in range(ceili(rect.size.x*4)+1):
			for z in range(ceili(rect.size.y*4)+1):
				var p:=to_global(Vector3(rect.position.x+x*.25,0,rect.position.y+z*.25))
				var c:=Vector2i(floori(p.x),floori(p.z))
				if not result.has(c):result.append(c)
	return result
