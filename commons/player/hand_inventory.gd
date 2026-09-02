extends Node
class_name HandInventory

## THE HAND INVENTORY (2026-08-29, Palle: "once we pick it up it should be added
## to a catalyst inventory and we should be able to flip between no-weapon,
## weapons or catalysts by pressing down on the joystick").
##
## A Node under the XROrigin3D in base.tscn, beside PickupXPListener, so every
## scene that inherits the rig carries it, and both hand strips (bare_hands and
## the museum's plain hands) leave it alone: it is none of the four wrist-tool
## names they remove.
##
## THREE STATES PER HAND, on that hand's thumbstick click — the OpenXR action
## primary_click, bound to thumbstick/click on every profile and claimed by
## nothing else on this rig: bare -> weapons -> catalysts -> bare, skipping any
## state the inventory cannot fill.
##
## THE GUN IS ADOPTED ON FIRST GRAB. godot-xr-tools 4.5.1 never reparents a held
## pickable: it stays a child of its original parent, driven from there by a
## RemoteTransform3D sibling. In the museum the gun stands in a hall SEGMENT,
## and the segment is freed at the next hall crossing — with the gun still in
## the visitor's hand, leaving the FunctionPickup holding a dead reference and
## the collision hand wearing phantom shapes. So on has_picked_up of a pink gun
## the inventory drops it, moves it under its own holster (rig-owned, never
## freed), and hands it straight back to the same pickup. Stowed = out of the
## tree: no physics, no draw, fire() refuses. Drawn = back in the tree and
## re-given to the hand. Letting go of the gun holsters it, so a released gun
## never hangs in a hall as a frozen body in the air.
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
signal gun_adopted(gun: Node3D)

const STATES: Array[String] = ["bare", "weapons", "catalysts"]
const CATALYST_SCENE := "res://commons/hazards/becoming_catalyst/becoming_catalyst.tscn"

@export var enabled: bool = true
@export var click_action: String = "primary_click"

var _pickups: Dictionary = {}        # "left"/"right" -> XRToolsFunctionPickup
var _controllers: Dictionary = {}    # "left"/"right" -> XRController3D
var _state: Dictionary = {"left": "bare", "right": "bare"}
var _gun: Node3D = null              # the adopted gun; may be out of the tree
var _gun_hand: String = ""           # the hand holding it, "" when stowed
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

func get_state(hand: String) -> String:
	return String(_state.get(hand, "bare"))


func has_gun() -> bool:
	return _gun != null and is_instance_valid(_gun)


func has_catalyst() -> bool:
	return _has_catalyst


func get_gun() -> Node3D:
	return _gun if has_gun() else null


static func is_gun(node: Node) -> bool:
	if node == null:
		return false
	if node.has_meta("artifact_lookup_name") and str(node.get_meta("artifact_lookup_name")) == "pink_gun":
		return true
	return node.get_node_or_null("PinkGun") != null


# ── the grab: adoption ───────────────────────────────────────────────────

func _on_picked_up(what: Node, hand: String) -> void:
	if not enabled or _busy:
		return
	if not (what is Node3D) or not is_gun(what):
		return
	if what == _gun:
		# our own gun, taken from the holster's parked spot or the other hand
		_gun_hand = hand
		_set_state(hand, "weapons")
		return
	call_deferred("_adopt", what, hand)


func _adopt(gun: Node3D, hand: String) -> void:
	if not is_instance_valid(gun) or not _pickups.has(hand):
		return
	var pk: XRToolsFunctionPickup = _pickups[hand]
	_busy = true
	pk.drop_object()
	var old: Node = gun.get_parent()
	if old != null:
		old.remove_child(gun)
	# the museum's own metas, which would have this body freed at the next hall
	for m in ["em_cartridge_deferred", "em_vr_content", "em_foe_gun"]:
		if gun.has_meta(m):
			gun.remove_meta(m)
	gun.set_meta("em_inventory", true)
	if "snap_to_shelf" in gun:
		gun.set("snap_to_shelf", false)   # grab_cube would drag it to any shelf point within a metre
	gun.set("freeze", true)
	_holster.add_child(gun)
	gun.set("enabled", true)
	pk._pick_up_object(gun)
	_busy = false
	var held: bool = bool(gun.call("is_picked_up")) if gun.has_method("is_picked_up") else false
	if not held:
		push_warning("[inventory] the gun was adopted but the hand did not take it back")
	if has_gun() and _gun != gun:
		_gun.queue_free()               # one gun in the inventory: the newest
	_gun = gun
	_gun_hand = hand if held else ""
	_set_state(hand, "weapons" if held else "bare")
	gun_adopted.emit(gun)
	print("[inventory] adopted the pink gun into the %s hand" % hand)


