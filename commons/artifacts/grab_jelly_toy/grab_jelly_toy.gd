## @identity
## name: Grab Jelly Toy
## concept: Grab & stretch (native soft bodies)
## tier: small
## truth: the soft body you can take in your hand — a little jelly cube with two grabbable nubs on
##        opposite corners. Pull a nub and it stretches toward you; push your hand in and it dents;
##        let go and it wobbles back. Native SoftBody3D, held near the origin by one lightly pinned
##        face so it never falls away.
extends Node3D
class_name GrabJellyToy

@export var emissive: bool = false
@export var jelly_size: float = 0.35
@export var jelly_color: Color = Color(0.4, 0.8, 0.65)

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
	var s: float = jelly_size
	var h: float = s * 0.5

	# A small, soft jelly cube held near the origin (centre ~0.4m up so it sits in the hand).
	var cy: float = 0.4
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 0.6, "stiffness": 0.3, "pressure": 0.0, "damping": 0.25,
		"precision": 5, "color": jelly_color, "emissive": emissive,
	})
	sb.mesh = GSB.soft_box(s, 5)
	sb.position = Vector3(0, cy, 0)
	add_child(sb)
	_sb = sb

	# Rest-pin one face (the -Z face) lightly to the world so the toy stays near origin instead of
	# falling. A single anchor patch keeps it floating in place but still floppy everywhere else.
	_pins.append({"pos": Vector3(0, 0, -h), "node": null})

	# Two grabbable nubs on opposite corners — grab and the cube stretches toward your hand.
	var corner_a := Vector3(h, h, h)
	var corner_b := Vector3(-h, -h, h)
	var nub_a := GSB.add_handle(self, sb.to_global(corner_a), 0.045, Color(0.95, 0.75, 0.3))
	var nub_b := GSB.add_handle(self, sb.to_global(corner_b), 0.045, Color(0.3, 0.7, 0.95))
	_pins.append({"pos": corner_a, "node": nub_a})
	_pins.append({"pos": corner_b, "node": nub_b})

	add_child(_label("TAKE IT IN YOUR HAND — STRETCH", Vector3(0, 0.72, 0)))
	call_deferred("_apply_pins")


func _apply_pins() -> void:
	if not is_instance_valid(_sb):
		return
	for p in _pins:
		GSB.pin_patch(_sb, p["pos"], p["node"], 0.12)


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 24
	l.pixel_size = 0.0014
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.9, 0.92, 1.0)
	l.outline_size = 6
	return l
