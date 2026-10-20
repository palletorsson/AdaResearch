extends Node3D
## An exploded view of recorded picks, not another random pattern generator.
const G = preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
const Fabric = preload("res://commons/artifacts/jacquard_weaver/weave_fabric.gd")
signal sample_requested
const BUTTON = preload("res://commons/interactables/push_button.tscn")
var records: Array = []
var gap := 0.0
var fabric_mesh: MeshInstance3D
var fabric_material: ShaderMaterial
var sample_button: Node3D
var yarn: Node3D
var caption: Label3D
var slider: XRToolsInteractableSlider
var handle: XRToolsInteractableHandle
var warp_paths: Array = []
var weft_path := PackedVector3Array()
var drawdown_mesh: MeshInstance3D
var warp_mat = G.material("f3e6c8")
var weft_mat = G.material("e84b7e")

func _ready() -> void:
	yarn=Node3D.new(); add_child(yarn)
	var dark = G.material("302f35",.4)
	G.box(self,Vector3(0,.84,.15),Vector3(2.92,.09,3.65),dark,true)
	for x in [-1.35,1.35]:
		for z in [-1.54,1.79]: G.box(self,Vector3(x,.4,z),Vector3(.065,.8,.065),dark,true)
	G.label(self,"CLOTH OPENS INTO CROSSINGS",Vector3(0,2.99,0),23)
	G.label(self,"96 WARP THREADS · 12-HOOK PATTERN × 8 · RECORDED PICKS",Vector3(0,2.87,0),12)
	caption=G.label(self,"",Vector3(0,.69,2.01),13)
	G.box(self,Vector3(0,1.05,2.02),Vector3(1.3,.025,.025),G.material("b79361",.6))
	var origin := Node3D.new(); origin.position=Vector3(-.6,1.05,2.02)
	slider=XRToolsInteractableSlider.new(); slider.slider_limit_max=1.2; slider.slider_position=gap/.075*1.2
	var handle_origin := Node3D.new(); handle=XRToolsInteractableHandle.new()
	handle.freeze=true; handle.collision_layer=4; handle.collision_mask=0; handle.snap_distance=.5
	var shape := CollisionShape3D.new(); var b := BoxShape3D.new(); b.size=Vector3(.11,.11,.11); shape.shape=b
	handle.add_child(shape); G.box(handle,Vector3.ZERO,b.size,weft_mat)
	handle_origin.add_child(handle); slider.add_child(handle_origin); origin.add_child(slider); add_child(origin)
	slider.slider_moved.connect(func(p):set_gap(float(p)/1.2*.075))
	_button("FLAT",Vector3(-.78,1.03,2.02),func():slider.move_slider(0.0))
	_button("LAYERS",Vector3(.78,1.03,2.02),func():slider.move_slider(1.0))
	sample_button=_button("WEAVE\n96 PICKS",Vector3(1.18,1.03,2.02),func():sample_requested.emit())
	redraw()

func _button(title: String, p: Vector3, callback: Callable) -> Node3D:
	var b=BUTTON.instantiate(); b.position=p; b.rotation_degrees.x=90; b.scale=Vector3.ONE*.6; add_child(b)
	b.get_node("InteractableAreaButton").button_pressed.connect(func(_b):callback.call())
	G.label(self,title,p+Vector3(0,.09,.045),13)
	return b

func set_history(history: Array) -> void:
	records=history.duplicate(true)
	if is_instance_valid(yarn): redraw()

func set_gap(amount: float) -> void:
	gap=clampf(amount,0.0,.075)
	_update_opening()

func _update_opening() -> void:
	var amount:=gap/.075
	if is_instance_valid(fabric_material):fabric_material.set_shader_parameter("opening",amount)
	if is_instance_valid(drawdown_mesh):drawdown_mesh.visible=amount>.10
	caption.text="96 WARP × %d RECORDED PICKS · %s\nCOLOURS + LIFTS REPEAT ACROSS WIDTH / EACH ROW WAS WOVEN" % [records.size(),"CLOTH" if amount<.01 else "OPEN %.0f%%" % (amount*100)]
	if records.is_empty():caption.text="WEAVE ONE PICK OR 96 PICKS\nPULL THE SLIDER TO OPEN THE CLOTH"

func redraw() -> void:
	G.clear(yarn);warp_paths.clear();weft_path.clear();drawdown_mesh=null;fabric_mesh=null
	if records.is_empty():_update_opening();return
	var result:Dictionary=Fabric.build(records)
	warp_paths=result.warps;weft_path=result.weft
	fabric_material=Fabric.material();fabric_material.set_shader_parameter("pick_count",float(records.size()))
	fabric_mesh=MeshInstance3D.new();fabric_mesh.mesh=result.mesh;fabric_mesh.material_override=fabric_material
	# The shader opens above the original mesh bounds; keep it visible from every side.
	fabric_mesh.custom_aabb=AABB(Vector3(-1.45,.85,-1.4),Vector3(2.9,2.4,3.4))
	yarn.add_child(fabric_mesh)
	drawdown_mesh=G.drawdown(yarn,records,8,.025,-1.30)
	_update_opening()
