extends Node3D
class_name SpineRunner

## The corridor mode: walk the entire spine as one continuous runner.
##
## Three GridSystem slots stay alive:
##   prev    at z ∈ [-map_depth, 0]     (behind the player)
##   current at z ∈ [0, map_depth]      (where the player is)
##   next    at z ∈ [map_depth, 2*map_depth]  (ahead)
##
## When player crosses z ≥ map_depth  → forward rotation
##   free prev, promote current→prev, next→current, load queue[i+2] into next
##   teleport player z -= map_depth
##
## When player crosses z < 0  → backward rotation
##   free next, demote current→next, prev→current, load queue[i-2] into prev
##   teleport player z += map_depth
##
## Felt motion = seam events, not coordinate progress.

const SpineQueueScript = preload("res://commons/artifacts/spine_runner/spine_queue.gd")
const MetabolismHUDScript = preload("res://commons/artifacts/spine_runner/metabolism_hud.gd")
const GridSystemScene = preload("res://commons/grid/grid_system.tscn")

@export var use_test_queue: bool = true
# When true, each spawned GridSystem loads map_data.corridor.json (if present)
# instead of map_data.json. Generate corridors via:
#   python tools/spine_corridor_generate.py --sequence <name>
@export var prefer_corridor_variant: bool = true
# Spine runner map footprint: 8 wide (x) × 16 deep (z), cube_size = 1.0.
@export var map_width: float = 8.0
@export var map_depth: float = 16.0
@export var show_hud: bool = true
@export var debug_print: bool = true
@export var return_scene: String = "res://commons/scenes/lab.tscn"
# Locomotion model.
#   "streaming" (default): player walks through monotonically-growing world.
#     Slots live at their true z. A sliding window (prev/current/next/far_next)
#     stays near the player. Maps load in the background; old maps free behind.
#     No teleport ever.
#   "seam": old model — player crosses z=map_depth, whole rig teleports back.
@export var locomotion_mode: String = "streaming"
# How many slots to keep loaded ahead of and behind the current slot.
# Window = [current - BEHIND, ..., current + AHEAD]. Larger = smoother but
# heavier on GPU/memory.
@export var slots_ahead: int = 2
@export var slots_behind: int = 1

var _queue: Array[String] = []
var _queue_index: int = 0        # index of the CURRENT slot's map

var _prev_slot: Node3D = null    # z_offset = -map_depth
var _current_slot: Node3D = null # z_offset = 0
var _next_slot: Node3D = null    # z_offset = +map_depth

var _player: Node3D = null         # PlayerBody / DesktopPlayer — read global_position from this
var _teleport_target: Node3D = null # XROrigin3D (for VR) or same as _player (desktop)
var _hud: MetabolismHUD = null
var _name_tag: Label3D = null      # Floating label visible in VR showing current map name
var _last_seam_time_ms: int = 0    # Debounce timer for VR button seam triggers
var _last_rotation_time_ms: int = 0 # Prevents auto-seam retriggering
const ROTATION_COOLDOWN_MS := 1200   # No auto seam for this many ms after rotation
const REARM_ZONE_MIN := 2.5          # Player must re-enter [MIN, MAX] window after rotation
const REARM_ZONE_MAX := 13.5
var _armed: bool = true              # False until player is back in the rearm zone
var _hud_canvas: CanvasLayer = null
var _budget_pressure: float = 0.0

# --- streaming mode state ---
# idx -> slot node (keyed by queue index, not by position). A slot at idx
# sits at world z ∈ [idx*map_depth, (idx+1)*map_depth].
var _slots: Dictionary = {}
var _current_idx: int = 0        # which queue index the player is currently in


