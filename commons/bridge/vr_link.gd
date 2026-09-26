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
##
## ————————————————————————————————————————————————————————————————————
## THE WALKER GETS EYES AND HANDS (2026-09-26)
## ————————————————————————————————————————————————————————————————————
##
## Palle: "We have a python program that can walk through the halls but can we
## make that agent look at the artifact, use path finding and interact with the
## artifacts?"
##
## Until now the PC could only hand the ghost a polyline. Everything the ghost
## "knew" about the room came from map_data.json, read on the PC — where an
## artifact was placed, never what stands there now, and nothing about what it
## can do. Three commands change that, and they are the whole of the upgrade
## on this side; the path finding lives on the PC (tools/vr_agent.py, over
## tools/map_pathfinder.py — the ONE step relation, never restated here).
##
##   scan      what is in the room NOW: every node the grid stamped with
##             `artifact_lookup_name`, its live position, its extent, its cell,
##             and its AFFORDANCES — which of the interaction verbs below it
##             would answer to. Read from the scene, not from the registry, so
##             a placeholder, a freed hall or an artifact the map moved cannot
##             lie to the planner.
##   look      the ghost turns to face one artifact and reports whether it can
##             actually see it (a ray from its eye; a wall in between is named),
##             how far, and what the registry says it is. A gaze line is drawn
##             for the person in the headset, so the walker's attention is
##             visible in the room.
##   interact  the same ladder DesktopPlayer._try_interact climbs, one rung at
##             a time and reported: interact() → activate() → the `activated`
##             signal → a push button's trigger() → a trigger volume entered
##             (touch) → carried in the hand (grab / use / drop). A teleporter
##             is never taken by `auto` — it would move the PERSON to the next
##             map — only by the explicit verb `teleport`.
##
## THE GHOST CAN HAVE A BODY. `walker` with `body: true` builds it as a
## CharacterBody3D on layer 20 — the grid's player layer — so an artifact's own
## trigger volume sees it walk in, exactly as it sees a player. It is NOT in
## the `player` / `player_body` groups and its name contains neither "Player"
## nor "XR": every handler that would hurt or move the person (DangerZone,
## QuitGameController, configurable_portal, jump_pad, ResetPlayerController,
## subtitle_trigger) filters on exactly those, so the walker crossing a fire
## zone costs the wearer nothing. Transport cubes and health crosses accept
## `em_walker`, which it is. When a `touch` is asked for by name the body is
## put in the player groups for the length of ONE synchronous emit and taken
## out again — the artifact is told a player entered, because that is what the
## agent means, and nothing that polls groups later can see it.
##
## PROTOCOL, newline-delimited JSON. Downlink (PC → game), by `cmd`:
##   ping, say{msg}, goto{pos}, walker_stop
##   walker{path:[[x,y,z]..] | cells:[[row,col]..], speed, loop, body, report,
##          snap, cube, gutter, centre}    cells are converted by the LIVE grid
##          (GridStructureComponent.grid_to_world) and every waypoint is dropped
##          onto the floor by a ray, so the walker stands on the deck rather
##          than at y=0 inside it. report:true answers with `walker_done`.
##   scan{}                              → {k:"scene", artifacts, utilities, cell}
##   look{token|cell|index|pos, dwell}   → {k:"seen", ...}
##   interact{token|cell|index, verb}    → {k:"acted", ok, verb, detail}
##          verb: auto | interact | activate | signal | press | touch | grab |
##                use | drop | teleport
##   where{}                             → {k:"ghost", pos, cell}
## Uplink (game → PC), by `k`: pose (20 Hz), log, pong, scene, seen, acted,
##   ghost, walker_done, activated (the grid's own interactable_activated,
##   forwarded — the game confirming an interaction in its own words).

const HOST := "127.0.0.1"
const PORT := 8771
const SEND_HZ := 20.0
## Retry a dropped/absent server at a human pace. The server is usually started
## AFTER the game, so this is the normal path, not an error path.
const RETRY_S := 2.0

## Layer 20 — the grid's player layer (DangerZone, subtitle_trigger, jump_pad,
## force_pad and every DetectionArea mask 524288). The ghost's body lives there
## so trigger volumes see it; see the header for why that is safe.
const PLAYER_LAYER := 1 << 19
## How many nodes a scan will visit before it stops and says so. The endless
## museum keeps two segments live and they are large; an authored map is a
## few thousand nodes.
const SCAN_NODE_CAP := 60000
## How many meshes an artifact's extent is merged over. The capture pipeline's
## AABB has the same shape and the same caveat: MeshInstance3D only.
const AABB_MESH_CAP := 300
const EYE_HEIGHT := 1.55

var _peer: StreamPeerTCP = null
var _armed := false
var _accum := 0.0
var _retry := 0.0
var _rx := ""
var _seq := 0

## The endless museum, when we are in it. Cached — resolving it every pose frame
## would walk the scene root 20 times a second for an answer that changes once
## per map load.
var _museum_node: Node = null

## The ghost the python walker drives. Built on first use, never before.
var _ghost: Node3D = null
var _ghost_path: Array = []
var _ghost_i := 0
var _ghost_speed := 1.4          # m/s — an unhurried museum walk
var _ghost_loop := false
## Whether the ghost was built with a CharacterBody3D (see the header).
var _ghost_has_body := false
## Answer with `walker_done` when the current path ends (non-loop only).
var _ghost_report := false
## Once the path ends, turn to face this, if set. What a visitor does on
## arriving in front of a work: stops, and turns to it.
var _ghost_face: Variant = null
## The `tag` of the walker command being walked, returned on walker_done.
var _ghost_cmd_tag: Variant = null
var _ghost_tag: Label3D = null
var _ghost_hand: Node3D = null

## The gaze line drawn by `look`, and when it goes.
var _gaze: MeshInstance3D = null
var _gaze_until_ms := 0

## What the hand holds, and how to put it back the way it was.
var _held: Node3D = null
var _held_freeze := false
var _held_layer := 0
var _held_mask := 0

