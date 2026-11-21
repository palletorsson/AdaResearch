extends Node
## THE INNER OPERA in the tower (Palle, 2026-11-16)
##
## "The space opera is an opera scene short to sing about each artifact. As Care Unit Model B there is a voice that
## sings inside the head of the agent." With the handover kit (Model_B_Inner_Opera, 16 November): "can we make the
## player sing about the object in the world on the oculus?" - and: "it has to run on the quest as a voice stream,
## no rust ... must be godot based".
##
## So: nothing native. From the kit this uses three things, unchanged, in res://audio:
##   runtime/InnerOperaAttention.gd     the rules - a look must settle 0.9 s to count as choosing; one thought at
##                                      a time; a thing stays quiet until it has been looked away from; a silence
##                                      after each thought that nothing shortens;
##   generators/RobotVoiceGenerator.gd  the kit's sample-free voice in GDScript;
##   voice_scores/                      phrases as authored plans (the kit's tools/make_thought.py wrote the roof's).
## The kit's Rust engine, its extension and the scripts that need it are NOT here.
##
## This node says which things, and when:
##   commons/data/opera/tower_bindings.json: the score, and for a hall (by map name) which rows and props prompt
##   which thought. A bound thing is put in the kit's group with its object id; where it has nothing a look can
##   land on, it is given a box the size of what is drawn.
##   Listening begins two seconds after the opening has lifted, never in the black. The phrases are being made in
##   the background from the first frame (commons/void/inner_voice_godot.gd).
##
## Under a probe's scripted walker, or with --opera-quiet, the voice is made and "sounds" at -80 dB: rendering is
## tested, nothing is played aloud on the PC. --no-opera skips the node.
const ATTENTION := "res://audio/runtime/InnerOperaAttention.gd"
const VOICE := "res://commons/void/inner_voice_godot.gd"
const ACCOMPANIMENT := "res://commons/void/inner_opera_score.gd"
const BINDINGS := "res://commons/data/opera/tower_bindings.json"
const ATLAS_PATH := "res://commons/data/tower_system_atlas.json"
const TWO_VISITS_SONG := "spine_c2b6fc98a64a37b397"
const OpeningTrail := preload("res://commons/void/opening_opera_trail.gd")
const GROUP := "inner_opera_object"
const AFTER_OPENING := 2.0

var game: Node3D
var voice: Node
var music: Node
var music_path := ""
var attention: RefCounted
var listening := false
var quiet := false
var score_path := ""
var score_error := ""
var voice_options := {}
var by_floor := {}                        # floor index -> {row[/named/child]: object id}
var bound := {}                           # "floor/id" -> instance id of the node that was bound
var gaze_distance := 14.0
var gaze_angle_degrees := 3.0
var volume_db := -2.0
var renderer := "model_b"
var heard: Array = []
var _since_ready := 0.0
var _look_again := 0.0
var _gaze_previous := ""
var _gaze_report_in := 0.0
var _atlas_loaded := false
var _encounter_plain: Dictionary = {}
var _song_plain: Dictionary = {}


func _ready() -> void:
	game = get_parent() as Node3D
	var args := OS.get_cmdline_user_args()
	if game == null or args.has("--no-opera") or not _read_bindings():
		queue_free()
		return
	if not ResourceLoader.exists(ATTENTION) or not ResourceLoader.exists(VOICE):
		print("[opera] the inner-voice scripts are not in this build: nothing will be sung")
		queue_free()
		return
	attention = (load(ATTENTION) as GDScript).new()
	voice = (load(VOICE) as GDScript).new()
	voice.set("volume_db", volume_db)
	add_child(voice)
	voice.connect("started", _on_started)
	voice.connect("finished", _on_finished)
	voice.connect("failed", _on_failed)
	voice.connect("rendered", func(id, seconds, cached): print("[opera] ready: '%s' (%s)" % [id, "kept from an earlier run" if cached else "made in %.1f s" % seconds]))
	score_error = str(voice.call("load_score", score_path, voice_options, renderer))
	quiet = args.has("--opera-quiet")
	if not music_path.is_empty() and ResourceLoader.exists(ACCOMPANIMENT):
		music = (load(ACCOMPANIMENT) as GDScript).new()
		add_child(music)
		music.call("configure", music_path)
		music.call("set_context", false, quiet)
	print("[opera] Godot voice (%s); score %s%s" % [str(voice.get("renderer_name")), score_path, "" if score_error.is_empty() else "  ERROR: " + score_error])
	game.set_meta("inner_opera", self)


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F9 and not game.vr:
		get_viewport().set_input_as_handled()
		_desktop_photograph()
		return

