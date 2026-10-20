extends Node3D
## One compact board using the shared demo's XR hand/pointer button mechanism.
signal action_requested(index: int)
const PushButton = preload("res://commons/interactables/push_button_front.tscn")
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const ValueSurface = preload("res://commons/ui/control_value_surface.gd")
const NAMES := ["RESET 42", "CURRENT VIEWS", "KEEP", "REPLAY", "EXPORT", "IMPORT", "CLEAR KEPT", "NEXT SEED"]
var face: Node3D
var buttons: Array[Node3D] = []
var close_button: Node3D
var reopen_button: Node3D
var display: Dictionary
var is_open := true

func _ready() -> void:
	face = Node3D.new(); face.name = "BoardFace"; add_child(face)
	var backing := MeshInstance3D.new(); backing.name = "Backing"
	var box := BoxMesh.new(); box.size = Vector3(0.88, 0.46, 0.035)
	backing.mesh = box; backing.position.z = -0.025
	var material := StandardMaterial3D.new(); material.albedo_color = Color(0.81, 0.80, 0.76)
	material.roughness = 0.85; backing.material_override = material; face.add_child(backing)
	var heading := BakedText.make_label_mesh("SEED BENCH / 48 VALUES", Color(0.09,0.10,0.11), Vector2(0.55,0.04), 1800, true)
	heading.position = Vector3(-0.10,0.175,-0.006); face.add_child(heading)
	for i in range(8):
		var button := make_button(NAMES[i], Vector2(0.175,0.065))
		button.name = "Action_%s" % i
		button.position = Vector3((i % 4 - 1.5) * 0.20, 0.065 - (i / 4) * 0.10, 0)
		face.add_child(button); buttons.append(button)
		button.pressed.connect(func():
			if is_open: action_requested.emit(i))
	close_button = make_button("CLOSE", Vector2(0.12,0.05))
	close_button.name = "Close"; close_button.position = Vector3(0.33,0.175,0)
	face.add_child(close_button); close_button.pressed.connect(func(): set_open(false))
	reopen_button = make_button("CONTROLS", Vector2(0.20,0.065))
	reopen_button.name = "Reopen"; reopen_button.position = Vector3(0.28,0.175,0)
	add_child(reopen_button); reopen_button.pressed.connect(func(): set_open(true))
	display = ValueSurface.build(face, Vector2(0.79,0.09), Vector3(0,-0.155,-0.005))
	display.viewport.size = Vector2i(1000,140)
	display.viewport.get_child(0).size = Vector2(1000,140)
	display.label.size = Vector2(1000,140)
	display.label.add_theme_font_size_override("font_size", 30)
	display.label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	set_open(true)

func make_button(words: String, size: Vector2) -> Node3D:
	# Replace cap, body collider AND touch target before entering the tree.
	# Do not nonuniformly scale physics controls or keep a round collision target.
	var button: Node3D = PushButton.instantiate()
	button.transform = Transform3D.IDENTITY
	button.released_color = Color(0.18,0.21,0.23)
	button.selected_color = Color(0.10,0.55,0.44)
	button.pressed_color = Color(0.88,0.42,0.12)
	button.released_emission_energy = 0.02; button.pressed_emission_energy = 0.15
	var base: StaticBody3D = button.get_node("ButtonBase")
	base.transform = Transform3D.IDENTITY; base.position.z = -0.003
	var base_mesh := BoxMesh.new(); base_mesh.size = Vector3(size.x+0.012,size.y+0.012,0.012)
	base.get_node("BaseMesh").mesh = base_mesh
	var cap: StaticBody3D = button.get_node("Button")
	cap.transform = Transform3D.IDENTITY; cap.position.z = 0.015; cap.collision_layer = 0
	var cap_mesh := BoxMesh.new(); cap_mesh.size = Vector3(size.x,size.y,0.018)
	cap.get_node("ButtonMesh").mesh = cap_mesh
	var cap_shape := BoxShape3D.new(); cap_shape.size = cap_mesh.size
	cap.get_node("CollisionShape3D").shape = cap_shape
	var area: Area3D = button.get_node("InteractableAreaButton")
	area.transform = Transform3D.IDENTITY; area.displacement = Vector3(0,0,-0.009)
	var touch := BoxShape3D.new(); touch.size = Vector3(size.x+0.008,size.y+0.008,0.045)
	area.get_node("CollisionShape3D").shape = touch
	area.get_node("CollisionShape3D").position = Vector3(0,0,0.025)
	var pose: Area3D = button.get_node("HandPoseArea")
	pose.transform = Transform3D.IDENTITY
	var pose_shape := BoxShape3D.new(); pose_shape.size = Vector3(size.x+0.02,size.y+0.02,0.07)
	pose.get_node("CollisionShape3D").shape = pose_shape
	pose.get_node("CollisionShape3D").position = Vector3(0,0,0.025)
	var ink := BakedText.make_label_mesh(words, Color(0.96,0.96,0.91), size-Vector2(0.014,0.014), 2000, true)
	ink.name = "Caption"; ink.position.z = 0.010; cap.add_child(ink)
	return button

func enable_button(button: Node3D, enabled: bool) -> void:
	button.visible = enabled
	var area: Area3D = button.get_node("InteractableAreaButton")
	# Clear pointer ownership when closing while a controller is still pressed.
	for pointer in area._pointers.keys(): area._release_pointer(pointer)
	for item in area._trigger_items.keys(): area._on_button_exited(item)
	area.set_deferred("collision_layer", 1048576 if enabled else 0)
	area.set_deferred("collision_mask", 393216 if enabled else 0)
	area.get_node("CollisionShape3D").set_deferred("disabled", not enabled)
	button.get_node("HandPoseArea/CollisionShape3D").set_deferred("disabled", not enabled)

func set_open(value: bool) -> void:
	is_open = value; face.visible = value
	for button in buttons: enable_button(button, value)
	enable_button(close_button, value); enable_button(reopen_button, not value)

func set_reading(seed_text: String, mapping: String, kept: bool, message: String) -> void:
	display.label.text = "SEED %s   /   %s   /   %s\n%s" % [seed_text, mapping,
		"KEPT" if kept else "NO KEPT COPY", message]
	display.viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	buttons[0].set_selected(false)
	buttons[1].set_selected(mapping == "FIVE VIEWS")
