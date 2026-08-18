extends Node3D

# Simple test script to demonstrate the BuildEnv with visual geometry
# Attach this to a Node3D in a test scene

# Untyped on purpose: resolves dynamically regardless of when Godot registers the
# BuildEnv class_name (declared on LearnWorldStacked.gd). env.step()/reset()/bodies work.
@onready var env = $BuildEnv
var test_step := 0
var auto_demo_running := false
var auto_reset_timer := 0.0
var auto_reset_interval := 10.0  # Reset every 10 seconds
var structure_count := 0

func _ready() -> void:
	# Wait for environment to initialize
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame

	print("\n=== BuildEnv Visual Test ===")
	print("Auto-rebuild: Every %.1f seconds" % auto_reset_interval)
	print("Press SPACE to place random pieces")
	print("Press R to reset environment")
	print("Press T to run automated test")
	print("Press D to toggle auto-demo")
	print("\n")

	# Automatically place a few pieces on startup so user sees something immediately
	print("Placing initial pieces for visualization...")
	_place_initial_demo_pieces()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				_place_random_piece()
			KEY_R:
				_reset_env()
			KEY_T:
				_run_automated_test()
			KEY_D:
				_toggle_auto_demo()

func _process(delta: float) -> void:
	# Auto-reset timer - build new structure every 10 seconds
	auto_reset_timer += delta
	if auto_reset_timer >= auto_reset_interval:
		auto_reset_timer = 0.0
		_auto_rebuild_structure()

	if auto_demo_running:
		# Place a piece every second
		if test_step % 60 == 0:  # Assuming 60 FPS
			_place_random_piece()

	test_step += 1

func _place_random_piece() -> void:
	"""Place a random primitive at a random location"""
	var action = {
		"primitive_id": randi() % 8,  # 0-7 primitive types
		"x": randf_range(-3.0, 3.0),
		"z": randf_range(-3.0, 3.0),
		"yaw_bin": randi() % 16
	}

	var result = env.step(action)
	var obs = result["obs"]

	print("Placed piece #%d | Height: %.2f | Pieces: %d | KE: %.2f | Reward: %.2f" % [
		test_step,
		obs["height"],
		obs["n"],
		obs["ke"],
		result["reward"]
	])
	test_step += 1

func _reset_env() -> void:
	"""Reset the environment"""
	env.reset()
	test_step = 0
	print("Environment reset")

func _run_automated_test() -> void:
	"""Run an automated test sequence"""
	print("\n=== Starting Automated Test ===")
	_reset_env()

	# Place a sequence of pieces to test each primitive type
	for i in range(8):
		await get_tree().create_timer(0.5).timeout

		var action = {
			"primitive_id": i,
			"x": (i % 4 - 1.5) * 1.5,
			"z": (i / 4 - 0.5) * 2.0,
			"yaw_bin": i * 2
		}

		var result = env.step(action)
		print("Primitive %d placed - Reward: %.2f" % [i, result["reward"]])

	print("=== Automated Test Complete ===")
	print("Total pieces: %d" % env.bodies.size())
	print("Motifs discovered: %d" % env.motif_library.size())

func _place_initial_demo_pieces() -> void:
	"""Place a variety of pieces on startup for immediate visualization"""
	# Build a simple structure: 3 pillars with beams across top

	# Base cubes
	env.step({"primitive_id": 0, "x": -2.0, "z": 0.0, "yaw_bin": 0})
	env.step({"primitive_id": 0, "x": 0.0, "z": 0.0, "yaw_bin": 0})
	env.step({"primitive_id": 0, "x": 2.0, "z": 0.0, "yaw_bin": 0})

	await get_tree().create_timer(0.3).timeout

	# Pillars on top
	env.step({"primitive_id": 3, "x": -2.0, "z": 0.0, "yaw_bin": 0})
	env.step({"primitive_id": 3, "x": 0.0, "z": 0.0, "yaw_bin": 0})
	env.step({"primitive_id": 3, "x": 2.0, "z": 0.0, "yaw_bin": 0})

	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.3).timeout

	# Beams connecting pillars
	env.step({"primitive_id": 1, "x": -1.0, "z": 0.0, "yaw_bin": 0})
	env.step({"primitive_id": 1, "x": 1.0, "z": 0.0, "yaw_bin": 0})

	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.3).timeout

	# Pyramid on top
	env.step({"primitive_id": 2, "x": 0.0, "z": 0.0, "yaw_bin": 0})

	print("✓ Initial demo structure placed")
	print("✓ You should now see: ground + cubes + pillars + beams + pyramid")
	test_step = 10

