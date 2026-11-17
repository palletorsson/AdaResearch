extends Node
## THE VERBS THE COINS GIVE (Palle, 2026-11-17, Trans_Pre: "instead of picking count we can pick, translate, rotate and
## scale"; then chosen: the verbs act on the things the player PLACES with the inventory wand, and they are LOCKED until
## their coin is collected - on floors 0-12 the player can only place and take back). Taking back (the grip, X) always
## works. PICK and ROTATE already existed and are gated where they happen (small hooks in inventory_hand.gd,
## inventory_desktop.gd and inventory_prism.gd call locked()); TRANSLATE and SCALE are new and live here:
##   desktop   G pushes the pointed placed thing (or the lifted one) STEP along the camera's horizontal forward,
##             snapped to the nearest world axis; Shift+G pulls it nearer. Z makes it GROW x bigger, Shift+Z smaller,
##             within SMALLEST..LARGEST of the size it was made at. It then settles by its own rules.
##   VR        while a thing is LIFTED (the trigger held on it), the right stick is the verbs': forward / back push and
##             pull it the same steps along the aim's axis, right / left grow and shrink it. The Void owns the sticks
##             for walking and turning, so they are taken (MovementDirect and MovementTurn of the right hand disabled)
##             only while something is lifted and a stick verb is collected, and given back the moment it is set down.
## The size: Godot resets a RigidBody3D's scale every physics step, so - as the carrier applies an item's own "scale"
## (inventory_carrier.gd build(): the work, its child, is scaled) - the WORK is scaled and the carrier refits its
## collider to it (_fit). The factor is the node's meta inv_scale; the kept row (placed.json) carries it as "scale".
## One node of this script per game (badge_layer.gd makes it); its static functions are what the hooks call.

const Badges := preload("res://commons/player/badges.gd")
const Collision := preload("res://commons/player/inventory_collision.gd")
const STEP := 0.05          # metres, one push or pull
const GROW := 1.1           # one Z: ten per cent
const SMALLEST := 0.5
const LARGEST := 2.0
const REACH := 8.0          # the wand's reach (inventory_wand.gd)
const STICK := 0.6          # the VR stick past this is a verb
const REPEAT := 0.25        # seconds between steps while the stick is held
const SAY_AGAIN_MS := 6000  # a locked verb says so once, then not again for this long

static var _said: Dictionary = {}
static var last_said := ""  # the last notice (a probe reads it when there is no game)

var desktop_inventory: Node = null    # a probe's; else the game's DesktopInventory
var prism: Node = null                # a probe's; else the game's XROrigin3D/InventoryPrism
var _taken: Array = []                # [weakref(provider), was_enabled]
var _held := ""                       # the stick's axis being held ("y" / "x")
var _repeat := 0.0
static var _nudged: Array = []        # weakrefs of lifted things carrying a badge_nudge

# -- THE GATE ----------------------------------------------------------------------------------------------------------

## True when the verb is still locked (its coin not collected). `say`: the game's notice says so, once in SAY_AGAIN_MS.
static func locked(verb: String, say := true) -> bool:
	if Badges.can(verb):return false
	if say:
		var now := Time.get_ticks_msec()
		if not _said.has(verb) or now - int(_said[verb]) >= SAY_AGAIN_MS:
			_said[verb] = now
			notice(Badges.locked_notice(verb))
	return true

static func notice(text: String) -> void:
	last_said = text
	var tree := Engine.get_main_loop() as SceneTree
	var game: Node = tree.get_first_node_in_group("void_game") if tree != null else null
	if game != null and game.has_method("_notice"):game._notice(text)
	else:print("[badges] ", text.replace("\n", " / "))

# -- WHAT THE VERBS ACT ON ---------------------------------------------------------------------------------------------

## The view's horizontal forward, snapped to the nearest world axis (+-X or +-Z).
static func axis(view: Node3D) -> Vector3:
	var f := -view.global_basis.z;f.y = 0.0
	if f.length() < .001:return Vector3.FORWARD
	return Vector3(signf(f.x), 0, 0) if absf(f.x) > absf(f.z) else Vector3(0, 0, signf(f.z))

static func _compass(d: Vector3) -> String:
	if absf(d.x) > absf(d.z):return "east" if d.x > 0 else "west"
	return "south" if d.z > 0 else "north"

## The lifted thing, else the placed thing the aim points at (not a tape strip). Null when the hand has none there.
static func target(hand: Node, aim: Node3D, exclude: Array = []) -> Node3D:
	if hand == null or aim == null:return null
	if is_instance_valid(hand.lifted):return hand.lifted
	var n: Node = hand.pointed_own(aim, REACH, exclude)
	if n is Node3D and n.get("paid_length") == null:return n
	return null