func _ready() -> void:
	_queue = SpineQueueScript.build_test() if use_test_queue else SpineQueueScript.build()
	if _queue.is_empty():
		push_error("SpineRunner: queue empty")
		return
	_print("queue size = %d, first = %s" % [_queue.size(), _queue[0]])

	if show_hud:
		_hud_canvas = CanvasLayer.new()
		_hud_canvas.layer = 100
		add_child(_hud_canvas)
		_hud = MetabolismHUDScript.new()
		_hud_canvas.add_child(_hud)
		_hud.budget_pressure.connect(_on_budget_pressure)

	_find_player()
	_build_name_tag()
	_build_return_portal()
	_wire_vr_controllers()
	_disable_bounds_check_if_streaming()
	if locomotion_mode == "streaming":
		_stream_update_window()
	else:
		# Legacy seam mode — three fixed slots
		_spawn_slot(-map_depth, _queue_index - 1)
		_spawn_slot(0, _queue_index)
		_spawn_slot(map_depth, _queue_index + 1)
	_refresh_name_tag()


func _disable_bounds_check_if_streaming() -> void:
	if locomotion_mode != "streaming":
		return
	# The PlayerBoundsCheck utility clamps the player to a single map's
	# AABB and resets them when they exceed it. In streaming mode the
	# corridor extends monotonically along +z; the check would yank the
	# player back every time they cross into the next slot.
	var bc := get_tree().root.find_child("PlayerBoundsCheck", true, false)
	if bc == null:
		_print("no PlayerBoundsCheck found (ok)")
		return
	if "active" in bc:
		bc.active = false
		_print("PlayerBoundsCheck disabled (streaming mode)")
	# Also intercept GridSystem's updates to limits — it runs on every map
	# load and re-enables the check. We'll rely on the bc.active flag, but
	# widen the bounds too as a belt-and-suspenders safety.
	if "box_bounds" in bc:
		bc.box_bounds = Vector3(1000.0, 1000.0, 1000.0)


func _build_return_portal() -> void:
	# Mounted as a child of the runner, so it stays at world z=0 (south edge)
	# for the current slot. Player can always walk backward to exit.
	var SpinePortalScene := load("res://commons/artifacts/spine_portal/spine_portal.tscn")
	if SpinePortalScene == null:
		_print("return portal: spine_portal.tscn not found, skipping")
		return
	var portal: Node = SpinePortalScene.instantiate()
	portal.name = "ReturnPortal"
	# Configure target and color (amber-red to signal "exit")
	if "target_scene" in portal:
		portal.target_scene = return_scene
	if "portal_color" in portal:
		portal.portal_color = Color(0.95, 0.35, 0.25)
	portal.position = Vector3(map_width * 0.5, 0.0, -0.6)  # just south of corridor, centered
	add_child(portal)
	_print("return portal placed at %s (target=%s)" % [str(portal.position), return_scene])


func _build_name_tag() -> void:
	_name_tag = Label3D.new()
	_name_tag.text = "SPINE · —"
	_name_tag.font_size = 64
	_name_tag.outline_size = 10
	_name_tag.modulate = Color(1.0, 0.88, 0.55)
	_name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_tag.no_depth_test = true
	_name_tag.position = Vector3(4.0, 4.0, 8.0)   # center of corridor, high
	add_child(_name_tag)


func _refresh_name_tag() -> void:
	if _name_tag == null: return
	var idx: int = _current_idx if locomotion_mode == "streaming" else _queue_index
	var cur: String = _queue[idx] if idx < _queue.size() else "(end)"
	var lead := "[%d/%d] %s" % [idx + 1, _queue.size(), cur]
	var prev_s: String = _queue[idx - 1] if idx - 1 >= 0 else "—"
	var next_s: String = _queue[idx + 1] if idx + 1 < _queue.size() else "—"
	var mode_hint := "(walk north · menu=exit)" if locomotion_mode == "streaming" else "(A=next B=prev menu=exit)"
	_name_tag.text = "SPINE\n%s\nprev: %s\nnext: %s\n%s" % [lead, prev_s, next_s, mode_hint]
	# Position above the current slot's center
	if _current_slot:
		_name_tag.global_position = _current_slot.global_position + Vector3(map_width * 0.5, 4.0, map_depth * 0.5)


func _process(_delta: float) -> void:
	if _player == null:
		_find_player()
		return
	if locomotion_mode == "streaming":
		_stream_update_window()


