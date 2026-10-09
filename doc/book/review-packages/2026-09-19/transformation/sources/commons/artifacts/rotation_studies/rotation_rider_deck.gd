extends Node3D
## Upright end-platform. Rotation supplies the arc; counter-rotation keeps its
## surface level. Only supported feet receive each tick's displacement.
const SIZE := Vector3(2.0,0.2,2.0)
var riders: Array[CharacterBody3D] = []
var deck_body: StaticBody3D
var detector: Area3D
var blocked_until: Dictionary = {}
var along_z := true
var color := Color(0.9,0.65,0.3)

func _ready() -> void:
	deck_body = StaticBody3D.new()
	deck_body.name = "DeckBody"
	deck_body.collision_layer = 1
	deck_body.collision_mask = 0
	add_child(deck_body)
	_box(deck_body,SIZE,Vector3(0,-0.1,0),color,true)
	# Side rails leave both boarding ends open. The axle-side gap separates the
	# upright rider from the blade as it passes through vertical.
	for side in [-1.0,1.0]:
		var rail_at := Vector3(side*0.96,0.75,0) if along_z else Vector3(0,0.75,side*0.96)
		var rail_size := Vector3(0.05,0.05,1.8) if along_z else Vector3(1.8,0.05,0.05)
		_box(deck_body,rail_size,rail_at,Color("e3d7b7"),true)
		for end in [-0.75,0.75]:
			var post := Vector3(side*0.96,0.35,end) if along_z else Vector3(end,0.35,side*0.96)
			_box(deck_body,Vector3(0.04,0.7,0.04),post,Color("e3d7b7"),true)
	var label := Label3D.new()
	label.text = "STAND / RIDE"
	label.font_size = 26
	label.pixel_size = 0.002
	label.position.y = 0.009
	label.rotation_degrees = Vector3(-90,180 if along_z else 90,0)
	add_child(label)
	detector = Area3D.new()
	detector.name = "FeetDetection"
	detector.collision_layer = 0
	detector.collision_mask = 1 | (1 << 19)
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(2.1,0.5,2.1)
	shape.shape = bounds
	shape.position.y = 0.18
	detector.add_child(shape)
	add_child(detector)

func _is_player(body: Node3D) -> bool:
	return body is XRToolsPlayerBody or body.is_in_group("em_walker") or body.is_in_group("player") or body.is_in_group("player_body")

func _supported(body: CharacterBody3D, boarding: bool) -> bool:
	var feet := to_local(body.global_position)
	var rising := body.velocity.y
	if body is XRToolsPlayerBody: rising = (body.velocity-body.ground_velocity).dot(body.up_player)
	return feet.y >= -0.06 and feet.y <= 0.16 and absf(feet.x) < 0.96 and absf(feet.z) < 0.96 and (not boarding or rising <= 0.25)

func _release(body: CharacterBody3D) -> void:
	riders.erase(body)
	if is_instance_valid(body) and body is XRToolsPlayerBody:
		var callback := _jumped.bind(body)
		if body.player_jumped.is_connected(callback): body.player_jumped.disconnect(callback)

func _jumped(body: CharacterBody3D) -> void:
	blocked_until[body.get_instance_id()] = Time.get_ticks_msec() + 400
	_release(body)

func transport_to(next_position: Vector3) -> void:
	if not is_instance_valid(detector):
		position = next_position
		return
	for index in range(riders.size()-1,-1,-1):
		if not is_instance_valid(riders[index]): riders.remove_at(index)
		elif not _supported(riders[index],false): _release(riders[index])
	for candidate in detector.get_overlapping_bodies():
		if not candidate is CharacterBody3D or not _is_player(candidate) or riders.has(candidate): continue
		if Time.get_ticks_msec() < int(blocked_until.get(candidate.get_instance_id(),0)): continue
		if _supported(candidate,true):
			riders.append(candidate)
			if candidate is XRToolsPlayerBody: candidate.player_jumped.connect(_jumped.bind(candidate))
	var before := global_position
	position = next_position
	force_update_transform()
	deck_body.force_update_transform()
	var movement := global_position-before
	for rider in riders:
		if movement.is_zero_approx(): continue
		if rider is XRToolsPlayerBody:
			var pose: Transform3D = rider.global_transform
			pose.origin += movement
			rider.teleport(pose)
			# Rebase only this support: XRTools otherwise applies the same
			# moving-ground delta again after we move body and tracking origin.
			var ground: Node3D = rider.get("_previous_ground_node") as Node3D
			if is_instance_valid(ground) and is_ancestor_of(ground):
				rider.velocity -= rider.ground_velocity
				rider.ground_velocity = Vector3.ZERO
				rider.set("_previous_ground_global",ground.to_global(rider.get("_previous_ground_local")))
		else:
			rider.global_position += movement

func _exit_tree() -> void:
	for rider in riders.duplicate():
		if is_instance_valid(rider): _release(rider)
	riders.clear()

func _box(parent: Node3D, size: Vector3, at: Vector3, tint: Color, solid: bool) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.6
	mesh.material_override = material
	parent.add_child(mesh)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		collision.position = at
		parent.add_child(collision)
