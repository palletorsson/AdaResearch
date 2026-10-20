extends Node3D
## Compose known operations; change the surround separately from the material.
const G = preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
const SLIDER = preload("res://commons/interactables/physical_stepped_slider.gd")
const BUTTON = preload("res://commons/interactables/push_button.tscn")
const SOFA = preload("res://commons/primitives/sofa/sofa.tscn")
const CHAIR = preload("res://commons/primitives/chair/chair_modern.tscn")
var material: ShaderMaterial
var receivers: Array[MeshInstance3D] = []
var sofa: MeshInstance3D
var sphere: MeshInstance3D
var cube: MeshInstance3D
var surroundings: Node3D
var backdrop: MeshInstance3D
var ceiling: MeshInstance3D
var lights: Array[OmniLight3D] = []
var sliders: Dictionary = {}
var buttons: Dictionary = {}
var readout: Label3D
var recipe := "LAYERED"
var dots := 1.0
var rim_amount := 1.0
var glow := .35
var ground_colour := Color(.06,.012,.07)
var roughness := .18
var theatrical := true
var quiet_wall: StandardMaterial3D
var stage_wall: StandardMaterial3D

func _ready()->void:
	material=ShaderMaterial.new();material.shader=preload("./recipe.gdshader")
	var pale:=G.material("ded4c4");var dark:=G.material("252331");var gold:=G.material("b69b64",.65)
	quiet_wall=G.material("96969b");stage_wall=G.material("651d54")
	G.box(self,Vector3(0,.008,0),Vector3(19,.016,14),dark)
	backdrop=G.box(self,Vector3(0,3,-6.9),Vector3(19,6,.12),stage_wall,true)
	backdrop.gi_mode=GeometryInstance3D.GI_MODE_DISABLED
	label("05 / THE ROOM CAN BE OTHERWISE",Vector3(0,5.3,-6.79),53)
	label("Change the material. Then change what surrounds it.",Vector3(0,4.75,-6.78),25)
	label("← COLLECTION     /     PLURAL BODY BEYOND",Vector3(0,.22,6.75),18)
	for x in [-8.9,8.9]:
		G.box(self,Vector3(x,3,-1.5),Vector3(.16,6,.18),gold,true)
	G.box(self,Vector3(0,6,-1.5),Vector3(18,.16,.18),gold)
	# The same sofa as the previous material room, with its source cross-section stood up.
	sofa=SOFA.instantiate();sofa.name="CarriedSofa"
	for cam in sofa.find_children("*","Camera3D",true,false):cam.free()
	sofa.position=Vector3(0,.9,-1.65)
	sofa.basis=Basis(Vector3(0,0,1),Vector3(1,0,0),Vector3(0,1,0)).scaled_local(Vector3(1.8,3.5,1.8))
	add_child(sofa);receivers.append(sofa)
	var body:=StaticBody3D.new();var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3.ONE;col.shape=shape;body.add_child(col);sofa.add_child(body)
	for x in [-2.8,2.8]:G.box(self,Vector3(x,.5,1.1),Vector3(1.25,1,1.25),pale,true)
	sphere=MeshInstance3D.new();sphere.name="CarriedSphere";var ball:=SphereMesh.new();ball.radius=.5;ball.height=1;ball.radial_segments=64;ball.rings=32;sphere.mesh=ball;sphere.position=Vector3(-2.8,1.5,1.1);add_child(sphere);receivers.append(sphere)
	var sb:=StaticBody3D.new();var sc:=CollisionShape3D.new();var ss:=SphereShape3D.new();ss.radius=.5;sc.shape=ss;sb.add_child(sc);sphere.add_child(sb)
	cube=G.box(self,Vector3(2.8,1.43,1.1),Vector3(.86,.86,.86),pale,true);cube.name="CarriedCube";receivers.append(cube)
	for receiver in receivers:
		receiver.material_override=material;receiver.gi_mode=GeometryInstance3D.GI_MODE_DISABLED
	# Fixed lamps stay outside the switchable surround. Geometry is not a light emitter here.
	for at in [Vector3(-4,4,3),Vector3(4,4,3),Vector3(1.8,4,-3)]:
		var lamp:=OmniLight3D.new();lamp.position=at;lamp.omni_range=11;lamp.light_energy=3;lamp.light_color=Color("fceada");add_child(lamp);lights.append(lamp)
		var bulb:=MeshInstance3D.new();var bm:=SphereMesh.new();bm.radius=.10;bm.height=.2;bulb.mesh=bm;bulb.material_override=pale;bulb.position=at;add_child(bulb)
	_build_surround(gold)
	# Controls share one bench, with a low readout and a view past it toward the sofa.
	G.box(self,Vector3(-3.2,.94,4.9),Vector3(4.8,.12,.7),pale,true)
	for x in [-5.3,-1.1]:G.box(self,Vector3(x,.44,4.9),Vector3(.12,.88,.4),gold,true)
	for i in range(3):
		var key:String=["DOTS","RIM","GLOW"][i];var slider=SLIDER.new();slider.param_name=key;slider.continuous=true;slider.position=Vector3(-5.3+i*.4,1.25,5.1);add_child(slider);sliders[key]=slider
		slider.value_changed.connect(func(v:float):set_control(key,v))
	for i in range(4):
		var key:String=["PALE","LAYERED","SETTING","RESET"][i];var b=BUTTON.instantiate();b.position=Vector3(-3.65+i*.75,1.01,4.85);add_child(b);buttons[key]=b
		b.get_node("InteractableAreaButton").button_pressed.connect(func(_b):act(key))
		var l:=label(key,b.position+Vector3(0,.018,.24),12);l.modulate=Color("252331");l.rotation_degrees.x=-60
	G.box(self,Vector3(-2.5,1.27,4.58),Vector3(2.95,.38,.04),dark)
	readout=label("",Vector3(-2.5,1.28,4.61),16)
	set_meta("em_visibility_bounds",AABB(Vector3(-9.6,0,-7.1),Vector3(19.2,6.2,14.5)))
	set_notify_transform(true)
	update_material();update_setting()

