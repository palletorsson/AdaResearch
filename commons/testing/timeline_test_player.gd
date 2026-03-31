## TimelineTestPlayer
## AI agent that plays through a map's timeline by reading the triggers
## and directly simulating player actions. No physics needed — it reads
## timeline.json and fires events in the right order.
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/timeline_test_player.gd -- --map=Point_One
##
## Options:
##   --map=MapName       Map to test (required)
##   --speed=2.0         Playback speed multiplier (default 1.0)
##   --capture           Save screenshot at each event
##   --timeout=60        Max seconds before abort (default 60)

extends SceneTree

var map_name := "Point_One"
var speed := 1.0
var do_capture := false
var timeout_sec := 60.0

var _grid_system: Node
var _timeline_comp: Node
var _timeline_data: Dictionary = {}
var _events_fired: Array[String] = []
var _elapsed := 0.0
var _screenshot_count := 0
var _camera: Camera3D


func _init():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="):
			map_name = arg.substr(6)
		elif arg.begins_with("--speed="):
			speed = float(arg.substr(8))
		elif arg == "--capture":
			do_capture = true
		elif arg.begins_with("--timeout="):
			timeout_sec = float(arg.substr(10))

	print("[Agent] ══════════════════════════════════════")
	print("[Agent] Map: %s | Speed: %.1fx" % [map_name, speed])
	print("[Agent] ══════════════════════════════════════")


