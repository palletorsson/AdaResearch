extends Node
## THE HAND THAT THROWS (2026-08-27, Palle: "yes wire the trigger, refill on
## entering a map, how do I shot in vr and in desktop?").
##
## THERE IS NO SINGLE INPUT MECHANISM IN THIS PROJECT and there cannot be one at
## the input layer: VR reads XRController3D.button_pressed with OpenXR action
## names, the grid desktop reads DesktopPlayer._input, and the museum reads its
## own _input. What all three CAN share is one verb, because the two things a
## throw needs — get_viewport().get_camera_3d() and get_tree().current_scene —
## are lane-blind. So this autoload owns the verb and each lane only has to
## reach it.
##
##   VR       trigger (either hand). A or X also fires, because the trigger is
##            XR-Tools' action button for a HELD object: while your hand has
##            something in it the trigger belongs to that thing, and this stands
##            aside rather than fighting it.
##   DESKTOP  F, or the middle mouse button. Left is taken by the pointer
##            (sliders, buttons, knobs) and right by the carry-grab, and taking
##            either would break an interaction somewhere in 2,800 maps.
##
## The count lives in GameManager beside the health, not here: a hand is
## per-lane — VR has two, the desktop has none — and the count is per-player.

const MUSHROOM := "res://commons/artifacts/spore_mushroom/spore_mushroom.tscn"
## the OpenXR action names that mean "throw", from openxr_action_map.tres
const VR_FIRE := ["trigger_click", "ax_button"]
const DESKTOP_KEYS := [KEY_F]

@export var throw_speed: float = 6.4
@export var throw_lift: float = 0.26      ## how much of an arc, as a fraction of forward
@export var cooldown: float = 0.42
@export var spawn_ahead: float = 0.32     ## metres in front of the eye or the hand
@export var show_desktop_count: bool = true

@export_group("VR hand")
## SOMETHING IN THE HAND (2026-08-27, Palle: "In VR if I have a mushroom let me
## hold one in the hand and a number how many"). A mushroom sits at the muzzle,
## pointing the way it will go, with the count beside it — so the aim is
## VISIBLE. That matters more than it sounds: a throw that goes somewhere
## unexpected is impossible to debug from inside a headset, and a held object
## that points where the throw goes turns a mystery into a glance.
@export var show_vr_hand: bool = true
@export var vr_hand_scale: float = 0.55
## WHICH WAY IS FORWARD. "hand" is the controller's own -Z, which is what the
## laser pointer and the gravity gun both use in this project. If a throw still
## goes behind you on your runtime, "flip" is the same axis reversed and "head"
## throws where you are looking instead of where you point.
@export_enum("hand", "flip", "head") var vr_aim: String = "hand"
@export var muzzle: float = 0.5           ## metres of flight before it may land

var _cool: float = 0.0
var _wired: Array = []          # controllers already connected
var _hud: CanvasLayer = null
var _hud_label: Label = null
var _scan: float = 0.0
var _key_down: bool = false
var _mmb_down: bool = false
var _hands: Array = []          # the holders parented to each controller


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_signal("mushrooms_updated"):
		gm.connect("mushrooms_updated", Callable(self, "_on_count"))


func _process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)
	_poll_desktop()
	# controllers arrive with the rig, which is not up when an autoload readies
	_scan += delta
	if _scan > 1.0:
		_scan = 0.0
		_wire_controllers()
		if show_desktop_count and _hud == null and not _in_vr():
			_build_hud()


