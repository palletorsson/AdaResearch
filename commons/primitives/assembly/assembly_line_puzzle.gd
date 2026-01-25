extends Node3D

## Assembly Line Puzzle - Composite Product Version
##
## Ghost forms require multiple shapes (cube + pyramid combinations).
## Place shapes in the correct slots within the ghost projection.
## When all slots filled, product moves down the line.
## Supports different puzzle types: houses, lab equipment, etc.

const CUBE_SCENE := preload("res://commons/primitives/cubes/grab_cube.tscn")
const PYRAMID_SCENE := preload("res://commons/primitives/pyramid/grab_pyramid.tscn")
const CYLINDER_SCENE := preload("res://commons/primitives/cylinder/grab_cylinder.tscn")
const DISC_SCENE := preload("res://commons/primitives/cylinder/grab_disc.tscn")

signal shape_placed(shape_type: String, slot_index: int)
signal product_completed(product_number: int)
signal all_products_completed()

enum ShapeType { CUBE, PYRAMID, CYLINDER, DISC }

enum PuzzleType {
	HOUSES,      # House, house, tall house
	LAB_EQUIPMENT,  # Half-Life style: health charger, terminal, specimen jar
	SCIENTIFIC_EQUIPMENT  # Real lab equipment: microscope, scales, multimeter
}

# Product definitions - each product has slots for shapes
class ProductDef:
	var slots: Array[Dictionary] = []  # Each slot: {type: ShapeType, offset: Vector3, scale: Vector3 (optional)}
	var name: String = ""  # Product name for display
	var reward_type: String = ""  # What reward mesh to create

	func _init(slot_array: Array[Dictionary], product_name: String = "", reward: String = ""):
		for s in slot_array:
			slots.append(s)
		name = product_name
		reward_type = reward

@export var puzzle_type: PuzzleType = PuzzleType.HOUSES

## Single product filter - if set, only build this specific product
## e.g., "scales", "microscope", "multimeter"
var _single_product_filter: String = ""

@export_group("Input Conveyor")
@export var spawn_interval: float = 2.5
@export var input_speed: float = 0.10
@export var input_start: Vector3 = Vector3(1.0, 0.5, 0)
@export var input_end: Vector3 = Vector3(-0.8, 0.5, 0)

@export_group("Production Station")
@export var station_position: Vector3 = Vector3(0, 0.5, -0.4)
@export var ghost_color: Color = Color(0.3, 0.8, 1.0, 0.4)
@export var slot_match_distance: float = 0.08
@export var snap_duration: float = 0.25

@export_group("Output Conveyor")
@export var output_speed: float = 0.12
@export var output_start: Vector3 = Vector3(0, 0.5, -0.4)
@export var output_end: Vector3 = Vector3(0, 0.5, -1.4)

@export_group("Visuals")
@export var conveyor_color: Color = Color(0.9, 0.9, 0.95)
@export var shape_scale: float = 0.07

# Product sequence
var _product_sequence: Array[ProductDef] = []
var _current_product_index: int = 0

# Ghost and slots
var _ghost_container: Node3D
var _ghost_meshes: Array[MeshInstance3D] = []
var _slot_filled: Array[bool] = []
var _slot_pieces: Array[Node3D] = []

# Conveyor pieces
var _input_pieces: Array[Node3D] = []
var _output_products: Array[Node3D] = []

# Timers
var _spawn_timer: float = 0.0

# Score
var _products_completed: int = 0

func _ready() -> void:
	_setup_product_sequence()
	_create_input_conveyor()
	_create_output_conveyor()
	_create_production_station()
	_spawn_timer = spawn_interval * 0.5
	_setup_current_product_ghost()

func _process(delta: float) -> void:
	_spawn_timer += delta
	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		_spawn_shape_for_current_product()

	_update_input_conveyor(delta)
	_update_output_conveyor(delta)
	_check_slot_matches()

func _setup_product_sequence() -> void:
	match puzzle_type:
		PuzzleType.HOUSES:
			_setup_houses_sequence()
		PuzzleType.LAB_EQUIPMENT:
			_setup_lab_equipment_sequence()
		PuzzleType.SCIENTIFIC_EQUIPMENT:
			_setup_scientific_equipment_sequence()


