extends Node3D
## Fixed bodies, fixed lights: alter the surface response, then walk around it.
const G = preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
const SLIDER = preload("res://commons/interactables/physical_stepped_slider.gd")
const BUTTON = preload("res://commons/interactables/push_button.tscn")
const SOFA = preload("res://commons/primitives/sofa/sofa.tscn")
const CHAIR = preload("res://commons/primitives/chair/chair_modern.tscn")
const VASE = preload("res://commons/primitives/design_classics/aalto_vase.tscn")
const SHADERS = [preload("./rim_study.gdshader"),
	preload("res://algorithms/shaders/queer_materials/pop_plastic.gdshader"),
	preload("res://algorithms/shaders/queer_materials/fur_velvet.gdshader"),
	preload("res://algorithms/shaders/queer_collection_2/oil_slick_latex.gdshader")]
const NAMES = ["STUDY", "PLASTIC", "VELVET", "OIL"]
const ROUGHNESS = [.28, .05, .82, .15]
var materials: Array[ShaderMaterial] = []
var receivers: Array[MeshInstance3D] = []
var sphere: MeshInstance3D
var cube: MeshInstance3D
var sofa: MeshInstance3D
var chair: Node3D
var vase: Node3D
var sliders: Dictionary = {}
var buttons: Dictionary = {}
var readout: Label3D
var rim_note: Label3D
var mode := 0
var roughness := .28
var rim_amount := .8

func _ready() -> void:
	for shader in SHADERS:
		var mat := ShaderMaterial.new(); mat.shader = shader; materials.append(mat)
	var ivory := G.material("d9d4c6"); var coal := G.material("25252e"); var rose := G.material("ae8e97"); var brass := G.material("a19771", .7)
	G.box(self,Vector3(0,.02,0),Vector3(14,.03,11),coal)
	G.box(self,Vector3(0,2.4,-5.45),Vector3(14,4.8,.12),rose,true)
	for side in [-1.0,1.0]:
		G.box(self,Vector3(side*7,2.4,-1),Vector3(.12,4.8,8.8),ivory,true)
		for z in [-4.8,-.3,4.5]:
			G.box(self,Vector3(side*6.65,2.5,z),Vector3(.18,5,.24),brass,true)
	for z in [-4.8,-.3,4.5]: G.box(self,Vector3(0,4.93,z),Vector3(13.5,.15,.24),brass)
	# Pale wall panels and a restrained floor border give the materials a stable surround.
	for x in [-4.5,0.0,4.5]:
		G.box(self,Vector3(x,2.6,-5.36),Vector3(3.9,3.65,.04),ivory)
	for x in [-5.7,5.7]: G.box(self,Vector3(x,.04,-.2),Vector3(.045,.01,9.4),brass)
	label("03 / A BODY ACQUIRES A SURFACE",Vector3(0,4.35,-5.30),54).modulate=Color("24252e")
	label("Keep the body. Change what it returns to the eye.",Vector3(0,3.82,-5.29),28).modulate=Color("24252e")
	# The existing sofa scene includes a demonstration camera; remove it before tree entry.
	sofa = SOFA.instantiate(); sofa.name = "ExistingSofa"
	for cam in sofa.find_children("*","Camera3D",true,false): cam.free()
	# Its source cross-section is in XZ, extruded along Y. Stand that section up.
	sofa.position=Vector3(-3.6,.9,-2.5)
	sofa.basis=Basis(Vector3(0,0,1),Vector3(1,0,0),Vector3(0,1,0)).scaled_local(Vector3(1.8,3.5,1.8))
	add_child(sofa); receivers.append(sofa)
	box_collision(sofa,Vector3.ZERO,Vector3(1,1,1))
	chair=CHAIR.instantiate(); chair.name="ExistingChair"; chair.position=Vector3(3.3,0,-1.7); chair.rotation.y=PI; chair.scale=Vector3.ONE*2.0; add_child(chair)
	for mesh in chair.find_children("*","MeshInstance3D",true,false): receivers.append(mesh)
	G.box(self,Vector3(0,.68,-2.0),Vector3(1.55,.14,1.35),ivory,true)
	G.box(self,Vector3(0,.32,-2.0),Vector3(.32,.64,.32),brass,true)
	vase=VASE.instantiate(); vase.name="ExistingVase"; vase.position=Vector3(0,.75,-2); add_child(vase)
	for mesh in vase.find_children("*","MeshInstance3D",true,false):
		if not mesh.is_queued_for_deletion(): receivers.append(mesh)
	# The primary comparison is deliberately still: one material on curved and flat normals.
	for x in [-1.65,.45]:
		G.box(self,Vector3(x,.50,1.2),Vector3(1.4,1,1.4),ivory,true)
	sphere=MeshInstance3D.new(); sphere.name="CarriedSphere"; var ball:=SphereMesh.new(); ball.radius=.58; ball.height=1.16; ball.radial_segments=64; ball.rings=32
	sphere.mesh=ball; sphere.position=Vector3(-1.65,1.58,1.2); add_child(sphere); receivers.append(sphere)
	var sphere_body:=StaticBody3D.new(); var sphere_col:=CollisionShape3D.new(); var sphere_shape:=SphereShape3D.new(); sphere_shape.radius=.58; sphere_col.shape=sphere_shape; sphere_body.add_child(sphere_col); sphere.add_child(sphere_body)
	cube=G.box(self,Vector3(.45,1.47,1.2),Vector3(.94,.94,.94),ivory,true); cube.name="CarriedCube"; receivers.append(cube)
	label("CURVED NORMALS",Vector3(-1.65,.80,1.915),17).modulate=Color("24252e")
	label("FLAT NORMALS",Vector3(.45,.80,1.915),17).modulate=Color("24252e")
	# One reachable console; roughness is shared, the rim control belongs to the small study.
	G.box(self,Vector3(-3.4,1.0,4.18),Vector3(4.3,.12,.68),ivory,true)
	for x in [-5.25,-1.55]: G.box(self,Vector3(x,.48,4.18),Vector3(.12,.96,.4),brass,true)
	for i in range(2):
		var key: String=["ROUGH","RIM"][i]; var slider=SLIDER.new(); slider.name=key; slider.continuous=true; slider.param_name=key; slider.position=Vector3(-4.8+i*.5,1.3,4.40); add_child(slider); sliders[key]=slider
		slider.value_changed.connect(func(v:float): set_control(key,v))
	for i in range(5):
		var key: String=["STUDY","PLASTIC","VELVET","OIL","RESET"][i]; var button=BUTTON.instantiate(); button.name=key; button.position=Vector3(-3.75+i*.53,1.07,4.17); add_child(button)
		button.get_node("InteractableAreaButton").button_pressed.connect(func(_b): act(key)); buttons[key]=button
		var text:=label(key,button.position+Vector3(0,.018,.22),12); text.rotation_degrees.x=-60; text.modulate=Color("24252e"); text.outline_size=0
	G.box(self,Vector3(-3.4,1.57,3.94),Vector3(4.2,.65,.04),coal)
	readout=label("",Vector3(-3.4,1.39,4.0),20)
	rim_note=label("",Vector3(-3.4,1.72,4.0),16)
	label("Same meshes.\nSame lights.\nWalk around them.",Vector3(4.5,2.6,-5.29),26).modulate=Color("24252e")
	# Existing collection lights remain in the adjoining hall. These local lights stay fixed.
	for pos in [Vector3(-4,4,3),Vector3(4,4,3),Vector3(0,4,-3)]:
		var light:=OmniLight3D.new(); light.position=pos; light.omni_range=8; light.light_energy=2.4; light.light_color=Color("fcebd8"); add_child(light)
	var fill:=OmniLight3D.new(); fill.position=Vector3(-3.4,2.5,5.6); fill.omni_range=3.5; fill.light_energy=2.0; add_child(fill)
	set_meta("em_visibility_bounds",AABB(Vector3(-7.2,0,-5.6),Vector3(14.4,5.1,11.4)))
	update_material()