func _build_surround(gold:Material)->void:
	surroundings=Node3D.new();surroundings.name="SurrealSurround";add_child(surroundings)
	# Reuse the existing dream-water shader overhead, with its front side facing down.
	# It still uses TIME and no collision, fluid solver, screen refraction or corrected normals.
	ceiling=MeshInstance3D.new();ceiling.name="WaterAbove";var plane:=PlaneMesh.new();plane.size=Vector2(15,10);plane.subdivide_width=80;plane.subdivide_depth=56
	ceiling.mesh=plane;ceiling.position=Vector3(0,5.65,-.8);ceiling.rotation.x=PI;ceiling.custom_aabb=AABB(Vector3(-7.5,-.15,-5),Vector3(15,.3,10));var water:=ShaderMaterial.new();water.shader=preload("res://algorithms/shaders/book_of_shaders/queer_water.gdshader");ceiling.material_override=water;surroundings.add_child(ceiling)
	for x in [-7.55,7.55]:G.box(surroundings,Vector3(x,5.64,-.8),Vector3(.10,.12,10.2),gold)
	for z in [-5.85,4.25]:G.box(surroundings,Vector3(0,5.64,z),Vector3(15.2,.12,.10),gold)
	var pearl:=ShaderMaterial.new();pearl.shader=preload("res://algorithms/shaders/queer_collection_2/crushed_pearl.gdshader")
	for i in range(2):
		var side:= -1.0 if i==0 else 1.0
		var ring:=MeshInstance3D.new();var torus:=TorusMesh.new();torus.inner_radius=1.9;torus.outer_radius=2.04;torus.rings=64;torus.ring_segments=12;ring.mesh=torus;ring.material_override=pearl;ring.position=Vector3(side*6.05,2.9,-2.4);ring.rotation.x=PI*.5;ring.rotation.z=side*.30;surroundings.add_child(ring)
		var chair=CHAIR.instantiate();chair.name="ChairInRing_%d"%i;chair.position=Vector3(side*6.05,3.4,-2.4);chair.rotation_degrees=Vector3(0,180,side*110);chair.scale=Vector3.ONE*2.4;surroundings.add_child(chair)
		# This suspended reference is scenery, not a new invisible obstacle.
		for collision in chair.find_children("*","CollisionObject3D",true,false):collision.collision_layer=0;collision.collision_mask=0
		for mesh in chair.find_children("*","MeshInstance3D",true,false):mesh.material_override=pearl
		_drape(Vector3(side*5.5,0,-6.65))
	for mesh in surroundings.find_children("*","GeometryInstance3D",true,false):
		mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;mesh.gi_mode=GeometryInstance3D.GI_MODE_DISABLED