func _desktop_photograph() -> void:
	await RenderingServer.frame_post_draw
	var directory := ProjectSettings.globalize_path("user://opera_journal/desktop")
	var file := directory.path_join("floor-%d-%d-%d.png" % [game.checkpoint, int(Time.get_unix_time_from_system()), Time.get_ticks_msec()])
	var image := get_viewport().get_texture().get_image()
	if image != null and DirAccess.make_dir_recursive_absolute(directory) == OK and image.save_png(file) == OK:
		print("[opera] Desktop photograph: ",file)
		game.call("_notice","Photograph saved · "+file)
	else:
		game.call("_notice","Could not save the desktop photograph.")


func _read_bindings() -> bool:
	if not FileAccess.file_exists(BINDINGS): return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BINDINGS))
	if not parsed is Dictionary: return false
	score_path = str(parsed.get("score", ""))
	music_path = str(parsed.get("accompaniment", ""))
	gaze_distance = float(parsed.get("gaze_distance", gaze_distance))
	gaze_angle_degrees = clampf(float(parsed.get("gaze_angle_degrees", gaze_angle_degrees)), 0.0, 5.0)
	if parsed.get("voice") is Dictionary: voice_options = parsed.voice
	volume_db = float(parsed.get("volume_db", volume_db))
	renderer = str(parsed.get("renderer", renderer))
	if not FileAccess.file_exists(score_path):
		print("[opera] no score at %s" % score_path)
		return false
	var building: Object = game.get("building")
	if building == null or building.get("content") == null: return false
	var floors: Array = building.get("content").get("data").get("floors")
	var maps: Dictionary = parsed.get("maps", {})
	for index in floors.size():
		var wanted: Variant = maps.get(str(floors[index].get("map", "")))
		if wanted is Dictionary: by_floor[index] = wanted
	return not by_floor.is_empty()


## ---- which things ----

## Every half second: whatever of a bound hall has been stood on its floor is given its object id.
func _bind_what_stands() -> void:
	var content: Object = game.get("building").get("content")
	var exhibits: Dictionary = content.get("exhibits")
	var props: Dictionary = content.get("props")
	for index in by_floor:
		var wanted: Dictionary = by_floor[index]
		for id in wanted:
			var key := "%d/%s" % [index, str(id)]
			var selector := str(id)
			var row_key := "%d/%s" % [index, selector.get_slice("/", 0)]
			var mount := (exhibits.get(row_key) if exhibits.has(row_key) else props.get(row_key)) as Node3D
			if mount == null or not is_instance_valid(mount) or not mount.is_inside_tree(): continue
			# One edited installation may contain several independent studies. Bind the
			# named study, preserving the row-only form used by Point Zero.
			if selector.contains("/"):
				mount = mount.get_node_or_null(NodePath(selector.substr(selector.find("/") + 1))) as Node3D
				if mount == null: continue
			if int(bound.get(key, 0)) == mount.get_instance_id(): continue
			_bind(mount, str(wanted[id]))
			if wanted[id] == TWO_VISITS_SONG:
				var wheel := mount.get_node_or_null("Artifact")
				if wheel != null and wheel.has_signal("two_visits_completed"):
					var map := str(game.building.content.data.floors[int(index)].map)
					var edit: Dictionary = OpeningTrail.placements(map).get(TWO_VISITS_SONG, {})
					if edit.has("position") and is_instance_valid(wheel.view_frame):
						wheel.view_frame.apply_floor_pose(game.building.content.roots[int(index)], edit)
			bound[key] = mount.get_instance_id()


func _bind(mount: Node3D, object_id: String) -> void:
	mount.add_to_group(GROUP)
	mount.set_meta("object_id", object_id)
	var has_body := mount is CollisionObject3D and not (mount as CollisionObject3D).get_shape_owners().is_empty()
	for body in mount.find_children("*", "CollisionObject3D", true, false):
		if not (body as CollisionObject3D).get_shape_owners().is_empty(): has_body = true
	if not has_body:
		# nothing a look can land on: a box the size of what is drawn
		var box := AABB()
		var first := true
		var inverse: Transform3D = mount.global_transform.affine_inverse()
		for drawn in mount.find_children("*", "VisualInstance3D", true, false):
			var visual := drawn as VisualInstance3D
			if visual is Light3D or not visual.is_visible_in_tree(): continue
			var part: AABB = (inverse * visual.global_transform) * visual.get_aabb()
			box = part if first else box.merge(part)
			first = false
		if first: box = AABB(Vector3(-0.3, 0, -0.3), Vector3(0.6, 0.6, 0.6))
		var area := Area3D.new()
		area.name = "OperaLook"
		area.collision_layer = 1 << 21
		area.collision_mask = 0
		area.monitoring = false
		var shape := CollisionShape3D.new()
		var block := BoxShape3D.new()
		block.size = Vector3(clampf(box.size.x, 0.4, 9.0), clampf(box.size.y, 0.4, 9.0), clampf(box.size.z, 0.4, 9.0))
		shape.shape = block
		shape.position = box.get_center()
		area.add_child(shape)
		mount.add_child(area)
	print("[opera] bound %s -> '%s' (%s)" % [mount.name, object_id, "its own solids" if has_body else "a box for the look"])


