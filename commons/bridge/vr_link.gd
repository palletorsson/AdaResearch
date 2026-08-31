extends Node
## VR LINK — the headset and the PC on one wire.
##
## 2026-08-31, Palle: "Can we play the game in vr send the coordinate over usb to
## the desktop app showing the 3d view a top down view and a text one the pc
## screen. And visa versa. Have the python walker walk around in vr?"
##
## THE CABLE IS ALREADY A NETWORK. `adb reverse tcp:8771 tcp:8771` makes the
## headset's OWN 127.0.0.1:8771 come out of the USB cable on the PC's
## 127.0.0.1:8771 — no wifi, no IP address to configure, no router in the way.
## Godot's editor already does this for its remote debugger on 6007, so the
## mechanism is not exotic; it is the one the toolchain uses on itself.
##
## Which means THERE IS NO ANDROID CODE HERE. The same StreamPeerTCP to
## 127.0.0.1 is a loopback socket on the desktop and a USB tunnel on the Quest,
## and every other bridge in this project (em_control.json, mapsim_control.json,
## desktop_feedback.md) is a FILE poll that cannot cross to a headset at all —
## user:// on the Quest is on the Quest. This is the first one that can.
##
## The APK already installed carries android.permission.INTERNET (verified with
## `adb shell dumpsys package`), so nothing needs rebuilding to use this.
##
##   PC:   python tools/vr_link.py            # sets up adb reverse, serves :8772
##   VR:   already listening, if it was armed (see GATING)
##
## GATING — dormant unless asked for. A live map must be untouched by this file
## existing. It arms on `--vr-link` (desktop) or the presence of
## `user://vr_link.on` (the headset, which has no command line — vr_link.py
## pushes that file with the same run-as trick push_map_to_quest.ps1 uses).
## Unarmed, _ready() disables processing and returns: no socket, no timer, no cost.

const HOST := "127.0.0.1"
const PORT := 8771
const SEND_HZ := 20.0
## Retry a dropped/absent server at a human pace. The server is usually started
## AFTER the game, so this is the normal path, not an error path.
const RETRY_S := 2.0

var _peer: StreamPeerTCP = null
var _armed := false
var _accum := 0.0
var _retry := 0.0
var _rx := ""
var _seq := 0

## The ghost the python walker drives. Built on first use, never before.
var _ghost: Node3D = null
var _ghost_path: Array = []
var _ghost_i := 0
var _ghost_speed := 1.4          # m/s — an unhurried museum walk
var _ghost_loop := false


func _ready() -> void:
	_armed = _arm_requested()
	if not _armed:
		set_process(false)
		return
	print("[vr-link] armed — dialling %s:%d (adb reverse makes this the PC over USB)" % [HOST, PORT])
	_connect()


## Two ways in, because the headset has no command line.
func _arm_requested() -> bool:
	# BOTH lists. get_cmdline_args() holds what came before a `--` separator and
	# get_cmdline_user_args() what came after; this project's own scenes use the
	# second (DesktopMapTester reads --map= from it), so a flag typed the natural
	# way next to --map= would otherwise be silently ignored.
	for a in OS.get_cmdline_args():
		if String(a).begins_with("--vr-link"):
			return true
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--vr-link"):
			return true
	return FileAccess.file_exists("user://vr_link.on")


func _connect() -> void:
	_peer = StreamPeerTCP.new()
	# NON-BLOCKING. connect_to_host returns immediately; poll() advances the
	# handshake. A blocking connect here would stall the render thread for the
	# OS connect timeout every retry, which on a headset reads as the game
	# hanging — the whole point of arming this is that it must be invisible.
	var err: int = _peer.connect_to_host(HOST, PORT)
	if err != OK:
		_peer = null


func _process(delta: float) -> void:
	if _peer == null:
		_retry += delta
		if _retry >= RETRY_S:
			_retry = 0.0
			_connect()
		return

	_peer.poll()
	var st: int = _peer.get_status()
	if st == StreamPeerTCP.STATUS_CONNECTING:
		return
	if st != StreamPeerTCP.STATUS_CONNECTED:
		# server gone or never there — drop it and retry on the slow clock
		_peer = null
		_retry = 0.0
		return

	_pump_in()

	_accum += delta
	if _accum >= 1.0 / SEND_HZ:
		_accum = 0.0
		_send(_pose())

	_step_ghost(delta)