func _setup_houses_sequence() -> void:
	var cube_height = shape_scale * 2
	var filter = _single_product_filter.to_lower()

	# Product 1: House (cube bottom + pyramid roof)
	if filter == "" or filter == "house":
		var p1 = ProductDef.new([
			{"type": ShapeType.CUBE, "offset": Vector3(0, 0, 0)},
			{"type": ShapeType.PYRAMID, "offset": Vector3(0, cube_height, 0)}
		], "House", "house")
		_product_sequence.append(p1)

		# Product 2: House (same pattern) - only if building all houses
		if filter == "":
			var p2 = ProductDef.new([
				{"type": ShapeType.CUBE, "offset": Vector3(0, 0, 0)},
				{"type": ShapeType.PYRAMID, "offset": Vector3(0, cube_height, 0)}
			], "House", "house")
			_product_sequence.append(p2)

	# Product 3: Tall house (2 cubes stacked + pyramid roof)
	if filter == "" or filter == "tower" or filter == "tall_house":
		var p3 = ProductDef.new([
			{"type": ShapeType.CUBE, "offset": Vector3(0, 0, 0)},
			{"type": ShapeType.CUBE, "offset": Vector3(0, cube_height, 0)},
			{"type": ShapeType.PYRAMID, "offset": Vector3(0, cube_height * 2, 0)}
		], "Tower", "tower")
		_product_sequence.append(p3)


func _setup_lab_equipment_sequence() -> void:
	var cube_height = shape_scale * 2
	var cube_width = shape_scale * 2
	var filter = _single_product_filter.to_lower()

	# Product 1: Health Charger (2 cubes stacked - wall mount + body)
	if filter == "" or filter == "health_charger" or filter == "charger":
		var p1 = ProductDef.new([
			{"type": ShapeType.CUBE, "offset": Vector3(0, 0, 0)},
			{"type": ShapeType.CUBE, "offset": Vector3(0, cube_height, 0)}
		], "Health Station", "health_charger")
		_product_sequence.append(p1)

	# Product 2: Security Camera (cube mount + pyramid camera)
	if filter == "" or filter == "security_camera" or filter == "camera":
		var p2 = ProductDef.new([
			{"type": ShapeType.CUBE, "offset": Vector3(0, 0, 0)},
			{"type": ShapeType.PYRAMID, "offset": Vector3(0, cube_height * 0.5, cube_width * 0.5)}
		], "Camera", "security_camera")
		_product_sequence.append(p2)

	# Product 3: Specimen Container (cube base + cube jar + pyramid lid)
	if filter == "" or filter == "specimen_jar" or filter == "jar":
		var p3 = ProductDef.new([
			{"type": ShapeType.CUBE, "offset": Vector3(0, 0, 0)},
			{"type": ShapeType.CUBE, "offset": Vector3(0, cube_height, 0)},
			{"type": ShapeType.PYRAMID, "offset": Vector3(0, cube_height * 2, 0)}
		], "Specimen Jar", "specimen_jar")
		_product_sequence.append(p3)


func _setup_scientific_equipment_sequence() -> void:
	var cube_height = shape_scale * 2
	var filter = _single_product_filter.to_lower()

	# Product 1: Microscope (base cube + stand cube + eyepiece pyramid)
	# Abstracted: cube base + tall cube body + angled pyramid eyepiece
	if filter == "" or filter == "microscope":
		var p1 = ProductDef.new([
			{"type": ShapeType.CUBE, "offset": Vector3(0, 0, 0)},
			{"type": ShapeType.CUBE, "offset": Vector3(0, cube_height, 0)},
			{"type": ShapeType.PYRAMID, "offset": Vector3(cube_height * 0.5, cube_height * 1.5, 0)}
		], "Microscope", "microscope")
		_product_sequence.append(p1)

	# Product 2: Electronic Scales (box base + disc weighing platform)
	# Matches actual electronic scales: box body + circular weighing surface
	if filter == "" or filter == "scales" or filter == "electronicscales" or filter == "scale":
		var p2 = ProductDef.new([
			# Base: wide box (main body with display)
			{"type": ShapeType.CUBE, "offset": Vector3(0, 0, 0), "scale": Vector3(1.5, 0.7, 1.2)},
			# Platform: circular disc on top (weighing surface)
			{"type": ShapeType.DISC, "offset": Vector3(0, cube_height * 0.5, 0), "scale": Vector3(1.2, 1.0, 1.2)}
		], "Scales", "electronicscales")
		_product_sequence.append(p2)

	# Product 3: Multimeter (base cube + display pyramid + probe cube)
	if filter == "" or filter == "multimeter":
		var p3 = ProductDef.new([
			{"type": ShapeType.CUBE, "offset": Vector3(0, 0, 0)},
			{"type": ShapeType.PYRAMID, "offset": Vector3(0, cube_height * 0.8, 0)},
			{"type": ShapeType.CUBE, "offset": Vector3(cube_height, cube_height * 0.3, 0)}
		], "Multimeter", "multimeter")
		_product_sequence.append(p3)


