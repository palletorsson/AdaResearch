# test_plane_heights.gd
# Test script to demonstrate the effect of plane height on hole generation

@tool
extends Node3D

@export var test_different_heights: bool:
	set(value):
		if value:
			test_height_variations()

func test_height_variations():
	print("🧪 TESTING PLANE HEIGHT VARIATIONS")
	print("=" * 50)
	
	# Test different height offsets
	var height_offsets = [-0.5, -0.2, 0.0, 0.2, 0.3, 0.5]
	
	for offset in height_offsets:
		print("\n📐 Testing plane height offset: %.1f" % offset)
		var triangle_count = simulate_terrain_generation(offset)
		var coverage = triangle_count / float(32 * 32 * 32) * 100.0  # Rough estimate
		
		print("   ⮚ Generated %d triangles (%.1f%% coverage)" % [triangle_count, coverage])
		
		if triangle_count == 0:
			print("   ❌ NO TRIANGLES - Plane too low!")
		elif triangle_count < 100:
			print("   ⚠️  FEW TRIANGLES - Plane possibly too low")
		else:
			print("   ✅ GOOD TRIANGLE COUNT - Plane height working")

func simulate_terrain_generation(plane_offset: float) -> int:
	"""Simulate terrain generation with given plane offset"""
	var resolution = 32
	var iso_level = 0.0
	var triangle_count = 0
	
	# Create simple noise
	var noise = FastNoiseLite.new()
	noise.frequency = 0.1
	
	# Simulate voxel generation and triangle counting
	for x in range(resolution):
		for y in range(resolution):
			for z in range(resolution):
				# Calculate 8 corners of cube
				var corners = []
				for dx in [0, 1]:
					for dy in [0, 1]:
						for dz in [0, 1]:
							var world_x = x + dx
							var world_y = y + dy  
							var world_z = z + dz
							
							var noise_value = noise.get_noise_3d(world_x, world_y, world_z)
							var height_factor = world_y / float(resolution) + plane_offset
							var terrain_value = clamp(noise_value + height_factor, -1.0, 1.0)
							corners.append(terrain_value)
				
				# Check if this cube would generate triangles
				var below_count = 0
				var above_count = 0
				for corner_value in corners:
					if corner_value < iso_level:
						below_count += 1
					else:
						above_count += 1
				
				# If we have both below and above iso-level, we'd generate triangles
				if below_count > 0 and above_count > 0:
					triangle_count += 1  # Simplified count
	
	return triangle_count

func _ready():
	print("🎛️ Plane Height Tester Ready")
	print("Click 'test_different_heights' in inspector to run tests") 