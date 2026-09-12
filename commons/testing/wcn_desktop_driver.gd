extends Node
class_name WcnDesktopDriver
## ACTUAL DESKTOP INPUT for the Waves/Chance/Noise live probes (2026-09-10).
##
## The endless museum's own desktop walker has no interaction pointer (its LMB
## handling is the doll editor's), so in the museum a panel button is a VR affair.
## The project's desktop rig — commons/scenes/desktop_player.tscn, the one every
## desktop_* test scene carries — has one: DesktopInteractionPointer under Head
## raycasts from the camera and turns a LEFT mouse button into
## XRToolsPointerEvent.pressed/released on the thing under the crosshair, exactly
## as the VR controller does. This driver stands that rig in a built museum hall
## and feeds it the same events a person would: ui_* actions to walk, mouse
## buttons through Input.parse_input_event to press. Nothing here emits an
## artifact's signal directly; whatever fires, fired because the rig's pointer
## hit it. That is the distinction the handback keeps: "emitted signal" versus
## "desktop input".
##
## Limits, stated: synthetic events through the real input pipeline are not a
## person's hand on a mouse; the rig is not the museum's walker; a headset is a
## third lane. All three are reported separately.

var rig: CharacterBody3D
var head: Node3D
var cam: Camera3D
var pointer: Node
var log: Array = []

## Stand the rig at a world position, facing -z (the museum's "into the hall").
## `museum`: the EndlessMuseum node. Its walker keeps a one-second camera guard that
## reclaims the viewport for the walker's own camera whenever the view "drifts"
## (endless_museum.gd, cam_guard, 2026-08-21) — under it every capture taken
## "from the rig" was drawn by the walker's camera (first live chain, 2026-09-10).
## The guard is stopped here, explicitly and for the rest of the run, so the rig's
## camera and the probe's later capture cameras draw what they stand at.
var walker_cam_guard_stopped: bool = false

func spawn(at: Vector3, museum: Node = null) -> void:
	if museum != null:
		var walker_cam: Camera3D = museum.get("_cam")
		if walker_cam != null and is_instance_valid(walker_cam):
			for c in walker_cam.get_children():
				if c is Timer:
					(c as Timer).stop()
					walker_cam_guard_stopped = true
	log.append({"event": "walker_cam_guard_stopped", "value": walker_cam_guard_stopped})
	var ps: PackedScene = load("res://commons/scenes/desktop_player.tscn")
	rig = ps.instantiate()
	rig.name = "WcnDesktopRig"
	# NOT a child of the root: DesktopPlayer._ready treats a root-parented rig
	# as "running standalone" and change_scene_to_file's the Lab Desktop scene,
	# which frees the museum under the probe (first live chain, 2026-09-10).
	# Under this Node the rig is its own 3D top: global_position is its own.
	add_child(rig)
	rig.global_position = at + Vector3(0, 0.05, 0)
	head = rig.get_node_or_null("Head")
	cam = rig.get_node_or_null("Head/Camera3D")
	pointer = rig.get_node_or_null("Head/DesktopInteractionPointer")
	if cam != null:
		cam.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	log.append({"event": "spawn", "at": [at.x, at.y, at.z]})

func is_ready() -> bool:
	return rig != null and head != null and cam != null and pointer != null

