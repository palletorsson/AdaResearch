extends SceneTree
var checks: Array = []
var failures: Array = []
var artifact: Node3D
var pointer: Node3D
var event_script
func _initialize() -> void: call_deferred("run")
func check(title: String, good: bool) -> void:
	checks.append({"name":title,"passed":good})
	if not good: failures.append(title)
func button(index: int) -> void:
	var target: Node3D = artifact.find_child("Btn_%d"%index,true,false).get_node("InteractableAreaButton")
	for kind in [2,3]: target.pointer_event(event_script.new(kind,pointer,target,target.global_position,target.global_position))
func drop_face(face: int) -> void:
	var tray: Node3D = artifact.tray
	var body: RigidBody3D = tray._dice_body
	body.freeze = true
	tray.on_desktop_grab(null)
	await physics_frame
	await process_frame
	body.global_transform = Transform3D(Basis(Quaternion(tray.FACE_NORMALS[face-1],Vector3.UP)),tray.to_global(Vector3(0,1.12,0)))
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	await physics_frame
	await process_frame
	body.sleeping = false
	body.freeze = false
	# A controlled drop removes velocity inferred from moving the frozen body.
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	tray.on_desktop_drop(null)
	for i in range(720):
		await physics_frame
		if not tray._is_rolling: break
	check("physical drop reads face %d"%face,tray._last_result==face and not tray._is_rolling)
func run() -> void:
	event_script = load("res://addons/godot-xr-tools/events/pointer_event.gd")
	artifact = load("res://commons/artifacts/continuing_die/continuing_die.tscn").instantiate()
	artifact.position = Vector3(17,0,-12)
	artifact.rotation.y = PI
	root.add_child(artifact)
	pointer = Node3D.new();root.add_child(pointer)
	await create_timer(0.2).timeout
	check("initial live chain empty while example is separate",artifact.chain.is_empty() and artifact.total==0 and artifact.example_column.get_child_count()==3)
	check("reuses production pickable die",artifact.tray._dice_body.get_script().resource_path.ends_with("pickable.gd"))
	artifact.tray._dice_body.freeze = true
	artifact.tray.on_desktop_grab(null)
	await create_timer(1).timeout
	check("held die cannot create a landing",artifact.chain.is_empty())
	await drop_face(6)
	check("six records height and permits continuation",artifact.chain==[6] and artifact.total==6 and not artifact.closed and not artifact.capped)
	artifact._on_landed(6)
	check("one release cannot count twice",artifact.chain==[6])
	button(0)
	await create_timer(1).timeout
	check("return button preserves chain and adds no throw",artifact.chain==[6] and not artifact.armed)
	await drop_face(6)
	await drop_face(3)
	check("6 + 6 + 3 closes at fifteen",artifact.chain==[6,6,3] and artifact.total==15 and artifact.closed and not artifact.capped)
	check("each throw has a distinct labelled section",artifact.live_column.find_children("Throw_*","Node3D",false,false).size()==3)
	var shape: BoxShape3D = artifact.live_column.get_node("ColumnSupport").get_child(0).shape
	check("physical column height matches total",absf(shape.size.y-1.35)<0.0001)
	var complete: Dictionary = artifact.get_state()
	await drop_face(6)
	check("completed chain refuses further throws",artifact.chain==[6,6,3] and artifact.total==15)
	button(1)
	check("NEW CHAIN clears live column only",artifact.chain.is_empty() and artifact.live_column.get_child_count()==0 and artifact.example_column.get_child_count()==3)
	# Controlled physical drops test the explicit display boundary.
	for i in range(5): await drop_face(6)
	check("five sixes reach a labelled unfinished limit",artifact.total==30 and artifact.capped and not artifact.closed and artifact.status.text.contains("UNFINISHED"))
	check("display ceiling bounds generated geometry",artifact.live_column.find_children("Throw_*","Node3D",false,false).size()==5 and absf(artifact.get_state().height-2.7)<0.001)
	var capped_state: Dictionary = artifact.get_state()
	await drop_face(2)
	check("unfinished cap refuses sixth throw",artifact.chain==[6,6,6,6,6] and artifact.total==30)
	button(1)
	# These release/landing injections test transaction edge cases, not physical evidence.
	for value in [6,6,6,6,2]:
		artifact._on_released();artifact._on_landed(value)
	check("non-six at fifth throw finishes rather than caps",artifact.closed and not artifact.capped and artifact.total==26)
	button(1)
	artifact._on_released();button(1);artifact._on_landed(6)
	check("new chain invalidates in-flight stale result",artifact.chain.is_empty())
	artifact._on_released();artifact._on_landed(0);artifact._on_landed(7)
	check("invalid faces are not recorded",artifact.chain.is_empty())
	button(1)
	# Let the preceding return finish its deferred unfreeze before a new grab.
	await process_frame
	await physics_frame
	artifact.tray._dice_body.freeze = true
	artifact.tray.on_desktop_grab(null)
	artifact.tray._dice_body.global_position = artifact.tray.to_global(Vector3(3,2,0))
	var held_position: Vector3 = artifact.tray._dice_body.global_position
	button(1)
	await create_timer(0.1).timeout
	check("NEW CHAIN never takes a held die from the hand",artifact.tray._dice_body.freeze and artifact.tray._dice_body.global_position.distance_to(held_position)<0.0001)
	await drop_face(4)
	check("release after held reset starts the new chain",artifact.chain==[4] and artifact.closed)
	button(1)
	artifact.tray._dice_body.freeze = true
	artifact.tray.on_desktop_grab(null)
	artifact.tray._dice_body.global_position = artifact.tray.to_global(Vector3(0,-2,0))
	artifact.tray._dice_body.freeze = false
	artifact.tray.on_desktop_drop(null)
	await create_timer(2).timeout
	check("fallen die returns without inventing a throw",artifact.chain.is_empty() and artifact.tray.to_local(artifact.tray._dice_body.global_position).y>0.8 and not artifact.armed)
	check("variant spawns no reward rain",artifact.tray._reward_balls.is_empty())
	FileAccess.open("res://doc/book/iterations/2026-09-24-continuing-die/native-checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"complete_physical_chain":complete,"capped_physical_chain":capped_state,"scope":"Controlled native physics drops on the shipped die at a translated, rotated host. Pointer buttons are production controls. Transaction-only injections are identified in probe.gd. No headset input or fairness measurement."},"  "))
	print("CONTINUING DIE ",checks.size()," CHECKS; FAILURES ",failures)
	quit(0 if failures.is_empty() else 1)
