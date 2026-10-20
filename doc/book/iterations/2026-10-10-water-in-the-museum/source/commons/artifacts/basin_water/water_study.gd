extends Node3D
## Opt-in museum setting for BasinWater: one field, three visual operations.
## The glass bridge has collision. The rendered water has none.
const G = preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
const SLIDER = preload("res://commons/interactables/physical_stepped_slider.gd")
const BUTTON = preload("res://commons/interactables/push_button.tscn")
const CHAIR = preload("res://commons/primitives/chair/chair_modern.tscn")
const MODES = ["COLOUR", "NORMAL", "HEIGHT"]
var surface: MeshInstance3D
var material: ShaderMaterial
var bridge: MeshInstance3D
var sliders: Dictionary = {}
var buttons: Dictionary = {}
var readout: Label3D
var mode := 2
var octaves := 3
var relief := .22
var phase := 0.0
var playing := false

func _ready() -> void:
	name = "WaterStudy"
	var plane := PlaneMesh.new(); plane.size = Vector2(11,11); plane.subdivide_width = 96; plane.subdivide_depth = 96
	surface.mesh = plane; surface.position = Vector3(0,-.40,-8)
	surface.custom_aabb = AABB(Vector3(-5.5,-.25,-5.5),Vector3(11,.5,11))
	material = ShaderMaterial.new(); material.shader = preload("./layered_water.gdshader"); surface.material_override = material
	var stone := G.material("d5d2bd"); var teal := G.material("26434a"); var brass := G.material("a29874",.65)
	var glass := G.material("afdfdf",.15); glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; glass.albedo_color.a = .13; glass.roughness = .1
	bridge = G.box(self,Vector3(0,-.03,-8),Vector3(1.8,.06,11.2),glass,true); bridge.name = "GlassBridge"
	# Brass edges and flush crossbars make the actual support legible.
	for x in [-.91,.91]:
		G.box(self,Vector3(x,-.035,-8),Vector3(.035,.07,11.3),brass,true)
		for z in [-2.65,-5.3,-8,-10.7,-13.35]:
			G.box(self,Vector3(x,.5,z),Vector3(.035,1,.035),brass,true)
		G.box(self,Vector3(x,1,-8),Vector3(.045,.045,10.7),brass,true)
	for z in [-2.5,-5.25,-8,-10.75,-13.5]: G.box(self,Vector3(0,-.028,z),Vector3(1.8,.04,.025),brass)
	# Rim and balustrade keep the deep basin beside the walking route.
	for x in [-5.58,5.58]:
		G.box(self,Vector3(x,.02,-8),Vector3(.16,.12,11.35),stone,true)
		G.box(self,Vector3(x,.55,-8),Vector3(.025,1.0,11.2),glass,true)
		G.box(self,Vector3(x,1.07,-8),Vector3(.04,.04,11.2),brass,true)
	for z in [-2.42,-13.58]:
		for x in [-3.3,3.3]:
			G.box(self,Vector3(x,.02,z),Vector3(4.7,.12,.16),stone,true)
			G.box(self,Vector3(x,.55,z),Vector3(4.65,1.0,.025),glass,true)
			G.box(self,Vector3(x,1.07,z),Vector3(4.65,.04,.04),brass,true)
	# A bathhouse colonnade, open overhead; the museum still supplies its sky.
	for x in [-7.2,7.2]:
		for z in [-2.7,-8,-13.3]:
			var col := MeshInstance3D.new(); var cylinder := CylinderMesh.new(); cylinder.top_radius=.19; cylinder.bottom_radius=.24; cylinder.height=4.6; cylinder.radial_segments=24
			col.mesh=cylinder; col.material_override=stone; col.position=Vector3(x,2.3,z); add_child(col)
			G.box(self,Vector3(x,2.3,z),Vector3(.42,4.6,.42),stone,true).visible=false
			G.box(self,Vector3(x,.09,z),Vector3(.65,.18,.65),stone,true)
		G.box(self,Vector3(x,4.6,-8),Vector3(.45,.23,12),stone)
	for z in [-2.7,-13.3]: G.box(self,Vector3(0,4.65,z),Vector3(14.8,.16,.22),brass)
	G.box(self,Vector3(0,2.8,-21.3),Vector3(19,5.6,.18),teal,true)
	label("04 / WHAT CARRIES YOU?",Vector3(0,4.7,-21.15),60)
	label("One field. Several scales. Three ways to see it.",Vector3(0,4.05,-21.15),29)
	label("←  NEXT HALL",Vector3(-8,2.2,-21.15),32)
	label("Glass carries you.\nThe water has no collider.",Vector3(0,1.65,-15),26)
	# The sphere and cube return as rigid witnesses. They do not bob with the shader.
	for x in [-3.2,3.2]: G.box(self,Vector3(x,.5,-.7),Vector3(1.2,1,1.2),stone,true)
	var ball := MeshInstance3D.new(); var sphere := SphereMesh.new(); sphere.radius=.45; sphere.height=.9; ball.mesh=sphere; ball.position=Vector3(-3.2,1.45,-.7); ball.material_override=teal; add_child(ball)
	G.box(self,Vector3(3.2,1.4,-.7),Vector3(.8,.8,.8),teal,true)
	for x in [-8.5,8.5]:
		var chair := CHAIR.instantiate(); chair.position=Vector3(x,0,-9.5); chair.rotation.y=PI*.5*signf(x); chair.scale=Vector3.ONE*1.8; add_child(chair)
	# A single low bench beside the bridge entrance, within arm's reach.
	G.box(self,Vector3(-3.3,.95,1.2),Vector3(4.4,.12,.7),stone,true)
	for x in [-5.2,-1.4]: G.box(self,Vector3(x,.45,1.2),Vector3(.13,.9,.45),brass,true)
	for i in range(2):
		var key: String=["SCALES","RELIEF"][i]; var slider=SLIDER.new(); slider.param_name=key; slider.continuous=i==1; slider.step_count=4; slider.position=Vector3(-5+i*.42,1.26,1.40); add_child(slider); sliders[key]=slider
		slider.value_changed.connect(func(v:float):set_control(key,v))
	for i in range(5):
		var key: String=["COLOUR","NORMAL","HEIGHT","TIME","RESET"][i]; var button=BUTTON.instantiate(); button.position=Vector3(-3.95+i*.53,1.02,1.16); add_child(button); buttons[key]=button
		button.get_node("InteractableAreaButton").button_pressed.connect(func(_b):act(key))
		var caption:=label(key,button.position+Vector3(0,.015,.23),12); caption.modulate=Color("183237"); caption.rotation_degrees.x=-60
	G.box(self,Vector3(-2.6,1.27,.90),Vector3(2.75,.40,.05),teal)
	readout=label("",Vector3(-2.6,1.27,.94),18)
	label("Add finer noise at half the weight.",Vector3(-3.3,.80,1.57),19).modulate=Color("1c363c")
	for pos in [Vector3(-4,3.6,1),Vector3(4,3.6,-10),Vector3(0,4,-19)]:
		var light:=OmniLight3D.new(); light.position=pos; light.omni_range=11; light.light_energy=3; light.light_color=Color("f3ead3"); add_child(light)
	get_parent().set_meta("em_visibility_bounds",AABB(Vector3(-10,-1.2,-21.5),Vector3(20,7,24)))
	update_surface()

