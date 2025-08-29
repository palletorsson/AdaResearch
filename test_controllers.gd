extends Node3D

func _ready():
	# Simple controller test
	var xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("🎮 VR initialized - controllers should work")
		get_viewport().use_xr = true
	else:
		print("❌ VR not initialized - controllers won't work")

func _process(_delta):
	# Check for controller input every frame
	if Input.is_action_just_pressed("trigger_click"):
		print("🔫 Trigger pressed!")
	
	# Check XR controllers directly
	for i in range(XRServer.get_tracker_count()):
		var tracker = XRServer.get_tracker(i)
		if tracker and tracker.type == XRServer.TRACKER_CONTROLLER:
			if tracker.get_input("trigger_click"):
				print("🎮 Controller ", i, " trigger pressed!")