static func _is_kit(n: Node) -> bool:
	return n.is_in_group("playground_balls") or n.is_in_group("playground_rods")

## TRANSLATE: `step` added to where the thing is. A lifted thing keeps the step as an offset to where the wand puts it
## (meta badge_nudge, read by inventory_hand.lifted_placement); a placed one is moved and settles by its own rule - a
## grid block (the sand-block rule) steps a whole bench pitch, as its rule would pull a 5 cm push back to its point.
## Returns what happened: lifted, moved, kit, nothing.
static func translate(hand: Node, n: Node3D, step: Vector3) -> String:
	if n == null or not is_instance_valid(n):return "nothing"
	if _is_kit(n):return "kit"
	if hand != null and n == hand.lifted:
		n.set_meta("badge_nudge", Vector3(n.get_meta("badge_nudge", Vector3.ZERO)) + step)
		_nudged.append(weakref(n))
		return "lifted"
	var d := step
	if bool(n.get("snap_grid")) and str(n.get("how")) == "block" and n.get("pitch") is Vector2:
		var pitch: Vector2 = n.get("pitch")
		d = step.normalized() * pitch.x
	n.global_position += d
	_settle(n)
	return "moved"

## SCALE: GROW times bigger (or smaller), clamped to SMALLEST..LARGEST of the size it was made at. Returns scaled,
## limit (already at the end of the range), kit, nothing.
static func scale_by(hand: Node, n: Node3D, grow: bool) -> String:
	if n == null or not is_instance_valid(n):return "nothing"
	if _is_kit(n):return "kit"
	var now := float(n.get_meta("inv_scale", 1.0))
	var want := snappedf(clampf(now * GROW if grow else now / GROW, SMALLEST, LARGEST), .0001)
	if is_equal_approx(want, now):return "limit"
	var lifted: bool = hand != null and n == hand.lifted
	apply_scale(n, want, not lifted)
	if not lifted:_settle(n)
	return "scaled"

## The thing at `s` times the size it was made at. A carrier scales its WORK (the item's own scale times s) and refits
## its collider to what it now draws (inventory_carrier._fit - box, compound and own alike); any other placed body has its
## children scaled about its origin. `keep_bottom`: its lowest point stays where it was (it grows up, not into the floor).
static func apply_scale(n: Node3D, s: float, keep_bottom := true) -> bool:
	if n == null or not is_instance_valid(n):return false
	s = clampf(s, SMALLEST, LARGEST)
	var was := float(n.get_meta("inv_scale", 1.0))
	var low := _bottom(n) if keep_bottom else 0.0
	var work: Variant = n.get("work")
	if work is Node3D and n.has_method("_fit"):
		var item: Variant = n.get("item")
		var base := 1.0
		if item is Dictionary:
			var made: Dictionary = item
			base = float(made.get("scale", 1.0))
		if base <= 0.0:base = 1.0
		(work as Node3D).scale = Vector3.ONE * base * s
		n.call("_fit")
	else:
		var k := s / was
		for c in n.get_children():
			if c is Node3D:(c as Node3D).position *= k;(c as Node3D).scale *= k
	if is_equal_approx(s, 1.0):n.remove_meta("inv_scale")
	else:n.set_meta("inv_scale", s)
	if keep_bottom and n.is_inside_tree():n.global_position.y += low - _bottom(n)
	if n is RigidBody3D and n.is_inside_tree():
		PhysicsServer3D.body_set_state((n as RigidBody3D).get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, n.global_transform)
	return true

## The lowest point of what the thing draws, in the world.
static func _bottom(n: Node3D) -> float:
	var b: AABB = Collision.mesh_bounds(n, n)
	return (n.global_transform * b).position.y if n.is_inside_tree() else b.position.y

## After a push or a size: its physics state moved with it, then its own rule - pinned stays pinned where it now is,
## a carrier settles (falls, stands, snaps to its wall), any other body is woken.
static func _settle(n: Node3D) -> void:
	if n is RigidBody3D and n.is_inside_tree():
		PhysicsServer3D.body_set_state((n as RigidBody3D).get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, n.global_transform)
	if bool(n.get("pinned")) and n.has_method("pin"):n.pin()
	elif n.has_method("settle"):n.settle()
	if n is RigidBody3D and not (n as RigidBody3D).freeze:(n as RigidBody3D).sleeping = false

# -- THE DESKTOP KEYS --------------------------------------------------------------------------------------------------

func _ready() -> void:
	add_to_group("badge_verbs")

func _game() -> Node:
	return get_tree().get_first_node_in_group("void_game") if is_inside_tree() else null