## The last scan, so `look`/`interact` may say `index: 3` instead of a token
## that six placements share. Re-resolved live on use — a scan is a snapshot.
var _scan: Array = []

## Grid systems whose `interactable_activated` this node already forwards.
var _hooked_grids: Dictionary = {}
var _hook_accum := 0.0


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
	_tick_gaze()
	_forget_freed_held()
	_hook_grids(delta)

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
	var hall: Dictionary = _hall()
	if not hall.is_empty():
		d["hall"] = hall
	if _ghost != null and is_instance_valid(_ghost):
		d["ghost"] = _v3(_ghost.global_position)
	return d


## ————————————————————————————————————————————————————————————————————
## THE MUSEUM IS NOT A MAP
## ————————————————————————————————————————————————————————————————————
##
## 196 halls stream past a single cursor, so there is no map_data.json to look
## up and no one room to draw — which is why the browser views show "no authored
## map" the moment you walk into it. What there IS is the engine's own segment
## list, [{node, z0, z1, index, w, pearl, map}], and the hall you are standing in
## is simply the one whose z-range contains you.
##
## READ FROM THE OUTSIDE, NEVER EDITED IN. endless_museum.gd is nineteen
## thousand lines that another session commits to constantly; adding a reporting
## hook inside it would collide. GDScript privacy is a convention, so `get()`
## reads _segments perfectly well from here, and if the museum is refactored
## this returns an empty dictionary instead of breaking anything.
func _museum() -> Node:
	if _museum_node != null and is_instance_valid(_museum_node):
		return _museum_node
	var cur: Node = get_tree().current_scene
	if cur == null:
		return null
	# by capability, not by name: endless_museum.tscn, _vr and _staged all wrap
	# the same script, and only one of them is called EndlessMuseum
	if cur.get("_segments") != null:
		_museum_node = cur
		return cur
	for c in cur.get_children():
		if c.get("_segments") != null:
			_museum_node = c
			return c
	return null


func _hall() -> Dictionary:
	var mus: Node = _museum()
	if mus == null:
		return {}
	var segs_v: Variant = mus.get("_segments")
	if not (segs_v is Array):
		return {}
	var z: float = 0.0
	var body: Node3D = _player_body()
	if body == null:
		var o: Node3D = _xr_origin()
		if o == null:
			return {}
		z = o.global_position.z
	else:
		z = body.global_position.z
	for s_v in (segs_v as Array):
		if not (s_v is Dictionary):
			continue
		var s: Dictionary = s_v
		var z0: float = float(s.get("z0", 0.0))
		var z1: float = float(s.get("z1", 0.0))
		if z >= z0 and z <= z1:
			return {
				"pearl": String(s.get("pearl", "")),
				"map": String(s.get("map", "")),
				"index": int(s.get("index", -1)),
				"z0": snappedf(z0, 0.01), "z1": snappedf(z1, 0.01),
				"w": int(s.get("w", 0)),
				# how far through this hall, 0..1 — the one number a strip view
				# needs that a raw z cannot give
				"through": snappedf((z - z0) / maxf(0.001, z1 - z0), 0.001),
			}
	# between segments, or ahead of the stream window (only 2 are ever live)
	return {"pearl": "", "map": "", "index": -1, "z0": 0.0, "z1": 0.0, "w": 0,
		"through": 0.0}


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


## THE MUSEUM WALKER IS NOT A "PLAYER" — the standing lesson, and it bit here
## exactly as recorded: in the endless museum this reported no position at all,
## silently, for twenty polls. The museum builds its own `_player:
## CharacterBody3D` and puts it in NO group, so both group lookups miss and the
## XROrigin3D fallback misses too (desktop museum has no XR rig). Ask the museum
## for its walker before falling back to the conventions.
func _player_body() -> Node3D:
	var mus: Node = _museum()
	if mus != null:
		var mp: Variant = mus.get("_player")
		if mp is Node3D and is_instance_valid(mp):
			return mp as Node3D
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
##
## Every handler RETURNS its reply and _command sends it, so a headless probe
## can call _command() with no socket and read the answer — the branch a test
## cannot reach is the branch that rots (probe_vr_link_agent.gd).

func _command(c: Dictionary) -> Dictionary:
	var reply: Dictionary = {}
	match String(c.get("cmd", "")):
		"ping":
			reply = {"k": "pong", "t": Time.get_ticks_msec() / 1000.0}
		"goto":
			reply = _goto(_to_v3(c.get("pos", [])))
		"walker":
			reply = _walker(c)
		"walker_stop":
			_drop_held()
			if _ghost != null and is_instance_valid(_ghost):
				_ghost.queue_free()
			_ghost = null
			_ghost_tag = null
			_ghost_hand = null
			_ghost_path = []
			_ghost_report = false
			_ghost_face = null
			reply = {"k": "log", "msg": "walker cleared"}
		"say":
			print("[vr-link] PC says: %s" % String(c.get("msg", "")))
		"scan":
			reply = _scan_scene()
		"look":
			reply = _look(c)
		"interact":
			reply = _interact(c)
		"where":
			reply = _where()
		_:
			reply = {"k": "log", "msg": "unknown cmd %s" % String(c.get("cmd", ""))}
	# a `tag` on the command rides back on its reply, so the PC can match an
	# answer to the question it asked and never to a stale one
	if not reply.is_empty() and c.has("tag"):
		reply["tag"] = c.get("tag")
	if not reply.is_empty():
		_send(reply)
	return reply


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
func _goto(p: Vector3) -> Dictionary:
	var body: Node3D = _player_body()
	var o: Node3D = _xr_origin()
	var target: Node3D = body if body != null else o
	if target == null:
		return {"k": "log", "msg": "goto: no player found"}
	target.global_position = p
	if "velocity" in target:
		target.set("velocity", Vector3.ZERO)
	return {"k": "log", "msg": "goto %.2f %.2f %.2f" % [p.x, p.y, p.z]}


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
##
## Since 2026-09-26 the path may also arrive as CELLS, from tools/vr_agent.py's
## path finding, and the grid that built the room converts them — one
## implementation of the cell rule, the engine's own, instead of a Python copy
## that `--calibrate` existed to doubt.