func _stream_update_window() -> void:
	# Compute which queue index the player is currently in based on their
	# monotonic world z. Each slot idx occupies z ∈ [idx*map_depth, (idx+1)*map_depth].
	var pz: float = _player.global_position.z if _player else 0.0
	var new_idx: int = int(floor(pz / map_depth))
	new_idx = clampi(new_idx, 0, _queue.size() - 1)

	# Desired window
	var lo: int = maxi(0, new_idx - slots_behind)
	var hi: int = mini(_queue.size() - 1, new_idx + slots_ahead)

	# Spawn missing, free out-of-window
	for idx in range(lo, hi + 1):
		if not _slots.has(idx):
			_spawn_stream_slot(idx)
	var to_free: Array = []
	for idx in _slots.keys():
		if int(idx) < lo or int(idx) > hi:
			to_free.append(idx)
	for idx in to_free:
		_free_stream_slot(int(idx))

	# Update current idx + name tag when player crosses into a new slot
	if new_idx != _current_idx:
		_current_idx = new_idx
		_current_slot = _slots.get(new_idx)
		_refresh_name_tag()
		_print("stream: player entered idx=%d (%s)" % [new_idx, _queue[new_idx]])
	elif _current_slot == null and _slots.has(new_idx):
		_current_slot = _slots[new_idx]


func _spawn_stream_slot(idx: int) -> void:
	if idx < 0 or idx >= _queue.size(): return
	var z_offset: float = float(idx) * map_depth
	var map_name := _queue[idx]
	var slot := GridSystemScene.instantiate()
	slot.name = "StreamSlot_%d_%s" % [idx, map_name]
	slot.position = Vector3(0, 0, z_offset)
	if "map_name" in slot: slot.map_name = map_name
	if "auto_load_map_on_ready" in slot: slot.auto_load_map_on_ready = true
	if "prefer_corridor_variant" in slot: slot.prefer_corridor_variant = prefer_corridor_variant
	add_child(slot)
	_slots[idx] = slot
	if idx == _current_idx:
		_current_slot = slot
	_print("stream spawn idx=%d z=%.1f → %s" % [idx, z_offset, map_name])
	# GridSystem will re-clamp PlayerBoundsCheck on its deferred init.
	# Re-disable it after a short delay so the check stays off.
	get_tree().create_timer(0.8).timeout.connect(_disable_bounds_check_if_streaming)


func _free_stream_slot(idx: int) -> void:
	if not _slots.has(idx): return
	var s: Node = _slots[idx]
	_slots.erase(idx)
	if s == _current_slot: _current_slot = null
	if is_instance_valid(s):
		s.queue_free()
	_print("stream free idx=%d" % idx)


func _input(event: InputEvent) -> void:
	# Manual seam triggers for testing:
	#   N = next map (force forward rotation)
	#   P = previous map (force backward rotation)
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_N:
			print("SpineRunner: ======= N PRESSED: forcing forward rotation =======")
			print("  queue_index=%d  prev=%s  current=%s  next=%s" % [
				_queue_index,
				"null" if _prev_slot == null else _prev_slot.name,
				"null" if _current_slot == null else _current_slot.name,
				"null" if _next_slot == null else _next_slot.name,
			])
			_rotate_forward()
		KEY_P:
			print("SpineRunner: ======= P PRESSED: forcing backward rotation =======")
			_rotate_backward()


func _rotate_forward() -> void:
	if _next_slot == null:
		# End of queue — bounce the player back to keep them inside the last map
		if _player:
			_player.global_position.z = _current_slot.global_position.z + map_depth - 0.2
		_print("at end of queue (no next slot)")
		return
	# Free the trailing slot
	if _prev_slot:
		_prev_slot.queue_free()
	# Shift positions: current -> prev, next -> current
	_prev_slot = _current_slot
	_current_slot = _next_slot
	_next_slot = null
	_prev_slot.position.z -= map_depth
	_current_slot.position.z -= map_depth
	# Teleport player rig (XROrigin3D in VR, DesktopPlayer on desktop)
	if _teleport_target:
		_teleport_target.global_position.z -= map_depth
	# Advance queue
	_queue_index += 1
	# Load new next
	_spawn_slot(map_depth, _queue_index + 1)
	_refresh_name_tag()
	_last_rotation_time_ms = Time.get_ticks_msec()
	_armed = false
	_print_state("forward")