## POLLED, NOT LISTENED FOR. _unhandled_input alone passed on a bench and
## FAILED in a real map: measured in Point_One through the project's own
## catalog, F and the middle mouse both did nothing, because an event only
## reaches _unhandled_input if nothing between the OS and here consumed it, and
## the desktop map catalog consumes its keys. Polling the device cannot be eaten
## by anybody. The listener below stays as well — it costs nothing and it is the
## path that fires on the same frame as the press.
func _poll_desktop() -> void:
	if _in_vr():
		return
	# a key press belongs to a text field while one has focus — the page editor
	# and the map switcher both put the visitor in one
	var vp := get_viewport()
	if vp != null:
		var focus := vp.gui_get_focus_owner()
		if focus is LineEdit or focus is TextEdit:
			_key_down = false
			_mmb_down = false
			return
	var k := false
	for code in DESKTOP_KEYS:
		if Input.is_physical_key_pressed(code):
			k = true
			break
	if k and not _key_down:
		fire_from_view()
	_key_down = k
	var m := Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
	if m and not _mmb_down:
		fire_from_view()
	_mmb_down = m


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var k := event as InputEventKey
		if k.pressed and not k.echo and k.keycode in DESKTOP_KEYS:
			fire_from_view()
	elif event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.pressed and m.button_index == MOUSE_BUTTON_MIDDLE:
			fire_from_view()


# ── the verb ────────────────────────────────────────────────────────────────

## Throw one from wherever the player is looking. Returns false when the hand is
## empty or still cooling, which is also what a caller wants to know.
func fire_from_view() -> bool:
	var cam: Camera3D = null
	var vp := get_viewport()
	if vp != null:
		cam = vp.get_camera_3d()
	if cam == null:
		return false
	var fwd: Vector3 = -cam.global_transform.basis.z
	return fire(cam.global_position + fwd * spawn_ahead, fwd)


## Throw one from a controller, down its own -Z — the same axis the XR-Tools
## pointer ray uses, so it goes where the hand points rather than where the
## head looks.
func fire_from_hand(controller: Node3D) -> bool:
	if controller == null or not is_instance_valid(controller):
		return false
	var fwd: Vector3 = _aim_of(controller)
	return fire(controller.global_position + fwd * spawn_ahead, fwd)


## the direction a hand throws, by whichever rule is set
func _aim_of(controller: Node3D) -> Vector3:
	match vr_aim:
		"flip":
			return controller.global_transform.basis.z
		"head":
			var vp := get_viewport()
			var cam: Camera3D = vp.get_camera_3d() if vp != null else null
			if cam != null:
				return -cam.global_transform.basis.z
	return -controller.global_transform.basis.z


func fire(from: Vector3, dir: Vector3) -> bool:
	if _cool > 0.0:
		return false
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("spend_mushroom"):
		if not bool(gm.call("spend_mushroom")):
			return false
	if not ResourceLoader.exists(MUSHROOM):
		push_warning("MushroomHand: no mushroom scene at %s" % MUSHROOM)
		return false
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var m: Node3D = (load(MUSHROOM) as PackedScene).instantiate() as Node3D
	# parented to the CURRENT SCENE, never to the hand: the catalyst learned
	# this — a projectile parented to a moving controller inherits its motion
	scene.add_child(m)
	# a throw is an arc, so the aim carries a little lift
	var aim: Vector3 = (dir.normalized() + Vector3.UP * throw_lift).normalized()
	m.call("launch", from, aim, throw_speed, muzzle)
	_cool = cooldown
	return true


# ── VR ──────────────────────────────────────────────────────────────────────

func _in_vr() -> bool:
	var xr := XRServer.find_interface("OpenXR")
	return xr != null and xr.is_initialized()


func _wire_controllers() -> void:
	var root := get_tree().root
	if root == null:
		return
	for n in root.find_children("*", "XRController3D", true, false):
		if _wired.has(n):
			continue
		if not (n as Node).has_signal("button_pressed"):
			continue
		(n as Node).connect("button_pressed", Callable(self, "_on_vr_button").bind(n))
		_wired.append(n)
		if show_vr_hand:
			_build_vr_hand(n as Node3D)
		print("[mushroom-hand] wired %s — trigger or A/X throws" % (n as Node).name)