func _get_current_product() -> ProductDef:
	if _current_product_index < _product_sequence.size():
		return _product_sequence[_current_product_index]
	return null

func _create_input_conveyor() -> void:
	var conveyor = MeshInstance3D.new()
	conveyor.name = "InputConveyor"

	var length = abs(input_start.x - input_end.x) + 0.3
	var box = BoxMesh.new()
	box.size = Vector3(length, 0.02, 0.25)
	conveyor.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = conveyor_color
	mat.roughness = 0.8
	conveyor.material_override = mat

	var center_x = (input_start.x + input_end.x) / 2.0
	conveyor.position = Vector3(center_x, input_start.y - 0.05, input_start.z)
	add_child(conveyor)

	_create_rail(Vector3(center_x, input_start.y - 0.01, input_start.z - 0.14), length, true)
	_create_rail(Vector3(center_x, input_start.y - 0.01, input_start.z + 0.14), length, true)
	_create_arrow(Vector3(input_start.x - 0.3, input_start.y + 0.02, input_start.z), -90)

func _create_output_conveyor() -> void:
	var conveyor = MeshInstance3D.new()
	conveyor.name = "OutputConveyor"

	var length = abs(output_start.z - output_end.z) + 0.2
	var box = BoxMesh.new()
	box.size = Vector3(0.3, 0.02, length)
	conveyor.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = conveyor_color.darkened(0.1)
	mat.roughness = 0.8
	conveyor.material_override = mat

	var center_z = (output_start.z + output_end.z) / 2.0
	conveyor.position = Vector3(output_start.x, output_start.y - 0.05, center_z)
	add_child(conveyor)

	_create_rail(Vector3(output_start.x - 0.16, output_start.y - 0.01, center_z), length, false)
	_create_rail(Vector3(output_start.x + 0.16, output_start.y - 0.01, center_z), length, false)
	_create_arrow(Vector3(output_start.x, output_start.y + 0.02, output_start.z - 0.15), 180)

func _create_rail(pos: Vector3, length: float, horizontal: bool) -> void:
	var rail = MeshInstance3D.new()
	var box = BoxMesh.new()
	if horizontal:
		box.size = Vector3(length, 0.06, 0.02)
	else:
		box.size = Vector3(0.02, 0.06, length)
	rail.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = conveyor_color.darkened(0.2)
	rail.material_override = mat
	rail.position = pos
	add_child(rail)

func _create_arrow(pos: Vector3, rotation_y: float) -> void:
	var arrow = MeshInstance3D.new()
	var prism = PrismMesh.new()
	prism.size = Vector3(0.08, 0.01, 0.12)
	arrow.mesh = prism
	arrow.rotation_degrees = Vector3(-90, rotation_y, 0)
	arrow.position = pos

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.7, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.7, 0.3)
	mat.emission_energy_multiplier = 0.5
	arrow.material_override = mat
	add_child(arrow)

func _create_production_station() -> void:
	# Ghost container will hold all slot ghosts
	_ghost_container = Node3D.new()
	_ghost_container.name = "GhostContainer"
	_ghost_container.position = station_position
	add_child(_ghost_container)

	# Base platform for production station
	var platform = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.35, 0.02, 0.25)
	platform.mesh = box
	platform.position = Vector3(station_position.x, station_position.y - 0.06, station_position.z)

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.85, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 0.6)
	mat.emission_energy_multiplier = 0.3
	platform.material_override = mat
	add_child(platform)

	# Product counter label
	var label = Label3D.new()
	label.name = "ProductLabel"
	label.text = "Built: 0"
	label.font_size = 24
	label.position = Vector3(station_position.x, station_position.y + 0.22, station_position.z)
	label.modulate = Color(1, 1, 1, 0.9)
	add_child(label)

func _setup_current_product_ghost() -> void:
	# Clear old ghosts
	for mesh in _ghost_meshes:
		if is_instance_valid(mesh):
			mesh.queue_free()
	_ghost_meshes.clear()
	_slot_filled.clear()
	_slot_pieces.clear()

	var product = _get_current_product()
	if not product:
		return

	# Create ghost mesh for each slot
	for i in product.slots.size():
		var slot = product.slots[i]
		var custom_scale = slot.get("scale", Vector3.ONE)
		var ghost = _create_ghost_mesh(slot.type, custom_scale)
		ghost.position = slot.offset
		_ghost_container.add_child(ghost)
		_ghost_meshes.append(ghost)
		_slot_filled.append(false)
		_slot_pieces.append(null)

	# Update label with product name and count
	var label = get_node_or_null("ProductLabel")
	if label:
		var product_name = product.name if product else "Product"
		label.text = "%s | Built: %d" % [product_name, _products_completed]

