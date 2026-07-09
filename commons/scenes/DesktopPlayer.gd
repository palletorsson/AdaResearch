extends CharacterBody3D
class_name DesktopPlayer

# Movement settings
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var gravity: float = 9.8
@export var use_gravity: bool = true
@export var allow_jump: bool = true
@export var fly_mode: bool = false     # F toggles walk <-> fly at runtime
@export var interaction_distance: float = 5.0
var _fly_key_held: bool = false

# Camera reference
@onready var camera: Camera3D = $Head/Camera3D
@onready var head: Node3D = $Head
@onready var interaction_raycast: RayCast3D = $Head/InteractionRaycast
@onready var crosshair: ColorRect = $Head/Camera3D/Crosshair
@onready var desktop_pointer = $Head/DesktopInteractionPointer

# Mouse look
var mouse_motion: Vector2 = Vector2.ZERO
var camera_rotation: Vector2 = Vector2.ZERO

# Interaction
var current_interactable: Node = null

# Voxel editing mode
var voxel_edit_mode: bool = false
var _voxel_controller: VoxelEditController = null
var _voxel_structure: GridStructureComponent = null
var _voxel_map_name: String = ""

func _ready():
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if GameManager:
		GameManager.register_player(self)

	# Auto-bootstrap if running standalone
	if get_parent() == get_tree().root:
		print("DesktopPlayer: Running standalone - redirecting to Lab Desktop scene...")
		call_deferred("_redirect_to_lab")

func _redirect_to_lab():
	get_tree().change_scene_to_file("res://commons/scenes/lab_desktop.tscn")

func _input(event):
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_motion = event.relative

	# Toggle mouse capture with ESC
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# E key toggles voxel edit mode
	if event is InputEventKey and event.pressed and not event.echo:
		var keycode: int = (event as InputEventKey).keycode
		if keycode == KEY_E and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_toggle_voxel_mode()
			return
		# Ctrl+S save in voxel mode
		if voxel_edit_mode and (event as InputEventKey).ctrl_pressed:
			if keycode == KEY_S:
				_voxel_save()
				return
			if keycode == KEY_Z:
				if _voxel_controller:
					_voxel_controller.undo()
				return
			if keycode == KEY_Y:
				if _voxel_controller:
					_voxel_controller.redo()
				return

	# Mouse clicks
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed:
			if voxel_edit_mode:
				# Voxel mode: left-click add, right-click remove
				if event.button_index == MOUSE_BUTTON_LEFT:
					if _voxel_controller:
						_voxel_controller.try_add()
				elif event.button_index == MOUSE_BUTTON_RIGHT:
					if _voxel_controller:
						_voxel_controller.try_remove()
			else:
				# Normal mode: left-click interacts (teleport, artifacts)
				if event.button_index == MOUSE_BUTTON_LEFT:
					# Let the pointer handle VR interactables (sliders, buttons, knobs)
					if desktop_pointer and (desktop_pointer.has_hover_target() or desktop_pointer.is_dragging()):
						pass  # Pointer system handles this via its own _input
					else:
						_try_interact()

func _physics_process(delta: float) -> void:
	# Apply mouse look
	_apply_camera_rotation(delta)

	# G toggles walk <-> fly (fly: Space up, Ctrl down). Was F, but F is the
	# flashlight — freed it to avoid the double-bind.
	if Input.is_key_pressed(KEY_G):
		if not _fly_key_held:
			_fly_key_held = true
			fly_mode = not fly_mode
			print("DesktopPlayer: %s mode" % ("FLY" if fly_mode else "WALK"))
	else:
		_fly_key_held = false

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var speed = sprint_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed

	if fly_mode:
		# Fly toward where you LOOK: forward/back follow the camera's full 3D
		# look direction (pitch included), so W climbs when you look up.
		var basis: Basis = camera.global_transform.basis if camera else transform.basis
		var dir := (basis * Vector3(input_dir.x, 0, input_dir.y))
		if dir.length() > 0.001:
			dir = dir.normalized()
		# Space / Ctrl add pure vertical on top of the look direction.
		if Input.is_key_pressed(KEY_SPACE):
			dir.y += 1.0
		if Input.is_key_pressed(KEY_CTRL):
			dir.y -= 1.0
		velocity = dir * speed
		move_and_slide()
		return

	# ── walk mode ────────────────────────────────────────────────────────
	if use_gravity:
		if not is_on_floor():
			velocity.y -= gravity * delta
		if allow_jump and Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = jump_velocity
	else:
		velocity.y = 0.0

	var direction := Vector3.ZERO
	if input_dir != Vector2.ZERO:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func _apply_camera_rotation(_delta: float):
	if mouse_motion == Vector2.ZERO:
		return

	# Rotate horizontally (around Y axis)
	camera_rotation.y -= mouse_motion.x * mouse_sensitivity

	# Rotate vertically (around X axis) with clamping
	camera_rotation.x -= mouse_motion.y * mouse_sensitivity
	camera_rotation.x = clamp(camera_rotation.x, -PI/2, PI/2)

	# Apply rotations
	rotation.y = camera_rotation.y
	if head:
		head.rotation.x = camera_rotation.x

	mouse_motion = Vector2.ZERO

