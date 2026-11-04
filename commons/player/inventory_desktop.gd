extends Node3D
## THE INVENTORY ON A DESKTOP: the Void's desktop walker has no hands, so this gives it the same hand and wand as
## the VR prism (inventory_hand.gd, inventory_wand.gd), aimed by the camera. Tab steps through the belt (the empty
## hand, then each collected prefab; Shift+Tab back - the belt shows a moment as a strip at the foot of the view), F
## places the prefab where the crosshair points, F held on a thing the hand placed drags it and letting go sets it
## down, X takes the pointed thing back, Q / E turn the ghost (Shift: a quarter turn). The miniature of the prefab in
## the hand stands at the lower right of the view, as it stands over the hand in VR.

const HandLib = preload("res://commons/player/inventory_hand.gd")
const WandLib = preload("res://commons/player/inventory_wand.gd")
const BeltLib = preload("res://commons/player/inventory_belt_view.gd")
const MINI_AT := Vector3(0.2, -0.11, -0.4)    # the miniature's holder in the camera's frame (above the avatar's shoulders, which fill the foot of the view)
const BELT_AT := Vector3(0, -0.09, -0.38)     # the belt's strip low in the view, over the avatar's shoulders
const TURN_STEP := 15.0                        # Q / E, degrees; with Shift a quarter turn

var game: Node = null
var camera: Camera3D = null
var hand: Node = null
var wand: Node3D = null
var belt: Node3D = null
var _holder: Node3D = null
var _f_down := false

func setup(p_game: Node, p_camera: Camera3D) -> void:
	game = p_game;camera = p_camera

func _ready() -> void:
	hand = HandLib.new();hand.name = "InventoryHand";add_child(hand);hand.add_to_group("inventory_hands")
	wand = WandLib.new();wand.name = "Wand";add_child(wand)
	if camera != null:
		wand.setup(hand, camera, _body_rids)
		_holder = Node3D.new();_holder.name = "MiniHolder";camera.add_child(_holder);_holder.position = MINI_AT
		belt = BeltLib.new();belt.name = "Belt";belt.setup(hand, camera, BELT_AT, .045, .028)
	hand.item_changed.connect(func(_id):_sync_mini();hand.yaw_offset = 0.0)   # a new thing in the hand faces you first
	hand.keep_in_void()   # in the Void's main tower what is built is kept and stood again

## The walker's own body is not a surface to place on.
func _body_rids() -> Array:
	var out: Array = []
	var body: Node = game.get("body") if game != null else null
	if body is CollisionObject3D:out.append((body as CollisionObject3D).get_rid())
	return out

func _sync_mini() -> void:
	if _holder == null:return
	var it: Dictionary = hand.Items.item(hand.current)
	hand._sync_mini(_holder if not it.is_empty() and str(it.get("mount", "")) != "worn" else null)

func _process(delta: float) -> void:
	if wand != null:wand.update(true, delta)

func _active() -> bool:
	return camera != null and is_inside_tree() and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo or not _active():return
	var k := event as InputEventKey
	match k.keycode:
		KEY_TAB:
			if not k.pressed:return
			if is_instance_valid(hand.lifted):hand.cancel_lift()
			var id: String = hand.cycle(-1 if k.shift_pressed else 1)
			_say("IN THE HAND / " + hand.name_of(id).to_upper() + ("" if id == "" else "\nF: place / hold F on it: move / X: take back"))
			get_viewport().set_input_as_handled()
		KEY_F:
			if k.pressed and not _f_down:
				_f_down = true
				var did: String = wand.press()
				_report(did)
				if did != "":get_viewport().set_input_as_handled()
			elif not k.pressed and _f_down:
				_f_down = false
				_report(wand.release())
		KEY_X:
			if not k.pressed:return
			if wand.grip():_say("TAKEN BACK");get_viewport().set_input_as_handled()
		KEY_Q, KEY_E:
			# THE TURN: Q turns the ghost (or a dragged thing) left, E right; Shift a quarter turn
			if not k.pressed or not wand.placing():return
			var step: float = (90.0 if k.shift_pressed else TURN_STEP) * (1.0 if k.keycode == KEY_Q else -1.0)
			hand.yaw_offset = wrapf(hand.yaw_offset + step, -180.0, 180.0)
			get_viewport().set_input_as_handled()

func _report(did: String) -> void:
	if did == "refused" and hand.notice != "":_say(hand.notice)

func _say(text: String) -> void:
	if game != null and game.has_method("_notice"):game._notice(text)
