# GameMenu.gd - VR Game Menu using slanted cube primitives
extends Node3D

@export var menu_radius: float = 3.0
@export var menu_items: Array[String] = ["PLAY", "OPTIONS", "ABOUT", "QUIT"]
@export var base_colors: Array[Color] = [
	Color.LIME_GREEN,     # Play - green
	Color.ORANGE,         # Options - orange  
	Color.PURPLE,         # About - purple
	Color.CRIMSON         # Quit - red
]

var menu_elements: Array[Node3D] = []
var selected_index: int = 0

func _ready():
	create_game_menu()
	setup_menu_navigation()

func create_game_menu():
	# Create menu items using the slanted cube primitive
	for i in range(menu_items.size()):
		var menu_item = create_menu_item(i)
		menu_elements.append(menu_item)
		add_child(menu_item)

func create_menu_item(index: int) -> Node3D:
	# Load the slanted cube scene
	var slanted_cube_scene = preload("res://commons/primitives/slantedcube/slantedcube.tscn")
	var menu_item = slanted_cube_scene.instantiate()
	
	# Set menu text and color
	if menu_item.has_method("set_menu_text"):
		menu_item.set_menu_text(menu_items[index])
	
	if menu_item.has_method("set_base_color"):
		var color = base_colors[index] if index < base_colors.size() else Color.WHITE
		menu_item.set_base_color(color)
	
	# Position in vertical stack
	position_menu_item(menu_item, index, menu_items.size())
	
	# Connect selection signal
	if menu_item.has_signal("menu_item_selected"):
		menu_item.menu_item_selected.connect(_on_menu_item_selected)
	
	return menu_item

func position_menu_item(item: Node3D, index: int, total: int):
	# Stack buttons vertically instead of in a circle
	var spacing = 1.0  # Vertical spacing between buttons
	var y_offset = (total - 1) * spacing * 0.5  # Center the stack
	
	item.position = Vector3(0, y_offset - (index * spacing), 0)
	
	# Face toward player (no rotation needed for stacked layout)
	item.rotation = Vector3.ZERO

func setup_menu_navigation():
	# Add keyboard/gamepad navigation
	set_process_input(true)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP, KEY_W:
				navigate_menu(-1)
			KEY_DOWN, KEY_S:
				navigate_menu(1)
			KEY_ENTER, KEY_SPACE:
				activate_selected_item()
			KEY_ESCAPE:
				close_menu()

func navigate_menu(direction: int):
	# Update selection
	selected_index = (selected_index + direction) % menu_items.size()
	if selected_index < 0:
		selected_index = menu_items.size() - 1
	
	# Visual feedback for selection
	update_menu_selection()

func update_menu_selection():
	for i in range(menu_elements.size()):
		var item = menu_elements[i]
		if i == selected_index:
			# Highlight selected item
			if item.has_method("animate_hover"):
				item.animate_hover(true)
		else:
			# Unhighlight others
			if item.has_method("animate_hover"):
				item.animate_hover(false)

func activate_selected_item():
	if selected_index < menu_elements.size():
		var selected_item = menu_elements[selected_index]
		if selected_item.has_method("activate"):
			selected_item.activate()

func _on_menu_item_selected(item_text: String):
	print("Selected menu item: ", item_text)
	
	# Handle menu actions
	match item_text:
		"PLAY":
			start_game()
		"OPTIONS":
			open_options()
		"ABOUT":
			open_about()
		"QUIT":
			quit_game()

func start_game():
	print("Starting game...")
	# Load main game scene
	get_tree().change_scene_to_file("res://scenes/game/main_game.tscn")

func open_options():
	print("Opening options menu...")
	# Load options scene
	get_tree().change_scene_to_file("res://scenes/menus/options.tscn")

func open_about():
	print("Opening about page...")
	# Load about scene
	get_tree().change_scene_to_file("res://scenes/menus/about.tscn")

func quit_game():
	print("Quitting game...")
	# Confirmation dialog could go here
	get_tree().quit()

func close_menu():
	print("Closing menu...")
	# Could return to previous scene or show pause menu
	queue_free()

# Animation methods for menu appearance
func show_menu_animated():
	# Animate menu items appearing
	for i in range(menu_elements.size()):
		var item = menu_elements[i]
		item.scale = Vector3.ZERO
		
		var tween = create_tween()
		tween.tween_delay(i * 0.1)  # Stagger appearance
		tween.tween_property(item, "scale", Vector3.ONE, 0.3)
		tween.tween_callback(item.get_node("InteractionArea").set_monitoring.bind(true))

func hide_menu_animated():
	# Animate menu items disappearing
	for i in range(menu_elements.size()):
		var item = menu_elements[i]
		var tween = create_tween()
		tween.tween_delay(i * 0.05)
		tween.tween_property(item, "scale", Vector3.ZERO, 0.2)

# VR specific methods
func setup_vr_interactions():
	# Enable VR controller interactions
	for item in menu_elements:
		if item.has_node("InteractionArea"):
			var area = item.get_node("InteractionArea")
			area.set_monitoring(true)

func _on_vr_controller_trigger(controller_id: int, item: Node3D):
	# Handle VR controller trigger on menu item
	if item.has_method("activate"):
		item.activate()

# Menu customization
func set_menu_theme(theme_name: String):
	match theme_name:
		"neon":
			apply_neon_theme()
		"classic":
			apply_classic_theme()
		"minimal":
			apply_minimal_theme()

func apply_neon_theme():
	base_colors = [
		Color.CYAN,
		Color.MAGENTA, 
		Color.YELLOW,
		Color.RED
	]
	update_menu_colors()

func apply_classic_theme():
	base_colors = [
		Color.FOREST_GREEN,
		Color.ROYAL_BLUE,
		Color.DARK_ORANGE,
		Color.DARK_RED
	]
	update_menu_colors()

func apply_minimal_theme():
	base_colors = [
		Color.WHITE,
		Color.LIGHT_GRAY,
		Color.GRAY,
		Color.DIM_GRAY
	]
	update_menu_colors()

func update_menu_colors():
	for i in range(menu_elements.size()):
		if i < base_colors.size():
			var item = menu_elements[i]
			if item.has_method("set_base_color"):
				item.set_base_color(base_colors[i])