func _create_ghost_mesh(shape_type: ShapeType, custom_scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var base_size = shape_scale * 2

	match shape_type:
		ShapeType.CUBE:
			var box = BoxMesh.new()
			box.size = Vector3(base_size * custom_scale.x, base_size * custom_scale.y, base_size * custom_scale.z)
			mesh_instance.mesh = box
		ShapeType.PYRAMID:
			mesh_instance.mesh = _build_pyramid_mesh(base_size * custom_scale.x)
		ShapeType.CYLINDER:
			var cyl = CylinderMesh.new()
			cyl.top_radius = base_size * 0.5 * custom_scale.x
			cyl.bottom_radius = base_size * 0.5 * custom_scale.x
			cyl.height = base_size * custom_scale.y
			mesh_instance.mesh = cyl
		ShapeType.DISC:
			var disc = CylinderMesh.new()
			disc.top_radius = base_size * 0.6 * custom_scale.x
			disc.bottom_radius = base_size * 0.6 * custom_scale.x
			disc.height = base_size * 0.15 * custom_scale.y  # Thin disc
			mesh_instance.mesh = disc

	var mat = StandardMaterial3D.new()
	mat.albedo_color = ghost_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = ghost_color
	mat.emission_energy_multiplier = 0.6
	mesh_instance.material_override = mat

	return mesh_instance

func _build_pyramid_mesh(size: float) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half = size * 0.5
	var h = size * 0.8

	var v0 = Vector3(-half, 0, -half)
	var v1 = Vector3(half, 0, -half)
	var v2 = Vector3(half, 0, half)
	var v3 = Vector3(-half, 0, half)
	var apex = Vector3(0, h, 0)

	st.add_vertex(v0); st.add_vertex(v2); st.add_vertex(v1)
	st.add_vertex(v0); st.add_vertex(v3); st.add_vertex(v2)
	st.add_vertex(v0); st.add_vertex(v1); st.add_vertex(apex)
	st.add_vertex(v1); st.add_vertex(v2); st.add_vertex(apex)
	st.add_vertex(v2); st.add_vertex(v3); st.add_vertex(apex)
	st.add_vertex(v3); st.add_vertex(v0); st.add_vertex(apex)

	st.generate_normals()
	return st.commit()

func _spawn_shape_for_current_product() -> void:
	var product = _get_current_product()
	if not product:
		return

	# Find which shapes are still needed
	var needed_shapes: Array[ShapeType] = []
	for i in product.slots.size():
		if not _slot_filled[i]:
			needed_shapes.append(product.slots[i].type)

	if needed_shapes.is_empty():
		return

	# Spawn a needed shape (with some randomness)
	var shape_type: ShapeType
	if randf() < 0.7 and not needed_shapes.is_empty():
		# 70% chance to spawn a needed shape
		shape_type = needed_shapes[randi() % needed_shapes.size()]
	else:
		# 30% chance to spawn random from basic shapes
		shape_type = ShapeType.CUBE if randf() > 0.5 else ShapeType.PYRAMID

	var piece: Node3D
	match shape_type:
		ShapeType.CUBE:
			piece = CUBE_SCENE.instantiate()
			piece.set_meta("shape_type", "cube")
		ShapeType.PYRAMID:
			piece = PYRAMID_SCENE.instantiate()
			piece.set_meta("shape_type", "pyramid")
		ShapeType.CYLINDER:
			piece = CYLINDER_SCENE.instantiate()
			piece.set_meta("shape_type", "cylinder")
		ShapeType.DISC:
			piece = DISC_SCENE.instantiate()
			piece.set_meta("shape_type", "disc")

	piece.position = input_start + Vector3(0, 0.08, randf_range(-0.04, 0.04))
	piece.scale = Vector3.ONE * shape_scale

	if "freeze" in piece:
		piece.freeze = false

	add_child(piece)
	_input_pieces.append(piece)

func _update_input_conveyor(delta: float) -> void:
	var to_remove: Array[Node3D] = []

	for piece in _input_pieces:
		if not is_instance_valid(piece):
			to_remove.append(piece)
			continue

		var is_held = false
		if piece.has_method("is_picked_up"):
			is_held = piece.is_picked_up()

		if not is_held:
			piece.position.x -= input_speed * delta

			if piece.position.x < input_end.x:
				to_remove.append(piece)
				piece.queue_free()

	for piece in to_remove:
		_input_pieces.erase(piece)

func _update_output_conveyor(delta: float) -> void:
	var to_remove: Array[Node3D] = []

	for product in _output_products:
		if not is_instance_valid(product):
			to_remove.append(product)
			continue

		product.position.z -= output_speed * delta

		if product.position.z < output_end.z:
			to_remove.append(product)
			# Fade out and remove
			var tween = create_tween()
			tween.tween_property(product, "scale", Vector3.ONE * 0.01, 0.3)
			tween.tween_callback(product.queue_free)

	for product in to_remove:
		_output_products.erase(product)

func _check_slot_matches() -> void:
	var product = _get_current_product()
	if not product:
		return

	for piece in _input_pieces.duplicate():
		if not is_instance_valid(piece):
			continue

		var is_held = false
		if piece.has_method("is_picked_up"):
			is_held = piece.is_picked_up()

		if is_held:
			continue

		var piece_type_str = piece.get_meta("shape_type", "unknown")
		var piece_type: ShapeType
		match piece_type_str:
			"cube":
				piece_type = ShapeType.CUBE
			"pyramid":
				piece_type = ShapeType.PYRAMID
			"cylinder":
				piece_type = ShapeType.CYLINDER
			"disc":
				piece_type = ShapeType.DISC
			_:
				piece_type = ShapeType.CUBE

		# Check each unfilled slot
		for i in product.slots.size():
			if _slot_filled[i]:
				continue

			var slot = product.slots[i]
			if slot.type != piece_type:
				continue

			# Calculate world position of slot
			var slot_world_pos = _ghost_container.global_position + slot.offset
			var distance = piece.global_position.distance_to(slot_world_pos)

			if distance < slot_match_distance:
				_snap_piece_to_slot(piece, i)
				break

func _snap_piece_to_slot(piece: Node3D, slot_index: int) -> void:
	var product = _get_current_product()
	if not product or slot_index >= product.slots.size():
		return

	var slot = product.slots[slot_index]

	# Remove from input pieces
	_input_pieces.erase(piece)

	# Mark slot as filled
	_slot_filled[slot_index] = true
	_slot_pieces[slot_index] = piece

	# Disable physics and grabbing
	if piece is RigidBody3D:
		piece.freeze = true

	# Snap to slot position with tween
	var target_pos = _ghost_container.global_position + slot.offset
	var tween = create_tween()
	tween.tween_property(piece, "global_position", target_pos, snap_duration)
	tween.tween_property(piece, "rotation", Vector3.ZERO, snap_duration)

	# Hide ghost for this slot
	if slot_index < _ghost_meshes.size() and is_instance_valid(_ghost_meshes[slot_index]):
		_ghost_meshes[slot_index].visible = false

	shape_placed.emit(piece.get_meta("shape_type", "unknown"), slot_index)

	# Check if all slots filled
	await tween.finished
	_check_product_complete()

func _check_product_complete() -> void:
	for filled in _slot_filled:
		if not filled:
			return

	# All slots filled - product complete!
	_products_completed += 1
	product_completed.emit(_products_completed)
	print("AssemblyLine: Product %d complete!" % _products_completed)

	# Move completed product to output
	await _move_product_to_output()

	# Cycle to next product type (or loop back to first)
	_current_product_index = (_current_product_index + 1) % _product_sequence.size()

	# Reset ghost for next product - endless factory!
	_setup_current_product_ghost()

func _move_product_to_output() -> void:
	# Create a container for the completed product
	var product_container = Node3D.new()
	product_container.name = "CompletedProduct_%d" % _products_completed
	product_container.position = output_start
	add_child(product_container)

	# Reparent all slot pieces to the container
	for piece in _slot_pieces:
		if is_instance_valid(piece):
			var world_pos = piece.global_position
			piece.get_parent().remove_child(piece)
			product_container.add_child(piece)
			piece.global_position = world_pos

	# Animate moving to output start
	var tween = create_tween()
	tween.tween_property(product_container, "position", output_start, 0.4)
	await tween.finished

	_output_products.append(product_container)

	# Clear slot tracking
	_slot_pieces.clear()

func _show_completion_message() -> void:
	var label = get_node_or_null("ProductLabel")
	if label:
		label.text = "ALL COMPLETE!"
		label.modulate = Color(0.2, 1.0, 0.3)

	# Play completion sound
	if has_node("/root/SoundBank"):
		var sound_bank = get_node("/root/SoundBank")
		var sound = sound_bank.get_sound("AudioSynthesizer.POWER_UP_JINGLE")
		if sound:
			var player = AudioStreamPlayer3D.new()
			player.stream = sound
			player.volume_db = -3.0
			add_child(player)
			player.global_position = global_position
			player.play()

			# Clean up after sound finishes playing
			player.finished.connect(func():
				if is_instance_valid(player):
					player.queue_free()
			)

	# Spawn a grabbable reward based on puzzle type
	await get_tree().create_timer(0.5).timeout
	_spawn_reward()


func _spawn_reward() -> void:
	var pickable_scene = load("res://addons/godot-xr-tools/objects/pickable.tscn")
	if not pickable_scene:
		return

	var reward = pickable_scene.instantiate()
	reward.name = "Reward"

	# Get the reward type from the last completed product
	var last_product_idx = _current_product_index - 1
	if last_product_idx < 0:
		last_product_idx = _product_sequence.size() - 1
	var equipment_type = "unknown"
	if last_product_idx >= 0 and last_product_idx < _product_sequence.size():
		equipment_type = _product_sequence[last_product_idx].reward_type

	# Create collision shape
	var collision = reward.get_node_or_null("CollisionShape3D")
	if collision:
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(0.08, 0.12, 0.08)
		collision.shape = box_shape

	# Create mesh based on puzzle type
	var reward_mesh: Node3D
	match puzzle_type:
		PuzzleType.HOUSES:
			reward_mesh = _create_house_mesh()
		PuzzleType.LAB_EQUIPMENT:
			reward_mesh = _create_lab_equipment_mesh()
		PuzzleType.SCIENTIFIC_EQUIPMENT:
			reward_mesh = _create_scientific_equipment_reward(equipment_type)

	if reward_mesh:
		reward.add_child(reward_mesh)

	reward.position = station_position + Vector3(0, 0.15, 0)

	var highlight_scene = load("res://addons/godot-xr-tools/objects/highlight/highlight_ring.tscn")
	if highlight_scene:
		var highlight = highlight_scene.instantiate()
		reward.add_child(highlight)

	add_child(reward)

	# Register equipment in the global registry for compositional assembly
	var eq_id = "eq_%s_%d" % [equipment_type, Time.get_ticks_msec()]
	if EquipmentRegistry:
		EquipmentRegistry.register(eq_id, reward, equipment_type, {
			"source": "assembly_line",
			"puzzle_type": PuzzleType.keys()[puzzle_type],
			"product_index": _products_completed
		})
	else:
		# Fallback: just tag the node directly
		reward.set_meta("equipment_id", eq_id)
		reward.set_meta("equipment_type", equipment_type)

	reward.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(reward, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _create_house_mesh() -> Node3D:
	var container = Node3D.new()
	container.name = "HouseMesh"

	var cube_size = 0.06

	# Cube body
	var body = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(cube_size, cube_size, cube_size)
	body.mesh = box
	body.position = Vector3(0, cube_size / 2, 0)

	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.9, 0.85, 0.7)
	body_mat.roughness = 0.7
	body.material_override = body_mat
	container.add_child(body)

	# Pyramid roof
	var roof = MeshInstance3D.new()
	roof.mesh = _build_pyramid_mesh(0.07)
	roof.position = Vector3(0, cube_size, 0)

	var roof_mat = StandardMaterial3D.new()
	roof_mat.albedo_color = Color(0.8, 0.3, 0.2)
	roof_mat.roughness = 0.6
	roof.material_override = roof_mat
	container.add_child(roof)

	return container


func _create_lab_equipment_mesh() -> Node3D:
	var container = Node3D.new()
	container.name = "LabEquipmentMesh"

	# Health Charger style - Half-Life inspired
	var base_size = 0.05
	var body_size = 0.06

	# Wall mount (back plate)
	var mount = MeshInstance3D.new()
	var mount_box = BoxMesh.new()
	mount_box.size = Vector3(body_size * 1.2, body_size * 1.5, base_size * 0.3)
	mount.mesh = mount_box
	mount.position = Vector3(0, body_size * 0.75, -base_size * 0.2)

	var mount_mat = StandardMaterial3D.new()
	mount_mat.albedo_color = Color(0.3, 0.35, 0.4)  # Dark metal
	mount_mat.metallic = 0.6
	mount_mat.roughness = 0.4
	mount.material_override = mount_mat
	container.add_child(mount)

	# Main body (charger unit)
	var body = MeshInstance3D.new()
	var body_box = BoxMesh.new()
	body_box.size = Vector3(body_size, body_size * 1.2, body_size * 0.8)
	body.mesh = body_box
	body.position = Vector3(0, body_size * 0.6, 0)

	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.6, 0.65, 0.7)  # Light metal
	body_mat.metallic = 0.4
	body_mat.roughness = 0.5
	body.material_override = body_mat
	container.add_child(body)

	# Screen/indicator (glowing)
	var screen = MeshInstance3D.new()
	var screen_box = BoxMesh.new()
	screen_box.size = Vector3(body_size * 0.6, body_size * 0.4, body_size * 0.1)
	screen.mesh = screen_box
	screen.position = Vector3(0, body_size * 0.7, body_size * 0.4)

	var screen_mat = StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.2, 0.8, 0.3)  # Green glow
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.2, 0.9, 0.3)
	screen_mat.emission_energy_multiplier = 2.0
	screen.material_override = screen_mat
	container.add_child(screen)

	# Cross symbol (health indicator)
	var cross_h = MeshInstance3D.new()
	var cross_box = BoxMesh.new()
	cross_box.size = Vector3(body_size * 0.4, body_size * 0.1, body_size * 0.05)
	cross_h.mesh = cross_box
	cross_h.position = Vector3(0, body_size * 1.1, body_size * 0.45)

	var cross_mat = StandardMaterial3D.new()
	cross_mat.albedo_color = Color(0.9, 0.2, 0.2)  # Red cross
	cross_mat.emission_enabled = true
	cross_mat.emission = Color(0.9, 0.1, 0.1)
	cross_mat.emission_energy_multiplier = 1.0
	cross_h.material_override = cross_mat
	container.add_child(cross_h)

	var cross_v = MeshInstance3D.new()
	var cross_v_box = BoxMesh.new()
	cross_v_box.size = Vector3(body_size * 0.1, body_size * 0.4, body_size * 0.05)
	cross_v.mesh = cross_v_box
	cross_v.position = Vector3(0, body_size * 1.1, body_size * 0.45)
	cross_v.material_override = cross_mat
	container.add_child(cross_v)

	return container


