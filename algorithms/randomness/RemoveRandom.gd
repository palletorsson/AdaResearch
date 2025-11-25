extends Node3D

# Grid selection mode
@export_enum("Range", "Column", "Row", "All") var selection_mode: String = "Range"

# Column/Row selection (used when selection_mode is "Column" or "Row")
@export var target_column: int = 0  # X coordinate
@export var target_row: int = 0     # Z coordinate

# Configurable range for cube removal (used when selection_mode is "Range")
@export var x_min: float = 2.0
@export var x_max: float = 4.0
@export var y_min: float = 0.0
@export var y_max: float = 2.0
@export var z_min: float = 2.0
@export var z_max: float = 21.0

# Visual enhancement parameters
@export var removal_speed: float = 1.0
@export var highlight_duration: float = 0.3
@export var show_removal_effects: bool = true

@export_group("MultiMesh")
@export var multimesh_path: NodePath = "../GridMultiMesh"

var timer: Timer
var multimesh_instance: MultiMeshInstance3D = null
var multimesh: MultiMesh = null
var active_instances: Array[int] = []  # Track which instances are still active
var initial_count: int = 0
var removed_count: int = 0

func _ready():
	# Find MultiMesh
	if not multimesh_path.is_empty():
		multimesh_instance = get_node_or_null(multimesh_path)

	if not multimesh_instance:
		multimesh_instance = _find_multimesh_instance(get_parent())

	if multimesh_instance:
		multimesh = multimesh_instance.multimesh
		if multimesh and multimesh.instance_count > 0:
			print("✅ Found MultiMesh with %d instances" % multimesh.instance_count)
			find_all_instances()
		else:
			push_warning("MultiMesh found but has no instances")
			return
	else:
		push_warning("Could not find MultiMeshInstance3D")
		return

	# Create timer
	timer = Timer.new()
	timer.wait_time = 0.5 / removal_speed
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()

func _find_multimesh_instance(node: Node) -> MultiMeshInstance3D:
	if node is MultiMeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_multimesh_instance(child)
		if result:
			return result
	return null

func find_all_instances():
	"""Find all instances that match selection criteria"""
	if not multimesh:
		return

	active_instances.clear()

	for i in range(multimesh.instance_count):
		var transform = multimesh.get_instance_transform(i)
		if _should_include_instance(transform.origin):
			active_instances.append(i)

	initial_count = active_instances.size()
	print("RemoveRandom: Selected %d instances based on mode '%s'" % [initial_count, selection_mode])

func _should_include_instance(pos: Vector3) -> bool:
	"""Check if an instance should be included based on selection mode"""
	match selection_mode:
		"All":
			return true
		"Column":
			return abs(pos.x - target_column) < 0.1
		"Row":
			return abs(pos.z - target_row) < 0.1
		"Range":
			return (pos.x >= x_min and pos.x <= x_max and
					pos.y >= y_min and pos.y <= y_max and
					pos.z >= z_min and pos.z <= z_max)
	return false

func _on_timer_timeout():
	"""Called every 0.5 seconds to remove one instance"""
	if active_instances.is_empty():
		print("No more instances to remove!")
		timer.stop()
		return

	# Pick a random instance to remove
	var random_index = randi() % active_instances.size()
	var instance_index = active_instances[random_index]

	# Highlight before removal
	highlight_instance_for_removal(instance_index)

	# Wait for highlight duration
	await get_tree().create_timer(highlight_duration).timeout

	# Remove by scaling to zero
	var transform = multimesh.get_instance_transform(instance_index)
	var removal_position = transform.origin
	transform.basis = Basis().scaled(Vector3.ZERO)
	multimesh.set_instance_transform(instance_index, transform)

	# Make transparent if colors enabled
	if multimesh.use_colors:
		multimesh.set_instance_color(instance_index, Color(0, 0, 0, 0))

	# Remove from active list
	active_instances.remove_at(random_index)
	removed_count += 1

	# Create visual effect
	if show_removal_effects:
		create_removal_effect(removal_position)

	print("Removed: %d/%d (%.1f%%)" % [removed_count, initial_count, (removed_count / float(initial_count)) * 100.0])

func highlight_instance_for_removal(instance_index: int):
	"""Highlight an instance before removing it"""
	if not multimesh or not multimesh.use_colors:
		return

	# Flash red
	multimesh.set_instance_color(instance_index, Color(1.0, 0.2, 0.2))

	# Pulsing scale effect
	var transform = multimesh.get_instance_transform(instance_index)
	var original_scale = transform.basis.get_scale()

	var tween = create_tween()
	tween.set_loops(2)
	tween.tween_method(func(scale_mult: float):
		var t = multimesh.get_instance_transform(instance_index)
		t.basis = Basis().scaled(original_scale * scale_mult)
		multimesh.set_instance_transform(instance_index, t)
	, 1.0, 1.2, highlight_duration / 4)
	tween.tween_method(func(scale_mult: float):
		var t = multimesh.get_instance_transform(instance_index)
		t.basis = Basis().scaled(original_scale * scale_mult)
		multimesh.set_instance_transform(instance_index, t)
	, 1.2, 1.0, highlight_duration / 4)

func create_removal_effect(position: Vector3):
	"""Create visual effect when an instance is removed"""
	# Simple particle burst
	var particles = GPUParticles3D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.5
	particles.explosiveness = 1.0

	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 1, 0)
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 5.0
	material.gravity = Vector3(0, -9.8, 0)
	particles.process_material = material

	add_child(particles)

	# Auto-cleanup
	await get_tree().create_timer(1.0).timeout
	particles.queue_free()

# Public API
func start_removal():
	"""Start removing instances"""
	if timer:
		timer.start()
		print("Started instance removal")

func stop_removal():
	"""Stop removing instances"""
	if timer:
		timer.stop()
		print("Stopped instance removal")

func reset_and_find_instances():
	"""Reset and find all instances again"""
	stop_removal()
	find_all_instances()
	removed_count = 0
	print("Reset complete. Found %d instances." % active_instances.size())
