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

## THE ARSENAL (2026-09-02, Palle: "yes add switching between the weapons").
##
## Every weapon picked up stays in the holster; the wheel draws a different one.
## Stowed means DISABLED AND HIDDEN, not merely invisible — the sledgehammer runs
## a _physics_process that measures its own head speed and strikes what it sweeps
## through, so a stowed hammer riding the holster while you swing a gun would go
## on breaking things you never aimed at. VR stows by taking the weapon out of
## the tree for the same reason.
var _arsenal: Array[Node3D] = []
var _drawn_i: int = -1


## ONE LIST OF WEAPONS, NOT TWO. HandInventory.is_weapon is the VR rig's own test
## (token meta, then a PinkGun child, then a name containing Sledgehammer), so
## desktop and VR can never disagree about what a weapon is. The first version of
## this file used `has_method("action")` for it, which is not a test of anything:
## see _fires below.
const HandInv := preload("res://commons/player/hand_inventory.gd")


func _is_weapon_node(p: Node) -> bool:
	return p != null and is_instance_valid(p) and HandInv.is_weapon(p)


## DOES CLICKING THIS DO ANYTHING? Not "has an action()" — EVERY XRToolsPickable
## has action(), inherited, and all it does is emit action_pressed. The
## sledgehammer extends XRToolsPickable and so answers `true` to has_method
## while listening to nothing, which is how the first version of this ended up
## calling action() on a hammer, consuming the click, and firing a signal into
## an empty room. The probe caught it: "LMB starts a swing: true" while the head
## moved 0.00 m/s.
##
## The real question is whether anything is LISTENING. pink_gun connects to its
## pickable's action_pressed in _ready; the sledgehammer connects nothing,
## because its rule is speed, not a trigger.
func _fires(p: Node) -> bool:
	if p == null or not is_instance_valid(p) or not p.has_signal("action_pressed"):
		return false
	return not p.get_signal_connection_list("action_pressed").is_empty()


