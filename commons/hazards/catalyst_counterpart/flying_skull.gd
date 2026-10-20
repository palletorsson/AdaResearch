extends CharacterBody3D
const BALL := preload("res://commons/hazards/catalyst_counterpart/head_ball.gd")
## Experimental counterpart: the visitor and the form share operations.
## A catalyst hit interrupts behaviour; it does not determine a relationship.
signal interrupted
signal tagged
signal defeated
signal ball_hit_player(body: Node3D)

enum State { WATCH, TELEGRAPH, DASH, RECOVER, INTERRUPTED }
const RADIUS := 0.30
const WINDUP := 1.2
const SPEED := 2.2
var state := State.WATCH
var active := false
var power := 1
var elapsed := 0.0
var phase := 0.0
var destination := Vector3.ZERO
var interruptions := 0
var tags := 0
var target_override: Node3D
var visual := Node3D.new()
var boundary := SphereShape3D.new()
var eye_material := StandardMaterial3D.new()
var cue := MeshInstance3D.new()
var size_factor := 1.0
var flame: CPUParticles3D
## Host-defined terrain and extent; defaults retain the original museum trial.
var home_position := Vector3(0, 1.65, -3.5)
var travel_bounds := AABB(Vector3(-2, 0.75, -6), Vector3(4, 1.65, 6.7))
var target_y_limits := Vector2(0.8, 2.2)
var ground_height: Callable
## Combat is enabled by the biome host; earlier nonlethal studies keep their rule.
var combat_enabled := false
var destroyed := false
var incoming_hits := 0
var projectiles: Array[Node3D] = []
var explosion: CPUParticles3D

func _ready() -> void:
	name = "FlyingCounterpart"
	collision_layer = 2 # Existing catalyst projectiles address this layer.
	collision_mask = 1 # Architecture, never an invisible wall for the visitor.
	add_to_group("catalyst_counterpart")
	var collision := CollisionShape3D.new()
	boundary.radius = RADIUS
	collision.shape = boundary
	add_child(collision)
	add_child(visual)
	var bone := _material(Color(0.73, 0.72, 0.68), 0.5)
	var dark := _material(Color(0.025, 0.026, 0.03), 0.3)
	# A faceted cranium, inset-looking dark sockets, cheekbones and an open jaw.
	var cranium := SphereMesh.new()
	cranium.radius = 0.27; cranium.height = 0.49
	cranium.radial_segments = 12; cranium.rings = 6
	_mesh(cranium, bone, Vector3(0, 0.06, 0), Vector3(1, 1, 0.84))
	for side in [-1.0, 1.0]:
		var socket := SphereMesh.new()
		socket.radius = 0.105; socket.height = 0.19
		socket.radial_segments = 8; socket.rings = 4
		_mesh(socket, dark, Vector3(side * 0.115, 0.065, -0.188), Vector3(1, 1, 0.52))
		_box(Vector3(0.10, 0.07, 0.12), bone, Vector3(side * 0.17, -0.075, -0.12))
		var eye := SphereMesh.new()
		eye.radius = 0.025; eye.height = 0.05
		_mesh(eye, eye_material, Vector3(side * 0.115, 0.07, -0.247), Vector3.ONE)
	_box(Vector3(0.045, 0.075, 0.025), dark, Vector3(0, -0.04, -0.21))
	_box(Vector3(0.27, 0.045, 0.13), bone, Vector3(0, -0.21, -0.075))
	for x in [-0.09, -0.03, 0.03, 0.09]:
		_box(Vector3(0.035, 0.045, 0.04), bone, Vector3(x, -0.105, -0.175))
		_box(Vector3(0.035, 0.025, 0.04), bone, Vector3(x, -0.18, -0.13))
	_build_flame()
	eye_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var cue_material := _material(Color(0.85, 0.84, 0.76, 0.35), 1.0)
	cue_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cue_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cue.material_override = cue_material
	cue.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Cue belongs to the arena, so body turns cannot change its locked endpoint.
	get_parent().add_child.call_deferred(cue)
	cue.hide()
	set_power(1)

