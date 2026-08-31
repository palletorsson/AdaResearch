extends Node3D
## VR LINK — THE REAL MUSEUM, SPLIT. Eye view and plan, of the actual thing.
##
## 2026-08-31, Palle: "can we do this with the Godot version of the endless
## museum so we see the player for vr in a split view with these maps?"
##
## vr_link_viewer.tscn draws a SCHEMATIC — boxes rebuilt from
## em_layout_walk.json. Good enough to see where someone is, but it is not the
## museum: no artifacts, no walls as built, no light. This runs the REAL
## endless_museum.tscn on the desktop and puppets it from the headset.
##
## THE TRICK IS THAT THE MUSEUM STREAMS AROUND ITS OWN WALKER. `_eye_pos()` is
## `_player.position + EYE`, and every build/free decision reads that z. So
## driving the local museum's `_player` to the VR player's coordinates makes the
## local museum build EXACTLY the halls the person in the headset is walking
## through — the streaming follows for free, with no message about halls at all.
## The only thing crossing the wire is a position.
##
## LOCOMOTION IS TURNED OFF FROM THE OUTSIDE. endless_museum.gd already knows
## this shape: `_setup_feel()` refuses to build the Feel node for the proof shot,
## the collision test and the autopilot, because those "aim the body themselves
## and must not be fought over". This is a fourth such caller, and it says so by
## disabling the node in group `em_feel` rather than by editing that file —
## nineteen thousand lines another session commits to constantly.
##
##   python tools/vr_link.py
##   godot --path . --xr-mode off res://commons/scenes/vr_link_museum.tscn
##
## Both panes render the SAME World3D from two cameras: a SubViewport with
## own_world_3d false inherits the parent viewport's world, so the museum is
## built once and looked at twice.
##
## Keys: [1] follow-cam  [2] eye  [3] free-orbit · wheel zoom · [P] plan zoom.

const HOST := "127.0.0.1"
const PORT := 8771
const MUSEUM := "res://commons/scenes/endless_museum.tscn"

var _peer: StreamPeerTCP = null
var _rx := ""
var _retry := 0.0
var _said_hello := false

var _museum: Node = null
var _mus_player: Node3D = null
var _pose: Dictionary = {}
var _have_pose := false
## WHEN the last pose arrived. A pose with no age is the whole bug: this scene
## once sat perfectly still on a hall nobody was in, captioned "connected",
## because the server primed it with a pose from a previous session. Silence and
## stillness look identical unless something is counting.
var _last_pose_ms := 0
const STALE_MS := 2000

var _vp_eye: SubViewport
var _vp_plan: SubViewport
var _cam_eye: Camera3D
var _cam_plan: Camera3D
var _mark: Node3D
var _text: Label

var _mode := 0                 # 0 follow, 1 eye, 2 free orbit
var _yaw := 0.0
var _pitch := 0.55
var _dist := 9.0
var _plan_size := 34.0
var _dragging := false
var _quiet_done := false

var _shot_path := ""
var _shot_after := 14.0


func _ready() -> void:
	for a in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		var s: String = String(a)
		if s.begins_with("--shot="):
			_shot_path = s.substr(7)
		elif s.begins_with("--shot-after="):
			_shot_after = float(s.substr(13))

	_build_ui()
	_spawn_museum()
	_connect()
	print("[em-view] real museum + split view — dialling %s:%d" % [HOST, PORT])


## ————————————————————————————————————————————————————————————————————
## The museum itself
## ————————————————————————————————————————————————————————————————————

func _spawn_museum() -> void:
	var ps: PackedScene = load(MUSEUM)
	if ps == null:
		push_error("[em-view] cannot load %s" % MUSEUM)
		return
	_museum = ps.instantiate()
	add_child(_museum)
	print("[em-view] endless museum instanced — it will stream around the VR player")


