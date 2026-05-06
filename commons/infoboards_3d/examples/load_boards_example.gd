# load_boards_example.gd
# Examples of how to load Point, Line, and Triangle InfoBoards
extends Node3D

## EXAMPLE 1: Load using updated scene files (EASIEST)
## After updating LineInfoBoard.tscn to use UniversalInfoBoard.gd
func example_1_load_using_scene():
	# Load Line InfoBoard
	var line_board = preload("res://commons/infoboards_3d/boards/Line/LineInfoBoard.tscn").instantiate()
	line_board.position = Vector3(-2, 1.5, 0)
	add_child(line_board)

	# Note: The board_id is already set to "line" in the .tscn file!

## EXAMPLE 2: Create board programmatically with helper function
func example_2_helper_function():
	# Create any board by ID
	var line_board = create_info_board("line", Vector3(-2, 1.5, 0))
	var triangle_board = create_info_board("triangle", Vector3(0, 1.5, 0))
	var point_board = create_info_board("point", Vector3(2, 1.5, 0))

func create_info_board(board_id: String, pos: Vector3) -> Node3D:
	var board_3d = preload("res://commons/infoboards_3d/base/HandheldInfoBoard.tscn").instantiate()

	# Set up universal template
	var ui = board_3d.get_node("BoardFrame/TabletFrame/Viewport2Din3D/Viewport/InfoBoardUI")
	ui.set_script(preload("res://commons/infoboards_3d/base/UniversalInfoBoard.gd"))
	ui.board_id = board_id

	board_3d.position = pos
	add_child(board_3d)
	return board_3d

## EXAMPLE 3: Switch boards dynamically at runtime
func example_3_runtime_switching():
	# Start with Line board
	var board = create_info_board("line", Vector3(0, 1.5, 0))

	# Wait 3 seconds, then switch to Triangle
	await get_tree().create_timer(3.0).timeout
	var ui = board.get_node("SubViewport/InfoBoardUI")
	ui.switch_to_board("triangle")
	print("Switched to Triangle!")

	# Wait 3 more seconds, switch to Point
	await get_tree().create_timer(3.0).timeout
	ui.switch_to_board("point")
	print("Switched to Point!")

## EXAMPLE 4: Create a gallery of all fundamental boards
func example_4_create_gallery():
	var fundamentals = ["point", "line", "triangle"]
	var x_offset = -3.0

	for board_id in fundamentals:
		var board = create_info_board(board_id, Vector3(x_offset, 1.5, 0))
		x_offset += 3.0

## EXAMPLE 5: Load board by category
func example_5_load_by_category():
	var fundamental_boards = InfoBoardContentLoader.get_boards_by_category("Fundamentals")

	var x_offset = -4.0
	for board_id in fundamental_boards:
		var meta = InfoBoardContentLoader.get_board_meta(board_id)
		print("Loading: %s - %s" % [meta.title, meta.subtitle])

		var board = create_info_board(board_id, Vector3(x_offset, 1.5, 0))
		x_offset += 4.0

## EXAMPLE 6: Interactive board selector UI
var current_board_index = 0
var board_ids = ["point", "line", "triangle"]
var active_board: Node3D

func example_6_board_selector():
	# Create initial board
	active_board = create_info_board(board_ids[0], Vector3(0, 1.5, 0))

	# Switch boards on input
	print("Press N for next board, P for previous board")

func _input(event):
	if not active_board:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_N:  # Next board
			cycle_board(1)
		elif event.keycode == KEY_P:  # Previous board
			cycle_board(-1)

func cycle_board(direction: int):
	current_board_index = (current_board_index + direction) % board_ids.size()
	if current_board_index < 0:
		current_board_index = board_ids.size() - 1

	var ui = active_board.get_node("SubViewport/InfoBoardUI")
	var new_board_id = board_ids[current_board_index]
	ui.switch_to_board(new_board_id)

	var meta = InfoBoardContentLoader.get_board_meta(new_board_id)
	print("Switched to: %s - %s" % [meta.title, meta.subtitle])

## Use one of the examples in _ready()
func _ready():
	# Uncomment the example you want to try:

	#example_1_load_using_scene()
	#example_2_helper_function()
	#example_3_runtime_switching()
	example_4_create_gallery()  # Default: Shows point, line, triangle in a row
	#example_5_load_by_category()
	#example_6_board_selector()
