# bias_visualizer.gd
extends Node3D
class_name BiasVisualizer
## Visualizes bias in word embeddings using a 3D word cloud.
## Words are positioned in a simulated embedding space where proximity to
## gendered anchors (man/woman) reveals learned stereotypical associations.
## Three analogy modes show gender-profession, gender-trait, and algorithmic
## redlining patterns. VR-enabled with push-button analogy selection.

## Overall scale of the embedding space display (meters)
@export_range(0.5, 3.0, 0.1) var display_size: float = 1.0
## Radius of each word sphere in the cloud (meters)
@export_range(0.01, 0.2, 0.01) var word_scale: float = 0.05

## Color for male-gendered words (man, he, king)
@export var male_color: Color = Color(0.3, 0.5, 1.0)
## Color for female-gendered words (woman, she, queen)
@export var female_color: Color = Color(1.0, 0.4, 0.6)
## Color for trait words (strong, gentle, logical, etc.)
@export var neutral_color: Color = Color(0.5, 0.9, 0.4)
## Color for profession words (doctor, nurse, engineer, etc.)
@export var profession_color: Color = Color(1.0, 0.8, 0.2)

## Current analogy
@export_enum("Gender-Profession", "Gender-Trait", "Algorithmic Redlining") var analogy_type: int = 0:
	set(value):
		analogy_type = clampi(value, 0, 2)
		if is_inside_tree():  # Only update if node is ready
			_show_analogy()

const WORD_DATA = {
	"man": {"pos": Vector3(-0.4, 0.0, 0.0), "category": "gender_m"},
	"woman": {"pos": Vector3(0.4, 0.0, 0.0), "category": "gender_f"},
	"he": {"pos": Vector3(-0.35, 0.1, 0.05), "category": "gender_m"},
	"she": {"pos": Vector3(0.35, 0.1, 0.05), "category": "gender_f"},
	"king": {"pos": Vector3(-0.3, 0.3, 0.1), "category": "gender_m"},
	"queen": {"pos": Vector3(0.3, 0.3, 0.1), "category": "gender_f"},
	"doctor": {"pos": Vector3(-0.2, 0.2, 0.3), "category": "profession"},
	"nurse": {"pos": Vector3(0.25, 0.15, 0.3), "category": "profession"},
	"engineer": {"pos": Vector3(-0.3, 0.1, 0.35), "category": "profession"},
	"teacher": {"pos": Vector3(0.15, 0.2, 0.25), "category": "profession"},
	"CEO": {"pos": Vector3(-0.35, 0.25, 0.4), "category": "profession"},
	"secretary": {"pos": Vector3(0.3, 0.1, 0.35), "category": "profession"},
	"programmer": {"pos": Vector3(-0.25, 0.05, 0.3), "category": "profession"},
	"homemaker": {"pos": Vector3(0.35, 0.0, 0.25), "category": "profession"},
	"strong": {"pos": Vector3(-0.2, -0.2, 0.2), "category": "trait"},
	"gentle": {"pos": Vector3(0.2, -0.2, 0.2), "category": "trait"},
	"logical": {"pos": Vector3(-0.25, -0.1, 0.25), "category": "trait"},
	"emotional": {"pos": Vector3(0.25, -0.15, 0.2), "category": "trait"},
	"aggressive": {"pos": Vector3(-0.3, -0.25, 0.15), "category": "trait"},
	"nurturing": {"pos": Vector3(0.3, -0.2, 0.15), "category": "trait"},
}

const ANALOGIES = {
	0: {
		"title": "GENDER → PROFESSION BIAS",
		"equation": "man - woman + nurse = ?",
		"words": ["man", "woman", "doctor", "nurse", "engineer", "secretary", "CEO", "homemaker"],
		"explanation": "Professions cluster by gender.\nWho was in the training data?"
	},
	1: {
		"title": "GENDER → TRAIT BIAS",
		"equation": "he - she + emotional = ?",
		"words": ["man", "woman", "he", "she", "strong", "gentle", "logical", "emotional"],
		"explanation": "Traits encode stereotypes.\nThe model learned our prejudices."
	},
	2: {
		"title": "ALGORITHMIC REDLINING",
		"equation": "The ZIP code proxy",
		"words": ["man", "woman", "doctor", "nurse", "CEO", "secretary"],
		"explanation": "Bias isn't always explicit.\nProxies encode discrimination.\n(Safiya Noble, Ruha Benjamin)"
	},
}

