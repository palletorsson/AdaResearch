extends Node3D
## THE WAND: placing, moving and taking back without holding anything (Palle, 2026-11-04: "this enables us not to
## hold the object while we place, giving us more freedom to interact, like in the example of the tape"). One
## driver for both ways in: the VR prism points with the right controller, the desktop with the camera. With a
## prefab in the hand (the belt: the left stick click, Tab on a desktop), a translucent ghost stands where it would
## go and the aim line runs to it; the trigger places it there. MOVE is a drag: the trigger HELD on a thing the hand
## placed (past HOLD) lifts it - it follows the aim as itself - and letting go sets it down there; a TAP on a placed
## thing still places onto it (a crate on a crate, a ball on a ball). The grip takes the pointed thing back. With the
## empty hand nothing is shown and the grip and trigger stay the world's, except that a placed thing can still be
## dragged.

var hand: Node = null            # InventoryHand
var aim: Node3D = null           # the right controller, or the desktop camera
var exclude: Callable = func(): return []   # RIDs the rays look past (the prism's panels)
var ghost: Node3D = null
var ghost_ok := false
var aim_line: MeshInstance3D = null
var _ghost_key := ""
const REACH := 8.0
const HOLD := 0.3                 # seconds: a press on a placed thing held this long lifts it; shorter is a tap
var _pending: Node3D = null       # the placed thing under a trigger pressed less than HOLD ago
var _pending_t := 0.0
var _dragging := false            # the lifted thing goes down when the trigger is let go
## THE NODE EDITOR (2026-11-06): with a kit element in the hand (ball, rod, brace) the trigger fires at the nodes of
## an edit space instead of placing a prefab on a surface (commons/player/kit_node_editor.gd).
var editor: Node3D = null
const KitTest = preload("res://commons/artifacts/playground_kit/kit_test.gd")

func setup(p_hand: Node, p_aim: Node3D, p_exclude: Callable = Callable()) -> void:
	hand = p_hand;aim = p_aim
	if p_exclude.is_valid():exclude = p_exclude
	if editor == null:
		editor = preload("res://commons/player/kit_node_editor.gd").new();editor.name = "KitNodeEditor";add_child(editor)
	editor.hand = hand

## Place mode: a thing to place is in the hand (not a worn roll, not a tool), or a thing is lifted.
func placing() -> bool:
	return hand != null and ((hand.current != "" and hand.worn_node() == null and hand.current_tool() == "") or is_instance_valid(hand.lifted))

## Called every frame by the owner. `show` false hides everything (the prism put away, the desktop pointer off).
func update(show := true, delta := 0.0) -> void:
	if hand == null or aim == null:return
	if _pending != null:
		_pending_t += delta
		if not is_instance_valid(_pending):_pending = null
		elif _pending_t >= HOLD:
			if hand.lift_pointed(aim, REACH, exclude.call()):_dragging = true
			_pending = null
	var lifting: bool = is_instance_valid(hand.lifted)
	if lifting:
		_hide_ghost()
		var at: Dictionary = hand.lifted_placement(aim, REACH, exclude.call())
		if bool(at.get("ok", false)) or bool(at.get("hang", false)):hand.lifted.global_transform = at.xform
		_draw_aim(at)
		return
	var se: Node = _space_editor()
	if se != null:
		_hide_ghost()
		if aim_line != null:aim_line.visible = false
		if editor != null:editor.hide_all()
		if show:se.space_update(aim, hand)
		else:se.space_hide()
		return
	if editor != null and editor.active() and not is_instance_valid(hand.lifted):
		_hide_ghost()
		if aim_line != null:aim_line.visible = false
		if show:editor.update(aim, exclude.call())
		else:editor.hide_all()
		return
	if editor != null:editor.hide_all()
	if not show or not placing():
		_hide_ghost()
		if aim_line != null:aim_line.visible = false
		return
	var key: String = hand.instance_key(hand.current)
	if ghost == null or key != _ghost_key:
		if ghost != null:ghost.queue_free();ghost = null
		ghost = _make_ghost();_ghost_key = key
		if ghost == null:return
	var at: Dictionary = hand.placement_at(aim, REACH, exclude.call())
	var hit: Dictionary = at.hit
	if hit.is_empty() and not bool(at.get("hang", false)):ghost.visible = false
	else:   # on the hit, or hanging in the air 2 m along the wand
		ghost.visible = true;ghost.global_transform = at.xform
		_tint(ghost, Color(1, .25, .3, .45) if not at.ok else Color(1, 1, 1, .45))
	ghost_ok = at.ok
	_draw_aim(at)

func _hide_ghost() -> void:
	if ghost != null:ghost.visible = false

