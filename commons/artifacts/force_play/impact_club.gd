extends "res://commons/artifacts/force_play/play_body.gd"
## Oversized driver. Held contact is kinematic; the ball's response is Jolt contact.
var desktop_pointer: Node3D
const HEAD := Vector3(0.24,0,-1.5)

func _init() -> void:
	freeze=true;mass=1.6;picked_up_layer=4;collision_mask=1|4
	freeze_mode=RigidBody3D.FREEZE_MODE_KINEMATIC
	ranged_grab_method=RangedMethod.NONE
	var graphite=finish("20252e",0.7,0.22)
	var metal=finish("e0e4e6",0.7,0.25)
	var grip=finish("ef90bd",0.1,0.7)
	var light=finish("65f2d3",0.2,0.22)
	light.emission_enabled=true;light.emission=Color("65f2d3");light.emission_energy_multiplier=1.4
	for row in [[1.5,0.035,-0.66,metal],[0.3,0.06,0.0,grip],[0.10,0.075,-0.2,graphite],[0.10,0.075,-1.28,light]]:
		var shape=CylinderMesh.new();shape.height=row[0];shape.top_radius=row[1];shape.bottom_radius=row[1];shape.radial_segments=16
		part(shape,row[3],Vector3(0,0,row[2]),Vector3(PI/2,0,0))
	var shaft=CapsuleShape3D.new();shaft.radius=0.06;shaft.height=1.55
	collider(shaft,Vector3(0,0,-0.66),Vector3(PI/2,0,0))
	for row in [[Vector3(0.92,0.28,0.4),HEAD,graphite],
		[Vector3(0.98,0.22,0.055),HEAD+Vector3(0,0,0.215),metal],
		[Vector3(0.80,0.025,0.32),HEAD+Vector3(0,0.15,0),light],
		[Vector3(0.12,0.23,0.32),HEAD+Vector3(0.42,0,0),grip]]:
		var mesh=BoxMesh.new();mesh.size=row[0];part(mesh,row[2],row[1])
	var head=BoxShape3D.new();head.size=Vector3(1.0,0.31,0.46);collider(head,HEAD)
	var point=XRToolsGrabPoint.new();point.name="Handle";add_child(point)

func finish(hex: String, metal: float, rough: float) -> StandardMaterial3D:
	var mat=StandardMaterial3D.new();mat.albedo_color=Color(hex);mat.metallic=metal;mat.roughness=rough;return mat

func part(mesh: Mesh,mat: Material,at: Vector3,turn:=Vector3.ZERO) -> void:
	var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=mat;node.position=at;node.rotation=turn;add_child(node)

func collider(shape: Shape3D,at: Vector3,turn:=Vector3.ZERO) -> void:
	var node=CollisionShape3D.new();node.shape=shape;node.position=at;node.rotation=turn;add_child(node)

func _ready() -> void:
	super();release_mode=ReleaseMode.UNFROZEN

func held() -> bool:return is_picked_up() or has_meta("capability_desktop_held")

func on_desktop_grab(pointer: Node3D) -> void:
	super(pointer);desktop_pointer=pointer

func on_desktop_drop(pointer: Node3D) -> void:
	super(pointer);desktop_pointer=null

func _physics_process(_dt: float) -> void:
	if held():
		collision_layer=4;collision_mask=1|4
		if is_instance_valid(desktop_pointer):
			var eye: Camera3D=desktop_pointer.get("_camera")
			if is_instance_valid(eye):global_basis=eye.global_basis.orthonormalized()
