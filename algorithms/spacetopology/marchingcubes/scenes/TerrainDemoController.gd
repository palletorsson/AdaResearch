# TerrainDemoController.gd
# Controls the walkable terrain demo
# Provides UI and camera controls for testing marching cubes terrain

extends Node3D

# UI elements
var generate_button: Button
var progress_bar: ProgressBar
var stats_text: RichTextLabel
var size_slider: HSlider
var height_slider: HSlider
var noise_slider: HSlider

# Camera system
var camera: Camera3D
var camera_rotation: Vector3 = Vector3.ZERO
var camera_target = Vector3.ZERO
var is_mouse_captured = false

# VR Navigation
var vr_camera: XRCamera3D
var vr_controllers: Array[XRController3D] = []

# Terrain generation
var terrain_generator: TerrainGenerator

# Parameters
var terrain_size: float = 10.0
var terrain_height: float = 5.0
var noise_frequency: float = 0.05

# --- STAGE-2 DNA (promoted 2026-08-12) -----------------------------------------------
#
# strata — WHAT THE FIELD IS MADE OF. calculate_terrain_density() sums three different
# noises into one height: Perlin fBm (the landform), Simplex at 3x frequency (the crust)
# and Cellular RETURN_CELL_VALUE (flat-topped plates). The axis multiplies those three
# weights and nothing else. "all" hands back the shipped literals 1.0 / 0.2 / 0.3; the
# sole-layer rungs carry weight 1.0 so each shows its layer at full strength, which makes
# "all" about 1.5x the amplitude of a sole rung. Stated rather than hidden, and the reason
# swell is crossed with it.
@export_enum("all", "bedrock", "cells", "fine") var strata: String = "all"

# swell — HOW FAR THE FIELD IS ALLOWED TO DEPART FROM FLAT: the amplitude the noise sum is
# multiplied by before it becomes a height.
#
# THE LADDER DOES NOT REACH ZERO, and that is a fact about the artifact rather than a
# design compromise. Chunks are created at y = 0.0 (TerrainGenerator.create_terrain_voxel_
# grid) and sampled upward for 12 x 0.8 = 9.6 m, so the box floor IS the mean plane. The
# density ladder crosses iso 0.5 at surface_factor = 1/6, i.e. 0.167 units BELOW the
# geometric surface — so at amplitude 0 the extracted surface sits at y = -0.167, outside
# the sampled column, every voxel reads 0.45 or less, and marching cubes finds no crossing
# at all. Amplitude 0 renders NOTHING, not a slab. Small amplitudes render LESS, not
# flatter: only the ~45% of the footprint where combined_height clears 0.167 gets any
# geometry, which is also why the shipped default is a partial sheet rather than a ground.
#
# CEILING: 13.0 puts the crests near 6-8 m with the 9.6 m column still around them. Above
# ~15 the terrain leaves the box and the rung photographs as holes rather than as mountains.
@export_enum("rolling", "subdued", "hills", "range") var swell: String = "rolling"

# Law 4. TerrainGenerator.setup_noise_generators reads
#   var actual_seed = seed_value if seed_value >= 0 else randi()
# and the shipped call site passed no argument, so every launch drew a fresh randi() and
# five variants would have been five different terrains. Negative keeps that shipped
# randi() call for call; dna.fixture pins it to 7 for the sweep.
@export var terrain_seed: int = -1

# Law 6. The shipped path is call_deferred("generate_terrain_async") plus three awaited
# process frames inside the generator, so the mesh does not exist until roughly five
# frames after _ready. True runs the identical four steps with the awaits removed.
# Default false leaves the shipped deferred path untouched.
@export var build_synchronously: bool = false

## Signature of every value the build reads. apply_grid_config returns early when it has
## not moved, so a map token that changes nothing cannot trigger a rebuild.
var _cfg_signature: String = ""
## Nodes THIS script put into the tree. A rebuild frees these and only these.
var _owned: Array[Node] = []

func _ready() -> void:
	_read_config_meta()
	setup_ui()
	setup_terrain_generator()
	setup_camera()
	setup_vr_navigation()
	_cfg_signature = _config_signature()

	# Generate initial terrain
	if build_synchronously:
		generate_terrain_sync()
	else:
		call_deferred("generate_terrain_async")

