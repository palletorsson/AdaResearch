# euclid_postulates_plaque.gd
# Interactive plaque displaying Euclid's five postulates
# Highlights the controversial fifth postulate (parallel postulate)

extends Node3D

class_name EuclidPostulatesPlaque

# @identity
# essence: five axioms; four self-evident, the fifth (parallel postulate) independent and contingent
# desire: cycle through the postulates and feel the fifth one glow differently — it was always the odd one out
# critical_parameter: current_postulate — when it reaches 4 (the fifth), the entire color scheme shifts
# triggers: click/interact cycles postulates; reaching the fifth fires parallel_highlighted signal
# emerges: the dawning suspicion that the fifth postulate is not like the others — it can be denied
# needs: VR click interaction [has via mouse], XR grab interaction [missing]
# relationships: unlocks hyperbolic_surface and elliptic_surface (what happens when you deny the fifth); depends on angle_sum_triangle
# truth: the parallel postulate was assumed for two thousand years — its independence was the first crack in mathematical certainty

signal postulate_selected(index: int)
signal parallel_highlighted

@export var current_postulate: int = 0:
	set(value):
		current_postulate = clampi(value, 0, 4)
		_update_display()

@export var highlight_fifth: bool = true
@export var plaque_size: Vector3 = Vector3(0.8, 1.0, 0.05)

var _xr_active: bool = false
var _plaque_mesh: MeshInstance3D
var _title_label: Label3D
var _text_label: Label3D
var _postulate_labels: Array[Label3D] = []
var _highlight_mesh: MeshInstance3D

const POSTULATES = [
	"I. A straight line can be drawn\nfrom any point to any point.",
	"II. A finite straight line can be\nextended continuously in a line.",
	"III. A circle can be drawn with\nany center and any radius.",
	"IV. All right angles are\nequal to one another.",
	"V. If a line crosses two lines\nand interior angles sum < 180°,\nthe two lines meet on that side.\n\n(The Parallel Postulate)"
]

const POSTULATE_TITLES = [
	"First Postulate",
	"Second Postulate", 
	"Third Postulate",
	"Fourth Postulate",
	"Fifth Postulate — THE PARALLEL POSTULATE"
]

func _ready():
	_xr_active = XRServer.primary_interface != null
	_create_plaque()
	_create_labels()
	_create_highlight()
	_update_display()

func _create_plaque():
	_plaque_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = plaque_size
	_plaque_mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.12, 0.1)
	mat.metallic = 0.1
	mat.roughness = 0.8
	_plaque_mesh.material_override = mat
	add_child(_plaque_mesh)
	
	# Frame
	var frame = MeshInstance3D.new()
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(plaque_size.x + 0.04, plaque_size.y + 0.04, plaque_size.z * 0.5)
	frame.mesh = frame_mesh
	frame.position.z = -plaque_size.z * 0.3
	
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.6, 0.5, 0.3)
	frame_mat.metallic = 0.6
	frame_mat.roughness = 0.4
	frame.material_override = frame_mat
	add_child(frame)

func _create_labels():
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.pixel_size = 0.001
	_title_label.font_size = 24
	_title_label.position = Vector3(0, plaque_size.y * 0.38, plaque_size.z * 0.51)
	_title_label.modulate = Color(0.9, 0.85, 0.7)
	add_child(_title_label)
	
	_text_label = Label3D.new()
	_text_label.name = "TextLabel"
	_text_label.pixel_size = 0.001
	_text_label.font_size = 18
	_text_label.position = Vector3(0, 0, plaque_size.z * 0.51)
	_text_label.modulate = Color(0.85, 0.82, 0.75)
	add_child(_text_label)
	
	# Postulate indicators (I II III IV V)
	var indicator_y = -plaque_size.y * 0.35
	for i in range(5):
		var lbl = Label3D.new()
		lbl.pixel_size = 0.001
		lbl.font_size = 16
		lbl.text = ["I", "II", "III", "IV", "V"][i]
		lbl.position = Vector3(-0.3 + i * 0.15, indicator_y, plaque_size.z * 0.51)
		lbl.modulate = Color(0.5, 0.5, 0.5)
		add_child(lbl)
		_postulate_labels.append(lbl)

func _create_highlight():
	_highlight_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.12, 0.04, 0.01)
	_highlight_mesh.mesh = box
	_highlight_mesh.position.y = -plaque_size.y * 0.35
	_highlight_mesh.position.z = plaque_size.z * 0.52
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.2, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.2)
	mat.emission_energy_multiplier = 0.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_mesh.material_override = mat
	add_child(_highlight_mesh)

func _update_display():
	if not is_inside_tree():
		return
	
	_title_label.text = POSTULATE_TITLES[current_postulate]
	_text_label.text = POSTULATES[current_postulate]
	
	# Update highlight position
	_highlight_mesh.position.x = -0.3 + current_postulate * 0.15
	
	# Color the fifth postulate differently
	var is_fifth = current_postulate == 4
	if is_fifth and highlight_fifth:
		_title_label.modulate = Color(1.0, 0.7, 0.3)
		_text_label.modulate = Color(1.0, 0.9, 0.7)
		var mat = _highlight_mesh.material_override as StandardMaterial3D
		mat.albedo_color = Color(1.0, 0.4, 0.2, 0.9)
		mat.emission = Color(1.0, 0.4, 0.2)
		parallel_highlighted.emit()
	else:
		_title_label.modulate = Color(0.9, 0.85, 0.7)
		_text_label.modulate = Color(0.85, 0.82, 0.75)
		var mat = _highlight_mesh.material_override as StandardMaterial3D
		mat.albedo_color = Color(1.0, 0.8, 0.2, 0.8)
		mat.emission = Color(1.0, 0.8, 0.2)
	
	# Update indicator colors
	for i in range(5):
		if i == current_postulate:
			_postulate_labels[i].modulate = Color(1.0, 1.0, 1.0)
		elif i == 4 and highlight_fifth:
			_postulate_labels[i].modulate = Color(1.0, 0.5, 0.3)
		else:
			_postulate_labels[i].modulate = Color(0.5, 0.5, 0.5)
	
	postulate_selected.emit(current_postulate)

func next_postulate():
	current_postulate = (current_postulate + 1) % 5

func previous_postulate():
	current_postulate = (current_postulate + 4) % 5

func _input(event):
	if _xr_active:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			next_postulate()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			previous_postulate()

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