func _rotate_backward() -> void:
	if _prev_slot == null:
		# At queue start — keep the player inside current
		if _player:
			_player.global_position.z = _current_slot.global_position.z + 0.2
		_print("at start of queue (no prev slot)")
		return
	# Free the leading slot
	if _next_slot:
		_next_slot.queue_free()
	# Shift: current -> next, prev -> current
	_next_slot = _current_slot
	_current_slot = _prev_slot
	_prev_slot = null
	_next_slot.position.z += map_depth
	_current_slot.position.z += map_depth
	# Teleport player rig forward to stay in current
	if _teleport_target:
		_teleport_target.global_position.z += map_depth
	# Step queue back
	_queue_index -= 1
	# Load new prev
	_spawn_slot(-map_depth, _queue_index - 1)
	_refresh_name_tag()
	_last_rotation_time_ms = Time.get_ticks_msec()
	_armed = false
	_print_state("backward")


func _spawn_slot(z_offset: float, queue_idx: int) -> void:
	if queue_idx < 0 or queue_idx >= _queue.size():
		return
	var map_name := _queue[queue_idx]
	var slot := GridSystemScene.instantiate()
	slot.name = "SpineSlot_%d_%s" % [queue_idx, map_name]
	slot.position = Vector3(0, 0, z_offset)
	if "map_name" in slot:
		slot.map_name = map_name
	if "auto_load_map_on_ready" in slot:
		slot.auto_load_map_on_ready = true
	if "prefer_corridor_variant" in slot:
		slot.prefer_corridor_variant = prefer_corridor_variant
	if _budget_pressure >= 0.9 and "interactable_density" in slot:
		slot.interactable_density = 0.6
	add_child(slot)
	# Classify by offset (with small tolerance)
	if abs(z_offset) < 0.5:
		_current_slot = slot
	elif z_offset < 0.0:
		_prev_slot = slot
	else:
		_next_slot = slot
	_print("spawn slot z=%+.1f → %s [idx %d]" % [z_offset, map_name, queue_idx])
	# Hunt for the teleporter node in this slot; connect it to forward seam
	# once GridUtilitiesComponent has finished building.
	_hook_slot_teleporter(slot)


func _hook_slot_teleporter(slot: Node, attempts: int = 0) -> void:
	# Utilities are built deferred; retry a few times.
	var teleport := _find_teleporter(slot)
	if teleport == null:
		if attempts < 20:
			get_tree().create_timer(0.25).timeout.connect(func(): _hook_slot_teleporter(slot, attempts + 1))
		else:
			_print("slot '%s' no teleporter found after %d tries" % [slot.name, attempts])
		return
	if not teleport.has_signal("teleporter_activated"):
		return
	if teleport.teleporter_activated.is_connected(_on_slot_teleporter_fired):
		return
	teleport.teleporter_activated.connect(_on_slot_teleporter_fired.bind(slot))
	_print("hooked teleporter on slot '%s'" % slot.name)


func _find_teleporter(root: Node) -> Node:
	# BFS for any node that owns teleporter_activated signal
	var queue := [root]
	while queue.size() > 0:
		var n = queue.pop_front()
		if n == null: continue
		if n.has_signal("teleporter_activated"):
			return n
		for c in n.get_children():
			queue.append(c)
	return null


func _on_slot_teleporter_fired(slot: Node) -> void:
	if locomotion_mode == "streaming":
		# In streaming mode the teleporter is a landmark, not a transition.
		# Player walks past it into the next map organically.
		return
	# Seam mode: only react to teleporters in the CURRENT slot.
	if slot != _current_slot:
		_print("teleporter fired on non-current slot '%s', ignoring" % slot.name)
		return
	_print("teleporter -> forward seam")
	_rotate_forward()


