class_name InventoryWrist
extends Node3D
## THE INVENTORY ON THE PLAIN HAND (Palle, 2026-10-29: "the inventory on the plain hand, no bracelet"). The
## museum rig keeps plain hands - no bracelet, the wrist tools off - and the Void routes the buttons itself, so
## the bracelet's ITEMS tab can never be reached there. This node of museum_rig.tscn puts the inventory on the
## hand itself, in the museum and the Void alike:
##  - the ITEMS panel (the bracelet's own tabbed panel, ITEMS tab alone) sits on the LEFT wrist and shows when
##    the left palm turns up, a glance at a watch (the controller's +X against UP, em_layout rig.palm_up);
##    choose and turn knobs with the right pointer, as any switch;
##  - the current item is worn on or made in the RIGHT hand: trigger lays tape (the worn roll) or makes the
##    item in that hand - never while the right pointer is on a switch or the panel; grip, while the panel is
##    up, takes the last thing back (grip alone stays the Void's grab).
## em_layout.json rig.inventory false switches it off. A grid map's bracelet keeps its own hand; this one is
## the visitor's.

const HandLib = preload("res://commons/player/inventory_hand.gd")
const PanelViewport = preload("res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn")
const PanelUI = preload("res://commons/hazards/becoming_catalyst/tabbed_editor_panel.tscn")
const LAYOUT := "res://commons/data/em_layout.json"

@export var palm_up := 0.55          # the left palm's up-ness that shows the panel; 0.15 below it hides
@export var panel_size := Vector2(0.22, 0.22)

var enabled := true
var hand: Node = null                 # InventoryHand: the item, its knobs, the making and the wearing
var left: XRController3D = null
var right: XRController3D = null
var panel: Node3D = null              # Viewport2Din3D on the left wrist
var ui: Control = null                # the tabbed panel inside it
var showing := false
var _worn_state: Array = []

func _ready() -> void:
	var cfg := _rig_config()
	enabled = bool(cfg.get("inventory", true))
	palm_up = clampf(float(cfg.get("palm_up", palm_up)), 0.1, 1.0)
	if not enabled:
		set_process(false);return
	left = get_parent().get_node_or_null("LeftHand") as XRController3D
	right = get_parent().get_node_or_null("RightHand") as XRController3D
	if left == null or right == null:
		set_process(false);return
	hand = HandLib.new();hand.name = "InventoryHand";add_child(hand)
	hand.item_changed.connect(_on_item_changed)
	hand.config_changed.connect(func(_id, _cfg): _push())
	panel = PanelViewport.instantiate();panel.name = "InventoryPanelVP"
	panel.set("scene", PanelUI);panel.set("screen_size", panel_size);panel.set("viewport_size", Vector2(540, 540))
	# over the inside of the left wrist, tilted to the eye - the bracelet's own spot for it
	panel.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-45)), Vector3(0, 0.05, -0.11))
	left.add_child(panel)
	_set_showing(false)
	right.button_pressed.connect(_on_right_pressed)
	right.button_released.connect(_on_right_released)
	call_deferred("_bind_ui")

func _rig_config() -> Dictionary:
	if not FileAccess.file_exists(LAYOUT):return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	if parsed is Dictionary and parsed.get("rig") is Dictionary:return parsed["rig"]
	return {}

## The panel's scene is made by the viewport a frame or two after it enters the tree.
func _bind_ui() -> void:
	for i in 15:
		if not is_inside_tree():return
		await get_tree().process_frame
		ui = panel.get_scene_instance() if panel.has_method("get_scene_instance") else null
		if ui != null:break
	if ui == null:return
	if ui.has_method("set_active_tab"):ui.set_active_tab("ITEMS")
	# ITEMS alone: the tab row goes
	var tabs: Array = ui.get("_tab_buttons") if ui.get("_tab_buttons") is Array else []
	if not tabs.is_empty() and tabs[0] is Control:(tabs[0] as Control).get_parent().visible = false
	if ui.has_signal("item_selected") and not ui.item_selected.is_connected(_on_item_selected):ui.item_selected.connect(_on_item_selected)
	if ui.has_signal("item_knob_changed") and not ui.item_knob_changed.is_connected(_on_item_knob):ui.item_knob_changed.connect(_on_item_knob)
	_push()

func _push() -> void:
	if ui != null and is_instance_valid(ui) and ui.has_method("set_items"):ui.set_items(hand.available(), hand.current)

func _on_item_selected(id: String) -> void:
	hand.set_current(id)

func _on_item_knob(key: String, value: Variant) -> void:
	hand.set_knob(key, value)

func _on_item_changed(_id: String) -> void:
	_push();_sync_worn()

## The left palm up shows the panel, down hides it; the worn item follows the item and the hand.
func _process(_delta: float) -> void:
	if left == null:return
	var up: float = left.global_basis.x.dot(Vector3.UP)
	var want: bool = up > (palm_up - 0.15 if showing else palm_up)
	if want != showing:_set_showing(want)
	_sync_worn()

func _set_showing(v: bool) -> void:
	showing = v
	if panel != null:
		panel.visible = v;panel.set("enabled", v)
	if v:_push()

func _sync_worn() -> void:
	var state: Array = [hand.current, right.get_instance_id()]
	if state == _worn_state:return
	_worn_state = state
	hand.sync_worn(right)

## The right pointer is on a switch, a handle or the panel: the trigger is theirs.
func _pointing_at_something() -> bool:
	var p: Node = _right_pointer()
	return p != null and is_instance_valid(p.get("target"))

func _right_pointer() -> Node:
	var ch := right.find_children("FunctionPointer", "", true, false)
	return ch[0] if not ch.is_empty() else null

func _on_right_pressed(button_name: String) -> void:
	if hand == null:return
	match button_name:
		"trigger_click":
			if _pointing_at_something():return
			var worn: Node3D = hand.worn_node()
			if worn != null:
				worn.fire_worn()
			elif hand.current != "":
				var pk: Node = XRToolsFunctionPickup.find_instance(right)
				if pk != null and is_instance_valid(pk.get("picked_up_object")):return   # the hand is full
				var made: Node3D = hand.spawn_in(right)
				if made != null and right.has_method("trigger_haptic_pulse"):right.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.35, 0.0)
		"grip_click":
			if not showing:return   # grip alone is the Void's grab; with the panel up it takes back
			var worn: Node3D = hand.worn_node()
			var gone: Node3D = worn.undo_last() if worn != null and worn.has_method("undo_last") else hand.remove_last()
			if gone != null and right.has_method("trigger_haptic_pulse"):right.trigger_haptic_pulse("haptic", 0.0, 0.06, 0.3, 0.0)

func _on_right_released(button_name: String) -> void:
	if hand == null or button_name != "trigger_click":return
	var worn: Node3D = hand.worn_node()
	if worn != null:worn.release_worn()
