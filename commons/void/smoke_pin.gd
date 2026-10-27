extends XRToolsPickable
## A separate, close-range grip target; moving the canister alone cannot pull it.
const FX := preload("laser_fx.gd")
const PULL_DISTANCE := 0.12
var bomb_ref: WeakRef
var removed := false
var pull_start := Vector3.ZERO
var retiring := false

func _ready() -> void:
	freeze=true; release_mode=ReleaseMode.FROZEN
	collision_layer=4; collision_mask=0; can_ranged_grab=false
	original_collision_layer=collision_layer; original_collision_mask=collision_mask
	var collider := CollisionShape3D.new()
	var sphere := SphereShape3D.new(); sphere.radius=0.055
	collider.shape=sphere; add_child(collider)
	var mesh := TorusMesh.new(); mesh.inner_radius=0.028; mesh.outer_radius=0.042
	mesh.rings=16; mesh.ring_segments=8
	var ring := MeshInstance3D.new(); ring.mesh=mesh; ring.rotation.x=PI/2
	ring.material_override=FX.finish(Color("ffd45a")); add_child(ring)
	FX.rod(self,Vector3(-0.11,0,0),Vector3.ZERO,0.008,FX.finish(Color("b5bfc0")))
	picked_up.connect(func(_item): pull_start=get_picked_up_by().global_position)
	dropped.connect(func(_item):
		if removed: _retire())
	super()

func can_pick_up(by: Node3D) -> bool:
	var bomb: Node3D=bomb_ref.get_ref()
	return is_instance_valid(bomb) and not removed and not is_picked_up() \
		and bomb.is_picked_up() and bomb.get_picked_up_by()!=by \
		and by.global_position.distance_to(global_position)<0.22 and super(by)

func pick_up(by: Node3D) -> void:
	if not can_pick_up(by): return
	var bomb: Node3D=bomb_ref.get_ref()
	if get_parent()!=bomb.world: reparent(bomb.world,true)
	super(by)

func _physics_process(_delta: float) -> void:
	if removed: return
	var bomb: Node3D=bomb_ref.get_ref()
	if not is_instance_valid(bomb) or bomb.spent:
		_detach(); return
	if not is_picked_up():
		collision_layer=4 if bomb.is_picked_up() else 0
		global_transform=bomb.global_transform.translated_local(bomb.PIN_SOCKET)
		return
	if not bomb.is_picked_up():
		# Releasing the body mid-pull cancels the gesture, rather than arming it.
		get_picked_up_by().drop_object.call_deferred()
		return
	var hand_travel: float=get_picked_up_by().global_position.distance_to(pull_start)
	var separation: float=global_position.distance_to(bomb.to_global(bomb.PIN_SOCKET))
	if hand_travel>=PULL_DISTANCE and separation>=PULL_DISTANCE:
		bomb.remove_pin()
		_detach()

func _detach() -> void:
	removed=true; enabled=false
	if not is_picked_up(): _retire()

func remove_from_desktop() -> void:
	_detach()

func _retire() -> void:
	if retiring: return
	retiring=true; hide(); collision_layer=0
	get_tree().create_timer(0.7).timeout.connect(queue_free)
