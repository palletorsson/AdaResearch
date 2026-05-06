extends SceneTree

func _init() -> void:
	print("🔍 Validating SoftBody3D Scene...")
	
	# Load the main scene
	var scene = load("res://algorithms/physicssimulation/softbody3d/softbody3d.tscn")
	if scene:
		print("✅ Main scene loads successfully")
		
		# Try to instantiate the scene
		var instance = scene.instantiate()
		if instance:
			print("✅ Scene instantiates successfully")
			
			# Check for required nodes
			var soft_bodies = instance.get_node_or_null("SoftBodyVariations")
			if soft_bodies:
				print("✅ SoftBodyVariations node found")
				var children = soft_bodies.get_children()
				print("Found %d soft body children: %s" % [children.size(), children.map(func(c): return c.name)])
				
				for child in children:
					if child is SoftBody3D:
						print("✅ SoftBody3D found: %s" % child.name)
						if child.script:
							print("  📜 Has script: %s" % child.script.resource_path)
						else:
							print("  ⚠️ No script attached")
					else:
						print("❌ Non-SoftBody3D child: %s (%s)" % [child.name, child.get_class()])
			else:
				print("❌ SoftBodyVariations node not found")
			
			# Check for floor collision
			var floor = instance.get_node_or_null("Floor")
			if floor:
				var collision = floor.get_node_or_null("FloorCollision")
				if collision:
					print("✅ Floor collision found")
				else:
					print("⚠️ Floor collision not found")
			else:
				print("❌ Floor node not found")
				
		else:
			print("❌ Scene instantiation failed")
	else:
		print("❌ Main scene failed to load")
	
	print("🏁 Validation complete!")
	quit()
