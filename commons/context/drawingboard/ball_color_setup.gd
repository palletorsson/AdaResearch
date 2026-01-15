@tool
extends Node3D

# This script automatically sets the ball's visual color to match the paint color
@export var sync_with_paint_tip: bool = true:
	set(value):
		sync_with_paint_tip = value
		if sync_with_paint_tip and is_inside_tree():
			_sync_colors()

func _ready():
	if sync_with_paint_tip:
		_sync_colors()

func _sync_colors():
	# Find the BallPaintTip node
	var paint_tip = get_node_or_null("BallPaintTip")
	if not paint_tip:
		return

	var brush_color = paint_tip.get("brush_color")
	if brush_color == null:
		return

	# Find the MeshInstance3D and update its material
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		var material = mesh_instance.get_surface_override_material(0)
		if material == null:
			material = StandardMaterial3D.new()
			mesh_instance.set_surface_override_material(0, material)

		if material is StandardMaterial3D:
			material.albedo_color = brush_color
			material.metallic = 0.4
			material.roughness = 0.6
			material.emission_enabled = true
			material.emission = brush_color * 0.3
			material.emission_energy_multiplier = 1.0