func _read_config_meta() -> void:
	"""Map-token config, read BEFORE the first build.

	GridInteractablesComponent stamps config_<key> metadata at line 1195 and calls
	add_child at 1220, so a token's values are already on this node when _ready runs. The
	call_deferred("apply_grid_config") that follows then finds an unchanged signature and
	returns without rebuilding anything."""
	if has_meta("config_strata"):
		strata = str(get_meta("config_strata"))
	if has_meta("config_swell"):
		swell = str(get_meta("config_swell"))
	if has_meta("config_terrain_seed"):
		terrain_seed = int(get_meta("config_terrain_seed"))
	if has_meta("config_build_synchronously"):
		var v: Variant = get_meta("config_build_synchronously")
		if typeof(v) == TYPE_BOOL:
			build_synchronously = bool(v)
		else:
			build_synchronously = str(v).to_lower() == "true"

func _config_signature() -> String:
	return "%s|%s|%d|%.4f|%.5f" % [strata, swell, terrain_seed, terrain_size, noise_frequency]

func _strata_weights() -> Array:
	"""The three summand weights for the current value of `strata`.

	AN ARRAY AND NOT A Vector3, deliberately. Vector3 components are 32-bit floats, so
	Vector3(1.0, 0.2, 0.3).y widened back to a GDScript double is 0.20000000298023224 —
	NOT the double 0.2 the shipped literal compiles to. Returning an Array keeps every
	element a double, which is what makes `all` a bit-identical short-circuit rather than
	a value that merely lands near the old one."""
	match strata:
		"bedrock":
			return [1.0, 0.0, 0.0]  # pure Perlin fBm: ground with no cells and no crust
		"cells":
			return [0.0, 0.0, 1.0]  # cellular alone: flat-topped plates, vertical steps
		"fine":
			return [0.0, 1.0, 0.0]  # simplex detail alone at 3x frequency: crust, no landform
	# "all" — SHIPPED, the three literals handed back unchanged. Written as the fall-through
	# rather than a `_:` case so the analyzer can see the function always returns.
	return [1.0, 0.2, 0.3]

func _swell_height() -> float:
	match swell:
		"subdued":
			return 2.5
		"hills":
			return 9.0
		"range":
			return 13.0
	# "rolling" — SHIPPED. terrain_height, so the HeightSlider path still works.
	return terrain_height

func setup_ui() -> void:
	"""Initialize UI elements"""
	# Get UI references
	generate_button = $UI/Panel/VBoxContainer/Controls/GenerateButton
	progress_bar = $UI/Panel/VBoxContainer/ProgressBar
	stats_text = $UI/Panel/VBoxContainer/StatsText
	size_slider = $UI/Panel/VBoxContainer/Parameters/SizeSlider
	height_slider = $UI/Panel/VBoxContainer/Parameters/HeightSlider
	noise_slider = $UI/Panel/VBoxContainer/Parameters/NoiseSlider
	
	# Setup initial state
	#progress_bar.visible = false
	
	print("TerrainDemo: UI initialized")

func setup_terrain_generator() -> void:
	"""Initialize terrain generation system"""
	# terrain_seed defaults to -1, which is exactly the branch the no-argument call took.
	terrain_generator = TerrainGenerator.new(terrain_seed)
	terrain_generator.generation_progress.connect(_on_generation_progress)
	terrain_generator.generation_complete.connect(_on_generation_complete)
	
	# Configure initial parameters
	update_terrain_parameters()
	
	print("TerrainDemo: Terrain generator initialized")

func setup_camera() -> void:
	"""Setup camera system"""
	camera = $Camera3D
	vr_camera = find_child("XRCamera3D") as XRCamera3D
	
	# Mouse capture for camera control
	if not vr_camera:
		print("TerrainDemo: Desktop camera controls enabled")

func setup_vr_navigation() -> void:
	"""Setup VR teleportation system"""
	# Find VR components if they exist
	var xr_origin = find_child("XROrigin3D")
	if xr_origin != null:
		for child in xr_origin.get_children():
			if child is XRController3D:
				vr_controllers.append(child as XRController3D)
				setup_controller_teleport(child as XRController3D)
	
	print("TerrainDemo: Found %d VR controllers" % vr_controllers.size())

