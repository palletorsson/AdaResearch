## @identity
## name: Pressure Balloon
## concept: Poke & dent (native soft bodies)
## tier: medium
## truth: full of pressure, it pushes back — an over-pressurised soft body. Poke it and the skin dents
##        inward, then the internal pressure shoves it taut again and it bobs. Native SoftBody3D with a
##        positive pressure_coefficient (the balloon term) and low stiffness so it stays bouncy.
extends Node3D
class_name PressureBalloon

@export var emissive: bool = false
@export var balloon_radius: float = 0.26
@export var balloon_color: Color = Color(0.85, 0.28, 0.32)
@export var pressure: float = 0.35                # >0 inflates: pushes outward like a balloon
@export var stiffness: float = 0.25               # low = bouncy, but firm enough to stay taut on the knot

const GSB = preload("res://commons/soft_body/grab_soft_body.gd")

var _sb: SoftBody3D
var _knot: StaticBody3D
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

	# Bench base (MEDIUM tier: bench top at y=0.85, label up at y~1.6).
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 0.2, 0.8)
	base.mesh = bm
	base.position = Vector3(0, 0.75, 0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.16, 0.17, 0.2)
	bmat.roughness = 0.7
	base.material_override = bmat
	add_child(base)
	var pillar := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.22, 0.65, 0.22)
	pillar.mesh = pm
	pillar.position = Vector3(0, 0.42, 0)
	pillar.material_override = bmat
	add_child(pillar)

	# A little knot/stand on the bench top that the balloon ties to.
	var knot := StaticBody3D.new()       # a concrete anchor the balloon base pins to
	var knot_mesh := MeshInstance3D.new()
	var km := CylinderMesh.new()
	km.top_radius = 0.035
	km.bottom_radius = 0.055
	km.height = 0.1
	knot_mesh.mesh = km
	var kmat := StandardMaterial3D.new()
	kmat.albedo_color = Color(0.3, 0.05, 0.06)
	kmat.roughness = 0.6
	knot_mesh.material_override = kmat
	knot.add_child(knot_mesh)
	knot.position = Vector3(0, 0.85 + 0.05, 0)
	_knot = knot
	add_child(knot)

	# The over-pressurised balloon sitting just above the knot.
	var r: float = balloon_radius
	var knot_top: float = 0.85 + 0.1
	# Sink the balloon a little so its bottom tip overlaps the knot top — gives a small, solid cluster
	# of base verts inside the pin radius so the tether holds instead of the soft skin sliding off.
	var cy: float = knot_top + r - r * 0.18
	var sb := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 0.8, "stiffness": stiffness, "pressure": pressure, "damping": 0.18,
		"precision": 5, "color": balloon_color, "emissive": emissive,
	})
	sb.mesh = GSB.soft_sphere(r, 14, 18)
	sb.position = Vector3(0, cy, 0)
	add_child(sb)
	_sb = sb

	# Base-pin the bottom cap to the WORLD (immovable) so the pressurised balloon can't slosh off its
	# tether — a firm knot. The cap is held; everything above the knot stays soft and round: poke the
	# side, it dents, internal pressure pushes it back taut. (The knot mesh is the visible anchor.)
	_pins.append({"pos": Vector3(0, -r, 0), "node": null})

	add_child(_label("FULL OF PRESSURE — IT PUSHES BACK", Vector3(0, 1.6, 0)))
	call_deferred("_apply_pins")


func _apply_pins() -> void:
	if not is_instance_valid(_sb):
		return
	for p in _pins:
		# Moderate grip: anchor the bottom cap firmly enough to hold the balloon taut, small enough to
		# keep it round (not flattened into a disc) and leave the upper skin pokable.
		GSB.pin_patch(_sb, p["pos"], p["node"], balloon_radius * 0.55)


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 28
	l.pixel_size = 0.0016
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(1.0, 0.86, 0.86)
	l.outline_size = 6
	return l
