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

var _cool: float = 0.0
var _wired: Array = []          # controllers already connected
var _hud: CanvasLayer = null
var _hud_label: Label = null
var _scan: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_signal("mushrooms_updated"):
		gm.connect("mushrooms_updated", Callable(self, "_on_count"))


func _process(delta: float) -> void:
	_cool = maxf(0.0, _cool - delta)
	# controllers arrive with the rig, which is not up when an autoload readies
	_scan += delta
	if _scan > 1.0:
		_scan = 0.0
		_wire_controllers()
		if show_desktop_count and _hud == null and not _in_vr():
			_build_hud()


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
	var fwd: Vector3 = -controller.global_transform.basis.z
	return fire(controller.global_position + fwd * spawn_ahead, fwd)


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
	m.call("launch", from, aim, throw_speed)
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
	if _hud_label == null or not is_instance_valid(_hud_label):
		return
	_hud_label.text = "mushrooms  %s%s   [F]" % [
		"•".repeat(maxi(0, count)), "·".repeat(maxi(0, maximum - count))]
