# bias_from_inside.gd
# Visualizes a word embedding space from the perspective of a marginalized term.
# Instead of the god's-eye view, this places the camera INSIDE the compressed
# region. Nearby terms (other marginalized concepts) cluster tightly together.
# Distant terms (the "default" terms) are far away, tiny, unreachable.
# A slider shifts between "default perspective" (evenly distributed) and
# "compressed perspective" (reveals how uneven the space really is).
#
# @identity
#   essence: an embedding space experienced from the inside of its compression
#   desire: players feel what it means to be algorithmically crowded into a corner
#   critical_parameter: perspective_blend — 0.0 = default view, 1.0 = compressed view
#   triggers: instantiation, perspective slider interaction
#   emerges: the realization that "neutral" embeddings are anything but neutral
#   needs: [implemented] MultiMesh spheres, Label3D terms, camera lerp, ArtifactControls
#   relationships: algorithmic_bias (same map), algorithmic_bias_visualization (sibling)
#   truth: the embedding space is not a fact — it is a map drawn by the powerful

extends Node3D
class_name BiasFromInside

# --- Terms ---
# Marginalized terms cluster tightly in compressed space
var _marginalized_terms: Array[String] = [
	"queer", "nonbinary", "indigenous", "disabled",
	"refugee", "undocumented", "neurodivergent", "femme",
	"trans", "homeless", "incarcerated", "colonized"
]

# Default/dominant terms spread wide in embedding space
var _default_terms: Array[String] = [
	"normal", "standard", "professional", "citizen",
	"healthy", "rational", "objective", "nuclear family",
	"mainstream", "traditional", "universal", "default"
]

# --- Configuration ---
@export var sphere_radius: float = 0.025
@export var label_font_size: int = 12
@export var compressed_cluster_radius: float = 0.15
@export var default_spread_radius: float = 0.8
@export var default_spread_offset: float = 1.5
@export var animation_speed: float = 1.5

# --- Internal ---
var _perspective_blend: float = 0.0  # 0 = default, 1 = compressed
var _marginalized_positions_default: Array[Vector3] = []
var _marginalized_positions_compressed: Array[Vector3] = []
var _default_positions_default: Array[Vector3] = []
var _default_positions_compressed: Array[Vector3] = []

var _marginalized_multimesh: MultiMeshInstance3D
var _default_multimesh: MultiMeshInstance3D
var _marginalized_labels: Array[Label3D] = []
var _default_labels: Array[Label3D] = []
var _title_label: Label3D
var _perspective_label: Label3D
var _controls: Node

# Materials
var _marginalized_mat: StandardMaterial3D
var _default_mat: StandardMaterial3D


func _ready() -> void:
	_generate_positions()
	_create_materials()
	_create_multimeshes()
	_create_labels()
	_create_title()
	_create_controls()
	_apply_perspective(0.0)


func apply_grid_config(config: Dictionary) -> void:
	pass


# ------------------------------------------------------------------
# Position generation
# ------------------------------------------------------------------

func _generate_positions() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # Deterministic

	# Default perspective: everything looks evenly distributed
	for i in range(_marginalized_terms.size()):
		var angle := (float(i) / _marginalized_terms.size()) * TAU
		var r := 0.4 + rng.randf() * 0.3
		var pos := Vector3(cos(angle) * r, rng.randf_range(-0.1, 0.1), sin(angle) * r)
		_marginalized_positions_default.append(pos)

	for i in range(_default_terms.size()):
		var angle := (float(i) / _default_terms.size()) * TAU + 0.3
		var r := 0.35 + rng.randf() * 0.35
		var pos := Vector3(cos(angle) * r, rng.randf_range(-0.1, 0.1), sin(angle) * r)
		_default_positions_default.append(pos)

	# Compressed perspective: marginalized terms squeezed into a tight cluster,
	# default terms spread far and wide
	for i in range(_marginalized_terms.size()):
		var angle := (float(i) / _marginalized_terms.size()) * TAU
		var r := compressed_cluster_radius * (0.3 + rng.randf() * 0.7)
		var pos := Vector3(
			cos(angle) * r,
			rng.randf_range(-0.05, 0.05),
			sin(angle) * r
		)
		_marginalized_positions_compressed.append(pos)

	for i in range(_default_terms.size()):
		var angle := (float(i) / _default_terms.size()) * TAU
		var r := default_spread_radius + rng.randf() * 0.4
		var offset_dir := Vector3(cos(angle), 0, sin(angle))
		var pos := offset_dir * (default_spread_offset + r) + Vector3(0, rng.randf_range(-0.2, 0.2), 0)
		_default_positions_compressed.append(pos)


# ------------------------------------------------------------------
# Materials
# ------------------------------------------------------------------

func _create_materials() -> void:
	_marginalized_mat = StandardMaterial3D.new()
	_marginalized_mat.albedo_color = Color(0.85, 0.3, 0.55)  # Warm pink-magenta
	_marginalized_mat.emission_enabled = true
	_marginalized_mat.emission = Color(0.6, 0.15, 0.35)
	_marginalized_mat.emission_energy_multiplier = 0.4

	_default_mat = StandardMaterial3D.new()
	_default_mat.albedo_color = Color(0.7, 0.75, 0.8)  # Cool neutral gray
	_default_mat.emission_enabled = true
	_default_mat.emission = Color(0.3, 0.35, 0.4)
	_default_mat.emission_energy_multiplier = 0.2


# ------------------------------------------------------------------
# MultiMesh construction
# ------------------------------------------------------------------

