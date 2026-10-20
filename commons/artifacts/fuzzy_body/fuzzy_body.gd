extends Node3D
## A retained sphere, overlapping memberships and an explicit weighted rule blend.
## Field and cut views inspect the SAME source samples. No random displacement.
const Console = preload("res://commons/artifacts/fuzzy_body/fuzzy_console.gd")
const PointBody = preload("res://commons/artifacts/golden_mapping_lesson/point_body.gd")
const CORAL := Color("f17b85")
const BLUE := Color("60c9d5")
const GOLD := Color("f2d493")
const HOME := Vector3(0,1.4,3.52)
const CENTRE := Vector3(0,2.65,-1.55)
var panel: Node3D
var point: XRToolsPickable
var surface: MeshInstance3D
var wire: MeshInstance3D
var caption: Label3D
var meters: Array[MeshInstance3D]=[]
var meter_labels: Array[Label3D]=[]
var original := PackedVector3Array()
var output := PackedVector3Array()
var memberships := PackedVector3Array()
var mode := 1
var width := .95
var strength := .85
var threshold := .5
var centre_x := 0.0
var triangle_count := 0
var selected_count := 0
var syncing := false
var previous_x := INF
var clock := 0.0
var revision := 0
var parked_x := 0.0
var was_held := false
var last_held_x := 0.0

func _ready() -> void:
	panel=Console.new();panel.position.z=3.1;add_child(panel)
	for i in 3:panel.buttons[["FIELDS","RULES","CUT"][i]].pressed.connect(select_mode.bind(i))
	for i in 3:panel.buttons[["LEFT","CENTRE","RIGHT"][i]].pressed.connect(place_point.bind((i-1)*.78))
	for d in [panel.width_dial,panel.force_dial,panel.cut_dial]:d.hinge_moved.connect(read_controls)
	point=PointBody.new();point.name="CarriedPoint";point.position=HOME;point.tint=Color("17191e");add_child(point)
	make_source()
	surface=MeshInstance3D.new();surface.name="RuleBody";add_child(surface)
	var finish:=StandardMaterial3D.new();finish.vertex_color_use_as_albedo=true;finish.roughness=.28;finish.metallic=.16;finish.cull_mode=BaseMaterial3D.CULL_DISABLED
	surface.material_override=finish
	wire=MeshInstance3D.new();wire.name="RetainedOutline";add_child(wire)
	make_outline()
	make_room()
	sync_controls();rebuild()

func make_source() -> void:
	var sphere:=SphereMesh.new();sphere.radius=1.05;sphere.height=2.1;sphere.radial_segments=48;sphere.rings=24
	var arrays:=sphere.get_mesh_arrays()
	var verts:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var ids:PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	for i in range(0,ids.size(),3):
		var a:=verts[ids[i]];var b:=verts[ids[i+1]];var c:=verts[ids[i+2]]
		if (b-a).cross(c-a).length_squared()>.00000001:original.append_array(PackedVector3Array([a,b,c]))
	triangle_count=original.size()/3

func degrees(x: float) -> Vector3:
	# Independent sets: their sum need not equal one. AND is explicitly min.
	var a:=1.0-smoothstep(-width,width,x-.30)
	var b:=smoothstep(-width,width,x+.30)
	return Vector3(a,b,minf(a,b))

func transformed(p: Vector3, mu: Vector3) -> Vector3:
	var lift:=Vector3(p.x*.65,p.y*2.1+.15,p.z*.85)
	var hinge:=Vector3(.65,-.45,0)
	var fold:=Basis(Vector3.BACK,1.25)*(p-hinge)+hinge
	var twist:=Basis(Vector3.UP,p.y*2.8)*Vector3(p.x*1.2,p.y*1.35,p.z*.45)
	# Three rule consequents plus a fixed neutral baseline. This normalization
	# blends output positions; it does not turn memberships into probabilities.
	var target:Vector3=(p*.2+lift*mu.x+fold*mu.y+twist*mu.z)/(.2+mu.x+mu.y+mu.z)
	return p.lerp(target,strength)

