extends Node3D
class_name DressSelector

# @identity
# essence: Three mannequin display forms with color-coded outfits and selection buttons — identity as wardrobe choice
# desire: To present outfit selection as the final act of embodiment: the body fully assembled, now dressed by choice
# critical_parameter: OUTFIT_DATA — the array of label/color pairs defining what identities are available to perform
# triggers: Each mannequin on a pedestal with a selection button in front — press to choose your presentation
# emerges: The synthesis of body progression: hands found, anchor placed, arms connected, torso estimated, now clothed
# needs: Selection buttons [has], mannequin display [has], VR grab interaction [missing — buttons are visual only]
# relationships: Final artifact in bodyprogression sequence. Follows torso_estimation_vis. Dress as performed identity.
# truth: The outfit is not decoration — it is the last parameter of a body that was never given, only assembled.

## Dress/outfit selection interface with 3 mannequin display forms.
## Each mannequin has a different color and a selection button in front.

const OUTFIT_DATA := [
	{"label": "Classic", "color": Color(0.2, 0.2, 0.6)},
	{"label": "Wicked", "color": Color(0.5, 0.1, 0.5)},
	{"label": "Custom", "color": Color(0.1, 0.6, 0.4)},
]

func _ready() -> void:
	_build_display()

func _build_display() -> void:
	var spacing := 0.8

	for i in range(OUTFIT_DATA.size()):
		var data: Dictionary = OUTFIT_DATA[i]
		var x_offset: float = (i - 1) * spacing

		# Mannequin torso — capsule mesh
		var mannequin := MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.15
		capsule.height = 0.7
		mannequin.mesh = capsule
		mannequin.position = Vector3(x_offset, 0.8, 0)

		var body_mat := StandardMaterial3D.new()
		body_mat.albedo_color = data["color"]
		body_mat.roughness = 0.6
		mannequin.material_override = body_mat
		add_child(mannequin)

		# Head — small sphere on top
		var head := MeshInstance3D.new()
		var head_mesh := SphereMesh.new()
		head_mesh.radius = 0.08
		head_mesh.height = 0.16
		head.mesh = head_mesh
		head.position = Vector3(x_offset, 1.22, 0)
		head.material_override = body_mat
		add_child(head)

		# Stand base — thin cylinder
		var base := MeshInstance3D.new()
		var base_cyl := CylinderMesh.new()
		base_cyl.top_radius = 0.02
		base_cyl.bottom_radius = 0.02
		base_cyl.height = 0.45
		base.mesh = base_cyl
		base.position = Vector3(x_offset, 0.225, 0)

		var stand_mat := StandardMaterial3D.new()
		stand_mat.albedo_color = Color(0.4, 0.4, 0.4)
		stand_mat.metallic = 0.6
		base.material_override = stand_mat
		add_child(base)

		# Base plate
		var plate := MeshInstance3D.new()
		var plate_cyl := CylinderMesh.new()
		plate_cyl.top_radius = 0.12
		plate_cyl.bottom_radius = 0.14
		plate_cyl.height = 0.02
		plate.mesh = plate_cyl
		plate.position = Vector3(x_offset, 0.01, 0)
		plate.material_override = stand_mat
		add_child(plate)

		# Selection button — small sphere in front
		var button := MeshInstance3D.new()
		var btn_mesh := SphereMesh.new()
		btn_mesh.radius = 0.04
		btn_mesh.height = 0.08
		button.mesh = btn_mesh
		button.position = Vector3(x_offset, 0.5, 0.3)

		var btn_mat := StandardMaterial3D.new()
		btn_mat.albedo_color = Color(0.9, 0.9, 0.9)
		btn_mat.emission_enabled = true
		btn_mat.emission = Color(1.0, 1.0, 1.0)
		btn_mat.emission_energy_multiplier = 0.5
		btn_mat.metallic = 0.8
		btn_mat.roughness = 0.2
		button.material_override = btn_mat
		add_child(button)

		# Label below mannequin
		var label := Label3D.new()
		label.text = data["label"]
		label.font_size = 40
		label.position = Vector3(x_offset, -0.08, 0.15)
		label.modulate = Color.WHITE
		add_child(label)

	# Title label above the whole display
	var title := Label3D.new()
	title.text = "Outfit Selection"
	title.font_size = 56
	title.position = Vector3(0, 1.5, 0)
	title.modulate = Color.WHITE
	add_child(title)

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("scale"):
		scale = Vector3.ONE * float(config_data["scale"])
