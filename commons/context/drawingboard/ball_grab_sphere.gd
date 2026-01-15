@tool
extends "res://commons/primitives/cubes/grab_cube.gd"

# This script extends GrabCube (used by GrabSphere) and adds 
# automatic color syncing with the child BallPaintTip.

@export var sync_with_paint_tip: bool = true:
	set(value):
		sync_with_paint_tip = value
		if sync_with_paint_tip and is_inside_tree():
			_sync_colors()

func _ready() -> void:
	# Call the parent _ready from grab_cube.gd
	super._ready()
	
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
	# Note: GrabSphere/GrabCube usually has a MeshInstance3D named "MeshInstance3D"
	var mesh_instance = get_node_or_null("MeshInstance3D")
	if mesh_instance:
		# Use material_override if it exists, otherwise define one
		var material = mesh_instance.material_override
		
		# If we don't have a unique material yet, create one
		if material == null:
			material = StandardMaterial3D.new()
		elif not material.resource_local_to_scene:
			material = material.duplicate()
			
		# Assign back to material_override to ensure it takes precedence
		mesh_instance.material_override = material
			
		# Apply the color
		if material is StandardMaterial3D:
			material.albedo_color = brush_color
			material.metallic = 0.4
			material.roughness = 0.6
			material.emission_enabled = true
			material.emission = brush_color * 0.3
			material.emission_energy_multiplier = 1.0
			
			# Update the original material reference in base class so it acts as "reset" material
			_original_material = material
