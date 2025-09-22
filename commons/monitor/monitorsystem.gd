# GameMonitorSystem.gd
# Creates 4 different monitor displays with camera views: overhead, third person, mirror, and side view
extends Node3D
class_name GameMonitorSystem

@export var monitor_size: Vector2 = Vector2(2.0, 1.2)
@export var monitor_spacing: float = 3.0
@export var target_player: Node3D  # Assign the player/target object in editor

# Monitor references
var overhead_monitor: Node3D
var third_person_monitor: Node3D
var mirror_monitor: Node3D
var side_monitor: Node3D

# Camera references
var overhead_camera: Camera3D
var third_person_camera: Camera3D
var mirror_camera: Camera3D
var side_camera: Camera3D

# Viewport references
var overhead_viewport: SubViewport
var third_person_viewport: SubViewport
var mirror_viewport: SubViewport
var side_viewport: SubViewport

func _ready():
	setup_monitors()
	setup_cameras()
	if target_player:
		setup_camera_tracking()

func setup_monitors():
	"""Create 4 monitor displays in a row"""
	
	# Overhead Monitor (top-down view)
	overhead_monitor = create_monitor("Overhead View", Vector3(-monitor_spacing * 1.5, 2, 0))
	overhead_viewport = overhead_monitor.get_node("SubViewport")
	
	# Third Person Monitor (behind player view)
	third_person_monitor = create_monitor("Third Person", Vector3(-monitor_spacing * 0.5, 2, 0))
	third_person_viewport = third_person_monitor.get_node("SubViewport")
	
	# Mirror Monitor (front-facing view)
	mirror_monitor = create_monitor("Mirror View", Vector3(monitor_spacing * 0.5, 2, 0))
	mirror_viewport = mirror_monitor.get_node("SubViewport")
	
	# Side Monitor (side profile view)
	side_monitor = create_monitor("Side View", Vector3(monitor_spacing * 1.5, 2, 0))
	side_viewport = side_monitor.get_node("SubViewport")

func create_monitor(title: String, position: Vector3) -> Node3D:
	"""Create a monitor with screen, frame, and label"""
	var monitor = Node3D.new()
	monitor.name = title.replace(" ", "") + "Monitor"
	monitor.position = position
	add_child(monitor)
	
	# Create SubViewport for camera rendering
	var viewport = SubViewport.new()
	viewport.name = "SubViewport"
	viewport.size = Vector2i(512, 320)  # 16:10 aspect ratio
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	monitor.add_child(viewport)
	
	# Create monitor frame (dark material)
	var frame = MeshInstance3D.new()
	frame.name = "Frame"
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(monitor_size.x + 0.2, monitor_size.y + 0.2, 0.1)
	frame.mesh = frame_mesh
	var frame_material = StandardMaterial3D.new()
	frame_material.albedo_color = Color(0.1, 0.1, 0.1)
	frame_material.metallic = 0.8
	frame_material.roughness = 0.3
	frame.material_override = frame_material
	frame.position = Vector3(0, 0, -0.05)
	monitor.add_child(frame)
	
	# Create screen display (3D sprite with viewport texture)
	var screen = Sprite3D.new()
	screen.name = "Screen"
	screen.texture = viewport.get_texture()
	screen.pixel_size = 0.001  # High resolution display
	
	# Create unshaded material for bright display
	var screen_material = StandardMaterial3D.new()
	screen_material.flags_unshaded = true
	screen_material.albedo_texture = viewport.get_texture()
	screen_material.emission_enabled = true
	screen_material.emission = Color(1, 1, 1)
	screen_material.emission_energy = 1.5
	screen.material_override = screen_material
	
	# Scale screen to fit monitor size
	screen.scale = Vector3(monitor_size.x, monitor_size.y, 1)
	monitor.add_child(screen)
	
	# Create title label above monitor
	var label = Label3D.new()
	label.name = "Label"
	label.text = title
	label.position = Vector3(0, monitor_size.y * 0.6, 0)
	label.font_size = 24
	var label_material = StandardMaterial3D.new()
	label_material.albedo_color = Color(0.9, 0.9, 0.9)
	label_material.emission_enabled = true
	label_material.emission = Color(0.5, 0.5, 0.5)
	label.material_override = label_material
	monitor.add_child(label)
	
	return monitor

