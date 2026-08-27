extends SceneTree
## THE SPIDER IN THE MUSEUM'S FIRST HALL (2026-08-27, Palle: "can we see the
## spider in the endless museum map one for testing").
##
## It is baked into two authored halls — primitives/point one and forces/vfm 08
## arena — and baked is not the same as seen. This builds the primitives chapter
## forward until the "point one" hall exists, drains the patient stamp queue so
## nothing is still owed, finds the head_crab, and photographs it where it
## stands.
##
## IT INJECTS ITS OWN CONTROL FILE. ada_run/em_control.json currently holds a
## live resume (_resume_hall VFM_06_Springs, first_chapter forces) and Palle
## plays the desktop museum while probes run. endless_museum.gd:385 documents
## the rule in its own words: a probe sets EM_CONTROL on the instance so a test
## run never writes the file the user's live session is reading. Nothing here
## touches the live file.
const TRIAL := "res://ada_run/_trial_em_control.json"
const OUT := "res://ada_run/museum_crab"
const WANT_MAP := "Point_One"

var _l: Array = []
var _n := 0
func _initialize() -> void: call_deferred("_run")
func _say(s: String) -> void: _l.append(s); print(s)

func _find_crab(n: Node) -> Node3D:
	var stack: Array = [n]
	while not stack.is_empty():
		var q: Node = stack.pop_back()
		var sc = q.get_script()
		if sc != null and String(sc.resource_path).contains("head_crab"):
			return q as Node3D
		for c in q.get_children(): stack.append(c)
	return null

## point the walker and its camera at a world position
func _aim(walker: Node3D, cam: Camera3D, at: Vector3) -> void:
	var eye: Vector3 = cam.global_position
	var to: Vector3 = at - eye
	if to.length() < 0.01:
		return
	walker.rotation = Vector3(0.0, atan2(-to.x, -to.z), 0.0)
	var flat: float = Vector2(to.x, to.z).length()
	cam.rotation = Vector3(atan2(to.y, flat), 0.0, 0.0)


func _shoot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_root().get_texture().get_image()
	if img == null:
		_say("  no image for %s" % name); return
	var d := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(d)
	if img.save_png(d.path_join(name + ".png")) == OK:
		_n += 1; _say("  shot %s" % name)

func _run() -> void:
	# the trial control: the primitives chapter, no resume, no dollhouse
	var tf := FileAccess.open(TRIAL, FileAccess.WRITE)
	tf.store_string(JSON.stringify({
		"_readme": "TRIAL control for shoot_museum_crab — never the live file",
		"first_chapter": "primitives"}, "\t"))
	tf.close()

	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("EM_CONTROL", TRIAL)
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("_first_chapter", "primitives")
	get_root().add_child(inst)
	await process_frame

	# build forward until the hall exists
	var found := false
	var z0 := 0.0
	for tries in range(14):
		var segs: Array = inst.get("_segments")
		for sv in segs:
			var sd: Dictionary = sv
			if String(sd.get("map", "")) == WANT_MAP:
				z0 = float(sd.get("z0", 0.0)); found = true; break
		if found: break
		inst.call("_build_segment")
		await process_frame
	if not found:
		_say("the %s hall never appeared in 14 segments" % WANT_MAP)
		var segs2: Array = inst.get("_segments")
		for sv in segs2:
			_say("   built: %s" % String((sv as Dictionary).get("map", "?")))
		quit(1); return
	_say("MUSEUM: the '%s' hall stands at z0 = %.1f" % [WANT_MAP, z0])

	# drain the patient stamp queue so nothing is still owed
	inst.set("INSTANTIATE_AHEAD_M", 100000.0)
	var guard := 0
	while guard < 3000:
		await process_frame
		guard += 1
		var q: Array = inst.get("_stamp_queue")
		if q == null or q.size() == 0: break
	_say("  stamp queue drained after %d frame(s)" % guard)
	await create_timer(1.5).timeout

	var crab: Node3D = _find_crab(inst)
	if crab == null:
		_say("  NO head_crab in the built museum — the hall is there and the animal is not")
		var f0 := FileAccess.open(OUT + "/_index.txt", FileAccess.WRITE)
		if f0 != null: f0.store_string("no crab\n"); f0.close()
		quit(1); return
	_say("  head_crab found at %s" % str(crab.global_position))

	# USE THE MUSEUM'S OWN COMPOSER. _compose_look(token) picks a walkable cell
	# about 3 m from a body WITH A CLEAR LINE TO IT — the museum already knows
	# that a frame with a wall in it is the picture nobody wants. Two hand-picked
	# standpoints came back as a wall and an empty room; this is what --em-look
	# uses and it is right.
	var walker: Node3D = inst.get("_player")
	var cam: Camera3D = inst.get("_cam")
	if cam == null:
		cam = get_root().get_camera_3d()
	if walker == null or cam == null:
		_say("  no walker or camera to look through"); quit(1); return
	# FREEZE THE MUSEUM, THEN TAKE THE CAMERA. Three attempts failed the same
	# way and it was never the standpoint: the museum drives its walker and its
	# camera EVERY FRAME, so a rotation set here is gone before the frame is
	# drawn, and a Camera3D added here never stays current. Stopping the
	# museum's own process leaves the hall standing, the crab walking on its own
	# _process, and the viewport free.
	inst.set_process(false)
	inst.set_physics_process(false)
	if cam != null:
		cam.current = false
	var mine := Camera3D.new()
	mine.fov = 62.0
	get_root().add_child(mine)
	mine.make_current()
	await process_frame

	var p0: Vector3 = crab.global_position
	mine.global_position = p0 + Vector3(1.05, 0.85, 1.45)
	mine.look_at(p0 + Vector3(0, 0.10, 0), Vector3.UP)
	await create_timer(0.3).timeout
	await _shoot("1_the_animal")

	# a visitor's eye height, three metres back, looking down at it
	var p1: Vector3 = crab.global_position
	mine.global_position = Vector3(p1.x + 0.4, 1.62, p1.z + 3.0)
	mine.look_at(p1 + Vector3(0, 0.10, 0), Vector3.UP)
	await create_timer(0.25).timeout
	await _shoot("2_a_visitors_eye")

	# and the hall it is standing in
	mine.global_position = Vector3(p1.x + 1.0, 2.6, p1.z + 7.5)
	mine.look_at(Vector3(p1.x, 0.4, p1.z), Vector3.UP)
	await create_timer(0.25).timeout
	await _shoot("3_the_hall")
	_say("  it walked %.2f m while the three frames were taken" % p0.distance_to(crab.global_position))

	var f := FileAccess.open(OUT + "/_index.txt", FileAccess.WRITE)
	if f != null:
		f.store_string("\n".join(PackedStringArray(_l)) + "\n"); f.close()
	quit(0 if _n >= 3 else 1)