func _walker(c: Dictionary) -> Dictionary:
	var want_body: bool = bool(c.get("body", false))
	var snap: bool = bool(c.get("snap", true))
	_ghost_path = []
	if c.has("cells") and (c.get("cells") is Array):
		var cube: float = float(c.get("cube", 1.0))
		var gutter: float = float(c.get("gutter", 0.0))
		var centre: bool = bool(c.get("centre", false))
		var last_y: float = _standing_y()
		for cell_v in (c.get("cells") as Array):
			if not (cell_v is Array) or (cell_v as Array).size() < 2:
				continue
			var cell: Array = cell_v
			var p: Vector3 = _cell_to_world(int(cell[0]), int(cell[1]), cube, gutter, centre)
			p.y = last_y
			if snap:
				p.y = _floor_y(p, last_y)
			last_y = p.y
			_ghost_path.append(p)
	else:
		var raw: Array = c.get("path", []) as Array
		var first: bool = true
		var last_y: float = _standing_y()
		for p_v in raw:
			var p: Vector3 = _to_v3(p_v)
			if snap:
				# the first point's own y is the reference when nothing stood
				# here yet: the humanoid_walker's path arrives at y=0
				p.y = _floor_y(p, p.y if first else last_y)
			first = false
			last_y = p.y
			_ghost_path.append(p)
	_ghost_i = 0
	_ghost_speed = float(c.get("speed", 1.4))
	_ghost_loop = bool(c.get("loop", false))
	_ghost_report = bool(c.get("report", false)) and not _ghost_loop
	_ghost_cmd_tag = c.get("tag", null)
	_ghost_face = null
	if c.has("face"):
		var f: Variant = c.get("face")
		if f is Array and (f as Array).size() >= 3:
			_ghost_face = _to_v3(f)
	if _ghost_path.is_empty():
		_ghost_report = false
		return {"k": "log", "msg": "walker: empty path"}
	_ensure_ghost(want_body)
	_ghost.global_position = _ghost_path[0]
	_set_tag("walking")
	if _ghost_path.size() == 1:
		_arrive()
	return {"k": "log", "msg": "walker: %d waypoints at %.1f m/s%s" % [
		_ghost_path.size(), _ghost_speed, " (with a body)" if _ghost_has_body else ""]}


## The level the walker last stood on — the ghost's, else the person's (who is
## standing on a floor of this very map), else zero.
func _standing_y() -> float:
	if _ghost != null and is_instance_valid(_ghost):
		return _ghost.global_position.y
	var pb: Node3D = _player_body()
	if pb != null:
		return pb.global_position.y
	return 0.0


## The room's own cell rule. GridStructureComponent.grid_to_world is what placed
## the cubes the walker stands on; the fallback is the same arithmetic with the
## numbers the PC sent, for a scene that has no grid (a hall of the museum).
func _cell_to_world(row: int, col: int, cube: float, gutter: float, centre: bool) -> Vector3:
	var sc: Node = _structure_component()
	if sc != null and sc.has_method("grid_to_world"):
		var p: Vector3 = sc.call("grid_to_world", Vector3i(col, 0, row))
		return p
	var total: float = cube + gutter
	var off: float = 0.5 if centre else 0.0
	return Vector3((float(col) + off) * total, 0.0, (float(row) + off) * total)


func _grid_system() -> Node:
	for g in get_tree().get_nodes_in_group("grid_system"):
		if is_instance_valid(g):
			return g
	return null


func _structure_component() -> Node:
	var g: Node = _grid_system()
	if g == null:
		return null
	var sc: Variant = g.get("structure_component")
	if sc is Node and is_instance_valid(sc):
		return sc as Node
	return null


## Stand on what answers. The structure places a height-1 floor cube CENTRED at
## y=0, so its deck is at +0.5; a walker parked at y=0 (what cell_to_world on
## the PC gives) is half inside it. Cast down the cell and stand on the hit,
## as the museum's _hall_start_point does. No hit — void, or no collider yet —
## keeps the y that was given, which is the old behaviour.
##
## FROM HEAD HEIGHT, NOT FROM THE SKY. The first draft cast from 30 m up, and a
## map with a ceiling (most have one: GridSystem._handle_ceiling_generation)
## would have stood the walker on the roof. A body finds the floor from where
## it is: the ray starts a head above the level the walker last stood on
## (`ref_y`), which a ceiling clears and the next step's floor — at most one
## level up or down per cell — does not.
func _floor_y(p: Vector3, ref_y: float) -> float:
	var space: PhysicsDirectSpaceState3D = _space()
	if space == null:
		return p.y
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(p.x, ref_y + 2.2, p.z), Vector3(p.x, ref_y - 6.0, p.z))
	var hit: Dictionary = _ray_without_ghost(space, q)
	if hit.is_empty():
		return p.y
	return float((hit["position"] as Vector3).y) + 0.02


func _space() -> PhysicsDirectSpaceState3D:
	var vp: Viewport = get_viewport()
	if vp == null:
		return null
	var w: World3D = vp.find_world_3d()
	if w == null:
		return null
	return w.direct_space_state


## The ghost's own capsule must not answer a ray cast from its own eye or over
## its own feet. Layer 0 for the length of one query, then back — no exclude
## list, no RID bookkeeping.
func _ray_without_ghost(space: PhysicsDirectSpaceState3D, q: PhysicsRayQueryParameters3D) -> Dictionary:
	var body: CollisionObject3D = null
	if _ghost != null and is_instance_valid(_ghost) and _ghost is CollisionObject3D:
		body = _ghost
	var keep: int = 0
	if body != null:
		keep = body.collision_layer
		body.collision_layer = 0
	var hit: Dictionary = space.intersect_ray(q)
	if body != null:
		body.collision_layer = keep
	return hit


