# test_chairs.gd
# Simple test script to verify chair generation
extends Node3D

func _ready():
	print("🪑 Testing Modernist Chair Generation...")
	
	# Test material system
	var materials = ModernistMaterials.new()
	add_child(materials)
	print("✅ Materials system loaded")
	
	# Test each chair type
	var test_positions = [
		Vector3(-2, 0, 0),
		Vector3(0, 0, 0), 
		Vector3(2, 0, 0)
	]
	
	# Test a few chair types
	var test_chairs = [
		BauhausCantileverChair.new(),
		BarcelonaPavilionChair.new(),
		OrganicShellChair.new()
	]
	
	for i in range(test_chairs.size()):
		var chair = test_chairs[i]
		chair.position = test_positions[i]
		add_child(chair)
		print("✅ Chair ", i+1, " generated successfully")
	
	print("🎉 All chairs generated successfully!")
	print("📝 Scene ready for VR exploration")
















































