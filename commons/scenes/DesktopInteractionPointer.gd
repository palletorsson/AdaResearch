extends Node3D

## Desktop mouse pointer for VR interactables.
## Raycasts from camera center, delivers XRToolsPointerEvent to targets.
## Supports click (buttons) and click-drag (sliders, knobs).

signal pointing_event(event)

@export var distance: float = 5.0
@export var collision_mask_value: int = 1310720  # layers 19 (handles) + 21 (area buttons)

var _raycast: RayCast3D
var _camera: Camera3D

# Pointer state
var _last_target: Node3D = null
var _last_position: Vector3 = Vector3.ZERO
var _locked_target: Node3D = null
var _is_pressed: bool = false

# Carry-grab (desktop pickup): right-click grabs a pickable / RigidBody under the crosshair and
# carries it in front of the camera; right-click again drops it; mouse wheel adjusts hold distance.
# This is a desktop stand-in for VR grab so you can pick up, move and place objects before the headset.
const GRAB_MASK := 393220   # layers 3 (pickable) + 17 + 18 (grab) — deliberately NOT world/walls (layer 1)
var _held: Node3D = null
var _held_freeze: bool = false
var _held_layer: int = 0
var _held_mask: int = 0
var _hold_distance: float = 2.0

## THE WEAPON AT THE BOTTOM OF THE SCREEN (2026-09-02, Palle: "can we have like
## in half life that the gun is placed at the bottom of the screen and we can use
## from there after we pick it up?").
##
## A thing with a TRIGGER is held like a weapon: parked low and right, rigid to
## the view. A thing without one keeps floating out in front at _hold_distance,
## where you can see what you are carrying and put it somewhere. That is the same
## distinction your hands make, and it needs no mode switch or extra key.
##
## THE BASIS STAYS PARALLEL TO THE VIEW, and that is not a stylistic choice.
## pink_gun.fire() sends its projectile along the GUN's -Z, so any cosmetic tilt
## of the viewmodel becomes a shot that misses by exactly that angle. Games that
## tilt their viewmodels fire along the view ray instead; this one fires along the
## model, so the model must not lie about where it points. Offset only.
@export var weapon_offset := Vector3(0.17, -0.15, -0.34)   # right, down, forward

## Where an adopted weapon lives. Created under this pointer, which rides the
## walker — NOT under the hall.
var _holster: Node3D = null
var _weapon_home: Node = null        # where it hung before we took it
var _is_weapon: bool = false         # this hold is a viewmodel, not a carry


## A thing is a weapon here if it has a trigger. Nothing else asked.
func _has_trigger(p: Node) -> bool:
	return p != null and is_instance_valid(p) and p.has_method("action")


func _ready() -> void:
	# Create raycast child
	_raycast = RayCast3D.new()
	_raycast.name = "PointerRay"
	_raycast.target_position = Vector3(0, 0, -distance)
	_raycast.collision_mask = collision_mask_value
	_raycast.collide_with_bodies = true
	_raycast.collide_with_areas = true
	add_child(_raycast)

	# Find camera (sibling under Head)
	_camera = get_parent().get_node_or_null("Camera3D") as Camera3D


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not _raycast:
		return

	# Carry a held object: keep it floating in front of the camera at the hold
	# distance, AND POINTING WHERE YOU LOOK.
	#
	# The orientation half was missing, and it only became visible once a carried
	# thing could be fired (2026-09-02). pink_gun.fire() sends its projectile
	# along the GUN's -Z; carrying by position alone left the gun wearing whatever
	# rotation it happened to have on the shelf, so the trigger would work
	# perfectly and the shot would go somewhere else entirely. That is worse than
	# the feature not existing, because it looks like it exists.
	#
	# It also just matches VR, where a grabbed object is attached to the hand and
	# follows it. Nothing is lost by doing this to every carried object: there is
	# no rotate-while-carrying control on desktop, so the old behaviour was not a
	# choice anyone could have made on purpose. The body is frozen by _grab_held,
	# so writing the transform does not fight the physics server.
	# A HOLSTERED WEAPON NEEDS NO CARRYING. It is a child of the holster, which is
	# a child of this pointer, which mirrors the camera — so it is already exactly
	# where it should be, every frame, with no lag. Lerping it here would fight
	# its own parent and reintroduce the wobble a viewmodel must not have.
	if _is_weapon:
		pass
	elif _held and is_instance_valid(_held) and _camera:
		var cam_xf := _camera.global_transform
		var target_pos := cam_xf.origin + (-cam_xf.basis.z) * _hold_distance
		var xf := _held.global_transform
		xf.origin = xf.origin.lerp(target_pos, 0.4)
		xf.basis = xf.basis.orthonormalized().slerp(cam_xf.basis.orthonormalized(), 0.4)
		_held.global_transform = xf
	elif _held and not is_instance_valid(_held):
		_held = null

	var raw_collider: Node3D = null
	var hit_position := Vector3.ZERO

	if _raycast.is_colliding():
		raw_collider = _raycast.get_collider() as Node3D
		hit_position = _raycast.get_collision_point()

	# Resolve to nearest ancestor with pointer_event()
	var new_target := _resolve_pointer_target(raw_collider)
	var new_at := hit_position

	# If pressed and locked, keep the locked target
	if _is_pressed and _locked_target:
		new_target = _locked_target
		if not _raycast.is_colliding() or _resolve_pointer_target(raw_collider) != _locked_target:
			# Ray missed or hit something else — project mouse onto target plane
			new_at = _project_to_target_plane()

	# Emit hover events (enter / exit / move)
	_emit_hover_events(new_target, new_at)

	_last_target = new_target
	_last_position = new_at


