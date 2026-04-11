# @identity
# essence: SDF(x) = contour_rings(mines) -- minefield where crossing zero-boundary detonates
# desire: pulsing SDF contour rings from buried mines -- cross the zero-boundary and they explode
# critical_parameter: mine positions / SDF threshold -- signed distance field defines safe vs lethal
# triggers: player enters Area3D; SDF evaluated at position; zero-crossing triggers detonation
# emerges: signed distance fields as danger topology -- contour lines border safe and lethal
# needs: Area3D [has]; mine array [has]; SDF contour viz [has]; detonation logic [has]; VR interaction [missing]
# relationships: embodies patterngeneration; SDF connects to isosurface_trap (implicit surfaces)
# truth: the pattern is the weapon -- cross the zero-boundary and mathematics detonates.

extends Area3D
class_name PatternMine
## Pattern generation sequence hazard — a minefield with SDF contour rings.
## 8 sphere mines with concentric torus rings showing distance contours.
## Proximity to a mine (SDF < inner radius) triggers detonation with damage.
## Mines respawn after a cooldown, creating a repeating spatial pattern.

signal enemy_destroyed(enemy: Node3D)

@export_group("Field")
@export var mine_count: int = 8
@export var field_radius: float = 4.0

@export_group("Mine Geometry")
@export var mine_radius: float = 0.08
@export var ring_radii: Array[float] = [0.3, 0.6, 0.9]
@export var ring_tube_radius: float = 0.01

@export_group("Combat")
@export var detonation_radius: float = 0.3
@export var detonation_damage: float = 25.0
@export var respawn_time: float = 5.0

@export_group("Appearance")
@export var mine_color: Color = Color(1.0, 0.15, 0.1)
@export var inner_ring_color: Color = Color(1.0, 0.9, 0.1)
@export var outer_ring_color: Color = Color(0.2, 0.9, 0.3)

# State
var _player_node: Node3D = null
var _player_inside: bool = false
var _time: float = 0.0

# Per-mine data
var _mines: Array[Dictionary] = []
# Each entry: { "root": Node3D, "sphere": MeshInstance3D, "rings": [MeshInstance3D],
#                "pos": Vector3, "active": bool, "respawn_timer": float }


func _ready() -> void:
	# Detection area covering the whole field
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = field_radius + 1.0
	col.shape = shape
	add_child(col)

	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2  # Player layer

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_build_mines()
	_find_player()
	add_to_group("enemy")


func _process(delta: float) -> void:
	_time += delta

	if not is_instance_valid(_player_node):
		_find_player()

	var player_pos: Vector3 = Vector3.ZERO
	var has_player: bool = false
	if _player_inside and is_instance_valid(_player_node):
		player_pos = _player_node.global_position
		has_player = true

	for mine in _mines:
		if not mine["active"]:
			# Handle respawn timer
			mine["respawn_timer"] -= delta
			if mine["respawn_timer"] <= 0.0:
				_activate_mine(mine)
			continue

		# Pulse rings with sin(time) opacity
		var rings: Array = mine["rings"]
		for ri in range(rings.size()):
			var ring_mi: MeshInstance3D = rings[ri]
			var mat: StandardMaterial3D = ring_mi.get_surface_override_material(0)
			if mat:
				var phase: float = _time * 2.0 + float(ri) * 1.2
				var alpha: float = 0.2 + 0.4 * (0.5 + 0.5 * sin(phase))
				mat.albedo_color.a = alpha

		# Check proximity for detonation
		if has_player:
			var mine_world_pos: Vector3 = mine["root"].global_position
			var dist: float = player_pos.distance_to(mine_world_pos)
			if dist < detonation_radius:
				_detonate_mine(mine)


