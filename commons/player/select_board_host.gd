extends Node3D
## THE BIG SELECT BOARD, SHOWN (2026-11-17; the board itself is commons/player/select_board.gd).
##   VR       a Viewport2Din3D 1.2 x 0.8 m (2000 x 1332 px for the board's 1000 x 666), opened DIST in front of the head
##            and a little under the eye, upright, facing the eye; nearer when a wall is closer. It stays where it was
##            opened until it is closed (a head-locked board makes people sick). Pressed with the right FunctionPointer,
##            as the prism's faces were; its body is on the pointer's layers only (21, 23), never layer 1, so nothing
##            lands on it and the wand's placement ray looks past it (body_rids). The left Y opens and closes it
##            (inventory_prism.gd toggle(), which the Void's game.gd calls on by_button, and the prism itself where no
##            game routes the button). Made by the prism (drum retired).
##   desktop  a 2D overlay over the view (a SubViewport drawn at the window's own pixels, the mouse free while it is
##            open and captured again after if it was before). I opens it on PREFABS (game.gd), V on BADGES (here: this
##            node hears V before badges_view.gd's _unhandled_input does), Esc closes, M closes it and lets the pause
##            open. Made by inventory_desktop.gd.
## The tab is remembered across a close (last_tab, static: also across a map).

const BoardScene := preload("res://commons/player/select_board.tscn")
const BoardLib := preload("res://commons/player/select_board.gd")
const PanelViewport := preload("res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn")
const SCREEN := Vector2(1.2, 0.8)    # metres
const PX := 2.0                      # VR pixels per board pixel
const DIST := 0.9                    # metres from the eye to the board
const NEAREST := 0.45                # never nearer than this, whatever stands in front
const DROP := 0.12                   # the board's middle this far under the eye
const LAYERS := (1 << 20) | (1 << 22)   # the pointer's (PlayerRules.POINTER_MASK, XR Tools' default mask); not layer 1
const OVERLAY_LAYER := 70            # desktop: over the badges overlay (60), under the pause (120)
const FILL := Vector2(.94, .9)       # desktop: at most this share of the window

static var last_tab := "hand"

var hand: Node = null
var prism: Node = null               # VR: the InventoryPrism that made it (showing = the board is open)
var vr := false
var board: Control = null
var viewport: Node3D = null          # VR: the Viewport2Din3D
var overlay: CanvasLayer = null      # desktop
var container: SubViewportContainer = null
var opened := false
var open_from := Vector3.ZERO        # the eye when it opened, for PLACE on the PREFABS tab
var open_dir := Vector3.FORWARD
var eye_override: Node3D = null      # a probe's head
var _mouse_before := Input.MOUSE_MODE_VISIBLE

func setup(p_hand: Node, p_prism: Node, p_vr: bool) -> void:
	hand = p_hand;prism = p_prism;vr = p_vr

func _ready() -> void:
	add_to_group("select_boards")

func _game() -> Node:
	return get_tree().get_first_node_in_group("void_game") if is_inside_tree() else null

func is_open() -> bool:
	return opened

func current_tab() -> String:
	return board.current if board != null else last_tab

## Open it (on `tab`, else where it was left); open on another tab, switch; open on its own tab (or "" ), close.
func toggle(tab := "") -> void:
	if opened and (tab == "" or (board != null and board.current == tab)):close()
	else:open(tab)

func open(tab := "") -> void:
	if not _ensure():return
	if not opened:
		opened = true
		var eye := _eye()
		if eye != null:open_from = eye.global_position;open_dir = -eye.global_basis.z
		if vr:
			_place_in_front(eye)
			viewport.visible = true;viewport.set("enabled", true)
		else:
			_mouse_before = Input.mouse_mode;Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_fit_overlay();overlay.visible = true
		if prism != null and prism.has_method("_set_showing"):prism._set_showing(true)   # the prism's "palette up": the grip takes the last thing back, the tip ring shows the tape
	board.open = true
	board.show_tab(tab if tab != "" else (board.current if board.current != "" else last_tab))
	board.refresh_all()

