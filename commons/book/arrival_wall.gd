extends Node3D
## One set of arrival photographs per resident hall. Cameras exist only while
## exposing; the framed PNGs and their receipt survive under user://book_walls.
const Capture = preload("res://commons/book/installation_capture.gd")
signal completed(record: Dictionary)
var record: Dictionary = {}
var frames: Dictionary = {}
var output_root := "user://book_walls"
var busy := false
var finished := false

static func install(hall: Node3D, map_origin: Vector3) -> Node3D:
	# Headless validation has no rendered arrival to photograph.
	if DisplayServer.get_name() == "headless": return null
	var existing := hall.get_node_or_null("BookArrivalWall")
	if existing != null: return existing
	var map_id := str(hall.get_meta("em_map", ""))
	var path := "res://commons/maps/%s/book_images.json" % map_id
	if not FileAccess.file_exists(path): return null
	var choices: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not choices is Dictionary or not bool(choices.get("wall_works",{}).get("enabled",false)): return null
	var wall: Node3D = load("res://commons/book/arrival_wall.gd").new()
	wall.name = "BookArrivalWall"
	hall.add_child(wall)
	wall.begin.call_deferred(hall,map_origin,choices)
	return wall

func find_artifact(hall: Node, token: String) -> Node3D:
	for node in hall.find_children("*","Node3D",true,false):
		if str(node.get_meta("em_cartridge_token",node.get_meta("artifact_lookup_name",""))).split(":")[0] == token:
			return node
	return null

func begin(hall: Node3D, map_origin: Vector3, choices: Dictionary) -> void:
	if busy or finished: return
	busy = true
	var started := Time.get_ticks_msec()
	var map_id := str(hall.get_meta("em_map", ""))
	var folder := output_root.path_join(map_id).path_join("%s-%d" % [Time.get_datetime_string_from_system().replace(":","-"),Time.get_ticks_usec()])
	record = {"schema":"ada-arrival-wall/1", "map":map_id,"captured_at":Time.get_datetime_string_from_system(),
		"state_policy":"actual state; arrival unless an image waits for a full settled page; no reset, staged touch, manual advancement or seed draw",
		"images":[],"errors":[],"waiting":[],"folder":folder}
	var exposures: Array[Node] = []
	var pending: Array[Dictionary] = []
	# Freeze arrival subjects before yielding. The page remains alive until full;
	# it does not postpone the other photographs or the visitor's movement.
	for item in choices.images:
		if not item.has("wall_work"): continue
		var source := find_artifact(hall,str(item.artifact))
		if source == null:
			record.errors.append("Missing installation: " + str(item.artifact)); continue
		var choice: Dictionary = item.wall_work.duplicate(true)
		choice["id"] = item.id
		choice["artifact"] = item.artifact
		frames[item.id] = _make_frame(choice,map_origin)
		if str(choice.get("capture_when","arrival")) == "page_full":
			if not source.has_method("book_capture_ready"):
				record.errors.append("No page readiness check: " + str(item.artifact)); continue
			pending.append({"source":weakref(source),"choice":choice})
			record.waiting.append(item.id)
			var status := Label3D.new()
			status.name = "CaptureStatus"
			status.text = "Waiting for the page\nto fill."
			status.modulate = Color("62685e")
			status.outline_size = 0
			status.font_size = 36
			status.pixel_size = 0.003
			status.position.z = 0.004
			frames[item.id].add_child(status)
		else:
			exposures.append(_freeze(source,choice,started))
	for exposure in exposures: await _render_exposure(exposure,folder)
	while not pending.is_empty():
		for i in range(pending.size()-1,-1,-1):
			var item: Dictionary = pending[i]
			var source: Node3D = item.source.get_ref()
			if not is_instance_valid(source):
				record.errors.append("Installation left before capture: " + str(item.choice.artifact))
				record.waiting.erase(item.choice.id)
				pending.remove_at(i)
			elif source.book_capture_ready():
				var exposure := _freeze(source,item.choice,started)
				record.waiting.erase(item.choice.id)
				pending.remove_at(i)
				await _render_exposure(exposure,folder)
		if not pending.is_empty(): await get_tree().process_frame
	finished = true
	busy = false
	_save_record(folder)
	if not record.errors.is_empty(): push_warning("[book-wall] " + str(record.errors))
	print("[book-wall] ",record.images.size()," photographs: ",ProjectSettings.globalize_path(folder))
	completed.emit(record)

func _freeze(source: Node3D, choice: Dictionary, started: int) -> Node:
	var exposure := Capture.new()
	add_child(exposure)
	exposure.freeze(source,choice)
	exposure.receipt["captured_at"] = Time.get_datetime_string_from_system()
	exposure.receipt["after_arrival_ms"] = Time.get_ticks_msec()-started
	exposure.receipt["capture_when"] = str(choice.get("capture_when","arrival"))
	return exposure

func _render_exposure(exposure: Node, folder: String) -> void:
	var result: Dictionary = await exposure.render(folder)
	if result.ok:
		var item: Dictionary = result.receipt
		var print_material := StandardMaterial3D.new()
		print_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		print_material.albedo_texture = ImageTexture.create_from_image(result.image)
		frames[item.id].material_override = print_material
		frames[item.id].set_meta("book_image_sha256",item.sha256)
		var status: Node = frames[item.id].get_node_or_null("CaptureStatus")
		if status != null: status.queue_free()
		record.images.append(item)
	else:
		record.errors.append(result.error)
	exposure.queue_free()
	_save_record(folder)

func _save_record(folder: String) -> void:
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK:
		var file := FileAccess.open(folder.path_join("capture.json"),FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(record,"  "))

func _box(parent: Node3D, size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new(); mesh.size = size
	instance.mesh = mesh
	var material := StandardMaterial3D.new(); material.albedo_color = colour; material.roughness = 0.9
	instance.material_override = material
	instance.position = at
	parent.add_child(instance)
	return instance

func _make_frame(choice: Dictionary, map_origin: Vector3) -> MeshInstance3D:
	var mount := Node3D.new()
	mount.name = str(choice.id) + "Frame"
	add_child(mount)
	var wall: Dictionary = choice.wall
	mount.global_position = map_origin + Capture.vector(wall.position)
	mount.rotation.y = deg_to_rad(float(wall.yaw_degrees))
	var w := float(wall.get("width",1.6))
	var h := w * 0.75
	_box(mount,Vector3(w+0.18,h+0.18,0.035),Vector3.ZERO,Color("f3f0e7"))
	for x in [-1,1]: _box(mount,Vector3(0.025,h+0.23,0.055),Vector3(x*(w+0.205)*0.5,0,0.01),Color("27302c"))
	for y in [-1,1]: _box(mount,Vector3(w+0.23,0.025,0.055),Vector3(0,y*(h+0.205)*0.5,0.01),Color("27302c"))
	var print_surface := MeshInstance3D.new()
	var quad := QuadMesh.new(); quad.size = Vector2(w,h)
	print_surface.mesh = quad
	print_surface.position.z = 0.022
	var blank := StandardMaterial3D.new(); blank.albedo_color = Color("f3f0e7")
	print_surface.material_override = blank
	mount.add_child(print_surface)
	return print_surface
