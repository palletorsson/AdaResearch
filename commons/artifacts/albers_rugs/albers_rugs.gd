extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name AlbersRugs

## @identity
## lineage: the Ground hero — Josef Albers staged as a domestic dispute. Two identical
##   grey vases, one on a red rug, one on a green rug, joined by a level balance beam
##   that swears they are the same. Your eye files a complaint anyway: against red the
##   grey leans green, against green it leans rose. The beam does not care.
## essence: simultaneous contrast - the same triple reads differently against different
##   ground, because the eye budgets colour relationally. The instrument (a balance,
##   dead level) and the impression (two different vases) disagree, and BOTH are
##   telling their truth.
## truth: no colour is read alone; the ground gets a vote. Albers spent a career
##   proving the vote is usually decisive.
##
## The 2026-08-27 category-heroes pass, color.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const VASE_GREY := Color(0.52, 0.52, 0.52)

@export var seed: int = 11
@export var rugs_apart: float = 2.0
@export var rug_size: float = 1.5

func _ready() -> void:
	_rng.seed = seed
	_build_side(Vector3(-rugs_apart * 0.5, 0.0, 0.0), Color(0.68, 0.14, 0.10))
	_build_side(Vector3(rugs_apart * 0.5, 0.0, 0.0), Color(0.12, 0.38, 0.16))
	_build_beam()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "rugs_apart", "rug_size"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_side(at: Vector3, ground: Color) -> void:
	# the ground: a deep-pile rug, double-bordered like a proper parlour piece
	var rug := MeshInstance3D.new()
	var rug_mesh := BoxMesh.new()
	rug_mesh.size = Vector3(rug_size, 0.035, rug_size)
	rug.mesh = rug_mesh
	rug.position = at + Vector3(0.0, 0.018, 0.0)
	rug.material_override = _matte_mat(ground, 0.98)
	add_child(rug)
	var border := MeshInstance3D.new()
	var border_mesh := BoxMesh.new()
	border_mesh.size = Vector3(rug_size + 0.12, 0.028, rug_size + 0.12)
	border.mesh = border_mesh
	border.position = at + Vector3(0.0, 0.014, 0.0)
	border.material_override = _matte_mat(ground.darkened(0.35), 0.98)
	add_child(border)
	# the witness: one grey vase - SAME material object both sides, by construction
	var body := MeshInstance3D.new()
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.11
	body_mesh.bottom_radius = 0.17
	body_mesh.height = 0.4
	body.mesh = body_mesh
	body.position = at + Vector3(0.0, 0.235, 0.0)
	body.material_override = _matte_mat(VASE_GREY, 0.85)
	add_child(body)
	var neck := MeshInstance3D.new()
	var neck_mesh := CylinderMesh.new()
	neck_mesh.top_radius = 0.075
	neck_mesh.bottom_radius = 0.095
	neck_mesh.height = 0.16
	neck.mesh = neck_mesh
	neck.position = at + Vector3(0.0, 0.515, 0.0)
	neck.material_override = _matte_mat(VASE_GREY, 0.85)
	add_child(neck)
	var lip := MeshInstance3D.new()
	var lip_mesh := TorusMesh.new()
	lip_mesh.inner_radius = 0.06
	lip_mesh.outer_radius = 0.095
	lip.mesh = lip_mesh
	lip.position = at + Vector3(0.0, 0.6, 0.0)
	lip.material_override = _matte_mat(VASE_GREY, 0.85)
	add_child(lip)
	# the sample swatch: a grey card leaning on the vase, the raw triple in the flesh
	var card := MeshInstance3D.new()
	var card_mesh := BoxMesh.new()
	card_mesh.size = Vector3(0.16, 0.22, 0.008)
	card.mesh = card_mesh
	card.position = at + Vector3(0.24, 0.12, 0.22)
	card.rotation.x = deg_to_rad(-12.0)
	card.material_override = _matte_mat(VASE_GREY, 0.9)
	add_child(card)

func _build_beam() -> void:
	# the instrument: a balance beam from lip to lip, DEAD LEVEL, with a bubble
	# level riding its middle - the machine's verdict on the pair
	var beam := MeshInstance3D.new()
	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(rugs_apart, 0.03, 0.06)
	beam.mesh = beam_mesh
	beam.position = Vector3(0.0, 0.66, 0.0)
	beam.material_override = _steel_mat(Color(0.55, 0.48, 0.30))
	add_child(beam)
	var vial := MeshInstance3D.new()
	var vial_mesh := CylinderMesh.new()
	vial_mesh.top_radius = 0.025
	vial_mesh.bottom_radius = 0.025
	vial_mesh.height = 0.11
	vial.mesh = vial_mesh
	vial.rotation.z = PI * 0.5
	vial.position = Vector3(0.0, 0.7, 0.0)
	var vm := StandardMaterial3D.new()
	vm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vm.albedo_color = Color(0.8, 0.95, 0.7, 0.4)
	vial.material_override = vm
	add_child(vial)
	var bubble := MeshInstance3D.new()
	var bubble_mesh := SphereMesh.new()
	bubble_mesh.radius = 0.018
	bubble_mesh.height = 0.036
	bubble.mesh = bubble_mesh
	bubble.position = Vector3(0.0, 0.702, 0.0)   # centred: the beam IS level
	bubble.material_override = _glow_mat(Color(0.85, 0.95, 0.6), 0.9)
	add_child(bubble)
	var verdict := TextScreenScript.new()
	verdict.mode = 2
	verdict.width_m = 0.26
	verdict.position = Vector3(0.0, 0.76, 0.14)
	add_child(verdict)
	if verdict.has_method("set_text"):
		verdict.set_text("LEVEL", "same grey, says the instrument")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "AlbersPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(0.0, 0.24, rug_size * 0.5 + 0.55)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("ALBERS RUGS - simultaneous contrast",
			"Two identical grey vases; the beam between them is dead level and says so.\nYour eye disagrees: against red the grey leans green, against green it leans\nrose. No colour is read alone - the ground gets a vote, and it is decisive.")