func _input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# A CARRIED THING TAKES THE CLICK FIRST — see _try_held_action.
			if _try_held_action(true):
				get_viewport().set_input_as_handled()
			elif _last_target:
				_locked_target = _last_target
				_is_pressed = true
				XRToolsPointerEvent.pressed(self, _locked_target, _last_position)
				get_viewport().set_input_as_handled()
		else:
			_try_held_action(false)
			if _locked_target:
				XRToolsPointerEvent.released(self, _locked_target, _last_position)
				_locked_target = null
			_is_pressed = false

	# Right-click = grab / drop a pickable; mouse wheel adjusts hold distance while carrying.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if _held:
			_drop_held()
		else:
			var p := _find_grabbable()
			if p:
				_grab_held(p)
		get_viewport().set_input_as_handled()
	elif _held and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_hold_distance = clampf(_hold_distance - 0.25, 1.0, 5.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_hold_distance = clampf(_hold_distance + 0.25, 1.0, 5.0)


## THE TRIGGER A CARRIED OBJECT NEVER HAD ON DESKTOP.
##
## 2026-09-02, Palle: "In the endless museum there are silhouettes that attack.
## In VR we can pick up a gun and stop them in their tracks, they become
## sculptures but in desktop we can not stop the silhouettes."
##
## The gap was not that silhouettes could not be clicked — it was that a weapon
## in your hand was INERT here. In VR the chain is: grab the gun, the pickable's
## trigger emits action_pressed, pink_gun.fire() throws a catalyst projectile,
## and hit_by_catalyst_mode turns a silhouette into a statue. On desktop RMB
## already grabbed the gun (its pickable is collision_layer 3, which GRAB_MASK
## covers), and then nothing ever called the thing's action(). It sat in the
## hand doing nothing.
##
## So this adds ONE rung rather than a silhouette special case: while carrying a
## pickable, LMB is its trigger. Same rule in both modes — the gun stops them,
## and you must be holding the gun. The alternative, clicking a silhouette dead
## from any range holding nothing, would have made desktop a different game and
## written the object out of the story; this project's own line is that friends
## grant the player no power, and the power here is the object.
##
## It also comes free for everything else with an action — the sledgehammer, the
## laser — instead of one enemy learning one new way to die.
##
## THE HELD THING WINS OVER A HOVER TARGET. One pointer, one job: to press a
## button, drop what you are carrying (RMB), the same way a full hand in VR
## cannot also push. Returns true when it consumed the click.
##
## Separate from _input on purpose: _input refuses to run unless the mouse is
## captured, which no headless probe can arrange, and a branch no test can reach
## is a branch that rots. probe_desktop_trigger.gd calls this directly.
var _action_held: Node3D = null      # what THIS click is driving, if anything


func _try_held_action(pressed: bool) -> bool:
	if pressed:
		if not (_held != null and is_instance_valid(_held) and _held.has_method("action")):
			return false
		_action_held = _held
		_action_held.call("action")
		return true
	# Release goes to whatever the PRESS started, not to whatever is in the hand
	# now — a click that begins on the gun and ends after it was dropped would
	# otherwise leave the trigger held down forever, or release a different object.
	if _action_held == null or not is_instance_valid(_action_held):
		_action_held = null
		return false
	if _action_held.has_method("action_release"):
		_action_held.call("action_release")
	_action_held = null
	return true


func _emit_hover_events(new_target: Node3D, new_at: Vector3) -> void:
	if new_target and not _last_target:
		# Entered new target
		XRToolsPointerEvent.entered(self, new_target, new_at)
		XRToolsPointerEvent.moved(self, new_target, new_at, new_at)
	elif not new_target and _last_target:
		# Exited last target
		XRToolsPointerEvent.exited(self, _last_target, _last_position)
	elif new_target != _last_target:
		# Switched targets
		if _last_target:
			XRToolsPointerEvent.exited(self, _last_target, _last_position)
		if new_target:
			XRToolsPointerEvent.entered(self, new_target, new_at)
			XRToolsPointerEvent.moved(self, new_target, new_at, new_at)
	elif new_target and new_at != _last_position:
		# Moved on same target
		XRToolsPointerEvent.moved(self, new_target, new_at, _last_position)


func _resolve_pointer_target(collider: Node) -> Node3D:
	if not collider:
		return null
	var current := collider
	# Walk up the tree to find the node that handles pointer events
	while current:
		if current.has_method("pointer_event"):
			return current as Node3D
		if current.has_signal("pointer_event"):
			return current as Node3D
		current = current.get_parent()
	return null


func _project_to_target_plane() -> Vector3:
	if not _locked_target or not _camera:
		return _last_position
	var target_pos := _locked_target.global_position
	var cam_pos := _camera.global_position
	var plane_normal := (cam_pos - target_pos).normalized()
	var plane := Plane(plane_normal, target_pos)
	# Project from camera center (crosshair)
	var viewport_center := get_viewport().get_visible_rect().size * 0.5
	var ray_origin := _camera.project_ray_origin(viewport_center)
	var ray_dir := _camera.project_ray_normal(viewport_center)
	var hit = plane.intersects_ray(ray_origin, ray_dir)
	if hit:
		return hit
	return _last_position


## True when user is click-dragging on a control
func is_dragging() -> bool:
	return _is_pressed and _locked_target != null


## True when pointer hovers over a pointable control
func has_hover_target() -> bool:
	return _last_target != null


## True while carrying a grabbed object (desktop carry-grab).
func is_holding() -> bool:
	return _held != null and is_instance_valid(_held)


# Ray from the crosshair; returns the first pickable / RigidBody hit (walks up to the owner).
func _find_grabbable() -> Node3D:
	if not _camera:
		return null
	var space := _camera.get_world_3d().direct_space_state
	var from := _camera.global_position
	var to := from + (-_camera.global_transform.basis.z) * distance
	var q := PhysicsRayQueryParameters3D.create(from, to, GRAB_MASK)
	q.collide_with_bodies = true
	q.collide_with_areas = false
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return null
	var n: Node = hit.get("collider")
	while n:
		if n.has_method("pick_up") or n is RigidBody3D:
			return n as Node3D
		n = n.get_parent()
	return null


func _grab_held(p: Node3D) -> void:
	_held = p
	if p is RigidBody3D:
		_held_freeze = (p as RigidBody3D).freeze
		(p as RigidBody3D).freeze = true
	if p is CollisionObject3D:
		_held_layer = (p as CollisionObject3D).collision_layer
		_held_mask = (p as CollisionObject3D).collision_mask
		(p as CollisionObject3D).collision_layer = 0   # don't shove the player while carried
		(p as CollisionObject3D).collision_mask = 0
	if _camera:
		_hold_distance = clampf(_camera.global_position.distance_to(p.global_position), 1.0, 4.0)

	# A WEAPON IS ADOPTED ON FIRST GRAB — the same reason HandInventory adopts one
	# in VR, and the reason this is a reparent rather than a fixed offset applied
	# each frame. In the museum a gun hangs in a cabinet inside a hall SEGMENT,
	# and the segment is freed at the next crossing. Held by position alone, the
	# gun would simply vanish out of the player's hands one hall later, and the
	# pointer would be left holding a freed node — the exact failure this session
	# has now fixed twice elsewhere. Under the holster it belongs to the walker
	# and travels with them.
	_is_weapon = _has_trigger(p)
	if not _is_weapon:
		return
	# THE HOLSTER HANGS OFF THE CAMERA, not off this pointer. The camera IS the
	# view; the pointer only usually agrees with it. Under the museum's walker
	# they match, because em_desktop_pointer mirrors the camera every frame — but
	# the shared rig puts this pointer beside a Camera3D under a Head, and where
	# the pitch lives in that rig is not this file's business to assume. Hung off
	# the pointer, the probe measured the weapon at 0.000 against the view: dead
	# perpendicular. Hung off the camera it is 1.000 by construction, whatever
	# any rig does above it.
	var mount: Node3D = _camera if (_camera != null and is_instance_valid(_camera)) else self
	if _holster == null or not is_instance_valid(_holster) or _holster.get_parent() != mount:
		if _holster != null and is_instance_valid(_holster):
			_holster.queue_free()
		_holster = Node3D.new()
		_holster.name = "DesktopHolster"
		mount.add_child(_holster)
	_weapon_home = p.get_parent()
	if _weapon_home != null:
		p.reparent(_holster, false)
	# Parked, not lerped: a viewmodel that lags the view reads as a bug.
	p.transform = Transform3D(Basis.IDENTITY, weapon_offset)


func _drop_held() -> void:
	if _held and is_instance_valid(_held):
		# A weapon leaves the holster into the world it is standing in — NOT back
		# into the hall it came from, which may have been freed several crossings
		# ago. current_scene is the one parent guaranteed to still be there.
		if _is_weapon and _held.get_parent() == _holster:
			var home: Node = _weapon_home
			if home == null or not is_instance_valid(home) or not home.is_inside_tree():
				home = get_tree().current_scene
			if home != null:
				_held.reparent(home, true)
		if _held is RigidBody3D:
			(_held as RigidBody3D).freeze = _held_freeze
			(_held as RigidBody3D).linear_velocity = Vector3.ZERO
			(_held as RigidBody3D).angular_velocity = Vector3.ZERO
		if _held is CollisionObject3D:
			(_held as CollisionObject3D).collision_layer = _held_layer
			(_held as CollisionObject3D).collision_mask = _held_mask
	_held = null
	_weapon_home = null
	_is_weapon = false
