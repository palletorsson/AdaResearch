extends Node3D
class_name FourSoftBodyController

# Configuration
@export var soft_body_scene_path: String = "res://algorithms/physicssimulation/softbodies/softbodystop/softbodybody.tscn"
@export var spacing: float = 3.0
@export var stop_times: Array[float] = [7.5, 11.0, 12.0, 12.0]
@export var show_timers: bool = true

# Internal variables
var soft_body_instances: Array[SoftBody3D] = []
var stop_timers: Array[Timer] = []
var ui_labels: Array[Label] = []
var stopped_states: Array[bool] = [false, false, false, false]

func _ready():
 
	create_four_soft_bodies()
	setup_stop_timers()

	
	print("🎯 Four SoftBody Controller ready!")
	print("   Positions: 2x2 grid with %.1fm spacing" % spacing)
	print("   Stop times: ", stop_times)



func create_four_soft_bodies():
	"""Create 4 soft bodies in a 2x2 grid"""
	
	var soft_body_scene = load(soft_body_scene_path)
	
	if not soft_body_scene:
		print("❌ Failed to load soft body scene: ", soft_body_scene_path)
		create_fallback_soft_bodies()
		return
	
	# 2x2 grid positions
	var positions = [
		Vector3(0, 3, 0),  # Front-left
		Vector3(spacing, 3, 0),   # Front-right  
		Vector3(0, 3, spacing),   # Back-left
		Vector3(spacing, 3, spacing)     # Back-right
	]
	
	for i in range(4):
		var soft_body_instance = soft_body_scene.instantiate()
		soft_body_instance.name = "SoftBody_" + str(i + 1)
		soft_body_instance.position = positions[i]
		
		add_child(soft_body_instance)
		
		# Find the actual SoftBody3D node in the instance
		var soft_body_node = find_soft_body_in_instance(soft_body_instance)
		if soft_body_node:
			soft_body_instances.append(soft_body_node)
			print("✅ Created SoftBody %d at %s" % [i + 1, positions[i]])
		else:
			print("⚠️  Could not find SoftBody3D in instance %d" % (i + 1))

func find_soft_body_in_instance(instance: Node) -> SoftBody3D:
	"""Find the SoftBody3D node within an instance"""
	
	# Check if the instance itself is a SoftBody3D
	if instance is SoftBody3D:
		return instance as SoftBody3D
	
	# Search children recursively
	for child in instance.get_children():
		if child is SoftBody3D:
			return child as SoftBody3D
		
		var found = find_soft_body_in_instance(child)
		if found:
			return found
	
	return null

func create_fallback_soft_bodies():
	"""Create basic soft bodies if scene loading fails"""
	
	print("🔄 Creating fallback soft bodies...")
	
	var positions = [
		Vector3(-spacing/2, 3, -spacing/2),
		Vector3(spacing/2, 3, -spacing/2),
		Vector3(-spacing/2, 3, spacing/2),
		Vector3(spacing/2, 3, spacing/2)
	]
	
	for i in range(4):
		var soft_body = SoftBody3D.new()
		soft_body.name = "FallbackSoftBody_" + str(i + 1)
		soft_body.position = positions[i]
		
		# Create sphere mesh
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.5
		sphere_mesh.height = 1.0
		soft_body.mesh = sphere_mesh
		
		# Configure physics
		soft_body.linear_stiffness = 0.5
		soft_body.damping_coefficient = 0.01
		soft_body.total_mass = 1.0
		soft_body.simulation_precision = 5
		
		# Create colorful material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.from_hsv(i * 0.25, 0.8, 1.0)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.8
		soft_body.surface_set_material(0, material)
		
		add_child(soft_body)
		soft_body_instances.append(soft_body)

func setup_stop_timers():
	"""Setup individual stop timers for each soft body"""
	
	for i in range(soft_body_instances.size()):
		var timer = Timer.new()
		timer.name = "StopTimer_" + str(i + 1)
		timer.wait_time = stop_times[i] if i < stop_times.size() else 5.0
		timer.one_shot = true
		timer.autostart = true
		timer.timeout.connect(_on_stop_timeout.bind(i))
		
		add_child(timer)
		stop_timers.append(timer)
		
		print("⏰ Timer %d set for %.1f seconds" % [i + 1, timer.wait_time])


