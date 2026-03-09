extends Node3D

class_name CelestialBody

@export var body_name: String = "Body"
@export var body_mass: float = 1000.0
@export var body_color: Color = Color.WHITE
@export var initial_position: Vector3 = Vector3.ZERO
@export var initial_velocity: Vector3 = Vector3.ZERO

var velocity: Vector3
var current_force: Vector3
var trail_points: PackedVector3Array = PackedVector3Array()
var max_trail_points: int = 200
var trail_material: StandardMaterial3D

# Single mesh instances instead of per-frame CSG creation
var _body_mesh: MeshInstance3D
var _trail_mesh: MeshInstance3D
var _trail_immediate: ImmediateMesh
var _label: Label3D


func _ready():
	_create_body_mesh()
	_create_trail_renderer()


func _create_body_mesh():
	# Use MeshInstance3D + SphereMesh instead of CSGSphere3D (much lighter)
	_body_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 16
	sphere.rings = 8
	_body_mesh.mesh = sphere

	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.emission_enabled = true
	mat.emission = body_color * 0.3
	_body_mesh.material_override = mat

	add_child(_body_mesh)

	# Label
	_label = Label3D.new()
	_label.text = body_name
	_label.font_size = 24
	_label.pixel_size = 0.1
	_label.position = Vector3(0, 1, 0)
	add_child(_label)


func _create_trail_renderer():
	## A single ImmediateMesh that draws the entire trail as line strips.
	## Uses 1 RID total instead of 200+ CSGBox3D nodes per frame.
	trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = body_color
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.albedo_color.a = 0.7
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_material.no_depth_test = false

	_trail_immediate = ImmediateMesh.new()
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.mesh = _trail_immediate
	_trail_mesh.material_override = trail_material
	# Add to Trails node if it exists, otherwise add as sibling
	var trails_node: Node = null
	var parent := get_parent()
	if parent:
		var grandparent := parent.get_parent()
		if grandparent:
			trails_node = grandparent.get_node_or_null("Trails")
	if trails_node:
		trails_node.add_child(_trail_mesh)
	else:
		add_child(_trail_mesh)


func initialize():
	position = initial_position
	velocity = initial_velocity
	current_force = Vector3.ZERO
	trail_points.clear()
	_rebuild_trail_mesh()


func apply_force(force: Vector3):
	current_force += force


func update_physics(delta: float):
	velocity += current_force / body_mass * delta
	position += velocity * delta
	current_force = Vector3.ZERO


func update_trail():
	# Record position
	trail_points.append(position)
	if trail_points.size() > max_trail_points:
		trail_points = trail_points.slice(1)

	# Rebuild the single ImmediateMesh with line strip geometry
	_rebuild_trail_mesh()


func _rebuild_trail_mesh():
	if _trail_immediate == null:
		return
	_trail_immediate.clear_surfaces()
	if trail_points.size() < 2:
		return

	_trail_immediate.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in trail_points.size():
		# Fade alpha along trail (older = more transparent)
		var t: float = float(i) / float(trail_points.size() - 1)
		_trail_immediate.surface_set_color(Color(body_color.r, body_color.g, body_color.b, t * 0.7))
		_trail_immediate.surface_add_vertex(trail_points[i])
	_trail_immediate.surface_end()


func set_trail_color(color: Color):
	body_color = color
	if trail_material:
		trail_material.albedo_color = Color(color.r, color.g, color.b, 0.7)
	if _body_mesh and _body_mesh.material_override:
		_body_mesh.material_override.albedo_color = color
		_body_mesh.material_override.emission = color * 0.3


func reset_to_initial():
	position = initial_position
	velocity = initial_velocity
	current_force = Vector3.ZERO
	trail_points.clear()
	_rebuild_trail_mesh()
