class_name InventoryPrism
extends Node3D
## THE INVENTORY PRISM - the web palette (ada_encyclopedia /catalyst-inventory, OpenBrushCatalystInventory.tsx)
## in VR (Palle, 2026-10-29: "build the prism in VR, retire the wrist panel"). A node of museum_rig.tscn, the
## one rig scene the museum and the Void both drive, so both have it; plain hands keep it (no bracelet).
##  - A four-faced prism floats upright over the LEFT hand while the left palm is up (a glance at a watch:
##    the controller's +X against UP past em_layout rig.palm_up); rig.prism_always true keeps it there.
##    Faces as on the web: HAND · KNOBS · TAPE · PLACED (inventory_face.gd). The active face turns to the eye;
##    the ◀ ▶ ears on every face turn it, as the web's frame swipe and Q/E do.
##  - The RIGHT hand is the wand: its pointer presses the faces as any switch; trigger lays tape from the worn
##    roll or makes the current item into that hand's own FunctionPickup - never while the pointer is on a
##    target (a switch, a handle, the prism); grip, while the prism is up, takes the last thing back (grip
##    alone stays the Void's grab). The web's size ring at the wand tip: a ring the tape's width when the tape
##    is in the hand.
## em_layout.json rig.inventory false switches it off. A grid map's bracelet keeps its own hand.

const HandLib = preload("res://commons/player/inventory_hand.gd")
const FaceScene = preload("res://commons/player/inventory_face.tscn")
const PanelViewport = preload("res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn")
const LAYOUT := "res://commons/data/em_layout.json"
const TAPES := "res://commons/artifacts/tape_roll/tapes.json"
const SIDE := 0.12          # a face's width, and the prism's
const TALL := 0.15          # a face's height
const LIFT := 0.14          # the prism's centre above the left hand

@export var palm_up := 0.55
@export var always := false

var enabled := true
var hand: Node = null
var left: XRController3D = null
var right: XRController3D = null
var prism: Node3D = null          # the turning body, upright in the world over the left hand
var faces: Array = []             # Viewport2Din3D, one per face
var uis: Array = []               # the inventory_face Controls inside them
var active := 0
var showing := false
var pinned := false              # the Void's left X: up until pressed again, whatever the palm does
var ring: MeshInstance3D = null
var _yaw := 0.0
var _worn_state: Array = []

func _ready() -> void:
	var cfg := _rig_config()
	enabled = bool(cfg.get("inventory", true))
	palm_up = clampf(float(cfg.get("palm_up", palm_up)), 0.1, 1.0)
	always = bool(cfg.get("prism_always", always))
	if not enabled:
		set_process(false);return
	left = get_parent().get_node_or_null("LeftHand") as XRController3D
	right = get_parent().get_node_or_null("RightHand") as XRController3D
	if left == null or right == null:
		set_process(false);return
	hand = HandLib.new();hand.name = "InventoryHand";add_child(hand)
	hand.item_changed.connect(func(_id):refresh_faces();_sync_worn())
	hand.config_changed.connect(func(_id, _cfg):refresh_faces())
	prism = Node3D.new();prism.name = "Prism";add_child(prism);prism.top_level = true
	var body := MeshInstance3D.new();body.name = "Body";var box := BoxMesh.new();box.size = Vector3(SIDE - .004, TALL - .004, SIDE - .004);body.mesh = box
	var bm := StandardMaterial3D.new();bm.albedo_color = Color("0b0f18");bm.roughness = .6;body.material_override = bm;prism.add_child(body)
	for i in 4:
		var vp: Node3D = PanelViewport.instantiate();vp.name = "Face%d" % i
		vp.set("scene", FaceScene);vp.set("screen_size", Vector2(SIDE, TALL));vp.set("viewport_size", Vector2(384, 480))
		vp.set("update_mode", 2);vp.set("throttle_fps", 10.0)   # UPDATE_THROTTLED: four faces on a Quest
		var turn := Basis(Vector3.UP, i * PI / 2)
		vp.transform = Transform3D(turn, turn * Vector3(0, 0, SIDE / 2))
		prism.add_child(vp);faces.append(vp)
	ring = MeshInstance3D.new();ring.name = "TipRing";var torus := TorusMesh.new();torus.inner_radius = .03;torus.outer_radius = .0375;torus.rings = 24;torus.ring_segments = 8;ring.mesh = torus
	var rm := StandardMaterial3D.new();rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;rm.albedo_color = Color("f43f5e", .7);rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;ring.material_override = rm
	ring.rotation.x = PI / 2;ring.position = Vector3(0, 0, -.03);right.add_child(ring);ring.hide()
	_set_showing(always)
	right.button_pressed.connect(_on_right_pressed)
	right.button_released.connect(_on_right_released)
	call_deferred("_bind_faces")

func _rig_config() -> Dictionary:
	if not FileAccess.file_exists(LAYOUT):return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT))
	if parsed is Dictionary and parsed.get("rig") is Dictionary:return parsed["rig"]
	return {}

