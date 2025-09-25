extends Node

# Test script for the new # configuration parsing system
# Run this to verify the parsing works correctly

func _ready():
	print("Testing GridInteractablesComponent Config Parsing...")
	
	var grid_component = GridInteractablesComponent.new()
	
	# Test cases for the new # syntax
	var test_cases = [
		# Basic cases
		"clipboard",
		"clipboard#pages:point,line,triangle",
		"clipboard#title:Getting Started",
		"clipboard#pages:point,line#title:My Clipboard",
		
		# More complex cases
		"infokiosk#message:Hello World#color:red#size:large",
		"panel#width:200#height:100",
		
		# Legacy syntax (should still work)
		"scifi_panel:45",
		"cube:0:2.5:1.2",
		"item:90|Custom Label",
		
		# Edge cases
		"clipboard#",
		"clipboard#pages",
		"clipboard#title:",
		"artifact#config:value with spaces and:colons"
	]
	
	print("\n=== Testing Config Parsing ===")
	for i in range(test_cases.size()):
		var test_token = test_cases[i]
		print("\nTest ", i + 1, ": '", test_token, "'")
		
		var result = grid_component._parse_interactable_token(test_token)
		
		print("  lookup_name: ", result.get("lookup_name", ""))
		print("  overrides: ", result.get("overrides", {}))
		print("  config_data: ", result.get("config_data", {}))
		print("  ---")
	
	print("\n=== Config Parsing Test Complete ===")
	
	# Clean up
	grid_component.queue_free()
