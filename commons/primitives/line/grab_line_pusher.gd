extends GrabLine
class_name GrabLinePusher

# @identity
# essence: a GrabLine with a StaticBody3D collider welded to its tip — the endpoint gains physical presence and can shove rigid bodies in the scene
# desire: to make an abstract endpoint consequential — the learner feels that a point with a collider stops being a coordinate and becomes a thing that touches
# critical_parameter: tip_collider_radius (0.05) — the size of the tip's physical footprint; below it the point is a mathematical dot, at it the point can push
# triggers: _setup_pusher_tip on ready parents a collider and metallic sphere to the tip marker; moving the grab_line drags the collider through the physics world
# emerges: that the difference between a coordinate and an object is a collision shape — geometry becomes agency the moment it can occupy space
# needs: tip collider [has]; visible pusher mesh [has]; apply_grid_config [missing]; configurable mass/impulse [missing — kinematic push only]
# relationships: extends grab_line (adds a body to the endpoint); the acting verb beside grab_line_drawer (records) and grab_line_music (sounds) — three ways to spend the same held line
# truth: a point becomes real to the world only when it can be in the way

## GrabLine variant with a collider at the tip for pushing objects

@export_group("Pusher Settings")
@export var tip_collider_radius: float = 0.05
@export var pusher_color: Color = Color(1.0, 0.5, 0.0, 1.0)

var _tip_collider: StaticBody3D
var _pusher_mesh: MeshInstance3D
var _pusher_light: OmniLight3D

func _ready() -> void:
	super()
	_setup_pusher_tip()

func _setup_pusher_tip() -> void:
	if not _tip_marker:
		return

	# Create static body for collision at tip
	_tip_collider = StaticBody3D.new()
	_tip_collider.name = "PusherCollider"
	_tip_marker.add_child(_tip_collider)

	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = tip_collider_radius
	collision.shape = sphere_shape
	_tip_collider.add_child(collision)

	# Add visible pusher mesh
	_pusher_mesh = MeshInstance3D.new()
	_pusher_mesh.name = "PusherMesh"
	var sphere = SphereMesh.new()
	sphere.radius = tip_collider_radius
	sphere.height = tip_collider_radius * 2
	_pusher_mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = pusher_color
	mat.metallic = 0.7
	mat.roughness = 0.2
	mat.emission_enabled = true
	mat.emission = pusher_color
	mat.emission_energy_multiplier = 0.8
	_pusher_mesh.material_override = mat
	_tip_marker.add_child(_pusher_mesh)

	# Add light
	_pusher_light = OmniLight3D.new()
	_pusher_light.name = "PusherLight"
	_pusher_light.light_color = pusher_color
	_pusher_light.light_energy = 0.5
	_pusher_light.omni_range = 0.3
	_tip_marker.add_child(_pusher_light)

func set_pusher_color(color: Color) -> void:
	pusher_color = color
	if _pusher_mesh and _pusher_mesh.material_override:
		var mat = _pusher_mesh.material_override as StandardMaterial3D
		mat.albedo_color = color
		mat.emission = color
	if _pusher_light:
		_pusher_light.light_color = color
