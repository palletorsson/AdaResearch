extends "res://commons/artifacts/force_play/play_body.gd"
## A 2.2 m physical stick. The same full-length collider remains present while
## held; ordinary bodies receive contact impulses from the moving kinematic tool.
## This supplies reach, not a simulated measurement of the visitor's strength.
const LENGTH := 2.2
var desktop_pointer: Node3D

func _init() -> void:
	freeze=true;mass=0.8;picked_up_layer=4
	freeze_mode=RigidBody3D.FREEZE_MODE_KINEMATIC
	collision_layer=4;collision_mask=1|4
	ranged_grab_method=RangedMethod.NONE
	continuous_cd=true
	var dark=StandardMaterial3D.new();dark.albedo_color=Color("24252a");dark.roughness=0.3
	var rose=StandardMaterial3D.new();rose.albedo_color=Color("ed96bb")
	var pale=StandardMaterial3D.new();pale.albedo_color=Color("eee9db")
	for part in [[LENGTH,0.035,-0.85,dark],[0.27,0.049,0.0,rose],[0.12,0.052,-1.89,pale]]:
		var visual=MeshInstance3D.new();var mesh=CylinderMesh.new()
		mesh.height=part[0];mesh.top_radius=part[1];mesh.bottom_radius=part[1];mesh.radial_segments=12
		visual.mesh=mesh;visual.material_override=part[3];visual.position.z=part[2];visual.rotation.x=PI/2;add_child(visual)
	var collider=CollisionShape3D.new();var shape=CapsuleShape3D.new();shape.height=LENGTH;shape.radius=0.052
	collider.shape=shape;collider.position.z=-0.85;collider.rotation.x=PI/2;add_child(collider)
	var point=XRToolsGrabPoint.new();point.name="Handle";add_child(point)

func held() -> bool:
	return is_picked_up() or has_meta("capability_desktop_held")

func _ready() -> void:
	super()
	release_mode=ReleaseMode.UNFROZEN

func on_desktop_grab(pointer: Node3D) -> void:
	super(pointer);desktop_pointer=pointer

func on_desktop_drop(pointer: Node3D) -> void:
	super(pointer);desktop_pointer=null

func _physics_process(_dt: float) -> void:
	if held():
		# Desktop carry normally hides collision; this tool deliberately touches
		# artifacts. Exclude player layers, retain world and loose-body contacts.
		collision_layer=4;collision_mask=1|4
		if is_instance_valid(desktop_pointer):
			var eye: Camera3D=desktop_pointer.get("_camera")
			if is_instance_valid(eye):global_basis=eye.global_basis.orthonormalized()