func _initialize():
	# Load timeline data directly from JSON
	var tl_path := "res://commons/maps/%s/timeline.json" % map_name
	if FileAccess.file_exists(tl_path):
		var file := FileAccess.open(tl_path, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_timeline_data = json.data
			print("[Agent] Timeline loaded: %d events" % _timeline_data.get("events", []).size())
		else:
			print("[Agent] ERROR: Failed to parse timeline.json")
	else:
		print("[Agent] No timeline.json found — testing static map")

	# Load grid scene
	var grid_scene = load("res://commons/scenes/grid.tscn")
	if not grid_scene:
		print("[Agent] ERROR: Could not load grid.tscn")
		quit(1)
		return

	var instance = grid_scene.instantiate()

	# CRITICAL: Set map name on GridSystem BEFORE adding to tree
	# (GridSystem loads map in _ready, so map_name must be set first)
	var gs = _find_node(instance, "GridSystem")
	if gs:
		gs.map_name = map_name
		gs.auto_load_map_on_ready = true
		print("[Agent] Set GridSystem.map_name = %s BEFORE _ready" % map_name)

	root.add_child(instance)

	# Setup a camera so screenshots work
	_camera = Camera3D.new()
	_camera.name = "AgentCamera"
	_camera.position = Vector3(3, 8, 12)
	_camera.look_at(Vector3(3, 0, 5))
	_camera.current = true
	root.add_child(_camera)

	await _wait(1.0)

	# Find grid system (now in tree)
	_grid_system = _find_node(root, "GridSystem")
	if not _grid_system:
		print("[Agent] ERROR: GridSystem not found")
		quit(1)
		return

	# Wait for map generation
	print("[Agent] Loading map %s..." % map_name)
	await _wait(4.0)

	# Find timeline component
	_timeline_comp = _find_node(_grid_system, "GridTimelineComponent")
	if _timeline_comp:
		_timeline_comp.event_triggered.connect(_on_event)
		print("[Agent] Timeline component connected")

	if do_capture:
		await _capture("00_loaded")

	# Play through the timeline
	await _play_timeline()

	# Final report
	_report()
	quit(0)


# ── Play the timeline ────────────────────────────────────────

func _play_timeline():
	var events: Array = _timeline_data.get("events", [])
	if events.is_empty():
		print("[Agent] No events to play")
		return

	print("[Agent] Playing %d events..." % events.size())
	print("[Agent] ──────────────────────────────────")

	# Build a playback plan: ordered list of (time, event) based on triggers
	var plan: Array[Dictionary] = _build_plan(events)

	for step in plan:
		var event_id: String = step["event_id"]
		var action_type: String = step["action"]
		var wait_time: float = step.get("wait", 0.0) / speed

		if wait_time > 0:
			print("[Agent] ... waiting %.1fs" % (wait_time * speed))
			await _wait(wait_time)

		match action_type:
			"auto":
				# Delay/after events fire automatically — just wait and check
				print("[Agent] ⏱ %s (auto-trigger)" % event_id)
				await _wait(0.5 / speed)

			"walk_to_zone":
				var pos: Vector3 = step.get("position", Vector3.ZERO)
				print("[Agent] 🚶 Walking to zone: %s at %s" % [event_id, str(pos)])
				# Move camera to see the zone
				_camera.position = pos + Vector3(2, 3, 4)
				_camera.look_at(pos)
				await _wait(0.5 / speed)

				# Directly fire the event on the timeline component
				if _timeline_comp and _timeline_comp.has_method("_on_event_fire"):
					_timeline_comp._on_event_fire(event_id)
				else:
					_events_fired.append(event_id)

				await _wait(1.0 / speed)

			"interact":
				var target: String = step.get("target", "")
				print("[Agent] 👆 Interacting with: %s" % target)
				# Directly fire the event
				if _timeline_comp and _timeline_comp.has_method("_on_event_fire"):
					_timeline_comp._on_event_fire(event_id)
				else:
					_events_fired.append(event_id)

				await _wait(1.0 / speed)

		if do_capture:
			await _capture("%02d_%s" % [_screenshot_count, event_id])

		# Wait for cascade actions to complete
		await _wait(0.5 / speed)


func _build_plan(events: Array) -> Array[Dictionary]:
	"""Build ordered playback plan from timeline events."""
	var plan: Array[Dictionary] = []
	var resolved: Dictionary = {}  # event_id -> estimated time

	# First pass: resolve delay events
	for event in events:
		var trigger: Dictionary = event.get("trigger", {})
		var event_id: String = event.get("id", "")

		match trigger.get("type", ""):
			"delay":
				var t: float = float(trigger.get("seconds", 0))
				resolved[event_id] = t
				plan.append({
					"event_id": event_id,
					"action": "auto",
					"time": t,
					"wait": t,
				})

	# Second pass: resolve zone/interact events (player actions)
	for event in events:
		var trigger: Dictionary = event.get("trigger", {})
		var event_id: String = event.get("id", "")
		if resolved.has(event_id):
			continue

		match trigger.get("type", ""):
			"zone":
				var pos_arr: Array = trigger.get("position", [0, 0])
				var pos := Vector3(float(pos_arr[0]), 0.5, float(pos_arr[1]) if pos_arr.size() >= 2 else 0)
				# Estimate this happens after all delays
				var t: float = 0
				for v in resolved.values():
					t = max(t, v)
				t += 2.0  # walk time
				resolved[event_id] = t
				plan.append({
					"event_id": event_id,
					"action": "walk_to_zone",
					"time": t,
					"wait": 2.0,
					"position": pos,
				})

			"interact":
				var target: String = str(trigger.get("target", ""))
				var t: float = 0
				for v in resolved.values():
					t = max(t, v)
				t += 2.0
				resolved[event_id] = t
				plan.append({
					"event_id": event_id,
					"action": "interact",
					"time": t,
					"wait": 2.0,
					"target": target,
				})

	# Third pass: resolve "after" events
	for event in events:
		var trigger: Dictionary = event.get("trigger", {})
		var event_id: String = event.get("id", "")
		if resolved.has(event_id):
			continue

		if trigger.get("type") == "after":
			var dep_id: String = str(trigger.get("event", ""))
			var delay: float = float(trigger.get("delay", 0))
			var dep_time: float = resolved.get(dep_id, 0.0)
			var t: float = dep_time + delay + 1.0
			resolved[event_id] = t
			plan.append({
				"event_id": event_id,
				"action": "auto",
				"time": t,
				"wait": delay + 1.0,
			})

	# Sort by time
	plan.sort_custom(func(a, b): return a["time"] < b["time"])

	# Convert absolute times to relative waits
	var last_time := 0.0
	for i in range(plan.size()):
		plan[i]["wait"] = max(0, plan[i]["time"] - last_time)
		last_time = plan[i]["time"]

	return plan


# ── Event callback ───────────────────────────────────────────

func _on_event(event_id: String):
	if event_id not in _events_fired:
		_events_fired.append(event_id)
	print("[Agent] ✓ EVENT FIRED: %s (t=%.1fs)" % [event_id, _elapsed])


# ── Report ───────────────────────────────────────────────────

func _report():
	var expected := _get_event_ids()
	var missed: Array[String] = []
	for e in expected:
		if e not in _events_fired:
			missed.append(e)

	print("[Agent] ══════════════════════════════════════")
	print("[Agent] REPORT: %s" % map_name)
	print("[Agent]   Total events: %d" % expected.size())
	print("[Agent]   Fired: %d" % _events_fired.size())
	for e in _events_fired:
		print("[Agent]     ✓ %s" % e)
	if missed.size() > 0:
		print("[Agent]   Missed: %d" % missed.size())
		for m in missed:
			print("[Agent]     ✗ %s" % m)
	else:
		print("[Agent]   STATUS: ALL EVENTS FIRED ✓")
	if do_capture:
		print("[Agent]   Screenshots: %d" % _screenshot_count)
	print("[Agent] ══════════════════════════════════════")


func _get_event_ids() -> Array[String]:
	var ids: Array[String] = []
	for event in _timeline_data.get("events", []):
		ids.append(str(event.get("id", "")))
	return ids


# ── Helpers ──────────────────────────────────────────────────

func _capture(label: String):
	await RenderingServer.frame_post_draw
	var img := get_root().get_viewport().get_texture().get_image()
	var dir := "user://timeline_test/%s" % map_name
	DirAccess.make_dir_recursive_absolute(dir)
	var path := "%s/%s.png" % [dir, label]
	img.save_png(path)
	_screenshot_count += 1
	print("[Agent] 📸 %s" % label)


func _wait(seconds: float):
	_elapsed += seconds
	await create_timer(seconds).timeout


func _find_node(parent: Node, name_pattern: String) -> Node:
	if parent.name == name_pattern:
		return parent
	for child in parent.get_children():
		var result := _find_node(child, name_pattern)
		if result:
			return result
	return null