## The Feel node is created during the museum's own _ready, so it cannot be
## disabled until after that has run. Retried until found rather than assumed.
func _quiet_locomotion() -> void:
	if _quiet_done or _museum == null:
		return
	var feels: Array = get_tree().get_nodes_in_group("em_feel")
	for f in feels:
		if f is Node:
			(f as Node).set_process(false)
			(f as Node).set_physics_process(false)

	# ONLY THE PLAYER'S OWN HUD IS HIDDEN HERE. vr_link_viewer quiets eleven
	# autoloads because it draws a schematic and wants nothing painted over it;
	# this scene wants the OPPOSITE — it is showing the real museum, so
	# NatureRenderer, FloraSpawner and the rest must keep running or the
	# spectator would see a different building from the one in the headset.
	# What must go is the chrome belonging to a player who is not here: the
	# first shot had a "mushrooms ..... [F]" prompt over the split.
	for n_name in ["MushroomHand", "Subtitles"]:
		var n: Node = get_node_or_null("/root/%s" % n_name)
		if n == null:
			continue
		n.set_process(false)
		n.set_physics_process(false)
		_hide_visuals(n)
	# The mouse-look also fights a spectator: the museum captures the pointer for
	# its own walker. Give it back, so the split view can be clicked and dragged.
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if not feels.is_empty():
		_quiet_done = true
		print("[em-view] locomotion quieted (%d em_feel node(s)) — the headset drives the body" % feels.size())


func _hide_visuals(n: Node) -> void:
	if n is CanvasItem:
		(n as CanvasItem).visible = false
	elif n is CanvasLayer:
		(n as CanvasLayer).visible = false
	for c in n.get_children():
		_hide_visuals(c)


func _find_player() -> Node3D:
	if _mus_player != null and is_instance_valid(_mus_player):
		return _mus_player
	if _museum == null:
		return null
	var p: Variant = _museum.get("_player")
	if p is Node3D and is_instance_valid(p):
		_mus_player = p as Node3D
	return _mus_player


