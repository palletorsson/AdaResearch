# @identity
# essence: damage(t) = f(hue_phase, player_position) -- RGB zone shifting hue with color-coded effects
# desire: three overlapping colored spheres cycling through RGB, each hue carrying different damage
# critical_parameter: _hue_phase -- continuous rotation through color space determines active damage type
# triggers: player enters area; hue_phase cycles continuously; damage accumulates based on current color
# emerges: color as information -- the visible spectrum becomes a hazard language where hue means harm-type
# needs: Area3D detection [has]; RGB sphere meshes [has]; hue-based damage [has]; VR interaction [missing]
# relationships: embodies color sequence concepts as spatial hazard; pairs with noise_field
# truth: color is not decoration -- it is a signal channel carrying damage semantics in the visible spectrum.

extends Area3D
class_name ChromaticField
## Color sequence hazard — RGB zone that shifts hue and applies color-coded damage.
## Three overlapping spheres in red, green, blue rotate independently.
## The dominant hue determines the damage type. Teaches color mixing and perception.

signal enemy_destroyed(enemy: Node3D)

@export_group("Geometry")
@export var field_radius: float = 2.0
@export var inner_radius: float = 1.5

@export_group("Behavior")
@export var hue_cycle_speed: float = 0.15
@export var damage_per_second: float = 8.0
@export var rotation_speed: float = 0.5

@export_group("Appearance")
@export var red_color: Color = Color(1.0, 0.15, 0.1, 0.3)
@export var green_color: Color = Color(0.1, 1.0, 0.2, 0.3)
@export var blue_color: Color = Color(0.1, 0.2, 1.0, 0.3)

# State
var _hue_phase: float = 0.0
var _player_inside: bool = false
var _player_node: Node3D = null
var _damage_accumulator: float = 0.0

# Visual
var _sphere_r: MeshInstance3D = null
var _sphere_g: MeshInstance3D = null
var _sphere_b: MeshInstance3D = null
var _disc: MeshInstance3D = null
var _label: Label3D = null
var _mat_r: StandardMaterial3D
var _mat_g: StandardMaterial3D
var _mat_b: StandardMaterial3D
var _disc_mat: StandardMaterial3D


func _ready() -> void:
	# Collision setup
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = field_radius
	col.shape = shape
	add_child(col)

	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2  # Player layer

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_create_materials()
	_build_mesh()
	_find_player()
	add_to_group("enemy")


func _process(delta: float) -> void:
	_hue_phase += delta * hue_cycle_speed

	# Rotate RGB spheres independently
	if _sphere_r:
		_sphere_r.rotation.y += delta * rotation_speed * 1.0
		_sphere_r.rotation.x += delta * rotation_speed * 0.3
	if _sphere_g:
		_sphere_g.rotation.y += delta * rotation_speed * 0.7
		_sphere_g.rotation.z += delta * rotation_speed * 0.4
	if _sphere_b:
		_sphere_b.rotation.y += delta * rotation_speed * 1.3
		_sphere_b.rotation.x -= delta * rotation_speed * 0.5

	# Update colors based on hue phase
	var r_strength: float = 0.5 + 0.5 * sin(_hue_phase * TAU)
	var g_strength: float = 0.5 + 0.5 * sin(_hue_phase * TAU + TAU / 3.0)
	var b_strength: float = 0.5 + 0.5 * sin(_hue_phase * TAU + 2.0 * TAU / 3.0)

	_mat_r.albedo_color.a = r_strength * 0.4
	_mat_g.albedo_color.a = g_strength * 0.4
	_mat_b.albedo_color.a = b_strength * 0.4

	if _mat_r.emission_enabled:
		_mat_r.emission_energy_multiplier = r_strength * 2.0
	if _mat_g.emission_enabled:
		_mat_g.emission_energy_multiplier = g_strength * 2.0
	if _mat_b.emission_enabled:
		_mat_b.emission_energy_multiplier = b_strength * 2.0

	# Dominant channel label
	var dominant: String = "RED"
	if g_strength > r_strength and g_strength > b_strength:
		dominant = "GREEN"
	elif b_strength > r_strength and b_strength > g_strength:
		dominant = "BLUE"

	if _label:
		_label.text = "HUE: %s" % dominant
		match dominant:
			"RED":
				_label.modulate = Color(1.0, 0.3, 0.2)
			"GREEN":
				_label.modulate = Color(0.2, 1.0, 0.3)
			"BLUE":
				_label.modulate = Color(0.3, 0.4, 1.0)

	# Apply damage to player inside
	if _player_inside and is_instance_valid(_player_node):
		_damage_accumulator += delta * damage_per_second
		if _damage_accumulator >= 1.0:
			var dmg: float = floor(_damage_accumulator)
			_damage_accumulator -= dmg
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("apply_health_damage"):
				gm.apply_health_damage(dmg)


