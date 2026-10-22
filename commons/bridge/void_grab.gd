extends Node
## Grab-and-move in The Void, writing back through the bridge.
##
## 2026-10-22, Palle: "VR grab-and-move next". While the spawn menu is open (edit
## mode), the right hand's trigger on a work picks up its MOUNT — not the artifact's
## own grab logic, the record's node (`<id>` / `Prop_<id>` under `Content<n>`) — and
## drags it on the plane it stands on; the thumbstick turns it in 15° steps. On
## release the new position and facing go up the link as {"k":"spawn_move", floor,
## id, position, facing}; tools/vr_link.py writes them into the record and saves
## through the editor's route; the revision comes back to every game as a
## `transform` that live_update.gd applies in place — this game included, which
## re-seats the mount exactly where the file says. A refused save (422, 409)
## snaps the mount back to where it stood. Nothing is written here.
##
## Desktop: with the menu open (B), left-drag in the view outside the panel; Q / E
## turn. The ray comes from the camera through the mouse.
##
## Finding the mount under the laser: a ray on EVERY physics layer (the Void's
## pointer mask is handles/pointables/UI, most works are not on it) and the collider's
## ancestry up to a floor root; a hit on the slab picks the nearest mount within 1.5 m.

const SNAP_M := 0.25
const SNAP_DEG := 15.0
const NEAR_M := 1.5
const RAY_M := 12.0
const TURN_DEG_S := 90.0

var enabled := false
var _menu: Node = null
var _right: XRController3D = null
var _desktop := false
var _held: Node3D = null
var _held_root: Node3D = null
var _held_floor := -1
var _held_id := ""
var _held_coll := "artifacts"
var _start: Transform3D
var _plane_y := 0.0
var _mouse_down := false


func setup(menu: Node, right: XRController3D, desktop: bool) -> void:
	_menu = menu
	_right = right
	_desktop = desktop
	if _right != null:
		_right.button_pressed.connect(_on_button_pressed)
		_right.button_released.connect(_on_button_released)
	set_process(true)


func _process(delta: float) -> void:
	if not enabled:
		if _held != null:
			_drop(false)
		return
	if _held == null or not is_instance_valid(_held):
		_held = null
		return
	var ray: Dictionary = _ray()
	if ray.is_empty():
		return
	var plane := Plane(Vector3.UP, _plane_y)
	var hit: Variant = plane.intersects_ray(ray["from"], ray["dir"])
	if hit is Vector3:
		var p: Vector3 = hit
		_held.global_position = Vector3(p.x, _held.global_position.y, p.z)
	var turn := 0.0
	if _right != null and not _desktop:
		turn = _right.get_vector2("primary").x
	else:
		turn = (1.0 if Input.is_key_pressed(KEY_E) else 0.0) - (1.0 if Input.is_key_pressed(KEY_Q) else 0.0)
	if absf(turn) > 0.2:
		_held.rotation_degrees.y -= turn * TURN_DEG_S * delta


## ————————————————————————————————————————————————————————————————————
## Input
## ————————————————————————————————————————————————————————————————————

func _on_button_pressed(button_name: String) -> void:
	if enabled and button_name == "trigger_click" and _held == null:
		_grab()


func _on_button_released(button_name: String) -> void:
	if button_name == "trigger_click" and _held != null:
		_drop(true)


func _input(event: InputEvent) -> void:
	if not _desktop or not enabled:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb: InputEventMouseButton = event
		if mb.pressed:
			if _menu != null and _menu.has_method("mouse_over_panel") and bool(_menu.call("mouse_over_panel")):
				return
			_mouse_down = true
			if _held == null:
				_grab()
		else:
			_mouse_down = false
			if _held != null:
				_drop(true)


## ————————————————————————————————————————————————————————————————————
## The ray and the mount under it
## ————————————————————————————————————————————————————————————————————

func _ray() -> Dictionary:
	if _desktop or _right == null:
		var cam: Camera3D = get_viewport().get_camera_3d()
		if cam == null:
			return {}
		var m: Vector2 = get_viewport().get_mouse_position()
		return {"from": cam.project_ray_origin(m), "dir": cam.project_ray_normal(m)}
	return {"from": _right.global_position, "dir": -_right.global_transform.basis.z}


func _content() -> Node:
	for n in get_tree().get_nodes_in_group("biome_grid"):
		if is_instance_valid(n) and n.has_method("load_floor") and n.has_method("reset_floor"):
			return n
	return null


