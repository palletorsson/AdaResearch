extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FamilyChandelier

## @identity
## lineage: the graph taxonomy's rung 2 — a chandelier that IS a scene tree. One root
##   hub at the ceiling, arms to three children, arms again to their children, a lamp
##   at every node. Press the button and ONE mid-branch node starts to swing — and its
##   entire subtree swings rigidly with it, grandchildren and all, while its siblings
##   hang perfectly still.
## essence: add_child is the engine's home graph: rooted, directed, acyclic by refusal.
##   A child lives INSIDE its parent's transform, so moving a parent moves the whole
##   line of descent — inheritance you can watch. This chandelier is not a picture of
##   the scene tree; it is one, and the swing is the proof.
## truth: the tree is the graph the engine gives you for free. Move a parent, move a
##   lineage; cycles are refused at the door.
##
## The 2026-08-27 graph taxonomy (doc/GRAPHTHEORY_TAXONOMY.md), rung 2 of 13.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const BUTTON_SCENE := preload("res://commons/interactables/push_button.tscn")

@export var seed: int = 41
@export var ceiling_y: float = 3.1
@export var damp: float = 0.22
@export var shove: float = 0.9

var _swinger: Node3D                    # the mid node the button excites
var _theta := 0.12
var _omega := 0.0

func _ready() -> void:
	_rng.seed = seed
	_build_tree()
	_build_button()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "damp", "shove"]:
		if config_data.has(key):
			set(key, config_data[key])

func _physics_process(delta: float) -> void:
	# the swung node is a pendulum about its own attachment — its subtree rides along
	# for free, which is the entire lesson
	var acc := -(9.8 / 0.9) * sin(_theta) - damp * _omega
	_omega += acc * delta
	_theta += _omega * delta
	_swinger.rotation.z = _theta

# --- the tree, literally ------------------------------------------------------------

func _lamp(node: Node3D, tint: Color) -> void:
	var bulb := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.07
	bm.height = 0.14
	bulb.mesh = bm
	bulb.material_override = _glow_mat(tint, 1.8)
	node.add_child(bulb)

func _arm(parent: Node3D, to_local: Vector3) -> void:
	var arm := MeshInstance3D.new()
	var am := CylinderMesh.new()
	am.top_radius = 0.018
	am.bottom_radius = 0.018
	am.height = to_local.length()
	arm.mesh = am
	arm.position = to_local * 0.5
	# aim the cylinder along the arm
	var axis := Vector3.UP.cross(to_local.normalized())
	if axis.length() > 0.001:
		arm.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot(to_local.normalized()), -1.0, 1.0)))
	arm.material_override = _steel_mat(Color(0.5, 0.42, 0.26))
	parent.add_child(arm)

func _build_tree() -> void:
	var mount := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.12
	mm.bottom_radius = 0.08
	mm.height = 0.1
	mount.mesh = mm
	mount.position = Vector3(0.0, ceiling_y + 0.05, 0.0)
	mount.material_override = _steel_mat(Color(0.5, 0.42, 0.26))
	add_child(mount)

	var root := Node3D.new()             # THE root — nodes below are add_child all the way
	root.position = Vector3(0.0, ceiling_y, 0.0)
	add_child(root)
	_lamp(root, Color(1.0, 0.95, 0.85))
	var drop := Vector3(0.0, -0.55, 0.0)
	_arm(root, drop)

	var child_hues := [0.08, 0.35, 0.6]
	for i in range(3):
		var ang := TAU * float(i) / 3.0
		var offset := Vector3(cos(ang) * 0.75, -0.55, sin(ang) * 0.75)
		var child := Node3D.new()
		child.position = offset
		root.add_child(child)
		_arm(root, offset)
		_lamp(child, Color.from_hsv(child_hues[i], 0.55, 1.0))
		if i == 1:
			_swinger = child             # this lineage is the demonstration
		# grandchildren: two per child, hanging lower and narrower
		for k in range(2):
			var gang := ang + (0.5 - float(k)) * 0.9
			var goff := Vector3(cos(gang) * 0.42, -0.5, sin(gang) * 0.42)
			var grand := Node3D.new()
			grand.position = goff
			child.add_child(grand)
			_arm(child, goff)
			_lamp(grand, Color.from_hsv(child_hues[i], 0.35, 1.0))
			# one great-grandchild on the swinging line, to make the lineage long
			if i == 1 and k == 0:
				var ggoff := Vector3(0.0, -0.45, 0.0)
				var great := Node3D.new()
				great.position = ggoff
				grand.add_child(great)
				_arm(grand, ggoff)
				_lamp(great, Color.from_hsv(child_hues[i], 0.2, 1.0))

func _build_button() -> void:
	var btn := BUTTON_SCENE.instantiate()
	btn.position = Vector3(1.1, 0.85, 1.1)
	btn.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	btn.set("pressed_color", Color(1.0, 0.85, 0.4))
	btn.set("released_color", Color(0.35, 0.35, 0.4))
	add_child(btn)
	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.05
	sm.bottom_radius = 0.07
	sm.height = 0.8
	stem.mesh = sm
	stem.position = Vector3(1.1, 0.4, 1.1)
	stem.material_override = _steel_mat(Color(0.3, 0.3, 0.33))
	add_child(stem)
	if btn.has_signal("pressed"):
		btn.connect("pressed", Callable(self, "_on_shove"))
	else:
		var inner := btn.get_node_or_null("InteractableAreaButton")
		if inner and inner.has_signal("button_pressed"):
			inner.connect("button_pressed", Callable(self, "_on_shove"))

func _on_shove() -> void:
	_omega += shove * (1.0 if _omega >= 0.0 else -1.0)

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "ChandelierPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.15, 0.24, 1.1)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("FAMILY CHANDELIER",
			"add_child: the engine's home graph. Press - one branch swings, and its WHOLE\nline of descent swings rigidly with it, siblings untouched: children live inside\ntheir parent's transform. Rooted, directed, and cycles refused at the door.")