func _create_scientific_equipment_reward(reward_type: String = "microscope") -> Node3D:
	# Load actual lab equipment scene as reward
	# Map reward types to actual scene paths
	var scene_paths := {
		"microscope": "res://commons/lab/microscope/microscope.tscn",
		"electronicscales": "res://commons/lab/electronicscales/electronicscales.tscn",
		"multimeter": "res://commons/lab/multimeter/multimeter.tscn"
	}

	var scene_path = scene_paths.get(reward_type, scene_paths["microscope"])
	var equipment_scene = load(scene_path)

	if equipment_scene:
		var equipment = equipment_scene.instantiate()
		# Keep normal size for scientific equipment
		equipment.scale = Vector3.ONE
		return equipment
	else:
		push_warning("AssemblyLine: Could not load scene: %s" % scene_path)
		# Fallback to procedural mesh
		return _create_fallback_equipment_mesh()


func _create_fallback_equipment_mesh() -> Node3D:
	# Simple fallback if scene loading fails
	var container = Node3D.new()
	container.name = "FallbackEquipment"

	var body = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.06, 0.08, 0.06)
	body.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.75, 0.8)
	mat.metallic = 0.5
	body.material_override = mat
	container.add_child(body)

	return container


func get_products_completed() -> int:
	return _products_completed

