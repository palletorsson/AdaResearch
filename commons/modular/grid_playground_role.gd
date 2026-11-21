extends Node3D
## Interaction belongs to the authored marker and follows its full grid pose.

signal consumed(role: String)

const COIN := "res://commons/void/coin_pickup.tscn"
const GIFT := "res://commons/void/gift_cube.tscn"
const ROLES := ["coin", "gift", "bomb"]
const CONTACT_RANGE := 0.6
const CONTACT_HEIGHT := 0.8
const FUSE_SECONDS := 0.6
const BLAST_RANGE := 1.0
const SHELL_RADIUS := 0.43
const BALL_IMPACT_SPEED := 1.5

var role := ""
var dimensions := Vector3.ONE
var rewards: Node3D
var monochrome := false
var pickup: Node3D
var bomb: Node3D
var fuse := -1.0
var spent := false
var impact_query: PhysicsShapeQueryParameters3D
var blast_outline: MeshInstance3D

func _ready() -> void:
	if role == "gift":
		rewards.set_meta("grid_gift_rewards", true)
	if role == "bomb":
		impact_query = PhysicsShapeQueryParameters3D.new()
		impact_query.shape = SphereShape3D.new()
		impact_query.collision_mask = 4 # Inventory carriers, including gift balls.
		var outline := TorusMesh.new()
		outline.inner_radius = BLAST_RANGE - 0.03
		outline.outer_radius = BLAST_RANGE
		blast_outline = _mesh(self, outline, Color("e8e8e4") if monochrome else Color("9e527c"))
		blast_outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		blast_outline.top_level = true
		set_notify_transform(true)
		_place_blast_outline()
	refill()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and is_instance_valid(blast_outline):
		_place_blast_outline()

func _place_blast_outline() -> void:
	var at := global_position + Vector3.UP * 0.025
	var center := to_global(Vector3.UP * dimensions.y * 0.5)
	at.x = center.x
	at.z = center.z
	blast_outline.global_transform = Transform3D(Basis.IDENTITY, at)

func refill() -> void:
	spent = false
	fuse = -1.0
	if role == "bomb":
		blast_outline.show()
		blast_outline.material_override.albedo_color = Color("e8e8e4") if monochrome else Color("9e527c")
		if is_instance_valid(bomb):
			bomb.free()
		bomb = Node3D.new()
		bomb.position = Vector3.UP * dimensions.y * 0.5
		bomb.scale = dimensions
		add_child(bomb)
		var shell := SphereMesh.new()
		shell.radius = SHELL_RADIUS
		shell.height = SHELL_RADIUS * 2.0
		_mesh(bomb, shell, Color("16181c") if monochrome else Color("2e222b"))
		var signal_light := SphereMesh.new()
		signal_light.radius = 0.12
		signal_light.height = 0.24
		var tip := _mesh(bomb, signal_light, Color("f6f6f2") if monochrome else Color("ff506a"))
		tip.position = Vector3(0.14, 0.37, 0)
		return
	if is_instance_valid(pickup):
		pickup.free()
	var scene: PackedScene = load(COIN if role == "coin" else GIFT)
	pickup = scene.instantiate()
	pickup.score_provider = self
	pickup.motion = "still"
	if monochrome:
		pickup.set_meta("config_monochrome", true)
		if role == "gift":
			pickup.set_meta("config_gift", "random")
	pickup.scale = dimensions / 0.5
	pickup.position = Vector3.DOWN * dimensions.y * 0.5
	# The shared marker contact below follows the authored affine pose even
	# when a parent scales it. Gift/coin effects and loot use the native scenes.
	var area: Area3D = pickup.get_node("DetectionArea")
	area.monitoring = false
	area.monitorable = false
	add_child(pickup)
	pickup.set_process(false)

