extends XRToolsPickable
const G = preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
var loom: Node3D
var card_id := 0
var bits: Array = []
var slot := -1
var desktop_held := false
var home := Vector3.ZERO
var paper: Node3D
var card_label: Label3D

func _init() -> void:
	freeze = true; freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4; collision_mask = 1

func _ready() -> void:
	paper = Node3D.new(); paper.scale=Vector3(1.45,1.6,1.0); add_child(paper)
	var shape := CollisionShape3D.new(); var b := BoxShape3D.new(); b.size = Vector3(.725,.32,.025)
	shape.shape = b; add_child(shape)
	card_label = G.label(self, "", Vector3(0, -.112, .012), 13)
	redraw()
	super()
	picked_up.connect(func(_object): _lift())
	dropped.connect(func(_object): call_deferred("_release"))
	action_pressed.connect(func(_object):
		if is_instance_valid(loom): loom.insert_next(self))

func redraw() -> void:
	if not is_instance_valid(paper): return
	G.clear(paper); G.card(paper, bits, G.material("d9b980"))
	card_label.text = "CARD %02d  •  12 HOOKS" % (card_id + 1)

func held() -> bool:
	return desktop_held or is_picked_up()

func _lift() -> void:
	if is_instance_valid(loom): loom.remove_card(self)

func _release() -> void:
	if is_instance_valid(loom) and not held(): loom.drop_card(self)

func on_desktop_grab(_pointer: Node) -> void:
	desktop_held = true; _lift()

func on_desktop_drop(_pointer: Node = null) -> void:
	desktop_held = false; call_deferred("_release")

func settle(pos: Vector3) -> void:
	position = pos; rotation = Vector3.ZERO
	linear_velocity = Vector3.ZERO; angular_velocity = Vector3.ZERO
	force_update_transform()
