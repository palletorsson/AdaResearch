# @identity
# essence: sign != signified -- a procedural pipe mesh with label saying this is not a pipe
# desire: a pipe you can see and inspect but that insists it is not what it appears to be
# critical_parameter: presence -- which of the two terms (the pipe, the words) is actually in the frame; layers array -- representation levels as strata
# triggers: static display; player proximity reveals layer explanations; contradiction is always present
# emerges: the gap between name and thing becomes tangible -- every data structure is a Magritte painting
# needs: procedural pipe mesh [has]; label system [has]; layer explanation text [has]; VR interaction [missing]
# relationships: foundational for artmathematics sequence; sign/signified gap extends to all formal systems
# truth: representation is a gap pretending to be a bridge -- computation runs on signs detached from signified.

# magritte_pipe.gd
# "Ceci n'est pas une pipe" — This is not a pipe
# René Magritte's 1929 painting that exposes the gap between signifier and signified
#
# The representation is not the thing.
# The map is not the territory.
# The model is not the world.
#
# In QFEP terms: F (free energy / predictive model) ≠ reality
# There is always a gap — and that gap is where queerness lives.

extends Node3D

class_name MagrittePipe

signal representation_questioned()
signal layer_revealed(layer_name: String)

## Pipe visual parameters
@export var pipe_color: Color = Color(0.4, 0.25, 0.15)
@export var frame_color: Color = Color(0.7, 0.6, 0.4)
@export var background_color: Color = Color(0.9, 0.88, 0.82)

## Show the classic text
@export var show_text: bool = true

## Current layer of representation
@export var current_layer: int = 0

## DNA axis — what is actually standing inside the frame.
## The whole subject of this object is the relation between a thing and its
## name, so the only honest axis is which of the two is present. Not a mounting
## style: each value is a different sentence about the gap.
##   pipe_and_words     — the painting: a pipe, and under it the denial. The
##                        contradiction fully staged, both terms in the room.
##   pipe_only          — the picture with no caption. The treachery is still
##                        there; nothing on the canvas admits it.
##   words_only         — the denial over an empty canvas. A sign refusing a
##                        referent that was never brought. The purest case:
##                        "this is not a pipe" is TRUE and says nothing.
##   empty_frame        — neither. The support alone: representation with
##                        nothing represented, still hanging on the wall.
##   picture_of_picture — Les Deux Mystères, 1966: the painting reappears inside
##                        itself on a smaller canvas, with the pipe floating
##                        outside it. The regress refuses to bottom out.
@export_enum("pipe_and_words", "pipe_only", "words_only", "empty_frame", "picture_of_picture") var presence: String = "pipe_and_words"

## The same list as the @export_enum above. The enum is what the editor and the
## declaration gate read; this is what an incoming map token is checked against.
const PRESENCES: Array[String] = ["pipe_and_words", "pipe_only", "words_only", "empty_frame", "picture_of_picture"]

## Which values put a pipe on the canvas, and which put the sentence there.
const PRESENCE_HAS_PIPE: Array[String] = ["pipe_and_words", "pipe_only", "picture_of_picture"]
const PRESENCE_HAS_WORDS: Array[String] = ["pipe_and_words", "words_only", "picture_of_picture"]

# The layers of representation
var layers: Array[String] = [
	"Ceci n'est pas une pipe.",           # This is not a pipe
	"Ceci n'est pas une image.",          # This is not an image
	"Ceci n'est pas une représentation.", # This is not a representation
	"Ceci n'est pas un signe.",           # This is not a sign
	"Ceci n'est pas.",                    # This is not.
	"...",                                 # ...
]

var layer_explanations: Array[String] = [
	"The painting of a pipe is not a pipe.",
	"The digital model of the painting is not the painting.",
	"The concept of representation is not representation itself.",
	"The sign that points is not what it points to.",
	"Negation itself is a representation.",
	"The gap between sign and signified is irreducible.",
]

# Internal
var _frame: MeshInstance3D
var _canvas: MeshInstance3D
var _pipe_model: Node3D
var _inner_picture: Node3D
var _text_label: Label3D
var _explanation_label: Label3D
var _interactable: Area3D
var _animation_time: float = 0.0
var _pipe_base_y: float = 0.08
var _built: bool = false

func _ready() -> void:
	_build_body()
	# The click target is the frame, not the contents, so it survives every value
	# and is built once — outside _build_body, which is what a rebuild replaces.
	_create_interactable()
	_update_display()
	_built = true
	print("MagrittePipe: Ready — 'The map is not the territory'")

func _build_body() -> void:
	_create_frame()
	_create_canvas()
	if presence in PRESENCE_HAS_PIPE:
		_create_pipe()
	if presence == "picture_of_picture":
		_create_inner_picture()
	_create_text()

func _create_frame() -> void:
	_frame = MeshInstance3D.new()
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(0.8, 0.6, 0.05)
	_frame.mesh = frame_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = frame_color
	mat.metallic = 0.1
	mat.roughness = 0.8
	_frame.material_override = mat
	
	add_child(_frame)