## Each viewport makes its face a frame or two after entering the tree.
func _bind_faces() -> void:
	uis.resize(4)
	for i in 4:
		for k in 15:
			if not is_inside_tree():return
			var ui: Node = faces[i].get_scene_instance() if faces[i].has_method("get_scene_instance") else null
			if ui != null:
				uis[i] = ui;ui.setup(self, i);break
			await get_tree().process_frame

func refresh_faces() -> void:
	for ui in uis:
		if ui != null and is_instance_valid(ui) and ui.has_method("refresh"):ui.refresh()

# ── what the faces ask ───────────────────────────────────────────────────────────────────────────────────────

func turn(d: int) -> void:
	active = posmod(active + d, 4);refresh_faces()

func choose(id: String) -> void:
	hand.set_current(id)

func set_knob(key: String, value: Variant) -> void:
	hand.set_knob(key, value)

func set_tape_knob(key: String, value: Variant) -> void:
	hand.set_knob_for("tape", key, value)

func item_row(id: String) -> Dictionary:
	for it in hand.available():
		if it.id == id:return it
	return {}

func unlock_of(id: String) -> String:
	return str(hand.Items.item(id).get("unlock", ""))

func tape_designs() -> Array:
	var out: Array = []
	if not FileAccess.file_exists(TAPES):return out
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(TAPES))
	if not data is Dictionary or not data.get("tapes") is Dictionary:return out
	for id in data.tapes:
		var d: Dictionary = data.tapes[id]
		out.append({"id": str(id), "label": str(d.get("label", id)), "a": str(d.get("a", "cccccc")), "b": str(d.get("b", "888888"))})
	return out

## What is in the world: the things made (last on top) and the strips laid.
func placed_rows() -> Array:
	var rows: Array = []
	for n in hand.placed:
		if is_instance_valid(n):rows.append(str(n.name).trim_prefix("Held_").trim_prefix("Carrier_"))
	var roll: Node = hand.worn_of("tape")
	if roll != null:
		for s in roll.segments:
			if is_instance_valid(s):rows.append("tape %.2f m" % s.paid_length)
	return rows

func undo_last() -> void:
	var roll: Node = hand.worn_of("tape")
	if roll != null and roll.has_method("undo_last"):roll.undo_last()
	refresh_faces()

func take_back() -> void:
	var roll: Node = hand.worn_of("tape")
	var gone: Node = roll.undo_last() if roll != null and hand.current == "tape" and not roll.segments.is_empty() else hand.remove_last()
	if gone == null and roll != null:roll.undo_last()
	refresh_faces()

func take_all_back() -> void:
	while hand.remove_last() != null:pass
	var roll: Node = hand.worn_of("tape")
	if roll != null:roll.clear_tape()
	refresh_faces()

# ── the hands ────────────────────────────────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if left == null:return
	var up: float = left.global_basis.x.dot(Vector3.UP)
	var want: bool = always or pinned or up > (palm_up - 0.15 if showing else palm_up)
	if want != showing:_set_showing(want)
	_sync_worn()
	_place_prism(delta)
	var roll: Node = hand.worn_node()
	ring.visible = roll != null and showing
	if ring.visible:
		var w: float = roll._width() if roll.has_method("_width") else .075
		var torus: TorusMesh = ring.mesh;torus.outer_radius = w / 2;torus.inner_radius = maxf(w / 2 - .006, .004)

## Upright over the left hand, the active face turned to the eye.
func _place_prism(delta: float) -> void:
	if not showing:return
	var cam := get_viewport().get_camera_3d()
	var centre: Vector3 = left.global_position + Vector3.UP * LIFT
	var to_eye: Vector3 = (cam.global_position - centre) if cam != null else -left.global_basis.z
	to_eye.y = 0
	var want_yaw: float = (atan2(to_eye.x, to_eye.z) if to_eye.length() > .01 else _yaw) - active * PI / 2
	_yaw = lerp_angle(_yaw, want_yaw, minf(1.0, delta * 10.0))
	prism.global_transform = Transform3D(Basis(Vector3.UP, _yaw), centre)

## The Void's left X (Palle: "I do not get any menu from any button"): the prism up until X again.
func toggle() -> void:
	pinned = not pinned
	_set_showing(pinned)

func _set_showing(v: bool) -> void:
	showing = v
	if prism != null:prism.visible = v
	for vp in faces:vp.set("enabled", v)
	if v:refresh_faces()

func _sync_worn() -> void:
	var state: Array = [hand.current, right.get_instance_id()]
	if state == _worn_state:return
	_worn_state = state
	hand.sync_worn(right)

## The right pointer is on a switch, a handle or a face: the trigger is theirs.
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
				if made != null:
					refresh_faces()
					if right.has_method("trigger_haptic_pulse"):right.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.35, 0.0)
		"grip_click":
			if not showing:return
			take_back()
			if right.has_method("trigger_haptic_pulse"):right.trigger_haptic_pulse("haptic", 0.0, 0.06, 0.3, 0.0)

func _on_right_released(button_name: String) -> void:
	if hand == null or button_name != "trigger_click":return
	var worn: Node3D = hand.worn_node()
	if worn != null:
		worn.release_worn();refresh_faces()
