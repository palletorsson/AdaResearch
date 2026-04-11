# Laser Measure - Distance measurement tool with LCD display
# A sleek handheld device for measuring distances in 3D space
extends Node3D

@export_category("Measurement Settings")
@export var max_range: float = 50.0
@export var scan_frequency: float = 30.0
@export var unit: String = "m"  # "m", "cm", "units"
@export var decimal_places: int = 2

@export_category("Laser Beam Settings")
@export var show_laser: bool = true
@export var laser_color: Color = Color(1.0, 0.1, 0.1, 0.9)
@export var laser_hit_color: Color = Color(0.1, 1.0, 0.3, 0.9)
@export var laser_thickness: float = 0.003
@export var show_hit_dot: bool = true
@export var hit_dot_size: float = 0.02

@export_category("Damage Settings")
@export var deals_damage: bool = false           ## Enable to make laser hurt the player
@export var damage_amount: float = 1.0           ## 1% damage per hit
@export var damage_cooldown: float = 1.0         ## Seconds between damage ticks

@export_category("Display Settings")
@export var text_color: Color = Color(0.2, 1.0, 0.3, 1.0)
@export var show_target_name: bool = true

var raycast: RayCast3D
var laser_beam: MeshInstance3D
var laser_material: StandardMaterial3D
var hit_dot: MeshInstance3D
var hit_dot_material: StandardMaterial3D
var body_mesh: MeshInstance3D
var distance_label: Label3D
var target_label: Label3D
var scan_timer: float = 0.0

var last_distance: float = 0.0
var last_target: String = ""
var is_measuring: bool = false
var _damage_timer: float = 0.0

func _ready():
	setup_raycast()
	setup_laser_beam()
	setup_hit_dot()
	setup_display()
	update_display(0.0, "", false)

func setup_raycast():
	raycast = find_child("RayCast3D", true, false)
	if not raycast:
		raycast = RayCast3D.new()
		raycast.name = "MeasureRayCast"
		add_child(raycast)

	raycast.enabled = true
	raycast.target_position = Vector3(0, 0, -max_range)
	raycast.collision_mask = 0xFFFFFFFF
	raycast.collide_with_bodies = true
	raycast.collide_with_areas = false

func setup_laser_beam():
	if not show_laser:
		return

	laser_beam = MeshInstance3D.new()
	laser_beam.name = "LaserBeam"
	add_child(laser_beam)

	var beam_mesh = BoxMesh.new()
	beam_mesh.size = Vector3(laser_thickness, laser_thickness, max_range)
	laser_beam.mesh = beam_mesh
	laser_beam.position = Vector3(0, 0, -max_range / 2)

	laser_material = StandardMaterial3D.new()
	laser_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	laser_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	laser_material.emission_enabled = true
	laser_material.emission = laser_color
	laser_material.emission_energy_multiplier = 2.0
	laser_material.albedo_color = laser_color
	laser_beam.set_surface_override_material(0, laser_material)

func setup_hit_dot():
	if not show_hit_dot:
		return

	hit_dot = MeshInstance3D.new()
	hit_dot.name = "HitDot"
	add_child(hit_dot)

	var dot_mesh = SphereMesh.new()
	dot_mesh.radius = hit_dot_size
	dot_mesh.height = hit_dot_size * 2
	dot_mesh.radial_segments = 8
	dot_mesh.rings = 4
	hit_dot.mesh = dot_mesh
	hit_dot.visible = false

	hit_dot_material = StandardMaterial3D.new()
	hit_dot_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hit_dot_material.emission_enabled = true
	hit_dot_material.emission = laser_hit_color
	hit_dot_material.emission_energy_multiplier = 3.0
	hit_dot_material.albedo_color = laser_hit_color
	hit_dot.set_surface_override_material(0, hit_dot_material)

func setup_display():
	# Find the body mesh to attach labels to
	body_mesh = get_node_or_null("../LaserMeasure#Body")
	if not body_mesh:
		var parent = get_parent()
		if parent:
			body_mesh = parent.get_node_or_null("LaserMeasure#Body")

	if body_mesh:
		setup_labels()

func setup_labels():
	if not body_mesh:
		return

	# Main distance label on the back of the body (facing user when holding)
	# Body size is 0.04 x 0.025 x 0.12, back face is at +Z = 0.06 local
	distance_label = body_mesh.find_child("DistanceLabel", false, false)
	if not distance_label:
		distance_label = Label3D.new()
		distance_label.name = "DistanceLabel"
		body_mesh.add_child(distance_label)

	# Position on back face of body, facing +Z (toward user)
	distance_label.position = Vector3(0, 0, 0.061)  # Just past back surface
	distance_label.rotation_degrees = Vector3(0, 0, 0)  # Face backward (+Z)
	distance_label.font_size = 72
	distance_label.outline_size = 4
	distance_label.pixel_size = 0.001
	distance_label.modulate = text_color
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Target name label (smaller, below distance)
	if show_target_name:
		target_label = body_mesh.find_child("TargetLabel", false, false)
		if not target_label:
			target_label = Label3D.new()
			target_label.name = "TargetLabel"
			body_mesh.add_child(target_label)

		target_label.position = Vector3(0, -0.008, 0.061)
		target_label.rotation_degrees = Vector3(0, 0, 0)
		target_label.font_size = 36
		target_label.outline_size = 2
		target_label.pixel_size = 0.001
		target_label.modulate = text_color.darkened(0.3)
		target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _process(delta):
	scan_timer += delta
	if _damage_timer > 0.0:
		_damage_timer -= delta

	if scan_timer >= (1.0 / scan_frequency):
		perform_measurement()
		scan_timer = 0.0

