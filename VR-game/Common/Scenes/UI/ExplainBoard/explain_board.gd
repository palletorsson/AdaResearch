# explain_board.gd
extends Node3D

# References to UI elements
@onready var level_number_label = $Viewport/ExplainBoardUI/MainPanel/LevelNumber
@onready var level_id_label = $Viewport/ExplainBoardUI/MainPanel/LevelID
@onready var title_label = $Viewport/ExplainBoardUI/MainPanel/Title
@onready var summary_label = $Viewport/ExplainBoardUI/MainPanel/Summary
@onready var xp_label = $Viewport/ExplainBoardUI/MainPanel/XPLabel
@onready var health_label = $Viewport/ExplainBoardUI/MainPanel/HealthLabel

# The specific level info to display on this board
@export var specific_category: String = "arrays"
@export var specific_id: int = 0

# Animation settings
@export var base_display_time: float = 5.0  # Base time in seconds for displaying each text section
@export var chars_per_second: float = 15.0  # Reading speed estimation
@export var min_display_time: float = 4.0  # Minimum display time for very short sections
@export var max_display_time: float = 12.0  # Maximum display time for long sections
@export var fade_duration: float = 0.75  # Fade transition duration

# Animation state
var current_section: int = 0
var is_animating: bool = false
var explained_sections = []
var player_in_range: bool = true  # Default to true for testing
var animation_paused: bool = false

func _ready():
	# Connect to XP signal for updates if GameManager exists
	if get_node_or_null("/root/GameManager") != null:
		GameManager.connect("xp_updated", Callable(self, "_update_xp_display"))
		_update_xp_display(GameManager.get_xp())
		_update_health_display(100)  # Assuming full health at start
	
	# Load the array explanation
	_load_specific_level_info()

# Load explanation data from LevelsManager
func _load_specific_level_info():
	var level_data = LevelsManager.get_level_data(specific_category, specific_id)
	if not level_data.is_empty():
		_extract_explained_sections(level_data)
		_update_basic_info(specific_category, specific_id, level_data)
		start_animation()
	else:
		push_error("ExplainBoard: Failed to load explanation data for " + 
				  specific_category + "/" + str(specific_id))
		_display_fallback_explanation()

# Extract only the explained sections from level data
func _extract_explained_sections(data):
	explained_sections.clear()
	
	# Check if there's an "explained" section
	if data.has("explained") and data.explained is Dictionary:
		var sorted_keys = data.explained.keys()
		sorted_keys.sort()
		
		for key in sorted_keys:
			explained_sections.append(data.explained[key])
	
	print("ExplainBoard: Extracted " + str(explained_sections.size()) + " explained sections")
	
	# If we somehow ended up with no sections, add a fallback
	if explained_sections.size() == 0:
		explained_sections.append("No explanations available for this topic.")

# Update basic info that doesn't change during animation
func _update_basic_info(category, id, data):
	# Format number with leading zero if needed
	var number_text = str(id)
	if id < 10:
		number_text = "0" + number_text
	
	# Update labels
	level_number_label.text = number_text
	level_id_label.text = category + "/" + str(id)
	title_label.text = data.title
	
	print("ExplainBoard: Basic info updated for " + category + "/" + str(id))

# Display fallback explanation if data is not available
func _display_fallback_explanation():
	level_number_label.text = "01"
	level_id_label.text = "arrays/fallback"
	title_label.text = "UNDERSTANDING ARRAYS"
	summary_label.text = """
			update content
		"""
	print("ExplainBoard: Using fallback explanation content")

# Animation control functions
func start_animation():
	if explained_sections.size() > 0:
		current_section = 0
		is_animating = true
		_show_current_section()
	else:
		push_error("ExplainBoard: No explained sections to animate")

func stop_animation():
	is_animating = false

func pause_animation():
	animation_paused = true

func resume_animation():
	animation_paused = false
	# If we were in the middle of displaying a section, continue with the next one
	if is_animating:
		_show_current_section()

# Display the current section with fade effect
func _show_current_section():
	if animation_paused or not is_animating:
		return
		
	if current_section < explained_sections.size():
		var section_text = explained_sections[current_section]
		
		# Fade out current text
		var fade_out = create_tween()
		fade_out.tween_property(summary_label, "modulate", Color(1, 1, 1, 0), fade_duration)
		await fade_out.finished
		
		# Update text
		summary_label.text = section_text
		
		# Fade in new text
		var fade_in = create_tween()
		fade_in.tween_property(summary_label, "modulate", Color(1, 1, 1, 1), fade_duration)
		
		# Calculate display time based on text length
		var display_time = _calculate_display_time(section_text)
		
		# Wait for display time, then show next section
		await get_tree().create_timer(display_time).timeout
		
		# Move to next section or loop back to beginning
		current_section = (current_section + 1) % explained_sections.size()
		
		# Continue animation if still active
		if is_animating:
			_show_current_section()

# Calculate appropriate display time based on text length
func _calculate_display_time(text: String) -> float:
	# Calculate time based on text length (characters)
	var char_count = text.length()
	var estimated_time = char_count / chars_per_second
	
	# Add base time and clamp to min/max
	var display_time = base_display_time + estimated_time
	display_time = clamp(display_time, min_display_time, max_display_time)
	
	return display_time

# Update XP display
func _update_xp_display(new_xp):
	xp_label.text = "XP: " + str(new_xp)

# Update health display
func _update_health_display(health_value):
	health_label.text = "Health: " + str(health_value) + "%"

# Player interaction
func _on_area_entered(body):
	player_in_range = true
	resume_animation()

func _on_area_exited(body):
	player_in_range = false
	pause_animation()
