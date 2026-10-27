extends XRToolsPickable
## Catalyst canister: safe pickup -> opposite-hand pin pull -> release to ignite.
const FX := preload("laser_fx.gd")
const Cloud := preload("smoke_cloud.gd")
const FUSE := 1.6
const BLAST_RADIUS := 3.0
var world: Node3D
var armed := false
var spent := false
var held_once := false
var pin_removed := false
var pin: XRToolsPickable
var indicator: MeshInstance3D
const PIN_SOCKET := Vector3(0.15, 0.12, 0)
var flight_time := 0.0
var last_position := Vector3.ZERO
var excluded: Array[RID] = []
signal detonated()

func _ready() -> void:
	world=get_tree().get_first_node_in_group("void_game") as Node3D
	freeze=true; release_mode=ReleaseMode.UNFROZEN
	mass=0.18; collision_layer=4; collision_mask=1|2
	original_collision_layer=collision_layer; original_collision_mask=collision_mask
	continuous_cd=true; contact_monitor=true; max_contacts_reported=4
	var collision := CollisionShape3D.new(); collision.name="CollisionShape3D"
	var shape := SphereShape3D.new(); shape.radius=0.11
	collision.shape=shape; add_child(collision)
	var cream := FX.finish(Color("d8d4c3"))
	var dark := FX.finish(Color("2c3437"))
	FX.rod(self,Vector3(0,-0.10,0),Vector3(0,0.10,0),0.085,cream)
	FX.rod(self,Vector3(0,0.075,0),Vector3(0,0.115,0),0.092,dark)
	FX.rod(self,Vector3(0,-0.075,0),Vector3(0,-0.035,0),0.087,FX.finish(Color("caa451")))
	indicator=FX.box(self,Vector3(0,0.125,0),Vector3(0.07,0.025,0.07),FX.finish(Color("9cf8ff"),true),"ReadyIndicator")
	pin=load("res://commons/void/smoke_pin.gd").new()
	pin.bomb_ref=weakref(self); pin.name="SafetyPin"; add_child(pin); pin.position=PIN_SOCKET
	var label := Label3D.new();label.text="SMOKE";label.font_size=28;label.pixel_size=0.00065
	label.outline_size=0;label.modulate=Color("222b2d");label.position=Vector3(0,0,0.088);add_child(label)
	picked_up.connect(_taken)
	dropped.connect(_released)
	# XR trigger never throws a held canister. Desktop uses two distinct clicks:
	# pull pin, then assisted throw. Defer past XRTools' action delivery.
	action_pressed.connect(func(_item): _tool_action.call_deferred())
	body_entered.connect(func(_body):
		if armed and flight_time>0.08: _detonate.call_deferred())
	add_to_group("void_smoke_bomb")
	super()

func _taken(_item: Node3D) -> void:
	held_once=true

func pick_up(by: Node3D) -> void:
	if not can_pick_up(by): return
	# Reparent BEFORE XRTools creates its grab driver. Reparenting a held object
	# invokes XRToolsPickable._exit_tree(), which releases the controller grab.
	if is_instance_valid(world) and get_parent()!=world: reparent(world,true)
	# The removable pin has its own lifetime. Do not let the body's grab record
	# its RID as a child collision exception and touch it after the pin is freed.
	if is_instance_valid(pin) and is_instance_valid(world) and pin.get_parent()!=world:
		pin.reparent(world,true)
	super(by)

func can_pick_up(by: Node3D) -> bool:
	return not is_picked_up() and super(by)

func remove_pin() -> void:
	if pin_removed or not is_picked_up() or spent: return
	pin_removed=true
	indicator.material_override=FX.finish(Color("ffad54"),true)
	FX.sound(world,global_position,"pin")
	if is_instance_valid(world): world._notice("PIN OUT / release the canister to throw")

func _tool_action() -> void:
	if not is_picked_up() or spent: return
	if get_picked_up_by_controller()!=null: return
	if not pin_removed:
		remove_pin()
		pin.remove_from_desktop()
	else: _throw_assisted(self)

func _released(_item: Node3D) -> void:
	if spent or not held_once: return
	if is_instance_valid(world) and (world.recovering or world.returning):
		_retire(); return
	if not pin_removed: return # Dropping a pinned canister is harmless and recoverable.
	armed=true; enabled=false; flight_time=0
	excluded=[get_rid()]
	if is_instance_valid(world):
		add_collision_exception_with(world.body)
		excluded.append(world.body.get_rid())
		for body in world.get_node("XROrigin3D").find_children("*","PhysicsBody3D",true,false):
			add_collision_exception_with(body)
			excluded.append(body.get_rid())
		var guard := PhysicsRayQueryParameters3D.create(world.camera.global_position,global_position,1)
		guard.exclude=excluded
		var obstruction := get_world_3d().direct_space_state.intersect_ray(guard)
		if not obstruction.is_empty(): global_position=obstruction.position+obstruction.normal*0.14
	last_position=global_position

func _throw_assisted(_item: Node3D) -> void:
	if not is_picked_up() or spent: return
	var controller := get_picked_up_by_controller()
	var direction: Vector3 = -controller.global_basis.z if controller!=null else -world.camera.global_basis.z
	var grabber := get_picked_up_by()
	if grabber.has_method("drop_object"): grabber.drop_object()
	else: let_go(grabber,Vector3.ZERO,Vector3.ZERO)
	linear_velocity=direction.normalized()*10.0+Vector3.UP*2.0
	angular_velocity=Vector3(3,1,2)

func _physics_process(delta: float) -> void:
	if spent or not armed: return
	flight_time+=delta
	if is_instance_valid(world) and (world.recovering or world.returning):
		_retire(); return
	# Sweep between steps as well as contact monitoring, so thin panels stop a toss.
	var ray := PhysicsRayQueryParameters3D.create(last_position,global_position,1|2)
	ray.exclude=excluded
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		global_position=hit.position+hit.normal*0.12
		_detonate(); return
	last_position=global_position
	if flight_time>=FUSE: _detonate()

func _detonate() -> void:
	if spent or not armed: return
	if not is_instance_valid(world): _retire(); return
	var origin := global_position
	if "--smoke-debug" in OS.get_cmdline_user_args(): print("SMOKE_BURST at=",origin)
	for turret in get_tree().get_nodes_in_group("void_ceiling_turret"):
		var target: Vector3=turret.to_global(turret.muzzle)
		var distance := origin.distance_to(target)
		if "--smoke-debug" in OS.get_cmdline_user_args(): print("SMOKE_TARGET distance=",distance)
		if distance>BLAST_RADIUS: continue
		var ray := PhysicsRayQueryParameters3D.create(origin,target,1|2)
		ray.exclude=[get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if "--smoke-debug" in OS.get_cmdline_user_args(): print("SMOKE_OCCLUSION ",hit.get("collider"))
		if not hit.is_empty() and hit.collider!=turret: continue
		for i in range(3 if distance<=1.5 else 1):
			turret.hit_by_catalyst_mode(Color("ccd4db"),"smoke")
	var cloud := Cloud.new()
	world.add_child(cloud)
	cloud.global_position=origin+Vector3.UP*0.35
	FX.sparks(world,origin)
	detonated.emit()
	_retire()

func _retire() -> void:
	if spent: return
	spent=true; enabled=false; freeze=true; hide()
	collision_layer=0;collision_mask=0
	# Keep its RID until XRTools' delayed hand-collision cleanup completes.
	get_tree().create_timer(0.7).timeout.connect(queue_free)