func _process(_delta: float):
	_check_for_interactable()
	_update_crosshair_for_pointer()

	# Update voxel edit controller raycast from camera center
	if voxel_edit_mode and _voxel_controller and camera:
		var center := get_viewport().get_visible_rect().size * 0.5
		var origin := camera.project_ray_origin(center)
		var dir := camera.project_ray_normal(center)
		_voxel_controller.update_target_from_ray(origin, dir)

func _check_for_interactable():
	"""Check if looking at an interactable object"""
	if not interaction_raycast:
		return

	var found_interactable = false

	# First try raycast collision
	if interaction_raycast.is_colliding():
		var collider = interaction_raycast.get_collider()
		if collider and _is_interactable(collider):
			current_interactable = collider
			_highlight_interactable(collider, true)
			found_interactable = true

	# If raycast didn't find anything, check for nearby utilities
	if not found_interactable:
		found_interactable = _check_nearby_utilities()

	# Clear highlight if nothing found
	if not found_interactable:
		if current_interactable:
			_highlight_interactable(current_interactable, false)
		current_interactable = null

func _check_nearby_utilities() -> bool:
	"""Check for nearby utilities/teleporters even without physics collision"""
	var ray_origin = camera.global_position
	var ray_direction = -camera.global_transform.basis.z
	var ray_length = interaction_distance

	# Get all utilities in the scene
	var utilities = get_tree().get_nodes_in_group("utility")

	# Debug - print once every 60 frames
	if Engine.get_frames_drawn() % 60 == 0:
		print("DesktopPlayer: Found %d utilities in 'utility' group" % utilities.size())

	for utility in utilities:
		if utility is Node3D:
			var distance = ray_origin.distance_to(utility.global_position)
			if distance < ray_length:
				# Check if utility is roughly in the direction we're looking
				var to_utility = (utility.global_position - ray_origin).normalized()
				var dot = ray_direction.dot(to_utility)
				if dot > 0.95:  # Within ~18 degree cone
					# Only print if this is a new interactable
					var was_new = (current_interactable != utility)
					current_interactable = utility
					_highlight_interactable(utility, true)
					if was_new:
						print("DesktopPlayer: Found utility in view: %s" % utility.name)
					return true

	return false

func _is_interactable(node: Node) -> bool:
	"""Check if a node is interactable"""
	# Check if it's in an interactable group
	if node.is_in_group("artifact") or node.is_in_group("interactable") or node.is_in_group("utility"):
		return true

	# Check if it's a teleporter
	if node.has_method("get_destination"):
		return true

	# Check for parent that might be the interactable
	var parent = node.get_parent()
	if parent:
		if parent.is_in_group("artifact") or parent.is_in_group("interactable") or parent.is_in_group("utility"):
			return true
		if parent.has_method("get_destination"):
			return true

	return false

func _highlight_interactable(_node: Node, highlight: bool):
	"""Visual feedback for interactable objects"""
	# Update crosshair color
	if crosshair:
		if highlight:
			crosshair.modulate = Color(0, 1, 0)  # Green when looking at interactable
		else:
			crosshair.modulate = Color(1, 1, 1)  # White normally

