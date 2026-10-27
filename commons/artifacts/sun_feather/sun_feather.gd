extends "res://commons/void/lines_area.gd"
## Ten existing prefabs orbit one insertion point. Copy i applies (R*S)^i:
## angle=i*turn, radius=.5*ratio^i, size=.3*ratio^i. Ideal geometry study;
## miniature specimens have no collision. Table and supports remain solid.
const Plank = preload("res://commons/artifacts/primitive_encounters/timber_plank_2m.tscn")
const SourceBarrier = preload("res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.gd")
const PhysicalSlider = preload("res://commons/interactables/physical_stepped_slider.gd")
const Kit = preload("res://commons/artifacts/movable_pivot/mechanism.gd")
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
const Finish = preload("res://commons/artifacts/machine_finish.gd")
const COUNT := 10
const LOW_RATIO := .80
const HIGH_RATIO := 1.04
const TOP := .81
var turn_per_copy := 27.0
var scale_ratio := .92
var source_family := "timber"
var layout_mode := "radial"
var specimens: Array[Node3D] = []
var turn_slider: Node3D
var scale_slider: Node3D
var source_slider: Node3D
var controls: Node3D
var readout: Label3D
var offsets: Dictionary = {}
var loading := false
signal state_changed(state: Dictionary)

func _ready() -> void:
	var table:=Node3D.new();table.name="TemporaryTable";add_child(table)
	for z in [-.61,.61]:
		Kit.box(table,"StandardSheet",Vector3(2.44,.06,1.215),Vector3(0,.77,z),Timber.material(),true)
	Kit.box(table,"DarkDrawingSurface",Vector3(2.24,.008,2.24),Vector3(0,.804,0),Finish.steel())
	for x in [-.84,.84]:
		for z in [-.75,.75]:
			Kit.box(table,"BlockPlinth",Vector3(.46,.74,.46),Vector3(x,.37,z),Finish.ivory(),true)
			for y in [.10,.60]:Kit.box(table,"PackingBand",Vector3(.465,.018,.465),Vector3(x,y,z),Finish.steel())
	# A visible shared insertion point, and the rest radius on the table.
	Kit.cylinder(table,"InsertionPoint",.035,.02,Vector3(0,TOP+.011,0),Finish.pink())
	var ring:=MeshInstance3D.new();ring.name="ReferenceRadius";ring.mesh=TorusMesh.new()
	ring.mesh.inner_radius=.496;ring.mesh.outer_radius=.504;ring.mesh.rings=64;ring.mesh.ring_segments=6
	ring.position.y=TOP+.002;ring.material_override=Finish.ivory();table.add_child(ring)
	for i in COUNT:
		var part:=Node3D.new();part.name="Copy%02d"%(i+1);add_child(part);specimens.append(part)
		var visual:=Node3D.new();visual.name="ScaledPrefab";part.add_child(visual)
		var plank:=Plank.instantiate() as RigidBody3D;plank.name="TimberPlank2m";plank.position.y=.03
		plank.enabled=false;plank.collision_layer=0;plank.collision_mask=0;visual.add_child(plank)
		var barrier:=SourceBarrier.new();barrier.name="BlueDoNotCross";barrier.solid=false;barrier.span_m=2.2;barrier.height_m=1.15;visual.add_child(barrier)
	controls=Node3D.new();controls.name="Controls";add_child(controls)
	Kit.box(controls,"MountingLip",Vector3(1.35,.11,.18),Vector3(0,.77,1.28),Finish.steel(),true)
	turn_slider=make_slider("TurnPerCopy","TURN / COPY",-.42,true,0)
	scale_slider=make_slider("ScalePerCopy","SIZE / COPY",0,true,0)
	source_slider=make_slider("PrefabSource","TIMBER / BLUE",.42,false,0)
	turn_slider.value_changed.connect(func(value):if not loading:set_parameters(value*42,scale_ratio,source_family))
	scale_slider.value_changed.connect(func(value):if not loading:set_parameters(turn_per_copy,lerpf(LOW_RATIO,ratio_high(),value),source_family))
	source_slider.value_changed.connect(func(value):if not loading:set_parameters(turn_per_copy,scale_ratio,"barrier" if value>.5 else "timber"))
	Kit.box(controls,"RulePlate",Vector3(1.35,.085,.012),Vector3(0,1.18,1.31),Finish.ivory())
	readout=Label3D.new();readout.name="CurrentRule";readout.font_size=32;readout.pixel_size=.0017
	readout.modulate=Color("20232a");readout.outline_size=0;readout.position=Vector3(0,1.18,1.319);controls.add_child(readout)
	update_pattern();remember_defaults()