func reset() -> void:
	_current_product_index = 0
	_products_completed = 0

	for piece in _input_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	_input_pieces.clear()

	for product in _output_products:
		if is_instance_valid(product):
			product.queue_free()
	_output_products.clear()

	_setup_current_product_ghost()

	var label = get_node_or_null("ProductLabel")
	if label:
		var product = _get_current_product()
		var product_name = product.name if product else "Product"
		label.text = "%s | Built: %d" % [product_name, _products_completed]
		label.modulate = Color(1, 1, 1, 0.9)


## Apply configuration from grid system / artifact registry
## Accepts explicit names: "houses", "lab", "scientific" or numbers
## Also accepts specific products: "scales", "microscope", "multimeter"
## Shorthand: #scales, #microscope, #multimeter
func apply_grid_config(config_data: Dictionary) -> void:
	print("AssemblyLinePuzzle: Applying config: %s" % config_data)

	var needs_rebuild := false

	if config_data.has("puzzle_type"):
		var parsed = _parse_puzzle_type(config_data["puzzle_type"])
		if parsed["type"] != puzzle_type or parsed["filter"] != _single_product_filter:
			puzzle_type = parsed["type"]
			_single_product_filter = parsed["filter"]
			needs_rebuild = true

	# Check for explicit product filter
	if config_data.has("product"):
		var product = str(config_data["product"]).to_lower().strip_edges()
		if product != _single_product_filter:
			_single_product_filter = product
			# Auto-set puzzle type based on product
			if product in ["microscope", "scales", "electronicscales", "scale", "multimeter"]:
				puzzle_type = PuzzleType.SCIENTIFIC_EQUIPMENT
			elif product in ["health_charger", "security_camera", "specimen_jar"]:
				puzzle_type = PuzzleType.LAB_EQUIPMENT
			needs_rebuild = true

	# Shorthand configs: just the key name without value
	# e.g., #scales, #microscope
	# Grid system may set value to true (boolean), "" (string), or null
	for key in config_data.keys():
		var val = config_data[key]
		var is_shorthand = val == null or (val is bool and val == true) or (val is String and val == "")
		if is_shorthand:
			var parsed = _parse_puzzle_type(key)
			if parsed["type"] != puzzle_type or parsed["filter"] != _single_product_filter:
				puzzle_type = parsed["type"]
				_single_product_filter = parsed["filter"]
				needs_rebuild = true
				break

	if needs_rebuild:
		_rebuild_for_new_type()


