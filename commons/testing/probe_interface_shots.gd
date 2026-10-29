extends Node3D
## PICTURES OF THE INTERFACE: the inventory prism's four faces at their own resolution (each face's SubViewport
## saved as it is drawn in VR), with the tape chosen and a stroke laid so KNOBS, TAPE and PLACED have content,
## and a close-up of the prism over the left hand with the roll on the right. Not a test.
## Writes ada_run/inventory/ui/{face_hand, face_knobs, face_tape, face_placed, prism_closeup}.png
## Run: godot --path . --xr-mode off --resolution 1280x800 res://commons/testing/probe_interface_shots.tscn

const Rig = preload("res://commons/player/museum_rig.tscn")

var _left: XRControllerTracker
var _right: XRControllerTracker

func _ready() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/inventory/ui");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("d8d2c8");e.ambient_light_energy = .8;env.environment = e;add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-50, 30, 0);sun.light_energy = 1.1;add_child(sun)
	var floor_b := StaticBody3D.new();floor_b.collision_layer = 1;add_child(floor_b)
	var fs := CollisionShape3D.new();var fb := BoxShape3D.new();fb.size = Vector3(12, .1, 12);fs.shape = fb;fs.position.y = -.05;floor_b.add_child(fs)
	var fm := MeshInstance3D.new();var fbm := BoxMesh.new();fbm.size = fb.size;fm.mesh = fbm;fm.position.y = -.05
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");fm.material_override = fmat;floor_b.add_child(fm)
	var cam := Camera3D.new();add_child(cam);cam.fov = 45
	_left = XRControllerTracker.new();_left.name = &"left_hand";_left.type = XRServer.TRACKER_CONTROLLER;_left.hand = XRPositionalTracker.TRACKER_HAND_LEFT
	_right = XRControllerTracker.new();_right.name = &"right_hand";_right.type = XRServer.TRACKER_CONTROLLER;_right.hand = XRPositionalTracker.TRACKER_HAND_RIGHT
	_left.set_pose(&"aim", Transform3D(Basis(Vector3.RIGHT, PI / 5), Vector3(-0.25, 1.1, -0.3)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)   # held naturally, tip up: the top panel tilts back to the eye
	_hand(0.3);XRServer.add_tracker(_left);XRServer.add_tracker(_right)
	var rig: XROrigin3D = Rig.instantiate();add_child(rig);rig.current = true
	# the eye: close, in front of the left hand, slightly above - the prism turns to it
	cam.transform = Transform3D(Basis(), Vector3(-0.12, 1.62, 0.05)).looking_at(Vector3(-0.25, 1.17, -0.38));cam.current = true   # the eye, where the head is
	for i in 30:
		await get_tree().process_frame
	# the costume stands where the head is (built a few frames in, wherever it parents itself): for a picture
	# from the eye, every mesh that is not a hand, the prism, a strip or the floor goes
	for m in get_tree().root.find_children("*", "MeshInstance3D", true, false):
		var n: Node = m;var keep := false
		while n != null:
			if n.name in ["LeftHand", "RightHand", "InventoryPrism", "TapeStrip", "TapeStripe"] or n == floor_b:keep = true
			n = n.get_parent()
		if not keep:(m as MeshInstance3D).visible = false
	var p: Node = rig.get_node("InventoryPrism");p.toggle()   # the Void's left X
	# content: the tape chosen, dressed hazard, a stroke laid from the right hand
	p.choose("tape");p.set_tape_knob("tape", "hazard")
	for i in 4:
		await get_tree().process_frame
	var roll: Node3D = p.hand.worn_node()
	_hand(0.3);await _ticks(0.3)
	p._on_right_pressed("trigger_click");await _ticks(0.3)
	_hand(0.7);await _ticks(0.5)
	_hand(1.1);await _ticks(0.5)
	p._on_right_released("trigger_click")
	await get_tree().physics_frame
	p.refresh_faces()
	for i in 8:
		await get_tree().process_frame
	# each face as drawn
	for i in 4:
		var vp: SubViewport = p.faces[i].get_node("Viewport")
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var names: Array = ["hand", "knobs", "tape", "placed"]
	for i in 4:
		var vp: SubViewport = p.faces[i].get_node("Viewport")
		vp.get_texture().get_image().save_png(out_dir.path_join("face_%s.png" % names[i]))
	# the close-up, HAND face to the eye
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("prism_closeup.png"))
	# and turned to TAPE
	p.turn(2)
	for i in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("prism_closeup_tape.png"))
	print("[probe_interface_shots] wrote 6 pictures; strips laid: %d" % (roll.segments.size() if roll else -1))
	get_tree().quit(0)

func _hand(x: float) -> void:
	_right.set_pose(&"aim", Transform3D(Basis(Vector3.RIGHT, -PI / 4), Vector3(x, 1.0, 0)), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func _ticks(seconds: float) -> void:
	for i in int(ceil(seconds * Engine.physics_ticks_per_second)):
		await get_tree().physics_frame
