extends Node3D
const G=preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
const Field=preload("./field.gd")
const PaintSurface=preload("./paint_surface.gd")
const SLIDER=preload("res://commons/interactables/physical_stepped_slider.gd")
const BUTTON=preload("res://commons/interactables/push_button.tscn")
const Chair=preload("res://commons/primitives/chair/chair_modern.tscn")
var field:Node
var surface:MeshInstance3D
var touch:StaticBody3D
var material:ShaderMaterial
var receivers:Array[MeshInstance3D]=[]
var buttons:Dictionary={}
var sliders:Dictionary={}
var readout:Label3D
var alternate_ink:=false

func _ready()->void:
	var paper:=G.material("dcd6c8");var charcoal:=G.material("242c2d");var brass:=G.material("9c8961",.65)
	G.box(self,Vector3(0,.008,0),Vector3(18,.016,13),paper)
	G.box(self,Vector3(0,3.6,-4.1),Vector3(8,7.2,.18),charcoal,true)
	label("06 / WHAT STAYS WHEN YOU LET GO?",Vector3(0,6.7,-3.99),44)
	label("TOUCH / DRAW  ·  HOLD  ·  ONE STEP  ·  RUN",Vector3(0,6.23,-3.98),26)
	material=ShaderMaterial.new();material.shader=preload("./field_view.gdshader")
	surface=MeshInstance3D.new();surface.name="RetainedWall";var quad:=QuadMesh.new();quad.size=Vector2(5.6,5.6);surface.mesh=quad;surface.position=Vector3(0,3.25,-3.96);surface.material_override=material;add_child(surface);receivers.append(surface)
	touch=PaintSurface.new();touch.name="PaintSurface";touch.chamber=self;touch.position=surface.position;touch.collision_layer=1|(1<<20)|(1<<22);touch.collision_mask=0
	var col:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(5.6,5.6,.06);col.shape=shape;touch.add_child(col);add_child(touch)
	for x in [-4.8,4.8]:
		G.box(self,Vector3(x,.5,-.2),Vector3(1.3,1,1.3),charcoal,true)
		var mesh:=MeshInstance3D.new()
		if x<0:
			var ball:=SphereMesh.new();ball.radius=.55;ball.height=1.1;ball.radial_segments=64;ball.rings=32;mesh.mesh=ball
		else:
			var cube:=BoxMesh.new();cube.size=Vector3.ONE*1.05;mesh.mesh=cube
		mesh.material_override=material;mesh.position=Vector3(x,1.55,-.2);add_child(mesh);receivers.append(mesh)
		label("SAME RECORD / DIFFERENT BODY",Vector3(x,2.35,-.2),16)
		var sb:=StaticBody3D.new();var cs:=CollisionShape3D.new();var bs:=BoxShape3D.new();bs.size=Vector3.ONE*1.1;cs.shape=bs;sb.add_child(cs);mesh.add_child(sb)
	# Counterexample: existing Memory Skin with a declared noise texture, not a touch record.
	var memory:=ShaderMaterial.new();memory.shader=preload("res://algorithms/shaders/queer_collection_2/memory_skin.gdshader")
	var noise:=FastNoiseLite.new();noise.seed=73;noise.frequency=.035
	var tex:=NoiseTexture2D.new();tex.width=128;tex.height=128;tex.noise=noise;tex.seamless=true;memory.set_shader_parameter("noise_tex",tex)
	var strip:=MeshInstance3D.new();var qm:=QuadMesh.new();qm.size=Vector2(2.0,3.3);strip.mesh=qm;strip.position=Vector3(-7,2.8,-3.85);strip.material_override=memory;add_child(strip)
	G.box(self,Vector3(-7,2.8,-3.95),Vector3(2.25,3.55,.10),brass,true)
	label("LOOKS LIKE MEMORY",Vector3(-7,4.83,-3.8),23)
	label("Moving noise / no touch stored",Vector3(-7,.90,-3.8),19)
	# A real furniture prefab provides a place beside the experiment.
	for z in [-1.5,1.0]:
		var chair=Chair.instantiate();chair.position=Vector3(7,0,z);chair.rotation_degrees.y=90;add_child(chair)
	label("The colour is a reading.\nThe record is elsewhere.",Vector3(7,3.5,-3.95),26)
	G.box(self,Vector3(0,.94,2.65),Vector3(5.6,.12,.75),charcoal,true)
	for x in [-2.5,2.5]:G.box(self,Vector3(x,.44,2.65),Vector3(.15,.88,.5),brass,true)
	for i in range(2):
		var key:String=["FEED","LOSS"][i];var slider=SLIDER.new();slider.param_name=key;slider.continuous=true;slider.position=Vector3(-2.4+i*.43,1.24,2.85);add_child(slider);sliders[key]=slider
		slider.value_changed.connect(func(v:float):set_control(key,v))
	for i in range(5):
		var key:String=["RUN/HOLD","STEP","RESET","CLEAR","INK"][i];var button=BUTTON.instantiate();button.position=Vector3(-1.15+i*.72,1.01,2.58);add_child(button);buttons[key]=button
		button.get_node("InteractableAreaButton").button_pressed.connect(func(_b):act(key))
		var l:=label(key,button.position+Vector3(0,.018,.25),12);l.rotation_degrees.x=-60
	G.box(self,Vector3(.4,1.25,2.3),Vector3(3.8,.36,.04),charcoal)
	readout=label("",Vector3(.4,1.25,2.34),17)
	field=Field.new();field.name="RetainedState";add_child(field);field.changed.connect(_state_changed);_state_changed()
	sliders.FEED.set_normalized_value((field.feed-.02)/.045);sliders.LOSS.set_normalized_value((field.kill-.045)/.025)
	for at in [Vector3(-3,5,2),Vector3(3,5,2),Vector3(0,5,-2)]:
		var lamp:=OmniLight3D.new();lamp.position=at;lamp.omni_range=12;lamp.light_energy=2;lamp.light_color=Color("f2ead6");add_child(lamp)
	set_meta("em_visibility_bounds",AABB(Vector3(-9,0,-6.5),Vector3(18,7.3,13)))

func mark_world(world:Vector3)->void:
	var p:Vector3=touch.to_local(world)
	if p.z<-.03 or p.z>.16:return
	field.mark(Vector2(p.x/5.6+.5,.5-p.y/5.6))

func act(key:String)->void:
	match key:
		"RUN/HOLD":field.running=not field.running
		"STEP":field.step()
		"RESET":field.reset(true)
		"CLEAR":field.reset(false)
		"INK":
			alternate_ink=not alternate_ink
			material.set_shader_parameter("ink",Color("822547") if alternate_ink else Color("143436"))
	_state_changed()

func set_control(key:String,value:float)->void:
	if key=="FEED":field.feed=lerpf(.02,.065,value)
	elif key=="LOSS":field.kill=lerpf(.045,.07,value)
	_state_changed()

func _state_changed()->void:
	material.set_shader_parameter("state_texture",field.state_texture)
	readout.text="%s / %d steps / F %.4f · K %.4f\n96 × 96 cells · opposite edges connect"%["RUNNING" if field.running else "HELD",field.iterations,field.feed,field.kill]

func label(text:String,at:Vector3,size:int)->Label3D:
	var l:=Label3D.new();l.text=text;l.position=at;l.font_size=size*2;l.pixel_size=.002;l.modulate=Color("f2ecde");l.outline_size=0;l.double_sided=false;add_child(l);return l

func apply_grid_config(_config:Dictionary)->void:pass
