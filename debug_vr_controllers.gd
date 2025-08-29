extends Node3D

# VR Controller Debug Script
# Run this to diagnose hand controller issues

func _ready():
	print("\n🔍 VR Controller Diagnostics")
	print("=" * 40)
	
	# Check XR interface
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface:
		print("✅ OpenXR interface found")
		print("  - Initialized: ", xr_interface.is_initialized())
		print("  - Name: ", xr_interface.get_name())
		print("  - Capabilities: ", xr_interface.get_capabilities())
	else:
		print("❌ OpenXR interface not found")
	
	# Check if VR is enabled
	print("🥽 VR Status:")
	print("  - Viewport XR enabled: ", get_viewport().use_xr)
	print("  - XR Server primary interface: ", XRServer.get_primary_interface())
	
	# Check for XR nodes in scene
	print("🎮 XR Nodes in scene:")
	find_xr_nodes(get_tree().root)
	
	# Check trackers
	print("📡 Available Trackers:")
	var tracker_count = XRServer.get_tracker_count()
	print("  - Tracker count: ", tracker_count)
	
	for i in range(tracker_count):
		var tracker = XRServer.get_tracker(i)
		if tracker:
			print("  - Tracker ", i, ": ", tracker.name, " (", tracker.type, ")")
	
	# Check action map
	print("🗺️ Action Map:")
	if ResourceLoader.exists("res://openxr_action_map.tres"):
		print("✅ OpenXR action map found")
	else:
		print("❌ OpenXR action map missing")
	
	print("=" * 40)

func find_xr_nodes(node: Node, depth: int = 0):
	var indent = "  ".repeat(depth)
	
	if node is XROrigin3D:
		print(indent + "📍 XROrigin3D: ", node.name)
	elif node is XRCamera3D:
		print(indent + "📷 XRCamera3D: ", node.name)
	elif node is XRController3D:
		print(indent + "🎮 XRController3D: ", node.name, " (tracker: ", node.tracker, ")")
	
	for child in node.get_children():
		find_xr_nodes(child, depth + 1)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("\n🔄 Re-running diagnostics...")
			_ready()