## ————————————————————————————————————————————————————————————————————
## Wire — newline-delimited JSON, both directions
## ————————————————————————————————————————————————————————————————————
##
## NDJSON rather than a length-prefixed frame: it is debuggable with netcat, a
## partial read can never desynchronise the stream permanently, and a malformed
## line costs one line rather than the connection.

func _send(d: Dictionary) -> void:
	if _peer == null:
		return
	_peer.put_data((JSON.stringify(d) + "\n").to_utf8_buffer())


func _pump_in() -> void:
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
		var parsed: Variant = JSON.parse_string(line)
		if parsed is Dictionary:
			_command(parsed as Dictionary)


## ————————————————————————————————————————————————————————————————————
## Uplink — where the body is
## ————————————————————————————————————————————————————————————————————

func _pose() -> Dictionary:
	_seq += 1
	var d: Dictionary = {"k": "pose", "seq": _seq, "t": Time.get_ticks_msec() / 1000.0}

	var origin: Node3D = _xr_origin()
	var cam: Node3D = _camera()
	var body: Node3D = _player_body()

	var feet: Node3D = body if body != null else origin
	if feet != null:
		d["pos"] = _v3(feet.global_position)
	if cam != null:
		d["head"] = _v3(cam.global_position)
		# yaw only: the top-down view wants a heading, not a quaternion
		var f: Vector3 = -cam.global_basis.z
		d["yaw"] = atan2(f.x, f.z)
		d["pitch"] = asin(clampf(f.y, -1.0, 1.0))
	var hands: Array = []
	if origin != null:
		for c in origin.get_children():
			if c is XRController3D:
				hands.append({"n": String(c.name), "p": _v3((c as Node3D).global_position)})
	if not hands.is_empty():
		d["hands"] = hands

	d["map"] = _map_name()
	if _ghost != null:
		d["ghost"] = _v3(_ghost.global_position)
	return d


func _v3(v: Vector3) -> Array:
	# 4 decimals: a tenth of a millimetre, and it keeps the line short enough
	# that 20 Hz over USB is nothing at all.
	return [snappedf(v.x, 0.0001), snappedf(v.y, 0.0001), snappedf(v.z, 0.0001)]


func _map_name() -> String:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		for prop in ["current_map", "current_map_name", "map_name"]:
			var v: Variant = gm.get(prop)
			if v != null and String(v) != "":
				return String(v)
	var cur: Node = get_tree().current_scene
	return String(cur.name) if cur != null else ""


## ————————————————————————————————————————————————————————————————————
## Finding the body — the same strategies StuckDetector uses, and for the same
## reason: there is no one node called "the player" in this project.
## ————————————————————————————————————————————————————————————————————

func _xr_origin() -> Node3D:
	var l: Array = get_tree().get_nodes_in_group("player")
	for n in l:
		if n is XROrigin3D:
			return n as Node3D
	var found: Node = _first_of_class(get_tree().root, "XROrigin3D")
	return found as Node3D


func _camera() -> Node3D:
	var o: Node3D = _xr_origin()
	if o != null:
		for c in o.get_children():
			if c is XRCamera3D:
				return c as Node3D
	var vp: Viewport = get_viewport()
	return vp.get_camera_3d() if vp != null else null


func _player_body() -> Node3D:
	for g in ["player_body", "player"]:
		var l: Array = get_tree().get_nodes_in_group(g)
		for n in l:
			if n is Node3D and not (n is XROrigin3D):
				return n as Node3D
	return null


func _first_of_class(n: Node, cls: String) -> Node:
	if n.is_class(cls):
		return n
	for c in n.get_children():
		var r: Node = _first_of_class(c, cls)
		if r != null:
			return r
	return null


## ————————————————————————————————————————————————————————————————————
## Downlink — the PC talking back
## ————————————————————————————————————————————————————————————————————

func _command(c: Dictionary) -> void:
	match String(c.get("cmd", "")):
		"ping":
			_send({"k": "pong", "t": Time.get_ticks_msec() / 1000.0})
		"goto":
			_goto(_to_v3(c.get("pos", [])))
		"walker":
			_walker(c)
		"walker_stop":
			if _ghost != null:
				_ghost.queue_free()
				_ghost = null
			_ghost_path = []
			_send({"k": "log", "msg": "walker cleared"})
		"say":
			print("[vr-link] PC says: %s" % String(c.get("msg", "")))
		_:
			_send({"k": "log", "msg": "unknown cmd %s" % String(c.get("cmd", ""))})


