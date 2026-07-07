# Florensky in Production — paraconsistent symbol made operational
#
# Florensky's icon-as-window: an image that holds two ontological positions at once.
# Visualized as a triptych panel where the same form (a sphere) is rendered three ways:
#   - solid (one view says it is here)
#   - hollow (another view says it is not here)
#   - both at once, the holding gesture
# The triptych slowly rotates so the player sees the contradiction from many angles —
# the form doesn't resolve. It works because it doesn't resolve.
#
# @identity: First map where the player sees paraconsistent logic as production-ready.
# @qfep_term: Edge — holding without collapse.

extends Node3D
class_name FlorenskyInProduction

@export var panel_color: Color = Color(0.3, 0.3, 0.35, 1.0)
@export var solid_color: Color = Color(0.9, 0.85, 0.5, 1.0)
@export var hollow_color: Color = Color(0.5, 0.6, 0.85, 1.0)
@export var both_color: Color = Color(0.85, 0.55, 0.95, 1.0)
@export var rotation_speed: float = 0.2

var _triptych_root: Node3D
var _t: float = 0.0


func _ready() -> void:
	_triptych_root = Node3D.new()
	add_child(_triptych_root)
	_build_panel(-0.7, solid_color, "is")
	_build_panel(0.0, both_color, "is/not")
	_build_panel(0.7, hollow_color, "not")
	_build_label()


func apply_grid_config(config_data: Dictionary) -> void:
	pass


func _process(delta: float) -> void:
	_t += delta * rotation_speed
	_triptych_root.rotation.y = _t


func _build_panel(x_off: float, color: Color, label_text: String) -> void:
	# Backing panel.
	var panel := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 0.8, 0.04)
	panel.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = panel_color
	mat.roughness = 0.7
	panel.material_override = mat
	panel.position = Vector3(x_off, 1.0, 0)
	_triptych_root.add_child(panel)
	# Sphere on the panel.
	var sphere := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.16
	s.height = 0.32
	sphere.mesh = s
	var smat := StandardMaterial3D.new()
	smat.albedo_color = color
	smat.emission_enabled = true
	smat.emission = color
	smat.emission_energy_multiplier = 1.5
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Middle panel: half-transparent.
	if x_off == 0.0:
		smat.albedo_color.a = 0.55
	sphere.material_override = smat
	sphere.position = Vector3(x_off, 1.05, 0.06)
	_triptych_root.add_child(sphere)
	# Label.
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 24
	label.modulate = color
	label.position = Vector3(x_off, 0.55, 0.07)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_triptych_root.add_child(label)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "Florensky: in production"
	label.font_size = 28
	label.outline_size = 6
	label.modulate = both_color
	label.position = Vector3(0, 1.85, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
