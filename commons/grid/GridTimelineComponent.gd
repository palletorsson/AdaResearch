## GridTimelineComponent
## Reads timeline.json per map and orchestrates events in sequence.
## Events trigger based on: delay, player interaction, zone entry, or previous event completion.
## Actions: reveal/hide artifacts, change lighting, animate grid, activate teleporter.

extends Node
class_name GridTimelineComponent

signal event_triggered(event_id: String)
signal timeline_complete()

var _grid_system: Node
var _structure_component: Node
var _timeline_data: Dictionary = {}
var _events: Array = []
var _completed: Dictionary = {}  # event_id -> true
var _armed_timers: Array = []
var _initialized := false


func initialize(grid_system: Node, data_component: Node, structure_component: Node, _settings: Dictionary) -> void:
	_grid_system = grid_system
	_structure_component = structure_component

	var map_name: String = ""
	if data_component.has_method("get_map_name"):
		map_name = data_component.get_map_name()
	elif grid_system.get("current_map_name"):
		map_name = grid_system.current_map_name

	if map_name == "":
		return

	_load_timeline(map_name)
	if _events.is_empty():
		return

	# Wait one frame so all artifacts are placed
	await get_tree().process_frame
	await get_tree().process_frame

	_apply_initial_state()
	_arm_triggers()
	_initialized = true
	print("[Timeline] Loaded %d events for %s" % [_events.size(), map_name])


# ── Load ────────────────────────────────────────────────────

func _load_timeline(map_name: String) -> void:
	var path := "res://commons/maps/%s/timeline.json" % map_name
	if not FileAccess.file_exists(path):
		return

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("[Timeline] Failed to parse: %s" % path)
		return

	_timeline_data = json.data
	_events = _timeline_data.get("events", [])


# ── Initial state ───────────────────────────────────────────

func _apply_initial_state() -> void:
	var initial: Dictionary = _timeline_data.get("initial_state", {})

	# Hide artifacts
	for art_name in initial.get("hidden_artifacts", []):
		var node := _find_artifact(art_name)
		if node:
			node.visible = false
			# Disable collision too
			_set_collision_recursive(node, false)

	# Hide/deactivate utilities (teleporter)
	for util_name in initial.get("hidden_utilities", []):
		if util_name == "t":
			_set_teleporters_active(false)
		else:
			var node := _find_utility(util_name)
			if node:
				node.visible = false

	# Set initial lighting
	var lighting: Dictionary = initial.get("lighting", {})
	if lighting.has("ambient_energy"):
		_set_ambient_energy(float(lighting["ambient_energy"]), 0.0)


# ── Arm triggers ────────────────────────────────────────────

func _arm_triggers() -> void:
	for event in _events:
		var trigger: Dictionary = event.get("trigger", {})
		var event_id: String = event.get("id", "")

		match trigger.get("type", ""):
			"delay":
				_arm_delay(event_id, float(trigger.get("seconds", 1.0)))
			"interact":
				_arm_interact(event_id, str(trigger.get("target", "")))
			"zone":
				_arm_zone(event_id, trigger)
			"after":
				# Armed dynamically when the referenced event completes
				pass
			"all":
				# Armed dynamically when all referenced events complete
				pass


func _arm_delay(event_id: String, seconds: float) -> void:
	var timer := get_tree().create_timer(seconds)
	_armed_timers.append(timer)
	timer.timeout.connect(_on_event_fire.bind(event_id))


func _arm_interact(event_id: String, target_name: String) -> void:
	# Connect to the grid system's interactable_activated signal
	if _grid_system.has_signal("interactable_activated"):
		if not _grid_system.interactable_activated.is_connected(_on_interact_check):
			_grid_system.interactable_activated.connect(_on_interact_check)

	# Also try connecting to the artifact's own signals
	var node := _find_artifact(target_name)
	if node:
		# XR pickable objects emit "picked_up"
		if node.has_signal("picked_up"):
			node.picked_up.connect(_on_event_fire.bind(event_id))
		# Area3D proximity
		if node is Area3D:
			node.body_entered.connect(func(_body): _on_event_fire(event_id))
		# Check children for Area3D
		for child in node.get_children():
			if child is Area3D and not child.body_entered.is_connected(_on_interact_area_check):
				child.body_entered.connect(_on_interact_area_check.bind(event_id, target_name))

	# Store mapping for signal-based check
	node.set_meta("timeline_interact_event", event_id) if node else null


