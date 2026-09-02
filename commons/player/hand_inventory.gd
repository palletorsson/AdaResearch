extends Node
class_name HandInventory

## THE HAND INVENTORY (2026-08-29, Palle: "once we pick it up it should be added
## to a catalyst inventory and we should be able to flip between no-weapon,
## weapons or catalysts by pressing down on the joystick" — and, the same day,
## "add the sledgehammer to the catalyst inventory").
##
## A Node under the XROrigin3D in base.tscn, beside PickupXPListener, so every
## scene that inherits the rig carries it, and both hand strips (bare_hands and
## the museum's plain hands) leave it alone: it is none of the four wrist-tool
## names they remove.
##
## SLOTS PER HAND, on that hand's thumbstick click — the OpenXR action
## primary_click, bound to thumbstick/click on every profile and claimed by
## nothing else on this rig: bare, then each weapon the inventory holds in the
## order it was taken, then catalysts if one is known, then bare again.
##
## A WEAPON IS ADOPTED ON FIRST GRAB. godot-xr-tools 4.5.1 never reparents a
## held pickable: it stays a child of its original parent, driven from there by
## a RemoteTransform3D sibling. In the museum a weapon hangs in a cabinet in a
## hall SEGMENT, and the segment is freed at the next hall crossing — with the
## weapon still in the visitor's hand, leaving the FunctionPickup holding a dead
## reference and the collision hand wearing phantom shapes. So on has_picked_up
## of a weapon the inventory drops it, moves it under its own holster (rig-owned,
## never freed), and hands it straight back to the same pickup. Stowed = out of
## the tree: no physics, no draw, a gun's fire() refuses. Drawn = back in the
## tree and re-given to the hand. Letting go of a weapon holsters it, so a
## released one never hangs in a hall as a frozen body in the air.
##
## CATALYSTS = the existing bracelet lane, entered the way CatalystCapabilityManager
## restores it after a scene change: a crystal auto-absorbed onto the controller,
## then spawn_bracelet_on_controller. The crystal's mode is set to "off" first, so
## its default voxel editor does not hunt for a grid the museum has not got.
## Leaving the state is end_lease_now, which dissolves both. The inventory
## remembers that it had a catalyst, because the manager's flag is a save file
## and the museum's plain hands clears it at boot.
##
## The desktop walker has no hands and no inventory.
## Probe: commons/testing/probe_hand_inventory.gd (a fake rig, no headset).

signal state_changed(hand: String, state: String)
signal weapon_adopted(weapon: Node3D)

const CATALYST_SCENE := "res://commons/hazards/becoming_catalyst/becoming_catalyst.tscn"
const WEAPON_TOKENS: Array[String] = ["pink_gun", "line_sledgehammer"]

@export var enabled: bool = true
@export var click_action: String = "primary_click"

var _pickups: Dictionary = {}        # "left"/"right" -> XRToolsFunctionPickup
var _controllers: Dictionary = {}    # "left"/"right" -> XRController3D
var _weapons: Array = []             # adopted weapons, in the order they were taken
var _drawn: Dictionary = {}          # hand -> the weapon in that hand
var _catalyst_hand: String = ""
var _has_catalyst: bool = false
var _holster: Node3D = null
var _busy: bool = false              # our own drops and grabs, not the visitor's


func _ready() -> void:
	_holster = Node3D.new()
	_holster.name = "Holster"
	add_child(_holster)
	# the manager's flag may be true from a saved game before the museum's plain
	# hands ends the bracelet at boot: remember it while it is still true
	var mgr: Node = get_node_or_null("/root/CatalystCapabilityManager")
	if mgr != null and mgr.has_method("is_bracelet_activated") and bool(mgr.call("is_bracelet_activated")):
		_has_catalyst = true
	call_deferred("_wire")


func _wire() -> void:
	for hand in ["left", "right"]:
		var ctrl: XRController3D = XRHelpers.get_left_controller(self) if hand == "left" else XRHelpers.get_right_controller(self)
		if ctrl == null:
			continue
		_controllers[hand] = ctrl
		ctrl.button_pressed.connect(_on_button.bind(hand))
		var pk: XRToolsFunctionPickup = XRToolsFunctionPickup.find_left(self) if hand == "left" else XRToolsFunctionPickup.find_right(self)
		if pk == null:
			# the addon's finder skips nodes with no owner — a rig built at runtime
			# (a probe's) has none — so walk the controller's descendants ourselves
			pk = _find_pickup(ctrl)
		if pk == null:
			continue
		_pickups[hand] = pk
		pk.has_picked_up.connect(_on_picked_up.bind(hand))
		pk.has_dropped.connect(_on_dropped.bind(hand))
	print("[inventory] wired %d controller(s), %d pickup(s); catalyst known: %s" % [
		_controllers.size(), _pickups.size(), str(_has_catalyst)])


