extends "res://commons/primitives/point/drawing_pen.gd"
## Test-map adapter: the existing aligned pen receives charge at its visible tip.
signal charged_now
const DWELL := 0.25
const FIELD_RADIUS := 0.23
var charged := false
var charge_enabled := true
var dwell := 0.0
var field: Node3D
var home: Transform3D
var return_in := -1.0
var tip_glow: MeshInstance3D

func _ready() -> void:
	freeze = true
	release_mode = ReleaseMode.FROZEN
	ranged_grab_method = RangedMethod.NONE
	collision_layer = 4
	collision_mask = 196615
	pen_color = Color(0.12, 0.12, 0.12)
	super()
	# Lengthen the existing simple pen; its fixed grip and local -Z nib stay the same.
	get_node("Barrel").mesh.height = 0.44
	get_node("Barrel").position.z = -0.15
	get_node("Nib").position.z = -0.3875
	get_node("WritingTip").position.z = -0.405
	get_node("CollisionShape3D").shape.height = 0.47
	get_node("CollisionShape3D").position.z = -0.17
	tip_glow = load("res://commons/hazards/becoming_catalyst/first_catalyst_ability.gd").make_glow(0.045)
	get_node("WritingTip").add_child(tip_glow)
	tip_glow.hide()
	home = global_transform
	dropped.connect(func(_body): return_in = 2.0)

func held() -> bool:
	return super.is_drawing_ready()

func is_drawing_ready() -> bool:
	return charged and held()

func _process(delta: float) -> void:
	advance_charge(delta)
	if held(): return_in = -1.0
	elif return_in >= 0:
		return_in -= delta
		if return_in <= 0: global_transform = home

func advance_charge(delta: float) -> void:
	if charged: return
	if not charge_enabled or not held() or not is_instance_valid(field):
		dwell = 0.0
		return
	var inside: bool = get_node("WritingTip").global_position.distance_to(field.global_position) <= FIELD_RADIUS
	dwell = dwell + delta if inside else 0.0
	if dwell >= DWELL:
		charged = true
		tip_glow.show()
		charged_now.emit()

func reset_charge() -> void:
	charged = false
	dwell = 0.0
	tip_glow.hide()
	if not held(): global_transform = home