## ————————————————————————————————————————————————————————————————————
## Views
## ————————————————————————————————————————————————————————————————————

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	# A FRESH CONTROL KEEPS A ZERO RECT (standing lesson): set_anchors_preset
	# alone leaves offsets at 0 and the box paints nothing while every counter
	# reads correct. Offsets are cleared explicitly.
	row.offset_left = 0.0
	row.offset_top = 0.0
	row.offset_right = 0.0
	row.offset_bottom = 0.0
	row.add_theme_constant_override("separation", 2)
	layer.add_child(row)

	_vp_eye = _pane(row, "eye")
	_vp_plan = _pane(row, "plan")

	_cam_eye = Camera3D.new()
	_cam_eye.far = 900.0
	_vp_eye.add_child(_cam_eye)
	_cam_eye.current = true

	_cam_plan = Camera3D.new()
	_cam_plan.far = 900.0
	_cam_plan.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam_plan.size = _plan_size
	# A PLAN IS A DRAWING, so it gets its own flat environment rather than the
	# museum's. Inheriting the gallery lighting made the first plan a washed-out
	# bloom of glow with the floor barely legible — handsome in the eye view,
	# useless as a map. Camera3D.environment overrides per-camera, so the left
	# pane keeps the real look and only this one is flattened.
	var pe := Environment.new()
	pe.background_mode = Environment.BG_COLOR
	pe.background_color = Color(0.10, 0.11, 0.13)
	pe.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	pe.ambient_light_color = Color(1, 1, 1)
	pe.ambient_light_energy = 1.5
	pe.glow_enabled = false
	pe.fog_enabled = false
	pe.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	_cam_plan.environment = pe
	_vp_plan.add_child(_cam_plan)
	_cam_plan.current = true

	_text = Label.new()
	_text.position = Vector2(14, 10)
	_text.add_theme_font_size_override("font_size", 13)
	_text.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_text.add_theme_constant_override("outline_size", 5)
	layer.add_child(_text)

	# the VR player, drawn so they can be SEEN in the museum rather than inferred
	_mark = Node3D.new()
	var m := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.24
	cap.height = 1.75
	m.mesh = cap
	m.position = Vector3(0, 0.9, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.85, 0.80, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.80, 0.75)
	mat.emission_energy_multiplier = 0.9
	# DRAWN THROUGH THE WALLS, deliberately. A spectator marker that a podium can
	# hide is a marker you cannot trust — when it vanished from the first shot
	# there was no way to tell "occluded" from "never rendered". Now there is.
	mat.no_depth_test = true
	mat.render_priority = 10
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mark.add_child(m)
	# A CAPSULE SEEN FROM 80 M UP IS FOUR PIXELS. The plan pane needs a mark with
	# area, so the body gets a ground ring — flat, unshaded, drawn through the
	# floor, and legible at any plan zoom.
	var ring := MeshInstance3D.new()
	var rm := TorusMesh.new()
	rm.inner_radius = 0.75
	rm.outer_radius = 1.05
	ring.mesh = rm
	ring.position = Vector3(0, 0.05, 0)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.30, 0.95, 0.90)
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rmat.no_depth_test = true
	rmat.render_priority = 11
	ring.material_override = rmat
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mark.add_child(ring)

	var tag := Label3D.new()
	tag.text = "VR"
	tag.position = Vector3(0, 2.1, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.font_size = 52
	tag.pixel_size = 0.0028
	tag.modulate = Color(0.45, 1.0, 0.95)
	_mark.add_child(tag)
	add_child(_mark)


## One half of the split. own_world_3d stays FALSE so the SubViewport inherits
## the parent viewport's World3D — the museum is built once and rendered twice,
## rather than instanced per pane.
func _pane(row: HBoxContainer, pane_name: String) -> SubViewport:
	var box := SubViewportContainer.new()
	box.name = pane_name
	box.stretch = true
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(box)
	var vp := SubViewport.new()
	vp.own_world_3d = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.handle_input_locally = false
	box.add_child(vp)
	return vp


## ————————————————————————————————————————————————————————————————————
## The link
## ————————————————————————————————————————————————————————————————————

func _connect() -> void:
	_peer = StreamPeerTCP.new()
	if _peer.connect_to_host(HOST, PORT) != OK:
		_peer = null


func _process(delta: float) -> void:
	_quiet_locomotion()
	_pump(delta)
	_drive()
	_aim()
	_paint()
	if _shot_path != "":
		_shot_after -= delta
		if _shot_after <= 0.0:
			var p: String = _shot_path
			_shot_path = ""
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(p))
			print("[em-view] shot -> %s" % p)
			print("[em-view]   marker %s  eye-cam %s  plan-cam %s (size %.0f)" % [
				str(_mark.global_position), str(_cam_eye.global_position),
				str(_cam_plan.global_position), _plan_size])
			get_tree().quit(0)


func _pump(delta: float) -> void:
	if _peer == null:
		_retry += delta
		if _retry >= 2.0:
			_retry = 0.0
			_connect()
		return
	_peer.poll()
	var st: int = _peer.get_status()
	if st == StreamPeerTCP.STATUS_CONNECTING:
		return
	if st != StreamPeerTCP.STATUS_CONNECTED:
		_peer = null
		return
	if not _said_hello:
		_said_hello = true
		_peer.put_data((JSON.stringify({"k": "hello", "role": "viewer"}) + "\n").to_utf8_buffer())
	var n: int = _peer.get_available_bytes()
	if n <= 0:
		return
	var got: Array = _peer.get_data(n)
	if int(got[0]) != OK:
		return
	_rx += (got[1] as PackedByteArray).get_string_from_utf8()
	while true:
		var nl: int = _rx.find("\n")
		if nl < 0:
			break
		var line: String = _rx.substr(0, nl).strip_edges()
		_rx = _rx.substr(nl + 1)
		if line.is_empty():
			continue
		var v: Variant = JSON.parse_string(line)
		if v is Dictionary and String((v as Dictionary).get("k", "")) == "pose":
			_pose = v as Dictionary
			_have_pose = true
			_last_pose_ms = Time.get_ticks_msec()


