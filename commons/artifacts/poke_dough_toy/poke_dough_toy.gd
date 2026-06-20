## @identity
## name: Poke Dough Toy
## concept: Poke & dent (native soft bodies)
## tier: small
## truth: press a finger in, leave a dent — a real soft body, not a picture of one. Native SoftBody3D,
##        low stiffness so your hand sinks in and the surface gives. Held at hand height, lightly
##        base-pinned so it stays near origin instead of falling away.
extends Node3D
class_name PokeDoughToy

@export var emissive: bool = false
@export var dough_radius: float = 0.175           # ~0.35 m across
@export var dough_color: Color = Color(0.92, 0.84, 0.66)
@export var stiffness: float = 0.18               # low = squishy dough

const GSB = preload("res://commons/soft_body/grab_soft_body.gd")

var _sb: SoftBody3D
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

	# The held dough ball, centred at hand height (~0.4 m). No bench — this is a SMALL held toy.
	var r: float = dough_radius
	var cy: float = 0.4
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 1.2, "stiffness": stiffness, "pressure": 0.0, "damping": 0.35,
		"precision": 5, "color": dough_color, "emissive": emissive,
	})
	sb.mesh = GSB.soft_sphere(r, 12, 16)
	sb.position = Vector3(0, cy, 0)
	add_child(sb)
	_sb = sb

	# Lightly base-pin the bottom cap to the world so the ball hovers near origin instead of
	# falling out of frame. Only the bottom verts are pinned — the rest stays soft and pokable.
	_pins.append({"pos": Vector3(0, -r, 0), "node": null})

	add_child(_label("PRESS A FINGER IN — LEAVE A DENT", Vector3(0, cy + r + 0.16, 0)))
	# Pinning must happen after the soft body is inside the tree.
	call_deferred("_apply_pins")


func _apply_pins() -> void:
	if not is_instance_valid(_sb):
		return
	for p in _pins:
		GSB.pin_patch(_sb, p["pos"], p["node"], 0.09)


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 24
	l.pixel_size = 0.0014
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.95, 0.92, 0.82)
	l.outline_size = 6
	return l
