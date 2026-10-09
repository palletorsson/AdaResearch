extends Node3D
## Reversible tool response for an existing artifact, independent of inheritance.
## Tool-only surface colliders follow meshes; original player/grab shapes stay
## intact. Breaks retain the scene and restore its pre-hit state after a delay.
signal reacted(tool: StringName, world_point: Vector3, mode: StringName)
signal broken
signal rebuilt
const HIT_LAYER := 1 << 23
const META := &"ada_artifact_reaction"
const MAX_DEBRIS := 16
var target: Node3D
var policy := "break"
var rebuild_seconds := 8.0
var health := 3
var is_destroyed := false
var surfaces: Array[Dictionary] = []
var _saved: Array[Dictionary] = []
var _motion: Array[Dictionary] = []
var _modes: Array[Dictionary] = []
var _colours: Array[Dictionary] = []
var _debris: Array[Node3D] = []
var _fragment_tweens: Array[Tween] = []
var _remaining := 0.0
var _scan_clock := 0.0
var _target_visible := true
var _target_process := Node.PROCESS_MODE_INHERIT
var _last_melee := -1000

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("artifact_reactions")
	_scan()

func _process(delta: float) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		queue_free()
		return
	if _remaining > 0:
		_remaining -= delta
		if _remaining <= 0:
			if is_destroyed and _player_in_return_space(): _remaining = 0.5
			else: restore()
	_scan_clock -= delta
	if _scan_clock <= 0:
		_scan_clock = 0.25
		if not is_destroyed: _scan()

func _scan() -> void:
	# Rebuilt procedural meshes should not leave an ever-growing lookup list.
	for i in range(surfaces.size() - 1, -1, -1):
		if not is_instance_valid(surfaces[i].mesh.get_ref()) or not is_instance_valid(surfaces[i].body.get_ref()):
			surfaces.remove_at(i)
	# Do not cross into a monitor's private filming world or target controls.
	var pending: Array[Node] = [target]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is SubViewport or node == self or node.is_queued_for_deletion(): continue
		if node is MeshInstance3D and node.mesh != null:
			_bind_mesh(node)
		for child in node.get_children():
			if not child.has_meta("reaction_surface"): pending.append(child)
	for item in surfaces:
		var mesh: MeshInstance3D = item.mesh.get_ref()
		var body: StaticBody3D = item.body.get_ref()
		if not is_instance_valid(mesh) or not is_instance_valid(body): continue
		var bounds := mesh.get_aabb()
		body.position = bounds.get_center()
		var size := bounds.size.max(Vector3.ONE * 0.025)
		if not (item.shape as BoxShape3D).size.is_equal_approx(size):
			(item.shape as BoxShape3D).size = size
		body.collision_layer = HIT_LAYER if mesh.is_visible_in_tree() else 0

func _bind_mesh(mesh: MeshInstance3D) -> void:
	if mesh.has_meta("reaction_surface_bound"): return
	mesh.set_meta("reaction_surface_bound", true)
	var body := StaticBody3D.new()
	body.name = "ToolHitSurface"
	body.set_meta("reaction_surface", true)
	body.set_meta(META, weakref(self))
	body.collision_layer = HIT_LAYER
	body.collision_mask = 0
	var shape := BoxShape3D.new()
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	mesh.add_child(body)
	surfaces.append({"mesh":weakref(mesh),"body":weakref(body),"shape":shape})
	# A measuring instrument must not burn its own handle.
	for ray in target.find_children("*", "RayCast3D", true, false): ray.add_exception(body)

## Common interaction entry point. The pink gun retains its colour-only nature.
func react(tool: StringName, at: Vector3, colour: Color = Color("ed9fc5"), strength: float = 1.0, mode: StringName = &"") -> bool:
	if not is_instance_valid(target) or is_destroyed: return false
	if tool == &"melee":
		var now := Time.get_ticks_msec()
		if now - _last_melee < 250: return false
		_last_melee = now
	reacted.emit(tool, at, mode)
	_tint(colour)
	_remaining = rebuild_seconds
	if policy == "colour" or tool in [&"catalyst", &"gun"]: return true
	if tool == &"laser": health = 0
	else: health -= maxi(1, int(ceil(strength)))
	if health <= 0: _break(at, colour)
	return true

func _tint(colour: Color) -> void:
	for item in surfaces:
		var mesh: MeshInstance3D = item.mesh.get_ref()
		if not is_instance_valid(mesh): continue
		if not mesh.has_meta("reaction_tinted"):
			_colours.append({"node":weakref(mesh),"overlay":mesh.material_overlay})
			mesh.set_meta("reaction_tinted", true)
		var overlay := StandardMaterial3D.new()
		overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		overlay.albedo_color = Color(colour, 0.64)
		overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material_overlay = overlay

