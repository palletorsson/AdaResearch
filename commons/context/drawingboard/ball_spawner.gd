@tool
extends Node3D

const BALL_SCENE_PATH = "res://commons/primitives/sphere/grab_sphere.tscn"
const BALL_SCRIPT_PATH = "res://commons/context/drawingboard/ball_grab_sphere.gd"
const PAINT_TIP_SCRIPT_PATH = "res://commons/context/drawingboard/ball_paint_tip.gd"

@export var ball_count: int = 20
@export var spawn_area_size: Vector2 = Vector2(1.5, 0.5)
@export var base_height: float = 0.0

@export var min_scale: float = 0.5
@export var max_scale: float = 1.5

func _ready() -> void:
	# Clean up existing balls if running in tool mode to avoid duplicates if re-run
	# But generally we just spawn once on ready in game
	spawn_balls()

func spawn_balls() -> void:
	var ball_scene = load(BALL_SCENE_PATH)
	var ball_script = load(BALL_SCRIPT_PATH)
	var tip_script = load(PAINT_TIP_SCRIPT_PATH)
	
	if not ball_scene or not ball_script or not tip_script:
		push_error("BallSpawner: Failed to load resources")
		return

	# Clear children first if any
	for child in get_children():
		child.queue_free()
		
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	for i in range(ball_count):
		var ball = ball_scene.instantiate()
		ball.name = "Ball_%d" % i
		
		# Set the custom script
		ball.set_script(ball_script)
		
		# Set properties for GrabSphere/GrabCube
		ball.freeze = true
		ball.snap_to_shelf = true
		ball.snap_max_distance = 0.08
		ball.snap_match_rotation = false
		ball.snap_falloff_distance = 1.0
		ball.sync_with_paint_tip = true
		
		# Random position layout
		# Arrange in a rough grid or random cloud
		var x = rng.randf_range(-spawn_area_size.x/2, spawn_area_size.x/2)
		var z = rng.randf_range(-spawn_area_size.y/2, spawn_area_size.y/2)
		ball.transform.origin = Vector3(x, base_height, z)
		
		# Random scale
		var s = rng.randf_range(min_scale, max_scale)
		ball.scale = Vector3(s, s, s)
		
		# Add Paint Tip
		var tip = Node3D.new()
		tip.name = "BallPaintTip"
		tip.set_script(tip_script)
		
		# Random Color (HSV for nice colors)
		var hue = float(i) / float(ball_count) # Spectrum
		var color = Color.from_hsv(hue, 1.0, 1.0)
		tip.set("brush_color", color)
		
		# Randomize brush size (2 to 25)
		var b_size = int(rng.randf_range(2, 25))
		tip.set("brush_size", b_size)
		
		# Randomize snap grid size (powers of 2 usually good: 4, 8, 16, 32, 64)
		var snap_sizes = [4, 8, 16, 32, 64]
		var s_size = snap_sizes[rng.randi() % snap_sizes.size()]
		tip.set("snap_grid_size", s_size)
		
		# Add RayCast for the tip (needed by ball_paint_tip.gd usually)
		var ray = RayCast3D.new()
		ray.name = "RayCast3D"
		ray.target_position = Vector3(0, 0, -3.0) # Longer projection for easier painting
		ray.collide_with_areas = true
		tip.add_child(ray)
		
		ball.add_child(tip)
		
		add_child(ball)
