extends Node3D
## Read spatial Z by walking between the existing matched volumes.
## This changes only the receiver. The model, clock, forcing and floor stay intact.
const FIRST_Z := 0.25
const PITCH := 0.27
const DEAD_BAND := 0.025
var study: Node3D
var visitors: Dictionary = {}
var frames: Array[Node3D] = []
var floor_mark: Node3D
var words: Label3D
var last_body: int = 0
var last_band: int = -1

func _ready() -> void:
	study = get_parent()
	for side in range(2):
		var frame := Node3D.new()
		frame.name = "SliceFrame_%d" % side
		frame.position = Vector3(2.8 if side == 0 else -2.8, 1.85, 0)
		add_child(frame)
		frames.append(frame)
		for sign_ in [-1, 1]:
			bar(frame,Vector3(.024,2.84,.024),Vector3(sign_*1.42,0,0))
			bar(frame,Vector3(2.84,.024,.024),Vector3(0,sign_*1.42,0))
	floor_mark = Node3D.new();floor_mark.name = "SelectedSliceAtEdges";add_child(floor_mark)
	for side in [-1,1]:bar(floor_mark,Vector3(.12,.008,.035),Vector3(side*1.045,.039,0))
	for side in [-1,1]:
		bar(self,Vector3(.016,.006,3.1),Vector3(side*1.045,.03,1.6))
	for z in range(study.Model.N):
		var label_: Label3D = study.label("SliceAddress_%d"%z,str(z),34)
		label_.pixel_size=.002;label_.position=Vector3(-1.14,.038,FIRST_Z+PITCH*z)
		label_.rotation_degrees=Vector3(-90,180,0);add_child(label_)
	words = study.label("WalkToRead","WALK BETWEEN THE VOLUMES
YOUR POSITION SELECTS Z",34)
	words.position=Vector3(0,.032,-.3);words.rotation_degrees=Vector3(-90,180,0);add_child(words)
	var area := Area3D.new();area.name="BodyReader";area.collision_layer=0;area.collision_mask=0xFFFFFFFF
	var shape:=CollisionShape3D.new();var bounds:=BoxShape3D.new();bounds.size=Vector3(1.84,2.4,3.3)
	shape.shape=bounds;shape.position=Vector3(0,1.2,1.6);area.add_child(shape)
	area.body_entered.connect(_entered);area.body_exited.connect(_exited);add_child(area)
	refresh()

func accepts(body:Node3D) -> bool:
	return body is XRToolsPlayerBody or (body is CharacterBody3D and (body.is_in_group("em_walker") or body.is_in_group("player_body") or body.is_in_group("player")))

func _entered(body:Node3D) -> void:
	if accepts(body):visitors[body.get_instance_id()]=weakref(body)

func _exited(body:Node3D) -> void:
	visitors.erase(body.get_instance_id())
	if body.get_instance_id()==last_body:last_body=0;last_band=-1

func _physics_process(_delta:float) -> void:
	for id in visitors.keys():
		var body: Node3D = visitors[id].get_ref()
		if not is_instance_valid(body):visitors.erase(id);continue
		var p:Vector3=study.to_local(body.global_position)
		if absf(p.x)>.92 or p.z<-.05 or p.z>3.25:continue
		var band:int=clampi(roundi((p.z-FIRST_Z)/PITCH),0,study.Model.N-1)
		if id==last_body and last_band>=0:
			if absf(p.z-(FIRST_Z+PITCH*last_band))<=PITCH/2+DEAD_BAND:return
		last_body=id
		if band!=last_band:
			last_band=band
			study.select_spatial_slice(band)
		return

func refresh() -> void:
	var z:float=FIRST_Z+PITCH*study.slice_z
	for frame in frames:frame.position.z=z
	floor_mark.position.z=z

func bar(parent:Node3D,size:Vector3,at:Vector3) -> MeshInstance3D:
	var n:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;n.mesh=mesh;n.position=at
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("ffd18e");mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	n.material_override=mat;n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;parent.add_child(n)
	return n