func _ensure_ghost(want_body: bool) -> void:
	if _ghost != null and is_instance_valid(_ghost) and _ghost_has_body == want_body:
		return
	var at: Vector3 = Vector3.ZERO
	if _ghost != null and is_instance_valid(_ghost):
		at = _ghost.global_position
		_drop_held()
		_ghost.queue_free()
	else:
		var pb: Node3D = _player_body()
		if pb != null:
			at = pb.global_position
	_ghost = null
	_ghost_has_body = want_body

	if want_body:
		var cb := CharacterBody3D.new()
		# collides with NOTHING (it is moved by position, never by physics) but
		# stands on the player layer so an Area3D that watches for a player
		# watches it too — the same layer the museum's transport cubes were
		# widened to see (UtilityRegistry.make_carriable).
		cb.collision_layer = PLAYER_LAYER
		cb.collision_mask = 0
		var shape := CollisionShape3D.new()
		var cap_shape := CapsuleShape3D.new()
		cap_shape.radius = 0.18
		cap_shape.height = 1.7
		shape.shape = cap_shape
		shape.position = Vector3(0, 0.85, 0)
		cb.add_child(shape)
		cb.add_to_group("python_walker")
		cb.add_to_group("em_walker")
		_ghost = cb
	else:
		_ghost = Node3D.new()
	# NOT "Player", NOT "XR": DangerZone._is_player and its kin match on the
	# name as well as the groups, and this is the whole reason the body is safe.
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
	tag.text = "python walker"
	tag.position = Vector3(0, 1.95, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.no_depth_test = true
	tag.font_size = 48
	tag.pixel_size = 0.0018
	tag.modulate = Color(0.55, 1.0, 0.70)
	_ghost.add_child(tag)
	_ghost_tag = tag

	# The hand: where a grabbed thing rides. +Z is this ghost's forward (see
	# _face), so the hand sits a little ahead of the chest.
	var hand := Node3D.new()
	hand.name = "Hand"
	hand.position = Vector3(0.3, 1.15, 0.45)
	_ghost.add_child(hand)
	_ghost_hand = hand

	# parent to the scene, not to this autoload: an autoload survives map
	# changes and the ghost must not — a walker from the last room standing in
	# this one is a bug that looks like a feature.
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_tree().root
	host.add_child(_ghost)
	_ghost.global_position = at


func _set_tag(text: String) -> void:
	if _ghost_tag != null and is_instance_valid(_ghost_tag):
		_ghost_tag.text = text


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
		if _ghost_i >= _ghost_path.size() - 1 and not _ghost_loop:
			_arrive()
			return
	else:
		_ghost.global_position = here + (target - here).normalized() * step
	# face the walk
	_face(target)


## The walk is over: turn to what was asked for, and say so once. The PC's
## agent sequences on this — walk, then look, then act — so it is sent exactly
## when the last waypoint is reached, not when the command was received.
func _arrive() -> void:
	if _ghost_face is Vector3:
		_face(_ghost_face as Vector3)
	_set_tag("python walker")
	if _ghost_report:
		_ghost_report = false
		var done: Dictionary = {"k": "walker_done", "pos": _v3(_ghost.global_position),
			"waypoints": _ghost_path.size()}
		if _ghost_cmd_tag != null:
			done["tag"] = _ghost_cmd_tag
		_send(done)


## Turn the ghost so its +Z faces a point (yaw only). The original walker faced
## its path with look_at(position - flat), which makes +Z the heading; every
## turn goes through here so the two agree.
func _face(point: Vector3) -> void:
	if _ghost == null or not is_instance_valid(_ghost):
		return
	var flat: Vector3 = point - _ghost.global_position
	flat.y = 0.0
	if flat.length_squared() > 0.0001:
		_ghost.look_at(_ghost.global_position - flat, Vector3.UP)


func _where() -> Dictionary:
	if _ghost == null or not is_instance_valid(_ghost):
		return {"k": "ghost", "pos": null, "cell": null}
	return {"k": "ghost", "pos": _v3(_ghost.global_position),
		"cell": _cell_of(_ghost.global_position)}


## [row, col] of a world point, by the live grid when there is one.
func _cell_of(p: Vector3) -> Variant:
	var sc: Node = _structure_component()
	if sc != null and sc.has_method("world_to_grid"):
		var g: Vector3i = sc.call("world_to_grid", p)
		return [g.z, g.x]
	var gs: Node = _grid_system()
	var total: float = 1.0
	if gs != null:
		total = float(gs.get("cube_size") if gs.get("cube_size") != null else 1.0) \
			+ float(gs.get("gutter") if gs.get("gutter") != null else 0.0)
	return [int(round(p.z / total)), int(round(p.x / total))]


## ————————————————————————————————————————————————————————————————————
## EYES — scan and look
## ————————————————————————————————————————————————————————————————————

## Everything the grid stamped as an artifact, as it stands now.
func _scan_scene() -> Dictionary:
	var root: Node = get_tree().current_scene
	if root == null:
		root = get_tree().root
	var arts: Array = []
	var visited: int = 0
	var truncated: bool = false
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		visited += 1
		if visited > SCAN_NODE_CAP:
			truncated = true
			break
		if n.has_meta("artifact_lookup_name") and n is Node3D:
			arts.append(_record(n as Node3D, arts.size()))
			# the placed thing is the unit; what it embeds is its own business
			continue
		for ch in n.get_children():
			stack.append(ch)
	_scan = arts

	var utils: Array = []
	for u in get_tree().get_nodes_in_group("utility"):
		if not (u is Node3D) or not is_instance_valid(u):
			continue
		var rec: Dictionary = {"name": String(u.name), "pos": _v3((u as Node3D).global_position),
			"path": String(u.get_path())}
		if u.has_method("get_destination"):
			rec["teleporter"] = true
			rec["destination"] = String(u.call("get_destination"))
		elif u.has_method("_start_teleport_sequence"):
			rec["teleporter"] = true
		utils.append(rec)

	var cell: Dictionary = {"cube": 1.0, "gutter": 0.0, "source": "none"}
	var gs: Node = _grid_system()
	if gs != null:
		if gs.get("cube_size") != null:
			cell["cube"] = float(gs.get("cube_size"))
		if gs.get("gutter") != null:
			cell["gutter"] = float(gs.get("gutter"))
		cell["source"] = "grid"
	return {"k": "scene", "map": _map_name(), "artifacts": arts, "utilities": utils,
		"cell": cell, "visited": visited, "truncated": truncated,
		"ghost": _v3(_ghost.global_position) if (_ghost != null and is_instance_valid(_ghost)) else null}


func _record(n: Node3D, index: int) -> Dictionary:
	var box: AABB = _subtree_aabb(n)
	var centre: Vector3 = box.get_center() if box.size.length_squared() > 0.0 else n.global_position + Vector3(0, 0.8, 0)
	var rec: Dictionary = {
		"index": index,
		"token": String(n.get_meta("artifact_lookup_name", "utility:" + String(n.name))),
		"name": String(n.get_meta("artifact_name", "")),
		"type": String(n.get_meta("artifact_type", "")),
		"pos": _v3(n.global_position),
		"centre": _v3(centre),
		"size": _v3(box.size),
		"affordances": _affordances(n),
		"path": String(n.get_path()),
		"placeholder": bool(n.get_meta("is_placeholder_artifact", false)),
	}
	var gc: Variant = n.get_meta("grid_cell", null)
	if gc is Vector2i:
		# grid_cell is Vector2i(x, z); the PC thinks in (row, col) = (z, x)
		rec["cell"] = [(gc as Vector2i).y, (gc as Vector2i).x]
	var desc: String = String(n.get_meta("description", ""))
	if desc != "":
		rec["description"] = desc.substr(0, 240)
	var cfg: Dictionary = {}
	for k in n.get_meta_list():
		var ks: String = String(k)
		if ks.begins_with("config_"):
			cfg[ks.substr(7)] = str(n.get_meta(k))
	if not cfg.is_empty():
		rec["config"] = cfg
	return rec


## Merged world-space extent of the MeshInstance3Ds under a node — the capture
## pipeline's measure, with the capture pipeline's caveat (a MultiMesh reads as
## nothing). Bounded, because a simulation artifact can carry thousands.
func _subtree_aabb(n: Node) -> AABB:
	var box: AABB = AABB()
	var have: bool = false
	var count: int = 0
	var stack: Array = [n]
	while not stack.is_empty() and count < AABB_MESH_CAP:
		var cur: Node = stack.pop_back()
		if cur is MeshInstance3D and (cur as MeshInstance3D).mesh != null and (cur as VisualInstance3D).layers != 0:
			var mi: MeshInstance3D = cur
			var b: AABB = mi.global_transform * mi.get_aabb()
			box = b if not have else box.merge(b)
			have = true
			count += 1
		for ch in cur.get_children():
			stack.append(ch)
	return box if have else AABB()


## Which of the interaction verbs this node would answer to. Read, not guessed:
## the same tests DesktopPlayer._try_interact and DesktopInteractionPointer make
## before they act, run ahead of time and reported.
func _affordances(n: Node) -> Array:
	var out: Array = []
	if _required_args(n, "interact") == 0:
		out.append("interact")
	if _required_args(n, "activate") == 0:
		out.append("activate")
	if n.has_signal("activated"):
		out.append("signal")
	if _button_in(n) != null:
		out.append("press")
	if _pointer_target_in(n) != null:
		out.append("pointer")
	if not _trigger_areas_in(n).is_empty():
		out.append("touch")
	if _grabbable_in(n) != null:
		out.append("grab")
	if n.has_method("get_destination") or n.has_method("_start_teleport_sequence") \
			or n.has_method("_on_teleport_area_body_entered"):
		out.append("teleporter")
	return out


## How many arguments a method needs before it can be called with none. -1 when
## there is no such method. critter_entity.interact(action) and
## capacity_bracelet.activate(modes, controller) both exist and both would
## error if called bare; has_method() alone cannot tell them from origin's.
func _required_args(n: Object, method: String) -> int:
	if not n.has_method(method):
		return -1
	for d_v in n.get_method_list():
		var d: Dictionary = d_v
		if String(d.get("name", "")) != method:
			continue
		var args: Array = d.get("args", [])
		var defaults: Array = d.get("default_args", [])
		return maxi(0, args.size() - defaults.size())
	# a built-in or a method the list does not describe: assume callable bare
	return 0


## The first node under `n` (n included) of one of these kinds, or null.
## Bounded: an artifact that embeds a simulation can carry thousands of nodes.
##   button    a `pressed` signal and a bare trigger() — push_button_2d3d.gd
##   pointer   answers pointer_event() — XR Tools sliders, buttons, knobs
##   grabbable pick_up(), or a rigid body — what the desktop pointer settles on
func _find_kind(n: Node, kind: String, cap: int = 400) -> Node:
	var count: int = 0
	var stack: Array = [n]
	while not stack.is_empty() and count < cap:
		var cur: Node = stack.pop_back()
		count += 1
		var hit: bool = false
		match kind:
			"button":
				hit = cur.has_signal("pressed") and _required_args(cur, "trigger") == 0
			"pointer":
				hit = cur.has_method("pointer_event")
			"grabbable":
				hit = cur is Node3D and (cur.has_method("pick_up") or cur is RigidBody3D)
		if hit:
			return cur
		for ch in cur.get_children():
			stack.append(ch)
	return null


func _button_in(n: Node) -> Node:
	return _find_kind(n, "button")


func _pointer_target_in(n: Node) -> Node:
	return _find_kind(n, "pointer")


## Area3Ds whose body_entered somebody listens to — a trigger volume.
func _trigger_areas_in(n: Node) -> Array:
	var out: Array = []
	var count: int = 0
	var stack: Array = [n]
	while not stack.is_empty() and count < 400:
		var cur: Node = stack.pop_back()
		count += 1
		if cur is Area3D and (cur as Area3D).body_entered.get_connections().size() > 0:
			out.append(cur)
		for ch in cur.get_children():
			stack.append(ch)
	return out


## What the desktop pointer's _find_grabbable would settle on: the nearest
## thing with pick_up(), or a rigid body.
func _grabbable_in(n: Node) -> Node3D:
	return _find_kind(n, "grabbable") as Node3D


## Resolve which artifact a command means: by `index` into the last scan, by
## `cell` [row, col], or by `token` — and when a token is placed more than once,
## the placement nearest the ghost, so "look at the plinth" means the one here.
func _resolve(c: Dictionary) -> Node3D:
	if bool(c.get("utility", false)):
		return _nearest_teleporter()
	if c.has("index"):
		var i: int = int(c.get("index"))
		if i >= 0 and i < _scan.size():
			var rec: Dictionary = _scan[i]
			var n: Node = get_node_or_null(NodePath(String(rec.get("path", ""))))
			if n is Node3D and is_instance_valid(n):
				return n as Node3D
	var token: String = String(c.get("token", ""))
	var want_cell: Variant = c.get("cell", null)
	var here: Vector3 = _ghost.global_position if (_ghost != null and is_instance_valid(_ghost)) else Vector3.ZERO
	var best: Node3D = null
	var best_d: float = 1.0e18
	var root: Node = get_tree().current_scene
	if root == null:
		root = get_tree().root
	var visited: int = 0
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		visited += 1
		if visited > SCAN_NODE_CAP:
			break
		if n.has_meta("artifact_lookup_name") and n is Node3D:
			var ok_token: bool = token == "" or String(n.get_meta("artifact_lookup_name")) == token
			var ok_cell: bool = true
			if want_cell is Array and (want_cell as Array).size() >= 2:
				var gc: Variant = n.get_meta("grid_cell", null)
				ok_cell = gc is Vector2i and (gc as Vector2i).y == int((want_cell as Array)[0]) \
					and (gc as Vector2i).x == int((want_cell as Array)[1])
			if ok_token and ok_cell:
				var d: float = (n as Node3D).global_position.distance_squared_to(here)
				if d < best_d:
					best_d = d
					best = n as Node3D
			continue
		for ch in n.get_children():
			stack.append(ch)
	return best


## The teleporter nearest the ghost: a node in group `utility` that has the
## teleport ladder DesktopPlayer knows. Utilities carry no artifact meta, so
## they are found by capability.
func _nearest_teleporter() -> Node3D:
	var here: Vector3 = _ghost.global_position if (_ghost != null and is_instance_valid(_ghost)) else Vector3.ZERO
	var best: Node3D = null
	var best_d: float = 1.0e18
	for u in get_tree().get_nodes_in_group("utility"):
		if not (u is Node3D) or not is_instance_valid(u):
			continue
		if not (u.has_method("get_destination") or u.has_method("_start_teleport_sequence")
				or u.has_method("_on_teleport_area_body_entered")):
			continue
		var d: float = (u as Node3D).global_position.distance_squared_to(here)
		if d < best_d:
			best_d = d
			best = u as Node3D
	return best


func _look(c: Dictionary) -> Dictionary:
	var dwell: float = float(c.get("dwell", 2.0))
	var target: Node3D = null
	var centre: Vector3
	var rec: Dictionary = {}
	if c.has("pos") and not c.has("token") and not c.has("index") and not c.has("cell"):
		centre = _to_v3(c.get("pos"))
	else:
		target = _resolve(c)
		if target == null:
			return {"k": "seen", "ok": false, "detail": "no such artifact",
				"token": String(c.get("token", ""))}
		rec = _record(target, -1)
		centre = _to_v3(rec["centre"])
	if _ghost == null or not is_instance_valid(_ghost):
		_ensure_ghost(false)
	var eye: Vector3 = _ghost.global_position + Vector3(0, EYE_HEIGHT, 0)
	var to: Vector3 = centre - eye
	var flat: Vector3 = to
	flat.y = 0.0
	# bearing BEFORE turning: how far off the walker's heading the thing was
	var fwd: Vector3 = _ghost.global_basis.z
	fwd.y = 0.0
	var bearing: float = 0.0
	if flat.length_squared() > 0.0001 and fwd.length_squared() > 0.0001:
		bearing = rad_to_deg(fwd.normalized().signed_angle_to(flat.normalized(), Vector3.UP))
	_face(centre)

	# LINE OF SIGHT. A ray from the eye to the centre; a hit that is not the
	# artifact itself is a wall, a plinth, another work — and is named.
	var los: bool = true
	var blocked_by: String = ""
	var space: PhysicsDirectSpaceState3D = _space()
	if space != null and to.length() > 0.05:
		var q := PhysicsRayQueryParameters3D.create(eye, centre)
		q.collide_with_areas = false
		var hit: Dictionary = _ray_without_ghost(space, q)
		if not hit.is_empty():
			var col: Object = hit.get("collider")
			if col is Node and target != null and (col == target or target.is_ancestor_of(col as Node)):
				los = true
			elif col is Node:
				los = false
				blocked_by = String((col as Node).name)
	_draw_gaze(eye, centre, dwell, los)
	var label: String = "looking at %s" % (String(rec.get("token", "")) if not rec.is_empty() else "a point")
	_set_tag(label)

	var reply: Dictionary = {"k": "seen", "ok": true, "distance": snappedf(to.length(), 0.01),
		"bearing": snappedf(bearing, 0.1), "line_of_sight": los, "eye": _v3(eye), "at": _v3(centre)}
	if blocked_by != "":
		reply["blocked_by"] = blocked_by
	for k in rec:
		reply[k] = rec[k]
	return reply


## A line from the eye to the thing looked at — attention made visible in the
## room, the way the capsule makes the walk visible. Green when the ray got
## through, red when something stood in the way.
func _draw_gaze(from: Vector3, to: Vector3, dwell: float, clear: bool) -> void:
	if _gaze != null and is_instance_valid(_gaze):
		_gaze.queue_free()
	_gaze = null
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(from)
	im.surface_add_vertex(to)
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.45, 1.0, 0.6) if clear else Color(1.0, 0.35, 0.3)
	mat.no_depth_test = true
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_tree().root
	host.add_child(mi)
	mi.global_transform = Transform3D.IDENTITY
	_gaze = mi
	_gaze_until_ms = Time.get_ticks_msec() + int(maxf(0.2, dwell) * 1000.0)


