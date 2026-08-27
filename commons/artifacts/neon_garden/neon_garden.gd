extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name NeonGarden

## @identity
## lineage: the color taxonomy's rung 5 — a bed of black soil under a dark pergola,
##   planted with flowers whose petals are PURE EMISSION: albedo black, glow only.
##   They bloom brighter as the light around them dies, and they breathe — each flower's
##   emission swells and eases on its own seeded phase, a garden idling like signage.
## essence: emission is colour that owes the room nothing. The shelf in one_bulb_room
##   dies when its bulb stops; these petals cannot die that way, because their colour is
##   not reflected — it is DECLARED. Two ontologies of colour, one taxonomy apart.
## truth: emission — colour as what a body emits. These bloom in any darkness.
##
## The 2026-08-27 color taxonomy (doc/COLOR_TAXONOMY.md), rung 5 of 12.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 25
@export_range(4, 14) var flowers: int = 9
@export var bed_w: float = 2.4
@export var bed_d: float = 1.5
## Breathing depth, 0..1 of each flower's base energy. The pulse is the only motion.
@export_range(0.0, 1.0, 0.05) var breath: float = 0.35

var _petal_mats: Array = []            # {mat, base, rate, phase}

func _ready() -> void:
	_rng.seed = seed
	_build_bed()
	_build_pergola()
	for i in range(flowers):
		_plant(i)
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "flowers", "breath"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(_delta: float) -> void:
	var t := float(Time.get_ticks_msec()) / 1000.0
	for p in _petal_mats:
		var m: StandardMaterial3D = p["mat"]
		m.emission_energy_multiplier = p["base"] * (1.0 + breath * sin(t * p["rate"] + p["phase"]))

# --- the dark ground ----------------------------------------------------------------

func _build_bed() -> void:
	var soil := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(bed_w, 0.22, bed_d)
	soil.mesh = sm
	soil.position = Vector3(0.0, 0.11, 0.0)
	soil.material_override = _matte_mat(Color(0.04, 0.035, 0.04), 1.0)
	add_child(soil)
	var lip := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(bed_w + 0.12, 0.08, bed_d + 0.12)
	lip.mesh = lm
	lip.position = Vector3(0.0, 0.04, 0.0)
	lip.material_override = _matte_mat(Color(0.10, 0.09, 0.09), 0.9)
	add_child(lip)

func _build_pergola() -> void:
	# a dark canopy on four posts: local night, so the garden carries its own darkness
	var wood := _matte_mat(Color(0.07, 0.06, 0.07), 0.95)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var post := MeshInstance3D.new()
			var pm := BoxMesh.new()
			pm.size = Vector3(0.07, 2.1, 0.07)
			post.mesh = pm
			post.position = Vector3(sx * (bed_w * 0.5 + 0.02), 1.05, sz * (bed_d * 0.5 + 0.02))
			post.material_override = wood
			add_child(post)
	var roof := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(bed_w + 0.35, 0.06, bed_d + 0.35)
	roof.mesh = rm
	roof.position = Vector3(0.0, 2.12, 0.0)
	roof.material_override = wood
	add_child(roof)

# --- the flowers --------------------------------------------------------------------

func _plant(i: int) -> void:
	var x := _rng.randf_range(-bed_w * 0.5 + 0.2, bed_w * 0.5 - 0.2)
	var z := _rng.randf_range(-bed_d * 0.5 + 0.2, bed_d * 0.5 - 0.2)
	var h := _rng.randf_range(0.5, 1.15)
	var hue := _rng.randf()
	var glow := Color.from_hsv(hue, 0.85, 1.0)
	# petals: albedo BLACK, emission full — the point of the whole rung
	var petal_mat := StandardMaterial3D.new()
	petal_mat.albedo_color = Color(0.0, 0.0, 0.0)
	petal_mat.emission_enabled = true
	petal_mat.emission = glow
	var base_e := _rng.randf_range(1.6, 2.6) if emissive else 0.8
	petal_mat.emission_energy_multiplier = base_e
	_petal_mats.append({"mat": petal_mat, "base": base_e,
		"rate": _rng.randf_range(0.5, 1.3), "phase": _rng.randf_range(0.0, TAU)})

	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.012
	sm.bottom_radius = 0.02
	sm.height = h
	stem.mesh = sm
	stem.position = Vector3(x, 0.22 + h * 0.5, z)
	stem.rotation.z = _rng.randf_range(-0.12, 0.12)
	stem.material_override = _matte_mat(Color(0.05, 0.06, 0.05), 1.0)
	add_child(stem)
	var head := Node3D.new()
	head.position = Vector3(x, 0.22 + h, z)
	add_child(head)
	var petals := _rng.randi_range(5, 7)
	for k in range(petals):
		var petal := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.0
		pm.bottom_radius = 0.055
		pm.height = 0.16
		petal.mesh = pm
		var ang := TAU * float(k) / float(petals)
		petal.position = Vector3(cos(ang) * 0.07, 0.02, sin(ang) * 0.07)
		petal.rotation = Vector3(cos(ang) * 1.25, 0.0, -sin(ang) * 1.25)
		petal.material_override = petal_mat
		head.add_child(petal)
	var pistil := MeshInstance3D.new()
	var im := SphereMesh.new()
	im.radius = 0.035
	im.height = 0.07
	pistil.mesh = im
	var pistil_mat := StandardMaterial3D.new()
	pistil_mat.albedo_color = Color(0, 0, 0)
	pistil_mat.emission_enabled = true
	pistil_mat.emission = Color.from_hsv(fmod(hue + 0.5, 1.0), 0.7, 1.0)
	pistil_mat.emission_energy_multiplier = 2.0 if emissive else 0.7
	pistil.material_override = pistil_mat
	head.add_child(pistil)

# --- the placard --------------------------------------------------------------------

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "GardenPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-bed_w * 0.5 - 0.4, 0.24, bed_d * 0.5 + 0.3)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("NEON GARDEN",
			"Emission owes the room nothing: petals with albedo black, colour DECLARED\nrather than reflected. The bulb's shelf dies with its light;\nthese bloom in any darkness, breathing on their own phases.")
