# catalyst_target.gd
# Practice target for catalyst projectiles.
# Floats in the air, reacts to hits with flash and shake.
# Grid config: "moving:true" for patrol, "orbit:true" for circular path.
extends StaticBody3D

var _mesh: MeshInstance3D
var _mat: StandardMaterial3D
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _inner_ring: MeshInstance3D

# Movement
var _moving: bool = false
var _orbit: bool = false
var _patrol_speed: float = 1.5
var _patrol_range: float = 2.5
var _time: float = 0.0
var _start_pos: Vector3

# Hit reaction
var _flash_timer: float = 0.0
var _hit_count: int = 0
var _base_emission: float = 1.2


func _ready() -> void:
	collision_layer = 2  # Player-hittable layer
	collision_mask = 0
	_start_pos = position
	_build_visual()
	_build_collision()
	add_to_group("catalyst_target")


func _process(delta: float) -> void:
	# Movement
	_time += delta
	if _moving:
		position.x = _start_pos.x + sin(_time * _patrol_speed) * _patrol_range
	elif _orbit:
		position.x = _start_pos.x + cos(_time * _patrol_speed) * _patrol_range
		position.z = _start_pos.z + sin(_time * _patrol_speed) * _patrol_range

	# Ring spin
	if _ring:
		_ring.rotate_y(delta * 0.8)
	if _inner_ring:
		_inner_ring.rotate_x(delta * 1.2)

	# Flash decay
	if _flash_timer > 0.0:
		_flash_timer -= delta
		var t := _flash_timer / 0.4
		if _mat:
			_mat.emission_energy_multiplier = _base_emission + t * 4.0
		if _flash_timer <= 0.0 and _mat:
			_mat.emission_energy_multiplier = _base_emission


func _build_visual() -> void:
	# Core sphere — warm orange glow
	_mesh = MeshInstance3D.new()
	_mesh.name = "Core"
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	sphere.radial_segments = 16
	sphere.rings = 8
	_mesh.mesh = sphere
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.85, 0.35, 0.1)
	_mat.emission_enabled = true
	_mat.emission = Color(0.9, 0.4, 0.15)
	_mat.emission_energy_multiplier = _base_emission
	_mat.metallic = 0.5
	_mat.roughness = 0.3
	_mesh.material_override = _mat
	add_child(_mesh)

	# Outer ring
	_ring = MeshInstance3D.new()
	_ring.name = "OuterRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.015
	torus.outer_radius = 0.2
	torus.rings = 24
	torus.ring_segments = 8
	_ring.mesh = torus
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = Color(1.0, 0.7, 0.2)
	_ring_mat.emission_enabled = true
	_ring_mat.emission = Color(1.0, 0.8, 0.3)
	_ring_mat.emission_energy_multiplier = 0.8
	_ring_mat.metallic = 0.6
	_ring_mat.roughness = 0.2
	_ring.material_override = _ring_mat
	add_child(_ring)

	# Inner ring — perpendicular
	_inner_ring = MeshInstance3D.new()
	_inner_ring.name = "InnerRing"
	var torus2 := TorusMesh.new()
	torus2.inner_radius = 0.01
	torus2.outer_radius = 0.15
	torus2.rings = 20
	torus2.ring_segments = 6
	_inner_ring.mesh = torus2
	_inner_ring.rotation.x = PI / 2.0
	var inner_mat := StandardMaterial3D.new()
	inner_mat.albedo_color = Color(0.9, 0.5, 0.15)
	inner_mat.emission_enabled = true
	inner_mat.emission = Color(0.95, 0.6, 0.2)
	inner_mat.emission_energy_multiplier = 0.6
	inner_mat.metallic = 0.5
	inner_mat.roughness = 0.25
	_inner_ring.material_override = inner_mat
	add_child(_inner_ring)


func _build_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.2
	col.shape = shape
	add_child(col)


# Called by projectile _on_hit effects or can be called manually
func hit_by_projectile(_projectile_color: Color = Color.WHITE) -> void:
	_hit_count += 1
	_flash_timer = 0.4

	# Shake via tween
	var base := position
	var tween := create_tween()
	for i in 4:
		var offset := Vector3(
			randf_range(-0.03, 0.03),
			randf_range(-0.02, 0.02),
			randf_range(-0.03, 0.03)
		)
		tween.tween_property(self, "position", base + offset, 0.04)
	tween.tween_property(self, "position", base, 0.06)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("moving"):
		_moving = true
	if config_data.has("orbit"):
		_orbit = true
	if config_data.has("speed"):
		_patrol_speed = float(config_data["speed"])
	if config_data.has("range"):
		_patrol_range = float(config_data["range"])
