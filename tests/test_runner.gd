# test_runner.gd
# Simple runner script for the automated scene tester
# Place this file in your project root and run it to test all scenes

extends SceneTree

func _init():
	print("🧪 VR Algorithm Library - Automated Testing Tool")
	var separator = ""
	for i in 60:
		separator += "="
	print(separator)
	print("This will test all .tscn files in your algorithms/ directory")
	print("📸 Screenshots will be captured for each scene")
	print("📊 A detailed report will be generated")
	print("⏰ Timeout: 10 seconds per scene")
	print(separator)
	
	# Start the actual tester
	var tester = AutomatedSceneTester.new()
	
	# Replace current scene tree with tester
	get_root().replace_by(tester.get_root())

# Note: Make sure AutomatedSceneTester class is available
# Either include it in autoload or place both scripts in same file