## THE ONE LINE THAT MAKES THE MUSEUM FOLLOW. Everything else here is a camera.
## Is the headset actually IN the endless museum? The pose carries a `hall` only
## when the museum's segment list claims the player's z, so this is the museum's
## own answer rather than a guess from the scene name.
func _in_museum() -> bool:
	var h: Variant = _pose.get("hall")
	return h is Dictionary and String((h as Dictionary).get("pearl", "")) != ""


func _stale_ms() -> int:
	if not _have_pose:
		return -1
	return Time.get_ticks_msec() - _last_pose_ms


func _drive() -> void:
	# the body is only shown when it is somewhere this view can honestly place it
	_mark.visible = _have_pose and _stale_ms() <= STALE_MS and _in_museum()
	if not _have_pose:
		return
	# DO NOT DRIVE THE MUSEUM FROM A CORPSE. Writing a stale coordinate every
	# frame pins the local museum to a hall the player left long ago and fights
	# nothing, so it looks exactly like a working link showing a still person.
	if _stale_ms() > STALE_MS:
		return
	# AND NOT FROM A FOREIGN COORDINATE SPACE. If the headset is not in the
	# museum, its position is in some other map's frame and means NOTHING here.
	# Driving the local museum to it streams the walker to an arbitrary z and
	# drops the marker into a hall chosen by coincidence — which is how this
	# looked "like nothing was happening" while the link was in fact perfect,
	# at 14.6 Hz, with the headset sitting in VRStaging.
	if not _in_museum():
		return
	var p: Vector3 = _vec(_pose.get("pos", []))
	_mark.global_position = p
	if _pose.has("yaw"):
		_mark.rotation.y = float(_pose["yaw"])
	var mp: Node3D = _find_player()
	if mp == null:
		return
	mp.global_position = p
	# a CharacterBody3D still accumulates velocity between our writes; zeroing it
	# stops move_and_slide from dragging the body off the coordinate we just set
	if "velocity" in mp:
		mp.set("velocity", Vector3.ZERO)


func _vec(a: Variant) -> Vector3:
	if a is Array and (a as Array).size() >= 3:
		var arr: Array = a as Array
		return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
	return Vector3.ZERO


func _aim() -> void:
	var p: Vector3 = _mark.global_position
	var yaw: float = float(_pose.get("yaw", 0.0)) if _pose.has("yaw") else 0.0
	match _mode:
		1:
			# what the wearer is looking at, near enough — the head height and
			# heading the headset reports
			var head: Vector3 = _vec(_pose.get("head", [])) if _pose.has("head") else p + Vector3(0, 1.65, 0)
			_cam_eye.global_position = head
			_cam_eye.rotation = Vector3(float(_pose.get("pitch", 0.0)), yaw, 0.0)
		2:
			var cp: float = cos(_pitch)
			_cam_eye.global_position = p + Vector3(sin(_yaw) * cp, sin(_pitch), cos(_yaw) * cp) * _dist
			_cam_eye.look_at(p + Vector3(0, 1.0, 0), Vector3.UP)
		_:
			# over the shoulder, behind the heading, so the body is visible in
			# the room it is actually standing in
			var back: Vector3 = Vector3(sin(yaw), 0.0, cos(yaw)) * -_dist
			_cam_eye.global_position = p + back + Vector3(0, _dist * 0.45, 0)
			_cam_eye.look_at(p + Vector3(0, 1.2, 0), Vector3.UP)
	# THE PLAN IS A DRAWING, NOT A ROTATED MODEL — north (-Z) stays up, the same
	# rule the museum's own doll-house plan follows.
	#
	# AND A PLAN IS A SECTION, NOT A VIEW FROM ABOVE. The first attempt put the
	# camera 80 m up and photographed the ROOF: the museum has ceilings, so
	# looking down showed white slabs and nothing of the hall. The near plane
	# does the cutting — held 2.5 m above the floor the player is standing on,
	# so the roof is clipped away and the room is drawn as an architect would
	# draw it. No cull masks, no hidden nodes, nothing to keep in sync.
	_cam_plan.size = _plan_size
	_cam_plan.global_position = p + Vector3(0, 80.0, 0)
	_cam_plan.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	_cam_plan.near = 80.0 - 2.5
	_cam_plan.far = 300.0


