extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RevolvingDoor

## @identity
## lineage: a brass-and-glass revolving door standing alone in a doorframe to nowhere —
##   no wall, no building, just the door. Press the shove button and a ghost hand pushes
##   it from a cycling angle: along the swing, at 45 degrees, straight at the axle.
## essence: the door can only USE the component of a push that points along its swing.
##   Full alignment spins it hard, 45 degrees spins it by cos(45) = 0.71, and a push
##   straight at the axle — however hard — does nothing at all. That selective deafness
##   IS the dot product: F·t = |F| cos θ.
## truth: alignment is a quantity, not a yes or no. The door meters agreement between
##   your intention and its one available motion, and pays out spin in proportion.
##
## The 2026-08-27 forces brief: "remove the abstract but keep the force under breath" —
## the one vector allowed here is a ghost arrow that shows the shove for a breath,
## then fades.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const BUTTON_SCENE := preload("res://commons/interactables/push_button.tscn")

@export var seed: int = 11
@export var leaf_w: float = 0.72       # leaf width, m — door diameter 1.44
@export var leaf_h: float = 2.05
@export var shove: float = 3.2         # ghost-hand impulse, rad/s at full alignment
## Angular drag per second. 0.55 lets a full shove carry ~2.5 turns before rest —
## enough to feel earned, short enough that the next press starts near stillness.
@export var damp: float = 0.55

# The three shove angles the button cycles through, degrees from the swing tangent.
const ANGLES := [0.0, 45.0, 90.0]

var _axle: Node3D
var _omega := 0.0
var _angle_idx := 0
var _ghost: Node3D
var _ghost_life := 0.0
var _readout: Node3D

func _ready() -> void:
	_rng.seed = seed
	_build_frame()
	_build_leaves()
	_build_button()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "shove", "damp"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	_omega *= exp(-damp * delta)
	_axle.rotation.y += _omega * delta
	if _ghost_life > 0.0:
		_ghost_life -= delta
		var mat := (_ghost.get_child(0) as MeshInstance3D).material_override as StandardMaterial3D
		mat.albedo_color.a = clamp(_ghost_life / 0.9, 0.0, 1.0) * 0.85
		if _ghost_life <= 0.0:
			_ghost.visible = false

# --- the door -----------------------------------------------------------------------

func _build_frame() -> void:
	# A free-standing arch: two jambs and a lintel, framing a door that leads to the
	# same room it came from. The surrealism is the missing building.
	var brass := _steel_mat(Color(0.55, 0.46, 0.28))
	for sx in [-1.0, 1.0]:
		var jamb := MeshInstance3D.new()
		var jamb_mesh := BoxMesh.new()
		jamb_mesh.size = Vector3(0.12, leaf_h + 0.3, 0.12)
		jamb.mesh = jamb_mesh
		jamb.position = Vector3(sx * (leaf_w + 0.14), (leaf_h + 0.3) * 0.5, 0.0)
		jamb.material_override = brass
		add_child(jamb)
	var lintel := MeshInstance3D.new()
	var lintel_mesh := BoxMesh.new()
	lintel_mesh.size = Vector3(leaf_w * 2.0 + 0.52, 0.14, 0.16)
	lintel.mesh = lintel_mesh
	lintel.position = Vector3(0.0, leaf_h + 0.37, 0.0)
	lintel.material_override = brass
	add_child(lintel)

	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = leaf_w + 0.18
	base_mesh.bottom_radius = leaf_w + 0.24
	base_mesh.height = 0.06
	base.mesh = base_mesh
	base.position = Vector3(0.0, 0.03, 0.0)
	base.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
	add_child(base)

func _build_leaves() -> void:
	_axle = Node3D.new()
	_axle.position = Vector3(0.0, 0.0, 0.0)
	add_child(_axle)
	var pole := MeshInstance3D.new()
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.035
	pole_mesh.bottom_radius = 0.035
	pole_mesh.height = leaf_h
	pole.mesh = pole_mesh
	pole.position = Vector3(0.0, leaf_h * 0.5 + 0.06, 0.0)
	pole.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	_axle.add_child(pole)
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.55, 0.75, 0.80, 0.22)
	glass.roughness = 0.05
	glass.metallic = 0.1
	for i in range(4):
		var leaf_mesh := BoxMesh.new()
		leaf_mesh.size = Vector3(leaf_w, leaf_h - 0.1, 0.024)
		# each leaf rides a carrier so it rotates about the AXLE, not its own centre
		var carrier := Node3D.new()
		carrier.rotation.y = PI * 0.5 * float(i)
		var inner := MeshInstance3D.new()
		inner.mesh = leaf_mesh
		inner.position = Vector3(leaf_w * 0.5, leaf_h * 0.5 + 0.06, 0.0)
		inner.material_override = glass
		carrier.add_child(inner)
		var stile := MeshInstance3D.new()
		var stile_mesh := BoxMesh.new()
		stile_mesh.size = Vector3(leaf_w, 0.05, 0.05)
		stile.mesh = stile_mesh
		stile.position = Vector3(leaf_w * 0.5, leaf_h + 0.01, 0.0)
		stile.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
		carrier.add_child(stile)
		_axle.add_child(carrier)

