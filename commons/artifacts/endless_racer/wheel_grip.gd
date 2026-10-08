extends "res://commons/artifacts/force_play/play_body.gd"
## A held point reads hand position; it never pulls the driver's body.
var desktop_pointer: Node3D
var active := false

func _ready() -> void:
	freeze=true;freeze_mode=RigidBody3D.FREEZE_MODE_KINEMATIC
	gravity_scale=0;collision_layer=4;collision_mask=0
	var shape=SphereShape3D.new();shape.radius=0.085
	var collider=CollisionShape3D.new();collider.shape=shape;add_child(collider)
	var mesh=MeshInstance3D.new();var ball=SphereMesh.new();ball.radius=0.07;ball.height=0.14;ball.radial_segments=12;ball.rings=6
	mesh.mesh=ball;var mat=StandardMaterial3D.new();mat.albedo_color=Color("f4a1c5");mat.roughness=0.25;mesh.material_override=mat;add_child(mesh)

func held() -> bool:return is_picked_up() or is_instance_valid(desktop_pointer)
func on_desktop_grab(pointer: Node3D) -> void:desktop_pointer=pointer
func on_desktop_drop(_pointer: Node3D=null) -> void:desktop_pointer=null;freeze=true
