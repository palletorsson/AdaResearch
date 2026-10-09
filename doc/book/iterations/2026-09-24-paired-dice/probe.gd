extends SceneTree
var checks: Array = []
var failures: Array[String] = []
var artifact: Node3D
func _initialize() -> void:
	call_deferred("run")
func check(label: String, good: bool, detail: Variant = null) -> void:
	checks.append({"name":label,"passed":good,"detail":detail})
	if not good: failures.append(label)
func drop_face(index: int, face: int) -> void:
	var tray: Node3D = artifact.trays[index]
	var body: RigidBody3D = tray._dice_body
	body.freeze = true
	tray.on_desktop_grab(null)
	body.global_transform = Transform3D(Basis(Quaternion(tray.FACE_NORMALS[face-1],Vector3.UP)),tray.to_global(Vector3(0,1.12,0)))
	body.linear_velocity = Vector3.ZERO
	body.angular_velocity = Vector3.ZERO
	await physics_frame
	body.freeze = false
	tray.on_desktop_drop(null)
	for i in range(720):
		await physics_frame
		if not tray._is_rolling: break
	check("physical drop %d reads face %d" % [index,face],tray._last_result == face and not tray._is_rolling,tray._last_result)
func run() -> void:
	artifact = load("res://commons/artifacts/paired_dice_column/paired_dice_column.tscn").instantiate()
	artifact.position = Vector3(17,0,-12)
	artifact.rotation.y = PI
	root.add_child(artifact)
	await create_timer(0.2).timeout
	check("starts empty, no invented pair",artifact.total_pairs == 0 and artifact.history.is_empty())
	check("both dice use existing XRToolsPickable",artifact.trays[0]._dice_body.get_script().resource_path.ends_with("pickable.gd") and artifact.trays[1]._dice_body.get_script().resource_path.ends_with("pickable.gd"))
	var a: Node3D = artifact.trays[0]
	var b: Node3D = artifact.trays[1]
	a._dice_body.freeze = true
	a.on_desktop_grab(null)
	await create_timer(1.8).timeout
	check("held die cannot count",artifact.pending[0] == 0 and a._total_rolls == 0)
	await drop_face(0,3)
	check("one settled die is not a pair",artifact.total_pairs == 0 and artifact.pending[0] == 3)
	await drop_face(1,4)
	check("3 plus 4 commits exactly once",artifact.total_pairs == 1 and artifact.last_pair == Vector2i(3,4),artifact.get_state())
	check("seven full-size unit meshes",artifact._column.find_children("Unit_*","MeshInstance3D",false,false).size() == 7)
	var support: BoxShape3D = artifact._column.get_node("ColumnSupport").get_child(0).shape
	check("support height follows sum",is_equal_approx(support.size.y,7*0.18))
	artifact._on_landed(4,1)
	check("duplicate landing cannot duplicate pair",artifact.total_pairs == 1)
	await drop_face(0,5)
	check("new pair cannot reuse previous B",artifact.total_pairs == 1 and artifact.pending[1] == 0)
	await drop_face(1,2)
	check("different ingredients give same total",artifact.total_pairs == 2 and artifact.last_pair == Vector2i(5,2))
	check("both decompositions retained",artifact.history == [Vector2i(3,4),Vector2i(5,2)])
	check("paired variant creates no reward bodies",a._reward_balls.is_empty() and b._reward_balls.is_empty())
	artifact.return_dice()
	await create_timer(1.6).timeout
	check("return adds no throw or pair",artifact.total_pairs == 2 and artifact.pending == [0,0])
	check("return respects transformed host",a._dice_body.global_position.distance_to(a.to_global(Vector3(0,0.97,0))) < 0.1)
	a._dice_body.freeze = true
	a.on_desktop_grab(null)
	a._dice_body.global_position = a.to_global(Vector3(6,-2,0))
	await create_timer(1.2).timeout
	check("held far-away die is never reclaimed",a.to_local(a._dice_body.global_position).x > 5)
	a._dice_body.freeze = false
	a.on_desktop_drop(null)
	await create_timer(2.2).timeout
	check("fallen die returns without a pair",a.to_local(a._dice_body.global_position).length() < 1.2 and artifact.total_pairs == 2)
	# Neither boot nor return has drawn a random result. For transactional checks,
	# explicitly inject release/land events; these are not physical throw evidence.
	artifact._on_released(0)
	artifact._on_landed(2,0)
	artifact._on_lifted(0)
	artifact._on_released(1)
	artifact._on_landed(6,1)
	check("lifting a pending die invalidates its old face",artifact.total_pairs == 2 and artifact.pending == [0,6])
	artifact.clear_record()
	artifact._on_landed(5,0)
	artifact._on_landed(5,1)
	check("clear cancels in-flight stale results",artifact.total_pairs == 0 and artifact.history.is_empty())
	for i in range(15):
		artifact._on_released(0)
		artifact._on_released(1)
		artifact._on_landed(i%6+1,0)
		artifact._on_landed(6-i%6,1)
	check("history bounded to twelve without losing total",artifact.history.size() == 12 and artifact.total_pairs == 15)
	check("history uses two multimeshes",artifact._record.find_children("*","MultiMeshInstance3D",false,false).size() == 2)
	artifact.clear_record()
	check("clear removes geometry and record",artifact._column.get_child_count() == 0 and artifact._record.get_child_count() == 0 and artifact.total_pairs == 0)
	await drop_face(0,3)
	await drop_face(1,4)
	await drop_face(0,5)
	await drop_face(1,2)
	var report := {"checks":checks,"failures":failures,"state":artifact.get_state(),"scope":"Controlled native physics drops on production trays at a translated, rotated host; injected events separately test pair transactions. No tracked headset or fairness claim."}
	var file := FileAccess.open("res://doc/book/iterations/2026-09-24-paired-dice/native-checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("PAIRED DICE ",checks.size()," checks; failures: ",failures)
	quit(0 if failures.is_empty() else 1)