func close() -> void:
	if not opened:return
	opened = false
	if board != null:last_tab = board.current;board.open = false
	if vr and viewport != null:viewport.visible = false
	if overlay != null:
		overlay.visible = false
		if _mouse_before == Input.MOUSE_MODE_CAPTURED:Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if prism != null and prism.has_method("_set_showing"):prism._set_showing(false)

## The board's body, for a placement ray to look past.
func body_rids() -> Array:
	if viewport == null:return []
	var b: Node = viewport.get_node_or_null("StaticBody3D")
	return [b.get_rid()] if b is CollisionObject3D else []

# ── making it (on first open) ──────────────────────────────────────────────────────────────────────────────────

func _ensure() -> bool:
	if board != null and is_instance_valid(board):return true
	if hand == null:return false
	if vr:
		viewport = PanelViewport.instantiate();viewport.name = "BoardScreen"
		viewport.set("scene", BoardScene);viewport.set("screen_size", SCREEN);viewport.set("viewport_size", BoardLib.SIZE * PX)
		viewport.set("update_mode", 2);viewport.set("throttle_fps", 24.0)   # UPDATE_THROTTLED; a press or a change shows within 1/24 s
		viewport.set("input_keyboard", false);viewport.set("unshaded", true);viewport.set("transparent", 0)   # OPAQUE: no sorting against the world
		viewport.set("collision_layer", LAYERS)
		viewport.top_level = true;viewport.visible = false
		add_child(viewport)
		var sv: SubViewport = viewport.get_node("Viewport")
		sv.size_2d_override = Vector2i(BoardLib.SIZE);sv.size_2d_override_stretch = true   # laid out at 1000 x 666, drawn at 2000 x 1332
		board = viewport.get_scene_instance() as Control
	else:
		overlay = CanvasLayer.new();overlay.name = "BoardOverlay";overlay.layer = OVERLAY_LAYER;overlay.visible = false;add_child(overlay)
		var shade := ColorRect.new();shade.color = Color(0.02, 0.03, 0.05, .6);shade.mouse_filter = Control.MOUSE_FILTER_STOP;overlay.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		container = SubViewportContainer.new();container.name = "Board";container.stretch = true;overlay.add_child(container)
		var sv := SubViewport.new();sv.name = "Viewport";sv.disable_3d = true;sv.transparent_bg = false;sv.handle_input_locally = true
		sv.size_2d_override = Vector2i(BoardLib.SIZE);sv.size_2d_override_stretch = true   # laid out at 1000 x 666, drawn at the window's pixels
		container.add_child(sv)
		board = BoardScene.instantiate();sv.add_child(board)
		get_viewport().size_changed.connect(_fit_overlay)
	if board == null:return false
	board.setup(hand, _game(), vr)
	board.close_requested.connect(close)
	board.prefab_requested.connect(_on_prefab)
	board.discovery_requested.connect(_on_discovery)
	board.menu_requested.connect(_on_menu)
	board.current = last_tab
	return true

func _fit_overlay() -> void:
	if container == null:return
	var view := get_viewport().get_visible_rect().size
	var k := minf(view.x * FILL.x / BoardLib.SIZE.x, view.y * FILL.y / BoardLib.SIZE.y)
	container.size = (BoardLib.SIZE * k).round()
	container.position = ((view - container.size) * .5).round()

func _eye() -> Node3D:
	if eye_override != null and is_instance_valid(eye_override):return eye_override
	if vr and prism != null:
		var cam: Node = prism.get_parent().get_node_or_null("XRCamera3D") if prism.get_parent() != null else null
		if cam is Node3D:return cam
	return get_viewport().get_camera_3d()