func setup_controller_teleport(controller: XRController3D) -> void:
	"""Setup teleportation for a VR controller"""
	# Create teleport ray
	var teleport_ray = RayCast3D.new()
	teleport_ray.name = "TeleportRay"
	teleport_ray.target_position = Vector3(0, 0, -10)
	teleport_ray.collision_mask = 4  # VR navigation layer
	teleport_ray.enabled = true
	controller.add_child(teleport_ray)
	
	# Create teleport preview marker
	var teleport_marker = MeshInstance3D.new()
	teleport_marker.name = "TeleportPreview"
	teleport_marker.mesh = create_teleport_preview_mesh()
	teleport_marker.visible = false
	
	# Glowing material for teleport preview
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GREEN
	material.emission_enabled = true
	material.emission = Color.GREEN
	material.emission_energy = 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.8
	teleport_marker.set_surface_override_material(0, material)
	
	get_tree().current_scene.add_child(teleport_marker)
	
	# Connect controller signals
	controller.button_pressed.connect(_on_vr_button_pressed.bind(controller, teleport_ray, teleport_marker))
	controller.button_released.connect(_on_vr_button_released.bind(controller, teleport_ray, teleport_marker))

func create_teleport_preview_mesh() -> ArrayMesh:
	"""Create a circular mesh for teleport preview"""
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	var radius = 0.8
	var segments = 16
	
	# Center vertex
	vertices.append(Vector3.ZERO)
	normals.append(Vector3.UP)
	
	# Circle vertices
	for i in range(segments):
		var angle = i * TAU / segments
		var x = cos(angle) * radius
		var z = sin(angle) * radius
		vertices.append(Vector3(x, 0.01, z))
		normals.append(Vector3.UP)
	
	# Create triangles
	for i in range(segments):
		var next_i = (i + 1) % segments
		indices.append(0)
		indices.append(i + 1)
		indices.append(next_i + 1)
	
	# Create mesh
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _input(event: InputEvent) -> void:
	"""Handle input events"""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_mouse_captured:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				is_mouse_captured = true
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_mouse_captured:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				is_mouse_captured = false
	
	elif event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if is_mouse_captured:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				is_mouse_captured = false

func _process(delta: float) -> void:
	# Update camera if not in VR mode
	if not vr_camera:
		update_camera_movement(delta)
	
	# Update teleport previews
	update_teleport_previews()

func update_camera_movement(delta: float) -> void:
	"""Handle non-VR camera movement"""
	if not camera:
		return
	
	# Mouse look
	if is_mouse_captured:
		var mouse_delta = Input.get_last_mouse_velocity() * delta * 0.001
		camera_rotation.y -= mouse_delta.x
		camera_rotation.x -= mouse_delta.y
		camera_rotation.x = clamp(camera_rotation.x, -PI/2, PI/2)
		# FIXED: Convert Vector2 camera_rotation to Vector3 for Camera3D
		camera.rotation = Vector3(camera_rotation.x, camera_rotation.y, 0.0)
	
	# WASD movement
	var input_vector = Vector3.ZERO
	var speed = 15.0 if Input.is_action_pressed("ui_accept") else 8.0
	
	if Input.is_action_pressed("ui_up"):
		input_vector.z -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.z += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	
	# Vertical movement
	if Input.is_key_pressed(KEY_Q):
		input_vector.y -= 1
	if Input.is_key_pressed(KEY_E):
		input_vector.y += 1
	
	# Apply movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		var movement = camera.transform.basis * input_vector * speed * delta
		camera.position += movement

func update_teleport_previews() -> void:
	"""Update teleport preview positions"""
	for controller in vr_controllers:
		var teleport_ray = controller.find_child("TeleportRay") as RayCast3D
		var teleport_marker = get_tree().current_scene.find_child("TeleportPreview") as MeshInstance3D
		
		if teleport_ray != null and teleport_marker != null and teleport_marker.visible:
			if teleport_ray.is_colliding():
				var collision_point = teleport_ray.get_collision_point()
				var collider = teleport_ray.get_collider()
				
				teleport_marker.global_position = collision_point
				
				var material = teleport_marker.get_surface_override_material(0) as StandardMaterial3D
				if collider != null and collider.has_meta("vr_walkable"):
					material.albedo_color = Color.GREEN
					material.emission = Color.GREEN
				else:
					material.albedo_color = Color.RED
					material.emission = Color.RED

