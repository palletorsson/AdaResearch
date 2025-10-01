# PointColor.gd - Standalone color management for 3D mesh objects
extends Node

# Target mesh to colorize
var target_mesh: MeshInstance3D = null

# Current color
@export var current_color: Color = Color.HOT_PINK

# Material settings
var use_emission: bool = true
var emission_strength: float = 0.8


func _ready():
	# Try to find target mesh in parent if not set

	if not target_mesh and get_parent() is MeshInstance3D:
		target_mesh = get_parent()

	# Apply initial color if target exists
	if target_mesh:
		apply_color(current_color)

# Set the target mesh to colorize
func set_target_mesh(mesh: MeshInstance3D):
	target_mesh = mesh
	if target_mesh and current_color != Color.WHITE:
		apply_color(current_color)

# Set the color of the target mesh
func set_color(color: Color):
	current_color = color
	apply_color(color)

# Apply color to the target mesh
func apply_color(color: Color):
	if not target_mesh:
		return

	# Create new material or modify existing one
	var material: StandardMaterial3D
	if target_mesh.material_override and target_mesh.material_override is StandardMaterial3D:
		material = target_mesh.material_override as StandardMaterial3D
	else:
		material = StandardMaterial3D.new()
		target_mesh.material_override = material

	# Apply color settings
	material.albedo_color = color

	if use_emission:
		material.emission_enabled = true
		material.emission = color * emission_strength
	else:
		material.emission_enabled = false

# Configure material properties
func configure_material(emission: bool = true, emission_str: float = 0.8, unshaded: bool = true):
	use_emission = emission
	emission_strength = emission_str

	# Reapply color with new settings
	if target_mesh:
		apply_color(current_color)
