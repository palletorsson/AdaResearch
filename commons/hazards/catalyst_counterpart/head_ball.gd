extends CharacterBody3D
const GLOW := preload("res://commons/hazards/becoming_catalyst/first_catalyst_glow.gdshader")
## Swept sphere collision: a fast ball cannot skip the player between frames.
var direction := Vector3.FORWARD
var speed := 3.0
var lifetime := 5.0
var spent := false
signal player_hit(body: Node3D)
signal surface_hit(body: Node3D, at: Vector3)

func _ready() -> void:
	name = "HeadBall"
	collision_layer = 0
	collision_mask = 1 | 524288 # Architecture / desktop body, XRTools player body.
	var shape := CollisionShape3D.new()
	var boundary := SphereShape3D.new(); boundary.radius = 0.09
	shape.shape = boundary; add_child(shape)
	var view := MeshInstance3D.new()
	var mesh := SphereMesh.new(); mesh.radius = 0.09; mesh.height = 0.18
	mesh.radial_segments = 12; mesh.rings = 6; view.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.80, 0.49)
	view.material_override = mat; add_child(view)
	# Keep this small visual self-contained; loading an ability or helper script
	# here makes a basic projectile depend on unrelated script imports.
	var glow := MeshInstance3D.new()
	var halo := SphereMesh.new()
	halo.radius = 0.14; halo.height = 0.28
	halo.radial_segments = 24; halo.rings = 12
	glow.mesh = halo
	var glow_material := ShaderMaterial.new()
	glow_material.shader = GLOW
	glow.material_override = glow_material
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow.material_override.set_shader_parameter("glow_colour", Color(1.0, 0.55, 0.18))
	glow.material_override.set_shader_parameter("strength", 0.8)
	add_child(glow)

func _physics_process(delta: float) -> void:
	if spent: return
	lifetime -= delta
	if lifetime <= 0.0: queue_free(); return
	var collision := move_and_collide(direction.normalized() * speed * delta)
	if collision == null: return
	spent = true
	var body: Node = collision.get_collider()
	if body is Node3D: surface_hit.emit(body, collision.get_position())
	if body != null and (body.is_in_group("player_body") or body.is_in_group("player")):
		player_hit.emit(body)
	queue_free()