func _create_multimeshes() -> void:
	# Marginalized terms
	var m_mesh := SphereMesh.new()
	m_mesh.radius = sphere_radius
	m_mesh.height = sphere_radius * 2.0
	m_mesh.radial_segments = 12
	m_mesh.rings = 6

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = m_mesh
	mm.instance_count = _marginalized_terms.size()

	_marginalized_multimesh = MultiMeshInstance3D.new()
	_marginalized_multimesh.multimesh = mm
	_marginalized_multimesh.material_override = _marginalized_mat
	add_child(_marginalized_multimesh)

	# Default terms
	var d_mesh := SphereMesh.new()
	d_mesh.radius = sphere_radius
	d_mesh.height = sphere_radius * 2.0
	d_mesh.radial_segments = 12
	d_mesh.rings = 6

	var mm2 := MultiMesh.new()
	mm2.transform_format = MultiMesh.TRANSFORM_3D
	mm2.mesh = d_mesh
	mm2.instance_count = _default_terms.size()

	_default_multimesh = MultiMeshInstance3D.new()
	_default_multimesh.multimesh = mm2
	_default_multimesh.material_override = _default_mat
	add_child(_default_multimesh)


# ------------------------------------------------------------------
# Labels
# ------------------------------------------------------------------

func _create_labels() -> void:
	for i in range(_marginalized_terms.size()):
		var lbl := Label3D.new()
		lbl.text = _marginalized_terms[i]
		lbl.font_size = label_font_size
		lbl.modulate = Color(1, 0.6, 0.8)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.pixel_size = 0.001
		add_child(lbl)
		_marginalized_labels.append(lbl)

	for i in range(_default_terms.size()):
		var lbl := Label3D.new()
		lbl.text = _default_terms[i]
		lbl.font_size = label_font_size
		lbl.modulate = Color(0.75, 0.8, 0.85)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.no_depth_test = true
		lbl.pixel_size = 0.001
		add_child(lbl)
		_default_labels.append(lbl)


func _create_title() -> void:
	_title_label = Label3D.new()
	_title_label.text = "Embedding Space: View From Inside"
	_title_label.font_size = 20
	_title_label.modulate = Color(1, 1, 1, 0.9)
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.position = Vector3(0, 0.55, 0)
	_title_label.pixel_size = 0.001
	add_child(_title_label)

	_perspective_label = Label3D.new()
	_perspective_label.text = "DEFAULT PERSPECTIVE"
	_perspective_label.font_size = 16
	_perspective_label.modulate = Color(0.7, 0.75, 0.8, 0.8)
	_perspective_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_perspective_label.position = Vector3(0, 0.48, 0)
	_perspective_label.pixel_size = 0.001
	add_child(_perspective_label)


# ------------------------------------------------------------------
# Controls (ArtifactControls pattern)
# ------------------------------------------------------------------

func _create_controls() -> void:
	var slider_scene = load("res://commons/interactables/slider_horizontal.tscn")
	if slider_scene == null:
		return

	_controls = Node3D.new()
	_controls.name = "ArtifactControls"
	add_child(_controls)

	var slider := slider_scene.instantiate()
	slider.position = Vector3(0, 0.02, 0.45)
	slider.rotation_degrees.y = 180
	_controls.add_child(slider)

	var label_node = slider.get_node_or_null("Frame/LabelName")
	if label_node:
		label_node.text = "Perspective"
	slider.set_param_name("Perspective")
	slider.set_normalized_value(0.0)
	slider.slider_moved.connect(_on_perspective_changed)


func _on_perspective_changed(value: float) -> void:
	_perspective_blend = clampf(value, 0.0, 1.0)
	_apply_perspective(_perspective_blend)


# ------------------------------------------------------------------
# Perspective application
# ------------------------------------------------------------------

func _apply_perspective(blend: float) -> void:
	# Lerp marginalized term positions
	for i in range(_marginalized_terms.size()):
		var pos := _marginalized_positions_default[i].lerp(
			_marginalized_positions_compressed[i], blend
		)
		var xf := Transform3D.IDENTITY
		xf.origin = pos
		_marginalized_multimesh.multimesh.set_instance_transform(i, xf)
		if i < _marginalized_labels.size():
			_marginalized_labels[i].position = pos + Vector3(0, sphere_radius + 0.015, 0)

	# Lerp default term positions
	for i in range(_default_terms.size()):
		var pos := _default_positions_default[i].lerp(
			_default_positions_compressed[i], blend
		)
		var xf := Transform3D.IDENTITY
		xf.origin = pos
		_default_multimesh.multimesh.set_instance_transform(i, xf)
		if i < _default_labels.size():
			_default_labels[i].position = pos + Vector3(0, sphere_radius + 0.015, 0)

	# Update perspective label and colors
	if blend < 0.3:
		_perspective_label.text = "DEFAULT PERSPECTIVE — everything looks fair"
		_perspective_label.modulate = Color(0.7, 0.75, 0.8, 0.8)
	elif blend < 0.7:
		_perspective_label.text = "SHIFTING... space is warping"
		_perspective_label.modulate = Color(0.9, 0.7, 0.5, 0.9)
	else:
		_perspective_label.text = "COMPRESSED PERSPECTIVE — feel the crowding"
		_perspective_label.modulate = Color(1.0, 0.4, 0.6, 1.0)

	# Marginalized spheres glow more as compression increases
	_marginalized_mat.emission_energy_multiplier = 0.4 + blend * 0.8
	# Default spheres fade as they recede
	_default_mat.albedo_color.a = 1.0 - blend * 0.4
