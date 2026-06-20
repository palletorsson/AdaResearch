## @identity
## name: Soft Handshake
## concept: Soft pets & membranes (native)
## tier: applied
## truth: shake hands with a soft body; it squeezes back. A soft mitt on a post, with a grabbable
##        handle pinned into its palm; take the handle, push and squeeze, and the whole paw gives and
##        deforms around your grip, springing back when you let go. A small readout reports how deep
##        you have pressed. Native SoftBody3D with rigid fingertip nubs that ride the soft palm.
extends Node3D
class_name SoftHandshake

@export var emissive: bool = false
@export var mitt_radius: float = 0.2
@export var mitt_color: Color = Color(0.95, 0.6, 0.55)

const GSB = preload("res://commons/soft_body/grab_soft_body.gd")

var _sb: SoftBody3D
var _pins: Array = []   # [{pos:Vector3, node:Node3D}]
var _handle: Node3D
var _readout: Label3D
var _handle_rest: Vector3 = Vector3.ZERO


func _ready() -> void:
	_build()
	# Keep processing ON so the readout tracks live squeeze depth (like taffy_pull's span readout).
	set_process(true)


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_pins.clear()
	var r: float = mitt_radius
	var palm_y: float = 1.0                          # ~waist/chest height — a greeting device

	# Post and small base under the mitt.
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.16, 0.17, 0.2)
	pmat.roughness = 0.7
	var base := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.18
	bm.bottom_radius = 0.22
	bm.height = 0.08
	base.mesh = bm
	base.position = Vector3(0, 0.04, 0)
	base.material_override = pmat
	add_child(base)
	var post := MeshInstance3D.new()
	var post_m := CylinderMesh.new()
	post_m.top_radius = 0.06
	post_m.bottom_radius = 0.07
	post_m.height = palm_y - r
	post.mesh = post_m
	post.position = Vector3(0, (palm_y - r) * 0.5, 0)
	post.material_override = pmat
	add_child(post)

	# The soft mitt: a dense sphere as the palm. Slightly squashed feel comes from the soft sim.
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 1.0, "stiffness": 0.3, "pressure": 0.0, "damping": 0.3,
		"precision": 5, "color": mitt_color, "emissive": emissive,
	})
	sb.mesh = GSB.soft_sphere(r, 12, 16)
	sb.position = Vector3(0, palm_y, 0)
	add_child(sb)
	_sb = sb

	# Anchor the BACK of the mitt (-Z, toward the post) to the world so it stays on the post
	# while the front palm gives. Pin only the back patch — front + sides stay soft.
	_pins.append({"pos": Vector3(0, 0, -r), "node": null})

	# A grabbable handle pinned into the PALM (front, +Z) — grab and squeeze; the paw deforms.
	var palm_local := Vector3(0, 0, r * 0.85)
	_handle = GSB.add_handle(self, sb.to_global(palm_local), 0.06, Color(0.95, 0.85, 0.4))
	_handle_rest = _handle.global_position
	_pins.append({"pos": palm_local, "node": _handle})

	# A few rigid fingertip nubs around the upper front of the palm (do NOT deform).
	# They ride along on the artifact; characterful "fingers" framing the grip.
	var finger_dirs := [
		Vector3(-0.7, 0.5, 0.6), Vector3(0.0, 0.75, 0.6), Vector3(0.7, 0.5, 0.6),
	]
	for d in finger_dirs:
		var dir: Vector3 = (d as Vector3).normalized()
		_add_finger(Vector3(0, palm_y, 0) + dir * r, r)

	add_child(_label("SHAKE HANDS — IT SQUEEZES BACK", Vector3(0, palm_y + 0.55, 0), 22, 0.0013))
	_readout = _label("squeeze 0.00 m", Vector3(0, palm_y + 0.36, 0), 18, 0.0011)
	_readout.modulate = Color(0.7, 1.0, 0.8)
	add_child(_readout)

	call_deferred("_apply_pins")


func _add_finger(pos: Vector3, r: float) -> void:
	var f := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = r * 0.16
	cm.height = r * 0.7
	cm.radial_segments = 8
	f.mesh = cm
	f.position = pos
	# Point the fingertip outward/forward.
	f.rotation = Vector3(deg_to_rad(60.0), 0.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.55, 0.5)
	mat.roughness = 0.5
	f.material_override = mat
	add_child(f)


func _apply_pins() -> void:
	if not is_instance_valid(_sb):
		return
	for p in _pins:
		GSB.pin_patch(_sb, p["pos"], p["node"], 0.13)
	# Record the handle's settled rest position for the squeeze readout baseline.
	if is_instance_valid(_handle):
		_handle_rest = _handle.global_position


func _process(_delta: float) -> void:
	# Live readout: how far the handle has been pushed in from its rest position = squeeze depth.
	if is_instance_valid(_handle) and is_instance_valid(_readout):
		var depth: float = _handle.global_position.distance_to(_handle_rest)
		_readout.text = "squeeze %.2f m" % depth
		# Green at rest -> warmer/whiter the harder you press.
		var f: float = clamp(depth / max(0.001, mitt_radius), 0.0, 1.0)
		_readout.modulate = Color(0.7 + f * 0.3, 1.0 - f * 0.2, 0.8 - f * 0.5)


func _label(text: String, pos: Vector3, font_size: int = 22, pixel: float = 0.0013) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = font_size
	l.pixel_size = pixel
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.9, 0.92, 1.0)
	l.outline_size = 6
	return l
