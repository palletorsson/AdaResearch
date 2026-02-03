# bias_visualizer.gd
# Demonstrates bias in word embeddings
# Joy Buolamwini's "Coded Gaze" made visible

extends Node3D

class_name BiasVisualizer

## Display settings
@export var display_size: float = 1.0
@export var word_scale: float = 0.05

## Colors
@export var male_color: Color = Color(0.3, 0.5, 1.0)
@export var female_color: Color = Color(1.0, 0.4, 0.6)
@export var neutral_color: Color = Color(0.5, 0.9, 0.4)
@export var profession_color: Color = Color(1.0, 0.8, 0.2)

## Current analogy
@export_enum("Gender-Profession", "Gender-Trait", "Race-Crime", "Custom") var analogy_type: int = 0:
	set(value):
		analogy_type = value
		_show_analogy()

# Word data: simplified 3D positions showing bias relationships
# Based on real Word2Vec/GloVe patterns
const WORD_DATA = {
	# Gender axis
	"man": {"pos": Vector3(-0.4, 0.0, 0.0), "category": "gender_m"},
	"woman": {"pos": Vector3(0.4, 0.0, 0.0), "category": "gender_f"},
	"he": {"pos": Vector3(-0.35, 0.1, 0.05), "category": "gender_m"},
	"she": {"pos": Vector3(0.35, 0.1, 0.05), "category": "gender_f"},
	"king": {"pos": Vector3(-0.3, 0.3, 0.1), "category": "gender_m"},
	"queen": {"pos": Vector3(0.3, 0.3, 0.1), "category": "gender_f"},
	
	# Professions (biased positions)
	"doctor": {"pos": Vector3(-0.2, 0.2, 0.3), "category": "profession"},  # Closer to male
	"nurse": {"pos": Vector3(0.25, 0.15, 0.3), "category": "profession"},   # Closer to female
	"engineer": {"pos": Vector3(-0.3, 0.1, 0.35), "category": "profession"},
	"teacher": {"pos": Vector3(0.15, 0.2, 0.25), "category": "profession"},
	"CEO": {"pos": Vector3(-0.35, 0.25, 0.4), "category": "profession"},
	"secretary": {"pos": Vector3(0.3, 0.1, 0.35), "category": "profession"},
	"programmer": {"pos": Vector3(-0.25, 0.05, 0.3), "category": "profession"},
	"homemaker": {"pos": Vector3(0.35, 0.0, 0.25), "category": "profession"},
	
	# Traits (biased)
	"strong": {"pos": Vector3(-0.2, -0.2, 0.2), "category": "trait"},
	"gentle": {"pos": Vector3(0.2, -0.2, 0.2), "category": "trait"},
	"logical": {"pos": Vector3(-0.25, -0.1, 0.25), "category": "trait"},
	"emotional": {"pos": Vector3(0.25, -0.15, 0.2), "category": "trait"},
	"aggressive": {"pos": Vector3(-0.3, -0.25, 0.15), "category": "trait"},
	"nurturing": {"pos": Vector3(0.3, -0.2, 0.15), "category": "trait"},
}

# Analogies to demonstrate
const ANALOGIES = {
	0: {  # Gender-Profession
		"title": "GENDER → PROFESSION BIAS",
		"equation": "man - woman + nurse = ?",
		"expected": "doctor",
		"actual": "doctor (biased)",
		"words": ["man", "woman", "doctor", "nurse", "engineer", "secretary", "CEO", "homemaker"],
		"explanation": "Professions cluster by gender.\nWho was in the training data?"
	},
	1: {  # Gender-Trait
		"title": "GENDER → TRAIT BIAS",
		"equation": "he - she + emotional = ?",
		"expected": "logical",
		"actual": "logical (stereotyped)",
		"words": ["man", "woman", "he", "she", "strong", "gentle", "logical", "emotional"],
		"explanation": "Traits encode stereotypes.\nThe model learned our prejudices."
	},
	2: {  # Race-Crime (sensitive)
		"title": "ALGORITHMIC REDLINING",
		"equation": "The ZIP code proxy",
		"expected": "neutral",
		"actual": "discrimination",
		"words": ["man", "woman", "doctor", "nurse", "CEO", "secretary"],
		"explanation": "Bias isn't always explicit.\nProxies encode discrimination.\n(Safiya Noble, Ruha Benjamin)"
	},
}

var _word_nodes: Dictionary = {}
var _connection_lines: ImmediateMesh
var _connection_instance: MeshInstance3D
var _title_label: Label3D
var _equation_label: Label3D
var _explanation_label: Label3D

