extends Node3D
## Fold a net, shrink it, and leave a new rigid cube on the floor each cycle.
## Closed face geometry is copied at release; the working net opens again above it.
signal phase_changed(phase: String)
const OPEN_SECONDS := 1.4
const SHRINK_SECONDS := 0.8
const REOPEN_SECONDS := 2.0
var net: Node3D
var body: RigidBody3D
var collider: CollisionShape3D
var phase := "ARRIVE"
var elapsed := 0.0
var quiet_time := 0.0
var completed_cycles := 0
var home := Transform3D.IDENTITY
var small_pose := Transform3D.IDENTITY
var dropped_cubes: Array[RigidBody3D] = []
var produced_cubes := 0
var floor_y := 0.0
var original_root := Transform3D.IDENTITY
var decorations: Array[Node] = []
var original_materials: Dictionary = {}
var status: Label3D
var label_text := ""

func _ready() -> void:
	net = get_parent()
	original_root = net._cube_root.transform
	net.fold_progress = 0.0
	_decorate_faces()
	status = Label3D.new(); status.font_size = 42; status.pixel_size = 0.0025
	status.outline_size = 0; status.modulate = Color("403640")
	status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(status)
	_write("FOLD / SHRINK / ANOTHER")

func _decorate_faces() -> void:
	var faces: Array[Node] = net._cube_root.find_children("*","MeshInstance3D",true,false)
	var ink := StandardMaterial3D.new(); ink.albedo_color = Color("38323b"); ink.roughness = 0.6
	for i in faces.size():
		var face: MeshInstance3D = faces[i]
		original_materials[face] = face.material_override
		var skin := StandardMaterial3D.new(); skin.albedo_color = Color("d676a0") if i == faces.size()-1 else Color("eeeae1")
		skin.roughness = 0.4; skin.cull_mode = BaseMaterial3D.CULL_DISABLED
		face.material_override = skin
		var half: float = net.edge_length*0.5
		for edge in 4:
			var rail := MeshInstance3D.new(); var box := BoxMesh.new()
			box.size = Vector3(net.edge_length,0.006,0.009) if edge < 2 else Vector3(0.009,0.006,net.edge_length)
			rail.mesh = box; rail.material_override = ink
			rail.position = Vector3(0,0,half*(1 if edge == 0 else -1)) if edge < 2 else Vector3(half*(1 if edge == 2 else -1),0,0)
			face.add_child(rail); decorations.append(rail)
		var number := Label3D.new(); number.text = str(i+1); number.font_size = 36
		number.pixel_size = 0.003; number.outline_size = 0; number.modulate = Color("403640")
		number.position.y = 0.006; number.rotation.x = -PI/2
		face.add_child(number); decorations.append(number)

func _physics_process(delta: float) -> void:
	elapsed += delta
	match phase:
		"ARRIVE":
			# Placement/configuration finishes before we sample the actual hall floor.
			if elapsed < 0.25: return
			var p: Vector3 = net._cube_root.global_position
			var ray := PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.4,p+Vector3.DOWN*8.0,1)
			var hit := get_world_3d().direct_space_state.intersect_ray(ray)
			if hit.is_empty(): _write("WAITING FOR A FLOOR"); return
			floor_y = hit.position.y
			var target: Vector3 = net._cube_root.global_position
			target.y = floor_y+maxf(1.35,net.edge_length*1.95)
			net._cube_root.global_position = target; home = net._cube_root.global_transform
			status.global_position = Vector3(target.x,floor_y+0.13,target.z+1.05)
			_enter("OPEN")
		"OPEN":
			if elapsed >= OPEN_SECONDS: _enter("FOLD")
		"FOLD":
			net.fold_progress = _ease(elapsed/maxf(0.1,net.fold_duration))
			if net.fold_progress >= 1.0: _enter("CLOSED")
		"CLOSED":
			if elapsed >= 0.45: _enter("SHRINK")
		"SHRINK":
			_set_size(lerpf(1.0,net.drop_scale,_ease(elapsed/SHRINK_SECONDS)))
			if elapsed >= SHRINK_SECONDS: _release()
		"FALL":
			if body.get_contact_count() > 0 and body.linear_velocity.length() < 0.12:
				quiet_time += delta
			else: quiet_time = 0.0
			if quiet_time >= 0.3:
				_enter("THINK")
			elif elapsed > 8.0 or body.global_position.y < floor_y-2.0:
				# A removed floor never leaves an orphan endlessly falling.
				_begin_next()
		"THINK":
			_write("·".repeat(1+int(elapsed/0.55)%3))
			if elapsed >= net.think_hold: _begin_next()
		"REOPEN":
			net.fold_progress = 1.0-_ease(elapsed/REOPEN_SECONDS)
			_set_size(lerpf(net.drop_scale,1.0,_ease(elapsed/REOPEN_SECONDS)))
			if elapsed >= REOPEN_SECONDS:
				completed_cycles += 1; _enter("OPEN")

