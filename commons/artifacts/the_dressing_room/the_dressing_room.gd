extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheDressingRoom

## @identity
## lineage: the color taxonomy's rung 7 — a stage alcove with ONE dress on a mannequin
##   and three lamps on a rail: tungsten, blue, red. The lamps take turns. The dress
##   "changes colour" every few seconds and never changes at all — the readout keeps
##   saying so, like a stagehand under oath.
## essence: seen = light × skin. The engine does this multiplication in earnest
##   (real SpotLight3Ds, one at a time — nothing here is faked with material swaps),
##   so a rose albedo under blue light genuinely arrives grey-violet and under deep red
##   arrives on fire. Metamerism as drag: the same body, three presentations.
## truth: what you see is a product, not a property. The dress did not change.
##
## The 2026-08-27 color taxonomy (doc/COLOR_TAXONOMY.md), rung 7 of 12.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
# name, light colour, energy — tungsten reads honest, blue starves the red channel,
# deep red starves everything but it
const LAMPS := [
	["TUNGSTEN", Color(1.0, 0.93, 0.78), 3.0],
	["BLUE", Color(0.25, 0.45, 1.0), 3.4],
	["DEEP RED", Color(1.0, 0.12, 0.08), 3.4],
]
const DRESS_ALBEDO := Color(0.85, 0.32, 0.4)   # a rose the lamps will argue about

@export var seed: int = 27
@export var dwell: float = 4.0          # seconds per lamp

var _lights: Array = []
var _housings: Array = []
var _clock := 0.0
var _which := 0
var _readout: Node3D

func _ready() -> void:
	_rng.seed = seed
	_clock = _rng.randf_range(0.0, dwell)   # seeded phase, so two placements disagree
	_build_alcove()
	_build_mannequin()
	_build_rail()
	_build_plaque()
	_switch(0)

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "dwell"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	_clock += delta
	if _clock >= dwell:
		_clock = 0.0
		_switch((_which + 1) % LAMPS.size())

func _switch(i: int) -> void:
	_which = i
	for k in range(_lights.size()):
		_lights[k].visible = (k == i)
		var hm: StandardMaterial3D = _housings[k]
		hm.emission_energy_multiplier = 2.0 if k == i else 0.15
	if _readout and _readout.has_method("set_text"):
		_readout.set_text("LAMP: %s" % LAMPS[i][0], "the dress did not change")

# --- the alcove ---------------------------------------------------------------------

func _build_alcove() -> void:
	var dark := _matte_mat(Color(0.06, 0.055, 0.065), 0.95)
	for spec in [[Vector3(0.0, 1.4, -0.95), Vector3(2.6, 2.8, 0.1)],
			[Vector3(-1.25, 1.4, 0.0), Vector3(0.1, 2.8, 2.0)],
			[Vector3(1.25, 1.4, 0.0), Vector3(0.1, 2.8, 2.0)],
			[Vector3(0.0, 0.05, 0.0), Vector3(2.6, 0.1, 2.0)]]:
		var w := MeshInstance3D.new()
		var wm := BoxMesh.new()
		wm.size = spec[1]
		w.mesh = wm
		w.position = spec[0]
		w.material_override = dark
		add_child(w)
	var dais := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.55
	dm.bottom_radius = 0.62
	dm.height = 0.14
	dais.mesh = dm
	dais.position = Vector3(0.0, 0.17, -0.15)
	dais.material_override = _matte_mat(Color(0.12, 0.11, 0.12), 0.85)
	add_child(dais)

# --- the dress ----------------------------------------------------------------------

func _build_mannequin() -> void:
	# ONE material for the whole dress — the constancy under oath
	var fabric := _matte_mat(DRESS_ALBEDO, 0.75)
	var grey := _matte_mat(Color(0.35, 0.35, 0.37), 0.6)
	var skirt := MeshInstance3D.new()
	var sk := CylinderMesh.new()
	sk.top_radius = 0.16
	sk.bottom_radius = 0.52
	sk.height = 0.95
	skirt.mesh = sk
	skirt.position = Vector3(0.0, 0.72, -0.15)
	skirt.material_override = fabric
	add_child(skirt)
	var bodice := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.14
	bm.bottom_radius = 0.17
	bm.height = 0.45
	bodice.mesh = bm
	bodice.position = Vector3(0.0, 1.42, -0.15)
	bodice.material_override = fabric
	add_child(bodice)
	for side in [-1.0, 1.0]:
		var sleeve := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.09
		sm.height = 0.18
		sleeve.mesh = sm
		sleeve.position = Vector3(side * 0.2, 1.58, -0.15)
		sleeve.material_override = fabric
		add_child(sleeve)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.11
	hm.height = 0.22
	head.mesh = hm
	head.position = Vector3(0.0, 1.83, -0.15)
	head.material_override = grey
	add_child(head)

# --- the rail -----------------------------------------------------------------------

func _build_rail() -> void:
	var rail := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.025
	rm.bottom_radius = 0.025
	rm.height = 2.2
	rail.mesh = rm
	rail.rotation.z = PI * 0.5
	rail.position = Vector3(0.0, 2.55, 0.75)
	rail.material_override = _steel_mat(Color(0.3, 0.3, 0.33))
	add_child(rail)
	for i in range(3):
		var x := -0.75 + 0.75 * float(i)
		var housing := MeshInstance3D.new()
		var hm := CylinderMesh.new()
		hm.top_radius = 0.06
		hm.bottom_radius = 0.11
		hm.height = 0.22
		housing.mesh = hm
		housing.position = Vector3(x, 2.4, 0.75)
		housing.rotation.x = deg_to_rad(-35.0)
		var mat := _glow_mat(LAMPS[i][1], 0.15)
		housing.material_override = mat
		add_child(housing)
		_housings.append(mat)
		var light := SpotLight3D.new()
		light.light_color = LAMPS[i][1]
		light.light_energy = LAMPS[i][2]
		light.spot_range = 4.5
		light.spot_angle = 32.0
		light.shadow_enabled = true
		light.position = Vector3(x, 2.4, 0.75)
		light.rotation.x = deg_to_rad(-125.0)   # down and toward the dais
		light.visible = false
		add_child(light)
		_lights.append(light)

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "DressPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-1.05, 0.24, 1.05)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THE DRESSING ROOM",
			"seen = light x skin. One dress, one albedo, three lamps taking turns -\nthe engine multiplies in earnest, so the rose goes grey-violet under blue\nand catches fire under red. Metamerism as drag: same body, three presentations.")
	_readout = TextScreenScript.new()
	_readout.mode = 2
	_readout.width_m = 0.3
	_readout.position = Vector3(1.05, 0.24, 1.05)
	_readout.rotation.y = deg_to_rad(-38.0)
	add_child(_readout)