func _build_flame() -> void:
	# Pale fire keeps the early body grayscale; flame flicker is not locomotion.
	flame = CPUParticles3D.new()
	flame.name = "PaleFire"
	flame.position.y = 0.20
	flame.amount = 48; flame.lifetime = 0.8; flame.preprocess = 0.8
	flame.local_coords = true
	flame.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	flame.emission_sphere_radius = 0.20
	flame.direction = Vector3.UP; flame.spread = 12
	flame.gravity = Vector3(0, 0.5, 0)
	flame.initial_velocity_min = 0.30; flame.initial_velocity_max = 0.70
	flame.scale_amount_min = 0.045; flame.scale_amount_max = 0.095
	var size := Curve.new()
	size.add_point(Vector2(0, 0.2)); size.add_point(Vector2(0.2, 1)); size.add_point(Vector2(1, 0.01))
	flame.scale_amount_curve = size
	var colour := Gradient.new()
	colour.set_color(0, Color(0.88, 0.87, 0.83, 0.8)); colour.set_color(1, Color(0.55, 0.55, 0.53, 0))
	flame.color_ramp = colour
	var ember := SphereMesh.new()
	ember.radius = 0.45; ember.height = 3.0; ember.radial_segments = 6; ember.rings = 2
	flame.mesh = ember
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.vertex_color_use_as_albedo = true
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	flame.material_override = glow
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.add_child(flame)

