# ===========================================================================
# Fibonacci Pagoda
# Uses pillarpart.tscn stacked with Fibonacci-based scaling
#
# Traditional pagoda architecture meets Fibonacci mathematical patterns
# Each tier's scale follows the inverse Fibonacci sequence for tapering
# ===========================================================================

extends Node3D

## Fibonacci Pagoda
## Creates a pagoda structure using pillarpart instances scaled by Fibonacci ratios
## Chapter 08: Fractals - Mathematical patterns in architecture

const PILLAR_SCENE = preload("res://algorithms/fractals/pillar/pillarpart.tscn")

@export var num_tiers: int = 8
@export var base_scale: float = 3.0  # Scale of the bottom tier
@export var tier_height: float = 1.2  # Vertical spacing between tiers
@export var roof_overhang: float = 1.3  # How much wider the roof extends
@export var use_golden_ratio: bool = true  # Use golden ratio or pure Fibonacci

var _sim_root: Node3D
var _status_label: Label3D
var _tiers: Array = []
var _fibonacci_sequence: Array = []
var _golden_ratio: float = (1.0 + sqrt(5.0)) / 2.0

func _ready() -> void:
	_generate_fibonacci_sequence(num_tiers + 5)
	_setup_environment()
	_build_pagoda()
	set_process(false)

func _generate_fibonacci_sequence(count: int) -> void:
	"""Generate Fibonacci sequence for scaling calculations"""
	_fibonacci_sequence = [1, 1]
	for i in range(2, count):
		_fibonacci_sequence.append(_fibonacci_sequence[i-1] + _fibonacci_sequence[i-2])

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "PagodaRoot"
	add_child(_sim_root)
	
	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 32
	_status_label.modulate = Color(1.0, 0.9, 0.8)
	_status_label.position = Vector3(0, num_tiers * tier_height + 2.0, 0)
	_status_label.text = "Fibonacci Pagoda | Tiers: %d" % num_tiers
	_sim_root.add_child(_status_label)

func _build_pagoda() -> void:
	"""Build the pagoda from bottom to top using Fibonacci scaling"""
	var current_height: float = 0.0
	
	for tier in range(num_tiers):
		var tier_data = _create_tier(tier, current_height)
		current_height += tier_data["height"]
	
	# Add finial (top ornament) using smallest pillar
	_create_finial(current_height)

func _get_tier_scale(tier_index: int) -> float:
	"""Calculate scale for a tier using Fibonacci ratios"""
	if use_golden_ratio:
		# Scale decreases by golden ratio each tier
		return base_scale / pow(_golden_ratio, tier_index * 0.5)
	else:
		# Use inverse Fibonacci ratio for scaling
		var fib_index = num_tiers - tier_index
		var max_fib = float(_fibonacci_sequence[num_tiers])
		var tier_fib = float(_fibonacci_sequence[fib_index])
		return base_scale * (tier_fib / max_fib)

func _create_tier(tier_index: int, y_position: float) -> Dictionary:
	"""Create a single pagoda tier with roof"""
	var scale_factor = _get_tier_scale(tier_index)
	var tier_container = Node3D.new()
	tier_container.name = "Tier_%d" % tier_index
	tier_container.position = Vector3(0, y_position, 0)
	_sim_root.add_child(tier_container)
	
	# Create the main pillar body for this tier
	var pillar = PILLAR_SCENE.instantiate()
	pillar.scale = Vector3(scale_factor, scale_factor * 0.8, scale_factor)
	_apply_tier_material(pillar, tier_index)
	tier_container.add_child(pillar)
	
	# Create roof overhang using scaled pillars rotated
	_create_roof_layer(tier_container, scale_factor, tier_index)
	
	# Create corner pillars for structural detail
	_create_corner_pillars(tier_container, scale_factor, tier_index)
	
	_tiers.append(tier_container)
	
	return {
		"height": tier_height * scale_factor / base_scale + 0.3,
		"scale": scale_factor
	}

