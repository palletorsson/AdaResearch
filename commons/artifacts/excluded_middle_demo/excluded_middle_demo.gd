# excluded_middle_demo.gd
# Law of excluded middle: P ∨ ¬P
# Brouwer rejected this for non-constructive proofs

extends Node3D
class_name ExcludedMiddleDemo

# @identity
# essence: P ∨ ¬P — the law of excluded middle; Brouwer: "not always!"
# desire: see two glowing spheres (P and ¬P) with the disjunction between them, and toggle Brouwer's rejection
# critical_parameter: show_rejection — flips between classical acceptance and intuitionistic doubt
# triggers: VR slider toggles rejection mode; label text changes to reflect Brouwer's position
# emerges: the discomfort of undecidable propositions — some P genuinely cannot be decided
# needs: VR horizontal slider for rejection toggle [has]
# relationships: unlocks constructive_proof (if LEM is rejected, only constructive proofs survive); unlocks brouwer_choice_sequence; contrasts godel_statement_plaque (unprovable vs undecidable)
# truth: the law of excluded middle is not a law of logic — it is a philosophical commitment about what "true" means

@export var show_rejection: bool = true

var _true_sphere: MeshInstance3D
var _false_sphere: MeshInstance3D
var _label: Label3D
var _slider: Node
var _control_panel: Node3D

func _ready():
	_create_spheres()
	_create_label()
	_setup_controls()

func _create_spheres():
	# True state
	_true_sphere = MeshInstance3D.new()
	var s1 = SphereMesh.new()
	s1.radius = 0.1
	s1.height = 0.2
	_true_sphere.mesh = s1
	_true_sphere.position = Vector3(-0.2, 0, 0)
	var mat1 = StandardMaterial3D.new()
	mat1.albedo_color = Color(0.2, 0.8, 0.3)
	mat1.emission_enabled = true
	mat1.emission = Color(0.1, 0.5, 0.2)
	_true_sphere.material_override = mat1
	add_child(_true_sphere)

	var lbl1 = Label3D.new()
	lbl1.text = "P"
	lbl1.pixel_size = 0.001
	lbl1.font_size = 16
	lbl1.position = Vector3(-0.2, 0.15, 0)
	add_child(lbl1)

	# False state
	_false_sphere = MeshInstance3D.new()
	var s2 = SphereMesh.new()
	s2.radius = 0.1
	s2.height = 0.2
	_false_sphere.mesh = s2
	_false_sphere.position = Vector3(0.2, 0, 0)
	var mat2 = StandardMaterial3D.new()
	mat2.albedo_color = Color(0.8, 0.2, 0.2)
	mat2.emission_enabled = true
	mat2.emission = Color(0.5, 0.1, 0.1)
	_false_sphere.material_override = mat2
	add_child(_false_sphere)

	var lbl2 = Label3D.new()
	lbl2.text = "¬P"
	lbl2.pixel_size = 0.001
	lbl2.font_size = 16
	lbl2.position = Vector3(0.2, 0.15, 0)
	add_child(lbl2)

	# OR symbol
	var or_lbl = Label3D.new()
	or_lbl.text = "∨"
	or_lbl.pixel_size = 0.002
	or_lbl.font_size = 24
	or_lbl.position = Vector3(0, 0, 0)
	add_child(or_lbl)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	if show_rejection:
		_label.text = "LAW OF EXCLUDED MIDDLE\nP ∨ ¬P\n\nBrouwer: \"Not always!\"\nSome P cannot be decided."
	else:
		_label.text = "LAW OF EXCLUDED MIDDLE\nP ∨ ¬P\n\"Either true or false\""
	_label.position = Vector3(0, -0.25, 0)
	add_child(_label)

func _setup_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("EXCLUDED MIDDLE", [
		[{"type": "slider_h", "label": "REJECTION", "default": 1.0}],
	])
	_control_panel.position = Vector3(0, 0.5, 0.6)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	_slider = _control_panel.find_child("Param_0", true, false)
	if _slider and _slider.has_signal("slider_moved"):
		_slider.slider_moved.connect(_on_rejection_changed)
	if _slider and _slider.has_method("set_normalized_value"):
		_slider.set_normalized_value(1.0 if show_rejection else 0.0)

func _on_rejection_changed(_pos = null):
	if _slider and _slider.has_method("get_normalized_value"):
		var val = _slider.get_normalized_value()
		show_rejection = val > 0.5
		_label.queue_free()
		_create_label()

func apply_grid_config(config_data: Dictionary) -> void:
	pass