func update_terrain_parameters() -> void:
	"""Update terrain parameters from UI"""
	var weights: Array = _strata_weights()
	var params = {
		"size": Vector2(terrain_size, terrain_size),
		"height": _swell_height(),
		"noise_frequency": noise_frequency,
		"threshold": 0.5,
		"debug_mode": true,  # Enable debug mode to prevent holes
		"min_density": 0.7,  # Guarantee minimum density
		"height_weight": weights[0],
		"detail_weight": weights[1],
		"feature_weight": weights[2]
	}
	terrain_generator.configure_terrain(params)

func _on_generate_pressed() -> void:
	"""Handle generate button press"""
	generate_terrain_async()

func generate_terrain_async() -> void:
	"""Generate terrain asynchronously"""
	print("TerrainDemo: Starting terrain generation...")
	
	# Disable UI during generation
	generate_button.disabled = true
	generate_button.text = "Generating..."
	progress_bar.visible = true
	progress_bar.value = 0
	
	# Clear previous terrain
	clear_previous_terrain()
	
	# Update parameters and generate
	update_terrain_parameters()
	var terrain_meshes = await terrain_generator.generate_terrain_async()

	# Add terrain to scene
	terrain_generator.add_terrain_to_scene(self)
	_record_owned()

func generate_terrain_sync() -> void:
	"""The shipped four steps with no awaits — the mesh exists when this returns.

	Same order as generate_terrain_async, including generation_complete firing before
	add_terrain_to_scene, so _on_generation_complete sees exactly what it always saw."""
	print("TerrainDemo: Starting terrain generation (synchronous)...")

	if generate_button != null:
		generate_button.disabled = true
		generate_button.text = "Generating..."
	if progress_bar != null:
		progress_bar.visible = true
		progress_bar.value = 0

	update_terrain_parameters()
	terrain_generator.generate_terrain_sync()
	terrain_generator.add_terrain_to_scene(self)
	_record_owned()

func _record_owned() -> void:
	for m in terrain_generator.terrain_meshes:
		if m != null and not _owned.has(m):
			_owned.append(m)
	for b in terrain_generator.collision_bodies:
		if b != null and not _owned.has(b):
			_owned.append(b)

func _free_owned() -> void:
	"""Free ONLY what this script put into the tree. remove_child first, so the rebuilt
	chunks do not collide with a still-queued name and get renamed to TerrainChunk_0@2."""
	for n in _owned:
		if is_instance_valid(n):
			var p: Node = n.get_parent()
			if p != null:
				p.remove_child(n)
			n.queue_free()
	_owned.clear()

func _rebuild_terrain() -> void:
	_free_owned()
	# A new generator, because the seed is read once in _init.
	setup_terrain_generator()
	generate_terrain_sync()

func clear_previous_terrain() -> void:
	"""Clear previously generated terrain"""
	# Remove old terrain
	for child in get_children():
		if child.name.begins_with("TerrainChunk_") or child.name.ends_with("_VR_Collision") or child.name.begins_with("NavTile_"):
			child.queue_free()

func _on_generation_progress(percentage: float) -> void:
	"""Update progress bar during generation"""
	progress_bar.value = percentage
	
	var status = ""
	if percentage <= 25:
		status = "ðŸ—ï¸ Creating voxel grid..."
	elif percentage <= 50:
		status = "ðŸŒ„ Generating height field..."
	elif percentage <= 75:
		status = "ðŸŽ¨ Creating terrain meshes..."
	else:
		status = "âš¡ Building collision..."
	
	stats_text.text = "[color=cyan]ðŸ”„ Generating terrain...[/color]\n[color=gray]%s[/color]\n[color=white]Progress: %.0f%%[/color]" % [status, percentage]

func _on_generation_complete() -> void:
	"""Handle generation completion"""
	print("TerrainDemo: Generation complete!")
	
	# Re-enable UI
	generate_button.disabled = false
	generate_button.text = "Generate Terrain"
	progress_bar.visible = false
	
	# Update statistics
	update_terrain_statistics()