func _mesh(parent: Node3D, mesh: Mesh, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	instance.mesh = mesh
	instance.material_override = material
	parent.add_child(instance)
	return instance

func add_points(_amount: int, _where: Vector3) -> void:
	# PickupCube calls this provider instead of the museum GameManager.
	consumed.emit(role)

func _hit_by_ball(center: Vector3) -> bool:
	var bounds := bomb.global_basis.get_scale().abs()
	var radius := SHELL_RADIUS * bounds[bounds.max_axis_index()]
	if not is_equal_approx(impact_query.shape.radius, radius):
		impact_query.shape.radius = radius
	impact_query.transform = Transform3D(Basis.IDENTITY, center)
	for hit in get_world_3d().direct_space_state.intersect_shape(impact_query):
		var ball := hit.collider as RigidBody3D
		if ball == null or ball.freeze or str(ball.get_meta("gift_cube_reward", "")).is_empty():
			continue
		if ball.linear_velocity.length_squared() >= BALL_IMPACT_SPEED * BALL_IMPACT_SPEED:
			return true
	return false

func step(game: Node, delta: float) -> bool:
	if spent:
		return false
	var center := to_global(Vector3.UP * dimensions.y * 0.5)
	var offset: Vector3 = game.body.global_position + Vector3.UP * 0.65 - center
	var distance := Vector2(offset.x, offset.z).length()
	var within_height := absf(offset.y) <= CONTACT_HEIGHT
	var contact := within_height and distance <= CONTACT_RANGE
	if role != "bomb":
		if contact:
			spent = true
			# The reward must fall in world space, clear of the moving marker.
			pickup.reparent(rewards, true)
			pickup.collect()
		return false
	if fuse < 0.0:
		var impact := _hit_by_ball(center)
		if contact or impact:
			fuse = FUSE_SECONDS
			var shell: MeshInstance3D = bomb.get_child(0)
			shell.material_override.albedo_color = Color("da3250")
			blast_outline.material_override.albedo_color = Color("ff6586")
			game._notice("BALL HIT / bomb arming" if impact else "BOMB ARMING / step back")
		return false
	fuse -= delta
	if fuse > 0.0:
		return false
	spent = true
	bomb.hide()
	blast_outline.hide()
	var hit_player := within_height and distance <= BLAST_RANGE
	_spawn_large_boom(center)
	if game != null and game.has_method("trigger_impact_feedback"):
		game.trigger_impact_feedback(1.0, center, hit_player)
	consumed.emit(role)
	return hit_player

func _spawn_large_boom(center: Vector3) -> void:
	var fx := Node3D.new()
	fx.name = "RoleBoomFX"
	rewards.add_child(fx)
	fx.global_position = center

	var core_mat := StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	core_mat.albedo_color = Color(1.0, 0.98, 0.92, 0.94) if monochrome else Color(1.0, 0.68, 0.72, 0.94)
	var core := MeshInstance3D.new()
	core.mesh = SphereMesh.new()
	core.material_override = core_mat
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core.scale = Vector3.ONE * 0.35
	fx.add_child(core)

	var ring := TorusMesh.new()
	ring.inner_radius = 0.76
	ring.outer_radius = 1.0
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ring_mat.albedo_color = Color(1.0, 0.96, 0.88, 0.96) if monochrome else Color(1.0, 0.45, 0.56, 0.96)
	var shock := MeshInstance3D.new()
	shock.mesh = ring
	shock.material_override = ring_mat
	shock.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shock.scale = Vector3(0.4, 0.8, 0.4)
	fx.add_child(shock)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.94, 0.84) if monochrome else Color(1.0, 0.55, 0.62)
	light.light_energy = 18.0
	light.omni_range = 12.0
	light.shadow_enabled = false
	fx.add_child(light)

	var shard_mesh := BoxMesh.new()
	shard_mesh.size = Vector3(0.20, 0.10, 0.32)
	var shard_mat := StandardMaterial3D.new()
	shard_mat.albedo_color = Color("090a0e")
	shard_mat.metallic = 0.35
	shard_mat.roughness = 0.42
	var tween := fx.create_tween().set_parallel(true)
	tween.tween_property(core, "scale", Vector3.ONE * 7.6, 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(core_mat, "albedo_color:a", 0.0, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(shock, "scale", Vector3(6.2, 0.16, 6.2), 0.72).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring_mat, "albedo_color:a", 0.0, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(light, "light_energy", 0.0, 0.60).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	for i in 18:
		var m := MeshInstance3D.new()
		m.mesh = shard_mesh
		m.material_override = shard_mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var angle := TAU * float(i) / 18.0 + randf_range(-0.18, 0.18)
		var dist := randf_range(3.2, 6.2)
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		m.position = dir * 0.25
		fx.add_child(m)
		tween.tween_property(m, "position", dir * dist + Vector3(0.0, randf_range(0.6, 2.6), 0.0), 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(m, "rotation", Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8)), 0.72)
		tween.tween_property(m, "scale", Vector3.ONE * 0.08, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(fx.queue_free)
