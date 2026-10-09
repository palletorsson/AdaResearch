# An authored word-position study. It moves points, never the visitor or camera.
# @identity
# essence: indexed words interpolate between two seeded, authored arrangements
# desire: distinguish being present from being easy to tell apart
# critical_parameter: perspective_blend (legacy API name) — the COMPRESSION handle
# triggers: one slider changes positions; READ opens the maker's interpretation
# emerges: the same words remain while their spatial separations change
# needs: real normalized rail input, fixed salience, space for both endpoints
# truth: two coloured groups are a curatorial choice, not measured model embeddings

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
## Legacy export/token name retained. The control moves geometry, not a camera.
@export_range(0.0, 1.0, 0.05) var perspective_blend: float = 0.0
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
var _slider: Node
var _reading: Node3D

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
	_create_stand()
	_perspective_blend = clampf(perspective_blend, 0.0, 1.0)
	_apply_perspective(_perspective_blend)
	_slider.set_normalized_value(_perspective_blend)


## Apply author configuration before regenerating deterministic endpoints.
func apply_grid_config(config: Dictionary) -> void:
	if config.has("perspective_blend"):
		perspective_blend = clampf(float(config["perspective_blend"]),0.0,1.0)
	for key in ["compressed_cluster_radius","default_spread_radius","default_spread_offset"]:
		if config.has(key): set(key,maxf(0.0,float(config[key])))
	if is_node_ready():
		_generate_positions()
		_perspective_blend=perspective_blend
		_apply_perspective(_perspective_blend)
		_slider.set_normalized_value(_perspective_blend)


# ------------------------------------------------------------------
# Position generation
# ------------------------------------------------------------------

func _generate_positions() -> void:
	_marginalized_positions_default.clear()
	_marginalized_positions_compressed.clear()
	_default_positions_default.clear()
	_default_positions_compressed.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # Deterministic

	# Arrangement A: two seeded rings. Neither arrangement is a fairness measure.
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
	_rebuild_header("ARRANGEMENT A", Color(0.7, 0.75, 0.8))


func _rebuild_header(readout: String, readout_color: Color) -> void:
	if readout == _header_cache:
		return
	_header_cache = readout
	for child in _header.get_children():
		child.queue_free()

	# Bake each line onto its own face. Independent billboards must not rotate
	# a shared backing plate over the lower line.
	var lines: Array=["WORD POSITIONS — AUTHORED STUDY",readout]
	for i in range(lines.size()):
		var face=BakedText.make_panel_mesh(lines[i],Color(.05,.06,.08),Color(.85,.9,1),Vector2(.7,.065),1100,true)
		face.position.y=.038-float(i)*.076
		face.material_override.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
		_header.add_child(face)


# ------------------------------------------------------------------
# Controls (ArtifactControls pattern)
# ------------------------------------------------------------------

func _create_controls() -> void:
	var RackTpl: GDScript=load("res://commons/audio/rack_templates/RackTemplates.gd")
	_controls=RackTpl.create_panel("WORD POSITIONS",[
		[{"type":"slider_h","label":"COMPRESSION","default":perspective_blend}],
		[{"type":"button","label":"READ / CLOSE"}]
	])
	# Keep the controls in front of the initial ring of word labels.
	_controls.position=Vector3(0,.02,1.02)
	_controls.rotation_degrees.x=-20
	add_child(_controls)
	_slider=_controls.find_child("Param_0",true,false)
	_slider.slider_moved.connect(_on_perspective_changed)
	_controls.find_child("Btn_0",true,false).get_node("InteractableAreaButton").button_pressed.connect(func(_b): _reading.visible=not _reading.visible)
	_reading=Node3D.new()
	_reading.name="ProjectReading"
	_reading.position=Vector3(.65,.22,1.02)
	var panel=BakedText.make_text_block(["PROJECT READING", "Both groups were chosen.", "More room is not a verdict.", "Which distinction matters to you?"],Color(.9,.92,1),.04,.64,.018,true)
	_reading.add_child(panel)
	_reading.hide()
	add_child(_reading)


func _create_stand() -> void:
	var stand := MeshInstance3D.new()
	stand.name="ControlStand"
	var shape := CylinderMesh.new()
	shape.top_radius=.055
	shape.bottom_radius=.12
	shape.height=1.05
	stand.mesh=shape
	stand.position=Vector3(0,-.56,.91)
	var material := StandardMaterial3D.new()
	material.albedo_color=Color(.13,.15,.18)
	stand.material_override=material
	add_child(stand)


func _on_perspective_changed(_travel: float) -> void:
	# The rail signal carries physical travel. Read its normalized coordinate.
	_perspective_blend=clampf(_slider.get_normalized_value(),0.0,1.0)
	perspective_blend=_perspective_blend
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
		_rebuild_header("ARRANGEMENT A", Color(0.7, 0.75, 0.8))
	elif blend < 0.7:
		_rebuild_header("BETWEEN A AND B", Color(0.7, 0.75, 0.8))
	else:
		_rebuild_header("ARRANGEMENT B", Color(0.7, 0.75, 0.8))

	# Materials remain fixed as positions change. Interpretation is opt-in.
