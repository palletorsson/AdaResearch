## @identity
## name: Stretch Blob Room
## concept: Grab & stretch (native soft bodies)
## tier: large
## truth: take hold of it and it follows — a room-scale soft blob hung from four grabbable handles on
##        an overhead frame. Grab any handle and the whole blob sags and stretches toward it, the rest
##        drooping under its own weight. Native SoftBody3D, pinned at four points to handles you can
##        pull: the soft body big enough to lean into.
extends Node3D
class_name StretchBlobRoom

@export var emissive: bool = false
@export var blob_radius: float = 0.8
@export var blob_color: Color = Color(0.55, 0.45, 0.85)

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
	var r: float = blob_radius

	# Overhead frame — four posts and a top ring the handles hang from.
	var frame_y: float = 3.0
	var span: float = 1.6
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.18, 0.19, 0.22)
	fmat.roughness = 0.7
	fmat.metallic = 0.3
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var post := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.12, frame_y, 0.12)
			post.mesh = pm
			post.position = Vector3(sx * span, frame_y * 0.5, sz * span)
			post.material_override = fmat
			add_child(post)
	for axis in [0, 1]:
		var beam := MeshInstance3D.new()
		var bm := BoxMesh.new()
		if axis == 0:
			bm.size = Vector3(span * 2.0 + 0.12, 0.12, 0.12)
			beam.position = Vector3(0, frame_y, span)
		else:
			bm.size = Vector3(0.12, 0.12, span * 2.0 + 0.12)
			beam.position = Vector3(span, frame_y, 0)
		beam.mesh = bm
		beam.material_override = fmat
		add_child(beam)
		var beam2 := MeshInstance3D.new()
		beam2.mesh = bm
		if axis == 0:
			beam2.position = Vector3(0, frame_y, -span)
		else:
			beam2.position = Vector3(-span, frame_y, 0)
		beam2.material_override = fmat
		add_child(beam2)

	# The big soft blob, hanging so its top sits just below the frame.
	var blob_top: float = frame_y - 0.5
	var cy: float = blob_top - r
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 6.0, "stiffness": 0.25, "pressure": 0.0, "damping": 0.3,
		"precision": 5, "color": blob_color, "emissive": emissive,
	})
	sb.mesh = GSB.soft_sphere(r, 14, 18)
	sb.position = Vector3(0, cy, 0)
	add_child(sb)
	_sb = sb

	# Four grabbable handles on the upper hemisphere — pull one and the blob stretches toward it.
	var ax: float = r * 0.62
	var ay: float = r * 0.7
	var corners := [
		Vector3(ax, ay, ax), Vector3(-ax, ay, ax),
		Vector3(ax, ay, -ax), Vector3(-ax, ay, -ax),
	]
	for c in corners:
		var local: Vector3 = c
		var handle := GSB.add_handle(self, sb.to_global(local), 0.09, Color(0.95, 0.6, 0.3))
		_pins.append({"pos": local, "node": handle})

	add_child(_label("TAKE HOLD OF IT — IT FOLLOWS", Vector3(0, 3.6, 0)))
	call_deferred("_apply_pins")


func _apply_pins() -> void:
	if not is_instance_valid(_sb):
		return
	for p in _pins:
		GSB.pin_patch(_sb, p["pos"], p["node"], 0.2)


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 40
	l.pixel_size = 0.004
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.9, 0.92, 1.0)
	l.outline_size = 8
	return l
