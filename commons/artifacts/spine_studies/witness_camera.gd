extends "res://addons/godot-xr-tools/objects/pickable.gd"
## A physical camera handle. Both pickup systems retain the pose on release.
var channel := "A"
var desktop_held := false

func _init() -> void:
	collision_layer = 4
	collision_mask = 1
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = ReleaseMode.FROZEN

func _ready() -> void:
	add_to_group("no_gravity_gun")
	var shape := BoxShape3D.new(); shape.size = Vector3(0.42,0.30,0.50)
	var collision := CollisionShape3D.new(); collision.shape = shape; add_child(collision)
	var shell := BoxMesh.new(); shell.size = Vector3(0.40,0.24,0.28)
	part(shell,Vector3.ZERO,Color("c96790"))
	var grip := BoxMesh.new(); grip.size = Vector3(0.075,0.14,0.20)
	part(grip,Vector3(0.17,0.17,0),Color("38363e"))
	var lens := CylinderMesh.new(); lens.top_radius = 0.08; lens.bottom_radius = 0.095; lens.height = 0.15
	var barrel := part(lens,Vector3(0,0,-0.21),Color("24232b")); barrel.rotation.x = PI*0.5
	var glass := CylinderMesh.new(); glass.top_radius = 0.066; glass.bottom_radius = 0.066; glass.height = 0.007
	var face := part(glass,Vector3(0,0,-0.29),Color("94cad2")); face.rotation.x = PI*0.5
	var caption := Label3D.new(); caption.text = channel+" / PICK UP · AIM · RELEASE"
	caption.font_size = 32; caption.pixel_size = 0.00065; caption.outline_size = 0
	caption.position = Vector3(0,0.012,0.146); add_child(caption)
	var front := Label3D.new(); front.text = channel; front.font_size = 48
	front.pixel_size = 0.0011; front.outline_size = 0
	front.position = Vector3(-0.145,0,-0.146); front.rotation.y = PI; add_child(front)
	super()

func part(mesh: Mesh, at: Vector3, colour: Color) -> MeshInstance3D:
	var result := MeshInstance3D.new(); result.mesh = mesh; result.position = at
	var surface := StandardMaterial3D.new(); surface.albedo_color = colour; surface.roughness = 0.5
	result.material_override = surface; add_child(result); return result

func held_by_visitor() -> bool:
	return desktop_held or is_picked_up()

func on_desktop_grab(_pointer: Node) -> void:
	desktop_held = true

func on_desktop_drop(_pointer: Node) -> void:
	desktop_held = false
	freeze = true; linear_velocity = Vector3.ZERO; angular_velocity = Vector3.ZERO

func lens_pose() -> Transform3D:
	return global_transform * Transform3D(Basis.IDENTITY,Vector3(0,0,-0.32))