func perform_measurement():
	if not raycast:
		return

	raycast.force_raycast_update()

	if raycast.is_colliding():
		var hit_point = raycast.get_collision_point()
		var hit_object = raycast.get_collider()
		var distance = global_position.distance_to(hit_point)

		last_distance = distance
		last_target = _get_display_name(hit_object)
		is_measuring = true

		update_laser_hit(distance)
		update_hit_dot(hit_point)
		update_display(distance, last_target, true)

		# Damage: any hit triggers damage when enabled (the laser itself is the hazard)
		if deals_damage and _damage_timer <= 0.0:
			var gm = get_node_or_null("/root/GameManager")
			if gm and gm.has_method("apply_health_damage"):
				# The laser beam touching anything while player holds it = player in danger
				# For static placed lasers: hitting the player body specifically
				if _is_player_body(hit_object):
					gm.apply_health_damage(damage_amount)
					_damage_timer = damage_cooldown
					print("[LaserMeasure] LASER HIT PLAYER! dmg=%.1f target=%s" % [damage_amount, hit_object.name])
	else:
		is_measuring = false
		last_distance = 0.0
		last_target = ""

		update_laser_miss()
		hide_hit_dot()
		update_display(0.0, "", false)

func _get_display_name(obj: Node) -> String:
	if not obj:
		return ""

	var name = obj.name
	# Clean up common suffixes
	name = name.replace("StaticBody3D", "").replace("RigidBody3D", "")
	name = name.replace("CollisionShape3D", "").replace("MeshInstance3D", "")
	name = name.strip_edges()

	# Truncate long names
	if name.length() > 12:
		name = name.substr(0, 10) + ".."

	return name

func update_laser_hit(distance: float):
	if not laser_beam or not laser_material:
		return

	var beam_mesh = laser_beam.mesh as BoxMesh
	if beam_mesh:
		beam_mesh.size.z = distance
		laser_beam.position.z = -distance / 2

	laser_material.emission = laser_hit_color
	laser_material.albedo_color = laser_hit_color

func update_laser_miss():
	if not laser_beam or not laser_material:
		return

	var beam_mesh = laser_beam.mesh as BoxMesh
	if beam_mesh:
		beam_mesh.size.z = max_range
		laser_beam.position.z = -max_range / 2

	laser_material.emission = laser_color
	laser_material.albedo_color = laser_color

func update_hit_dot(world_position: Vector3):
	if not hit_dot:
		return

	hit_dot.global_position = world_position
	hit_dot.visible = true

	# Pulse effect
	var pulse = 0.8 + 0.4 * sin(Time.get_ticks_msec() * 0.01)
	hit_dot.scale = Vector3.ONE * pulse

func hide_hit_dot():
	if hit_dot:
		hit_dot.visible = false

func update_display(distance: float, target: String, is_active: bool):
	if not distance_label:
		return

	if is_active:
		var display_value = distance
		var unit_suffix = unit

		# Convert units if needed
		match unit:
			"cm":
				display_value = distance * 100.0
			"units":
				unit_suffix = "u"

		# Format with specified decimal places
		var format_str = "%." + str(decimal_places) + "f %s"
		distance_label.text = format_str % [display_value, unit_suffix]
		distance_label.modulate = text_color

		if target_label and show_target_name:
			target_label.text = target if target != "" else "---"
			target_label.modulate = text_color.darkened(0.3)
	else:
		distance_label.text = "--- %s" % unit
		distance_label.modulate = text_color.darkened(0.5)

		if target_label:
			target_label.text = "No target"
			target_label.modulate = text_color.darkened(0.6)

# Public API
func get_distance() -> float:
	return last_distance

func get_target_name() -> String:
	return last_target

func is_hitting() -> bool:
	return is_measuring

func set_unit(new_unit: String):
	unit = new_unit

func set_max_range(new_range: float):
	max_range = new_range
	if raycast:
		raycast.target_position = Vector3(0, 0, -max_range)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("damage"):
		deals_damage = str(config_data["damage"]).to_lower() == "true"
	if config_data.has("damage_amount"):
		damage_amount = float(config_data["damage_amount"])
	if config_data.has("cooldown"):
		damage_cooldown = float(config_data["cooldown"])


func _is_player_body(obj: Node) -> bool:
	if not obj:
		return false
	# Direct checks
	if obj.is_in_group("player") or obj.is_in_group("player_body"):
		return true
	if obj.name.containsn("player") or obj.name.containsn("Player"):
		return true
	# Check collision layer 20 (player body layer = 524288)
	if obj is CollisionObject3D:
		if (obj as CollisionObject3D).collision_layer & 524288 != 0:
			return true
	# Check parent chain
	var node := obj
	while node:
		if node.name == "PlayerBody" or node is XROrigin3D:
			return true
		if node.is_in_group("player"):
			return true
		node = node.get_parent()
	return false