func _create_canvas() -> void:
	_canvas = MeshInstance3D.new()
	var canvas_mesh = BoxMesh.new()
	canvas_mesh.size = Vector3(0.7, 0.5, 0.01)
	_canvas.mesh = canvas_mesh
	_canvas.position.z = 0.03
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = background_color
	mat.metallic = 0.0
	mat.roughness = 1.0
	_canvas.material_override = mat
	
	add_child(_canvas)

func _create_pipe() -> void:
	_pipe_model = _make_pipe_body()
	_pipe_model.name = "PipeModel"
	if presence == "picture_of_picture":
		# The pipe floats clear of the inner canvas below it — the 1966 version,
		# where the painted pipe and the pipe outside the painting share a wall.
		_pipe_base_y = 0.155
		_pipe_model.position = Vector3(0, _pipe_base_y, 0.055)
		_pipe_model.scale = Vector3(0.8, 0.8, 0.8)
	else:
		_pipe_base_y = 0.08
		_pipe_model.position = Vector3(0, _pipe_base_y, 0.04)
	add_child(_pipe_model)

func _make_pipe_body() -> Node3D:
	var body := Node3D.new()

	# Bowl of pipe
	var bowl = MeshInstance3D.new()
	var bowl_mesh = CylinderMesh.new()
	bowl_mesh.top_radius = 0.04
	bowl_mesh.bottom_radius = 0.035
	bowl_mesh.height = 0.08
	bowl.mesh = bowl_mesh
	bowl.rotation.x = PI * 0.1
	bowl.position = Vector3(-0.12, 0, 0)
	
	var pipe_mat = StandardMaterial3D.new()
	pipe_mat.albedo_color = pipe_color
	pipe_mat.metallic = 0.2
	pipe_mat.roughness = 0.6
	bowl.material_override = pipe_mat
	body.add_child(bowl)
	
	# Stem of pipe
	var stem = MeshInstance3D.new()
	var stem_mesh = CylinderMesh.new()
	stem_mesh.top_radius = 0.012
	stem_mesh.bottom_radius = 0.015
	stem_mesh.height = 0.25
	stem.mesh = stem_mesh
	stem.rotation.z = PI * 0.5
	stem.position = Vector3(0.02, -0.02, 0)
	stem.material_override = pipe_mat
	body.add_child(stem)
	
	# Mouthpiece
	var mouth = MeshInstance3D.new()
	var mouth_mesh = CylinderMesh.new()
	mouth_mesh.top_radius = 0.008
	mouth_mesh.bottom_radius = 0.012
	mouth_mesh.height = 0.06
	mouth.mesh = mouth_mesh
	mouth.rotation.z = PI * 0.5 + PI * 0.15
	mouth.position = Vector3(0.15, -0.04, 0)
	mouth.material_override = pipe_mat
	body.add_child(mouth)

	return body

func _create_inner_picture() -> void:
	# The painting hung inside itself. A smaller frame and canvas sunk into the
	# big one, carrying the pipe again at scale — so the question "which of these
	# is the pipe" gets one more turn and still has no floor.
	_inner_picture = Node3D.new()
	_inner_picture.name = "PictureOfPicture"
	_inner_picture.position = Vector3(0, -0.055, 0.042)

	var inner_frame := MeshInstance3D.new()
	var inner_frame_mesh := BoxMesh.new()
	inner_frame_mesh.size = Vector3(0.34, 0.26, 0.012)
	inner_frame.mesh = inner_frame_mesh
	var f_mat := StandardMaterial3D.new()
	f_mat.albedo_color = frame_color.darkened(0.18)
	f_mat.metallic = 0.1
	f_mat.roughness = 0.8
	inner_frame.material_override = f_mat
	_inner_picture.add_child(inner_frame)

	var inner_canvas := MeshInstance3D.new()
	var inner_canvas_mesh := BoxMesh.new()
	inner_canvas_mesh.size = Vector3(0.29, 0.21, 0.006)
	inner_canvas.mesh = inner_canvas_mesh
	inner_canvas.position = Vector3(0, 0, 0.008)
	var c_mat := StandardMaterial3D.new()
	c_mat.albedo_color = background_color.darkened(0.07)
	c_mat.metallic = 0.0
	c_mat.roughness = 1.0
	inner_canvas.material_override = c_mat
	_inner_picture.add_child(inner_canvas)

	var small_pipe := _make_pipe_body()
	small_pipe.name = "InnerPipe"
	small_pipe.scale = Vector3(0.42, 0.42, 0.42)
	small_pipe.position = Vector3(0, 0.035, 0.016)
	_inner_picture.add_child(small_pipe)

	add_child(_inner_picture)