func label(text:String,at:Vector3,size:int)->Label3D:
	var l:=Label3D.new(); l.text=text; l.position=at; l.font_size=size*2; l.pixel_size=.002; l.modulate=Color("f0eadb"); l.outline_size=0; l.double_sided=false; add_child(l); return l

func _process(delta:float)->void:
	if playing:
		phase=fposmod(phase+delta*.24,TAU)
		material.set_shader_parameter("phase",phase)

func act(key:String)->void:
	if key=="RESET": mode=2; octaves=3; relief=.22; phase=0; playing=false
	elif key=="TIME": playing=not playing
	elif key in MODES: mode=MODES.find(key)
	update_surface()

func set_control(key:String,value:float)->void:
	if key=="SCALES": octaves=clampi(roundi(1+3*value),1,4)
	elif key=="RELIEF": relief=clampf(value,0,1)*.25
	update_surface()

func update_surface()->void:
	material.set_shader_parameter("mode",mode); material.set_shader_parameter("octaves",octaves); material.set_shader_parameter("relief",relief); material.set_shader_parameter("phase",phase)
	sliders.SCALES.set_normalized_value(float(octaves-1)/3); sliders.RELIEF.set_normalized_value(relief/.25)
	readout.text="%s  |  %d scales  |  %.2f m\n%s"%[MODES[mode],octaves,relief,"Moving — TIME holds it" if playing else "Held — TIME moves it"]
