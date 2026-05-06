# ResourceTest.gd
# Test script to verify BoxShape3D_interact resource is accessible
extends Node3D

func _ready():
	print("ResourceTest: Testing BoxShape3D_interact resource accessibility")
	
	# Test loading the HandheldInfoBoard scene
	var scene_path = "res://commons/infoboards_3d/base/HandheldInfoBoard.tscn"
	if ResourceLoader.exists(scene_path):
		print("✓ HandheldInfoBoard.tscn exists")
		
		var scene_resource = ResourceLoader.load(scene_path)
		if scene_resource:
			print("✓ HandheldInfoBoard.tscn loaded successfully")
			
			# Try to instantiate the scene
			var instance = scene_resource.instantiate()
			if instance:
				print("✓ HandheldInfoBoard instantiated successfully")
				
				# Check if the InteractionArea exists
				var interaction_area = instance.get_node_or_null("InteractionArea")
				if interaction_area:
					print("✓ InteractionArea found")
					
					# Check if the CollisionShape3D exists
					var collision_shape = interaction_area.get_node_or_null("CollisionShape3D")
					if collision_shape:
						print("✓ CollisionShape3D found")
						
						# Check if the shape is accessible
						var shape = collision_shape.shape
						if shape:
							print("✓ BoxShape3D_interact shape is accessible")
							print("  Shape type: %s" % shape.get_class())
							print("  Shape size: %s" % shape.size)
						else:
							print("✗ BoxShape3D_interact shape is null")
					else:
						print("✗ CollisionShape3D not found")
				else:
					print("✗ InteractionArea not found")
				
				instance.queue_free()
			else:
				print("✗ Failed to instantiate HandheldInfoBoard")
		else:
			print("✗ Failed to load HandheldInfoBoard.tscn")
	else:
		print("✗ HandheldInfoBoard.tscn does not exist")