# ── letting go holsters ──────────────────────────────────────────────────

func _on_dropped(hand: String) -> void:
	if _busy or not has_gun():
		return
	if _gun_hand != hand:
		return
	var still: bool = bool(_gun.call("is_picked_up")) if _gun.has_method("is_picked_up") else false
	if still:
		return
	call_deferred("_stow")
	_set_state(hand, "bare")


# ── the flip ─────────────────────────────────────────────────────────────

func _on_button(button: String, hand: String) -> void:
	if not enabled or button != click_action:
		return
	cycle(hand)


## Advance one hand to the next state it can fill.
func cycle(hand: String) -> void:
	var i: int = STATES.find(get_state(hand))
	for k in range(1, STATES.size() + 1):
		var nxt: String = STATES[(i + k) % STATES.size()]
		if _available(nxt):
			set_hand_state(hand, nxt)
			return


func _available(s: String) -> bool:
	match s:
		"weapons":
			return has_gun()
		"catalysts":
			return _has_catalyst
		_:
			return true


func set_hand_state(hand: String, s: String) -> void:
	if not _controllers.has(hand):
		return
	var cur: String = get_state(hand)
	if cur == s:
		return
	# leave
	match cur:
		"weapons":
			if _gun_hand == hand:
				_stow()
		"catalysts":
			_catalyst_off()
	# enter
	match s:
		"weapons":
			if _gun_hand != "" and _gun_hand != hand:
				_stow()
				_set_state(_gun_hand if _gun_hand != "" else hand, "bare")
			_draw(hand)
		"catalysts":
			_catalyst_on(hand)
	_set_state(hand, s)


func _set_state(hand: String, s: String) -> void:
	if String(_state.get(hand, "")) == s:
		return
	_state[hand] = s
	print("[inventory] %s hand: %s" % [hand, s])
	state_changed.emit(hand, s)


# ── the gun in and out of the hand ───────────────────────────────────────

func _draw(hand: String) -> void:
	if not has_gun() or not _pickups.has(hand):
		return
	var pk: XRToolsFunctionPickup = _pickups[hand]
	_busy = true
	if _gun.get_parent() == null:
		_holster.add_child(_gun)
	_gun.set("enabled", true)
	_gun.set("freeze", true)
	pk._pick_up_object(_gun)
	_busy = false
	var held: bool = bool(_gun.call("is_picked_up")) if _gun.has_method("is_picked_up") else false
	_gun_hand = hand if held else ""
	if not held:
		push_warning("[inventory] the %s hand did not take the gun" % hand)


func _stow() -> void:
	if not has_gun():
		return
	_busy = true
	if _gun_hand != "" and _pickups.has(_gun_hand):
		var pk: XRToolsFunctionPickup = _pickups[_gun_hand]
		if pk.picked_up_object == _gun:
			pk.drop_object()
	var p: Node = _gun.get_parent()
	if p != null:
		p.remove_child(_gun)
	_busy = false
	_gun_hand = ""


# ── the catalyst on and off the hand ─────────────────────────────────────

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


func _catalyst_off() -> void:
	var mgr: Node = get_node_or_null("/root/CatalystCapabilityManager")
	if mgr != null and mgr.has_method("end_lease_now"):
		mgr.call("end_lease_now")
	# _has_catalyst stays: the visitor still owns it, the hand is just bare
