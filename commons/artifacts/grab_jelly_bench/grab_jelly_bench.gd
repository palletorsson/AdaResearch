## @identity
## name: Grab Jelly Bench
## tier: medium
## truth: a real soft body, not a picture of one — grab a corner nub and the jelly stretches like
##        taffy, push your hand in and it dents, let go and it wobbles back. Native SoftBody3D, pinned
##        to grabbable handles: the soft body you can take hold of.
extends Node3D
class_name GrabJellyBench

@export var emissive: bool = false
@export var jelly_size: float = 0.5
@export var jelly_color: Color = Color(0.85, 0.35, 0.55)

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
	# Bench base.
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.1, 0.2, 0.8)
	base.mesh = bm
	base.position = Vector3(0, 0.75, 0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.16, 0.17, 0.2)
	bmat.roughness = 0.7
	base.material_override = bmat
	add_child(base)
	var pillar := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.25, 0.65, 0.25)
	pillar.mesh = pm
	pillar.position = Vector3(0, 0.42, 0)
	pillar.material_override = bmat
	add_child(pillar)

	# The soft jelly cube resting on the bench top (top at y=0.85).
	var s: float = jelly_size
	var cy: float = 0.85 + s * 0.5 + 0.02
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 2.0, "stiffness": 0.35, "pressure": 0.0, "damping": 0.25,
		"precision": 5, "color": jelly_color, "emissive": emissive,
	})
	sb.mesh = GSB.soft_box(s, 5)
	sb.position = Vector3(0, cy, 0)
	add_child(sb)
	_sb = sb

	# Pin the bottom face to the world so it sits on the bench.
	_pins.append({"pos": Vector3(0, -s * 0.5, 0), "node": null})
	# Four grabbable nubs on the top corners — grab to stretch.
	var h: float = s * 0.5
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var local := Vector3(sx * h, h, sz * h)
			var handle := GSB.add_handle(self, sb.to_global(local), 0.055,
				Color(0.95, 0.7, 0.25))
			_pins.append({"pos": local, "node": handle})

	add_child(_label("GRAB A CORNER — IT STRETCHES", Vector3(0, 1.7, 0)))
	# Pinning must happen after everything is in the tree.
	call_deferred("_apply_pins")


func _apply_pins() -> void:
	if not is_instance_valid(_sb):
		return
	for p in _pins:
		GSB.pin_patch(_sb, p["pos"], p["node"], 0.13)


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