func _paint() -> void:
	var lines: Array = []
	var live: bool = _peer != null and _peer.get_status() == StreamPeerTCP.STATUS_CONNECTED
	# "connected" means connected TO THE SERVER, which is not the same as
	# hearing from a game — say which, because conflating them is what made a
	# frozen view look healthy.
	var age: int = _stale_ms()
	var stale: bool = age > STALE_MS
	var state: String = "waiting for the server"
	if live:
		state = "server ok — no game attached" if not _have_pose \
			else ("STALE %.1fs — the headset has stopped sending" % (age / 1000.0) if stale
				  else "live from the headset")
	lines.append("VR LINK — REAL MUSEUM        %s" % state)
	if not _have_pose:
		lines.append("no pose yet — is the headset armed?  python tools/vr_link.py --headset")
	else:
		if stale:
			lines.append("!! the position below is the LAST one received, not where anyone is now")
		var p: Vector3 = _vec(_pose.get("pos", []))
		var hall: Variant = _pose.get("hall")
		if _in_museum():
			var h: Dictionary = hall
			lines.append("hall   %s   [%s]  #%d   %.0f%% through" % [
				String(h.get("map", "")), String(h.get("pearl", "")),
				int(h.get("index", -1)), float(h.get("through", 0.0)) * 100.0])
			lines.append("pos    %7.2f %6.2f %8.2f" % [p.x, p.y, p.z])
			lines.append("local  %s" % ("driving the museum's walker"
				if _find_player() != null else "no museum player yet"))
		else:
			# SAY WHERE THEY ACTUALLY ARE. Silently drawing a marker in the wrong
			# frame is worse than drawing nothing.
			lines.append("")
			lines.append("!!  the headset is in  %s" % String(_pose.get("map", "?")))
			lines.append("!!  that is NOT the endless museum, so its coordinates")
			lines.append("!!  mean nothing in this view. Walk into the museum in VR.")
			lines.append("!!  For an authored map, use instead:")
			lines.append("!!     res://commons/scenes/vr_link_viewer.tscn")
			lines.append("")
			lines.append("headset pos %7.2f %6.2f %8.2f   (in %s's own frame)"
				% [p.x, p.y, p.z, String(_pose.get("map", "?"))])
	lines.append("")
	lines.append("[1] follow  [2] eye  [3] orbit   wheel zoom   [P]/[O] plan zoom     mode %d" % _mode)
	_text.text = "\n".join(lines)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and (ev as InputEventKey).pressed:
		var k: InputEventKey = ev
		match k.keycode:
			KEY_1: _mode = 0
			KEY_2: _mode = 1
			KEY_3: _mode = 2
			KEY_P: _plan_size = maxf(8.0, _plan_size * 0.8)
			KEY_O: _plan_size = minf(220.0, _plan_size * 1.25)
	elif ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_dist = maxf(2.0, _dist * 0.88)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_dist = minf(160.0, _dist * 1.14)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
	elif ev is InputEventMouseMotion and _dragging and _mode == 2:
		var mm: InputEventMouseMotion = ev
		_yaw -= mm.relative.x * 0.008
		_pitch = clampf(_pitch + mm.relative.y * 0.006, 0.05, 1.5)
