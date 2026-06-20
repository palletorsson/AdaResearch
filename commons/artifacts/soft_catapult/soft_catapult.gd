## @identity
## name: Soft Catapult
## concept: Bounce & pile (native soft bodies)
## tier: applied
## truth: a soft body stores the throw — a tabletop sling whose pocket is a stretchy membrane pinned
##        along its back edge to a frame. A ball rests in the sag of the pocket; pull it back and the
##        cloth loads like a drawn bow, storing the throw as elastic tension until it lets go. Native
##        SoftBody3D as the spring, with a live readout of how far the pocket has stretched.
extends Node3D
class_name SoftCatapult

@export var emissive: bool = false
@export var pocket_size: float = 0.6
@export var pocket_color: Color = Color(0.5, 0.8, 0.6)
@export var ball_radius: float = 0.11
@export var ball_color: Color = Color(0.95, 0.5, 0.35)

const GSB = preload("res://commons/soft_body/grab_soft_body.gd")

var _pocket: SoftBody3D
var _ball: SoftBody3D
var _readout: Label3D
var _pins: Array = []   # [{pos:Vector3, node:Node3D}]
var _rest_centre: Vector3 = Vector3.ZERO


func _ready() -> void:
	_build()
	set_process(true)     # this one runs: it samples pocket stretch for the readout


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_pins.clear()
	_pocket = null
	_ball = null
	_readout = null
	var s: float = pocket_size
	var half: float = s * 0.5
	var deck_y: float = 0.85
	var back_z: float = -half     # pocket pinned along its back (−Z) edge

	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.2, 0.16, 0.13)
	fmat.roughness = 0.6
	fmat.metallic = 0.2

	# A small table the sling sits on.
	var table := MeshInstance3D.new()
	var tbm := BoxMesh.new()
	tbm.size = Vector3(s + 0.4, 0.12, s + 0.5)
	table.mesh = tbm
	table.position = Vector3(0, deck_y - 0.06, 0)
	table.material_override = fmat
	add_child(table)

	# Back frame: two uprights + a top bar the pocket's back edge pins to.
	var bar_y: float = deck_y + s * 0.5
	for sx in [-1.0, 1.0]:
		var upright := MeshInstance3D.new()
		var um := BoxMesh.new()
		um.size = Vector3(0.07, s * 0.5 + 0.05, 0.07)
		upright.mesh = um
		upright.position = Vector3(sx * half, deck_y + (s * 0.5 + 0.05) * 0.5, back_z)
		upright.material_override = fmat
		add_child(upright)
	var bar := MeshInstance3D.new()
	var barm := BoxMesh.new()
	barm.size = Vector3(s + 0.14, 0.07, 0.07)
	bar.mesh = barm
	bar.position = Vector3(0, bar_y, back_z)
	bar.material_override = fmat
	add_child(bar)

	# The pocket: a subdivided sheet, tilted so its back edge is high (at the bar) and its front edge
	# dips toward the table → a sling that cradles the ball. Pinned ONLY along the back edge.
	var pocket := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 0.8, "stiffness": 0.45, "pressure": 0.0, "damping": 0.1,
		"precision": 5, "color": pocket_color, "emissive": emissive,
	})
	var pm := PlaneMesh.new()
	pm.size = Vector2(s, s)
	pm.subdivide_width = 12
	pm.subdivide_depth = 12
	pocket.mesh = pm
	# Position the pocket centre between the bar and the table, tilted back-up / front-down.
	var centre_y: float = deck_y + s * 0.25
	pocket.position = Vector3(0, centre_y, 0)
	pocket.rotation = Vector3(-0.5, 0, 0)   # tip the back edge up toward the bar
	add_child(pocket)
	_pocket = pocket
	_rest_centre = pocket.global_position

	# Pin the back-edge vertices (local −Z row) to the world, so the front pocket can swing/load.
	for sx in [-1.0, 0.0, 1.0]:
		_pins.append({"pos": Vector3(sx * half, 0.0, back_z), "node": null})

	# The ball resting in the pocket's sag.
	var br: float = ball_radius
	var ball := GSB.soft_setup(SoftBody3D.new(), {
		"mass": 1.0, "stiffness": 0.55, "pressure": 0.5, "damping": 0.15,
		"precision": 5, "color": ball_color, "emissive": emissive,
	})
	ball.mesh = GSB.soft_sphere(br, 12, 16)
	ball.position = Vector3(0, centre_y + br + 0.04, 0.05)
	add_child(ball)
	_ball = ball

	_readout = _label("LOADED: 0.00 m", Vector3(0, bar_y + 0.45, back_z))
	_readout.font_size = 30
	_readout.pixel_size = 0.0018
	add_child(_readout)
	add_child(_label("A SOFT BODY STORES THE THROW", Vector3(0, bar_y + 0.85, back_z)))

	call_deferred("_apply_pins")


func _apply_pins() -> void:
	if not is_instance_valid(_pocket):
		return
	for p in _pins:
		GSB.pin_patch(_pocket, p["pos"], p["node"], 0.12)


# Live readout: how far the pocket centre has stretched from its loaded rest (proxy for stored throw).
func _process(_delta: float) -> void:
	if not is_instance_valid(_pocket) or not is_instance_valid(_readout):
		return
	var drift: float = _pocket.global_position.distance_to(_rest_centre)
	_readout.text = "LOADED: %.2f m" % drift


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = 26
	l.pixel_size = 0.0015
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Color(0.9, 0.92, 1.0)
	l.outline_size = 6
	return l