func setup_cameras():
	"""Create cameras for each monitor viewport"""
	
	# Overhead Camera (top-down view)
	overhead_camera = Camera3D.new()
	overhead_camera.name = "OverheadCamera"
	overhead_camera.fov = 60
	overhead_viewport.add_child(overhead_camera)
	
	# Third Person Camera (behind player)
	third_person_camera = Camera3D.new()
	third_person_camera.name = "ThirdPersonCamera"
	third_person_camera.fov = 75
	third_person_viewport.add_child(third_person_camera)
	
	# Mirror Camera (front-facing)
	mirror_camera = Camera3D.new()
	mirror_camera.name = "MirrorCamera"
	mirror_camera.fov = 70
	mirror_viewport.add_child(mirror_camera)
	
	# Side Camera (side profile)
	side_camera = Camera3D.new()
	side_camera.name = "SideCamera"
	side_camera.fov = 65
	side_viewport.add_child(side_camera)

func setup_camera_tracking():
	"""Set up cameras to track the target player"""
	if not target_player:
		print("No target player assigned for camera tracking")
		return
	
	# Initial camera positioning
	update_camera_positions()

func _process(delta):
	"""Update camera positions each frame to follow target"""
	if target_player:
		update_camera_positions()

func update_camera_positions():
	"""Update all camera positions relative to target"""
	if not target_player:
		return
		
	var target_pos = target_player.global_position
	var target_forward = -target_player.global_transform.basis.z
	var target_right = target_player.global_transform.basis.x
	
	# Overhead Camera - directly above target
	if overhead_camera:
		overhead_camera.global_position = target_pos + Vector3(0, 10, 0)
		overhead_camera.look_at(target_pos, Vector3(0, 0, 1))  # North up
	
	# Third Person Camera - behind and above target
	if third_person_camera:
		var offset = -target_forward * 5 + Vector3(0, 3, 0)
		third_person_camera.global_position = target_pos + offset
		third_person_camera.look_at(target_pos + Vector3(0, 1, 0), Vector3.UP)
	
	# Mirror Camera - in front of target, looking back
	if mirror_camera:
		var offset = target_forward * 3 + Vector3(0, 1.5, 0)
		mirror_camera.global_position = target_pos + offset
		mirror_camera.look_at(target_pos + Vector3(0, 1, 0), Vector3.UP)
	
	# Side Camera - to the right of target
	if side_camera:
		var offset = target_right * 6 + Vector3(0, 2, 0)
		side_camera.global_position = target_pos + offset
		side_camera.look_at(target_pos + Vector3(0, 1, 0), Vector3.UP)

func set_target_player(new_target: Node3D):
	"""Change the target that cameras follow"""
	target_player = new_target
	if target_player:
		setup_camera_tracking()

func toggle_monitor_visibility(monitor_name: String, visible: bool):
	"""Show/hide specific monitors"""
	var monitor: Node3D
	match monitor_name.to_lower():
		"overhead":
			monitor = overhead_monitor
		"third_person":
			monitor = third_person_monitor
		"mirror":
			monitor = mirror_monitor
		"side":
			monitor = side_monitor
	
	if monitor:
		monitor.visible = visible

func set_monitor_positions(positions: Array[Vector3]):
	"""Reposition monitors to custom locations"""
	var monitors = [overhead_monitor, third_person_monitor, mirror_monitor, side_monitor]
	for i in range(min(monitors.size(), positions.size())):
		if monitors[i]:
			monitors[i].position = positions[i]

func get_camera_by_name(camera_name: String) -> Camera3D:
	"""Get specific camera reference"""
	match camera_name.to_lower():
		"overhead":
			return overhead_camera
		"third_person":
			return third_person_camera
		"mirror":
			return mirror_camera
		"side":
			return side_camera
	return null

# Monitor control functions
func set_monitor_brightness(brightness: float):
	"""Adjust brightness of all monitor screens"""
	var monitors = [overhead_monitor, third_person_monitor, mirror_monitor, side_monitor]
	for monitor in monitors:
		if monitor:
			var screen = monitor.get_node("Screen") as Sprite3D
			if screen and screen.material_override:
				screen.material_override.emission_energy = brightness

func set_monitor_size(new_size: Vector2):
	"""Resize all monitors"""
	monitor_size = new_size
	var monitors = [overhead_monitor, third_person_monitor, mirror_monitor, side_monitor]
	for monitor in monitors:
		if monitor:
			var screen = monitor.get_node("Screen") as Sprite3D
			var frame = monitor.get_node("Frame") as MeshInstance3D
			if screen:
				screen.scale = Vector3(monitor_size.x, monitor_size.y, 1)
			if frame and frame.mesh is BoxMesh:
				(frame.mesh as BoxMesh).size = Vector3(monitor_size.x + 0.2, monitor_size.y + 0.2, 0.1)
