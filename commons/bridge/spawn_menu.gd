extends Node
## Shared prefab browser. B opens the desktop library; Y places one world board.
## Reopening relocates that same board. Artifact instances remain in the shared layout.
## Choose a prefab, aim its footprint, confirm with click/trigger. Esc/Y cancels.

const BoardStand := preload("res://commons/bridge/prefab_board.gd")
const UI_SCENE := preload("res://commons/bridge/spawn_menu_ui.tscn")
## Grab-and-move while the menu is open (edit mode): commons/bridge/void_grab.gd.
const VoidGrab := preload("res://commons/bridge/void_grab.gd")
const VIEWPORT_2D_3D := "res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn"
const PANEL_W := 4.0
const PANEL_H := 4.0
const VIEWPORT_PX := Vector2(1920, 1920)
const TOGGLE_KEY := KEY_B
const TOGGLE_BUTTONS := ["by_button", "menu_button"] # Left Y places the board; Menu remains an alias.
const AHEAD_VR := 2.0
const AHEAD_DESKTOP := 2.5

var _link: Node = null          # the VRLink autoload (our parent)
var _ui: Control = null
var _layer: CanvasLayer = null  # desktop
var _vp3d: Node3D = null        # VR
var _stand: RigidBody3D
var _mounted := false
var _mount_tries := 0
var _open := false
var _last_spawned := ""
var _last_floor := -1
var _mouse_before := Input.MOUSE_MODE_CAPTURED
var _grab: Node = null
var _pending_prefab := ""
var _pending_where: Dictionary = {}
var _placement_turn := 0.0
var _armed_at := 0
var _ghost: MeshInstance3D = null



func _ready() -> void:
	_link = get_parent()
	if _link != null and _link.has_signal("update_acked"):
		_link.update_acked.connect(_on_ack)
		_link.spawn_result.connect(_on_spawn_result)
	set_process(true)
	print("[spawn-menu] created")


func _process(_delta: float) -> void:
	if not _pending_prefab.is_empty():
		_update_placement()
	if not _mounted:
		_mount_tries += 1
		if _mount_tries % 30 == 1:   # every half second until the rig is there
			_try_mount()


## ————————————————————————————————————————————————————————————————————
## Mounting — a world board in VR, a layer on desktop
## ————————————————————————————————————————————————————————————————————

func _xr_active() -> bool:
	var vp: Viewport = get_viewport()
	return vp != null and vp.use_xr and XRServer.primary_interface != null


func _hand(which: String) -> XRController3D:
	for n in get_tree().get_nodes_in_group("player"):
		if n is XROrigin3D:
			for c in (n as Node).get_children():
				if c is XRController3D and String((c as Node).name).to_lower().begins_with(which):
					return c as XRController3D
	var origin: Node = _first_of_class(get_tree().root, "XROrigin3D")
	if origin != null:
		for c in origin.get_children():
			if c is XRController3D and String((c as Node).name).to_lower().begins_with(which):
				return c as XRController3D
	return null


func _first_of_class(n: Node, cls: String) -> Node:
	if n.is_class(cls):
		return n
	for c in n.get_children():
		var r: Node = _first_of_class(c, cls)
		if r != null:
			return r
	return null


func _try_mount() -> void:
	if _xr_active():
		var left: XRController3D = _hand("left")
		var right: XRController3D = _hand("right")
		if left == null:
			return
		var packed: PackedScene = load(VIEWPORT_2D_3D)
		if packed == null:
			push_warning("[spawn-menu] XR Tools viewport_2d_in_3d is missing; desktop layer instead")
			_mount_desktop()
			return
		_vp3d = packed.instantiate()
		_vp3d.name = "SpawnMenuPanel"
		_vp3d.set("screen_size", Vector2(PANEL_W, PANEL_H))
		_vp3d.set("viewport_size", VIEWPORT_PX)
		_vp3d.set("scene", UI_SCENE)
		_vp3d.set("unshaded", true)
		# UI-only layer: the stand supplies physical collision, not the pointer plane.
		_vp3d.set("collision_layer", 1 << 22)
		_stand = BoardStand.new()
		add_child(_stand)
		_stand.add_child(_vp3d)
		_vp3d.position = BoardStand.SCREEN_CENTRE
		if right != null:
			right.button_pressed.connect(_on_right_button)
		left.button_pressed.connect(_on_left_button)
		_vp3d.visible = false
		_vp3d.set("enabled", false)
		_mounted = true
		call_deferred("_bind_ui_from_viewport")
		_make_grab(right, false)
		print("[spawn-menu] 4 x 4 m world board ready (Y relocates it)")
	else:
		_mount_desktop()