var _word_nodes: Dictionary = {}
var _word_mm: MultiMesh
var _word_mmi: MultiMeshInstance3D
var _connection_lines: ImmediateMesh
var _connection_instance: MeshInstance3D
var _title_label: Label3D
var _equation_label: Label3D
var _explanation_label: Label3D
var _control_panel: Node3D
var _rotation_enabled: bool = false
var _created_nodes: Array[Node] = []

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_create_base()
	_create_labels()
	_create_word_cloud()
	_create_connections()
	_create_vr_controls()
	_show_analogy()

func _create_base():
	var base = MeshInstance3D.new()
	base.name = "Base"
	
	var box = BoxMesh.new()
	box.size = Vector3(display_size * 1.2, 0.02, display_size * 1.2)
	base.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.12)
	mat.metallic = 0.5
	mat.roughness = 0.5
	base.material_override = mat
	
	base.position = Vector3(0, -0.01, 0)
	add_child(base)
	_created_nodes.append(base)

	# Gender axis indicators
	var axis_label_m = Label3D.new()
	axis_label_m.text = "♂"
	axis_label_m.pixel_size = 0.003
	axis_label_m.font_size = 32
	axis_label_m.position = Vector3(-display_size * 0.5, 0.02, 0)
	axis_label_m.modulate = male_color
	add_child(axis_label_m)
	_created_nodes.append(axis_label_m)

	var axis_label_f = Label3D.new()
	axis_label_f.text = "♀"
	axis_label_f.pixel_size = 0.003
	axis_label_f.font_size = 32
	axis_label_f.position = Vector3(display_size * 0.5, 0.02, 0)
	axis_label_f.modulate = female_color
	add_child(axis_label_f)
	_created_nodes.append(axis_label_f)

func _create_labels():
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.pixel_size = 0.003
	_title_label.font_size = 28
	_title_label.position = Vector3(0, display_size * 0.7, -display_size * 0.5)
	add_child(_title_label)
	_created_nodes.append(_title_label)

	_equation_label = Label3D.new()
	_equation_label.name = "EquationLabel"
	_equation_label.pixel_size = 0.002
	_equation_label.font_size = 24
	_equation_label.position = Vector3(0, display_size * 0.55, -display_size * 0.5)
	_equation_label.modulate = Color(0.9, 0.9, 0.5)
	add_child(_equation_label)
	_created_nodes.append(_equation_label)

	_explanation_label = Label3D.new()
	_explanation_label.name = "ExplanationLabel"
	_explanation_label.pixel_size = 0.0015
	_explanation_label.font_size = 20
	_explanation_label.position = Vector3(0, 0.05, display_size * 0.55)
	_explanation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_explanation_label)
	_created_nodes.append(_explanation_label)

func _create_word_cloud():
	var words = WORD_DATA.keys()
	var count = words.size()

	# Create MultiMesh for all word spheres
	var sphere := SphereMesh.new()
	sphere.radius = word_scale
	sphere.height = word_scale * 2

	_word_mm = MultiMesh.new()
	_word_mm.transform_format = MultiMesh.TRANSFORM_3D
	_word_mm.use_colors = true
	_word_mm.mesh = sphere
	_word_mm.instance_count = count

	# Shared material with per-instance color and subtle emission
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.3

	_word_mmi = MultiMeshInstance3D.new()
	_word_mmi.name = "WordCloud"
	_word_mmi.multimesh = _word_mm
	_word_mmi.material_override = mat
	add_child(_word_mmi)
	_created_nodes.append(_word_mmi)

	# Fill instances and create labels
	for i in count:
		var word = words[i]
		var data = WORD_DATA[word]
		var pos = data.pos * display_size

		var color: Color
		match data.category:
			"gender_m":
				color = male_color
			"gender_f":
				color = female_color
			"profession":
				color = profession_color
			"trait":
				color = neutral_color
			_:
				color = neutral_color

		# Start hidden (zero scale)
		var xf := Transform3D()
		xf.origin = pos
		xf = xf.scaled_local(Vector3.ZERO)
		_word_mm.set_instance_transform(i, xf)
		_word_mm.set_instance_color(i, color)

		var label = Label3D.new()
		label.text = word
		label.pixel_size = 0.0015
		label.font_size = 16
		label.position = pos + Vector3(0, word_scale * 1.5, 0)
		label.visible = false
		label.modulate = color
		add_child(label)
		_created_nodes.append(label)

		_word_nodes[word] = {"index": i, "label": label, "data": data, "pos": pos}