func _arm_zone(event_id: String, trigger: Dictionary) -> void:
	var pos_arr: Array = trigger.get("position", [0, 0, 0])
	var radius: float = trigger.get("radius", 2.0)
	var pos := Vector3(float(pos_arr[0]), 0.5, float(pos_arr[1]) if pos_arr.size() >= 2 else 0)

	# Create trigger area
	var area := Area3D.new()
	area.name = "TimelineZone_%s" % event_id
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	col.shape = shape
	area.add_child(col)
	area.position = pos
	area.body_entered.connect(func(body):
		if body.is_in_group("player_body"):
			_on_event_fire(event_id)
			area.queue_free()
	)
	_grid_system.add_child(area)


# ── Event firing ────────────────────────────────────────────

func _on_interact_check(_object_id, _position, _data) -> void:
	# Check all interact events
	for event in _events:
		var event_id: String = event.get("id", "")
		if _completed.has(event_id):
			continue
		var trigger: Dictionary = event.get("trigger", {})
		if trigger.get("type") == "interact":
			# Fire if the interacted object matches
			_on_event_fire(event_id)


func _on_interact_area_check(body: Node3D, event_id: String, _target: String) -> void:
	if body.is_in_group("player_body"):
		_on_event_fire(event_id)


func _on_event_fire(event_id: String) -> void:
	if _completed.has(event_id):
		return

	_completed[event_id] = true
	print("[Timeline] Event: %s" % event_id)
	event_triggered.emit(event_id)

	# Find and execute actions
	for event in _events:
		if event.get("id") == event_id:
			for action in event.get("actions", []):
				_execute_action(action)
			break

	# Check if any "after" or "all" events should now fire
	_check_dependent_triggers()

	# Check if all events done
	if _completed.size() >= _events.size():
		timeline_complete.emit()
		print("[Timeline] Complete")


func _check_dependent_triggers() -> void:
	for event in _events:
		var event_id: String = event.get("id", "")
		if _completed.has(event_id):
			continue

		var trigger: Dictionary = event.get("trigger", {})

		if trigger.get("type") == "after":
			var dep_id: String = str(trigger.get("event", ""))
			if _completed.has(dep_id):
				var delay: float = float(trigger.get("delay", 0.0))
				if delay > 0:
					_arm_delay(event_id, delay)
				else:
					_on_event_fire(event_id)

		elif trigger.get("type") == "all":
			var deps: Array = trigger.get("events", [])
			var all_done := true
			for dep in deps:
				if not _completed.has(str(dep)):
					all_done = false
					break
			if all_done:
				_on_event_fire(event_id)


# ── Action execution ────────────────────────────────────────

func _execute_action(action: Dictionary) -> void:
	var action_type: String = action.get("type", "")
	var target: String = str(action.get("target", ""))
	var duration: float = float(action.get("duration", 0.5))

	match action_type:
		"reveal":
			_action_reveal(target, action.get("animation", ""), duration)
		"hide":
			_action_hide(target, duration)
		"lighting":
			_action_lighting(action, duration)
		"grid_animate":
			_action_grid_animate(action)
		"activate":
			_action_activate(target)
		"text":
			_action_text(action)
		_:
			print("[Timeline] Unknown action: %s" % action_type)