## Turn the body (yaw) and the head (pitch) toward a world point, the way mouse
## look would leave them; keep the rig's own bookkeeping consistent so a later
## motion event does not snap back.
func aim_at(target: Vector3) -> void:
	var flat := Vector3(target.x, rig.global_position.y, target.z)
	if flat.distance_to(rig.global_position) > 0.01:
		rig.look_at(flat, Vector3.UP)
		rig.rotation.x = 0.0; rig.rotation.z = 0.0
	head.look_at(target, Vector3.UP)
	head.rotation.y = 0.0; head.rotation.z = 0.0
	# AIM ON THE CAMERA'S OWN POSITION AND FORWARD (2026-09-11, Synthesis Lab). The rig's
	# camera sits at the head pivot (desktop_player.tscn: Head at y 1.6, Camera3D at
	# identity), so head.look_at is right when the rig stands still — but a rig placed
	# within its radius of a collider is pushed out by the physics AFTER the aim (0.11 m
	# from a platform, a 0.5 m stand before a bench), the eye moves, and the ray meant
	# for a button 0.65 m away passes 8 cm over it. Iterating on the camera's actual
	# forward costs nothing; the real remedy is a stand clear of colliders, and a press
	# records the pose so a miss can be read.
	var miss_deg: float = 0.0
	if cam != null and is_instance_valid(cam):
		for k in range(4):
			var to_t: Vector3 = (target - cam.global_position).normalized()
			var fwd: Vector3 = -cam.global_transform.basis.z
			var yaw_t: float = atan2(-to_t.x, -to_t.z)
			var yaw_f: float = atan2(-fwd.x, -fwd.z)
			rig.rotation.y += wrapf(yaw_t - yaw_f, -PI, PI)
			var pitch_t: float = asin(clampf(to_t.y, -1.0, 1.0))
			var pitch_f: float = asin(clampf(fwd.y, -1.0, 1.0))
			head.rotation.x += pitch_t - pitch_f
			head.rotation.x = clampf(head.rotation.x, -PI * 0.49, PI * 0.49)
		var to_t2: Vector3 = (target - cam.global_position).normalized()
		miss_deg = rad_to_deg(acos(clampf(to_t2.dot(-cam.global_transform.basis.z), -1.0, 1.0)))
	rig.set("camera_rotation", Vector2(head.rotation.x, rig.rotation.y))
	rig.set("mouse_motion", Vector2.ZERO)
	var rec: Dictionary = pose()
	rec["miss_deg"] = snappedf(miss_deg, 0.01)
	log.append({"event": "aim", "pose": rec})

## Where the rig stands and looks, and which camera the viewport is drawing from.
func pose() -> Dictionary:
	if rig == null or not is_instance_valid(rig):
		return {"rig": null}
	var fwd: Vector3 = -cam.global_transform.basis.z if cam != null and is_instance_valid(cam) else -rig.global_transform.basis.z
	var cur: Camera3D = get_viewport().get_camera_3d()
	return {"rig": [snappedf(rig.global_position.x, 0.01), snappedf(rig.global_position.y, 0.01), snappedf(rig.global_position.z, 0.01)],
		"eye": [snappedf(cam.global_position.x, 0.01), snappedf(cam.global_position.y, 0.01), snappedf(cam.global_position.z, 0.01)] if cam != null else null,
		"forward": [snappedf(fwd.x, 0.01), snappedf(fwd.y, 0.01), snappedf(fwd.z, 0.01)],
		"current_camera": str(cur.get_path()).right(50) if cur != null else "none"}

## Hold a ui_* action for a number of physics frames (walking), then release.
## Returns the displacement the rig actually made.
func walk(action: String, frames: int) -> Vector3:
	var from: Vector3 = rig.global_position
	Input.action_press(action)
	for i in range(frames):
		await get_tree().physics_frame
	Input.action_release(action)
	for i in range(3):
		await get_tree().physics_frame
	var d: Vector3 = rig.global_position - from
	log.append({"event": "walk", "action": action, "frames": frames, "moved": [snappedf(d.x, 0.01), snappedf(d.y, 0.01), snappedf(d.z, 0.01)], "pose": pose()})
	return d

## What the pointer's ray sees right now (after two process frames so hover is fresh).
func hover_target() -> Node:
	await get_tree().process_frame
	await get_tree().process_frame
	if pointer != null and pointer.has_method("has_hover_target") and bool(pointer.call("has_hover_target")):
		return pointer.get("_last_target")
	return null

## A left click through the input pipeline: press, one frame, release.
func click(button_index: int = MOUSE_BUTTON_LEFT) -> void:
	var centre: Vector2 = get_viewport().get_visible_rect().size * 0.5
	var down := InputEventMouseButton.new()
	down.button_index = button_index; down.pressed = true; down.position = centre; down.global_position = centre
	Input.parse_input_event(down)
	await get_tree().process_frame
	await get_tree().physics_frame
	var up := InputEventMouseButton.new()
	up.button_index = button_index; up.pressed = false; up.position = centre; up.global_position = centre
	Input.parse_input_event(up)
	await get_tree().process_frame
	log.append({"event": "click", "button": button_index})

