extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Local rack; returning this tool never resets the experiment.
var stick: RigidBody3D
var home: Transform3D
@export_file("*.gd") var tool_script := "res://commons/artifacts/force_play/push_stick.gd"
@export var invitation := "TAKE THE STICK\nPush / swing / reach"
@export var return_label := "RETURN STICK"

func _ready() -> void:
	var pale=material("e9e4d8");var ink=material("25252b")
	box(Vector3(0,0.08,0),Vector3(0.5,0.16,0.65),pale,true)
	box(Vector3(0,0.58,0.22),Vector3(0.12,1.0,0.12),pale,true)
	stick=load(tool_script).new()
	stick.name="PushStick";stick.position=Vector3(0,0.7,0);stick.rotation.x=PI/2;add_child(stick)
	home=stick.global_transform
	var words=label(invitation,Vector3(0,1.3,0.35),0.001)
	words.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	var button=PUSH.instantiate();button.position=Vector3(0.16,0.21,-0.18);button.rotation.x=-PI/2;add_child(button)
	button.pressed.connect(return_stick)
	var caption=label(return_label,Vector3(0,0.4,-0.3),0.0007);caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED

func return_stick() -> bool:
	if stick.held():return false
	stick.freeze=true;stick.freeze_mode=RigidBody3D.FREEZE_MODE_STATIC
	stick.global_transform=home;stick.linear_velocity=Vector3.ZERO;stick.angular_velocity=Vector3.ZERO
	stick.force_update_transform();stick.reset_physics_interpolation()
	PhysicsServer3D.body_set_state(stick.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,home)
	_restore_mode.call_deferred();return true

func _restore_mode() -> void:
	await get_tree().physics_frame
	if is_instance_valid(stick):stick.freeze_mode=RigidBody3D.FREEZE_MODE_KINEMATIC