# --- the ghost shove ----------------------------------------------------------------

func _build_button() -> void:
	var btn := BUTTON_SCENE.instantiate()
	btn.position = Vector3(leaf_w + 0.75, 0.85, 0.55)
	btn.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	btn.set("pressed_color", Color(0.95, 0.60, 0.15))
	btn.set("released_color", Color(0.30, 0.75, 0.85))
	add_child(btn)
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.05
	stem_mesh.bottom_radius = 0.07
	stem_mesh.height = 0.8
	stem.mesh = stem_mesh
	stem.position = Vector3(leaf_w + 0.75, 0.4, 0.55)
	stem.material_override = _steel_mat(Color(0.35, 0.35, 0.38))
	add_child(stem)
	if btn.has_signal("pressed"):
		btn.connect("pressed", Callable(self, "_on_shove"))
	else:
		var inner := btn.get_node_or_null("InteractableAreaButton")
		if inner and inner.has_signal("button_pressed"):
			inner.connect("button_pressed", Callable(self, "_on_shove"))

	# The ghost arrow, built once, shown for a breath per shove.
	_ghost = Node3D.new()
	_ghost.visible = false
	add_child(_ghost)
	var shaft := MeshInstance3D.new()
	var shaft_mesh := BoxMesh.new()
	shaft_mesh.size = Vector3(0.55, 0.03, 0.03)
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(-0.275, 0.0, 0.0)
	var gm := _glow_mat(Color(0.95, 0.85, 0.40), 1.6)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shaft.material_override = gm
	_ghost.add_child(shaft)
	var head := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.06
	head_mesh.height = 0.14
	head.mesh = head_mesh
	head.rotation.z = -PI * 0.5
	head.position = Vector3(0.07, 0.0, 0.0)
	head.material_override = gm
	_ghost.add_child(head)

func _on_shove() -> void:
	var angle_deg: float = ANGLES[_angle_idx]
	_angle_idx = (_angle_idx + 1) % ANGLES.size()
	var theta := deg_to_rad(angle_deg)
	# The whole lesson in one line: the door receives |shove|·cos θ, nothing else.
	_omega += shove * cos(theta)
	# Ghost arrow at the rim of the leaf nearest the button, tilted theta off the
	# tangent. The door's swing tangent at that point runs along -Z (leaf along +X).
	var edge := _axle.rotation.y
	var rim := Vector3(cos(edge), 0.0, -sin(edge)) * leaf_w
	_ghost.position = rim + Vector3(0.0, 1.15, 0.0)
	_ghost.rotation.y = edge + PI * 0.5 + theta
	_ghost.visible = true
	_ghost_life = 0.9
	if _readout and _readout.has_method("set_text"):
		_readout.set_text("θ = %d°" % int(angle_deg),
			"the door keeps cos θ = %.2f of the shove" % cos(theta))

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "DoorPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-(leaf_w + 0.55), 0.24, 0.8)
	ts.rotation.y = deg_to_rad(40.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("REVOLVING DOOR",
			"The door spends only what points along its swing: F*t = |F| cos theta.\nAligned spins it, 45 degrees spins it by 0.71, straight at the axle - nothing.\nAgreement is a quantity.")
	_readout = TextScreenScript.new()
	_readout.name = "DoorReadout"
	_readout.mode = 2
	_readout.width_m = 0.30
	_readout.position = Vector3(leaf_w + 0.75, 0.24, 1.15)
	_readout.rotation.y = deg_to_rad(-30.0)
	add_child(_readout)
	if _readout.has_method("set_text"):
		_readout.set_text("θ next: 0°", "press the button - a ghost hand shoves the door")