func _print_state(direction: String) -> void:
	var prev_name: String = _queue[_queue_index - 1] if _queue_index - 1 >= 0 else "(none)"
	var cur_name: String  = _queue[_queue_index]     if _queue_index >= 0 and _queue_index < _queue.size() else "(end)"
	var next_name: String = _queue[_queue_index + 1] if _queue_index + 1 < _queue.size() else "(none)"
	_print("%s: prev=%s | current=%s | next=%s" % [direction, prev_name, cur_name, next_name])


func _wire_vr_controllers() -> void:
	# Find XRController3D nodes under XROrigin3D (xr-tools LeftHand / RightHand).
	# Connect button_pressed signals:
	#   right A (ax_button) -> next map (forward)
	#   right B (by_button) -> previous map (backward)
	#   left  X (ax_button) -> next map (mirror, for convenience)
	#   left  Y (by_button) -> previous map (mirror)
	var xr_origin := get_tree().root.find_child("XROrigin3D", true, false)
	if xr_origin == null:
		_print("no XROrigin3D -- VR controller wiring skipped")
		return
	var wired := 0
	for child in xr_origin.get_children():
		if child is XRController3D:
			if not child.button_pressed.is_connected(_on_vr_button):
				child.button_pressed.connect(_on_vr_button.bind(str(child.name)))
			wired += 1
			_print("wired VR controller: %s" % child.name)
	if wired == 0:
		# Fallback: look for nodes named LeftHand / RightHand regardless of type
		for name in ["LeftHand", "RightHand"]:
			var n := xr_origin.find_child(name, false, false)
			if n and n is XRController3D:
				if not n.button_pressed.is_connected(_on_vr_button):
					n.button_pressed.connect(_on_vr_button.bind(str(n.name)))
					wired += 1
	_print("VR controllers wired: %d" % wired)


func _on_vr_button(button_name: String, controller_name: String) -> void:
	_print("VR button: %s on %s" % [button_name, controller_name])
	var now := Time.get_ticks_msec()
	if now - _last_seam_time_ms < 350:
		return
	match button_name:
		"ax_button", "ax_touch":
			if locomotion_mode == "streaming":
				# In streaming mode, A acts as a "fast-forward" nudge: teleport
				# the player rig one map_depth north. Useful to skip ahead.
				_last_seam_time_ms = now
				if _teleport_target:
					_teleport_target.global_position.z += map_depth
				_print("stream nudge: +%s m" % str(map_depth))
			else:
				_last_seam_time_ms = now
				_rotate_forward()
		"by_button", "by_touch":
			if locomotion_mode == "streaming":
				_last_seam_time_ms = now
				if _teleport_target:
					_teleport_target.global_position.z -= map_depth
				_print("stream nudge: -%s m" % str(map_depth))
			else:
				_last_seam_time_ms = now
				_rotate_backward()
		"menu_button", "select_button":
			_last_seam_time_ms = now
			_print("VR exit: menu_button -> return to %s" % return_scene)
			_exit_corridor()


func _exit_corridor() -> void:
	# Emit request_load_scene via the XRToolsSceneBase ancestor.
	var n: Node = self
	while n != null:
		if n.has_signal("request_load_scene"):
			n.emit_signal("request_load_scene", return_scene, null)
			return
		n = n.get_parent()
	push_error("SpineRunner: no XRToolsSceneBase ancestor to emit request_load_scene")


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player_body")
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		var dp := get_tree().root.find_child("DesktopPlayer", true, false)
		if dp: _player = dp
	# For teleports: prefer XROrigin3D (parent of PlayerBody in VR);
	# on desktop the player IS the thing to teleport.
	var xr_origin := get_tree().root.find_child("XROrigin3D", true, false)
	if xr_origin != null:
		_teleport_target = xr_origin
	else:
		_teleport_target = _player


func _on_budget_pressure(level: float) -> void:
	_budget_pressure = level


func _print(msg: String) -> void:
	if debug_print:
		print("SpineRunner: ", msg)
