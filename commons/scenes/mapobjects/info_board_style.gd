# ArrayExplanationBoard.gd
# A simplified info board for array explanations that uses LevelsManager
extends Node3D

# References to UI elements
@onready var title_label = $Viewport/InfoBoardUI/MainPanel/Title
@onready var level_id_label = $Viewport/InfoBoardUI/MainPanel/LevelID
@onready var summary_label = $Viewport/InfoBoardUI/MainPanel/Summary

# Set these in the Inspector to specify which array explanation to load
@export var specific_category: String = "arrays"
@export var specific_id: int = 0

func _ready():
	# Load the array explanation from LevelsManager
	_load_specific_level_info()

# Load array explanation data from LevelsManager
func _load_specific_level_info():
	pass
# Update the info board with array explanation data from LevelsManager
func _update_info_board(category, id, data):
	# Format level ID
	level_id_label.text = category + "/" + str(id)
	
	# Update title and summary from the level data
	title_label.text = data.title
	summary_label.text = data.summary
	
	print("ArrayExplanationBoard: Successfully loaded array explanation for " + 
		 category + "/" + str(id))

# Display fallback explanation if LevelsManager data is not available
func _display_fallback_explanation():
	title_label.text = "UNDERSTANDING ARRAYS"
	level_id_label.text = "arrays/fallback"
	summary_label.text = """
Arrays are fundamental data structures that store collections of items in memory.

SINGLE ELEMENT:
- A single element is accessed with one index: array[0]
- Memory is allocated for one value at a specific address

1D ARRAY:
- A row of elements accessed with one index: array[i]
- Memory is allocated in a contiguous block
- Perfect for lists, sequences, or collections

2D ARRAY:
- A grid of elements accessed with two indices: array[row][col]
- Implemented as an "array of arrays"
- Perfect for grids, tables, and matrices
"""
	print("ArrayExplanationBoard: Using fallback explanation content")