func _release() -> void:
	_trim_drops()
	produced_cubes += 1
	small_pose = net._cube_root.global_transform
	body = RigidBody3D.new(); body.name = "Cube_%03d" % produced_cubes
	body.collision_layer = 6; body.collision_mask = 7
	body.contact_monitor = true; body.max_contacts_reported = 8; body.continuous_cd = true
	var physics := PhysicsMaterial.new(); physics.bounce = 0.12; physics.friction = 0.8
	body.physics_material_override = physics
	add_child(body); body.top_level = true
	body.global_transform = Transform3D(small_pose.basis.orthonormalized(),small_pose.origin)
	var scale_size := small_pose.basis.get_scale().abs()
	collider = CollisionShape3D.new()
	var shape := BoxShape3D.new(); shape.size = scale_size*net.edge_length
	collider.shape = shape; collider.position.y = -shape.size.y*0.5
	body.add_child(collider)
	# Copy the CLOSED six-face hierarchy, including its ink edges and numbers.
	# Share mesh/material resources, but give each result its own transform/body.
	var result: Node3D = net._cube_root.duplicate(0)
	result.name = "SixFaces"; body.add_child(result); result.global_transform = small_pose
	net._cube_root.hide()
	var direction := Vector3(cos(produced_cubes*2.4),0,sin(produced_cubes*2.4))
	body.linear_velocity = direction*0.24
	body.angular_velocity = Vector3(direction.z,0.2,-direction.x)*0.3
	dropped_cubes.append(body); quiet_time = 0.0
	_enter("FALL")

func _set_size(factor: float) -> void:
	# Shrink around the cube's centre, retaining its position before the drop.
	var full_edge: float = net.edge_length*home.basis.get_scale().y
	net._cube_root.global_transform = Transform3D(home.basis*Basis.from_scale(Vector3.ONE*factor),home.origin-Vector3.UP*full_edge*(1.0-factor)*0.5)

func _begin_next() -> void:
	# The fallen cube stays on the floor. A fresh working net opens above it.
	net._cube_root.show()
	_enter("REOPEN")

func _trim_drops() -> void:
	for item in dropped_cubes.duplicate():
		if not is_instance_valid(item):
			dropped_cubes.erase(item)
		elif item.global_position.y < floor_y-2.0 or item.global_position.distance_to(home.origin)>4.0:
			dropped_cubes.erase(item); item.queue_free()
	while dropped_cubes.size() >= net.max_dropped_cubes:
		dropped_cubes.pop_front().queue_free()

func _enter(next: String) -> void:
	phase = next; elapsed = 0.0
	_write({"OPEN":"FOLLOW ONE SQUARE","FOLD":"FOLD","CLOSED":"A CUBE","SHRINK":"SMALLER","FALL":"FALL","THINK":"·","REOPEN":"ANOTHER ONE"}.get(next,next))
	phase_changed.emit(phase)

func _write(words: String) -> void:
	if words == label_text: return
	label_text = words; status.text = words

func _ease(t: float) -> float:
	return 0.5-0.5*cos(PI*clampf(t,0.0,1.0))

func dispose() -> void:
	set_physics_process(false)
	for item in dropped_cubes:
		if is_instance_valid(item): item.get_parent().remove_child(item); item.queue_free()
	dropped_cubes.clear()
	if is_instance_valid(net._cube_root):
		if net._cube_root.get_parent() != net: net._cube_root.reparent(net,true)
		net._cube_root.transform = original_root
		net._cube_root.show()
	for face in original_materials:
		if is_instance_valid(face): face.material_override = original_materials[face]
	for item in decorations:
		if is_instance_valid(item): item.get_parent().remove_child(item); item.queue_free()
