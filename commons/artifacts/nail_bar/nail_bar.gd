extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name NailBar

## @identity
## lineage: the Skin hero — albedo as manicure. A salon rack of giant fingernails, each
##   lacquered one albedo, presented under one honest white lamp: what a surface
##   REFLECTS, as a beauty ritual. The polish bottles stand under their nails, caps
##   matched, because skin colour here is a CHOICE with a product line.
## essence: albedo_color is the fraction of each channel a surface hands back. The
##   lacquer does not glow, does not transmit — it refuses and returns. Every nail is
##   one refusal, curated; the rack is a palette wearing itself.
## truth: skin is the colour a thing answers light with. The salon knows it is an
##   answer, and sells it.
##
## The 2026-08-27 category-heroes pass, color. Queer beautiful applied — the taxonomy's
## own truth line names paint and nails; the hero takes it literally.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const LACQUERS := [
	Color(0.78, 0.16, 0.12), Color(0.92, 0.75, 0.14), Color(0.13, 0.30, 0.62),
	Color(0.88, 0.44, 0.66), Color(0.20, 0.42, 0.17), Color(0.10, 0.10, 0.11),
	Color(0.88, 0.86, 0.82),
]

@export var seed: int = 7
@export var pitch: float = 0.42

func _ready() -> void:
	_rng.seed = seed
	_build_counter()
	_build_nails()
	_build_lamp()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "pitch"]:
		if config_data.has(key):
			set(key, config_data[key])

func _build_counter() -> void:
	var w := pitch * float(LACQUERS.size()) + 0.5
	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(w, 0.06, 0.7)
	top.mesh = top_mesh
	top.position = Vector3(0.0, 0.9, 0.0)
	top.material_override = _matte_mat(Color(0.92, 0.88, 0.86), 0.4)
	add_child(top)
	var skirt := MeshInstance3D.new()
	var skirt_mesh := BoxMesh.new()
	skirt_mesh.size = Vector3(w, 0.86, 0.6)
	skirt.mesh = skirt_mesh
	skirt.position = Vector3(0.0, 0.44, 0.0)
	skirt.material_override = _matte_mat(Color(0.30, 0.19, 0.10), 0.85)
	add_child(skirt)

func _build_nails() -> void:
	var n := LACQUERS.size()
	for i in range(n):
		var col: Color = LACQUERS[i]
		var x := (float(i) - float(n - 1) * 0.5) * pitch
		# the nail: a tall capsule sliced by scale into a lacquered oval — filed
		# almond, salon standard, forty centimetres, unapologetic
		var nail := MeshInstance3D.new()
		var nail_mesh := CapsuleMesh.new()
		nail_mesh.radius = 0.09
		nail_mesh.height = 0.46
		nail.mesh = nail_mesh
		nail.scale = Vector3(1.0, 1.0, 0.34)
		nail.position = Vector3(x, 1.22, 0.0)
		nail.rotation.x = deg_to_rad(-8.0)
		var lm := StandardMaterial3D.new()
		lm.albedo_color = col
		lm.roughness = 0.12
		lm.metallic = 0.05
		nail.material_override = lm
		add_child(nail)
		# its cuticle stand
		var stand := MeshInstance3D.new()
		var stand_mesh := CylinderMesh.new()
		stand_mesh.top_radius = 0.045
		stand_mesh.bottom_radius = 0.06
		stand_mesh.height = 0.14
		stand.mesh = stand_mesh
		stand.position = Vector3(x, 1.0, 0.0)
		stand.material_override = _steel_mat(Color(0.7, 0.7, 0.72))
		add_child(stand)
		# the product: a little bottle below, SAME albedo, capped black
		var bottle := MeshInstance3D.new()
		var bottle_mesh := CylinderMesh.new()
		bottle_mesh.top_radius = 0.035
		bottle_mesh.bottom_radius = 0.045
		bottle_mesh.height = 0.1
		bottle.mesh = bottle_mesh
		bottle.position = Vector3(x, 0.98, 0.24)
		var bm := StandardMaterial3D.new()
		bm.albedo_color = col
		bm.roughness = 0.15
		bottle.material_override = bm
		add_child(bottle)
		var cap := MeshInstance3D.new()
		var cap_mesh := CylinderMesh.new()
		cap_mesh.top_radius = 0.018
		cap_mesh.bottom_radius = 0.018
		cap_mesh.height = 0.06
		cap.mesh = cap_mesh
		cap.position = Vector3(x, 1.06, 0.24)
		cap.material_override = _matte_mat(Color(0.08, 0.08, 0.09), 0.5)
		add_child(cap)

func _build_lamp() -> void:
	# ONE honest white lamp over the rack: albedo shown under the light that tells
	# no stories. (The dressing room next door is where the light lies.)
	var arm := MeshInstance3D.new()
	var arm_mesh := CylinderMesh.new()
	arm_mesh.top_radius = 0.02
	arm_mesh.bottom_radius = 0.02
	arm_mesh.height = 1.1
	arm.mesh = arm_mesh
	arm.position = Vector3(-pitch * float(LACQUERS.size()) * 0.5 - 0.2, 1.5, 0.0)
	arm.material_override = _steel_mat(Color(0.35, 0.35, 0.38))
	add_child(arm)
	var shade := MeshInstance3D.new()
	var shade_mesh := CylinderMesh.new()
	shade_mesh.top_radius = 0.07
	shade_mesh.bottom_radius = 0.16
	shade_mesh.height = 0.14
	shade.mesh = shade_mesh
	shade.position = Vector3(0.0, 2.02, 0.0)
	shade.material_override = _steel_mat(Color(0.88, 0.86, 0.82))
	add_child(shade)
	var glow := MeshInstance3D.new()
	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 0.05
	glow_mesh.height = 0.1
	glow.mesh = glow_mesh
	glow.position = Vector3(0.0, 1.96, 0.0)
	glow.material_override = _glow_mat(Color(1.0, 0.98, 0.94), 2.2)
	add_child(glow)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.98, 0.94)
	light.light_energy = 1.6
	light.omni_range = 4.0
	light.position = Vector3(0.0, 1.9, 0.0)
	add_child(light)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "NailPlate"
	ts.mode = 2
	ts.width_m = 0.42
	ts.position = Vector3(-(pitch * float(LACQUERS.size()) * 0.5 + 0.45), 0.24, 0.6)
	ts.rotation.y = deg_to_rad(35.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("NAIL BAR - albedo_color",
			"Skin is the colour a thing answers light with: the lacquer refuses and\nreturns, channel by channel, under one honest white lamp.\nThe salon knows it is an answer. That is why it sells the bottle.")