func update_terrain_statistics() -> void:
	"""Update the statistics display"""
	if terrain_generator == null:
		return
	
	var info = terrain_generator.get_terrain_info()
	
	var stats_html = "[color=cyan]Terrain Statistics:[/color]\n"
	stats_html += "â€¢ Terrain Size: %.0fx%.0f units\n" % [info.terrain_size.x, info.terrain_size.y]
	stats_html += "â€¢ Height Variation: %.1f units\n" % info.height_variation
	stats_html += "â€¢ Terrain Chunks: %d\n" % info.terrain_chunks
	stats_html += "â€¢ Mesh Instances: %d\n" % info.mesh_instances
	stats_html += "â€¢ Collision Bodies: %d\n" % info.collision_bodies
	stats_html += "â€¢ Total Vertices: %s\n" % format_number(info.total_vertices)
	stats_html += "â€¢ Total Triangles: %s\n" % format_number(info.total_triangles)
	
	# Count VR navigation tiles
	var nav_tile_count = 0
	for child in get_children():
		if child.name.begins_with("NavTile_"):
			nav_tile_count += 1
	
	stats_html += "\n[color=green]VR Navigation:[/color]\n"
	stats_html += "â€¢ Walkable Tiles: %d (1x1m)\n" % nav_tile_count
	stats_html += "â€¢ VR Controllers: %d\n" % vr_controllers.size()
	
	# Memory estimate
	var memory_mb = (info.total_vertices * 12 + info.total_triangles * 6) / (1024 * 1024)
	stats_html += "\nâ€¢ Memory Est: %.1f MB" % memory_mb
	
	stats_text.text = stats_html

func format_number(num: int) -> String:
	"""Format large numbers with commas"""
	var str_num = str(num)
	var formatted = ""
	var count = 0
	
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = str_num[i] + formatted
		count += 1
	
	return formatted

# Slider event handlers
func _on_size_changed(value: float) -> void:
	terrain_size = value
	var size_label = $UI/Panel/VBoxContainer/Parameters/SizeLabel
	size_label.text = "Terrain Size: %.0f units" % value

func _on_height_changed(value: float) -> void:
	terrain_height = value
	var height_label = $UI/Panel/VBoxContainer/Parameters/HeightLabel
	height_label.text = "Height Variation: %.1f" % value

func _on_noise_changed(value: float) -> void:
	noise_frequency = value
	var noise_label = $UI/Panel/VBoxContainer/Parameters/NoiseLabel
	noise_label.text = "Noise Frequency: %.3f" % value

# VR teleportation handlers
func _on_vr_button_pressed(_controller: XRController3D, teleport_ray: RayCast3D, teleport_marker: MeshInstance3D, button: String) -> void:
	if button == "trigger_click" or button == "by_button":
		teleport_marker.visible = true

func _on_vr_button_released(_controller: XRController3D, teleport_ray: RayCast3D, teleport_marker: MeshInstance3D, button: String) -> void:
	if button == "trigger_click" or button == "by_button":
		teleport_marker.visible = false
		
		if teleport_ray.is_colliding():
			var collision_point = teleport_ray.get_collision_point()
			var collider = teleport_ray.get_collider()
			
			if collider != null and collider.has_meta("vr_walkable"):
				perform_vr_teleport(collision_point)

func perform_vr_teleport(target_position: Vector3) -> void:
	"""Teleport VR player to target position"""
	var xr_origin = find_child("XROrigin3D")
	if xr_origin != null:
		var teleport_position = target_position + Vector3(0, 0.1, 0)
		xr_origin.global_position = teleport_position
		print("VR Teleport: Moved to ", teleport_position)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	"""Map-token config. Was a bare `pass`.

	The signature guard is the whole point: GridInteractablesComponent always calls this
	(deferred) after _ready has already built with the same values, so without it every
	configured placement would rebuild its terrain once for nothing. Rebuilds are
	SYNCHRONOUS — no call_deferred in a build path — and free only _owned."""
	if config.has("strata"):
		strata = str(config["strata"])
	if config.has("swell"):
		swell = str(config["swell"])
	if config.has("terrain_seed"):
		terrain_seed = int(config["terrain_seed"])

	if terrain_generator == null:
		# The call can arrive before _ready has run. It does not today — curation_station
		# add_child()s first and only then calls this (curation_station.gd:378-382), and the
		# grid defers the call — but a composer that instantiates and configures without
		# parenting would otherwise rebuild against a null generator. The exports are
		# already set above; _ready builds with them and records the signature.
		return

	var sig: String = _config_signature()
	if sig == _cfg_signature:
		return
	_cfg_signature = sig
	_rebuild_terrain()
