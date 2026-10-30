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
var ghost: Node3D = null          # the current prefab, translucent, where the trigger would put it
var ghost_ok := false
var aim_line: MeshInstance3D = null
var _ghost_key := ""
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

var hand_page := 0   # the HAND face flicks through pages of cards (Garry's Mod's spawn list)

func flick(d: int, pages: int) -> void:
	hand_page = posmod(hand_page + d, maxi(pages, 1));refresh_faces()

## The palette's own panel bodies, for a placement ray to look past.
func _panel_rids() -> Array:
	var out: Array = []
	for vp in faces:
		var b: Node = vp.get_node_or_null("StaticBody3D")
		if b != null:out.append(b.get_rid())
	return out

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
	_update_ghost()

## THE GHOST (Palle: "a ghost object that shows where a possible placement is, and a raycast line"): while the
## palette is up and a prefab is in the hand, a translucent copy stands where the trigger would put it - the
## item's own look when the place is good, red when it would be refused - with the aim line from the hand.
func _update_ghost() -> void:
	var placeable: bool = showing and hand.current != "" and hand.worn_node() == null and hand.current_tool() == ""
	if not placeable:
		if ghost != null:ghost.visible = false
		if aim_line != null:aim_line.visible = false
		return
	var key: String = hand.instance_key(hand.current)
	if ghost == null or key != _ghost_key:
		if ghost != null:ghost.queue_free();ghost = null
		ghost = _make_ghost();_ghost_key = key
		if ghost == null:return
	var at: Dictionary = hand.placement_at(right, 8.0, _panel_rids())
	var hit: Dictionary = at.hit
	if hit.is_empty():ghost.visible = false
	else:
		ghost.visible = true;ghost.global_transform = at.xform
		_tint(ghost, Color(1, .25, .3, .45) if not at.ok else Color(1, 1, 1, .45))
	ghost_ok = at.ok
	if aim_line == null:
		aim_line = MeshInstance3D.new();aim_line.name = "AimLine";aim_line.mesh = ImmediateMesh.new();add_child(aim_line);aim_line.top_level = true
		var lm := StandardMaterial3D.new();lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;lm.albedo_color = Color("f59e0b", .55);lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;aim_line.material_override = lm
	var to: Vector3 = hit.position if not hit.is_empty() else right.global_position - right.global_basis.z * 8.0
	aim_line.global_transform = Transform3D.IDENTITY
	var im: ImmediateMesh = aim_line.mesh;im.clear_surfaces();im.surface_begin(Mesh.PRIMITIVE_LINES);im.surface_add_vertex(right.global_position);im.surface_add_vertex(to);im.surface_end();aim_line.visible = true

## The ghost is the item's own scene, scaled as the carrier would, made inert and translucent.
func _make_ghost() -> Node3D:
	var it: Dictionary = hand.Items.item(hand.current)
	var path: String = hand.Items.scene_for(str(it.get("token", "")))
	if path == "" or not ResourceLoader.exists(path):return null
	var n: Node = (load(path) as PackedScene).instantiate()
	if not n is Node3D:n.free();return null
	var cfg: Dictionary = hand.config_for(hand.current)
	for k in cfg:n.set_meta("config_%s" % str(k), cfg[k])
	if n.has_method("apply_grid_config"):n.apply_grid_config(cfg)
	n.name = "Ghost_" + hand.current;add_child(n);(n as Node3D).top_level = true
	hand._make_inert(n)
	(n as Node3D).scale = Vector3.ONE * float(it.get("scale", 1.0))
	return n

static func _tint(root: Node, col: Color) -> void:
	var stack: Array = [root]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		for c in x.get_children():stack.append(c)
		if x is MeshInstance3D:
			var mi := x as MeshInstance3D
			if not mi.has_meta("ghost_mat"):
				# the thing's own colour, seen through: a shaded translucent copy of its first material's albedo
				var base := Color(.85, .85, .85)
				var src: Material = mi.get_active_material(0) if mi.mesh != null and mi.mesh.get_surface_count() > 0 else null
				if src is StandardMaterial3D:base = (src as StandardMaterial3D).albedo_color
				var m := StandardMaterial3D.new();m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;m.cull_mode = BaseMaterial3D.CULL_DISABLED;m.roughness = .7
				mi.material_override = m;mi.set_meta("ghost_mat", true);mi.set_meta("ghost_base", base)
			var base_col: Color = mi.get_meta("ghost_base")
			var tinted: Color = base_col.lerp(Color(col.r, col.g, col.b), 0.0 if col.is_equal_approx(Color(1, 1, 1, col.a)) else .75)
			(mi.material_override as StandardMaterial3D).albedo_color = Color(tinted.r, tinted.g, tinted.b, col.a)
		elif x is Label3D:(x as Label3D).modulate = col

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
			elif hand.current_tool() == "rubber":
				var gone: bool = hand.erase_at(right, 8.0, _panel_rids());refresh_faces()
				if right.has_method("trigger_haptic_pulse"):right.trigger_haptic_pulse("haptic", 0.0, 0.06 if gone else 0.15, 0.3 if gone else 0.6, 0.0)
			elif hand.current != "":
				# Garry's Mod: the thing appears where the wand points, settled by its own rule; pointing at nothing,
				# it comes into the hand instead (the kit's tower-in-hand way)
				var made: Node3D = hand.spawn_where_pointed(right, 8.0, _panel_rids())
				if made == null and hand.notice == "point at a floor or a wall":
					var pk: Node = XRToolsFunctionPickup.find_instance(right)
					if pk != null and is_instance_valid(pk.get("picked_up_object")):return   # the hand is full
					made = hand.spawn_in(right)
				refresh_faces()
				if right.has_method("trigger_haptic_pulse"):
					if made != null:right.trigger_haptic_pulse("haptic", 0.0, 0.08, 0.35, 0.0)
					else:right.trigger_haptic_pulse("haptic", 0.0, 0.15, 0.6, 0.0)   # a longer buzz: not here
		"grip_click":
			if not showing:return
			# the thing pointed at, if the hand placed it (Palle: "remove the object with the grip button"); else the last
			if hand.pointed_own(right, 8.0, _panel_rids()) != null:hand.erase_at(right, 8.0, _panel_rids());refresh_faces()
			else:take_back()
			if right.has_method("trigger_haptic_pulse"):right.trigger_haptic_pulse("haptic", 0.0, 0.06, 0.3, 0.0)

func _on_right_released(button_name: String) -> void:
	if hand == null or button_name != "trigger_click":return
	var worn: Node3D = hand.worn_node()
	if worn != null:
		worn.release_worn();refresh_faces()
