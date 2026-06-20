## @identity
## name: Taffy Pull
## concept: Grab & stretch (native soft bodies)
## tier: applied
## truth: pinned at both ends, it stretches between your hands — a soft taffy rod held by two grabbable
##        handles about a metre apart. Pull the handles apart and the taffy necks and thins in the
##        middle; bring them together and it sags. A small readout reports the current span. Native
##        SoftBody3D, pinned at each end to a handle: a candy-puller you work with two hands.
extends Node3D
class_name TaffyPull

@export var emissive: bool = false
@export var span: float = 1.0                     # rest distance between the two handles (metres)
@export var taffy_thickness: float = 0.16
@export var taffy_color: Color = Color(0.95, 0.7, 0.45)

const GSB = preload("res://commons/soft_body/grab_soft_body.gd")

var _sb: SoftBody3D
var _pins: Array = []   # [{pos:Vector3, node:Node3D}]
var _handle_a: Node3D
var _handle_b: Node3D
var _readout: Label3D
var _rod_half: float = 0.5


func _ready() -> void:
	_build()
	# Keep processing ON here so the readout tracks the live distance between handles.
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
	var t: float = taffy_thickness
	var rod_len: float = span
	_rod_half = rod_len * 0.5
	var cy: float = 1.0                            # ~waist/chest height — a two-handed device

	# Two short pedestals under where the handles rest (just visual grounding).
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.16, 0.17, 0.2)
	pmat.roughness = 0.7
	for sx in [-1.0, 1.0]:
		var ped := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.18, cy - 0.25, 0.18)
		ped.mesh = pm
		ped.position = Vector3(sx * _rod_half, (cy - 0.25) * 0.5, 0)
		ped.material_override = pmat
		add_child(ped)

	# The soft taffy rod: a long box, finely subdivided along its length so it necks and stretches.
	var rod := BoxMesh.new()
	rod.size = Vector3(rod_len, t, t)
	rod.subdivide_width = 12                        # length axis — needs density to neck
	rod.subdivide_height = 2
	rod.subdivide_depth = 2
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 1.5, "stiffness": 0.2, "pressure": 0.0, "damping": 0.2,
		"precision": 5, "color": taffy_color, "emissive": emissive,
	})
	sb.mesh = rod
	sb.position = Vector3(0, cy, 0)
	add_child(sb)
	_sb = sb

	# A grabbable handle at each end — pull them apart and the taffy thins between them.
	_handle_a = GSB.add_handle(self, sb.to_global(Vector3(-_rod_half, 0, 0)), 0.07,
		Color(0.9, 0.5, 0.3))
	_handle_b = GSB.add_handle(self, sb.to_global(Vector3(_rod_half, 0, 0)), 0.07,
		Color(0.3, 0.6, 0.9))
	_pins.append({"pos": Vector3(-_rod_half, 0, 0), "node": _handle_a})
	_pins.append({"pos": Vector3(_rod_half, 0, 0), "node": _handle_b})

	add_child(_label("PINNED AT BOTH ENDS — STRETCH IT THIN", Vector3(0, cy + 0.5, 0), 22, 0.0013))
	_readout = _label("span %.2f m" % rod_len, Vector3(0, cy + 0.32, 0), 18, 0.0011)
	_readout.modulate = Color(0.7, 1.0, 0.8)
	add_child(_readout)

	call_deferred("_apply_pins")


func _apply_pins() -> void:
	if not is_instance_valid(_sb):
		return
	for p in _pins:
		GSB.pin_patch(_sb, p["pos"], p["node"], max(0.12, taffy_thickness))


func _process(_delta: float) -> void:
	# Live readout: actual distance between the two handles (the stretched span).
	if is_instance_valid(_handle_a) and is_instance_valid(_handle_b) and is_instance_valid(_readout):
		var d: float = _handle_a.global_position.distance_to(_handle_b.global_position)
		_readout.text = "span %.2f m" % d
		# Tint toward white as it is pulled past rest, redder as it slackens.
		var f: float = clamp((d - _rod_half * 2.0) / max(0.001, _rod_half), -1.0, 1.0)
		_readout.modulate = Color(0.7 + max(0.0, f) * 0.3, 1.0, 0.8 - max(0.0, -f) * 0.4)


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
