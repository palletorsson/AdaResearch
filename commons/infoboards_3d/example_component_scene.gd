# example_component_scene.gd
# Example of how to use InfoBoardComponent in your scenes
# This follows the same pattern as using GridUtilitiesComponent
extends Node3D

# Component references
@onready var info_board_component: InfoBoardComponent = $InfoBoardComponent

# Info board layout (similar to grid utility layout)
# "ib:randomwalk" = Random Walk info board
# "ib:randomwalk:0.5" = Random Walk board with 0.5m height offset
var board_layout = [
	[" ", " ", " ", " ", " "],
	[" ", "ib:randomwalk", " ", " ", " "],
	[" ", " ", " ", " ", " "],
	[" ", " ", " ", " ", " "],
	[" ", " ", " ", " ", " "]
]

# Optional: Board definitions for custom properties
var board_definitions = {
	"ib:randomwalk": {
		"properties": {
			"category": "Randomness",
			"auto_advance": false,
			"category_color": Color(0.8, 0.5, 0.9)
		}
	}
}

func _ready():
	setup_info_boards()

func setup_info_boards():
	# Initialize the component
	var settings = {
		"cube_size": 2.0,  # 2 meters between positions
		"gutter": 0.5,     # 0.5m spacing
		"default_height": 1.5  # Boards at 1.5m height
	}

	info_board_component.initialize(self, settings)

	# Connect signals
	info_board_component.board_generation_complete.connect(_on_boards_generated)
	info_board_component.board_interacted.connect(_on_board_interacted)

	# Generate boards from layout
	info_board_component.generate_boards(board_layout, board_definitions)

	# Alternative: Place individual boards at specific positions
	# info_board_component.place_board_at("ib_randomwalk", Vector3(5, 1.5, 0))

func _on_boards_generated(board_count: int):
	print("Example: Generated %d info boards" % board_count)

func _on_board_interacted(board_type: String, position: Vector3, data: Dictionary):
	print("Example: Board '%s' interacted at %s" % [board_type, position])
	print("  Page: %d" % data.get("page_index", 0))

# Example: Dynamically add a board during gameplay
func add_board_dynamically():
	var board_type = "randomwalk"  # Note: just the type, not "ib:randomwalk"
	var position = Vector3(0, 1.5, 5)

	var board = info_board_component.place_board_at(board_type, position)
	if board:
		print("Example: Dynamically added board at %s" % position)