## Parse puzzle type from string name or number
## Returns {type: PuzzleType, filter: String}
func _parse_puzzle_type(value) -> Dictionary:
	var result = {"type": puzzle_type, "filter": ""}

	# Handle boolean values (shorthand without explicit value)
	if value is bool:
		return result

	if value is int:
		result["type"] = value as PuzzleType
		return result

	var type_str = str(value).to_lower().strip_edges()

	match type_str:
		# Category types (builds all products in category)
		"houses", "house", "0":
			result["type"] = PuzzleType.HOUSES
		"lab", "lab_equipment", "1":
			result["type"] = PuzzleType.LAB_EQUIPMENT
		"scientific", "scientific_equipment", "science", "2":
			result["type"] = PuzzleType.SCIENTIFIC_EQUIPMENT

		# Individual scientific equipment products
		"microscope":
			result["type"] = PuzzleType.SCIENTIFIC_EQUIPMENT
			result["filter"] = "microscope"
		"scales", "scale", "electronicscales":
			result["type"] = PuzzleType.SCIENTIFIC_EQUIPMENT
			result["filter"] = "scales"
		"multimeter":
			result["type"] = PuzzleType.SCIENTIFIC_EQUIPMENT
			result["filter"] = "multimeter"

		# Individual lab equipment products
		"health_charger", "charger":
			result["type"] = PuzzleType.LAB_EQUIPMENT
			result["filter"] = "health_charger"
		"security_camera", "camera":
			result["type"] = PuzzleType.LAB_EQUIPMENT
			result["filter"] = "security_camera"
		"specimen_jar", "jar":
			result["type"] = PuzzleType.LAB_EQUIPMENT
			result["filter"] = "specimen_jar"

		# Individual house products
		"tower", "tall_house":
			result["type"] = PuzzleType.HOUSES
			result["filter"] = "tower"

		_:
			# Try parsing as int
			if type_str.is_valid_int():
				result["type"] = int(type_str) as PuzzleType
			else:
				push_warning("AssemblyLinePuzzle: Unknown puzzle_type '%s'" % value)

	return result


## Rebuild puzzle for a new type
func _rebuild_for_new_type() -> void:
	# Clear existing pieces
	for piece in _input_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	_input_pieces.clear()

	for product in _output_products:
		if is_instance_valid(product):
			product.queue_free()
	_output_products.clear()

	# Clear product sequence and rebuild
	_product_sequence.clear()
	_current_product_index = 0
	_products_completed = 0

	# Clear ghost container
	if _ghost_container:
		for child in _ghost_container.get_children():
			child.queue_free()

	# Setup new sequence
	_setup_product_sequence()
	_setup_current_product_ghost()

	var label = get_node_or_null("ProductLabel")
	if label:
		var product = _get_current_product()
		var product_name = product.name if product else "Product"
		label.text = "%s | Built: %d" % [product_name, _products_completed]
		label.modulate = Color(1, 1, 1, 0.9)

	print("AssemblyLinePuzzle: Rebuilt for %s type" % PuzzleType.keys()[puzzle_type])
