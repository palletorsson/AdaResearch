extends Node3D

# WFC Test Scene Controller
# Press SPACE to generate a new WFC grid

@onready var wfc_grid = $WFCGrid3D
@onready var camera = $Camera3D

var camera_distance = 20.0
var camera_angle = 0.0

func _ready():
	print("=== WFC Test Scene ===")
	print("Press SPACE to generate")
	print("Press R to regenerate")
	print("Press A to toggle animation")
	print("Press arrow keys to rotate camera")
	print("=====================")

	# Position camera
	update_camera()

func _process(delta):
	# Camera rotation
	if Input.is_action_pressed("ui_left"):
		camera_angle -= delta * 2.0
		update_camera()
	if Input.is_action_pressed("ui_right"):
		camera_angle += delta * 2.0
		update_camera()

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				print("\n=== Generating WFC Grid ===")
				wfc_grid.generate()

			KEY_R:
				print("\n=== Regenerating WFC Grid ===")
				wfc_grid.regenerate()

			KEY_A:
				wfc_grid.animate_generation = not wfc_grid.animate_generation
				print("Animation: ", "ON" if wfc_grid.animate_generation else "OFF")

			KEY_UP:
				camera_distance = max(5.0, camera_distance - 2.0)
				update_camera()

			KEY_DOWN:
				camera_distance = min(50.0, camera_distance + 2.0)
				update_camera()

func update_camera():
	var grid_center = Vector3(
		wfc_grid.grid_width * wfc_grid.tile_size / 2.0,
		wfc_grid.grid_height * wfc_grid.tile_size / 2.0,
		wfc_grid.grid_depth * wfc_grid.tile_size / 2.0
	)

	camera.position = grid_center + Vector3(
		cos(camera_angle) * camera_distance,
		camera_distance * 0.7,
		sin(camera_angle) * camera_distance
	)

	camera.look_at(grid_center, Vector3.UP)

func _on_WFCGrid3D_generation_started():
	print("WFC: Generation started")

func _on_WFCGrid3D_generation_complete():
	print("WFC: Generation complete!")

func _on_WFCGrid3D_tile_placed(position, tile_id):
	if wfc_grid.animate_generation:
		print("Placed tile '", tile_id, "' at ", position)
