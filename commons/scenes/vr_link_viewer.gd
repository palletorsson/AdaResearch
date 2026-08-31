extends Node3D
## VR LINK VIEWER — the desktop end, in Godot, watching the endless museum.
##
## 2026-08-31, Palle: "can we do one godot version using the endless museum also"
##
## The browser views at localhost:8772 draw a canvas approximation of an
## AUTHORED map, and go blank the moment you walk into the museum — because the
## museum is not a map. 196 halls stream past a single cursor; there is no
## map_data.json to look up and no one room to draw.
##
## This is the same three views in Godot, and it draws the museum's OWN record.
## `ada_run/em_layout_walk.json` is what the engine wrote down as it built each
## hall — 198 rows, each with the as-built `cells` grid, `cell_x0`, and `span`.
## Together with the live segment's `z0` (which the link now reports) that is an
## EXACT reconstruction, not a guess: span 34 = vestibule 4 + h 30 + porch +
## court, and the grid lands where the hall actually is.
##
##   python tools/vr_link.py                          # the server
##   godot --path . --xr-mode off res://commons/scenes/vr_link_viewer.tscn
##
## ONE GODOT PER MACHINE. This project's rule is never to run two instances at
## once — they share user:// and the second can lose the lock. That is not a
## problem in the intended shape, where the GAME is on the Quest and only the
## viewer is on the PC. Running both on the desktop is a testing convenience and
## may misbehave; if it does, that is the lock, not this scene.
##
## Controls: drag orbit · wheel zoom · T top-down · F follow · click teleports.

const HOST := "127.0.0.1"
const PORT := 8771
const WALK_PATH := "res://ada_run/em_layout_walk.json"
const CELL := 1.0

var _peer: StreamPeerTCP = null
var _rx := ""
var _retry := 0.0

var _halls: Dictionary = {}          # "chapter|pearl" -> as-built row
var _pose: Dictionary = {}
## See vr_link_museum.gd: a pose with no age reads as current forever, and a
## frozen view is indistinguishable from a stationary player.
var _last_pose_ms := 0
const STALE_MS := 2000
var _trail: PackedVector3Array = PackedVector3Array()
var _drawn_key := ""                 # which hall the geometry currently shows
var _drawn_z0 := 0.0

var _cam: Camera3D
var _pivot: Node3D
var _env_res: Environment
var _solid: MultiMeshInstance3D
var _floor: MultiMeshInstance3D
var _player_mark: Node3D
var _ghost_mark: Node3D
var _trail_line: MeshInstance3D
var _text: Label

var _yaw := 0.6
var _pitch := 0.9
var _dist := 34.0
var _topdown := false
var _follow := true
var _dragging := false


## --shot=<path> --shot-after=<seconds>: save a PNG and quit. A viewer whose
## only evidence is a printed instance count is a viewer nobody has looked at
## (end every run with a gallery).
var _shot_path := ""
var _shot_after := 8.0


func _ready() -> void:
	for a in OS.get_cmdline_args() + OS.get_cmdline_user_args():
		var s: String = String(a)
		if s.begins_with("--shot="):
			_shot_path = s.substr(7)
		elif s.begins_with("--shot-after="):
			_shot_after = float(s.substr(13))
		elif s == "--topdown":
			_topdown = true
	_quiet_autoloads()
	_build_world()
	_load_walk()
	_connect()
	print("[viewer] dialling %s:%d — start the game with --vr-link" % [HOST, PORT])