static func _find_pickup(under: Node) -> XRToolsFunctionPickup:
	var stack: Array = [under]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is XRToolsFunctionPickup:
			return n as XRToolsFunctionPickup
		for c in n.get_children():
			stack.append(c)
	return null


# ── the public face ──────────────────────────────────────────────────────

## "bare", "weapons" or "catalysts".
func get_state(hand: String) -> String:
	if _drawn.has(hand) and is_instance_valid(_drawn[hand]):
		return "weapons"
	if _catalyst_hand == hand:
		return "catalysts"
	return "bare"


func get_weapon(hand: String) -> Node3D:
	return _drawn[hand] if _drawn.has(hand) and is_instance_valid(_drawn[hand]) else null


func get_weapons() -> Array:
	var out: Array = []
	for w in _weapons:
		if is_instance_valid(w):
			out.append(w)
	return out


func has_gun() -> bool:
	return not get_weapons().is_empty()


func has_catalyst() -> bool:
	return _has_catalyst


static func weapon_token(node: Node) -> String:
	if node == null:
		return ""
	if node.has_meta("artifact_lookup_name"):
		var tok := str(node.get_meta("artifact_lookup_name"))
		if WEAPON_TOKENS.has(tok):
			return tok
	if node.get_node_or_null("PinkGun") != null:
		return "pink_gun"
	if String(node.name).contains("Sledgehammer"):
		return "line_sledgehammer"
	return ""


static func is_weapon(node: Node) -> bool:
	return weapon_token(node) != ""


## The slots this hand cycles through, in order.
func slots() -> Array:
	var out: Array = ["bare"]
	for i in range(_weapons.size()):
		if is_instance_valid(_weapons[i]):
			out.append("weapon:%d" % i)
	if _has_catalyst:
		out.append("catalysts")
	return out


func current_slot(hand: String) -> String:
	if _drawn.has(hand) and is_instance_valid(_drawn[hand]):
		return "weapon:%d" % _weapons.find(_drawn[hand])
	if _catalyst_hand == hand:
		return "catalysts"
	return "bare"


# ── the grab: adoption ───────────────────────────────────────────────────

func _on_picked_up(what: Node, hand: String) -> void:
	if not enabled or _busy:
		return
	if not (what is Node3D) or not is_weapon(what):
		return
	if _weapons.has(what):
		# one of ours, taken from the other hand or straight from the holster
		for h in _drawn.keys():
			if _drawn[h] == what and h != hand:
				_drawn.erase(h)
				_set_state(h)
		_drawn[hand] = what
		_set_state(hand)
		return
	call_deferred("_adopt", what, hand)


func _adopt(w: Node3D, hand: String) -> void:
	if not is_instance_valid(w) or not _pickups.has(hand):
		return
	var pk: XRToolsFunctionPickup = _pickups[hand]
	_busy = true
	pk.drop_object()
	var old: Node = w.get_parent()
	if old != null:
		old.remove_child(w)
	# the museum's own metas, which would have this body freed at the next hall
	for m in ["em_cartridge_deferred", "em_vr_content", "em_foe_gun", "em_cabinet_weapon"]:
		if w.has_meta(m):
			w.remove_meta(m)
	w.set_meta("em_inventory", true)
	if "snap_to_shelf" in w:
		w.set("snap_to_shelf", false)   # grab_cube would drag it to any shelf point within a metre
	w.set("freeze", true)
	_holster.add_child(w)
	w.set("enabled", true)
	pk._pick_up_object(w)
	_busy = false
	var held: bool = bool(w.call("is_picked_up")) if w.has_method("is_picked_up") else false
	if not held:
		push_warning("[inventory] %s was adopted but the hand did not take it back" % weapon_token(w))
	_weapons.append(w)
	if _catalyst_hand == hand:
		_catalyst_off()
	if held:
		_drawn[hand] = w
	_set_state(hand)
	weapon_adopted.emit(w)
	print("[inventory] adopted %s into the %s hand (%d weapon(s))" % [weapon_token(w), hand, _weapons.size()])


# ── letting go holsters ──────────────────────────────────────────────────

