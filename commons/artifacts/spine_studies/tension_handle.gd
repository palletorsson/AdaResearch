extends "res://addons/godot-xr-tools/objects/pickable.gd"
## The solver follows a held handle; on release the handle follows the solver.
var desktop_held := false

func _init() -> void:
	collision_layer = 4
	collision_mask = 0
	freeze = true
	release_mode = ReleaseMode.FROZEN

func _ready() -> void:
	add_to_group("no_gravity_gun")
	var shape := SphereShape3D.new(); shape.radius = 0.16
	var collider := CollisionShape3D.new(); collider.shape = shape; add_child(collider)
	var mesh := SphereMesh.new(); mesh.radius = 0.11; mesh.height = 0.22
	var grip := MeshInstance3D.new(); grip.mesh = mesh
	var material := StandardMaterial3D.new(); material.albedo_color = Color("d37c99")
	material.roughness = 0.45; grip.material_override = material; add_child(grip)
	super()

func held_by_visitor() -> bool:
	return desktop_held or is_picked_up()

func on_desktop_grab(_pointer: Node) -> void:
	desktop_held = true

func on_desktop_drop(_pointer: Node) -> void:
	desktop_held = false
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