## A VIEWER IS NOT A GAME, BUT IT BOOTS LIKE ONE. Every scene in this project
## inherits 26 autoloads, and they do not know they are running behind an
## instrument panel: the first shot of this viewer came back washed flat green
## with a "mushrooms ..... [F]" HUD in the corner. That was NatureRenderer
## painting fog and sky over a museum diagram, FloraSpawner seeding a biome into
## it, and MushroomHand drawing a player's UI for a viewer with no player.
##
## Silenced rather than removed — an autoload that another system asks for must
## still answer; it simply must not process or paint. Anything not on this list
## is left alone deliberately.
func _quiet_autoloads() -> void:
	var noisy: Array = ["NatureRenderer", "FloraSpawner", "EcosystemManager",
		"BiomeAccrualManager", "MushroomHand", "Subtitles", "SceneNarrator",
		"StuckDetector", "DeathEffect", "HazardManager", "SoundBank"]
	var hushed: Array = []
	for n_name in noisy:
		var n: Node = get_node_or_null("/root/%s" % n_name)
		if n == null:
			continue
		n.set_process(false)
		n.set_physics_process(false)
		_hide_visuals(n)
		hushed.append(n_name)
	print("[viewer] quieted %d autoloads: %s" % [hushed.size(), ", ".join(hushed)])


func _hide_visuals(n: Node) -> void:
	if n is CanvasItem:
		(n as CanvasItem).visible = false
	elif n is CanvasLayer:
		(n as CanvasLayer).visible = false
	elif n is Node3D:
		(n as Node3D).visible = false
	for c in n.get_children():
		_hide_visuals(c)


func _build_world() -> void:
	## NO WorldEnvironment — ON PURPOSE, and this is the second attempt.
	##
	## NatureRenderer finds whatever WorldEnvironment is in the scene and mutates
	## THAT RESOURCE IN PLACE, tweening ambient_light_color and re-enabling fog.
	## Two things follow. Comparing `env.environment != my_resource` each frame
	## can never catch it, because the resource is still mine — it has just been
	## repainted; and set_process(false) does not stop it either, because a Tween
	## is driven by the SceneTree, not by the node that started it. The first two
	## shots came back a flat green wash for exactly this reason.
	##
	## Camera3D.environment takes priority over the world one, so hanging it on
	## the camera means NatureRenderer finds nothing, says so, and disables
	## itself — which is the behaviour its own warning already describes.
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.08, 0.09, 0.11)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.58, 0.66)
	e.ambient_light_energy = 1.0
	# no fog: a hall is 75 m long and this is a diagram, not a mood. The first
	# shot came back a flat green wash largely because of it.
	e.fog_enabled = false
	_env_res = e

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, 38.0, 0.0)
	sun.light_energy = 1.1
	add_child(sun)

	_pivot = Node3D.new()
	add_child(_pivot)
	_cam = Camera3D.new()
	_cam.current = true
	_cam.far = 900.0
	_cam.environment = _env_res     # overrides any WorldEnvironment; see above
	_pivot.add_child(_cam)

	# TWO MULTIMESHES, NOT 952 NODES. A hall is 34x28 cells; one MeshInstance3D
	# each would be a thousand nodes rebuilt on every hall change.
	_solid = _make_mm(Color(0.30, 0.33, 0.39), 1.0)
	_floor = _make_mm(Color(0.16, 0.18, 0.21), 0.08)
	add_child(_solid)
	add_child(_floor)

	_player_mark = _make_mark(Color(0.31, 0.82, 0.78), "you")
	_ghost_mark = _make_mark(Color(0.30, 0.95, 0.55), "walker")
	_ghost_mark.visible = false
	add_child(_player_mark)
	add_child(_ghost_mark)

	_trail_line = MeshInstance3D.new()
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.31, 0.82, 0.78)
	tm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tm.vertex_color_use_as_albedo = false
	_trail_line.material_override = tm
	add_child(_trail_line)

	var layer := CanvasLayer.new()
	add_child(layer)
	_text = Label.new()
	_text.position = Vector2(16, 12)
	_text.add_theme_font_size_override("font_size", 14)
	_text.add_theme_color_override("font_color", Color(0.90, 0.93, 0.98))
	_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_text.add_theme_constant_override("outline_size", 5)
	layer.add_child(_text)


func _make_mm(col: Color, alpha_h: float) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bm := BoxMesh.new()
	bm.size = Vector3(CELL * 0.98, 1.0, CELL * 0.98)
	mm.mesh = bm
	mm.instance_count = 0
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.95
	mmi.material_override = mat
	return mmi


