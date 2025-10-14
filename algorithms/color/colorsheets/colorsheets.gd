extends Control

@onready var main_container = VBoxContainer.new()
@onready var scroll_container = ScrollContainer.new()
@onready var sheets_container = VBoxContainer.new()

@export var color_palette_resource: Resource = preload("res://algorithms/color/color_palettes.tres")

func _ready():
	setup_ui()
	create_all_palette_sheets()

func setup_ui():
	# Main setup
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Scroll container
	scroll_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll_container)
	
	# Main container
	main_container.add_theme_constant_override("separation", 30)
	scroll_container.add_child(main_container)
	
	# Add margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	scroll_container.add_child(margin)
	margin.add_child(main_container)
	
	# Title
	var title = Label.new()
	title.text = "20 Cultural & Emotional Color Palette Sheets"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "4x4 Color Grids from Art, History, Culture & Human Experience"
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.7, 0.7, 0.7)
	main_container.add_child(subtitle)

func create_all_palette_sheets():
	# Create sheets in a grid layout (2 columns)
	var grid_container = GridContainer.new()
	grid_container.columns = 2
	grid_container.add_theme_constant_override("h_separation", 30)
	grid_container.add_theme_constant_override("v_separation", 30)
	main_container.add_child(grid_container)
	
	# Create each palette sheet
	var palette_keys = color_palette_resource.palettes.keys()
	for palette_key in palette_keys:
		var palette_data = color_palette_resource.palettes[palette_key]
		var sheet = create_palette_sheet(palette_data)
		grid_container.add_child(sheet)

func create_palette_sheet(palette_data: Dictionary) -> Control:
	var sheet_container = VBoxContainer.new()
	sheet_container.add_theme_constant_override("separation", 10)
	
	# Title
	var title_label = Label.new()
	title_label.text = palette_data.title
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sheet_container.add_child(title_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = palette_data.description
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.modulate = Color(0.8, 0.8, 0.8)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(300, 0)
	sheet_container.add_child(desc_label)
	
	# 4x4 Color grid
	var color_grid = GridContainer.new()
	color_grid.columns = 4
	color_grid.add_theme_constant_override("h_separation", 2)
	color_grid.add_theme_constant_override("v_separation", 2)
	
	var colors = palette_data.colors
	
	# Create 16 color rectangles (4x4 grid)
	for i in range(16):
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size = Vector2(50, 50)
		
		if i < colors.size():
			color_rect.color = colors[i]
		else:
			# Fill remaining slots with a neutral color
			color_rect.color = Color(0.5, 0.5, 0.5, 0.3)
		
		# Add subtle border
		var border_style = StyleBoxFlat.new()
		border_style.border_width_left = 1
		border_style.border_width_right = 1
		border_style.border_width_top = 1
		border_style.border_width_bottom = 1
		border_style.border_color = Color(0.3, 0.3, 0.3)
		color_rect.add_theme_stylebox_override("panel", border_style)
		
		color_grid.add_child(color_rect)
	
	sheet_container.add_child(color_grid)
	
	# Color count info
	var info_label = Label.new()
	info_label.text = str(colors.size()) + " colors"
	info_label.add_theme_font_size_override("font_size", 8)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.modulate = Color(0.6, 0.6, 0.6)
	sheet_container.add_child(info_label)
	
	return sheet_container
