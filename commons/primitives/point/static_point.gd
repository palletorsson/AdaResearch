# static_point.gd - Non-pickable point marker that shows position
# Cannot be grabbed by hands or captured by gravity gun
extends Node3D

# @identity
# essence: a location in space — coordinates (x, y, z) with no size, no volume
# desire: learner feels that a point is pure position, nothing more, nothing else
# critical_parameter: show_label — whether coordinate text billboard appears
# triggers: nothing — entirely still, waiting to be observed
# emerges: the realisation that all geometry begins from zero-dimensional position
# needs: [missing VR controls — observation only, non-grabbable by design]
# relationships: prerequisite for line; contrasts with interactive_point_origin (grabbable version)
# truth: position exists independently of any object occupying it


# Spine-corridor contract — see doc/SPINE_HINTS_CONTRACT.md
func spine_hints() -> Dictionary:
	return {
		"role":         "supporting",
		"footprint":    Vector2i(1, 1),
		"approach":     "any",
		"reading_dist": 1.5,
		"height":       1.0,
		"budget_ms":    0.3,
		"tags":         ["vector", "static", "isolated"],
	}


@export var point_color: Color = Color(0.0, 1.0, 1.0, 1.0)  # Cyan default
@export var point_radius: float = 0.04
@export var show_label: bool = true
@export var label_offset: Vector3 = Vector3(0, 0.1, 0)

var position_label: Label3D
var mesh_instance: MeshInstance3D

func _ready():
	# Add to no_gravity_gun group so it won't be picked up
	add_to_group("no_gravity_gun")
	_setup_mesh()
	if show_label:
		_setup_label()

func _setup_mesh():
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "PointMesh"

	var sphere = SphereMesh.new()
	sphere.radius = point_radius
	sphere.height = point_radius * 2
	sphere.radial_segments = 16
	sphere.rings = 8
	mesh_instance.mesh = sphere

	var material = StandardMaterial3D.new()
	material.albedo_color = point_color
	material.emission_enabled = true
	material.emission = point_color
	material.emission_energy_multiplier = 1.5
	mesh_instance.material_override = material

	add_child(mesh_instance)

func _setup_label():
	position_label = Label3D.new()
	position_label.name = "PositionLabel"
	position_label.position = label_offset
	position_label.font_size = 14
	position_label.modulate = Color.YELLOW
	position_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	position_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	position_label.outline_size = 2
	position_label.outline_modulate = Color.BLACK
	add_child(position_label)

func _process(_delta):
	if position_label and show_label:
		position_label.text = "(%.1f, %.1f, %.1f)" % [global_position.x, global_position.y, global_position.z]

func set_color(color: Color):
	point_color = color
	if mesh_instance and mesh_instance.material_override:
		var mat = mesh_instance.material_override as StandardMaterial3D
		mat.albedo_color = color
		mat.emission = color

func set_label_visible(visible: bool):
	show_label = visible
	if position_label:
		position_label.visible = visible