func _create_roof_layer(parent: Node3D, scale_factor: float, tier_index: int) -> void:
	"""Create the characteristic pagoda roof overhang"""
	var roof_scale = scale_factor * roof_overhang
	
	# Create 4 roof eaves pointing outward (N, S, E, W)
	var directions = [
		Vector3(1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(0, 0, 1),
		Vector3(0, 0, -1)
	]
	
	for i in range(directions.size()):
		var roof_part = PILLAR_SCENE.instantiate()
		var eave_scale = scale_factor * 0.4
		roof_part.scale = Vector3(eave_scale, eave_scale * 0.3, eave_scale * 0.5)
		
		# Position at the edge of the tier, angled downward
		var offset = directions[i] * scale_factor * 0.5
		roof_part.position = offset + Vector3(0, scale_factor * 0.35, 0)
		
		# Rotate to point outward and tilt down slightly
		roof_part.rotation_degrees = Vector3(
			-20 if directions[i].z != 0 else 0,  # Tilt down
			90 * i,  # Face outward
			-20 if directions[i].x != 0 else 0   # Tilt down
		)
		
		_apply_roof_material(roof_part, tier_index)
		parent.add_child(roof_part)
	
	# Add corner eaves for more traditional look
	var corner_directions = [
		Vector3(1, 0, 1).normalized(),
		Vector3(1, 0, -1).normalized(),
		Vector3(-1, 0, 1).normalized(),
		Vector3(-1, 0, -1).normalized()
	]
	
	for i in range(corner_directions.size()):
		var corner_eave = PILLAR_SCENE.instantiate()
		var eave_scale = scale_factor * 0.3
		corner_eave.scale = Vector3(eave_scale, eave_scale * 0.25, eave_scale * 0.4)
		
		var offset = corner_directions[i] * scale_factor * 0.6
		corner_eave.position = offset + Vector3(0, scale_factor * 0.3, 0)
		corner_eave.rotation_degrees = Vector3(-25, 45 + 90 * i, -25)
		
		_apply_roof_material(corner_eave, tier_index)
		parent.add_child(corner_eave)

func _create_corner_pillars(parent: Node3D, scale_factor: float, tier_index: int) -> void:
	"""Create small structural pillars at corners"""
	var corner_positions = [
		Vector3(1, 0, 1) * scale_factor * 0.3,
		Vector3(1, 0, -1) * scale_factor * 0.3,
		Vector3(-1, 0, 1) * scale_factor * 0.3,
		Vector3(-1, 0, -1) * scale_factor * 0.3
	]
	
	for pos in corner_positions:
		var corner_pillar = PILLAR_SCENE.instantiate()
		corner_pillar.scale = Vector3.ONE * scale_factor * 0.15
		corner_pillar.position = pos
		_apply_pillar_material(corner_pillar, tier_index)
		parent.add_child(corner_pillar)

func _create_finial(y_position: float) -> void:
	"""Create the ornamental top spire"""
	var finial_container = Node3D.new()
	finial_container.name = "Finial"
	finial_container.position = Vector3(0, y_position, 0)
	_sim_root.add_child(finial_container)
	
	# Stack progressively smaller pillars for the finial
	var finial_height = 0.0
	for i in range(5):
		var finial_part = PILLAR_SCENE.instantiate()
		var finial_scale = base_scale * 0.15 / pow(_golden_ratio, i * 0.7)
		finial_part.scale = Vector3(finial_scale, finial_scale * 1.5, finial_scale)
		finial_part.position = Vector3(0, finial_height, 0)
		
		_apply_finial_material(finial_part, i)
		finial_container.add_child(finial_part)
		finial_height += finial_scale * 0.8

func _apply_tier_material(node: Node3D, tier_index: int) -> void:
	"""Apply material to the main tier body"""
	var mesh_instances = _find_mesh_instances(node)
	
	for mesh_instance in mesh_instances:
		var material = StandardMaterial3D.new()
		
		# Color gradient from dark wood at base to lighter wood at top
		var t = float(tier_index) / float(num_tiers)
		var base_color = Color(0.4, 0.25, 0.15)  # Dark wood
		var top_color = Color(0.6, 0.45, 0.3)    # Light wood
		material.albedo_color = base_color.lerp(top_color, t)
		
		material.metallic = 0.1
		material.roughness = 0.8
		
		mesh_instance.material_override = material

func _apply_roof_material(node: Node3D, tier_index: int) -> void:
	"""Apply material to roof elements"""
	var mesh_instances = _find_mesh_instances(node)
	
	for mesh_instance in mesh_instances:
		var material = StandardMaterial3D.new()
		
		# Traditional dark roof tiles with slight color variation
		var t = float(tier_index) / float(num_tiers)
		var base_color = Color(0.15, 0.12, 0.1)   # Dark charcoal
		var accent_color = Color(0.25, 0.15, 0.1) # Warm dark
		material.albedo_color = base_color.lerp(accent_color, t * 0.5)
		
		material.metallic = 0.05
		material.roughness = 0.9
		
		mesh_instance.material_override = material

func _apply_pillar_material(node: Node3D, tier_index: int) -> void:
	"""Apply material to structural pillars"""
	var mesh_instances = _find_mesh_instances(node)
	
	for mesh_instance in mesh_instances:
		var material = StandardMaterial3D.new()
		
		# Red lacquered wood (traditional pagoda color)
		var t = float(tier_index) / float(num_tiers)
		material.albedo_color = Color(0.6, 0.15, 0.1).lerp(Color(0.8, 0.2, 0.15), t)
		
		material.metallic = 0.3
		material.roughness = 0.4
		
		mesh_instance.material_override = material

func _apply_finial_material(node: Node3D, level: int) -> void:
	"""Apply material to the finial spire"""
	var mesh_instances = _find_mesh_instances(node)
	
	for mesh_instance in mesh_instances:
		var material = StandardMaterial3D.new()
		
		# Golden/bronze finial
		var t = float(level) / 5.0
		material.albedo_color = Color(0.8, 0.6, 0.2).lerp(Color(1.0, 0.85, 0.4), t)
		
		material.metallic = 0.7
		material.roughness = 0.3
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.2
		
		mesh_instance.material_override = material

func _find_mesh_instances(node: Node) -> Array:
	"""Recursively find all MeshInstance3D nodes"""
	var result = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_mesh_instances(child))
	return result

func get_tier_count() -> int:
	return _tiers.size()

func get_fibonacci_at(index: int) -> int:
	if index < _fibonacci_sequence.size():
		return _fibonacci_sequence[index]
	return -1

func rebuild_pagoda() -> void:
	"""Clear and rebuild the pagoda"""
	for tier in _tiers:
		tier.queue_free()
	_tiers.clear()
	
	# Clear finial
	var finial = _sim_root.get_node_or_null("Finial")
	if finial:
		finial.queue_free()
	
	_build_pagoda()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