## A gun is FIRED; a hammer is SWUNG. line_sledgehammer inherits action() and
## listens to nothing: it breaks things by the speed of its own head, measured from
## global_position deltas in its _physics_process, and its docstring records a
## probe catching it destroying a barrier it was merely resting against. Giving
## it a "break()" entry point would be a second implementation of its one rule.
##
## So the swing lives HERE, in the hand, where a swing belongs. The pointer turns
## the holster through an arc; the head — 0.86 m out on the haft — reaches about
## 11 m/s at the strike (measured): over HEAD_SPEED_MIN (1.15) and well under
## HEAD_SPEED_MAX (45.0, above which the hammer reads a teleport and ignores the
## sample). The hammer needs no change and VR is untouched.
const SWING_TIME := 0.42     # long enough that the STRIKE is the fast part
const SWING_FROM_DEG := 52.0     # raised
const SWING_TO_DEG := -38.0      # driven down and through
var _swing_t: float = -1.0       # < 0 = not swinging


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


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not _raycast:
		return
	_swing_step(delta)

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
	# A FREED HELD THING IS CLEARED FIRST, WHATEVER KIND IT WAS. The stale-check
	# used to sit in an `elif` after the weapon branch, so a weapon that died
	# while held was never forgotten: _held stayed pointing at a corpse, _is_weapon
	# stayed true, and every later right-click ran _drop_held on nothing — the
	# hand locked shut and could never pick anything up again. Same shape as the
	# three freed-reference crashes fixed elsewhere today, reached by a different
	# door.
	if _held != null and not is_instance_valid(_held):
		_held = null
		if _is_weapon:
			_is_weapon = false
			_draw_weapon(_drawn_i)      # fall to the next live weapon, or empty
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
	# THE PRESS THAT ENABLES CAPTURE WAS ALWAYS EATEN (2026-09-02, Palle: "RMB
	# does not pick the gun up").
	#
	# The museum captures the mouse on the first mouse-button press
	# (endless_museum.gd: `if event is InputEventMouseButton and event.pressed:
	# Input.mouse_mode = MOUSE_MODE_CAPTURED`). Godot delivers _input BOTTOM-UP,
	# so this hand — a descendant of the walker — sees that press while the mode
	# is still VISIBLE, returned here, and the museum captured a frame later. The
	# click that turns looking on is therefore never a click at anything, and in
	# edit mode, where RMB release sets VISIBLE again, EVERY right-click arrived
	# uncaptured and the grab never fired once.
	#
	# Motion still needs the guard — a free cursor must not drag sliders across
	# the room. A BUTTON does not: if the player clicked in the 3D view, they
	# meant to click something in it.
	if event is InputEventMouseButton:
		pass
	elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
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
			else:
				# SAY WHY NOTHING HAPPENED. "RMB does not pick the gun up" cost a
				# round trip of guessing; a reach that finds nothing should name
				# what it looked with, so the next report is a fact. Only on the
				# miss — a working grab stays silent.
				print("[desktop-grab] nothing under the crosshair on layers 3/18/19"
					+ " within %.1f m (camera %s, mouse_mode %d)"
					% [distance, "ok" if _camera != null else "MISSING",
						Input.mouse_mode])
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and (
			event.button_index == MOUSE_BUTTON_WHEEL_UP
			or event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		var up: bool = event.button_index == MOUSE_BUTTON_WHEEL_UP
		# THE WHEEL MEANS TWO THINGS, AND NEITHER NEEDED A NEW KEY. Armed, it
		# switches weapons (which is where a Half-Life hand reaches anyway);
		# carrying a plain object, it pushes that object nearer or further. The
		# two can never be wanted at once, because you cannot hold both.
		if _arsenal.size() > 1 and _is_weapon:
			_draw_weapon(_drawn_i + (1 if up else -1))
			get_viewport().set_input_as_handled()
		elif _held:
			_hold_distance = clampf(_hold_distance + (-0.25 if up else 0.25), 1.0, 5.0)


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
		if _held == null or not is_instance_valid(_held):
			return false
		# A gun is fired. A hammer, which nothing listens to, is SWUNG.
		if not _fires(_held):
			if _is_weapon and _swing_t < 0.0:
				_swing_t = 0.0
				return true
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


## Draw the i-th weapon, wrapping. Anything freed since it was taken is forgotten
## first — a weapon can be destroyed while stowed, and a list of the dead is the
## bug this session has now fixed three times in other files.
func _draw_weapon(i: int) -> void:
	var live: Array[Node3D] = []
	for w in _arsenal:
		if is_instance_valid(w):
			live.append(w)
	_arsenal = live
	if _arsenal.is_empty():
		_drawn_i = -1
		_held = null
		_is_weapon = false
		return
	_drawn_i = wrapi(i, 0, _arsenal.size())
	_held = _arsenal[_drawn_i]
	_is_weapon = true
	_swing_t = -1.0                       # a switch cancels a swing in progress
	if _holster != null and is_instance_valid(_holster):
		_holster.rotation = Vector3.ZERO
	_held.transform = Transform3D(Basis.IDENTITY, weapon_offset)
	_show_only_drawn()


## Stowed = disabled and hidden. See the note on _arsenal: a stowed sledgehammer
## that keeps processing keeps striking, because its rule is the speed of its own
## head and the holster is moving whenever you are.
func _show_only_drawn() -> void:
	for j in range(_arsenal.size()):
		var w: Node3D = _arsenal[j]
		if not is_instance_valid(w):
			continue
		var drawn: bool = (j == _drawn_i)
		w.visible = drawn
		w.process_mode = Node.PROCESS_MODE_INHERIT if drawn else Node.PROCESS_MODE_DISABLED


## Turn the holster through the swing arc. The weapon rides it as a child, so the
## hammer's own head moves through the world and its own _physics_process
## measures the speed — nothing here tells it what it hit, or that it hit
## anything. That is deliberate: the hammer already owns the rule that speed
## breaks things, including the part where a shape SWEEP is used because a fast
## head steps over a thin plank between frames.
func _swing_step(delta: float) -> void:
	if _swing_t < 0.0:
		return
	if _holster == null or not is_instance_valid(_holster):
		_swing_t = -1.0
		return
	_swing_t += delta
	var u: float = clampf(_swing_t / SWING_TIME, 0.0, 1.0)

	# WIND UP, STRIKE, RECOVER — and START AND END AT REST.
	#
	# The first version went straight to SWING_FROM on frame one and snapped back
	# to zero on the last, and the probe measured the head at 42.56 m/s against
	# the hammer's 45.0 teleport cutoff: a 5% margin, and the peak was not the
	# swing at all — it was the two DISCONTINUITIES. The hammer would have struck
	# on the snap, breaking whatever stood in front the instant you clicked, and
	# one slow frame would have pushed it over 45 where every swing is silently
	# discarded. A number that close to a threshold is a bug wearing a pass.
	#
	# Three eased phases, continuous at both ends, so the fastest part of the
	# motion is the strike and nothing else moves fast at all. It lands at 5-14
	# m/s, which is what the hammer's own docstring measures a real VR swing at.
	var ang: float
	if u < 0.30:
		ang = lerpf(0.0, SWING_FROM_DEG, _ease(u / 0.30))
	elif u < 0.70:
		ang = lerpf(SWING_FROM_DEG, SWING_TO_DEG, _ease((u - 0.30) / 0.40))
	else:
		ang = lerpf(SWING_TO_DEG, 0.0, _ease((u - 0.70) / 0.30))
	_holster.rotation = Vector3(deg_to_rad(ang), 0.0, 0.0)
	if u >= 1.0:
		_swing_t = -1.0
		_holster.rotation = Vector3.ZERO


func _ease(t: float) -> float:
	var c: float = clampf(t, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)


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
	_is_weapon = _is_weapon_node(p)
	if not _is_weapon:
		return
	if not _arsenal.has(p):
		_arsenal.append(p)
	_drawn_i = _arsenal.find(p)
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
	_show_only_drawn()


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
		if _is_weapon:
			# It leaves the arsenal visible and running, whatever it was while
			# stowed — a weapon put down disabled would lie on the floor inert.
			_held.visible = true
			_held.process_mode = Node.PROCESS_MODE_INHERIT
			_arsenal.erase(_held)
	var was_weapon := _is_weapon
	_held = null
	_weapon_home = null
	_is_weapon = false
	# RMB PUTS DOWN ONE WEAPON, NOT THE WHOLE ARSENAL. Whatever else you were
	# carrying comes to hand instead of vanishing into a holster nobody can reach.
	if was_weapon and not _arsenal.is_empty():
		_draw_weapon(_drawn_i)
	elif was_weapon:
		_drawn_i = -1
