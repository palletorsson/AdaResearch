class_name InventoryPrism
extends Node3D
## THE INVENTORY PRISM - the web palette (ada_encyclopedia /catalyst-inventory, OpenBrushCatalystInventory.tsx)
## in VR (Palle, 2026-10-29: "build the prism in VR, retire the wrist panel"). A node of museum_rig.tscn, the
## one rig scene the museum and the Void both drive, so both have it; plain hands keep it (no bracelet).
##  - TILTED LIKE OPEN BRUSH (Palle, 2026-10-29: "read up on the principles"; Open Brush PanelManager.cs:
##    panels orbit the wand's FORWARD axis at a radius, oriented `wand.rotation * Euler(90,0,0)` - their up
##    along the controller, their face radially out - rolled in 120° snaps with a jiggle, haptics on each
##    step, a pane more than 70° off the gaze dropped). Here: a four-faced drum round the LEFT controller's
##    forward axis, 12 cm ahead of the hand, so the face on top tilts with the hand and reads when the
##    controller is held naturally; rolling the wrist shows the next face; the ◀ ▶ ears roll it in 90° snaps
##    (the Void owns the stick); the face the right pointer rests on lifts a centimetre. Shown while the left
##    palm is up (rig.palm_up), by left X (toggle), or always (rig.prism_always).
##    Faces as on the web: HAND · KNOBS · TAPE · PLACED (inventory_face.gd).
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
const SIDE := 0.12          # a face's width, and the drum's diameter
const TALL := 0.15          # a face's height, along the controller
const AHEAD := Vector3(0, 0.03, -0.12)   # the drum's centre on the controller: ahead along the aim, a little up
const HOVER_LIFT := 0.012   # the face the pointer rests on comes out this far (Tilt Brush: lifts and brightens)

@export var palm_up := 0.55
@export var always := false

var enabled := true
var hand: Node = null
var left: XRController3D = null
var right: XRController3D = null
var prism: Node3D = null          # the drum, a child of the left controller, rolled about its forward axis
var faces: Array = []             # Viewport2Din3D, one per face, round the drum
var face_rest: Array = []         # each face's resting transform on the drum
var uis: Array = []               # the inventory_face Controls inside them
var active := 0                   # the face on top (at the controller's +Y)
var showing := false
var pinned := false              # the Void's left X: up until pressed again, whatever the palm does
var ring: MeshInstance3D = null
var _roll := 0.0                  # the drum's roll about the forward axis, snapping to active * 90°
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
	# the drum on the left controller: its axis the controller's forward (-Z), the faces' up along it
	# no body: four flat panels in the air round the axis (Palle: "the whole interface should be 2d in 3d")
	prism = Node3D.new();prism.name = "Prism";left.add_child(prism);prism.position = AHEAD
	for i in 4:
		var vp: Node3D = PanelViewport.instantiate();vp.name = "Face%d" % i
		vp.set("scene", FaceScene);vp.set("screen_size", Vector2(SIDE, TALL));vp.set("viewport_size", Vector2(384, 480))
		vp.set("update_mode", 2);vp.set("throttle_fps", 10.0)   # UPDATE_THROTTLED: four faces on a Quest
		# a screen faces +Z with its top at +Y: laid on its back it faces +Y with its top along -Z (forward),
		# then rolled round the forward axis by the face's step - Open Brush's wand.rotation * Euler(90,0,0)
		var turn := Basis(Vector3.FORWARD, -i * PI / 2)
		vp.transform = Transform3D(turn * Basis(Vector3.RIGHT, -PI / 2), turn * Vector3(0, SIDE / 2, 0))
		prism.add_child(vp);faces.append(vp);face_rest.append(vp.transform)
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

## The ears roll the drum one face (Open Brush snaps 120° with a jiggle and a haptic tick; four faces, 90° here).
## The ears roll the drum one face (Open Brush snaps 120° with a jiggle and a haptic tick; four faces, 90° here).
func turn(d: int) -> void:
	active = posmod(active + d, 4);refresh_faces()
	if left != null and left.has_method("trigger_haptic_pulse"):left.trigger_haptic_pulse("haptic", 0.0, 0.05, 0.3, 0.0)
	if left != null and left.has_method("trigger_haptic_pulse"):left.trigger_haptic_pulse("haptic", 0.0, 0.05, 0.3, 0.0)

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
	_roll_drum(delta)
	var roll: Node = hand.worn_node()
	ring.visible = roll != null and showing
	if ring.visible:
		var w: float = roll._width() if roll.has_method("_width") else .075
		var torus: TorusMesh = ring.mesh;torus.outer_radius = w / 2;torus.inner_radius = maxf(w / 2 - .006, .004)

## The drum rolls about the controller's forward axis so the active face sits on top (at +Y), snapping fast
## as Open Brush does; the face the right pointer rests on lifts out a little.
func _roll_drum(delta: float) -> void:
	if not showing:return
	_roll = lerp_angle(_roll, active * PI / 2, minf(1.0, delta * 12.0))
	prism.transform = Transform3D(Basis(Vector3.FORWARD, _roll), AHEAD)
	var p: Node = _right_pointer();var over: Node = p.get("last_target") if p != null else null
	for i in 4:
		var vp: Node3D = faces[i];var rest: Transform3D = face_rest[i]
		var lifted: bool = over != null and is_instance_valid(over) and over.get_parent() == vp
		vp.transform = Transform3D(rest.basis, rest.origin + rest.basis.z * (HOVER_LIFT if lifted else 0.0))

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
