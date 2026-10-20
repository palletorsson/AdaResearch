extends "res://commons/artifacts/randomness_space/entropy_ruin.gd"
## Loose masonry: one support is drawn out; gravity/contact decide the consequence.
## The inherited builder supplies architecture. The museum weathering wall keeps
## its separate, authored dismantling model in the base script.
const PULL_SECONDS:=0.9
const SELECTION_SECONDS:=4.5
var extracting: int=-1
var pull_age:=0.0
var pull_from:=Vector3.ZERO
var pull_to:=Vector3.ZERO
var reset_frames:=0
var reading_clock:=0.0
var controls: Dictionary={}

func _ready() -> void:
	super._ready()
	for stack in stacks:
		for j in stack.size():
			var p: Dictionary=pieces[stack[j]]
			p.anchor=j<2
			p.body.freeze=p.anchor
			p.body.enabled=not p.anchor
			p.body.set_meta("force_constraint_body",p.anchor)
	for i in 3:controls[["RUN / PAUSE","ONE STONE","RESTORE"][i]]=find_child("Btn_"+str(i),true,false)
	_readout()

func _create_bed() -> void:
	Stage.box(self,Vector3(0,0.04,0),Vector3(6.8,0.08,3.8),Color("797365"),true)
	for x in [-3.35,3.35]:Stage.box(self,Vector3(x,0.12,0),Vector3(0.1,0.24,3.8),Color("b5ac99"),true)
	for z in [-1.85,1.85]:Stage.box(self,Vector3(0,0.12,z),Vector3(6.6,0.24,0.1),Color("b5ac99"),true)

func _piece(mesh: Mesh,pos: Vector3,mat: Material,size: Vector3) -> int:
	var body=load("res://commons/artifacts/randomness_space/ruin_stone.gd").new()
	var id:=pieces.size();body.name="Stone_%03d" % id
	body.position=pos;body.collision_layer=4;body.collision_mask=5
	body.mass=clampf(size.x*size.y*size.z*250,0.6,12.0)
	body.continuous_cd=true;body.linear_damp=0.12;body.angular_damp=0.18
	body.release_mode=0 # XRToolsPickable.ReleaseMode.UNFROZEN
	body.freeze_mode=RigidBody3D.FREEZE_MODE_STATIC
	body.set_meta("no_trail",true)
	var contact:=PhysicsMaterial.new();contact.friction=0.72;contact.bounce=0
	body.physics_material_override=contact
	var visual:=MeshInstance3D.new();visual.name="StoneMesh";visual.mesh=mesh;visual.material_override=mat;body.add_child(visual)
	var collision:=CollisionShape3D.new()
	if mesh is BoxMesh:
		var box:=BoxShape3D.new();box.size=size;collision.shape=box
	else:
		# Convex hull keeps a flat bearing face and the actual tapered silhouette.
		collision.shape=mesh.create_convex_shape(true,false)
	body.add_child(collision);add_child(body)
	pieces.append({"node":body,"body":body,"visual":visual,"home":body.transform,"size":size,"fallen":false,"anchor":false})
	body.picked_up.connect(_on_grab.bind(id))
	body.dropped.connect(_on_drop.bind(id))
	return id

func _process(delta: float) -> void:
	# Pausing automatic selection never suspends gravity on a released stone.
	reading_clock+=delta
	if reading_clock>0.25:reading_clock=0;_readout()
	if not running or extracting>=0 or reset_frames>0:return
	clock+=delta
	if clock>=SELECTION_SECONDS:clock=0;weather_one()