func _desktop() -> Node:
	if is_instance_valid(desktop_inventory):return desktop_inventory
	var g := _game()
	return g.get_node_or_null("DesktopInventory") if g != null else null

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	var k := event as InputEventKey
	if k.keycode != KEY_G and k.keycode != KEY_Z or k.ctrl_pressed or k.alt_pressed or k.meta_pressed:return
	var inv := _desktop()
	if inv == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and desktop_inventory == null:return
	if desktop_key(inv, k.keycode, k.shift_pressed) != "":get_viewport().set_input_as_handled()

## One key on the desktop inventory: G (Shift: pull) or Z (Shift: smaller). "" = nothing pointed (the key is not taken).
func desktop_key(inv: Node, key: Key, shift: bool) -> String:
	var hand: Node = inv.get("hand");var wand: Node = inv.get("wand");var cam: Node3D = inv.get("camera")
	if hand == null or cam == null:return ""
	var exclude: Array = wand.exclude.call() if wand != null else []
	var n := target(hand, cam, exclude)
	if n == null:return ""
	if key == KEY_G:
		if locked("translate"):return "locked"
		var d := axis(cam) * (-STEP if shift else STEP)
		var did := translate(hand, n, d)
		if did == "kit":notice("TRANSLATE\nthe kit keeps its own nodes")
		else:notice("TRANSLATE / %s 5 cm %s" % ["pulled" if shift else "pushed", _compass(d)])
		return did
	if locked("scale"):return "locked"
	var did := scale_by(hand, n, not shift)
	if did == "kit":notice("SCALE\nthe kit keeps its own size")
	elif did == "limit":notice("SCALE / x%.2f - as %s as it goes" % [float(n.get_meta("inv_scale", 1.0)), "big" if not shift else "small"])
	else:notice("SCALE / x%.2f the size it was made at" % float(n.get_meta("inv_scale", 1.0)))
	return did

# -- THE VR STICK ------------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _nudged.is_empty():forget_set_down()
	_vr_stick(delta)

## A lift that ended (set down, or taken back) leaves no offset behind for the next lift of the same thing.
static func forget_set_down() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var lifted: Array = []
	if tree != null:
		for hand in tree.get_nodes_in_group("inventory_hands"):
			if is_instance_valid(hand.get("lifted")):lifted.append(hand.lifted)
	var keep: Array = []
	for ref in _nudged:
		var n: Object = (ref as WeakRef).get_ref()
		if n == null or not is_instance_valid(n):continue
		if n in lifted:keep.append(ref)
		elif n.has_meta("badge_nudge"):n.remove_meta("badge_nudge")
	_nudged = keep

var _prism_look := 0.0
func _prism() -> Node:
	if is_instance_valid(prism):return prism
	_prism_look -= get_process_delta_time()
	if _prism_look > 0.0:return null
	_prism_look = 1.0
	var g := _game()
	if g == null or not bool(g.get("vr")):return null
	prism = g.get_node_or_null("XROrigin3D/InventoryPrism")
	return prism

func _vr_stick(delta: float) -> void:
	var p := _prism()
	var hand: Node = p.get("hand") if p != null else null
	var right: XRController3D = p.get("right") if p != null else null
	if hand == null or right == null or not is_instance_valid(hand.lifted):
		give_back();_held = "";return
	var v := right.get_vector2("primary")
	var kind := "y" if absf(v.y) > STICK and absf(v.y) >= absf(v.x) else ("x" if absf(v.x) > STICK else "")
	if not (Badges.can("translate") or Badges.can("scale")):
		give_back()   # nothing to give the stick to: it keeps walking and turning
		if kind != "":locked("translate" if kind == "y" else "scale")
		return
	take(right)
	if kind == "":_held = "";return
	if kind != _held:_held = kind;_repeat = 0.0
	_repeat -= delta
	if _repeat > 0.0:return
	_repeat = REPEAT
	if kind == "y":
		if not locked("translate"):translate(hand, hand.lifted, axis(right) * signf(v.y) * STEP)
	elif not locked("scale"):
		scale_by(hand, hand.lifted, v.x > 0.0)

## The right stick is the verbs' while a thing is lifted: the right hand's walking and turning are switched off.
func take(right: Node) -> void:
	if not _taken.is_empty():return
	for provider_name in ["MovementDirect", "MovementTurn"]:
		var provider: Node = right.find_child(provider_name, true, false)
		if provider != null and provider.get("enabled") != null:
			_taken.append([weakref(provider), bool(provider.enabled)]);provider.enabled = false

## ... and given back exactly as they were.
func give_back() -> void:
	for row in _taken:
		var provider: Object = (row[0] as WeakRef).get_ref()
		if provider != null and is_instance_valid(provider):provider.set("enabled", row[1])
	_taken.clear()

func taken() -> bool:
	return not _taken.is_empty()

func _exit_tree() -> void:
	give_back()