func _process(delta):
	"""Update UI timers"""
	
	if not show_timers:
		return
	
	for i in range(stop_timers.size()):
		if i < ui_labels.size() and i < stop_timers.size():
			var timer = stop_timers[i]
			var label = ui_labels[i]
			
			if not stopped_states[i] and timer.time_left > 0:
				label.text = "SoftBody %d: %.1fs" % [i + 1, timer.time_left]
				
				# Color coding
				if timer.time_left < 1.0:
					label.add_theme_color_override("font_color", Color.RED)
				elif timer.time_left < 2.0:
					label.add_theme_color_override("font_color", Color.YELLOW)
				else:
					label.add_theme_color_override("font_color", Color.WHITE)

func _on_stop_timeout(index: int):
	"""Called when a specific timer expires"""
	
	if index >= soft_body_instances.size():
		return
	
	var soft_body = soft_body_instances[index]
	
	print("⏰ Timer %d expired - stopping SoftBody: %s" % [index + 1, soft_body.name])
	stop_soft_body(index)

func stop_soft_body(index: int):
	"""Stop a specific soft body"""
	
	if index >= soft_body_instances.size() or stopped_states[index]:
		return
	
	var soft_body = soft_body_instances[index]
	stopped_states[index] = true
	
	# Stop using SoftBody3D methods
	soft_body.set_process_mode(Node.PROCESS_MODE_DISABLED)
	soft_body.damping_coefficient = 100.0
	soft_body.linear_stiffness = 1.0
	
	# Visual feedback

	
	# Update UI
	if index < ui_labels.size():
		ui_labels[index].text = "SoftBody %d: STOPPED!" % [index + 1]
		ui_labels[index].add_theme_color_override("font_color", Color.BLUE)
	
	print("🧊 SoftBody %d stopped and frozen!" % [index + 1])

func restart_all():
	"""Restart all soft bodies"""
	
	print("🔄 Restarting all soft bodies...")
	
	for i in range(soft_body_instances.size()):
		if stopped_states[i]:
			restart_soft_body(i)
	
	# Restart timers
	for timer in stop_timers:
		timer.start()

func restart_soft_body(index: int):
	"""Restart a specific soft body"""
	
	if index >= soft_body_instances.size():
		return
	
	var soft_body = soft_body_instances[index]
	stopped_states[index] = false
	
	# Re-enable
	soft_body.set_process_mode(Node.PROCESS_MODE_INHERIT)
	soft_body.damping_coefficient = 0.01
	soft_body.linear_stiffness = 0.5
	
	# Reset visual
	var material = soft_body.surface_get_material(0)
	if material is StandardMaterial3D:
		var std_mat = material as StandardMaterial3D
		std_mat.emission_enabled = false
		# Reset to original color based on index
		std_mat.albedo_color = Color.from_hsv(index * 0.25, 0.8, 1.0)
		std_mat.albedo_color.a = 0.8
	
	print("✅ SoftBody %d restarted!" % [index + 1])

func _input(event):
	"""Handle input"""
	
	if event.is_action_pressed("ui_accept"):  # Space key
		restart_all()
	
	if event.is_action_pressed("ui_select"):  # Enter key
		print("📊 Status Report:")
		for i in range(soft_body_instances.size()):
			var status = "RUNNING" if not stopped_states[i] else "STOPPED"
			print("   SoftBody %d: %s" % [i + 1, status])
	
	# Stop individual soft bodies with number keys
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				if not stopped_states[0]: stop_soft_body(0)
			KEY_2:
				if not stopped_states[1]: stop_soft_body(1)
			KEY_3:
				if not stopped_states[2]: stop_soft_body(2)
			KEY_4:
				if not stopped_states[3]: stop_soft_body(3)