func _tick_gaze() -> void:
	if _gaze == null:
		return
	if not is_instance_valid(_gaze):
		_gaze = null
		return
	if Time.get_ticks_msec() >= _gaze_until_ms:
		_gaze.queue_free()
		_gaze = null


## ————————————————————————————————————————————————————————————————————
## HANDS — interact
## ————————————————————————————————————————————————————————————————————
##
## DesktopPlayer._try_interact climbs: interact() → activate() → emit
## `activated`; teleporters get their own ladder. DesktopInteractionPointer adds
## RMB grab (freeze, strip layers, carry) and LMB action() on the carried thing.
## This is that, one rung per verb, and `auto` takes the first rung the
## artifact actually has — reporting which, so the PC's play report can say
## "pressed" rather than "did something".

func _interact(c: Dictionary) -> Dictionary:
	var verb: String = String(c.get("verb", "auto"))
	if verb == "drop":
		return _drop_reply()
	if verb == "use":
		return _use_reply()
	var target: Node3D = _resolve(c)
	if target == null:
		return {"k": "acted", "ok": false, "verb": verb, "detail": "no such artifact",
			"token": String(c.get("token", ""))}
	var token: String = String(target.get_meta("artifact_lookup_name", "utility:" + String(target.name)))
	var can: Array = _affordances(target)
	var chosen: String = verb
	if verb == "auto":
		chosen = ""
		for v in ["interact", "activate", "signal", "press", "touch", "grab"]:
			if v in can:
				chosen = String(v)
				break
		if chosen == "":
			return {"k": "acted", "ok": false, "verb": "auto", "token": token,
				"affordances": can,
				"detail": "nothing to do: no interact/activate/activated/button/trigger volume/grabbable"
					+ (" (a teleporter — verb 'teleport' takes it)" if "teleporter" in can else "")}
	_set_tag("%s: %s" % [chosen, token])
	var r: Dictionary = {"k": "acted", "verb": chosen, "token": token, "affordances": can,
		"pos": _v3(target.global_position)}
	match chosen:
		"interact":
			if _required_args(target, "interact") != 0:
				return _fail(r, "interact() is missing or needs arguments")
			target.call("interact")
			r["ok"] = true
			r["detail"] = "interact() called on %s" % String(target.name)
		"activate":
			if _required_args(target, "activate") != 0:
				return _fail(r, "activate() is missing or needs arguments")
			target.call("activate")
			r["ok"] = true
			r["detail"] = "activate() called on %s" % String(target.name)
		"signal":
			if not target.has_signal("activated"):
				return _fail(r, "no `activated` signal")
			target.emit_signal("activated")
			r["ok"] = true
			r["detail"] = "`activated` emitted on %s" % String(target.name)
		"press":
			var b: Node = _button_in(target)
			if b != null:
				b.call("trigger")
				r["ok"] = true
				r["detail"] = "trigger() on button %s" % String(b.name)
			else:
				var pt: Node = _pointer_target_in(target)
				if pt == null:
					return _fail(r, "no button (pressed + trigger()) and no pointer_event target")
				var at: Vector3 = (pt as Node3D).global_position if pt is Node3D else target.global_position
				if not _pointer_press(pt as Node3D, at):
					return _fail(r, "pointer_event target %s, but XRToolsPointerEvent is not available" % String(pt.name))
				r["ok"] = true
				r["detail"] = "pointer pressed+released on %s" % String(pt.name)
		"touch":
			var areas: Array = _trigger_areas_in(target)
			if areas.is_empty():
				return _fail(r, "no Area3D with a body_entered listener")
			_ensure_ghost(true)
			# for ONE synchronous emit the walker is the player — see the header
			_ghost.add_to_group("player")
			_ghost.add_to_group("player_body")
			var names: Array = []
			for a in areas:
				(a as Area3D).body_entered.emit(_ghost)
				names.append(String((a as Node).name))
			_ghost.remove_from_group("player")
			_ghost.remove_from_group("player_body")
			r["ok"] = true
			r["detail"] = "body_entered emitted on %s" % ", ".join(PackedStringArray(names))
		"grab":
			var g: Node3D = _grabbable_in(target)
			if g == null:
				return _fail(r, "nothing with pick_up() and no rigid body")
			if _held != null and is_instance_valid(_held):
				return _fail(r, "already holding %s — drop first" % String(_held.name))
			_grab(g)
			r["ok"] = true
			r["detail"] = "holding %s" % String(g.name)
		"teleport":
			r["ok"] = _teleport(target, r)
		_:
			return _fail(r, "unknown verb %s" % chosen)
	return r