func tint(mu: Vector3) -> Color:
	var total:=.12+mu.x+mu.y+mu.z
	return (Color("b4b6ba")*.12+CORAL*mu.x+BLUE*mu.y+GOLD*mu.z)/total

func rebuild() -> void:
	output.clear();memberships.clear();selected_count=0
	var drawing:=SurfaceTool.new();drawing.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0,original.size(),3):
		var midpoint:Vector3=(original[i]+original[i+1]+original[i+2])/3.0
		var selected:bool=mode!=2 or degrees(midpoint.x+centre_x).z>=threshold
		for j in 3:
			var p:=original[i+j];var mu:=degrees(p.x+centre_x)
			var q:=transformed(p,mu) if mode==1 else p
			output.append(q);memberships.append(mu)
			if selected:drawing.set_color(tint(mu));drawing.add_vertex(q)
		if selected:selected_count+=1
	if selected_count>0:
		drawing.generate_normals();surface.mesh=drawing.commit();surface.show()
	else:surface.mesh=null;surface.hide()
	surface.position=CENTRE+Vector3(centre_x,0,0);wire.position=surface.position
	wire.visible=mode!=0
	var mu:=degrees(centre_x)
	for i in 3:
		meters[i].scale.x=maxf(mu[i],.002)
		meters[i].position.x=-.62+.62*mu[i]
		meter_labels[i].text=["LEFT","RIGHT","BOTH"][i]+"  %.2f"%mu[i]
	panel.screen_title.text=["GRADED MEMBERSHIP","WEIGHTED RULES","THRESHOLD SELECTION"][mode]
	panel.screen_state.text="L %.2f / R %.2f\nBOTH %.2f / X %.2f"%[mu.x,mu.y,mu.z,centre_x]
	caption.text=["ONE SPHERE / TWO OVERLAPPING FIELDS","LEFT LIFTS / RIGHT FOLDS / BOTH TWIST","BOTH >= %.2f / %d OF %d FACES"%[threshold,selected_count,triangle_count]][mode]
	revision+=1

func make_outline() -> void:
	var mesh:=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for plane in 3:
		for i in 96:
			for theta in [TAU*i/96.0,TAU*(i+1)/96.0]:
				var p:=Vector3(cos(theta),sin(theta),0)*1.055
				if plane==1:p=Vector3(p.x,0,p.y)
				if plane==2:p=Vector3(0,p.x,p.y)
				mesh.surface_add_vertex(p)
	mesh.surface_end();wire.mesh=mesh
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("45565c");mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;wire.material_override=mat

func rod(a: Vector3,b: Vector3,r: float,col: Color) -> void:
	var item:=MeshInstance3D.new();var cylinder:=CylinderMesh.new();cylinder.top_radius=r;cylinder.bottom_radius=r;cylinder.height=a.distance_to(b);cylinder.radial_segments=12
	item.mesh=cylinder;item.material_override=panel.material(col);add_child(item);item.position=(a+b)*.5
	var direction:Vector3=(b-a).normalized();var side:=Vector3.RIGHT if absf(direction.dot(Vector3.RIGHT))<.9 else Vector3.FORWARD
	var axis:=side.cross(direction).normalized();item.basis=Basis(axis,direction,axis.cross(direction))