func _toggle_auto_demo() -> void:
	"""Toggle automatic piece placement demo"""
	auto_demo_running = not auto_demo_running
	if auto_demo_running:
		print("Auto-demo STARTED - pieces will place automatically")
	else:
		print("Auto-demo STOPPED")

func _auto_rebuild_structure() -> void:
	"""Reset and build a new random structure automatically"""
	structure_count += 1
	print("\n=== AUTO-REBUILD #%d ===" % structure_count)

	env.reset()
	await get_tree().create_timer(0.2).timeout

	# Build random structure type
	var structure_type = structure_count % 4

	match structure_type:
		0:
			_build_tower_structure()
		1:
			_build_bridge_structure()
		2:
			_build_pyramid_structure()
		3:
			_build_random_structure()

	print("Structure complete! Next rebuild in %.1f seconds..." % auto_reset_interval)

func _build_tower_structure() -> void:
	"""Build a tall tower structure"""
	print("Building: TOWER")

	# Base layer - wide foundation
	for x in range(-1, 2):
		for z in range(-1, 2):
			env.step({"primitive_id": 0, "x": float(x) * 0.6, "z": float(z) * 0.6, "yaw_bin": 0})

	await get_tree().create_timer(0.3).timeout

	# Pillars at corners
	for x in [-1, 1]:
		for z in [-1, 1]:
			env.step({"primitive_id": 3, "x": float(x) * 0.6, "z": float(z) * 0.6, "yaw_bin": 0})

	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.3).timeout

	# Platform level
	env.step({"primitive_id": 6, "x": 0.0, "z": 0.0, "yaw_bin": 0})

	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.3).timeout

	# Top pyramid
	env.step({"primitive_id": 2, "x": 0.0, "z": 0.0, "yaw_bin": 0})

func _build_bridge_structure() -> void:
	"""Build a bridge/span structure"""
	print("Building: BRIDGE")

	# Support pillars
	env.step({"primitive_id": 3, "x": -3.0, "z": 0.0, "yaw_bin": 0})
	env.step({"primitive_id": 3, "x": 0.0, "z": 0.0, "yaw_bin": 0})
	env.step({"primitive_id": 3, "x": 3.0, "z": 0.0, "yaw_bin": 0})

	await get_tree().create_timer(0.3).timeout

	# Connecting beams
	env.step({"primitive_id": 1, "x": -1.5, "z": 0.0, "yaw_bin": 0})
	env.step({"primitive_id": 1, "x": 1.5, "z": 0.0, "yaw_bin": 0})

	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.3).timeout

	# Deck plates
	env.step({"primitive_id": 6, "x": -1.5, "z": 0.0, "yaw_bin": 0})
	env.step({"primitive_id": 6, "x": 0.5, "z": 0.0, "yaw_bin": 0})

func _build_pyramid_structure() -> void:
	"""Build a stepped pyramid structure"""
	print("Building: PYRAMID")

	# Base layer - 3x3
	for x in range(-1, 2):
		for z in range(-1, 2):
			env.step({"primitive_id": 0, "x": float(x) * 0.7, "z": float(z) * 0.7, "yaw_bin": 0})

	await get_tree().create_timer(0.3).timeout

	# Second layer - 2x2 (using plates)
	for x in range(-1, 1):
		for z in range(-1, 1):
			env.step({"primitive_id": 6, "x": float(x) * 0.7 + 0.35, "z": float(z) * 0.7 + 0.35, "yaw_bin": 0})

	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().create_timer(0.3).timeout

	# Top pyramid
	env.step({"primitive_id": 2, "x": 0.0, "z": 0.0, "yaw_bin": 0})

func _build_random_structure() -> void:
	"""Build a completely random structure"""
	print("Building: RANDOM")

	# Place 8-12 random pieces
	var piece_count = randi() % 5 + 8

	for i in range(piece_count):
		var primitive_id = randi() % 8
		var x = randf_range(-2.5, 2.5)
		var z = randf_range(-2.5, 2.5)
		var yaw = randi() % 16

		env.step({
			"primitive_id": primitive_id,
			"x": x,
			"z": z,
			"yaw_bin": yaw
		})

		if i % 3 == 0:
			await get_tree().create_timer(0.2).timeout

func apply_grid_config(config: Dictionary) -> void:
	pass
