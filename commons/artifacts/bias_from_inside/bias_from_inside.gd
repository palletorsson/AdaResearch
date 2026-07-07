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

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

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
# Per-term tags: integrated 2D-in-3D display boards (baked text), one per sphere,
# spaced by their sphere positions — replaces 24 bare floating Label3D nodes.
var _marginalized_tags: Array[Node3D] = []
var _default_tags: Array[Node3D] = []
# Consolidated header: title + live perspective readout on ONE baked panel.
var _header: Node3D
var _header_cache: String = ""
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
	# Per-term tags — each a small integrated display board (baked text on a
	# framed face, billboarded). Warm-pink for marginalized, cool-grey for default.
	# Positions are driven by their sphere in _apply_perspective, so they stay
	# spaced with the data and never overlap the header.
	for i in range(_marginalized_terms.size()):
		var tag := BakedText.make_tag(
			_marginalized_terms[i], Color(1, 0.7, 0.85), 0.035,
			Color(0.14, 0.05, 0.10), true, Color(0.85, 0.30, 0.55))
		if tag:
			add_child(tag)
			_marginalized_tags.append(tag)

	for i in range(_default_terms.size()):
		var tag := BakedText.make_tag(
			_default_terms[i], Color(0.82, 0.86, 0.9), 0.035,
			Color(0.07, 0.08, 0.10), true, Color(0.4, 0.46, 0.55))
		if tag:
			add_child(tag)
			_default_tags.append(tag)


# The title + live perspective readout consolidated onto ONE baked text-block
# panel at the top — the header. Rebuilt only when the readout line changes
# (cache-guarded via _header_cache), so per-frame slider drags don't re-bake.
func _create_title() -> void:
	_header = Node3D.new()
	_header.name = "Header"
	_header.position = Vector3(0, 0.52, 0)
	add_child(_header)
	_rebuild_header("DEFAULT PERSPECTIVE — everything looks fair", Color(0.7, 0.75, 0.8))


func _rebuild_header(readout: String, readout_color: Color) -> void:
	if readout == _header_cache:
		return
	_header_cache = readout
	for child in _header.get_children():
		child.queue_free()

	# Opaque backing plate so the two lines read as one board. A single space
	# gives the panel content (empty text returns null from the helper).
	var plate := BakedText.make_panel_mesh(
		" ", Color(0.05, 0.06, 0.08, 0.92), Color(0.05, 0.06, 0.08),
		Vector2(0.62, 0.14), 900, false)
	if plate:
		plate.position.z = -0.004
		var pm = plate.material_override
		if pm is StandardMaterial3D:
			pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_header.add_child(plate)

	# Two stacked lines on the one surface: title, then the live readout.
	var block := BakedText.make_text_block(
		["Embedding Space: View From Inside", readout],
		Color(1, 1, 1), 0.05, 0.58, 0.012, true)
	# Tint only the readout (second child) with the perspective colour.
	var lines := block.get_children()
	if lines.size() >= 2 and lines[1] is MeshInstance3D:
		var lm = lines[1].material_override
		if lm is StandardMaterial3D:
			lm.albedo_color = readout_color
	for line in block.get_children():
		if line is MeshInstance3D:
			var lm2 = line.material_override
			if lm2 is StandardMaterial3D:
				lm2.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_header.add_child(block)


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

	var slider: Node = slider_scene.instantiate()
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
		if i < _marginalized_tags.size():
			_marginalized_tags[i].position = pos + Vector3(0, sphere_radius + 0.03, 0)

	# Lerp default term positions
	for i in range(_default_terms.size()):
		var pos := _default_positions_default[i].lerp(
			_default_positions_compressed[i], blend
		)
		var xf := Transform3D.IDENTITY
		xf.origin = pos
		_default_multimesh.multimesh.set_instance_transform(i, xf)
		if i < _default_tags.size():
			_default_tags[i].position = pos + Vector3(0, sphere_radius + 0.03, 0)

	# Update the consolidated header readout — rebuilt only when the line text
	# actually changes (cache-guarded inside _rebuild_header).
	if blend < 0.3:
		_rebuild_header("DEFAULT PERSPECTIVE — everything looks fair", Color(0.7, 0.75, 0.8))
	elif blend < 0.7:
		_rebuild_header("SHIFTING... space is warping", Color(0.9, 0.7, 0.5))
	else:
		_rebuild_header("COMPRESSED PERSPECTIVE — feel the crowding", Color(1.0, 0.4, 0.6))

	# Marginalized spheres glow more as compression increases
	_marginalized_mat.emission_energy_multiplier = 0.4 + blend * 0.8
	# Default spheres fade as they recede
	_default_mat.albedo_color.a = 1.0 - blend * 0.4
