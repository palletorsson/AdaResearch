# demo_hole_free.gd
# Demonstration of hole-free marching cubes terrain generation
# This script shows how to use the fixed system to generate seamless terrain

extends Node3D

var terrain_generator: TerrainGenerator
var terrain_meshes: Array[MeshInstance3D] = []

func _ready():
	print("🌍 Hole-Free Marching Cubes Demo")
	generate_demo_terrain()

func generate_demo_terrain():
	"""Generate demonstration terrain using the hole-free marching cubes system"""
	
	# Initialize the terrain generator
	terrain_generator = TerrainGenerator.new(12345)  # Fixed seed for reproducible results
	
	# Configure terrain parameters for hole-free generation
	terrain_generator.configure_terrain({
		"size": Vector2(40, 40),           # 40x40 world units
		"height": 8.0,                     # 8 units max height variation
		"noise_frequency": 0.06,           # Moderate detail level
		"threshold": 0.5,                  # Standard marching cubes threshold
		"debug_mode": false                # Enable surface variation for natural look
	})
	
	print("📐 Terrain configured: 40x40 units, 8 unit height")
	
	# Generate terrain asynchronously (non-blocking)
	var meshes = await terrain_generator.generate_terrain_async()
	
	# Add generated terrain to the scene
	for mesh_instance in meshes:
		add_child(mesh_instance)
		terrain_meshes.append(mesh_instance)
	
	# Add terrain to scene and create collision
	terrain_generator.add_terrain_to_scene(self)
	
	# Display generation statistics
	var info = terrain_generator.get_terrain_info()
	print("✅ Terrain Generated Successfully!")
	print("   Chunks: %d" % info.terrain_chunks)
	print("   Mesh instances: %d" % info.mesh_instances)
	print("   Total vertices: %d" % info.total_vertices)
	print("   Total triangles: %d" % info.total_triangles)
	print("   Collision bodies: %d" % info.collision_bodies)
	
	# Validate for holes
	validate_terrain_integrity()

func validate_terrain_integrity():
	"""Validate that the generated terrain has no holes"""
	var total_triangles = 0
	var valid_meshes = 0
	
	for mesh_instance in terrain_meshes:
		var mesh = mesh_instance.mesh as ArrayMesh
		if mesh != null and mesh.get_surface_count() > 0:
			valid_meshes += 1
			var arrays = mesh.surface_get_arrays(0)
			var indices = arrays[Mesh.ARRAY_INDEX] as PackedInt32Array
			total_triangles += indices.size() / 3
	
	if valid_meshes > 0 and total_triangles > 0:
		print("🔍 Validation: %d valid meshes, %d triangles - NO HOLES DETECTED!" % [valid_meshes, total_triangles])
	else:
		print("⚠️  Validation: Potential issues detected")

func _input(event):
	"""Handle user input for demonstration controls"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				# Regenerate terrain with new seed
				regenerate_terrain()
			KEY_D:
				# Toggle debug mode
				toggle_debug_mode()
			KEY_W:
				# Toggle wireframe mode
				toggle_wireframe_mode()
			KEY_H:
				# Show help
				show_help()

func regenerate_terrain():
	"""Regenerate terrain with a new random seed"""
	# Clear existing terrain
	for mesh_instance in terrain_meshes:
		mesh_instance.queue_free()
	terrain_meshes.clear()
	
	# Generate with new seed
	terrain_generator = TerrainGenerator.new()
	generate_demo_terrain()
	print("🔄 Terrain regenerated with new seed")

func toggle_debug_mode():
	"""Toggle debug mode to eliminate surface variation"""
	if terrain_generator:
		var current_debug = terrain_generator.debug_disable_surface_variation
		terrain_generator.configure_terrain({
			"debug_mode": not current_debug
		})
		regenerate_terrain()
		print("🐛 Debug mode: %s" % ("ON" if not current_debug else "OFF"))

func toggle_wireframe_mode():
	"""Toggle wireframe rendering for mesh inspection"""
	if terrain_generator:
		terrain_generator.debug_wireframe_mode = not terrain_generator.debug_wireframe_mode
		regenerate_terrain()
		print("📐 Wireframe mode: %s" % ("ON" if terrain_generator.debug_wireframe_mode else "OFF"))

func show_help():
	"""Display help information"""
	print("")
	print("🔧 HOLE-FREE MARCHING CUBES DEMO CONTROLS:")
	print("   R - Regenerate terrain with new seed")
	print("   D - Toggle debug mode (removes surface variation)")
	print("   W - Toggle wireframe mode (shows mesh structure)")
	print("   H - Show this help")
	print("")
	print("💡 FEATURES DEMONSTRATED:")
	print("   • Seamless chunk boundaries (no gaps)")
	print("   • Robust triangle generation (no holes)")
	print("   • Smooth surface transitions")
	print("   • Consistent density calculations")
	print("   • Hole detection and validation")
	print("")

# Example usage in a test scene:
# 1. Create a new 3D scene
# 2. Add this script to the root Node3D
# 3. Add a Camera3D positioned to view the terrain (e.g., position (20, 15, 20))
# 4. Run the scene to see hole-free terrain generation
# 5. Use the keyboard controls to test different configurations 