func _create_connections():
	_connection_lines = ImmediateMesh.new()
	_connection_instance = MeshInstance3D.new()
	_connection_instance.name = "ConnectionLines"
	_connection_instance.mesh = _connection_lines
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_connection_instance.material_override = mat
	
	add_child(_connection_instance)
	_created_nodes.append(_connection_instance)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, display_size * 0.6 + 0.12)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	_created_nodes.append(_control_panel)

	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.4, 0.1, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Three analogy buttons
	var labels = ["PROF", "TRAIT", "REDLN"]
	for i in range(3):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "AnalogyButton%d" % i
		btn.position = Vector3(-0.12 + i * 0.12, 0, 0)
		_control_panel.add_child(btn)
		_add_button_label(btn, labels[i])
		
		var idx = i
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): analogy_type = idx)
	
	# Rotate toggle button
	var rotate_btn = PUSH_BUTTON.instantiate()
	rotate_btn.name = "RotateButton"
	rotate_btn.position = Vector3(0.16, 0, 0)
	rotate_btn.rotation_degrees.x = -30
	_control_panel.add_child(rotate_btn)
	_add_button_label(rotate_btn, "ROT")
	var rotate_area = rotate_btn.get_node_or_null("InteractableAreaButton")
	if rotate_area:
		rotate_area.button_pressed.connect(func(_b): _rotation_enabled = not _rotation_enabled)

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 10
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)

func _show_analogy():
	# Hide all: zero-scale transform and hide labels
	for word in _word_nodes.keys():
		var info = _word_nodes[word]
		var xf := Transform3D()
		xf.origin = info.pos
		xf = xf.scaled_local(Vector3.ZERO)
		_word_mm.set_instance_transform(info.index, xf)
		info.label.visible = false

	var analogy = ANALOGIES.get(analogy_type, ANALOGIES[0])

	# Show selected: restore full-scale transform
	for word in analogy.words:
		if _word_nodes.has(word):
			var info = _word_nodes[word]
			var xf := Transform3D()
			xf.origin = info.pos
			_word_mm.set_instance_transform(info.index, xf)
			info.label.visible = true
	
	_title_label.text = analogy.title
	_equation_label.text = analogy.equation
	_explanation_label.text = analogy.explanation
	
	_draw_connections(analogy.words)

func _draw_connections(words: Array):
	_connection_lines.clear_surfaces()
	_connection_lines.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var pairs = [["man", "woman"], ["he", "she"], ["king", "queen"]]
	for pair in pairs:
		if pair[0] in words and pair[1] in words:
			var p1 = WORD_DATA[pair[0]].pos * display_size
			var p2 = WORD_DATA[pair[1]].pos * display_size
			_connection_lines.surface_set_color(Color(0.5, 0.5, 0.5, 0.3))
			_connection_lines.surface_add_vertex(p1)
			_connection_lines.surface_add_vertex(p2)
	
	var professions = ["doctor", "nurse", "engineer", "secretary", "CEO", "homemaker"]
	for prof in professions:
		if prof in words and WORD_DATA.has(prof):
			var prof_pos = WORD_DATA[prof].pos * display_size
			var nearest = "man" if prof_pos.x < 0 else "woman"
			if nearest in words:
				var gender_pos = WORD_DATA[nearest].pos * display_size
				var color = male_color if nearest == "man" else female_color
				color.a = 0.4
				_connection_lines.surface_set_color(color)
				_connection_lines.surface_add_vertex(prof_pos)
				_connection_lines.surface_add_vertex(gender_pos)
	
	_connection_lines.surface_end()

func _process(delta):
	if _rotation_enabled:
		rotation.y = wrapf(rotation.y + delta * 0.3, 0.0, TAU)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				analogy_type = 0
			KEY_2:
				analogy_type = 1
			KEY_3:
				analogy_type = 2
			KEY_SPACE:
				_rotation_enabled = not _rotation_enabled

func _exit_tree():
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()

func apply_grid_config(config_data: Dictionary) -> void:
	pass