## Stand within reach of a control, look at it, and click it. Returns what the
## pointer reported under the crosshair at the moment of the click.
func press(control: Node3D, stand_at: Vector3) -> Dictionary:
	rig.global_position = stand_at
	await get_tree().physics_frame
	aim_at(control.global_position)
	var seen: Node = await hover_target()
	var ray_rec: Dictionary = ray_report()
	await click(MOUSE_BUTTON_LEFT)
	var rec := {"control": str(control.get_path()).right(60), "hover": (str(seen.get_path()).right(60) if seen != null else "nothing"),
		"stand": [snappedf(stand_at.x, 0.01), snappedf(stand_at.y, 0.01), snappedf(stand_at.z, 0.01)], "ray": ray_rec}
	log.append({"event": "press", "record": rec})
	return rec

## What the pointer's own RayCast3D meets right now, and what an independent ray from the
## camera along its forward meets on the pointer's layers (19 + 21): the diagnostic for a
## press that finds nothing under the crosshair.
func ray_report() -> Dictionary:
	var out := {}
	var rc: RayCast3D = pointer.get("_raycast") if pointer != null else null
	if rc != null:
		out["raycast_colliding"] = rc.is_colliding()
		out["raycast_collider"] = str(rc.get_collider().get_path()).right(70) if rc.is_colliding() and rc.get_collider() != null else "none"
		var pt: Vector3 = rc.get_collision_point() if rc.is_colliding() else Vector3.ZERO
		out["raycast_point"] = [snappedf(pt.x, 0.01), snappedf(pt.y, 0.01), snappedf(pt.z, 0.01)]
		out["raycast_mask"] = rc.collision_mask
		out["raycast_areas"] = rc.collide_with_areas
		out["raycast_length"] = -rc.target_position.z
	if cam != null:
		var from: Vector3 = cam.global_position
		var dir: Vector3 = -cam.global_transform.basis.z
		var q := PhysicsRayQueryParameters3D.create(from, from + dir * 5.0, 1310720)
		q.collide_with_areas = true
		q.collide_with_bodies = true
		var hit: Dictionary = cam.get_world_3d().direct_space_state.intersect_ray(q)
		out["independent_ray"] = (str((hit["collider"] as Node).get_path()).right(70) if not hit.is_empty() else "none")
		out["camera_from"] = [snappedf(from.x, 0.01), snappedf(from.y, 0.01), snappedf(from.z, 0.01)]
		out["camera_dir"] = [snappedf(dir.x, 0.01), snappedf(dir.y, 0.01), snappedf(dir.z, 0.01)]
	return out

## A left button DOWN alone, then UP alone: the two halves of a click, for drags.
func press_down(button_index: int = MOUSE_BUTTON_LEFT) -> void:
	var centre: Vector2 = get_viewport().get_visible_rect().size * 0.5
	var down := InputEventMouseButton.new()
	down.button_index = button_index; down.pressed = true; down.position = centre; down.global_position = centre
	Input.parse_input_event(down)
	await get_tree().process_frame
	await get_tree().physics_frame
	log.append({"event": "press_down", "button": button_index})

func release(button_index: int = MOUSE_BUTTON_LEFT) -> void:
	var centre: Vector2 = get_viewport().get_visible_rect().size * 0.5
	var up := InputEventMouseButton.new()
	up.button_index = button_index; up.pressed = false; up.position = centre; up.global_position = centre
	Input.parse_input_event(up)
	await get_tree().process_frame
	log.append({"event": "release", "button": button_index})

## A drag through the pointer, as a mouse would make it: look at `from` (a handle),
## hold the left button, swing the view to `to` over `frames` process frames (the
## pointer emits MOVED events with the ray's point along the way; a slider projects
## them onto its track), release. Returns what was under the crosshair at the press
## and whether the pointer reported a drag midway.
func drag(from: Vector3, to: Vector3, frames: int) -> Dictionary:
	aim_at(from)
	var seen: Node = await hover_target()
	await press_down(MOUSE_BUTTON_LEFT)
	var midway: bool = false
	for k in range(1, frames + 1):
		aim_at(from.lerp(to, float(k) / float(frames)))
		await get_tree().process_frame
		if k == int(frames / 2) and pointer != null and pointer.has_method("is_dragging"):
			midway = bool(pointer.call("is_dragging"))
	await release(MOUSE_BUTTON_LEFT)
	var rec := {"hover": (str(seen.get_path()).right(60) if seen != null else "nothing"), "dragging_midway": midway,
		"from": [snappedf(from.x, 0.01), snappedf(from.y, 0.01), snappedf(from.z, 0.01)], "to": [snappedf(to.x, 0.01), snappedf(to.y, 0.01), snappedf(to.z, 0.01)], "frames": frames}
	log.append({"event": "drag", "record": rec})
	return rec

