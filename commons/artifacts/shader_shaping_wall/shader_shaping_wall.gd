extends Node3D
## One rule on two explicit square receivers. The circle is colour, not a hole.
const G = preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
const SLIDER = preload("res://commons/interactables/physical_stepped_slider.gd")
const BUTTON = preload("res://commons/interactables/push_button.tscn")
var material: ShaderMaterial
var display: MeshInstance3D
var cube_face: MeshInstance3D
var slider: Node3D
var value_label: Label3D
var code_label: Label3D
var mode_label: Label3D
var buttons: Dictionary = {}
var radius := 0.30
var soft := false

func _ready() -> void:
	var chalk := G.material("e5ded0")
	var dark := G.material("252a2c")
	var metal := G.material("6b6760",0.5)
	G.box(self,Vector3(0,2.1,-.12),Vector3(6.8,4.2,.20),chalk,true)
	G.box(self,Vector3(-1.55,2.12,.008),Vector3(3.17,3.17,.075),dark)
	material=ShaderMaterial.new()
	material.shader=preload("res://commons/artifacts/shader_shaping_wall/circle_mask.gdshader")
	display=surface("WallMask",Vector2(3.0,3.0),Vector3(-1.55,2.12,.05))
	label("01 / SHAPING",Vector3(1.8,3.48,.018),32)
	label("A mark on a surface",Vector3(1.8,3.05,.018),25)
	code_label=label("",Vector3(1.8,2.40,.018),20)
	label("Move the radius.\nThe wall stays where it is.",Vector3(1.8,1.56,.018),22)
	label("One rule. Two receivers.",Vector3(1.8,.76,.018),19)
	# A shallow bench leaves the two controls inside ordinary reaching distance.
	G.box(self,Vector3(.05,.97,2.0),Vector3(3.55,.12,.85),chalk,true)
	for x in [-1.4,1.5]:
		G.box(self,Vector3(x,.46,2.0),Vector3(.12,.92,.55),metal,true)
	var cube := G.box(self,Vector3(-1.0,1.39,1.91),Vector3(.72,.72,.72),dark,true)
	cube.name="FamiliarCube"
	# A square receiver on the cube's front avoids hiding BoxMesh's UV atlas.
	cube_face=surface("CubeFace",Vector2(.66,.66),Vector3(-1.0,1.39,2.276))
	label("SAME MASK",Vector3(-1.0,.78,2.44),13)
	G.box(self,Vector3(.53,1.26,1.9),Vector3(.80,.47,.055),dark)
	slider=SLIDER.new();slider.name="RadiusControl";slider.continuous=true;slider.param_name="RADIUS"
	slider.position=Vector3(.30,1.26,1.946);add_child(slider)
	slider.value_changed.connect(func(v:float):set_radius(lerpf(.08,.46,v)))
	value_label=label("",Vector3(.79,1.28,1.95),14)
	value_label.modulate=Color("eee8d9")
	mode_label=label("",Vector3(1.4,1.30,1.94),13)
	for i in range(2):
		var key:String=["EDGE","RESET"][i]
		var b:Node3D=BUTTON.instantiate();b.name=key;b.position=Vector3(1.05+float(i)*.46,1.04,2.12);add_child(b)
		b.get_node("InteractableAreaButton").button_pressed.connect(func(_b):act(key))
		buttons[key]=b
		var text:=label(key,b.position+Vector3(0,.015,.19),12);text.rotation_degrees.x=-60
	# Museum-scale lighting is mounted on the installation, not a new environment.
	for x in [-2.5,2.5]:
		var light:=OmniLight3D.new();light.position=Vector3(x,3.7,1.2);light.omni_range=7;light.light_energy=1.1;light.light_color=Color("ffe9cd");add_child(light)
	set_meta("em_visibility_bounds",AABB(Vector3(-3.4,0,-.22),Vector3(6.8,4.2,3.3)))
	update_rule()

func surface(title:String,size:Vector2,at:Vector3) -> MeshInstance3D:
	var n:=MeshInstance3D.new();n.name=title
	var q:=QuadMesh.new();q.size=size;n.mesh=q;n.material_override=material;n.position=at;add_child(n)
	return n

func label(text:String,at:Vector3,points:int) -> Label3D:
	var l:=Label3D.new();l.text=text;l.position=at;l.font_size=points*2;l.pixel_size=.002
	l.modulate=Color("24282a");l.outline_size=0;l.no_depth_test=false;add_child(l)
	return l

func set_radius(value:float) -> void:
	radius=clampf(value,.08,.46)
	update_rule()

func act(key:String) -> void:
	if key=="EDGE":soft=not soft
	elif key=="RESET":radius=.30;soft=false
	update_rule()

func update_rule() -> void:
	if material==null:return
	material.set_shader_parameter("radius",radius)
	material.set_shader_parameter("softness",.045 if soft else 0.0)
	slider.set_normalized_value(inverse_lerp(.08,.46,radius))
	value_label.text="%.2f"%radius
	mode_label.text="SOFT" if soft else "HARD"
	code_label.text="d = distance(UV, centre)\n\n1 - smoothstep(r - s, r + s, d)" if soft else "d = distance(UV, centre)\n\n1 - step(radius, d)"

func apply_grid_config(_config:Dictionary) -> void:
	pass