func box_collision(parent: Node3D, at: Vector3, size: Vector3) -> void:
	var body:=StaticBody3D.new(); var shape:=CollisionShape3D.new(); var box:=BoxShape3D.new(); box.size=size; shape.shape=box; shape.position=at; body.add_child(shape); parent.add_child(body)

func label(text:String,at:Vector3,points:int)->Label3D:
	var l:=Label3D.new(); l.text=text; l.position=at; l.font_size=points*2; l.pixel_size=.002; l.modulate=Color("eee5d4"); l.no_depth_test=false; l.shaded=false; l.outline_size=0; l.double_sided=false; add_child(l); return l

func act(key:String)->void:
	if key=="RESET": mode=0; roughness=.28; rim_amount=.8
	elif key in NAMES: mode=NAMES.find(key); roughness=ROUGHNESS[mode]
	update_material()

func set_control(key:String,value:float)->void:
	if key=="ROUGH": roughness=lerpf(.05,.95,clampf(value,0,1))
	elif key=="RIM" and mode==0: rim_amount=clampf(value,0,1)*1.5
	update_material()

func update_material()->void:
	if materials.is_empty() or readout==null:return
	materials[mode].set_shader_parameter("roughness",roughness)
	materials[0].set_shader_parameter("rim_amount",rim_amount)
	for mesh in receivers: mesh.material_override=materials[mode]
	sliders.ROUGH.set_normalized_value(inverse_lerp(.05,.95,roughness)); sliders.RIM.set_normalized_value(rim_amount/1.5)
	sliders.RIM.input_enabled=mode==0; sliders.RIM._handle.enabled=mode==0
	readout.text="%s  |  roughness %.2f"%[NAMES[mode],roughness]
	rim_note.text="edge = pow(1 - dot(normal, view), 3)\nrim amount %.2f"%rim_amount if mode==0 else "RIM is held. Choose STUDY to edit its edge."

func apply_grid_config(_config:Dictionary)->void: pass