func _fail(r: Dictionary, why: String) -> Dictionary:
	r["ok"] = false
	r["detail"] = why
	return r


## DesktopPlayer's own order for a teleporter, unchanged. Explicit only: this
## moves the PERSON in the headset to another map.
func _teleport(target: Node3D, r: Dictionary) -> bool:
	_ensure_ghost(true)
	if target.has_method("_on_teleport_area_body_entered"):
		target.call("_on_teleport_area_body_entered", _ghost)
		r["detail"] = "_on_teleport_area_body_entered"
	elif target.has_method("_on_TeleportArea_body_entered"):
		target.call("_on_TeleportArea_body_entered", _ghost)
		r["detail"] = "_on_TeleportArea_body_entered"
	elif target.has_method("_trigger_touch_interaction"):
		target.call("_trigger_touch_interaction", _ghost.global_position)
		r["detail"] = "_trigger_touch_interaction"
	elif target.has_method("_start_teleport_sequence"):
		target.call("_start_teleport_sequence")
		r["detail"] = "_start_teleport_sequence"
	else:
		r["detail"] = "no known teleport method"
		return false
	return true


## The XR Tools pointer event, if the addon is present. Looked up by name at
## call time rather than written as a type: the addon is gitignored, and a
## bridge that fails to PARSE because a class is absent would take the whole
## autoload — and the pose stream — down with it.
func _pointer_press(target: Node3D, at: Vector3) -> bool:
	var script: Script = null
	for entry_v in ProjectSettings.get_global_class_list():
		var entry: Dictionary = entry_v
		if String(entry.get("class", "")) == "XRToolsPointerEvent":
			script = load(String(entry.get("path", ""))) as Script
			break
	if script == null:
		return false
	_ensure_ghost(_ghost_has_body)
	var hand: Node3D = _ghost_hand if (_ghost_hand != null and is_instance_valid(_ghost_hand)) else _ghost
	script.call("pressed", hand, target, at)
	script.call("released", hand, target, at)
	return true