func _grab() -> void:
	var ray: Dictionary = _ray()
	if ray.is_empty():
		return
	var content: Node = _content()
	if content == null:
		return
	var space: PhysicsDirectSpaceState3D = get_viewport().get_world_3d().direct_space_state
	var from: Vector3 = ray["from"] + ray["dir"] * 0.3
	var q := PhysicsRayQueryParameters3D.create(from, from + ray["dir"] * RAY_M, 0xFFFFFFFF)
	q.collide_with_areas = true
	var hit: Dictionary = space.intersect_ray(q)
	if hit.is_empty():
		_say("nothing under the laser")
		return
	var found: Array = _mount_of(content, hit.get("collider"), hit.get("position", Vector3.ZERO))
	if found.is_empty():
		_say("no work there to move")
		return
	_held = found[0]
	_held_root = found[1]
	_held_floor = int(found[2])
	_held_coll = String(found[3])
	_held_id = String(found[4])
	_start = _held.global_transform
	_plane_y = _held.global_position.y
	_say("holding %s — release to save" % _held_id)


## [mount, floor_root, floor_index, collection, id] or [].
func _mount_of(content: Node, collider: Variant, at: Vector3) -> Array:
	var exhibits: Variant = content.get("exhibits")
	var props: Variant = content.get("props")
	var by_node: Dictionary = {}
	for pair in [[exhibits, "artifacts"], [props, "props"]]:
		var reg: Variant = pair[0]
		if reg is Dictionary:
			for key in (reg as Dictionary):
				var node: Variant = (reg as Dictionary)[key]
				if node is Node and is_instance_valid(node):
					by_node[node] = [String(key), String(pair[1])]
	# 1. the collider's ancestry
	var n: Node = collider as Node
	while n != null:
		if by_node.has(n):
			return _entry(n, by_node[n])
		n = n.get_parent()
	# 2. the nearest mount to the hit point
	var best: Node = null
	var best_d: float = NEAR_M
	for node in by_node:
		if node is Node3D:
			var d: float = (node as Node3D).global_position.distance_to(at)
			if d < best_d:
				best_d = d
				best = node
	if best != null:
		return _entry(best, by_node[best])
	return []


func _entry(node: Node, info: Array) -> Array:
	var key: String = info[0]            # "%d/%s"
	var slash: int = key.find("/")
	var floor_i: int = int(key.substr(0, slash))
	var id: String = key.substr(slash + 1)
	var coll: String = info[1]
	var root: Node = node.get_parent()
	while root != null and not root.has_meta("void_content_floor"):
		root = root.get_parent()
	if root == null:
		return []
	return [node, root, floor_i, coll, id]


## ————————————————————————————————————————————————————————————————————
## Release: snap, send, let the revision re-seat it
## ————————————————————————————————————————————————————————————————————

func _drop(save: bool) -> void:
	var mount: Node3D = _held
	_held = null
	if mount == null or not is_instance_valid(mount):
		return
	if not save:
		mount.global_transform = _start
		return
	var local: Vector3 = _held_root.to_local(mount.global_position)
	var pos: Array = [snappedf(local.x, SNAP_M), snappedf(local.z, SNAP_M)]
	var facing: float = fposmod(snappedf(mount.rotation_degrees.y, SNAP_DEG), 360.0)
	mount.position = Vector3(float(pos[0]), mount.position.y, float(pos[1]))
	mount.rotation_degrees.y = facing
	var moved: bool = _start.origin.distance_to(mount.global_position) > 0.01 \
		or absf(angle_difference(_start.basis.get_euler().y, mount.rotation.y)) > 0.01
	if not moved:
		_say("%s not moved" % _held_id)
		return
	var link: Node = _link()
	if link == null or not link.has_method("send_uplink"):
		mount.global_transform = _start
		_say("no link to the PC — put it back")
		return
	var req: Dictionary = {"k": "spawn_move", "floor": _held_floor, "id": _held_id, "collection": _held_coll,
		"position": pos, "facing": facing, "tag": "grab:%s" % _held_id}
	var content: Node = _content()
	if content != null and String(content.get("trial_id")) != "":
		req["trial"] = String(content.get("trial_id"))
	link.call("send_uplink", req)
	_say("%s → [%s, %s] facing %d — saving…" % [_held_id, str(pos[0]), str(pos[1]), int(facing)])
	# a refusal snaps it back: listen once for the bridge's answer to this tag
	var start: Transform3D = _start
	var cb: Callable
	cb = func(r: Dictionary) -> void:
		if String(r.get("tag", "")) != "grab:%s" % _held_id_of(req):
			return
		if link.spawn_result.is_connected(cb):
			link.spawn_result.disconnect(cb)
		if not bool(r.get("ok", false)) and is_instance_valid(mount):
			mount.global_transform = start
	link.spawn_result.connect(cb)


func _held_id_of(req: Dictionary) -> String:
	return String(req.get("id", ""))


func _link() -> Node:
	var n: Node = _menu
	while n != null:
		if n.has_method("send_uplink"):
			return n
		n = n.get_parent()
	return null


func _say(text: String) -> void:
	print("[void-grab] " + text)
	if _menu != null and _menu.has_method("_status"):
		_menu.call("_status", text)
