extends Node3D
## A spatial interpretation after Vera Molnar's (Des)Ordres (1974), not a reconstruction.
## Fixed indexed sites; repeatable local departures; no random resampling during interaction.
signal state_changed(state: Dictionary)
const SLIDER = preload("res://commons/interactables/slider_horizontal.tscn")
const COUNT := 4
const SHELLS := 4
const STEP := 0.56
const EDGE := 0.44
const CENTRE := Vector3(0,1.85,0)
const NEST := [1.0,0.76,0.52,0.28]
var amount := Vector3(0.22,0.32,0.18)
var target_amount := amount
var depth_layers := 4
var cells: Array[Dictionary] = []
var sliders: Array[Node3D] = []
var buttons: Array[Node3D] = []
var frames: MultiMeshInstance3D
var sites: MultiMeshInstance3D
var glass: Array[MeshInstance3D] = []
var layer_label: Label3D
var count_label: Label3D
var _built := false

func _ready() -> void:
	_build_data()
	_build_display()
	_build_controls()
	_built=true
	_refresh()
	set_process(false)

func _build_data() -> void:
	for z in COUNT:
		for y in COUNT:
			for x in COUNT:
				var home:=CENTRE+Vector3(x-1.5,y-1.5,1.5-z)*STEP
				var rng:=RandomNumberGenerator.new()
				rng.seed=74000+x*997+y*7919+z*65537
				var departures:Array[Dictionary]=[]
				for shell in SHELLS:
					departures.append({"offset":Vector3(rng.randf_range(-0.07,0.07),rng.randf_range(-0.07,0.07),rng.randf_range(-0.07,0.07)),"angles":Vector3(rng.randf_range(-24,24),rng.randf_range(-24,24),rng.randf_range(-24,24))*(PI/180.0),"scale_delta":rng.randf_range(-0.25,0.25)})
				cells.append({"address":Vector3i(x,y,z),"home":home,"departures":departures})

func frame_pose(index: int, shell: int) -> Transform3D:
	var cell:Dictionary=cells[index]
	var decision:Dictionary=cell.departures[shell]
	var size:float=EDGE*NEST[shell]*(1.0+amount.z*decision.scale_delta)
	var turn:=Basis.from_euler(decision.angles*amount.y)
	return Transform3D(turn.scaled(Vector3.ONE*size),cell.home+decision.offset*amount.x)

func set_operation(axis: int, value: float) -> void:
	if axis<0 or axis>2:return
	target_amount[axis]=clampf(value,0.0,1.0)
	set_process(true)

func _process(delta: float) -> void:
	amount=amount.move_toward(target_amount,delta*2.2)
	_refresh()
	if amount.is_equal_approx(target_amount):
		amount=target_amount
		set_process(false)

func set_layers(value: int) -> void:
	depth_layers=clampi(value,1,COUNT)
	if _built:_refresh()

func cycle_layers() -> void:
	set_layers(1 if depth_layers==4 else depth_layers+1)

func reset_order() -> void:
	target_amount=Vector3.ZERO
	for slider in sliders:slider.set_normalized_value(0.0)
	set_process(true)

func _refresh() -> void:
	var visible_cells:=COUNT*COUNT*depth_layers
	frames.multimesh.visible_instance_count=visible_cells*SHELLS
	sites.multimesh.visible_instance_count=visible_cells
	for i in cells.size():
		for shell in SHELLS:frames.multimesh.set_instance_transform(i*SHELLS+shell,frame_pose(i,shell))
		glass[i].transform=frame_pose(i,0)
		glass[i].visible=i<visible_cells
	count_label.text="%d SITES  /  %d NESTED CUBES" % [visible_cells,visible_cells*SHELLS]
	layer_label.text="DEPTH  %d / 4" % depth_layers
	state_changed.emit({"translation":amount.x,"rotation":amount.y,"scale":amount.z,"layers":depth_layers,"sites":visible_cells,"frames":visible_cells*SHELLS})

func _material(c: Color, flat:=false) -> StandardMaterial3D:
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=c;mat.roughness=0.65
	if flat:mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func _box(title:String,size:Vector3,at:Vector3,mat:Material,solid:=false) -> MeshInstance3D:
	var n:=MeshInstance3D.new();n.name=title;n.position=at
	var mesh:=BoxMesh.new();mesh.size=size;n.mesh=mesh;n.material_override=mat;add_child(n)
	if solid:
		var body:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=size
		shape.shape=box;body.add_child(shape);n.add_child(body)
	return n

func _label(words:String,at:Vector3,pixels:int=26) -> Label3D:
	var n:=Label3D.new();n.text=words;n.position=at;n.font_size=pixels;n.pixel_size=0.0015
	n.modulate=Color(0.1,0.1,0.1);n.outline_size=0;n.no_depth_test=false;add_child(n)
	return n