## Carry a thing the way the desktop pointer does: freeze it, strip its layers
## so it cannot shove anything, and let it ride the hand. The owner's desktop
## hooks (on_desktop_grab / on_desktop_drop) hear it, as they hear the pointer.
func _grab(g: Node3D) -> void:
	_ensure_ghost(_ghost_has_body)
	_held = g
	if g is RigidBody3D:
		_held_freeze = (g as RigidBody3D).freeze
		(g as RigidBody3D).freeze = true
	if g is CollisionObject3D:
		_held_layer = (g as CollisionObject3D).collision_layer
		_held_mask = (g as CollisionObject3D).collision_mask
		(g as CollisionObject3D).collision_layer = 0
		(g as CollisionObject3D).collision_mask = 0
	var hand: Node3D = _ghost_hand if (_ghost_hand != null and is_instance_valid(_ghost_hand)) else _ghost
	var scale_keep: Vector3 = g.global_transform.basis.get_scale()
	g.reparent(hand, false)
	g.transform = Transform3D(Basis.IDENTITY.scaled(scale_keep), Vector3.ZERO)
	var hook: Object = _hook_target(g)
	if hook != null and hook.has_method("on_desktop_grab"):
		hook.call("on_desktop_grab", hand)
	_set_tag("holding %s" % String(g.name))