func _create_text() -> void:
	if not show_text:
		return

	# Main text (the famous phrase). `pipe_only` and `empty_frame` are the two
	# values that withhold it — the canvas keeps its picture, or keeps nothing,
	# and says neither way what it is not.
	if presence in PRESENCE_HAS_WORDS:
		_text_label = Label3D.new()
		_text_label.text = layers[0]
		if presence == "picture_of_picture":
			# The inscription belongs to the INNER painting: smaller, and sitting
			# forward of the inner canvas so the small frame does not eat it.
			_text_label.font_size = 14
			_text_label.position = Vector3(0, -0.115, 0.060)
		else:
			_text_label.font_size = 28
			_text_label.position = Vector3(0, -0.15, 0.04)
		_text_label.pixel_size = 0.001
		_text_label.modulate = Color(0.15, 0.12, 0.1)
		_text_label.outline_size = 0
		_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(_text_label)


	# Explanation (outside frame)
	_explanation_label = Label3D.new()
	_explanation_label.text = layer_explanations[0]
	_explanation_label.font_size = 18
	_explanation_label.position = Vector3(0, -0.4, 0)
	_explanation_label.pixel_size = 0.001
	_explanation_label.modulate = Color(0.5, 0.5, 0.5, 0.8)
	_explanation_label.outline_size = 3
	_explanation_label.outline_modulate = Color.BLACK
	_explanation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_explanation_label.width = 600
	_explanation_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_explanation_label)

func _create_interactable() -> void:
	_interactable = Area3D.new()
	_interactable.name = "InteractableArea"
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(0.8, 0.6, 0.1)
	collision.shape = shape
	_interactable.add_child(collision)
	
	_interactable.input_event.connect(_on_input_event)
	_interactable.input_ray_pickable = true
	
	add_child(_interactable)

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance_layer()

func _process(delta: float) -> void:
	_animation_time += delta
	
	# Subtle floating animation for the pipe. The base height used to be written
	# here as a literal 0.08, which would have yanked the picture_of_picture pipe
	# down onto the inner canvas on the first frame — the float now hovers around
	# wherever _create_pipe actually put it.
	if _pipe_model:
		_pipe_model.position.y = _pipe_base_y + sin(_animation_time * 0.8) * 0.005
	
	# On higher layers, the pipe becomes more abstract
	if current_layer >= 3 and _pipe_model:
		var alpha = 1.0 - (current_layer - 3) * 0.25
		for child in _pipe_model.get_children():
			if child is MeshInstance3D:
				var mat = child.material_override as StandardMaterial3D
				if mat:
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mat.albedo_color.a = max(0.1, alpha)

func _update_display() -> void:
	if _text_label and current_layer < layers.size():
		_text_label.text = layers[current_layer]
	
	if _explanation_label and current_layer < layer_explanations.size():
		_explanation_label.text = layer_explanations[current_layer]
	
	emit_signal("layer_revealed", layers[current_layer] if current_layer < layers.size() else "...")

func advance_layer() -> void:
	current_layer = (current_layer + 1) % layers.size()
	_update_display()
	emit_signal("representation_questioned")
	
	print("MagrittePipe: Layer %d — '%s'" % [current_layer, layers[current_layer]])

func normalise_presence(raw: String, fallback: String) -> String:
	# An unrecognised string keeps whatever we already had rather than silently
	# dropping to the default: a mistyped map token should not look like a
	# working axis that happens to render the stock object.
	return raw if raw in PRESENCES else fallback

func apply_grid_config(config_data: Dictionary) -> void:
	# Deliberately narrow. This artifact had no apply_grid_config at all, so a
	# blanket `for key in config_data: if key in self` would newly expose every
	# inherited Node3D property (rotation, scale, visible) to whatever the grid
	# happens to pass — new behaviour for two shipped placements. Only the axis
	# is accepted; a config without it is a no-op, exactly as before.
	if not config_data.has("presence"):
		return
	var before: String = presence
	presence = normalise_presence(str(config_data["presence"]), before)
	# Rebuild ONLY on a real change, and only once _ready has built. Guarding on
	# _built is what keeps a config call during scene setup from tearing down
	# geometry that does not exist yet.
	if presence == before or not _built:
		return
	_rebuild_body()

func _rebuild_body() -> void:
	for old in [_frame, _canvas, _pipe_model, _inner_picture, _text_label, _explanation_label]:
		if is_instance_valid(old):
			if old.get_parent() != null:
				old.get_parent().remove_child(old)
			old.queue_free()
	_frame = null
	_canvas = null
	_pipe_model = null
	_inner_picture = null
	_text_label = null
	_explanation_label = null
	_build_body()
	_update_display()
	print("MagrittePipe: presence=%s" % presence)

func reset() -> void:
	current_layer = 0
	_update_display()
	
	# Reset pipe visibility
	if _pipe_model:
		for child in _pipe_model.get_children():
			if child is MeshInstance3D:
				var mat = child.material_override as StandardMaterial3D
				if mat:
					mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					mat.albedo_color.a = 1.0