func _physics_process(delta: float) -> void:
	if reset_frames>0:
		# Teleport while static, so RESTORE cannot push neighbouring stones with
		# a kinematic velocity calculated from their previous rubble positions.
		for p in pieces:
			p.body.transform=p.home;p.body.linear_velocity=Vector3.ZERO;p.body.angular_velocity=Vector3.ZERO
		reset_frames-=1
		if reset_frames==0:_wake_loose()
		return
	if extracting<0:return
	pull_age+=delta
	var body: RigidBody3D=pieces[extracting].body
	body.position=pull_from.lerp(pull_to,minf(1,pull_age/PULL_SECONDS))
	if pull_age>=PULL_SECONDS:
		body.freeze=false;body.sleeping=false;body.linear_velocity=Vector3.ZERO;body.angular_velocity=Vector3.ZERO
		body.enabled=true;body.set_meta("force_constraint_body",false)
		extracting=-1;clock=0;_readout()

func _wake_loose() -> void:
	for p in pieces:
		if not p.anchor and not _held(p.body) and p.body!=_extracting_body():
			p.body.freeze=false;p.body.sleeping=false

func _extracting_body() -> RigidBody3D:
	return null if extracting<0 else pieces[extracting].body

func _held(body: RigidBody3D) -> bool:
	return body.is_picked_up() or bool(body.get_meta("capability_desktop_held",false))

func _on_grab(_body: Node3D,id: int) -> void:
	running=false
	if not history.has(id):history.append(id);pieces[id].fallen=true
	_wake_loose();_readout()

func _on_drop(_body: Node3D,_id: int) -> void:
	_wake_loose();_readout()

func _candidates(begin: int,end: int) -> Array[int]:
	var choices: Array[int]=[]
	for s in range(begin,end):
		for j in range(2,stacks[s].size()-1):
			var id: int=stacks[s][j];var p: Dictionary=pieces[id]
			var offset: Vector3=p.body.position-p.home.origin
			if not p.fallen and not _held(p.body) and Vector2(offset.x,offset.z).length()<0.35 and p.body.position.y>0.65:
				choices.append(id);break
	return choices

func weather_one() -> void:
	if extracting>=0 or reset_frames>0:return
	# Begin with load-bearing drums, so one removal can affect several stones.
	var eligible:=_candidates(12,16)
	if eligible.is_empty():eligible=_candidates(0,12)
	if eligible.is_empty():running=false;_readout();return
	pull_and_drop(eligible[rng.randi_range(0,eligible.size()-1)])

func pull_and_drop(id: int) -> bool:
	if id<0 or id>=pieces.size() or extracting>=0 or reset_frames>0:return false
	var p: Dictionary=pieces[id]
	if p.anchor or p.fallen or _held(p.body):return false
	extracting=id;pull_age=0;pull_from=p.body.position
	pull_to=pull_from+Vector3(0,0,-1.1 if id>=72 else 0.75)
	p.body.freeze_mode=RigidBody3D.FREEZE_MODE_KINEMATIC
	p.body.set_meta("force_constraint_body",true)
	p.body.freeze=true;p.body.enabled=false;p.body.linear_velocity=Vector3.ZERO;p.body.angular_velocity=Vector3.ZERO
	p.fallen=true;history.append(id);_wake_loose();_readout()
	return true

func restore() -> void:
	for p in pieces:
		if _held(p.body):
			running=false
			if readout!=null:readout.text="Release the held stone before RESTORE."
			return
	extracting=-1;running=false;clock=0;pull_age=0
	for p in pieces:
		p.body.freeze_mode=RigidBody3D.FREEZE_MODE_STATIC
		p.body.freeze=true;p.body.linear_velocity=Vector3.ZERO;p.body.angular_velocity=Vector3.ZERO
		p.body.transform=p.home;p.body.reset_physics_interpolation()
		p.body.enabled=not p.anchor;p.fallen=false
		p.body.set_meta("force_constraint_body",p.anchor)
	history.clear();rng.seed=SEED;reset_frames=2;_readout()

func _readout() -> void:
	if readout==null:return
	var shifted:=0
	for p in pieces:
		if p.body.position.distance_to(p.home.origin)>0.18:shifted+=1
	readout.text="%d STONES / %d PULLED / %d MOVED\n%s / gravity stays on" % [pieces.size(),history.size(),shifted,"AUTO SELECT" if running else "SELECT PAUSED"]