func _ready():
	_create_base()
	_create_labels()
	_create_word_cloud()
	_create_connections()
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
	
	# Gender axis indicator
	var axis_label_m = Label3D.new()
	axis_label_m.text = "♂"
	axis_label_m.pixel_size = 0.003
	axis_label_m.font_size = 32
	axis_label_m.position = Vector3(-display_size * 0.5, 0.02, 0)
	axis_label_m.modulate = male_color
	add_child(axis_label_m)
	
	var axis_label_f = Label3D.new()
	axis_label_f.text = "♀"
	axis_label_f.pixel_size = 0.003
	axis_label_f.font_size = 32
	axis_label_f.position = Vector3(display_size * 0.5, 0.02, 0)
	axis_label_f.modulate = female_color
	add_child(axis_label_f)

func _create_labels():
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.pixel_size = 0.003
	_title_label.font_size = 28
	_title_label.position = Vector3(0, display_size * 0.7, -display_size * 0.5)
	add_child(_title_label)
	
	_equation_label = Label3D.new()
	_equation_label.name = "EquationLabel"
	_equation_label.pixel_size = 0.002
	_equation_label.font_size = 24
	_equation_label.position = Vector3(0, display_size * 0.55, -display_size * 0.5)
	_equation_label.modulate = Color(0.9, 0.9, 0.5)
	add_child(_equation_label)
	
	_explanation_label = Label3D.new()
	_explanation_label.name = "ExplanationLabel"
	_explanation_label.pixel_size = 0.0015
	_explanation_label.font_size = 20
	_explanation_label.position = Vector3(0, 0.05, display_size * 0.55)
	_explanation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_explanation_label)
	
	var hint = Label3D.new()
	hint.name = "ControlsHint"
	hint.pixel_size = 0.001
	hint.font_size = 18
	hint.text = "1-3 Analogies | Space Rotate"
	hint.position = Vector3(0, -0.03, display_size * 0.6)
	hint.modulate = Color(0.5, 0.5, 0.5)
	add_child(hint)

func _create_word_cloud():
	for word in WORD_DATA.keys():
		var data = WORD_DATA[word]
		
		# Create sphere for word
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = word_scale
		sphere_mesh.height = word_scale * 2
		
		var node = MeshInstance3D.new()
		node.name = "Word_" + word
		node.mesh = sphere_mesh
		
		# Color based on category
		var mat = StandardMaterial3D.new()
		match data.category:
			"gender_m":
				mat.albedo_color = male_color
			"gender_f":
				mat.albedo_color = female_color
			"profession":
				mat.albedo_color = profession_color
			"trait":
				mat.albedo_color = neutral_color
		
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 0.3
		node.material_override = mat
		
		node.position = data.pos * display_size
		node.visible = false
		add_child(node)
		
		# Label for word
		var label = Label3D.new()
		label.text = word
		label.pixel_size = 0.0015
		label.font_size = 16
		label.position = data.pos * display_size + Vector3(0, word_scale * 1.5, 0)
		label.visible = false
		label.modulate = mat.albedo_color
		add_child(label)
		
		_word_nodes[word] = {"sphere": node, "label": label, "data": data}

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

func _show_analogy():
	# Hide all words first
	for word in _word_nodes.keys():
		_word_nodes[word].sphere.visible = false
		_word_nodes[word].label.visible = false
	
	# Get current analogy data
	var analogy = ANALOGIES.get(analogy_type, ANALOGIES[0])
	
	# Show relevant words
	for word in analogy.words:
		if _word_nodes.has(word):
			_word_nodes[word].sphere.visible = true
			_word_nodes[word].label.visible = true
	
	# Update labels
	_title_label.text = analogy.title
	_equation_label.text = analogy.equation
	_explanation_label.text = analogy.explanation
	
	# Draw connections
	_draw_connections(analogy.words)

func _draw_connections(words: Array):
	_connection_lines.clear_surfaces()
	_connection_lines.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# Connect gender pairs
	var pairs = [["man", "woman"], ["he", "she"], ["king", "queen"]]
	for pair in pairs:
		if pair[0] in words and pair[1] in words:
			var p1 = WORD_DATA[pair[0]].pos * display_size
			var p2 = WORD_DATA[pair[1]].pos * display_size
			_connection_lines.surface_set_color(Color(0.5, 0.5, 0.5, 0.3))
			_connection_lines.surface_add_vertex(p1)
			_connection_lines.surface_add_vertex(p2)
	
	# Draw bias lines (professions to gender axis)
	var professions = ["doctor", "nurse", "engineer", "secretary", "CEO", "homemaker"]
	for prof in professions:
		if prof in words and WORD_DATA.has(prof):
			var prof_pos = WORD_DATA[prof].pos * display_size
			# Line to nearest gender word
			var nearest = "man" if prof_pos.x < 0 else "woman"
			if nearest in words:
				var gender_pos = WORD_DATA[nearest].pos * display_size
				var color = male_color if nearest == "man" else female_color
				color.a = 0.4
				_connection_lines.surface_set_color(color)
				_connection_lines.surface_add_vertex(prof_pos)
				_connection_lines.surface_add_vertex(gender_pos)
	
	_connection_lines.surface_end()

var _rotation_enabled: bool = false

func _process(delta):
	if _rotation_enabled:
		rotation.y += delta * 0.3

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