func _draw_aim(at: Dictionary) -> void:
	if aim_line == null:
		aim_line = MeshInstance3D.new();aim_line.name = "AimLine";aim_line.mesh = ImmediateMesh.new();add_child(aim_line);aim_line.top_level = true
		var lm := StandardMaterial3D.new();lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED;lm.albedo_color = Color("f59e0b", .55);lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA;aim_line.material_override = lm
	var hit: Dictionary = at.get("hit", {})
	var to: Vector3 = hit.position if not hit.is_empty() else (at.point if bool(at.get("hang", false)) else aim.global_position - aim.global_basis.z * REACH)
	aim_line.global_transform = Transform3D.IDENTITY
	var from: Vector3 = aim.global_position + (-aim.global_basis.z * .25 if aim is Camera3D else Vector3.ZERO)   # a camera's line starts ahead of the eye, or it is a dot
	var im: ImmediateMesh = aim_line.mesh;im.clear_surfaces();im.surface_begin(Mesh.PRIMITIVE_LINES);im.surface_add_vertex(from);im.surface_add_vertex(to);im.surface_end();aim_line.visible = true

## THE TRIGGER PRESSED, in this order: a worn roll lays tape; a tool does its one thing; a lifted thing is set down;
## on a thing the hand placed the press waits (a tap places onto it at the release, a hold lifts it); otherwise a
## prefab in the hand is placed. Returns what happened ("" = nothing, the trigger is the world's): worn, rubber, pin,
## set_down, refused, pending, placed.
func press() -> String:
	if hand == null or aim == null:return ""
	var worn: Node3D = hand.worn_node()
	if worn != null:worn.fire_worn();return "worn"
	var se: Node = _space_editor()
	if se != null:
		var said_space: String = se.space_press(aim, hand)
		if str(se.get("space_notice")) != "":hand.notice = str(se.get("space_notice"))
		return said_space
	if hand.current_tool() == "rubber":return "rubber" if hand.erase_at(aim, REACH, exclude.call()) else "refused"
	if hand.current_tool() == "pin":return "pin" if hand.pin_at(aim, REACH, exclude.call()) != "" else "refused"
	if hand.current_tool() == "test":   # the load test (kit_test.gd): start or undo it on the pointed kit structure
		var did: String = KitTest.toggle_at(aim, REACH, exclude.call(), hand.SURFACES)
		hand.notice = {"started": "testing: what the bars do not hold is loose", "holds": "it holds: nothing moves", "reset": "back on the nodes", "": "point at a ball or rod of the kit"}[did]
		return "test_" + did if did != "" else "refused"
	if is_instance_valid(hand.lifted):_dragging = false;return "set_down" if hand.set_down(aim, REACH, exclude.call()) else "refused"
	if editor != null and editor.active():
		var said: String = editor.press(aim, exclude.call())
		if editor.notice != "":hand.notice = editor.notice
		return said
	var own: Node = hand.pointed_own(aim, REACH, exclude.call())
	if own is Node3D and own.get("paid_length") == null:
		_pending = own;_pending_t = 0.0;return "pending"
	return _place()

## THE TRIGGER LET GO: a drag sets its thing down; a tap on a placed thing places the prefab onto it. "" = nothing.
func release() -> String:
	if hand == null or aim == null:return ""
	if _dragging and is_instance_valid(hand.lifted):
		_dragging = false
		# refused (pointing at nothing for a wall thing): it stays lifted, and the next press sets it down
		return "set_down" if hand.set_down(aim, REACH, exclude.call()) else "refused"
	_dragging = false
	if _pending != null:
		_pending = null
		return _place()
	return ""

func _place() -> String:
	if hand.current == "" or hand.current_tool() != "":return ""
	var made: Node3D = hand.spawn_where_pointed(aim, REACH, exclude.call())
	return "placed" if made != null else "refused"

## THE GRIP: a lifted thing, or the thing pointed at if the hand placed it, is taken back. False when it was not
## the hand's to take: the grip is then the world's (the Void's grab).
func grip() -> bool:
	if hand == null or aim == null:return false
	_pending = null
	if is_instance_valid(hand.lifted):_dragging = false;hand.cancel_lift();return true
	var se: Node = _space_editor()
	if se != null and se.space_grip():return true
	if editor != null and editor.active() and editor.first != null:editor.first = null;return true   # a half-made rod let go
	if hand.pointed_own(aim, REACH, exclude.call()) == null:
		return editor != null and editor.grip()   # the node editor: pointing at no node clears the edit space
	return hand.erase_at(aim, REACH, exclude.call())

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

## THE SPACE EDITOR (2026-11-06): a scaffold workstation whose glass box is the editor (display.gd `space`) takes the
## aim while the line passes through its box - a kit piece in the hand fires at its sockets, the empty hand takes a
## piece back, the rubber erases (group space_editors, first come first served). Null when none claims the aim.
func _space_editor() -> Node:
	if hand == null or aim == null or is_instance_valid(hand.lifted):return null
	for n in get_tree().get_nodes_in_group("space_editors"):
		if n.has_method("space_active") and n.space_active(hand, aim):return n
	return null