## The facts about a control the pointer should meet: its area's layer, flags and place, and
## whether the physics space finds anything at that place on the pointer's layers.
func inspect_control(control: Node) -> Dictionary:
	var out := {"control": str(control.get_path()).right(60)}
	var area: Node = control if control is Area3D else control.find_child("InteractableAreaButton", true, false)
	if area == null:
		for c in control.find_children("*", "Area3D", true, false):
			area = c; break
	if area == null:
		out["area"] = "none"
		return out
	var a: Area3D = area
	out["area"] = str(a.get_path()).right(60)
	out["layer"] = a.collision_layer
	out["mask"] = a.collision_mask
	out["monitorable"] = a.monitorable
	out["monitoring"] = a.monitoring
	out["process_mode"] = a.process_mode
	out["inside_tree"] = a.is_inside_tree()
	out["visible"] = a.visible
	var gp: Vector3 = a.global_position
	out["global_position"] = [snappedf(gp.x, 0.001), snappedf(gp.y, 0.001), snappedf(gp.z, 0.001)]
	out["global_scale"] = [snappedf(a.global_transform.basis.get_scale().x, 0.01), snappedf(a.global_transform.basis.get_scale().y, 0.01), snappedf(a.global_transform.basis.get_scale().z, 0.01)]
	var shapes: Array = []
	for c in a.get_children():
		if c is CollisionShape3D:
			var cs: CollisionShape3D = c
			shapes.append({"shape": str(cs.shape.get_class()) if cs.shape != null else "none", "disabled": cs.disabled,
				"radius": (cs.shape as SphereShape3D).radius if cs.shape is SphereShape3D else -1.0,
				"at": [snappedf(cs.global_position.x, 0.001), snappedf(cs.global_position.y, 0.001), snappedf(cs.global_position.z, 0.001)]})
	out["shapes"] = shapes
	var space := a.get_world_3d().direct_space_state
	var sph := SphereShape3D.new(); sph.radius = 0.06
	for mask in [1310720, 0xFFFFFFFF]:
		var q := PhysicsShapeQueryParameters3D.new(); q.shape = sph; q.transform = Transform3D(Basis.IDENTITY, gp)
		q.collision_mask = mask; q.collide_with_areas = true; q.collide_with_bodies = true
		var found: Array = []
		for hit in space.intersect_shape(q, 12):
			var col: Node = (hit as Dictionary).get("collider")
			if col != null: found.append(str(col.get_path()).right(50))
		out["at_position_mask_%d" % mask] = found
	# controlled rays at the shape itself
	var centre: Vector3 = gp
	var n: Vector3 = a.global_transform.basis.y.normalized()   # the cap's direction (push_button: local +y)
	for c in a.get_children():
		if c is CollisionShape3D:
			centre = (c as CollisionShape3D).global_position
			break
	out["cap_normal"] = [snappedf(n.x, 0.01), snappedf(n.y, 0.01), snappedf(n.z, 0.01)]
	var rays := {"along_normal_from_0.3": [centre + n * 0.3, centre - n * 0.1]}
	if cam != null:
		rays["camera_to_centre"] = [cam.global_position, centre + (centre - cam.global_position).normalized() * 0.2]
		rays["camera_to_outer_cap"] = [cam.global_position, centre + n * 0.02 + (centre + n * 0.02 - cam.global_position).normalized() * 0.2]
	for key in rays.keys():
		for mask in [1310720, 0xFFFFFFFF]:
			var rq := PhysicsRayQueryParameters3D.create(rays[key][0], rays[key][1], mask)
			rq.collide_with_areas = true; rq.collide_with_bodies = true
			var h: Dictionary = space.intersect_ray(rq)
			out["ray_%s_mask_%d" % [key, mask]] = (str((h["collider"] as Node).get_path()).right(50) if not h.is_empty() else "none")
	return out

func teardown() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if rig != null and is_instance_valid(rig):
		rig.queue_free()
	await get_tree().process_frame
	var cur: Camera3D = get_viewport().get_camera_3d()
	log.append({"event": "teardown", "current_camera_after": str(cur.get_path()).right(50) if cur != null else "none"})
