extends Node3D
## An open timber hopper. The wedge is its floor; lifting the retained handle
## raises the front gate. The released source ball is always a free rigid body.
signal ball_released
signal ball_held
const Plank = preload("res://commons/artifacts/line_relations_gallery/line_body.gd")
const WhiteBalls = preload("res://commons/artifacts/surface_ball_test/surface_ball_test.gd")
const BALL_LAYER := 1 << 25
const TRAVEL := .48
@export var unit_size := 1.0
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")

func travel() -> float:
	return maxf(.08,TRAVEL*unit_size)
var supply: Node3D
var ball: XRToolsPickable
var track: XRToolsInteractableSlider
var handle: XRToolsInteractableHandle
var opened := false
var resetting := false
var wood: Material

class Track extends XRToolsInteractableSlider:
	func _process(_delta: float) -> void:
		if grabbed_handles.is_empty():return
		var offset := 0.0
		var positions: Array[Vector3] = []
		for item in grabbed_handles:
			positions.append(item.global_position)
			offset += to_local(item.global_position).x-to_local(item.handle_origin.global_position).x
		move_slider(slider_position+offset/grabbed_handles.size())
		# Keep the hand proxy still when the constrained carriage moves.
		for i in grabbed_handles.size():grabbed_handles[i].global_position=positions[i]

func _ready() -> void:
	wood=StandardMaterial3D.new()
	wood.albedo_texture=load("res://commons/void/textures/construction_wood.png")
	wood.roughness=.9
	panel(self,"Back",Vector3(-.24,0,0),Vector3.UP,.34,Vector3(1,1,2.24))
	for side in [-1,1]:
		panel(self,"SideLeft" if side<0 else "SideRight",Vector3(0,0,side*.28),Vector3.RIGHT,.54,Vector3(1,5.667,.24))
	var origin := Node3D.new();origin.name="LiftOrigin"
	origin.position=Vector3(.24,-.02,0)*unit_size;origin.rotation_degrees.z=90
	track=Track.new();track.name="GateLift";track.slider_limit_max=travel()
	track.slider_steps=0.0;track.default_on_release=false
	var grip_origin := Node3D.new();grip_origin.name="HandleOrigin";grip_origin.position=Vector3(.06*unit_size,0,maxf(.12,.46*unit_size))
	handle=XRToolsInteractableHandle.new();handle.name="LiftHandle";handle.freeze=true
	handle.collision_layer=4;handle.collision_mask=0;handle.picked_up_layer=0
	# Preserve the grab offset: reaching from above must not lift the latch by itself.
	handle.ranged_grab_method=XRToolsPickable.RangedMethod.NONE
	var collision := CollisionShape3D.new();collision.name="GripCollision"
	var shape := BoxShape3D.new();shape.size=Vector3(.06,.06,maxf(.09,.32*unit_size));collision.shape=shape
	handle.add_child(collision);grip_origin.add_child(handle);track.add_child(grip_origin)
	origin.add_child(track);add_child(origin)
	panel(track,"SlidingGate",Vector3.ZERO,Vector3.RIGHT,.34,Vector3(1,1,2.0))
	var stem := Plank.new();stem.name="LeverStem";stem.skin="stick";stem.span=grip_origin.position.z
	stem.quaternion=Quaternion(Vector3.RIGHT,Vector3.BACK);stem.position=Vector3(.06*unit_size,0,grip_origin.position.z/2)
	track.add_child(stem);stem.enabled=false;stem.collision_layer=0;stem.collision_mask=0
	var cap := Plank.new();cap.name="LiftGrip";cap.skin="stick";cap.span=maxf(.08,.3*unit_size)
	cap.quaternion=Quaternion(Vector3.RIGHT,Vector3.BACK);cap.position=grip_origin.position
	track.add_child(cap);cap.enabled=false;cap.collision_layer=0;cap.collision_mask=0
	var label := Label3D.new();label.name="LiftInstruction";label.text="LIFT TO RELEASE ↑"
	label.position=Vector3(.26*unit_size,-.13*unit_size,grip_origin.position.z+.03);label.font_size=32;label.pixel_size=.00055 if unit_size<1 else .0016
	label.outline_size=0;add_child(label)
	track.slider_moved.connect(_lifted)
	supply=WhiteBalls.new();supply.name="OriginalWhiteGravityBall"
	supply.radius=.14*unit_size;supply.drop_height=.2*unit_size;supply.lifetime=120;add_child(supply)
	# This is a retained game piece, not a temporary surface-test shower.
	# Reset owns its lifetime; waiting at the box must not delete the ball.
	supply.set_physics_process(false)
	reset_box()

func panel(parent: Node3D, title: String, at: Vector3, axis: Vector3, span: float, size: Vector3) -> void:
	var plank := Plank.new();plank.name=title;plank.skin="plank";plank.span=span*unit_size
	plank.position=at*unit_size;plank.quaternion=Quaternion(Vector3.RIGHT,axis)
	parent.add_child(plank);plank.enabled=false;plank.collision_layer=1;plank.collision_mask=0
	var dimensions := Vector3(span,.06*size.y,.25*size.z)*unit_size
	plank.get_node("Skin").mesh=Timber.mesh(dimensions)
	plank.get_node("PickupBody").shape.size=dimensions
	plank.get_node("Skin").material_override=wood

func reset_box() -> void:
	resetting=true
	if is_instance_valid(ball):ball.drop()
	if handle.is_picked_up():handle.drop()
	opened=false;track.slider_position=0.0
	supply.cooldown=0
	var points: Array[Vector3]=[Vector3.ZERO]
	supply.drop(self,points)
	var original: RigidBody3D=supply.balls[0]
	# Keep the existing white gravity sphere, shape and physical material. Only
	# its holder changes to the project's normal desktop/XR pickup contract.
	ball=XRToolsPickable.new();ball.name="WhiteGravityBall"
	ball.transform=original.transform;ball.mass=maxf(.02,original.mass*unit_size)
	ball.physics_material_override=original.physics_material_override
	ball.continuous_cd=true;ball.collision_layer=BALL_LAYER|4;ball.collision_mask=1|BALL_LAYER
	ball.release_mode=XRToolsPickable.ReleaseMode.UNFROZEN
	for child in original.get_children():
		original.remove_child(child);ball.add_child(child)
	supply.remove_child(original);original.queue_free();supply.add_child(ball);supply.balls[0]=ball
	ball.picked_up.connect(func(_body):
		if not resetting:ball_held.emit())
	ball.dropped.connect(func(_body):
		if not resetting:ball_released.emit())
	resetting=false

func open_gate() -> void:
	track.move_slider(travel())

func _lifted(value: float) -> void:
	if value>=travel()*.95 and not opened:
		opened=true;ball.sleeping=false;ball_released.emit()