func _on_dropped(hand: String) -> void:
	if _busy or not _drawn.has(hand):
		return
	var w: Node3D = _drawn[hand]
	if not is_instance_valid(w):
		_drawn.erase(hand)
		_set_state(hand)
		return
	var still: bool = bool(w.call("is_picked_up")) if w.has_method("is_picked_up") else false
	if still:
		return
	# deferred: let_go is still unwinding under this signal. _stow erases the
	# hand's record itself — erasing it here first left the weapon in the world
	# (the probe's "a released gun litters").
	call_deferred("_holster_after_drop", hand)


func _holster_after_drop(hand: String) -> void:
	_stow(hand)
	_set_state(hand)


# ── the flip ─────────────────────────────────────────────────────────────

func _on_button(button: String, hand: String) -> void:
	if not enabled or button != click_action:
		return
	cycle(hand)


## Advance one hand to the next slot.
func cycle(hand: String) -> void:
	var sl: Array = slots()
	if sl.size() <= 1:
		return
	var i: int = sl.find(current_slot(hand))
	var nxt: String = sl[(i + 1) % sl.size()]
	set_slot(hand, nxt)


func set_slot(hand: String, slot: String) -> void:
	if not _controllers.has(hand) or slot == current_slot(hand):
		return
	# leave
	if _drawn.has(hand):
		_stow(hand)
	if _catalyst_hand == hand:
		_catalyst_off()
	# enter
	if slot.begins_with("weapon:"):
		var i: int = int(slot.substr(7))
		if i >= 0 and i < _weapons.size() and is_instance_valid(_weapons[i]):
			var w: Node3D = _weapons[i]
			for h in _drawn.keys():
				if _drawn[h] == w and h != hand:
					_stow(h)
					_set_state(h)
			_draw(hand, w)
	elif slot == "catalysts":
		if _catalyst_hand != "" and _catalyst_hand != hand:
			_catalyst_off()
		_catalyst_on(hand)
	_set_state(hand)


func _set_state(hand: String) -> void:
	var s: String = get_state(hand)
	print("[inventory] %s hand: %s%s" % [hand, s, (" (" + weapon_token(_drawn[hand]) + ")") if s == "weapons" else ""])
	state_changed.emit(hand, s)


# ── a weapon in and out of a hand ────────────────────────────────────────

func _draw(hand: String, w: Node3D) -> void:
	if not is_instance_valid(w) or not _pickups.has(hand):
		return
	var pk: XRToolsFunctionPickup = _pickups[hand]
	_busy = true
	if w.get_parent() == null:
		_holster.add_child(w)
	w.set("enabled", true)
	w.set("freeze", true)
	pk._pick_up_object(w)
	_busy = false
	var held: bool = bool(w.call("is_picked_up")) if w.has_method("is_picked_up") else false
	if held:
		_drawn[hand] = w
	else:
		push_warning("[inventory] the %s hand did not take %s" % [hand, weapon_token(w)])


func _stow(hand: String) -> void:
	if not _drawn.has(hand):
		return
	var w: Node3D = _drawn[hand]
	_drawn.erase(hand)
	if not is_instance_valid(w):
		return
	_busy = true
	if _pickups.has(hand):
		var pk: XRToolsFunctionPickup = _pickups[hand]
		if pk.picked_up_object == w:
			pk.drop_object()
	var p: Node = w.get_parent()
	if p != null:
		p.remove_child(w)
	_busy = false


# ── the catalyst on and off a hand ───────────────────────────────────────

func _catalyst_on(hand: String) -> void:
	var mgr: Node = get_node_or_null("/root/CatalystCapabilityManager")
	if mgr == null or not _controllers.has(hand):
		return
	var ctrl: XRController3D = _controllers[hand]
	var have: bool = false
	for cat in get_tree().get_nodes_in_group("catalyst"):
		if cat.get_parent() == ctrl:
			have = true
			break
	if not have:
		var ps: PackedScene = load(CATALYST_SCENE) as PackedScene
		if ps == null:
			push_warning("[inventory] no catalyst scene")
			return
		var cat: Node = ps.instantiate()
		_holster.add_child(cat)             # in the tree first, so _ready runs
		if cat.has_method("apply_grid_config"):
			cat.call("apply_grid_config", {"active_mode": "off"})
		if cat.has_method("auto_absorb"):
			cat.call("auto_absorb", ctrl)
	if mgr.has_method("spawn_bracelet_on_controller"):
		mgr.call("spawn_bracelet_on_controller", ctrl)
	_has_catalyst = true
	_catalyst_hand = hand


func _catalyst_off() -> void:
	var mgr: Node = get_node_or_null("/root/CatalystCapabilityManager")
	if mgr != null and mgr.has_method("end_lease_now"):
		mgr.call("end_lease_now")
	_catalyst_hand = ""
	# _has_catalyst stays: the visitor still owns it, the hand is just bare