## In front of the eye, level: DIST along the flat gaze (nearer if a wall is nearer), DROP under the eye, facing the eye.
func _place_in_front(eye: Node3D) -> void:
	if eye == null:return
	var from := eye.global_position
	var f := -eye.global_basis.z;f.y = 0.0
	if f.length() < .2:f = eye.global_basis.y if (-eye.global_basis.z).y < 0.0 else -eye.global_basis.y;f.y = 0.0   # looking straight down or up: the top of the head points the way
	if f.length() < .01:f = Vector3.FORWARD
	f = f.normalized()
	var d := DIST
	var q := PhysicsRayQueryParameters3D.create(from, from + f * (DIST + .15), 1)
	var hit := eye.get_world_3d().direct_space_state.intersect_ray(q)
	if not hit.is_empty():d = clampf(from.distance_to(hit.position) - .15, NEAREST, DIST)
	var centre := from + f * d + Vector3.DOWN * DROP
	viewport.global_transform = Transform3D(Basis(), centre).looking_at(from, Vector3.UP, true)

# ── the bracelet's editor panel (becoming_catalyst.gd) ───────────────────────────────────────────────────────

## The catalyst asks for its unified editor panel here instead of mounting it on the left wrist. The panel goes on the
## board's EDIT page; the catalyst gets a stand-in for the wrist viewport: get_scene_instance() is the panel (it wires every
## signal to it as before), and the visible it sets every frame (shown in an edit mode) shows or hides the EDIT tab.
## VR only (the catalyst's panel is a headset's). Null when there is no board to put it on.
func host_editor_panel(scene: PackedScene) -> Node3D:
	if not vr or scene == null or not _ensure():return null
	for old in get_children():   # a bracelet of an earlier map: its panel and stand-in go, the new one takes the page
		if old is EditorProxy:
			if is_instance_valid(old.ui):old.ui.get_parent().remove_child(old.ui);old.ui.queue_free()
			remove_child(old);old.queue_free()
	var ui: Control = scene.instantiate()
	var proxy := EditorProxy.new();proxy.name = "EditorPanelOnBoard";proxy.ui = ui;proxy.host = self;proxy.visible = false
	add_child(proxy)
	board.host_editor(ui)
	return proxy

class EditorProxy extends Node3D:
	var ui: Control = null
	var host: Node = null
	func get_scene_instance() -> Node:
		return ui
	func _notification(what: int) -> void:
		if what == NOTIFICATION_VISIBILITY_CHANGED and host != null and host.board != null:host.board.set_edit_available(visible)

# ── what the board asks ────────────────────────────────────────────────────────────────────────────────────────

func _on_prefab(id: String) -> void:
	var g := _game()
	close()
	if g == null or not g.has_method("place_inventory_prefab"):return
	await get_tree().physics_frame   # the board's collider is gone before the placing ray is cast
	var ib: Variant = g.get("inventory_board")
	if ib is Node:(ib as Node).set("placement_from", open_from);(ib as Node).set("placement_direction", open_dir)
	g.place_inventory_prefab(id)

func _on_discovery() -> void:
	var g := _game()
	close()
	var pause: Variant = g.get("discovery_pause") if g != null else null
	if pause is Node and pause.has_method("open"):pause.open()

func _on_menu() -> void:
	var g := _game()
	close()
	if g != null and g.has_method("return_to_menu"):g.return_to_menu()

# ── desktop keys ───────────────────────────────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if vr or not opened or not event is InputEventKey:return
	var k := event as InputEventKey
	if k.pressed and not k.echo and k.keycode == KEY_ESCAPE:
		close();get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if vr or not event is InputEventKey:return
	var k := event as InputEventKey
	if not k.pressed or k.echo or k.ctrl_pressed or k.alt_pressed or k.shift_pressed:return
	if k.keycode == KEY_V:
		toggle("badges");get_viewport().set_input_as_handled()
	elif k.keycode == KEY_M and opened:
		close()   # not handled: game.gd's M opens the pause/save over the world, not over the board
