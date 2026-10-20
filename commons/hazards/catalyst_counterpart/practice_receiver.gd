extends StaticBody3D
## A quiet receiver teaches the trigger before a moving counterpart needs it.
signal received
var enabled := false
var lit := false
var finish := StandardMaterial3D.new()

func _ready() -> void:
	name = "PracticeReceiver"
	collision_layer = 2
	collision_mask = 0
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.9, 0.9, 0.12)
	var view := MeshInstance3D.new()
	view.mesh = mesh
	finish.albedo_color = Color(0.07, 0.07, 0.07)
	finish.roughness = 0.5
	view.material_override = finish
	add_child(view)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collision.shape = shape
	add_child(collision)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.26; torus.outer_radius = 0.28
	torus.rings = 32; torus.ring_segments = 6
	ring.mesh = torus; ring.rotation.x = PI / 2; ring.position.z = 0.075
	var pale := StandardMaterial3D.new()
	pale.albedo_color = Color(0.85, 0.85, 0.83)
	ring.material_override = pale
	add_child(ring)

func hit_by_catalyst_mode(_colour: Color, _mode: String) -> void:
	if not enabled or lit: return
	lit = true
	finish.albedo_color = Color(0.9, 0.9, 0.86)
	received.emit()

func reset_receiver() -> void:
	enabled = false; lit = false
	finish.albedo_color = Color(0.07, 0.07, 0.07)