func _try_interact():
	"""Attempt to interact with current interactable"""
	if not current_interactable:
		print("DesktopPlayer: No interactable to interact with")
		return

	var target = current_interactable

	# Check parent if current is a mesh/collision shape
	if not target.is_in_group("artifact") and not target.is_in_group("interactable") and not target.is_in_group("utility"):
		target = target.get_parent()

	if not target:
		print("DesktopPlayer: Target became null after parent check")
		return

	print("DesktopPlayer: Interacting with: %s (groups: %s)" % [target.name, target.get_groups()])

	# Handle teleporters specially (check if in utility group or has teleport methods)
	if target.is_in_group("utility") or target.has_method("get_destination"):
		print("DesktopPlayer: Detected as utility/teleporter")

		# Try different teleporter activation methods
		if target.has_method("_on_teleport_area_body_entered"):
			print("DesktopPlayer: Calling _on_teleport_area_body_entered")
			target._on_teleport_area_body_entered(self)
		elif target.has_method("_on_TeleportArea_body_entered"):
			print("DesktopPlayer: Calling _on_TeleportArea_body_entered")
			target._on_TeleportArea_body_entered(self)
		elif target.has_method("_trigger_touch_interaction"):
			print("DesktopPlayer: Calling _trigger_touch_interaction")
			target._trigger_touch_interaction(global_position)
		elif target.has_method("_start_teleport_sequence"):
			print("DesktopPlayer: Calling _start_teleport_sequence")
			target._start_teleport_sequence()
		else:
			print("DesktopPlayer: No known teleport method found on: %s" % target.name)
		return

	# Try different interaction methods
	if target.has_method("interact"):
		target.interact()
	elif target.has_method("activate"):
		target.activate()
	elif target.has_signal("activated"):
		target.emit_signal("activated")

	# Also emit a signal that LabManager can listen to
	if target.is_in_group("artifact"):
		# Find LabManager and notify
		var lab_manager = get_tree().get_first_node_in_group("lab_manager")
		if lab_manager and lab_manager.has_method("_on_artifact_interacted"):
			lab_manager._on_artifact_interacted(target.name)

		# Try to get artifact ID from metadata
		var artifact_id = target.get_meta("artifact_id", target.name)
		print("DesktopPlayer: Activated artifact: %s" % artifact_id)


func _update_crosshair_for_pointer() -> void:
	if not crosshair or not desktop_pointer:
		return
	if voxel_edit_mode:
		return  # Voxel mode has its own crosshair color
	if desktop_pointer.is_dragging():
		crosshair.modulate = Color(1.0, 0.6, 0.1)  # Orange while dragging
	elif desktop_pointer.has_hover_target():
		crosshair.modulate = Color(1.0, 1.0, 0.2)  # Yellow when hovering a control
	elif current_interactable:
		pass  # Green set by _highlight_interactable
	else:
		crosshair.modulate = Color(1, 1, 1)


# ═══════════════════════════════════════════════════════════════
# VOXEL EDITING MODE — press V to toggle, L-click add, R-click remove
# ═══════════════════════════════════════════════════════════════

func _toggle_voxel_mode() -> void:
	voxel_edit_mode = not voxel_edit_mode

	if voxel_edit_mode:
		# Find GridStructureComponent in the scene
		_voxel_structure = _find_in_tree(get_tree().root, "GridStructureComponent") as GridStructureComponent
		if not _voxel_structure:
			print("DesktopPlayer: No GridStructureComponent found — voxel mode disabled")
			voxel_edit_mode = false
			return

		# Find map name from GridDataComponent
		var data_comp = _find_in_tree(get_tree().root, "GridDataComponent")
		if data_comp and data_comp.has_method("get_current_map_name"):
			_voxel_map_name = data_comp.get_current_map_name()
		if data_comp and data_comp.has_method("get_structure_data"):
			_voxel_structure.enable_editing(data_comp.get_structure_data())

		# Create edit controller
		if not _voxel_controller:
			_voxel_controller = VoxelEditController.new()
			_voxel_controller.name = "VoxelEditController"
			_voxel_controller.structure_component = _voxel_structure
			_voxel_controller.cube_size = _voxel_structure.cube_size
			add_child(_voxel_controller)

		print("DesktopPlayer: 🔨 VOXEL EDIT MODE ON — L-click=add R-click=remove Ctrl+S=save")
	else:
		print("DesktopPlayer: 🔨 Voxel edit mode OFF")

	# Update crosshair color
	if crosshair:
		crosshair.color = Color(0.3, 0.7, 1.0, 0.8) if voxel_edit_mode else Color(1, 1, 1, 0.5)


func _voxel_save() -> void:
	if not _voxel_structure or _voxel_map_name.is_empty():
		print("DesktopPlayer: Cannot save — no map loaded")
		return
	var ok := VoxelSaveManager.save(_voxel_map_name, _voxel_structure)
	if ok:
		print("DesktopPlayer: 💾 SAVED map: %s" % _voxel_map_name)


func _find_in_tree(node: Node, class_name_str: String) -> Node:
	if node.get_class() == class_name_str or (node is GridStructureComponent and class_name_str == "GridStructureComponent"):
		return node
	# Also check node name
	if node.name == class_name_str:
		return node
	for child in node.get_children():
		var found := _find_in_tree(child, class_name_str)
		if found:
			return found
	return null