func _drape(at:Vector3)->void:
	# Authored folds, not cloth simulation. Existing foil only perturbs the normals.
	var mesh:=MeshInstance3D.new();mesh.name="FoilDrape";var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(24):
		for column in range(40):
			for corner in [Vector2(0,0),Vector2(0,1),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(1,0)]:
				var u:float=(column+corner.x)/40.;var v:float=(row+corner.y)/24.
				st.set_uv(Vector2(u,v));st.add_vertex(Vector3((u-.5)*4.8,.12+v*4.25,.20*sin(u*TAU*7)+.12*sin(v*PI)))
	st.generate_normals();mesh.mesh=st.commit();mesh.position=at
	var foil:=ShaderMaterial.new();foil.shader=preload("res://commons/resourses/shaders/foil_paper.gdshader");foil.set_shader_parameter("albedo",Color("e68bbd"));mesh.material_override=foil;surroundings.add_child(mesh)

func label(text:String,at:Vector3,size:int)->Label3D:
	var l:=Label3D.new();l.text=text;l.position=at;l.font_size=size*2;l.pixel_size=.002;l.modulate=Color("f1e4d4");l.outline_size=0;l.double_sided=false;add_child(l);return l

func act(key:String)->void:
	if key=="SETTING":
		theatrical=not theatrical;update_setting();return
	if key=="PALE":recipe="PALE";dots=0;rim_amount=0;glow=0;ground_colour=Color("ded4c4");roughness=.8
	elif key in ["LAYERED","RESET"]:recipe="LAYERED";dots=1;rim_amount=1;glow=.35;ground_colour=Color(.06,.012,.07);roughness=.18
	if key=="RESET":theatrical=true;update_setting()
	update_material()

func set_control(key:String,value:float)->void:
	recipe="CUSTOM"
	if key=="DOTS":dots=clampf(value,0,1)
	elif key=="RIM":rim_amount=clampf(value,0,1)*1.5
	elif key=="GLOW":glow=clampf(value,0,1)*.8
	update_material()

func update_material()->void:
	material.set_shader_parameter("room_inverse",global_transform.affine_inverse())
	material.set_shader_parameter("ground",ground_colour)
	material.set_shader_parameter("roughness",roughness)
	material.set_shader_parameter("dots",dots);material.set_shader_parameter("rim_amount",rim_amount);material.set_shader_parameter("glow",glow)
	sliders.DOTS.set_normalized_value(dots);sliders.RIM.set_normalized_value(rim_amount/1.5);sliders.GLOW.set_normalized_value(glow/.8)
	_update_readout()

func update_setting()->void:
	surroundings.visible=theatrical;backdrop.material_override=stage_wall if theatrical else quiet_wall
	_update_readout()

func _update_readout()->void:
	if readout:readout.text="%s  |  dots %.2f / rim %.2f / glow %.2f\n%s"%[recipe,dots,rim_amount,glow,"THEATRE — setting only" if theatrical else "STUDIO — setting only"]

func apply_grid_config(_config:Dictionary)->void:
	if is_instance_valid(material):material.set_shader_parameter("room_inverse",global_transform.affine_inverse())

func _notification(what:int)->void:
	if what==NOTIFICATION_TRANSFORM_CHANGED and is_instance_valid(material):
		material.set_shader_parameter("room_inverse",global_transform.affine_inverse())
