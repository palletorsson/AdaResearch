# brouwer_choice_sequence.gd
# Brouwer's free choice sequences - unfinished infinite objects

extends Node3D
class_name BrouwerChoiceSequence

# @identity
# essence: a₁, a₂, a₃, ... , ?, ? — each term chosen freely, never completed
# desire: feel the openness of an infinite sequence that is always unfinished
# critical_parameter: time — the sequence unfolds perpetually, dots gently bobbing
# triggers: each dot fades in opacity toward the future; the question mark asserts genuine openness
# emerges: the intuition that infinity is a process, not a completed object
# needs: VR controls [missing] — could add ability to "choose" the next term
# relationships: depends on excluded_middle_demo (LEM rejection enables choice sequences); contrasts constructive_proof (witness vs process)
# truth: an infinite object that is never finished is not incomplete — it is the only honest way to talk about infinity

var _dots: Array[MeshInstance3D] = []
var _label: Label3D
var _time: float = 0.0

func _ready():
	_create_sequence()
	_create_label()

func _create_sequence():
	# Create dots representing an unfolding sequence
	for i in range(8):
		var dot = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.03
		sphere.height = 0.06
		dot.mesh = sphere
		dot.position = Vector3(-0.35 + i * 0.1, 0, 0)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.7, 1.0, 1.0 - i * 0.1)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		dot.material_override = mat
		add_child(dot)
		_dots.append(dot)
	
	# Ellipsis
	var ellipsis = Label3D.new()
	ellipsis.text = "..."
	ellipsis.pixel_size = 0.002
	ellipsis.font_size = 20
	ellipsis.position = Vector3(0.5, 0, 0)
	add_child(ellipsis)
	
	# Question mark at end
	var q = Label3D.new()
	q.text = "?"
	q.pixel_size = 0.002
	q.font_size = 24
	q.position = Vector3(0.65, 0, 0)
	q.modulate = Color(1, 0.8, 0.3)
	add_child(q)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 11
	_label.text = "CHOICE SEQUENCE\n\nInfinite, but never finished.\nEach term chosen freely.\nThe future is genuinely open."
	_label.position = Vector3(0, -0.2, 0)
	add_child(_label)

func _process(delta):
	_time += delta
	for i in range(_dots.size()):
		var dot = _dots[i]
		dot.position.y = sin(_time * 2.0 + i * 0.5) * 0.02


# --- Grid Integration ---
func apply_grid_config(config_data: Dictionary) -> void:
	pass
