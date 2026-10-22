extends Node
## The spawn menu of The Void — Garry's Mod's spawnmenu, on the left wrist.
##
## 2026-10-22, Palle: "a prefab add menu like in Garry's Mod … only the prefabs we
## have built in the sequences". The list is `commons/data/void_spawnlists.json`
## (tools/build_void_spawnlists.py: sequence → map → the artifacts standing in that
## map, with the artifact-gallery captures as thumbnails). Nothing here is hand-written.
##
## Picking a thumbnail does NOT instantiate anything in this game. It asks the bridge
## ({"k":"spawn", floor, token, position, facing} over the VR link); tools/vr_link.py
## saves the record through the editor's own POST /api/void-layout; the revision comes
## back to every attached game — this one included — as an in-place `add`
## (commons/bridge/live_update.gd). The file stays the truth, the other editors see
## it arrive, and the ack is printed on the hand. "Remove last" is the same lane.
##
## Created by the VRLink autoload the first time it sees the Void (the link is what
## carries the request, so the menu exists exactly where the link does). In VR the
## panel is an XR Tools Viewport2Din3D on the left controller, toggled by its menu
## button (Y / menu); the right hand's own FunctionPointer clicks it. On desktop the
## same UI is a CanvasLayer, toggled with B, and a spawn lands 2.5 m ahead of the camera.

const UI_SCENE := preload("res://commons/bridge/spawn_menu_ui.tscn")
## Grab-and-move while the menu is open (edit mode): commons/bridge/void_grab.gd.
const VoidGrab := preload("res://commons/bridge/void_grab.gd")
const VIEWPORT_2D_3D := "res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn"
const PANEL_W := 0.30
const PANEL_H := 0.20
const VIEWPORT_PX := Vector2(960, 640)
const TOGGLE_KEY := KEY_B
const TOGGLE_BUTTONS := ["menu_button", "by_button"]
const AHEAD_VR := 2.0
const AHEAD_DESKTOP := 2.5

var _link: Node = null          # the VRLink autoload (our parent)
var _ui: Control = null
var _layer: CanvasLayer = null  # desktop
var _vp3d: Node3D = null        # VR
var _mounted := false
var _mount_tries := 0
var _open := false
var _last_spawned := ""
var _last_floor := -1
var _mouse_before := Input.MOUSE_MODE_CAPTURED
var _grab: Node = null


func _ready() -> void:
	_link = get_parent()
	if _link != null and _link.has_signal("update_acked"):
		_link.update_acked.connect(_on_ack)
		_link.spawn_result.connect(_on_spawn_result)
	set_process(true)
	print("[spawn-menu] created")


func _process(_delta: float) -> void:
	if not _mounted:
		_mount_tries += 1
		if _mount_tries % 30 == 1:   # every half second until the rig is there
			_try_mount()


## ————————————————————————————————————————————————————————————————————
## Mounting — the wrist in VR, a layer on desktop
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
		# the right hand's own laser must see the panel: take its mask as our layer
		if right != null and right.has_node("FunctionPointer"):
			var pointer: Node = right.get_node("FunctionPointer")
			var mask: Variant = pointer.get("collision_mask")
			if mask is int and int(mask) != 0:
				_vp3d.set("collision_layer", int(mask))
		# above the back of the wrist, tilted towards the face; fine-tune in-headset
		_vp3d.position = Vector3(0.0, 0.07, -0.09)
		_vp3d.rotation_degrees = Vector3(-55.0, 0.0, 0.0)
		left.add_child(_vp3d)
		left.button_pressed.connect(_on_left_button)
		_vp3d.visible = false
		_vp3d.set("enabled", false)
		_mounted = true
		call_deferred("_bind_ui_from_viewport")
		_make_grab(right, false)
		print("[spawn-menu] mounted on %s (toggle: %s)" % [left.name, ", ".join(TOGGLE_BUTTONS)])
	else:
		_mount_desktop()


func _mount_desktop() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "SpawnMenuLayer"
	_layer.layer = 60
	add_child(_layer)
	_ui = UI_SCENE.instantiate()
	# the left 55 % of the screen: the right part stays free to grab-and-move in
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.anchor_right = 0.55
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
	if _layer == null:
		return
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == TOGGLE_KEY:
		_set_open(not _open)
		get_viewport().set_input_as_handled()


func _on_left_button(button_name: String) -> void:
	if button_name in TOGGLE_BUTTONS:
		_set_open(not _open)


func _set_open(open: bool) -> void:
	_open = open
	if _vp3d != null:
		_vp3d.visible = open
		_vp3d.set("enabled", open)
	if _layer != null:
		_layer.visible = open
		if open:
			_mouse_before = Input.mouse_mode
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = _mouse_before
	if _grab != null and is_instance_valid(_grab):
		_grab.set("enabled", open)
	if open and _ui != null and _ui.has_method("set_status"):
		_ui.call("set_status", "floor %d — pick a work (it stands %.1f m ahead), or %s a work in the room to move it" % [_player_floor(), AHEAD_VR if _vp3d != null else AHEAD_DESKTOP, "trigger-hold" if _vp3d != null else "left-drag"])


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

func _on_spawn_requested(token: String, is_prop: bool) -> void:
	var where: Dictionary = _landing()
	if where.is_empty():
		_status("no floor under you to spawn on")
		return
	var req: Dictionary = {"k": "spawn", "floor": int(where["floor"]), "position": where["position"], "facing": where["facing"]}
	if is_prop:
		req["kind"] = token
	else:
		req["token"] = token
	var content: Node = _content()
	if content != null and String(content.get("trial_id")) != "":
		req["trial"] = String(content.get("trial_id"))
	if _link != null and _link.has_method("send_uplink"):
		_link.call("send_uplink", req)
		_last_floor = int(where["floor"])
		_status("asked the bridge: %s on floor %d at %s…" % [token, where["floor"], str(where["position"])])
	else:
		_status("no link to the PC — the spawn menu needs vr_link.py")


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