func _action_reveal(target: String, animation: String, duration: float) -> void:
	if target == "t":
		_set_teleporters_active(true)
		return

	var node := _find_artifact(target)
	if not node:
		node = _find_utility(target)
	if not node:
		print("[Timeline] Reveal target not found: %s" % target)
		return

	_set_collision_recursive(node, true)

	match animation:
		"fade_in":
			node.visible = true
			# Scale from 0 to 1
			var original_scale := node.scale
			node.scale = Vector3.ZERO
			var tween := create_tween()
			tween.tween_property(node, "scale", original_scale, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		"scale_up":
			node.visible = true
			var original_scale := node.scale
			node.scale = Vector3.ZERO
			var tween := create_tween()
			tween.tween_property(node, "scale", original_scale, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		_:
			node.visible = true


func _action_hide(target: String, duration: float) -> void:
	var node := _find_artifact(target)
	if not node:
		return
	if duration > 0:
		var tween := create_tween()
		tween.tween_property(node, "scale", Vector3.ZERO, duration)
		tween.tween_callback(func(): node.visible = false)
	else:
		node.visible = false
	_set_collision_recursive(node, false)


func _action_lighting(action: Dictionary, duration: float) -> void:
	if action.has("ambient_energy"):
		_set_ambient_energy(float(action["ambient_energy"]), duration)


func _action_grid_animate(action: Dictionary) -> void:
	if _structure_component and _structure_component.has_method("play_animation"):
		_structure_component.play_animation(
			action.get("animation", "wave"),
			float(action.get("duration", 1.0))
		)


func _action_activate(target: String) -> void:
	if target == "t":
		_set_teleporters_active(true)


func _action_text(action: Dictionary) -> void:
	var text: String = str(action.get("text", ""))
	var pos_arr: Array = action.get("position", [0, 2, 0])
	var pos := Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]) if pos_arr.size() >= 3 else 0)

	var label := Label3D.new()
	label.text = text
	label.font_size = 64
	label.pixel_size = 0.003
	label.position = pos
	label.modulate = Color(0.9, 0.85, 1.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_grid_system.add_child(label)


# ── Helpers ─────────────────────────────────────────────────

func _find_artifact(art_name: String) -> Node3D:
	# Search in grid system children (interactables component places them)
	for child in _grid_system.get_children():
		if child.name.begins_with(art_name) or child.get_meta("lookup_name", "") == art_name:
			return child
		# Search one level deeper
		for grandchild in child.get_children():
			if grandchild.name.begins_with(art_name) or grandchild.get_meta("lookup_name", "") == art_name:
				return grandchild
	# Try scene tree search
	var results := _grid_system.get_tree().current_scene.find_children("*%s*" % art_name, "", true, false)
	if results.size() > 0:
		return results[0]
	return null


func _find_utility(util_name: String) -> Node3D:
	var results := _grid_system.get_tree().current_scene.find_children("*%s*" % util_name, "", true, false)
	if results.size() > 0:
		return results[0]
	return null


func _set_teleporters_active(active: bool) -> void:
	var teleporters := _grid_system.get_tree().current_scene.find_children("*", "Node3D", true, false)
	for node in teleporters:
		if node.has_method("_set_active") or node.get("active") != null:
			if "teleport" in node.name.to_lower() or node.is_in_group("teleporter"):
				node.set("active", active)
				node.visible = active


func _set_ambient_energy(target: float, duration: float) -> void:
	var world_env := _grid_system.get_tree().current_scene.find_children("*", "WorldEnvironment", true, false)
	if world_env.is_empty():
		return
	var env: Environment = world_env[0].environment
	if not env:
		return

	if duration <= 0:
		env.ambient_light_energy = target
	else:
		var tween := create_tween()
		tween.tween_property(env, "ambient_light_energy", target, duration)


func _set_collision_recursive(node: Node, enabled: bool) -> void:
	if node is CollisionShape3D:
		node.disabled = not enabled
	if node is StaticBody3D or node is RigidBody3D:
		if node.has_method("set_collision_layer"):
			node.collision_layer = 1 if enabled else 0
			node.collision_mask = 1 if enabled else 0
	for child in node.get_children():
		_set_collision_recursive(child, enabled)