func _to_v3(a: Variant) -> Vector3:
	if a is Array and (a as Array).size() >= 3:
		var arr: Array = a as Array
		return Vector3(float(arr[0]), float(arr[1]), float(arr[2]))
	return Vector3.ZERO


## Put the player somewhere. THE ORIGIN MOVES, NOT THE CAMERA — in room-scale VR
## the camera is where the human's head physically is and is not ours to set;
## moving it desynchronises the view from the tracking and is a reliable way to
## make someone ill. Shifting XROrigin3D moves the whole play space instead,
## which is what every legitimate teleport in this project does.
func _goto(p: Vector3) -> void:
	var body: Node3D = _player_body()
	var o: Node3D = _xr_origin()
	var target: Node3D = body if body != null else o
	if target == null:
		_send({"k": "log", "msg": "goto: no player found"})
		return
	target.global_position = p
	if "velocity" in target:
		target.set("velocity", Vector3.ZERO)
	_send({"k": "log", "msg": "goto %.2f %.2f %.2f" % [p.x, p.y, p.z]})


## ————————————————————————————————————————————————————————————————————
## The python walker, given a body
## ————————————————————————————————————————————————————————————————————
##
## tools/place.py's humanoid_walker decides placements by WALKING the room — it
## produces a move_path of grid cells and a decision at each one. Until now that
## path has only ever been an SVG (tools/placement_trajectory.py). Here it is
## handed world coordinates and a capsule, and walks the actual room while you
## stand in it. The point is not the marker; it is that the placement engine's
## reasoning becomes something you can be in the room WITH.

func _walker(c: Dictionary) -> void:
	var raw: Array = c.get("path", []) as Array
	_ghost_path = []
	for p in raw:
		_ghost_path.append(_to_v3(p))
	_ghost_i = 0
	_ghost_speed = float(c.get("speed", 1.4))
	_ghost_loop = bool(c.get("loop", false))
	if _ghost_path.is_empty():
		_send({"k": "log", "msg": "walker: empty path"})
		return
	_ensure_ghost()
	_ghost.global_position = _ghost_path[0]
	_send({"k": "log", "msg": "walker: %d waypoints at %.1f m/s" % [_ghost_path.size(), _ghost_speed]})


func _ensure_ghost() -> void:
	if _ghost != null and is_instance_valid(_ghost):
		return
	_ghost = Node3D.new()
	_ghost.name = "PythonWalker"

	var m := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.18
	cap.height = 1.7
	m.mesh = cap
	m.position = Vector3(0, 0.85, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.95, 0.55, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.20, 0.80, 0.40)
	mat.emission_energy_multiplier = 0.6
	# no shadow: it is a diagram standing in the room, not a person in it
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.material_override = mat
	_ghost.add_child(m)

	var tag := Label3D.new()
	tag.text = "humanoid_walker"
	tag.position = Vector3(0, 1.95, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.font_size = 48
	tag.pixel_size = 0.0018
	tag.modulate = Color(0.55, 1.0, 0.70)
	_ghost.add_child(tag)

	# parent to the scene, not to this autoload: an autoload survives map
	# changes and the ghost must not — a walker from the last room standing in
	# this one is a bug that looks like a feature.
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_tree().root
	host.add_child(_ghost)


func _step_ghost(delta: float) -> void:
	if _ghost == null or not is_instance_valid(_ghost) or _ghost_path.is_empty():
		return
	if _ghost_i >= _ghost_path.size() - 1:
		if _ghost_loop:
			_ghost_i = 0
			_ghost.global_position = _ghost_path[0]
		return
	var target: Vector3 = _ghost_path[_ghost_i + 1]
	var here: Vector3 = _ghost.global_position
	var step: float = _ghost_speed * delta
	var to_go: float = here.distance_to(target)
	if to_go <= step:
		_ghost.global_position = target
		_ghost_i += 1
	else:
		_ghost.global_position = here + (target - here).normalized() * step
	# face the walk
	var flat: Vector3 = target - _ghost.global_position
	flat.y = 0.0
	if flat.length_squared() > 0.0001:
		_ghost.look_at(_ghost.global_position - flat, Vector3.UP)