func make_room() -> void:
	panel.box(self,Vector3(0,3.3,-2.57),Vector3(7.2,6.6,.10),Color("e6e1d5"))
	var light:=OmniLight3D.new();light.position=Vector3(-.7,4,1.3);light.omni_range=7;light.light_energy=2.1;light.shadow_enabled=false;add_child(light)
	# Two open frames describe the fields without pretending to be their boundaries.
	for i in 2:
		var x:float=-1.45 if i==0 else 1.45;var col:Color=CORAL if i==0 else BLUE
		rod(Vector3(x-1.4,.08,-2.4),Vector3(x-1.4,5.2,-2.4),.032,col)
		rod(Vector3(x+1.4,.08,-2.4),Vector3(x+1.4,5.2,-2.4),.032,col)
		rod(Vector3(x-1.4,5.2,-2.4),Vector3(x+1.4,5.2,-2.4),.032,col)
		panel.text(self,["LEFT / LIFT","RIGHT / FOLD"][i],Vector3(x,5.42,-2.4),.0018,col)
	panel.box(self,Vector3(0,.025,-1.4),Vector3(7,.05,4.8),Color("d9ded9"))
	panel.box(self,Vector3(0,.32,-1.55),Vector3(6.5,.64,2.8),Color("23343b"),true)
	panel.text(self,"THE SOURCE REMAINS A SPHERE",Vector3(0,.34,-.13),.00145,Color("e6e1d5"))
	caption=panel.text(self,"",Vector3(0,4.73,.1),.0018,Color("203239"))
	panel.text(self,"TWO ROOMS CLAIM ONE BODY",Vector3(0,5.95,-1.7),.0028,Color("203239"))
	panel.text(self,"ENDLESS MUSEUM / always another room",Vector3(0,6.3,-1.7),.0013,Color("203239"))
	# Familiar hand point moves the centre of the larger sample, not the player.
	rod(HOME+Vector3(-.88,0,0),HOME+Vector3(.88,0,0),.007,Color("465b64"))
	panel.text(self,"HAND POINT / POSITION x1.7",HOME+Vector3(0,.18,0),.00065,Color("23343b"))
	for i in 3:
		var holder:=Node3D.new();holder.position=Vector3(2.75,1.35-i*.23,.8);add_child(holder)
		panel.box(holder,Vector3.ZERO,Vector3(1.24,.075,.022),Color("33434a"))
		meters.append(panel.box(holder,Vector3.ZERO,Vector3(1.24,.067,.025),[CORAL,BLUE,GOLD][i]))
		meter_labels.append(panel.text(holder,"",Vector3(0,.10,.03),.00062,Color("23343b")))
	panel.text(self,"AT THE CENTRE",Vector3(2.75,1.7,.8),.0009,Color("23343b"))

func _physics_process(delta: float) -> void:
	var held:bool=point.held()
	if held:
		last_held_x=clampf(to_local(point.global_position).x,-.88,.88)
	elif was_held:
		parked_x=last_held_x
	was_held=held
	# A frozen rigid body's server transform can arrive a physics frame after a
	# preset. Keep the parked target explicitly, instead of reading that stale
	# pose back into the instruction and undoing the visitor's button press.
	if not held:point.position=Vector3(parked_x,HOME.y,HOME.z)
	clock+=delta
	if clock<.05:return
	clock=0
	var local_x:float=last_held_x if held else parked_x
	if absf(local_x-previous_x)>.001:
		previous_x=local_x;centre_x=local_x*1.7;rebuild()

func place_point(x: float) -> void:
	# A button must not teleport something that is currently in a hand.
	if point.held():return
	parked_x=clampf(x,-.88,.88)
	point.position=Vector3(parked_x,HOME.y,HOME.z)
	previous_x=parked_x;centre_x=previous_x*1.7;rebuild()

func select_mode(value: int) -> void:
	mode=clampi(value,0,2);sync_controls();rebuild()

func sync_controls() -> void:
	syncing=true
	panel.width_dial.set_normalized_value((width-.15)/1.65)
	panel.force_dial.set_normalized_value(strength);panel.cut_dial.set_normalized_value(threshold)
	for i in 3:panel.buttons[["FIELDS","RULES","CUT"][i]].set_selected(mode==i)
	syncing=false

func read_controls(_value: float) -> void:
	if syncing:return
	width=lerpf(.15,1.8,panel.width_dial.get_normalized_value())
	strength=panel.force_dial.get_normalized_value();threshold=panel.cut_dial.get_normalized_value();rebuild()