func _make_mark(col: Color, tag_text: String) -> Node3D:
	var n := Node3D.new()
	var m := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.22
	cap.height = 1.8
	m.mesh = cap
	m.position = Vector3(0, 0.9, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.5
	m.material_override = mat
	n.add_child(m)
	var tag := Label3D.new()
	tag.text = tag_text
	tag.position = Vector3(0, 2.15, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.font_size = 44
	tag.pixel_size = 0.0025
	tag.modulate = col
	n.add_child(tag)
	return n


## ————————————————————————————————————————————————————————————————————
## The link — same socket, introduced as a viewer
## ————————————————————————————————————————————————————————————————————

func _connect() -> void:
	_peer = StreamPeerTCP.new()
	if _peer.connect_to_host(HOST, PORT) != OK:
		_peer = null


func _process(delta: float) -> void:
	_pump(delta)
	_aim(delta)
	_paint()
	if _shot_path != "":
		_shot_after -= delta
		if _shot_after <= 0.0:
			var p: String = _shot_path
			_shot_path = ""
			await RenderingServer.frame_post_draw
			var img: Image = get_viewport().get_texture().get_image()
			img.save_png(ProjectSettings.globalize_path(p))
			print("[viewer] shot -> %s" % p)
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
	# introduce ourselves once, so the server knows not to treat us as the game
	if _rx == "" and _pose.is_empty() and not _said_hello:
		_said_hello = true
		_say({"k": "hello", "role": "viewer"})
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
			_on_pose(v as Dictionary)

var _said_hello := false


func _say(d: Dictionary) -> void:
	if _peer != null:
		_peer.put_data((JSON.stringify(d) + "\n").to_utf8_buffer())


func _on_pose(d: Dictionary) -> void:
	_pose = d
	_last_pose_ms = Time.get_ticks_msec()
	var p: Vector3 = _vec(d.get("pos", []))
	_player_mark.global_position = p
	if _trail.is_empty() or _trail[_trail.size() - 1].distance_to(p) > 0.25:
		_trail.append(p)
		if _trail.size() > 1200:
			_trail.remove_at(0)
	var g: Variant = d.get("ghost")
	_ghost_mark.visible = g != null
	if g != null:
		_ghost_mark.global_position = _vec(g)
	_ensure_geometry()


func _vec(a: Variant) -> Vector3:
	if a is Array and (a as Array).size() >= 3:
		var arr: Array = a as Array
		return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
	return Vector3.ZERO


## ————————————————————————————————————————————————————————————————————
## The museum's own record
## ————————————————————————————————————————————————————————————————————

func _load_walk() -> void:
	if not FileAccess.file_exists(WALK_PATH):
		print("[viewer] no %s — halls will not draw. Walk the museum once." % WALK_PATH)
		return
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(WALK_PATH))
	if v is Dictionary and (v as Dictionary).has("halls"):
		_halls = (v as Dictionary)["halls"]
		print("[viewer] %d halls from the museum's own layout record" % _halls.size())


## Rebuild only when the hall (or its live z) actually changes. The pose arrives
## 20 times a second and the geometry changes once a hall.
func _ensure_geometry() -> void:
	var hall: Variant = _pose.get("hall")
	if hall is Dictionary and String((hall as Dictionary).get("pearl", "")) != "":
		var h: Dictionary = hall
		var key: String = "%s|%s" % [_chapter_of(h), String(h.get("pearl", ""))]
		var z0: float = float(h.get("z0", 0.0))
		if key == _drawn_key and is_equal_approx(z0, _drawn_z0):
			return
		if _halls.has(key):
			_draw_hall(_halls[key], z0)
			_drawn_key = key
			_drawn_z0 = z0
			return
	# not the museum (or an unwalked hall): fall back to the authored map
	var m: String = String(_pose.get("map", ""))
	if m != "" and m != _drawn_key:
		if _draw_map(m):
			_drawn_key = m


## The hall row carries `cells` (rows of "#" solid / "." open / "p" passage) and
## `cell_x0`. Row r of that grid is at absolute z0 + r, which is why the live z0
## has to come over the wire — the record deliberately stores no absolute z,
## because it depends on where the walk began.
func _draw_hall(row_v: Variant, z0: float) -> void:
	var row: Dictionary = row_v
	var cells: Array = row.get("cells", []) as Array
	var x0: float = float(row.get("cell_x0", 0.0))
	var solid: Array = []
	var open: Array = []
	for r in range(cells.size()):
		var line: String = String(cells[r])
		for c in range(line.length()):
			var ch: String = line[c]
			var t := Transform3D(Basis.IDENTITY, Vector3(x0 + float(c), 0.0, z0 + float(r)))
			if ch == "#":
				t = t.scaled_local(Vector3(1, 3.0, 1))
				t.origin.y = 1.5
				solid.append(t)
			elif ch == "." or ch == "p":
				open.append(t)
	_fill(_solid, solid)
	_fill(_floor, open)
	# frame the hall we just built rather than keeping whatever the last zoom was
	# half the span, not all of it: framing the whole 75 m hall puts the person
	# you are watching four pixels wide at the far end. Wheel out for the hall,
	# in for the body.
	var span: float = float(row.get("span", 40.0))
	_dist = clampf(span * 0.5, 20.0, 90.0)
	print("[viewer] hall %s — %d solid, %d open, z %0.1f..%0.1f, span %0.0f"
		% [String(row.get("map", "?")), solid.size(), open.size(), z0, z0 + span, span])


func _draw_map(name: String) -> bool:
	var p: String = "res://commons/maps/%s/map_data.json" % name
	if not FileAccess.file_exists(p):
		return false
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not (v is Dictionary):
		return false
	var d: Dictionary = v
	var layers: Dictionary = d.get("layers", {})
	var st: Array = layers.get("structure", []) as Array
	var settings: Dictionary = d.get("settings", {})
	var total: float = float(settings.get("cube_size", 1.0)) + float(settings.get("gutter", 0.0))
	var solid: Array = []
	var open: Array = []
	for r in range(st.size()):
		var rowv: Array = st[r] as Array
		for c in range(rowv.size()):
			var hgt: int = int(str(rowv[c]))
			if hgt <= 0:
				continue
			var t := Transform3D(Basis.IDENTITY, Vector3(float(c) * total, 0.0, float(r) * total))
			if hgt > 1:
				t = t.scaled_local(Vector3(1, float(hgt), 1))
				t.origin.y = float(hgt) * 0.5
				solid.append(t)
			else:
				open.append(t)
	_fill(_solid, solid)
	_fill(_floor, open)
	print("[viewer] map %s — %d solid, %d floor" % [name, solid.size(), open.size()])
	return true


func _fill(mmi: MultiMeshInstance3D, xforms: Array) -> void:
	var mm: MultiMesh = mmi.multimesh
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])