func _on_vr_button(action: String, controller: Node) -> void:
	if not (action in VR_FIRE):
		return
	# WHILE YOUR HAND IS FULL THE TRIGGER IS NOT MINE. XR-Tools' FunctionPickup
	# forwards trigger_click to whatever is held, so a held tool would lose its
	# action button to this. A/X still throws either way.
	if action == "trigger_click" and _hand_is_full(controller):
		return
	fire_from_hand(controller as Node3D)


func _hand_is_full(controller: Node) -> bool:
	for p in (controller as Node).find_children("*", "", true, false):
		var held = p.get("picked_up_object")
		if held != null and is_instance_valid(held):
			return true
	return false


# ── the hand, in VR ─────────────────────────────────────────────────────────

## One mushroom held at the muzzle, pointing where a throw will go, with the
## count beside it. Built as a CHILD OF THE CONTROLLER so it needs no per-frame
## work at all — the hand carries it, and the aim it shows is the aim that fires
## because both come from the same transform.
func _build_vr_hand(controller: Node3D) -> void:
	if controller.get_node_or_null("MushroomInHand") != null:
		return
	var holder := Node3D.new()
	holder.name = "MushroomInHand"
	controller.add_child(holder)
	# at the muzzle, on the throwing axis — flip and head aims move it too, so
	# what you see is always what you get
	var fwd := Vector3(0, 0, -1) if vr_aim != "flip" else Vector3(0, 0, 1)
	holder.position = fwd * spawn_ahead + Vector3(0, -0.03, 0)

	if ResourceLoader.exists(MUSHROOM):
		var body: Node3D = (load(MUSHROOM) as PackedScene).instantiate() as Node3D
		body.name = "Held"
		# it stays in its HELD state: no arc, no floor, never bait
		holder.add_child(body)
		body.scale = Vector3.ONE * vr_hand_scale

	var l := Label3D.new()
	l.name = "Count"
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 96
	l.pixel_size = 0.0012
	l.modulate = Color(0.99, 0.80, 0.86)
	l.outline_size = 26
	l.outline_modulate = Color(0.10, 0.06, 0.09, 0.85)
	l.position = Vector3(0.0, 0.085, 0.0)
	holder.add_child(l)
	_hands.append(holder)
	_refresh_vr_hands()


func _refresh_vr_hands() -> void:
	var gm := get_node_or_null("/root/GameManager")
	var n: int = int(gm.get("mushrooms")) if gm != null else 0
	for h in _hands:
		if not is_instance_valid(h):
			continue
		var holder: Node3D = h
		var l := holder.get_node_or_null("Count") as Label3D
		if l != null:
			l.text = str(n)
		var body := holder.get_node_or_null("Held") as Node3D
		if body != null:
			# an empty hand holds nothing, and the number says zero
			body.visible = n > 0


# ── the count, on the desktop ───────────────────────────────────────────────

func _build_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 40
	var l := Label.new()
	# set_anchors_PRESET alone leaves a fresh Control at 0x0 painting nothing —
	# the offsets have to move with the anchors. This project has paid for that
	# one twice, most recently in the museum's hazard flash.
	l.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	l.position = Vector2(18, -42)
	l.size = Vector2(280, 26)
	l.add_theme_color_override("font_color", Color(0.96, 0.72, 0.80))
	l.add_theme_font_size_override("font_size", 15)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(l)
	add_child(_hud)
	_hud_label = l
	var gm := get_node_or_null("/root/GameManager")
	var n: int = int(gm.get("mushrooms")) if gm != null else 0
	var mx: int = int(gm.get("max_mushrooms")) if gm != null else 0
	_on_count(n, mx)


func _on_count(count: int, maximum: int) -> void:
	_refresh_vr_hands()
	if _hud_label == null or not is_instance_valid(_hud_label):
		return
	_hud_label.text = "mushrooms  %s%s   [F]" % [
		"•".repeat(maxi(0, count)), "·".repeat(maxi(0, maximum - count))]