func _mount_desktop() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "SpawnMenuLayer"
	_layer.layer = 60
	add_child(_layer)
	_ui = UI_SCENE.instantiate()
	# Large desktop library; placement closes it so the whole view is available.
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.anchor_right = 0.94
	_ui.anchor_left = 0.06
	_ui.offset_left = 24
	_ui.offset_top = 24
	_ui.offset_right = 0
	_ui.offset_bottom = -24
	_layer.add_child(_ui)
	_layer.visible = false
	_bind_ui()
	_make_grab(null, true)
	_mounted = true
	print("[spawn-menu] desktop layer ready (toggle: B; drag in the view to move, Q/E turn)")


func _make_grab(right: XRController3D, desktop: bool) -> void:
	if _grab != null and is_instance_valid(_grab):
		return
	_grab = VoidGrab.new()
	_grab.name = "VoidGrab"
	add_child(_grab)
	_grab.call("setup", self, right, desktop)


## The desktop grab asks before taking a click the panel should get.
func mouse_over_panel() -> bool:
	if _layer == null or not _layer.visible or _ui == null:
		return false
	return _ui.get_global_rect().has_point(_ui.get_viewport().get_mouse_position())


func _bind_ui_from_viewport() -> void:
	if _vp3d == null or not _vp3d.has_method("get_scene_instance"):
		return
	var inst: Node = _vp3d.call("get_scene_instance")
	if inst == null:
		call_deferred("_bind_ui_from_viewport")
		return
	_ui = inst
	_ui.call("set_board_style")
	_ui.call("set_label_mode", true)
	_bind_ui()


func _bind_ui() -> void:
	if _ui == null:
		return
	if _ui.has_signal("spawn_requested"):
		_ui.spawn_requested.connect(_on_spawn_requested)
	if _ui.has_signal("remove_last_requested"):
		_ui.remove_last_requested.connect(_on_remove_last)
	if _ui.has_signal("close_requested"):
		_ui.close_requested.connect(func() -> void: _set_open(false))


## ————————————————————————————————————————————————————————————————————
## Toggling
## ————————————————————————————————————————————————————————————————————

func _input(event: InputEvent) -> void:
	if not _pending_prefab.is_empty():
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				_cancel_placement()
			elif event.keycode in [KEY_Q, KEY_E]:
				_placement_turn += -15.0 if event.keycode == KEY_Q else 15.0
			get_viewport().set_input_as_handled()
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_confirm_placement()
			get_viewport().set_input_as_handled()
		return
	if _layer != null and event is InputEventKey and event.pressed and not event.echo and event.keycode == TOGGLE_KEY:
		_set_open(not _open)
		get_viewport().set_input_as_handled()

func _on_left_button(button_name: String) -> void:
	if button_name in TOGGLE_BUTTONS:
		if not _pending_prefab.is_empty():
			_cancel_placement()
			_set_open(true, false)
		else: _set_open(true, true)

func _on_right_button(button_name: String) -> void:
	if _pending_prefab.is_empty(): return
	if button_name == "trigger_click": _confirm_placement()
	elif button_name == "ax_button": _placement_turn += 15.0

func _position_board() -> bool:
	var eye := _eye()
	if eye == null or _stand == null: return false
	var base_y := eye.global_position.y - 1.65
	var content := _content()
	if content != null:
		var roots: Dictionary = content.get("roots")
		var floor_i := _player_floor()
		if roots.has(floor_i): base_y = roots[floor_i].global_position.y
	var pose: Variant = _stand.supported_pose(eye, base_y)
	if pose == null:
		_status("No clear floor for both feet. Face a larger clear patch and press Y.")
		return false
	_stand.relocate(pose)
	return true