func _hook_target(p: Node) -> Object:
	if p != null and is_instance_valid(p) and p.has_meta("desktop_hook_target"):
		var t: Variant = p.get_meta("desktop_hook_target")
		if t is Object and is_instance_valid(t):
			return t
	return p


func _drop_held() -> void:
	if _held == null:
		return
	if is_instance_valid(_held):
		var home: Node = get_tree().current_scene
		if home == null:
			home = get_tree().root
		if home != _held.get_parent():
			_held.reparent(home, true)
		if _held is RigidBody3D:
			(_held as RigidBody3D).freeze = _held_freeze
			(_held as RigidBody3D).linear_velocity = Vector3.ZERO
			(_held as RigidBody3D).angular_velocity = Vector3.ZERO
		if _held is CollisionObject3D:
			(_held as CollisionObject3D).collision_layer = _held_layer
			(_held as CollisionObject3D).collision_mask = _held_mask
		var hook: Object = _hook_target(_held)
		if hook != null and hook.has_method("on_desktop_drop"):
			var hand: Node3D = _ghost_hand if (_ghost_hand != null and is_instance_valid(_ghost_hand)) else _ghost
			hook.call("on_desktop_drop", hand)
	_held = null


func _drop_reply() -> Dictionary:
	if _held == null or not is_instance_valid(_held):
		_held = null
		return {"k": "acted", "ok": false, "verb": "drop", "detail": "holding nothing"}
	var name: String = String(_held.name)
	_drop_held()
	_set_tag("python walker")
	return {"k": "acted", "ok": true, "verb": "drop", "detail": "put down %s" % name}


## LMB on the desktop: the carried thing's action() — a gun fires, a laser lights.
func _use_reply() -> Dictionary:
	if _held == null or not is_instance_valid(_held):
		return {"k": "acted", "ok": false, "verb": "use", "detail": "holding nothing"}
	if _required_args(_held, "action") != 0:
		return {"k": "acted", "ok": false, "verb": "use",
			"detail": "%s has no bare action()" % String(_held.name)}
	_held.call("action")
	if _held.has_method("action_release"):
		_held.call("action_release")
	return {"k": "acted", "ok": true, "verb": "use", "detail": "action() on %s" % String(_held.name)}


## A held thing freed under us (a map change, a hall streamed out) is forgotten
## before anything dereferences it — the shape of three crashes fixed elsewhere.
func _forget_freed_held() -> void:
	if _held != null and not is_instance_valid(_held):
		_held = null


## ————————————————————————————————————————————————————————————————————
## The game's own word for it
## ————————————————————————————————————————————————————————————————————
##
## GridInteractablesComponent emits interactable_activated when an artifact
## reports itself activated, and GridSystem re-emits it. Forwarded as
## `activated`, so the PC hears the confirmation from the game rather than
## inferring it from having sent a command. Hooked at 1 Hz: the grid does not
## exist when this autoload starts, and is rebuilt on every map.
func _hook_grids(delta: float) -> void:
	_hook_accum += delta
	if _hook_accum < 1.0:
		return
	_hook_accum = 0.0
	for g in get_tree().get_nodes_in_group("grid_system"):
		if not is_instance_valid(g) or not g.has_signal("interactable_activated"):
			continue
		var id: int = g.get_instance_id()
		if _hooked_grids.has(id):
			continue
		g.connect("interactable_activated", _on_grid_activated)
		_hooked_grids[id] = true


func _on_grid_activated(object_id: String, position: Vector3, data: Dictionary) -> void:
	_send({"k": "activated", "token": object_id, "pos": _v3(position),
		"name": String(data.get("name", ""))})
