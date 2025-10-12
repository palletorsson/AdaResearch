extends Node3D
class_name WFCTile3D

# 3D Visual representation of a WFC tile
# Can display different tile types with meshes and materials

var tile_id: String = ""
var tile_type: WFCTile = null
var grid_position: Vector3 = Vector3.ZERO
var mesh_instance: MeshInstance3D = null

func _init():
	# Create mesh instance when tile is instantiated
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)

func setup(tile: WFCTile, pos: Vector3, tile_size: float = 1.0):
	"""Initialize the 3D tile with a tile type and position"""
	tile_id = tile.tile_id
	tile_type = tile
	grid_position = pos

	# Position in world space
	position = pos * tile_size

	# Create or load mesh
	create_mesh(tile_size)

	# Apply color/material
	apply_material()

func create_mesh(tile_size: float = 1.0):
	"""Create the mesh for this tile"""
	if tile_type and tile_type.mesh_scene != "":
		# Load custom mesh scene if specified
		if ResourceLoader.exists(tile_type.mesh_scene):
			var scene = load(tile_type.mesh_scene)
			var instance = scene.instantiate()
			add_child(instance)
			return

	# Try to use custom corridor mesh if available
	if tile_type and (tile_id.begins_with("corridor") or tile_id == "terminal" or
					  tile_id == "room" or tile_id.begins_with("doorway_") or
					  tile_id.begins_with("corner_") or tile_id.begins_with("tjunc_") or
					  tile_id == "cross"):
		var custom_mesh_instance = CorridorTileMesh.create_corridor_tile(tile_id, tile_size)
		mesh_instance.mesh = custom_mesh_instance.mesh
		return

	# Default: create a box mesh
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(tile_size, tile_size, tile_size)
	mesh_instance.mesh = box_mesh

func apply_material():
	"""Apply material/color to the mesh"""
	if not mesh_instance or not mesh_instance.mesh:
		return

	var material = StandardMaterial3D.new()

	if tile_type:
		material.albedo_color = tile_type.color
	else:
		material.albedo_color = Color.WHITE

	material.metallic = 0.3
	material.roughness = 0.7

	mesh_instance.set_surface_override_material(0, material)

func highlight():
	"""Highlight this tile (for debugging/visualization)"""
	if mesh_instance and mesh_instance.get_surface_override_material(0):
		var mat = mesh_instance.get_surface_override_material(0)
		mat.emission_enabled = true
		mat.emission = Color.YELLOW
		mat.emission_energy = 0.5

func unhighlight():
	"""Remove highlight from this tile"""
	if mesh_instance and mesh_instance.get_surface_override_material(0):
		var mat = mesh_instance.get_surface_override_material(0)
		mat.emission_enabled = false