func _chapter_of(h: Dictionary) -> String:
	# the pose carries the map name, the record is keyed by chapter — look the
	# chapter up rather than asking the museum for a second field
	var want: String = String(h.get("map", ""))
	for k_v in _halls.keys():
		var k: String = k_v
		if String((_halls[k] as Dictionary).get("map", "")) == want:
			return k.split("|")[0]
	return ""


## ————————————————————————————————————————————————————————————————————
## Camera, text, input
## ————————————————————————————————————————————————————————————————————

func _aim(delta: float) -> void:
	var target: Vector3 = _player_mark.global_position
	if _follow:
		_pivot.global_position = _pivot.global_position.lerp(target, clampf(delta * 4.0, 0.0, 1.0))
	if _topdown:
		_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		_cam.size = _dist
		_cam.position = Vector3(0, 60, 0.01)
		_cam.rotation = Vector3(-PI * 0.5, 0, 0)
	else:
		_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		var cp: float = cos(_pitch)
		_cam.position = Vector3(sin(_yaw) * cp, sin(_pitch), cos(_yaw) * cp) * _dist
		_cam.look_at(_pivot.global_position, Vector3.UP)


func _paint() -> void:
	# the trail, as one line strip rebuilt from the points
	if _trail.size() >= 2:
		var im := ImmediateMesh.new()
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for v in _trail:
			im.surface_add_vertex(v + Vector3(0, 0.06, 0))
		im.surface_end()
		_trail_line.mesh = im

	var lines: Array = []
	var live: bool = _peer != null and _peer.get_status() == StreamPeerTCP.STATUS_CONNECTED
	var age: int = Time.get_ticks_msec() - _last_pose_ms
	var stale: bool = (not _pose.is_empty()) and age > STALE_MS
	var state: String = "waiting for the server"
	if live:
		state = "server ok — no game attached" if _pose.is_empty() \
			else ("STALE %.1fs" % (age / 1000.0) if stale else "live from the headset")
	lines.append("VR LINK VIEWER    %s" % state)
	if _pose.is_empty():
		lines.append("no pose yet — is the headset armed?  python tools/vr_link.py --headset")
	else:
		if stale:
			lines.append("!! LAST known position, not a current one")
		var p: Vector3 = _vec(_pose.get("pos", []))
		lines.append("map    %s" % String(_pose.get("map", "?")))
		var hall: Variant = _pose.get("hall")
		if hall is Dictionary:
			var h: Dictionary = hall
			if String(h.get("pearl", "")) != "":
				lines.append("hall   %s   [%s]  #%d" % [
					String(h.get("map", "")), String(h.get("pearl", "")), int(h.get("index", -1))])
				lines.append("       %.0f%% through   z %.1f .. %.1f   w %d" % [
					float(h.get("through", 0.0)) * 100.0,
					float(h.get("z0", 0.0)), float(h.get("z1", 0.0)), int(h.get("w", 0))])
			else:
				lines.append("hall   between segments (only 2 stream at once)")
		lines.append("pos    %6.2f %6.2f %6.2f" % [p.x, p.y, p.z])
		if _pose.has("yaw"):
			lines.append("yaw    %.0f deg" % (float(_pose["yaw"]) * 180.0 / PI))
		lines.append("trail  %d points" % _trail.size())
	lines.append("")
	lines.append("drag orbit · wheel zoom · [T] top-down %s · [F] follow %s · click teleports"
		% ["ON" if _topdown else "off", "ON" if _follow else "off"])
	_text.text = "\n".join(lines)


