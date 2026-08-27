extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name OneBulbRoom

## @identity
## lineage: the color taxonomy's rung 1 — a dark chamber, a shelf of saturated objects,
##   and ONE bulb on a cord. Press the button and the bulb swings as a real damped
##   pendulum; every colour in the room swings with it, blooming where the light passes
##   and dying where it does not.
## essence: albedo is a PROMISE light has to keep. Color(r,g,b) on a surface is nothing
##   until Light3D multiplies it — kill the light and every triple in the room is the
##   same black. The engine's own dependency order, made into furniture.
## truth: no light, no color. The room decides first.
##
## The 2026-08-27 color taxonomy (doc/COLOR_TAXONOMY.md), rung 1 of 12.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const BUTTON_SCENE := preload("res://commons/interactables/push_button.tscn")

@export var seed: int = 21
@export var cord_len: float = 1.35
@export var anchor_y: float = 2.75
## Pendulum damping per second. 0.35 lets one shove carry ~20 s of swing.
@export var damp: float = 0.35
@export var shove: float = 1.9          # rad/s added per button press

var _bulb_arm: Node3D                   # rotates about the anchor; the bulb hangs at -cord_len
var _theta := 0.4                       # swing angle, starts with a small drift
var _omega := 0.0
var _precess := 0.0                     # the swing plane wanders slowly

func _ready() -> void:
	_rng.seed = seed
	_build_chamber()
	_build_shelf()
	_build_bulb()
	_build_button()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "damp", "shove", "cord_len"]:
		if config_data.has(key):
			set(key, config_data[key])

func _physics_process(delta: float) -> void:
	# a real damped pendulum, not an animation: theta'' = -(g/L) sin(theta) - c*theta'
	var acc := -(9.8 / cord_len) * sin(_theta) - damp * _omega
	_omega += acc * delta
	_theta += _omega * delta
	_precess += delta * 0.07
	_bulb_arm.rotation = Vector3(sin(_precess) * _theta, 0.0, cos(_precess) * _theta)

# --- the chamber: dark, so the bulb is the only argument ----------------------------

func _build_chamber() -> void:
	var wall := _matte_mat(Color(0.055, 0.055, 0.065), 0.95)
	var floor_mesh := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(3.4, 0.1, 3.0)
	floor_mesh.mesh = fm
	floor_mesh.position = Vector3(0.0, 0.05, 0.0)
	floor_mesh.material_override = wall
	add_child(floor_mesh)
	# three walls and a ceiling — the open face is the door
	for spec in [[Vector3(0.0, 1.5, -1.45), Vector3(3.4, 3.0, 0.1)],
			[Vector3(-1.65, 1.5, 0.0), Vector3(0.1, 3.0, 3.0)],
			[Vector3(1.65, 1.5, 0.0), Vector3(0.1, 3.0, 3.0)],
			[Vector3(0.0, 3.0, 0.0), Vector3(3.4, 0.1, 3.0)]]:
		var w := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = spec[1]
		w.mesh = wm
		w.position = spec[0]
		w.material_override = wall
		add_child(w)

func _build_shelf() -> void:
	var shelf := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(2.6, 0.06, 0.5)
	shelf.mesh = sm
	shelf.position = Vector3(0.0, 0.85, -1.05)
	shelf.material_override = _matte_mat(Color(0.10, 0.09, 0.09), 0.9)
	add_child(shelf)
	# six saturated bodies, PURE albedo — no emission anywhere on this shelf, which is
	# the whole point: their colour exists only on loan from the bulb
	for i in range(6):
		var hue := float(i) / 6.0
		var mat := _matte_mat(Color.from_hsv(hue, 0.9, 0.9), 0.55)
		var x := -1.1 + 0.44 * float(i)
		var body := MeshInstance3D.new()
		match i % 3:
			0:
				var s := SphereMesh.new()
				s.radius = 0.14
				s.height = 0.28
				body.mesh = s
			1:
				var c := CylinderMesh.new()
				c.top_radius = 0.0
				c.bottom_radius = 0.13
				c.height = 0.3
				body.mesh = c
			_:
				var b := BoxMesh.new()
				b.size = Vector3(0.22, 0.22, 0.22)
				body.mesh = b
		body.position = Vector3(x, 1.03, -1.05)
		body.material_override = mat
		add_child(body)

# --- the bulb -----------------------------------------------------------------------

func _build_bulb() -> void:
	var anchor := Node3D.new()
	anchor.position = Vector3(0.0, anchor_y, 0.0)
	add_child(anchor)
	_bulb_arm = Node3D.new()
	anchor.add_child(_bulb_arm)
	var cord := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.006
	cm.bottom_radius = 0.006
	cm.height = cord_len
	cord.mesh = cm
	cord.position = Vector3(0.0, -cord_len * 0.5, 0.0)
	cord.material_override = _matte_mat(Color(0.15, 0.14, 0.13), 0.8)
	_bulb_arm.add_child(cord)
	var glass := MeshInstance3D.new()
	var gm := SphereMesh.new()
	gm.radius = 0.075
	gm.height = 0.15
	glass.mesh = gm
	glass.position = Vector3(0.0, -cord_len, 0.0)
	glass.material_override = _glow_mat(Color(1.0, 0.93, 0.78), 2.4)
	_bulb_arm.add_child(glass)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.93, 0.78)
	light.light_energy = 2.6
	light.omni_range = 5.5
	light.shadow_enabled = true
	light.position = Vector3(0.0, -cord_len, 0.0)
	_bulb_arm.add_child(light)

func _build_button() -> void:
	var btn := BUTTON_SCENE.instantiate()
	btn.position = Vector3(1.15, 0.85, 1.15)
	btn.rotation = Vector3(deg_to_rad(-25.0), 0.0, 0.0)
	btn.set("pressed_color", Color(1.0, 0.93, 0.78))
	btn.set("released_color", Color(0.35, 0.35, 0.4))
	add_child(btn)
	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.05
	sm.bottom_radius = 0.07
	sm.height = 0.8
	stem.mesh = sm
	stem.position = Vector3(1.15, 0.4, 1.15)
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
	ts.name = "BulbPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.2, 0.24, 1.2)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("ONE BULB",
			"No light, no color. Albedo is a promise light has to keep -\nsix saturated bodies, not one of them emissive.\nPress: shove the bulb, and watch every colour in the room swing.")