func _material(colour: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour; mat.roughness = roughness
	return mat

func _mesh(mesh: Mesh, material: Material, at: Vector3, dimensions: Vector3) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh; node.material_override = material
	node.position = at; node.scale = dimensions
	visual.add_child(node)

func _box(dimensions: Vector3, material: Material, at: Vector3) -> void:
	var mesh := BoxMesh.new(); mesh.size = dimensions
	_mesh(mesh, material, at, Vector3.ONE)

func set_power(value: int) -> void:
	power = clampi(value, 1, 3)

func set_active(value: bool) -> void:
	if destroyed: return
	active = value
	state = State.RECOVER if value else State.WATCH
	elapsed = 0.0
	velocity = Vector3.ZERO
	cue.hide()

func target_position() -> Vector3:
	if is_instance_valid(target_override): return target_override.global_position
	var camera := get_viewport().get_camera_3d()
	return camera.global_position if camera != null else global_position + Vector3.FORWARD * 3.0

func _physics_process(delta: float) -> void:
	advance(delta, target_position())

func advance(delta: float, target: Vector3) -> void:
	if destroyed: return
	phase += delta
	elapsed += delta
	size_factor = 1.0 + (0.22 * (0.5 + 0.5 * sin(phase * 1.4)) if power >= 3 else 0.0)
	visual.scale = Vector3.ONE * size_factor
	boundary.radius = RADIUS * size_factor
	var pale := 1.0 if state == State.TELEGRAPH else 0.28
	eye_material.albedo_color = Color(pale, pale, pale)
	var local_target := (get_parent() as Node3D).to_local(target)
	if active and state == State.RECOVER and elapsed >= 2.0:
		begin_telegraph(local_target)
	elif state == State.TELEGRAPH and elapsed >= WINDUP:
		if combat_enabled: throw_ball()
		state = State.DASH; elapsed = 0.0; cue.hide()
	elif state == State.DASH:
		var offset := destination - position
		if offset.length() <= 0.08 or elapsed > 3.0:
			state = State.RECOVER; elapsed = 0.0
		else:
			var step := offset.normalized() * minf(SPEED * delta, offset.length())
			var collision := move_and_collide(global_basis * step)
			if collision != null:
				state = State.RECOVER; elapsed = 0.0
			# Training contact is a tag, never health damage or locomotion force.
			if global_position.distance_to(target) < boundary.radius + 0.25:
				tags += 1; tagged.emit()
				state = State.RECOVER; elapsed = 0.0
	elif state == State.INTERRUPTED and elapsed >= 2.5:
		state = State.RECOVER if active else State.WATCH
		elapsed = 0.0
	elif state in [State.WATCH, State.RECOVER]:
		var home := home_position
		if power >= 2:
			home.x += 1.15 * sin(phase * 0.6)
			home.z += 0.65 * cos(phase * 0.6)
		else: home.y += 0.10 * sin(phase * 1.5)
		if ground_height.is_valid():
			home.y = float(ground_height.call(home)) + 1.65 + (0.10 * sin(phase * 1.5) if power == 1 else 0.0)
		move_and_collide((get_parent() as Node3D).global_basis * position.direction_to(home) * minf(delta * 0.65, position.distance_to(home)))
	# Hard trial bounds: no pursuing the visitor through the museum.
	position = _bounded(position)
	if state != State.DASH and global_position.distance_to(target) > 0.1:
		visual.look_at(target, Vector3.UP)

func begin_telegraph(local_target: Vector3) -> void:
	state = State.TELEGRAPH; elapsed = 0.0
	destination = _bounded(Vector3(local_target.x, clampf(local_target.y, target_y_limits.x, target_y_limits.y), local_target.z))
	if not cue.is_inside_tree(): return
	var difference := destination - position
	var line := CylinderMesh.new()
	line.top_radius = 0.009; line.bottom_radius = 0.009
	line.height = maxf(0.01, difference.length()); line.radial_segments = 6
	cue.mesh = line
	cue.position = (position + destination) * 0.5
	var axis := difference.normalized()
	var tangent := axis.cross(Vector3.RIGHT if absf(axis.dot(Vector3.UP)) > 0.98 else Vector3.UP).normalized()
	if tangent.length_squared() > 0.0: cue.basis = Basis(tangent, axis, tangent.cross(axis)).orthonormalized()
	cue.show()

func _bounded(at: Vector3) -> Vector3:
	at = at.clamp(travel_bounds.position, travel_bounds.end)
	if ground_height.is_valid():
		at.y = maxf(at.y, float(ground_height.call(at)) + boundary.radius + 0.12)
	return at

func hit_by_catalyst_mode(_colour: Color, _mode: String) -> void:
	if destroyed or (combat_enabled and not active): return
	if state == State.INTERRUPTED and not combat_enabled: return
	interruptions += 1
	if combat_enabled: incoming_hits += 1
	state = State.INTERRUPTED; elapsed = 0.0
	velocity = Vector3.ZERO
	cue.hide()
	interrupted.emit()
	if combat_enabled and incoming_hits >= 3: explode()

func throw_ball() -> Node3D:
	if not active or destroyed: return null
	var shot: Node3D = BALL.new()
	var world_target := (get_parent() as Node3D).to_global(destination)
	shot.direction = global_position.direction_to(world_target)
	shot.position = (get_parent() as Node3D).to_local(global_position + shot.direction * 0.40)
	shot.player_hit.connect(func(body): ball_hit_player.emit(body))
	get_parent().add_child(shot)
	projectiles = projectiles.filter(func(p): return is_instance_valid(p) and not p.is_queued_for_deletion())
	if projectiles.size() >= 6: projectiles.pop_front().queue_free()
	projectiles.append(shot)
	return shot

func clear_shots() -> void:
	for shot in projectiles:
		if is_instance_valid(shot): shot.queue_free()
	projectiles.clear()

func explode() -> void:
	if destroyed: return
	destroyed = true; active = false; velocity = Vector3.ZERO
	visual.hide(); cue.hide(); collision_layer = 0; collision_mask = 0
	clear_shots()
	explosion = CPUParticles3D.new()
	explosion.name = "HeadExplosion"
	explosion.position = position
	explosion.amount = 64; explosion.lifetime = 0.85; explosion.one_shot = true
	explosion.explosiveness = 1.0; explosion.spread = 180
	explosion.initial_velocity_min = 1.5; explosion.initial_velocity_max = 3.6
	explosion.gravity = Vector3(0, -3, 0)
	explosion.scale_amount_min = 0.035; explosion.scale_amount_max = 0.10
	var fragment := BoxMesh.new(); fragment.size = Vector3.ONE
	explosion.mesh = fragment
	explosion.material_override = _material(Color(0.90, 0.86, 0.70), 0.4)
	get_parent().add_child(explosion)
	explosion.emitting = true
	defeated.emit()

func restore() -> void:
	clear_shots()
	if is_instance_valid(explosion): explosion.queue_free()
	destroyed = false; incoming_hits = 0; interruptions = 0
	collision_layer = 2; collision_mask = 1
	visual.show(); set_active(false)

func hit_by_projectile(colour: Color) -> void:
	hit_by_catalyst_mode(colour, "primitives")

func _exit_tree() -> void:
	clear_shots()
	if is_instance_valid(explosion): explosion.queue_free()
	if is_instance_valid(cue): cue.queue_free()
