extends Node

# Simple test to check what's causing scene load failures

func _ready():
	print("Testing scene loading...")
	
	var failing_scenes = [
		"res://algorithms/MachineLearning/ensemble_methods/ensemble_methods.tscn",
		"res://algorithms/MachineLearning/explainable_AI_XAI/explainable_AI_XAI.tscn", 
		"res://algorithms/MachineLearning/feature_engineering/feature_engineering.tscn"
	]
	
	for scene_path in failing_scenes:
		print("Testing: ", scene_path)
		var scene_resource = load(scene_path)
		if scene_resource == null:
			print("  ❌ Failed to load scene resource")
			continue
		
		print("  ✅ Scene resource loaded successfully")
		var scene_instance = scene_resource.instantiate()
		if scene_instance == null:
			print("  ❌ Failed to instantiate scene")
			continue
			
		print("  ✅ Scene instantiated successfully")
		scene_instance.queue_free()
	
	print("Scene loading test complete")
	get_tree().quit()