## Head gaze is a small cone, not a pixel-perfect pointer. Keep the exact hit
## first; the surrounding rays let a small sphere survive natural head motion.
## Each ray still stops at physical scenery, so a wall cannot earn a thought
## for a hidden object. Invisible, unbound trigger areas are not scenery.
func _looked_at() -> String:
	var camera := game.get("camera") as Camera3D
	if camera == null: camera = get_viewport().get_camera_3d()
	if camera == null or not camera.is_inside_tree(): return ""
	var forward := -camera.global_basis.z.normalized()
	var exact := _gaze_ray(camera, forward)
	if not exact.is_empty():
		_gaze_previous = exact
		return exact
	var first := ""
	if gaze_angle_degrees > 0.0:
		var spread := tan(deg_to_rad(gaze_angle_degrees))
		for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN,
			Vector2(-1, -1).normalized(), Vector2(1, -1).normalized(),
			Vector2(-1, 1).normalized(), Vector2(1, 1).normalized()]:
			var direction: Vector3 = (forward + spread * (camera.global_basis.x * offset.x + camera.global_basis.y * offset.y)).normalized()
			var nearby := _gaze_ray(camera, direction)
			if nearby.is_empty(): continue
			if nearby == _gaze_previous: return nearby
			if first.is_empty(): first = nearby
	_gaze_previous = first
	return first


func _gaze_ray(camera: Camera3D, direction: Vector3) -> String:
	var from: Vector3 = camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * gaze_distance)
	query.collide_with_areas = true
	var body := game.get("body") as CollisionObject3D
	if body != null: query.exclude = [body.get_rid()]
	for step in 16:
		var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty(): return ""
		var walk := hit.collider as Node
		while walk != null:
			if walk.is_in_group(GROUP) and walk.has_meta("object_id"): return str(walk.get_meta("object_id"))
			walk = walk.get_parent()
		if not hit.collider is Area3D: return ""
		var exclusions: Array[RID] = query.exclude
		exclusions.append(hit.rid)
		query.exclude = exclusions
	return ""


func _physics_process(delta: float) -> void:
	if game == null or voice == null: return
	_look_again -= delta
	if _look_again <= 0.0:
		_look_again = 0.5
		_bind_what_stands()
	if not listening:
		if bool(game.get("ready_for_play")) and not game.has_meta("opening"): _since_ready += delta
		if _since_ready < AFTER_OPENING: return
		listening = true
		var walker: Variant = game.get("body")
		# The human desktop launcher briefly freezes input while placing the player.
		# That setup period is not an automated, muted probe.
		if not OS.get_cmdline_user_args().has("--opera-human") and walker is Object and (walker as Object).get("scripted_input") == true: quiet = true
		if quiet: voice.set("volume_db", -80.0)
		print("[opera] listening (%d things bound%s)" % [bound.size(), "; quiet: nothing is played aloud" if quiet else ""])
	if music != null:
		var stream: Variant = game.get("floor_stream")
		var floor_index := int(stream.get("focus")) if stream is Object else int(game.get("checkpoint"))
		music.call("set_context", by_floor.has(floor_index) and not game.has_meta("opening"), quiet)
	var looking := _looked_at()
	var chosen: String = attention.call("look", looking, delta)
	_gaze_report_in -= delta
	if _gaze_report_in <= 0.0:
		_gaze_report_in = 2.0
		_write_gaze_diagnostic(looking)
	if chosen.is_empty(): return
	if not bool(voice.call("has_object", chosen)):
		attention.call("mark_silent")
		return
	if not bool(voice.call("sing", chosen)) and not bool(voice.call("is_sounding")):
		print("[opera] '%s' is chosen and still being made" % chosen)