func _create_materials() -> void:
	_mat_r = StandardMaterial3D.new()
	_mat_r.albedo_color = red_color
	_mat_r.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_r.emission_enabled = true
	_mat_r.emission = Color(1.0, 0.2, 0.1)
	_mat_r.emission_energy_multiplier = 1.0
	_mat_r.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_g = StandardMaterial3D.new()
	_mat_g.albedo_color = green_color
	_mat_g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_g.emission_enabled = true
	_mat_g.emission = Color(0.1, 1.0, 0.2)
	_mat_g.emission_energy_multiplier = 1.0
	_mat_g.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_b = StandardMaterial3D.new()
	_mat_b.albedo_color = blue_color
	_mat_b.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_b.emission_enabled = true
	_mat_b.emission = Color(0.1, 0.2, 1.0)
	_mat_b.emission_energy_multiplier = 1.0
	_mat_b.cull_mode = BaseMaterial3D.CULL_DISABLED

	_disc_mat = StandardMaterial3D.new()
	_disc_mat.albedo_color = Color(0.3, 0.3, 0.3, 0.15)
	_disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


func _build_mesh() -> void:
	# Three offset spheres for R, G, B
	var sphere := SphereMesh.new()
	sphere.radius = inner_radius
	sphere.height = inner_radius * 2.0
	sphere.radial_segments = 24
	sphere.rings = 12

	_sphere_r = MeshInstance3D.new()
	_sphere_r.mesh = sphere
	_sphere_r.set_surface_override_material(0, _mat_r)
	_sphere_r.position = Vector3(0.25, inner_radius, 0.0)
	add_child(_sphere_r)

	_sphere_g = MeshInstance3D.new()
	_sphere_g.mesh = sphere
	_sphere_g.set_surface_override_material(0, _mat_g)
	_sphere_g.position = Vector3(-0.15, inner_radius, 0.2)
	add_child(_sphere_g)

	_sphere_b = MeshInstance3D.new()
	_sphere_b.mesh = sphere
	_sphere_b.set_surface_override_material(0, _mat_b)
	_sphere_b.position = Vector3(-0.15, inner_radius, -0.2)
	add_child(_sphere_b)

	# Ground disc showing the field boundary
	var disc := CylinderMesh.new()
	disc.top_radius = field_radius
	disc.bottom_radius = field_radius
	disc.height = 0.02
	_disc = MeshInstance3D.new()
	_disc.mesh = disc
	_disc.set_surface_override_material(0, _disc_mat)
	_disc.position = Vector3(0.0, 0.01, 0.0)
	add_child(_disc)

	# Label
	_label = Label3D.new()
	_label.text = "HUE: RED"
	_label.font_size = 28
	_label.pixel_size = 0.003
	_label.modulate = Color(1.0, 0.3, 0.2)
	_label.position = Vector3(0.0, inner_radius * 2.0 + 0.3, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_player_node = body
		_damage_accumulator = 0.0

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false


func _find_player() -> void:
	var scene: Node = get_tree().current_scene
	if not scene:
		return
	for candidate in [
		get_tree().get_first_node_in_group("player"),
		scene.find_child("XROrigin3D", true, false),
		scene.find_child("Player", true, false),
	]:
		if candidate is Node3D:
			_player_node = candidate
			return


# Damage interface for consistency
func take_damage(amount: float) -> void:
	pass  # Zone hazards are indestructible

func apply_damage(amount: float) -> void:
	pass

func damage(amount: float) -> void:
	pass

func configure(config: Dictionary) -> void:
	if config.has("damage"):
		damage_per_second = float(config["damage"])
	if config.has("radius"):
		field_radius = float(config["radius"])

func apply_grid_config(config: Dictionary) -> void:
	configure(config)