func _set_open(open: bool, relocate := true) -> void:
	if _vp3d != null:
		if open and (relocate or not _stand.placed):
			if not _position_board(): return
		_stand.set_deployed(open)
		_vp3d.visible = open
		_vp3d.set("enabled", open)
	_open = open
	if _layer != null:
		_layer.visible = open
		if open:
			_mouse_before = Input.mouse_mode
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else: Input.mouse_mode = _mouse_before
	if _grab != null and is_instance_valid(_grab): _grab.set("enabled", open)
	if open and _ui != null:
		_ui.call("set_status", "Floor %d · Y relocates board · choose → aim → confirm · artifacts stay" % _player_floor())


## ————————————————————————————————————————————————————————————————————
## Where it lands — floor index and the floor-local point ahead of the hand
## ————————————————————————————————————————————————————————————————————

func _content() -> Node:
	for n in get_tree().get_nodes_in_group("biome_grid"):
		if is_instance_valid(n) and n.has_method("load_floor") and n.has_method("reset_floor"):
			return n
	return null


func _eye() -> Node3D:
	var vp: Viewport = get_viewport()
	var cam: Camera3D = vp.get_camera_3d() if vp != null else null
	return cam


func _player_floor() -> int:
	var content: Node = _content()
	if content == null:
		return -1
	var eye: Node3D = _eye()
	var y: float = eye.global_position.y if eye != null else 0.0
	var building: Node = content.get_parent()
	var game: Node = building.get_parent() if building != null else null
	if game != null:
		var fs: Variant = game.get("floor_stream")
		if fs is Node and (fs as Node).has_method("floor_at"):
			return int((fs as Node).call("floor_at", y))
	# fall back: the resident floor whose root is closest below the eye
	var roots: Variant = content.get("roots")
	var best := -1
	var best_d := 1e9
	if roots is Dictionary:
		for k in (roots as Dictionary):
			var r: Variant = (roots as Dictionary)[k]
			if r is Node3D and is_instance_valid(r):
				var d: float = y - (r as Node3D).global_position.y
				if d >= -0.5 and d < best_d:
					best_d = d
					best = int(k)
	return best


func _landing() -> Dictionary:
	var content: Node = _content()
	var floor_i: int = _player_floor()
	if content == null or floor_i < 0:
		return {}
	var roots: Variant = content.get("roots")
	if not (roots is Dictionary) or not (roots as Dictionary).has(floor_i):
		return {}
	var root: Node3D = (roots as Dictionary)[floor_i]
	var from: Node3D = null
	var ahead: float = AHEAD_DESKTOP
	if _vp3d != null:
		from = _hand("right")
		ahead = AHEAD_VR
	if from == null:
		from = _eye()
	if from == null:
		return {}
	var fwd: Vector3 = -from.global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.01:
		fwd = Vector3.FORWARD
	fwd = fwd.normalized()
	var world: Vector3 = from.global_position + fwd * ahead
	var local: Vector3 = root.to_local(world)
	var eye_local: Vector3 = root.to_local(from.global_position)
	var to_player: Vector3 = eye_local - local
	var facing: float = rad_to_deg(atan2(to_player.x, to_player.z))
	return {"floor": floor_i, "position": [snappedf(local.x, 0.25), snappedf(local.z, 0.25)], "facing": snappedf(facing, 15.0)}


## ————————————————————————————————————————————————————————————————————
## The lane
## ————————————————————————————————————————————————————————————————————

func _on_spawn_requested(token: String, _is_prop: bool) -> void:
	_pending_prefab = token
	_placement_turn = 0
	_armed_at = Time.get_ticks_msec() + 400
	if _vp3d != null:
		# Keep the furniture in place while aiming; only suspend its UI input.
		_open = false
		_vp3d.set("enabled", false)
		if _grab != null: _grab.set("enabled", false)
	else: _set_open(false)
	_ghost = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1, 0.05, 1)
	_ghost.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.9, 0.75, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost.material_override = mat
	add_child(_ghost)
	var hint := Label3D.new()
	hint.text = "PLACE: " + token + "\nAim at floor · click / trigger confirms\nQ/E or A turns · Esc / Y cancels"
	hint.font_size = 28
	hint.pixel_size = 0.003
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint.position.y = 0.5
	_ghost.add_child(hint)
	_update_placement()