## Optional on-device evidence for a human playtest. Creating/removing this
## marker needs no restart and never moves the player or starts a phrase.
func _write_gaze_diagnostic(looking: String) -> void:
	if not FileAccess.file_exists("user://opera_debug.on"): return
	var camera := game.get("camera") as Camera3D
	if camera == null: return
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, camera.global_position - camera.global_basis.z * gaze_distance)
	query.collide_with_areas = true
	var body := game.get("body") as CollisionObject3D
	if body != null: query.exclude = [body.get_rid()]
	var hit: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	var stream: Variant = game.get("floor_stream")
	var report := {"gaze_revision": 2, "ticks_ms": Time.get_ticks_msec(), "floor": int(stream.get("focus")) if stream is Object else int(game.get("checkpoint")),
		"camera": str(camera.global_position), "direction": str(-camera.global_basis.z), "looking_at": looking,
		"first_collider": str(hit.collider.get_path()) if not hit.is_empty() else "", "dwell": attention.dwell_ratio(looking),
		"speaking": attention.is_speaking(), "quiet": quiet, "ready_count": voice.streams.size(),
		"heard": heard.slice(maxi(0, heard.size() - 8))}
	var file := FileAccess.open("user://opera_gaze.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(report, "  "))


func _ensure_atlas_breadcrumbs() -> void:
	if _atlas_loaded: return
	_atlas_loaded = true
	if not FileAccess.file_exists(ATLAS_PATH): return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ATLAS_PATH))
	if not (parsed is Dictionary): return
	var doc := parsed as Dictionary
	var encs: Variant = doc.get("encounterBreadcrumbs")
	if encs is Dictionary: _encounter_plain = encs as Dictionary
	var songs: Variant = doc.get("songBreadcrumbs")
	if songs is Dictionary: _song_plain = songs as Dictionary


func _plain_for(encounter_id: String, object_id: String) -> String:
	_ensure_atlas_breadcrumbs()
	for key in [encounter_id, object_id]:
		if key.is_empty(): continue
		var v: Variant = _encounter_plain.get(key, "")
		if v is String and not (v as String).strip_edges().is_empty():
			return (v as String).strip_edges()
	for key in [encounter_id, object_id]:
		if key.is_empty(): continue
		var v: Variant = _song_plain.get(key, "")
		if v is String and not (v as String).strip_edges().is_empty():
			return (v as String).strip_edges()
	return ""


# The line being sung is written on the viewfinder (the game's charge display), paired with its plain
# breadcrumb from tower_system_atlas.json when available, and cleared when it ends.
func _show(text: String, plain: String = "") -> bool:
	var display: Variant = get_parent().get("charge_display") if get_parent() != null else null
	if display is Object and is_instance_valid(display) and (display as Object).has_method("set_sung"):
		(display as Object).call("set_sung", text, plain)
		return true
	return false


func _on_started(object_id: String, text: String) -> void:
	if music != null: music.call("set_singing", true)
	var plain := _plain_for(object_id, object_id)
	heard.append({"object": object_id, "text": text, "sung": true, "on_display": _show(text, plain)})
	print("[opera] SINGS for '%s': %s" % [object_id, text])


func _on_finished(object_id: String) -> void:
	if music != null: music.call("set_singing", false)
	_show("")
	attention.call("mark_silent")
	print("[opera] finished: %s" % object_id)


func _on_failed(object_id: String, message: String) -> void:
	if music != null: music.call("set_singing", false)
	_show("")
	attention.call("mark_silent")
	heard.append({"object": object_id, "text": "", "sung": false, "failed": message})
	print("[opera] NOT SUNG for '%s': %s" % [object_id, message])


func _exit_tree() -> void:
	if voice != null and is_instance_valid(voice): voice.call("stop")


## ---- for a test ----

func state() -> Dictionary:
	return {"listening": listening, "quiet": quiet, "score": score_path, "score_error": score_error, "bound": bound.keys(), "thoughts": (voice.get("order") as Array).duplicate(),
		"ready": (voice.get("streams") as Dictionary).keys(), "costs": (voice.get("costs") as Dictionary).duplicate(true), "heard": heard.duplicate(true), "looking_at": _looked_at(), "music": music.call("state") if music != null else {}}


## A rendered phrase as 16-bit samples, for a test to measure. Empty until it is ready.
func samples_of(object_id: String) -> PackedByteArray:
	var streams: Dictionary = voice.get("streams")
	return (streams[object_id] as AudioStreamWAV).data if streams.has(object_id) else PackedByteArray()