func make_slider(title: String, caption: String, x: float, continuous: bool, value: float) -> Node3D:
	var slider:=PhysicalSlider.new();slider.name=title;slider.param_name=caption;slider.continuous=continuous;slider.step_count=2
	slider.position=Vector3(x,.98,1.29);slider.set_normalized_value(value);controls.add_child(slider)
	slider.get_node("Bezel").material_override=Finish.steel()
	slider.get_node("SliderOrigin/Track/Cap").material_override=Finish.pink()
	return slider

func set_parameters(turn: float, ratio: float, family: String) -> void:
	turn_per_copy=clampf(turn,0,42);scale_ratio=clampf(ratio,LOW_RATIO,ratio_high())
	source_family="barrier" if family=="barrier" else "timber"
	if is_node_ready():update_pattern()
	state_changed.emit({"turn_per_copy":turn_per_copy,"scale_ratio":scale_ratio,"source_family":source_family,"copies":COUNT})

func ratio_high() -> float:
	# A wider circumference has less spare tabletop than the original spiral.
	return 1.02 if layout_mode=="circumference" else HIGH_RATIO

func copy_pose(index: int) -> Transform3D:
	if layout_mode=="packed":
		return Transform3D(Basis.IDENTITY,Vector3(0,TOP,(index-4.5)*.16))
	var basis:=Basis(Vector3.UP,deg_to_rad(turn_per_copy*index))
	var radius := .65 if layout_mode=="circumference" else .5
	return Transform3D(basis,Vector3(0,TOP,0)+basis*Vector3(radius*pow(scale_ratio,index),0,0))

func update_pattern() -> void:
	for i in specimens.size():
		var part: Node3D=specimens[i]
		if not is_instance_valid(part):continue
		part.transform=copy_pose(i)*offsets.get(str(part.name),Transform3D.IDENTITY)
		var visual: Node3D=part.get_node("ScaledPrefab");visual.scale=Vector3.ONE*.30*pow(scale_ratio,i)
		visual.get_node("TimberPlank2m").visible=source_family=="timber"
		visual.get_node("BlueDoNotCross").visible=source_family=="barrier"
		_sync_bodies(part)
	loading=true
	if is_instance_valid(turn_slider):turn_slider.set_normalized_value(turn_per_copy/42)
	if is_instance_valid(scale_slider):scale_slider.set_normalized_value((scale_ratio-LOW_RATIO)/(ratio_high()-LOW_RATIO))
	if is_instance_valid(source_slider):source_slider.set_normalized_value(1 if source_family=="barrier" else 0)
	loading=false
	if is_instance_valid(readout):readout.text="%.0f°   /   %.2f ×   /   %s" % [turn_per_copy,scale_ratio,source_family.to_upper()]

func remember_defaults() -> void:
	for child in get_children():
		if not child is Node3D:continue
		var b:=_mesh_bounds(child,child)
		part_defaults[str(child.name)]={"position":[child.position.x,child.position.y,child.position.z],"rotation":[child.rotation_degrees.x,child.rotation_degrees.y,child.rotation_degrees.z],"bounds":[b.position.x,b.position.y,b.position.z,b.size.x,b.size.y,b.size.z]}

func apply_grid_config(config: Dictionary) -> void:
	layout_mode=str(config.get("layout_mode","radial"))
	set_parameters(float(config.get("turn_per_copy",27)),float(config.get("scale_ratio",.92)),str(config.get("source_family","timber")))
	var table:=get_node_or_null("TemporaryTable")
	if table!=null:
		table.get_node("ReferenceRadius").visible=layout_mode!="packed"
		table.get_node("InsertionPoint").visible=layout_mode!="packed"
		if layout_mode=="circumference":
			var ring: MeshInstance3D=table.get_node("ReferenceRadius")
			ring.mesh.inner_radius=.646;ring.mesh.outer_radius=.654
	if config.get("show_controls",true)==false and is_instance_valid(controls):
		controls.free()
	remember_defaults();offsets.clear()
	# Per-copy editor moves are retained as local adjustments to the recipe.
	for i in specimens.size():
		var part: Node3D=specimens[i];var id:=str(part.name)
		if config.get("parts",{}).has(id):
			var pose: Dictionary=config.parts[id]
			var p: Array=pose.get("position",part_defaults[id].position)
			var r: Array=pose.get("rotation",part_defaults[id].rotation)
			var edited:=Transform3D(Basis.from_euler(Vector3(r[0],r[1],r[2])*PI/180),Vector3(p[0],p[1],p[2]))
			offsets[id]=copy_pose(i).affine_inverse()*edited
	super.apply_grid_config(config)
	update_pattern()

func prepare_editor_preview() -> void:
	for slider in [turn_slider,scale_slider,source_slider]:
		if is_instance_valid(slider):slider.set_process(false)