func _build_mines() -> void:
	for i in range(mine_count):
		# Random position in a circle
		var angle: float = randf() * TAU
		var radius: float = randf() * field_radius
		var pos := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)

		var root := Node3D.new()
		root.position = pos
		add_child(root)

		# Mine sphere
		var sphere_mesh := SphereMesh.new()
		sphere_mesh.radius = mine_radius
		sphere_mesh.height = mine_radius * 2.0
		sphere_mesh.radial_segments = 12
		sphere_mesh.rings = 6

		var mine_mat := StandardMaterial3D.new()
		mine_mat.albedo_color = mine_color
		mine_mat.emission_enabled = true
		mine_mat.emission = mine_color
		mine_mat.emission_energy_multiplier = 2.0

		var sphere_mi := MeshInstance3D.new()
		sphere_mi.mesh = sphere_mesh
		sphere_mi.set_surface_override_material(0, mine_mat)
		sphere_mi.position.y = mine_radius
		root.add_child(sphere_mi)

		# Contour rings
		var rings: Array[MeshInstance3D] = []
		for ri in range(ring_radii.size()):
			var torus := TorusMesh.new()
			torus.inner_radius = ring_radii[ri]
			torus.outer_radius = ring_radii[ri] + ring_tube_radius
			torus.rings = 24
			torus.ring_segments = 8

			# Color gradient: inner=yellow, outer=green
			var t: float = float(ri) / float(ring_radii.size() - 1) if ring_radii.size() > 1 else 0.0
			var ring_color: Color = inner_ring_color.lerp(outer_ring_color, t)

			var ring_mat := StandardMaterial3D.new()
			ring_mat.albedo_color = Color(ring_color.r, ring_color.g, ring_color.b, 0.4)
			ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ring_mat.emission_enabled = true
			ring_mat.emission = ring_color
			ring_mat.emission_energy_multiplier = 1.0
			ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

			var ring_mi := MeshInstance3D.new()
			ring_mi.mesh = torus
			ring_mi.set_surface_override_material(0, ring_mat)
			ring_mi.position.y = 0.01  # Slightly above ground
			ring_mi.rotation.x = 0.0   # Flat on ground (torus default is XZ plane)
			root.add_child(ring_mi)
			rings.append(ring_mi)

		_mines.append({
			"root": root,
			"sphere": sphere_mi,
			"rings": rings,
			"pos": pos,
			"active": true,
			"respawn_timer": 0.0,
		})


func _detonate_mine(mine: Dictionary) -> void:
	mine["active"] = false
	mine["respawn_timer"] = respawn_time

	# Flash effect — briefly scale up and brighten, then hide
	var sphere: MeshInstance3D = mine["sphere"]
	var mat: StandardMaterial3D = sphere.get_surface_override_material(0)
	if mat:
		mat.emission_energy_multiplier = 8.0

	# Scale flash
	var tween := get_tree().create_tween()
	tween.tween_property(sphere, "scale", Vector3(3.0, 3.0, 3.0), 0.1)
	tween.tween_property(sphere, "scale", Vector3.ZERO, 0.2)
	tween.tween_callback(func(): sphere.visible = false)

	# Hide rings
	for ring in mine["rings"]:
		ring.visible = false

	# Deal damage
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("apply_health_damage"):
		gm.apply_health_damage(detonation_damage)


func _activate_mine(mine: Dictionary) -> void:
	mine["active"] = true
	var sphere: MeshInstance3D = mine["sphere"]
	sphere.visible = true
	sphere.scale = Vector3.ONE

	var mat: StandardMaterial3D = sphere.get_surface_override_material(0)
	if mat:
		mat.emission_energy_multiplier = 2.0

	for ring in mine["rings"]:
		ring.visible = true


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_player_node = body

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


# ── Damage Interface ────────────────────────────────────────────────────
func take_damage(amount: float) -> void:
	pass  # Zone hazard — indestructible

func apply_damage(amount: float) -> void:
	pass

func damage(amount: float) -> void:
	pass

func configure(config: Dictionary) -> void:
	if config.has("damage"):
		detonation_damage = float(config["damage"])
	if config.has("mine_count"):
		mine_count = int(config["mine_count"])

func apply_grid_config(config: Dictionary) -> void:
	configure(config)