func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		var mb: InputEventMouseButton = ev
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
			if not mb.pressed:
				pass
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_dist = maxf(4.0, _dist * 0.88)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_dist = minf(300.0, _dist * 1.14)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_teleport_at(mb.position)
	elif ev is InputEventMouseMotion and _dragging:
		var mm: InputEventMouseMotion = ev
		_yaw -= mm.relative.x * 0.008
		_pitch = clampf(_pitch + mm.relative.y * 0.006, 0.08, 1.5)
	elif ev is InputEventKey and (ev as InputEventKey).pressed:
		var k: InputEventKey = ev
		if k.keycode == KEY_T:
			_topdown = not _topdown
		elif k.keycode == KEY_F:
			_follow = not _follow


## RIGHT-CLICK TELEPORTS, so a drag-orbit cannot fire one by accident. The ray
## is dropped onto y=0 rather than raycast against bodies: the geometry here is
## a MultiMesh with no colliders, and the floor is the only plane that matters.
func _teleport_at(screen: Vector2) -> void:
	var from: Vector3 = _cam.project_ray_origin(screen)
	var dir: Vector3 = _cam.project_ray_normal(screen)
	if absf(dir.y) < 0.0001:
		return
	var t: float = -from.y / dir.y
	if t <= 0.0:
		return
	var hit: Vector3 = from + dir * t
	_say({"cmd": "goto", "pos": [hit.x, 0.0, hit.z]})
	print("[viewer] goto %.2f 0 %.2f" % [hit.x, hit.z])
