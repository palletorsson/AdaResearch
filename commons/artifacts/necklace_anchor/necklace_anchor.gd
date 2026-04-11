extends Node3D
class_name NecklaceAnchor

# @identity
# essence: Vertical stand with torus ring and glowing pendant — a display piece showing the first body anchor point at neck
# desire: To introduce the concept of body anchoring: a pendant at the neck as the seed from which embodiment grows outward
# critical_parameter: pendant emission_energy — the glow intensity that draws attention to the anchor point as identity seed
# triggers: The pendant slowly rotates, catching light; the torus ring marks where the necklace would sit on a body not yet assembled
# emerges: The idea that identity accretes around physical anchors — the pendant is the first fixed point in floating fragments
# needs: Animated pendant rotation [has], emissive material [has], VR interaction [missing — display only]
# relationships: Second artifact in bodyprogression. Follows mirror_artifact (hands), precedes ik_arm_demo (arms).
# truth: The body needs a center before it can have edges — the necklace is the seed, not the ornament.

## Pendant/necklace display on a stand showing an identity anchor point.
## A vertical stand with a torus necklace ring and a glowing pendant that slowly rotates.

var _pendant: MeshInstance3D

func _ready() -> void:
	_build_display()

func _build_display() -> void:
	# Vertical stand — thin cylinder
	var stand := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.02
	cyl.bottom_radius = 0.03
	cyl.height = 1.4
	stand.mesh = cyl
	stand.position.y = 0.7

	var stand_mat := StandardMaterial3D.new()
	stand_mat.albedo_color = Color(0.6, 0.55, 0.5)
	stand_mat.metallic = 0.7
	stand_mat.roughness = 0.3
	stand.material_override = stand_mat
	add_child(stand)

	# Base
	var base := MeshInstance3D.new()
	var base_cyl := CylinderMesh.new()
	base_cyl.top_radius = 0.12
	base_cyl.bottom_radius = 0.15
	base_cyl.height = 0.05
	base.mesh = base_cyl
	base.position.y = 0.025
	base.material_override = stand_mat
	add_child(base)

	# Torus necklace ring at top of stand
	var torus := MeshInstance3D.new()
	var torus_mesh := TorusMesh.new()
	torus_mesh.inner_radius = 0.12
	torus_mesh.outer_radius = 0.16
	torus.mesh = torus_mesh
	torus.position.y = 1.4
	# Tilt the torus to hang naturally
	torus.rotation_degrees.x = 90.0

	var torus_mat := StandardMaterial3D.new()
	torus_mat.albedo_color = Color(0.85, 0.75, 0.45)
	torus_mat.metallic = 0.9
	torus_mat.roughness = 0.15
	torus.material_override = torus_mat
	add_child(torus)

	# Pendant — glowing gem sphere dangling below the torus
	_pendant = MeshInstance3D.new()
	var gem := SphereMesh.new()
	gem.radius = 0.05
	gem.height = 0.1
	_pendant.mesh = gem
	_pendant.position = Vector3(0, 1.2, 0)

	var gem_mat := StandardMaterial3D.new()
	gem_mat.albedo_color = Color(0.3, 0.8, 1.0)
	gem_mat.emission_enabled = true
	gem_mat.emission = Color(0.3, 0.8, 1.0)
	gem_mat.emission_energy_multiplier = 2.0
	gem_mat.metallic = 0.5
	gem_mat.roughness = 0.1
	_pendant.material_override = gem_mat
	add_child(_pendant)

	# Chain from torus to pendant — thin cylinder
	var chain := MeshInstance3D.new()
	var chain_cyl := CylinderMesh.new()
	chain_cyl.top_radius = 0.005
	chain_cyl.bottom_radius = 0.005
	chain_cyl.height = 0.2
	chain.mesh = chain_cyl
	chain.position.y = 1.3
	chain.material_override = torus_mat
	add_child(chain)

	# Label
	var label := Label3D.new()
	label.text = "Identity Anchor"
	label.font_size = 48
	label.position = Vector3(0, 1.65, 0)
	label.modulate = Color.WHITE
	add_child(label)

func _process(delta: float) -> void:
	if _pendant:
		_pendant.rotate_y(delta * 0.8)

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("scale"):
		scale = Vector3.ONE * float(config_data["scale"])