func _update_placement() -> void:
	_pending_where = _landing()
	if _pending_where.is_empty():
		if _ghost != null: _ghost.visible = false
		return
	var roots: Dictionary = _content().get("roots")
	var root: Node3D = roots[_pending_where.floor]
	var from: Node3D = _hand("right") if _vp3d != null else _eye()
	if from != null:
		var direction := -from.global_basis.z
		if direction.y < -0.04:
			var distance: float = (root.global_position.y - from.global_position.y) / direction.y
			if distance > 0 and distance <= 25:
				var local := root.to_local(from.global_position + direction * distance)
				_pending_where.position = [snappedf(local.x, 0.25), snappedf(local.z, 0.25)]
	_pending_where.facing += _placement_turn
	if _ghost != null:
		_ghost.visible = true
		_ghost.global_position = root.to_global(Vector3(_pending_where.position[0], 0.04, _pending_where.position[1]))
		_ghost.global_rotation.y = deg_to_rad(_pending_where.facing)

func _cancel_placement() -> void:
	_pending_prefab = ""
	_pending_where = {}
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null

func _confirm_placement() -> void:
	if Time.get_ticks_msec() < _armed_at or _pending_where.is_empty(): return
	var req: Dictionary = {"k": "spawn", "prefab": _pending_prefab, "floor": int(_pending_where.floor),
		"position": _pending_where.position, "facing": _pending_where.facing}
	var content := _content()
	if content != null and content.get("trial_id") != null and str(content.get("trial_id")) != "": req.trial = str(content.get("trial_id"))
	if _link != null and _link.has_method("send_uplink"):
		_link.call("send_uplink", req)
		_last_floor = int(_pending_where.floor)
		_status("Placing %s…" % _pending_prefab)
	_cancel_placement()
	_set_open(true, false)

func _on_remove_last() -> void:
	if _last_spawned == "":
		_status("nothing spawned from this hand yet")
		return
	if _link != null and _link.has_method("send_uplink"):
		_link.call("send_uplink", {"k": "spawn_remove", "floor": _last_floor, "id": _last_spawned})
		_status("asked the bridge to remove %s…" % _last_spawned)


func _on_spawn_result(r: Dictionary) -> void:
	if bool(r.get("ok", false)):
		if bool(r.get("removed", false)):
			_status("removed %s (saved as %s)" % [String(r.get("id", "")), String(r.get("revision_id", "")).right(13)])
			_last_spawned = ""
		else:
			_last_spawned = String(r.get("id", ""))
			_last_floor = int(r.get("floor", _last_floor))
			var warn: Array = r.get("warnings", [])
			_status("saved %s as %s%s" % [_last_spawned, String(r.get("revision_id", "")).right(13),
				(" — " + String(warn[0])) if not warn.is_empty() else ""])
	else:
		_status("refused: %s" % String(r.get("error", "?")))


func _on_ack(a: Dictionary) -> void:
	# this game's own answer to the revision that carried the spawn
	if String(a.get("scene", "")) != "void":
		return
	var ops: Array = a.get("ops", [])
	for op_v in ops:
		var op: Dictionary = op_v
		var kind: String = String(op.get("kind", ""))
		if kind in ["add", "remove"]:
			_status("%s %s: %s" % [String(op.get("id", "")), kind, String(op.get("detail", ""))])
			return
	_status("%s %s%s" % [String(a.get("status", "")), String(a.get("mode", "")),
		(" (" + String(a.get("reason", "")) + ")") if String(a.get("reason", "")) != "" else ""])


func _status(text: String) -> void:
	print("[spawn-menu] " + text)
	if _ui != null and _ui.has_method("set_status"):
		_ui.call("set_status", text)
