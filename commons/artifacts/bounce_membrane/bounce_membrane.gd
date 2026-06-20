## @identity
## name: Bounce Membrane
## concept: Bounce & pile (native soft bodies)
## tier: medium
## truth: store the impact, give it back — a taut sheet strung at bench height between four posts,
##        pinned only at its corners. A heavier soft ball rests in the middle, dimpling the cloth into a
##        bowl; drop weight on it and the membrane stretches, stores the load, and flings it back. Native
##        SoftBody3D trampoline: the surface remembers the push.
extends Node3D
class_name BounceMembrane

@export var emissive: bool = false
@export var sheet_size: float = 1.1
@export var sheet_color: Color = Color(0.4, 0.7, 0.85)
@export var ball_radius: float = 0.17
@export var ball_color: Color = Color(0.95, 0.55, 0.3)

const GSB = preload("res://commons/soft_body/grab_soft_body.gd")

var _sheet: SoftBody3D
var _pins: Array = []   # [{pos:Vector3, node:Node3D}]


func _ready() -> void:
	_build()
	set_process(false)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_pins.clear()
	var s: float = sheet_size
	var deck_y: float = 0.85
	var half: float = s * 0.5

	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.17, 0.18, 0.22)
	fmat.roughness = 0.7
	fmat.metallic = 0.3

	# Four short corner posts holding the trampoline rim at bench height.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var post := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.1, deck_y, 0.1)
			post.mesh = pm
			post.position = Vector3(sx * half, deck_y * 0.5, sz * half)
			post.material_override = fmat
			add_child(post)
			# A small cap nub each post pins a sheet corner to (a static visual anchor at world rest).
			var cap := MeshInstance3D.new()
			var cm := BoxMesh.new()
			cm.size = Vector3(0.14, 0.06, 0.14)
			cap.mesh = cm
			cap.position = Vector3(sx * half, deck_y, sz * half)
			cap.material_override = fmat
			add_child(cap)

	# The trampoline: a subdivided horizontal PlaneMesh, pinned ONLY at its four corners (to the
	# world) so the centre is free to sag and rebound. PlaneMesh lies in the XZ plane already.
	var sheet := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 1.2, "stiffness": 0.35, "pressure": 0.0, "damping": 0.08,
		"precision": 5, "color": sheet_color, "emissive": emissive,
	})
	var pm2 := PlaneMesh.new()
	pm2.size = Vector2(s, s)
	pm2.subdivide_width = 14
	pm2.subdivide_depth = 14
	sheet.mesh = pm2
	sheet.position = Vector3(0, deck_y, 0)
	add_child(sheet)
	_sheet = sheet

	# Corner pins (PlaneMesh local coords: centred, in XZ). Pin only anchors — never the whole sheet.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_pins.append({"pos": Vector3(sx * half, 0.0, sz * half), "node": null})

	# A heavier soft ball resting in the middle, dimpling the cloth.
	var br: float = ball_radius
	var ball := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 3.0, "stiffness": 0.5, "pressure": 0.4, "damping": 0.15,
		"precision": 5, "color": ball_color, "emissive": emissive,
	})
	ball.mesh = GSB.soft_sphere(br, 12, 16)
	ball.position = Vector3(0, deck_y + br + 0.05, 0)   # just above the sheet → settles into a dimple
	add_child(ball)

	add_child(_label("STORE THE IMPACT, GIVE IT BACK", Vector3(0, 1.6, 0)))
	call_deferred("_apply_pins")


func _apply_pins() -> void:
	if not is_instance_valid(_sheet):
		return
	for p in _pins:
		GSB.pin_patch(_sheet, p["pos"], p["node"], 0.1)


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 28
	l.pixel_size = 0.0016
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.9, 0.92, 1.0)
	l.outline_size = 6
	return l