func _frame_mesh() -> ArrayMesh:
	# One shared mesh (12 narrow bars), instanced once per nested cube.
	var unit:=BoxMesh.new();var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in 3:
		for a in [-0.5,0.5]:
			for b in [-0.5,0.5]:
				var at:=Vector3.ZERO;var size:=Vector3.ONE*0.008
				size[axis]=1.008;at[(axis+1)%3]=a;at[(axis+2)%3]=b
				st.append_from(unit,0,Transform3D(Basis.from_scale(size),at))
	return st.commit()

func _batch(title:String,mesh:Mesh,mat:Material,count:int) -> MultiMeshInstance3D:
	var n:=MultiMeshInstance3D.new();n.name=title
	var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh;mm.instance_count=count
	n.multimesh=mm;n.material_override=mat;n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(n)
	return n

func _build_display() -> void:
	var paper:=_material(Color(0.88,0.87,0.83))
	var ink:=_material(Color(0.075,0.08,0.085),true)
	_box("GalleryFloor",Vector3(6.0,0.03,6.0),Vector3(0,0.015,0),_material(Color(0.23,0.24,0.25)),true)
	_box("LowPlinth",Vector3(3.0,0.40,3.0),Vector3(0,0.20,0),paper,true)
	_box("FloatingLip",Vector3(3.06,0.025,3.06),Vector3(0,0.405,0),ink)
	frames=_batch("NestedCubeFrames",_frame_mesh(),_material(Color(0.84,0.86,0.86),true),COUNT*COUNT*COUNT*SHELLS)
	var dot:=SphereMesh.new();dot.radius=0.009;dot.height=0.018;dot.radial_segments=8;dot.rings=4
	sites=_batch("FixedSites",dot,_material(Color(0.35,0.35,0.35),true),cells.size())
	var clear:=_material(Color(0.83,0.87,0.89,0.035))
	clear.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;clear.roughness=0.12;clear.metallic=0.08
	var unit:=BoxMesh.new()
	for i in cells.size():
		sites.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,cells[i].home))
		var pane:=MeshInstance3D.new();pane.name="ClearCell_%d" % i;pane.mesh=unit;pane.material_override=clear
		pane.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(pane);glass.append(pane)
	_label("AFTER VERA MOLNAR  /  (DES)ORDRES, 1974",Vector3(0,0.26,1.505),24)
	_label("A SPATIAL STUDY BY ADA RESEARCH",Vector3(0,0.19,1.505),19)

func _build_controls() -> void:
	var existing:=get_children()
	var paper:=_material(Color(0.89,0.88,0.85));var graphite:=_material(Color(0.14,0.15,0.16))
	_box("ControlFoot",Vector3(0.72,0.04,0.48),Vector3(0,0.02,1.87),graphite,true)
	_box("ControlStem",Vector3(0.09,0.97,0.09),Vector3(0,0.505,1.80),graphite,true)
	_box("SmallRail",Vector3(1.12,0.66,0.05),Vector3(0,1.10,1.88),paper,true)
	count_label=_label("",Vector3(0,1.385,1.913),19)
	var names:=["TRANSLATE","ROTATE","SCALE"]
	for i in 3:
		var slider:Node3D=SLIDER.instantiate();slider.name=names[i];slider.position=Vector3(-0.19,1.25-i*0.145,1.93);slider.scale=Vector3.ONE*1.65
		add_child(slider);slider.set_param_name(names[i]);slider.set_range(0,1);slider.set_normalized_value(amount[i])
		slider.slider_moved.connect(func(_value):set_operation(i,slider.get_normalized_value()))
		for part in slider.find_children("*","MeshInstance3D",true,false):
			if part.name=="AccentMesh":part.set_surface_override_material(0,_material(Color(0.22,0.22,0.22)))
		sliders.append(slider)
	var actions:Array[Callable]=[cycle_layers,reset_order]
	for i in 2:
		var button:Node3D=load("res://commons/interactables/push_button.tscn").instantiate()
		button.name="LayersButton" if i==0 else "ResetButton";button.position=Vector3(0.33,1.22-i*0.22,1.975)
		button.rotation_degrees=Vector3(90,0,0);button.scale=Vector3.ONE*1.2
		button.released_color=Color(0.35,0.35,0.35);button.pressed_color=Color.WHITE
		add_child(button);button.pressed.connect(actions[i]);buttons.append(button)
	layer_label=_label("",Vector3(0.33,1.30,1.935),17)
	_label("RESET",Vector3(0.33,1.08,1.935),17)
	_label("WALK AROUND. KEEP AN ADDRESS IN MIND.",Vector3(0,0.83,1.915),17)
	var rig:=Node3D.new();rig.name="ControlRig";add_child(rig)
	for child in get_children():
		if child!=rig and child not in existing:child.reparent(rig)
