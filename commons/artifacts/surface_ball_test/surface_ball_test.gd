extends Node3D
## Repeatable gravity-point test: equal white spheres, equal release height,
## no launch force. Contact and rolling make a surface's shape tangible.
@export var auto_trigger := false
@export var footprint := Vector2(3.2,2.0)
@export var drop_height := 3.0
@export var radius := .10
@export var lifetime := 12.0
var balls: Array[RigidBody3D] = []
var elapsed := 0.0
var cooldown := 0.0
var releases := 0
var contacts: Dictionary = {}
var armed := false
var target_surface: Node3D
var mesh: SphereMesh
var finish: StandardMaterial3D

func _ready() -> void:
	target_surface = get_parent() as Node3D
	mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2
	mesh.radial_segments = 24
	mesh.rings = 12
	finish = StandardMaterial3D.new()
	finish.albedo_color = Color.WHITE
	finish.roughness = .3
	finish.metallic = 0.0

func drop(surface: Node3D, points: Array[Vector3] = []) -> bool:
	if cooldown>0.0: return false
	clear()
	if points.is_empty():
		for z in range(3):
			for x in range(5): points.append(Vector3((x-2)*footprint.x/4,0,(z-1)*footprint.y/2))
	# A horizontal release plane above the highest sample makes the fall visible.
	# The points keep their plan positions; they are never launched along a normal.
	var release_y := -INF
	for point in points: release_y = maxf(release_y,surface.to_global(point).y)
	release_y += drop_height
	for i in points.size():
		var ball := RigidBody3D.new()
		ball.name = "GravityPoint%d" % i
		# Surface and other test balls only. They cannot obstruct the player's rig.
		ball.collision_layer = 1<<25
		ball.collision_mask = 1|(1<<25)
		ball.mass = .15
		ball.continuous_cd = true
		ball.contact_monitor = true
		ball.max_contacts_reported = 6
		var physics := PhysicsMaterial.new()
		physics.friction = .25
		physics.bounce = .08
		ball.physics_material_override = physics
		var collision := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = radius
		collision.shape = sphere
		ball.add_child(collision)
		var visible_ball := MeshInstance3D.new()
		visible_ball.name = "WhitePoint"
		visible_ball.mesh = mesh
		visible_ball.material_override = finish
		ball.add_child(visible_ball)
		var release := surface.to_global(points[i])
		release.y = release_y
		ball.position = to_local(release)
		ball.body_entered.connect(func(other): contacts[other.get_instance_id()] = str(other.get_path()))
		add_child(ball)
		balls.append(ball)
	elapsed = 0.0
	cooldown = 3.0
	releases += 1
	return true

func clear() -> void:
	for ball in balls:
		if is_instance_valid(ball): ball.queue_free()
	balls.clear()
	contacts.clear()

func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0,cooldown-delta)
	if not balls.is_empty():
		elapsed += delta
		if elapsed>=lifetime: clear()
	if not auto_trigger or target_surface == null: return
	var body: CharacterBody3D
	var tower := get_tree().get_first_node_in_group("void_game")
	if tower != null:
		if not tower.ready_for_play or tower.recovering: return
		body = tower.body
	else:
		for candidate in get_tree().get_nodes_in_group("player_body"):
			if candidate is CharacterBody3D and candidate.can_process(): body = candidate;break
	if body == null: return
	var at := target_surface.to_local(body.global_position)
	var size: Vector2 = target_surface.get("space_size") if target_surface.get("space_size") is Vector2 else footprint
	if absf(at.x)>size.x/2 or absf(at.z)>size.y/2 or absf(at.y)>5:
		armed = false
		return
	var query := PhysicsRayQueryParameters3D.create(body.global_position+Vector3.UP*.12,body.global_position-Vector3.UP*.3,1)
	query.exclude = [body.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var on_surface: bool = not hit.is_empty() and target_surface.is_ancestor_of(hit.collider)
	if on_surface: armed = true
	elif armed:
		armed = false
		var points: Array[Vector3] = []
		for z in range(3):
			for x in range(5): points.append(Vector3(at.x+(x-2)*.45,at.y,(z-1)*.45+at.z))
		drop(target_surface,points)