func _break(at: Vector3, colour: Color) -> void:
	is_destroyed = true
	_target_visible = target.visible
	_target_process = target.process_mode
	# Drop through the original pickup API before suspending its physics.
	var nodes: Array[Node] = [target]
	nodes.append_array(target.find_children("*", "", true, false))
	for node in nodes:
		if node.has_method("is_picked_up") and node.call("is_picked_up") and node.has_method("drop"):
			node.call("drop")
	for node in nodes:
		if node.process_mode != Node.PROCESS_MODE_INHERIT:
			_modes.append({"node":weakref(node),"mode":node.process_mode})
			node.process_mode = Node.PROCESS_MODE_DISABLED
		if node is RigidBody3D:
			_motion.append({"node":weakref(node),"pose":node.global_transform,"freeze":node.freeze})
			node.freeze = true
			node.linear_velocity = Vector3.ZERO
			node.angular_velocity = Vector3.ZERO
		if node is CollisionObject3D:
			_saved.append({"node":weakref(node),"layer":node.collision_layer,"mask":node.collision_mask})
			node.collision_layer = 0
			node.collision_mask = 0
	target.visible = false
	target.process_mode = Node.PROCESS_MODE_DISABLED
	_make_debris(at, colour)
	broken.emit()

func _make_debris(at: Vector3, colour: Color) -> void:
	# Bounded illustrative fragments, not a claim of mesh/CSG fracture.
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.45
	for i in range(MAX_DEBRIS):
		var piece := MeshInstance3D.new()
		var shape := BoxMesh.new()
		shape.size = Vector3(0.025, 0.025, 0.10 + 0.02 * (i % 5))
		piece.mesh = shape
		piece.material_override = material
		add_child(piece)
		piece.global_position = at
		piece.rotation = Vector3(i * 0.3, i * 0.6, i * 0.4)
		_debris.append(piece)
		var angle := i * 2.39996
		var offset := Vector3(cos(angle), 0.5 + float(i % 3) * 0.2, sin(angle)) * 0.45
		var tween := create_tween()
		_fragment_tweens.append(tween)
		tween.tween_property(piece,"global_position",at+offset,0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece,"global_position",at+Vector3(offset.x,-0.3,offset.z),0.5)
		tween.tween_property(piece,"scale",Vector3.ONE*0.001,0.4).set_delay(1.0)
		tween.tween_callback(piece.queue_free)

## Restore the same scene and its authored interactions; never replace its script.
func restore() -> void:
	if not is_instance_valid(target): return
	for item in _colours:
		var mesh: MeshInstance3D = item.node.get_ref()
		if is_instance_valid(mesh):
			mesh.material_overlay = item.overlay
			mesh.remove_meta("reaction_tinted")
	_colours.clear()
	for item in _motion:
		var body: RigidBody3D = item.node.get_ref()
		if is_instance_valid(body):
			body.global_transform = item.pose
			PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,item.pose)
			body.freeze = item.freeze
	_motion.clear()
	for item in _modes:
		var node: Node = item.node.get_ref()
		if is_instance_valid(node): node.process_mode = item.mode
	_modes.clear()
	for item in _saved:
		var body: CollisionObject3D = item.node.get_ref()
		if is_instance_valid(body):
			body.collision_layer = item.layer
			body.collision_mask = item.mask
	_saved.clear()
	if is_destroyed:
		target.visible = _target_visible
		target.process_mode = _target_process
	for tween in _fragment_tweens:
		if tween.is_valid(): tween.kill()
	_fragment_tweens.clear()
	for piece in _debris:
		if is_instance_valid(piece): piece.queue_free()
	_debris.clear()
	is_destroyed = false
	health = 3
	_remaining = 0
	_scan()
	rebuilt.emit()

func _player_in_return_space() -> bool:
	# Never rebuild a physical barrier through the visitor. Tool-only proxies
	# do not count, and the check is dormant until a rebuild is actually due.
	for item in _saved:
		if (int(item.layer) & 7) == 0: continue
		var body: CollisionObject3D = item.node.get_ref()
		if not is_instance_valid(body): continue
		for child in body.get_children():
			if child is CollisionShape3D and child.shape != null and not child.disabled:
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape = child.shape
				query.transform = child.global_transform
				query.collision_mask = (1 << 19) | 1
				# The museum Walker shares layer 1 with the floor. Filter actual
				# visitors so architecture cannot postpone restoration forever.
				for hit in get_world_3d().direct_space_state.intersect_shape(query,32):
					var visitor: Node = hit.collider
					if (int(visitor.collision_layer) & (1 << 19)) != 0: return true
					if visitor.is_in_group("em_walker") or visitor.is_in_group("player_body") or visitor.is_in_group("player") or visitor.is_in_group("vr_player"): return true
					while visitor != null:
						if visitor is XROrigin3D: return true
						visitor = visitor.get_parent()
	return false

func _exit_tree() -> void:
	# Removing only this behaviour must also give a surviving target back.
	if is_instance_valid(target) and target.is_inside_tree() and not target.is_queued_for_deletion():
		restore()
	for item in surfaces:
		var mesh: MeshInstance3D = item.mesh.get_ref()
		var body: StaticBody3D = item.body.get_ref()
		if is_instance_valid(mesh): mesh.remove_meta("reaction_surface_bound")
		if is_instance_valid(body): body.queue_free()
	if is_instance_valid(target): target.remove_meta(META)
