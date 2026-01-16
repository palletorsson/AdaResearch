# MapManual.gd
# Toggleable map information display that rotates in/out when player presses X button
# Uses MarkdownLabel for rendering markdown text

extends Node3D
class_name MapManual

# Configuration
@export var display_distance: float = 1.8  # Perfect VR reading distance (was 2.0)
@export var height_offset: float = -0.3  # Offset below eye level (negative = down)
@export var hint_distance: float = 1.1 # Distance from camera (closer than manual)
@export var hint_height_offset: float = -0.9 # Vertical offset (relative to camera height)
@export var hint_horizontal_offset: float = 0.0 # Horizontal offset (centered)

# ...



# ... (variables remain the same) ...

func _setup_hint_label() -> void:
	hint_label = Label3D.new()
	hint_label.name = "HintLabel"
	hint_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint_label.no_depth_test = true # Render on top
	hint_label.render_priority = 10
	hint_label.text = ""
	hint_label.font_size = 12 # Very small
	hint_label.outline_render_priority = 9
	hint_label.modulate = Color(1.0, 0.3, 0.3, 0.9) # Red text
	hint_label.visible = false
	hint_label.top_level = true # Decouple from parent rotation/smoothing
	add_child(hint_label)

# ... (rest of file) ...


@export var hidden_distance: float = -0.5  # Behind player
@export var animation_duration: float = 0.4
@export var follow_speed: float = 3.0
@export var tilt_angle: float = -7.5 # Degrees to tilt back (negative for top-away)

# State
var is_visible: bool = false
var is_animating: bool = false
var current_page: int = 0
var pages: Array[String] = []
var map_name_for_hint: String = ""
var has_content: bool = false

# Scrolling
@export var scroll_speed: float = 300.0  # Pixels per second

# VR controller references
var left_controller: XRController3D
var right_controller: XRController3D

# Node references
@onready var viewport_2d = $Viewport2Din3D
var hint_label: Label3D

# Internal referencing (dynmically found)
var scroll_container: ScrollContainer
var markdown_label: RichTextLabel
var title_label: Label
var page_label: Label
var prev_button: Button
var next_button: Button

# Tab menu buttons
var tab_menu: HBoxContainer
var summary_tab: Button
var technical_tab: Button
var critical_tab: Button
var blurb_tab: Button

# Available md files for current map
var available_md_files: Dictionary = {}  # {"summary": "path", "technical": "path", etc.}
var current_md_type: String = ""  # Currently selected tab
var current_map_name: String = ""

func _ready() -> void:
	# Ensure root is visible so we can show hint/manual independently
	visible = true
	
	# Setup UI nodes
	call_deferred("_find_ui_nodes_and_setup")
	_setup_hint_label()
	
	# Initially hide manual content (scale ~0)
	if viewport_2d:
		viewport_2d.scale = Vector3.ONE * 0.001
	
	# Find VR controllers
	_find_vr_controllers()
	
	# Connect to controller button signals
	_connect_controller_signals()
	
	# Connect to SceneManager for auto-close and auto-load
	if AdaSceneManager.instance:
		if not AdaSceneManager.instance.scene_transition_started.is_connected(_on_scene_transition_started):
			AdaSceneManager.instance.scene_transition_started.connect(_on_scene_transition_started)
		if not AdaSceneManager.instance.scene_transition_completed.is_connected(_on_scene_transition_completed):
			AdaSceneManager.instance.scene_transition_completed.connect(_on_scene_transition_completed)
	
	# Load map data when ready
	call_deferred("_load_map_data")

func _find_ui_nodes_and_setup() -> void:
	if not viewport_2d: return
	
	# Wait for content
	if viewport_2d.get_viewport().get_child_count() == 0:
		await get_tree().process_frame
		
	_find_ui_nodes()



func _on_scene_transition_started(_from, _to, _type):
	"""Auto-close manual when teleporting/transitioning"""
	if is_visible:
		hide_manual()
	# Also hide hint during transition
	if hint_label:
		hint_label.visible = false

func _on_scene_transition_completed(_scene, _data):
	"""Reload data when new map is ready"""
	call_deferred("_load_map_data")

func _process(delta: float) -> void:
	# ALWAYS UPDATE POSITION to follow camera (so manual opens in front, and hint stays visible)
	
	var camera = _find_camera()
	if not camera:
		return
	
	# Calculate target position in front of camera
	var camera_forward = -camera.global_transform.basis.z
	camera_forward.y = 0
	if camera_forward.length_squared() < 0.01:
		camera_forward = Vector3.FORWARD
	else:
		camera_forward = camera_forward.normalized()
	
	var target_pos = camera.global_position + camera_forward * display_distance
	target_pos.y = camera.global_position.y + height_offset
	
	# Smoothly interpolate root position
	global_position = global_position.lerp(target_pos, delta * follow_speed)
	
	# Look at camera
	var look_target = camera.global_position
	look_target.y = global_position.y
	
	if global_position.distance_to(look_target) > 0.1:
		var look_away_target = 2 * global_position - look_target
		var target_transform = global_transform.looking_at(look_away_target, Vector3.UP)
		
		# Apply drafting-table tilt (rotate around local X axis)
		var tilt_basis = Basis(Vector3.RIGHT, deg_to_rad(tilt_angle))
		target_transform.basis = target_transform.basis * tilt_basis
		
		global_transform = global_transform.interpolate_with(target_transform, delta * follow_speed)

	# Update Hint Visibility
	if hint_label:
		# Show hint if: Manual ClOSED, Not Animating, Has Content
		var should_show_hint = not is_visible and not is_animating and has_content
		# hint_label.visible = should_show_hint
		hint_label.visible = false # Disabled by request
		
		if should_show_hint:
			# Update text if needed
			if map_name_for_hint != "":
				hint_label.text = "(X) Info: %s" % map_name_for_hint
			else:
				hint_label.text = "(X) Info"
			
			# STRICT Position update (No smoothing for hint)
			# Calculate position directly from camera
			var h_forward = -camera.global_transform.basis.z
			h_forward.y = 0
			if h_forward.length_squared() > 0.01:
				h_forward = h_forward.normalized()
			else:
				h_forward = Vector3.FORWARD
				
			var h_pos = camera.global_position + h_forward * hint_distance
			h_pos.y = camera.global_position.y + hint_height_offset
			
			# Apply horizontal offset? (Assuming 0 for now based on recent edits, or relative to forward right)
			if abs(hint_horizontal_offset) > 0.001:
				var h_right = h_forward.cross(Vector3.UP).normalized()
				h_pos += h_right * hint_horizontal_offset
			
			hint_label.global_position = h_pos 
			# Note: hint_height_offset is absolute relative to cam, but position is local to root.
			# Root is at cam + height_offset.
			# So local hint y = hint_height - height_offset.
			# e.g. -0.6 - (-0.3) = -0.3 (lower than manual)

func toggle_manual() -> void:
	if is_animating:
		return
	
	if is_visible:
		hide_manual()
	else:
		show_manual()

func show_manual() -> void:
	if is_visible or is_animating:
		return

	print("MapManual: Showing manual...")

	# Ensure UI nodes are found (in case they weren't during _ready)
	if not tab_menu:
		_find_ui_nodes()

	# Reload map data each time we show (in case map changed)
	_load_map_data()
	
	is_animating = true
	is_visible = true
	
	if hint_label:
		hint_label.visible = false
	
	# Animate Viewport2D scale
	if viewport_2d:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		
		viewport_2d.scale = Vector3.ONE * 0.001
		tween.tween_property(viewport_2d, "scale", Vector3.ONE, animation_duration)
		tween.tween_callback(_on_show_complete)
	else:
		_on_show_complete()

func hide_manual() -> void:
	if not is_visible or is_animating:
		return
	
	is_animating = true
	
	# Animate Viewport2D scale out
	if viewport_2d:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_BACK)
		
		tween.tween_property(viewport_2d, "scale", Vector3.ONE * 0.001, animation_duration * 0.7)
		tween.tween_callback(_on_hide_complete)
	else:
		_on_hide_complete()

func _on_show_complete() -> void:
	is_animating = false
	is_visible = true

func _on_hide_complete() -> void:
	is_animating = false
	is_visible = false
	# Hint will reappear automatically in _process if conditions met

func _load_map_data() -> void:
	"""Load map information from current map's data"""
	pages.clear()
	has_content = false
	print("MapManual: Loading map data...")
	
	# Find GridSystem
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if not grid_system:
		grid_system = _find_node_by_class(get_tree().current_scene, "GridSystem")
	
	if grid_system:
		print("MapManual: Found GridSystem")
		var data_component = grid_system.get_data_component()
		if data_component:
			if data_component.json_loader and data_component.json_loader.map_data:
				print("MapManual: Got map data from GridSystem.data_component.json_loader")
				_parse_map_data(data_component.json_loader.map_data)
				return
	
	# Fallback: show default message if nothing found
	print("MapManual: No map data found, using fallback")
	pages.append("# Map Manual\n\nNo map data available.\n\nPress **X** to close.")
	_update_display()

func _parse_map_data(map_data: Dictionary) -> void:
	"""Parse map_data.json and create pages"""
	var content: String = ""
	map_name_for_hint = ""
	available_md_files.clear()

	if map_data.has("map_info"):
		# Prefer lookup_name for folder matching
		if map_data.map_info.has("lookup_name"):
			current_map_name = map_data.map_info.lookup_name
		elif map_data.map_info.has("name"):
			current_map_name = map_data.map_info.name

		# Use display name for hint
		if map_data.map_info.has("name"):
			map_name_for_hint = map_data.map_info.name

	# Detect available md files in map directory
	# Try both original name and with underscores (e.g., "Point Zero" -> "Point_Zero")
	print("MapManual: Detecting md files for map: '%s'" % current_map_name)
	if not current_map_name.is_empty():
		var folder_candidates = [
			current_map_name,
			current_map_name.replace(" ", "_")
		]
		# Also try display name if different from lookup name
		if not map_name_for_hint.is_empty() and map_name_for_hint != current_map_name:
			folder_candidates.append(map_name_for_hint)
			folder_candidates.append(map_name_for_hint.replace(" ", "_"))
		var md_types = ["summary", "technical", "critical", "blurb", "manual"]

		for folder_name in folder_candidates:
			var map_dir = "res://commons/maps/%s/" % folder_name
			print("MapManual: Checking folder: %s" % map_dir)
			for md_type in md_types:
				if available_md_files.has(md_type):
					continue  # Already found this type
				var md_path = map_dir + md_type + ".md"
				if FileAccess.file_exists(md_path):
					available_md_files[md_type] = md_path
					print("MapManual: Found %s.md in %s" % [md_type, folder_name])

		print("MapManual: Total md files found: %d - %s" % [available_md_files.size(), str(available_md_files.keys())])

	# Update tab visibility based on available files
	_update_tab_visibility()

	# Auto-select first available tab
	var tab_priority = ["summary", "technical", "critical", "blurb", "manual"]
	for tab_type in tab_priority:
		if available_md_files.has(tab_type):
			_select_tab(tab_type)
			has_content = true
			return

	# Check explicit manual_file reference in map_info
	if map_data.has("map_info") and map_data.map_info.has("manual_file"):
		var manual_path = map_data.map_info.manual_file
		var file_content = _load_markdown_file(manual_path)
		if not file_content.is_empty():
			has_content = true
			_split_and_add_pages(file_content)
			return

	# Fallback - inline data
	if map_data.has("map_info"):
		var info = map_data.map_info
		content = "# %s\n\n" % info.get("name", "Unknown Map")
		content += "%s\n\n" % info.get("description", "")
		has_content = true
		pages.append(content)

	if pages.is_empty():
		pages.append("# Map Manual\n\nNo content available.")

	current_page = 0
	_update_display()

func _split_and_add_pages(file_content: String) -> void:
	var page_parts = file_content.split("\n---PAGE---\n")
	if page_parts.size() > 1:
		for part in page_parts:
			pages.append(part.strip_edges())
	else:
		pages.append(file_content)
	current_page = 0
	_update_display()

func _load_markdown_file(file_path: String) -> String:
	if not FileAccess.file_exists(file_path):
		return ""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return ""
	var content = file.get_as_text()
	file.close()
	return content

func _update_display() -> void:
	if pages.is_empty():
		return
	var content = pages[current_page]
	
	if markdown_label:
		markdown_label.bbcode_enabled = true
		markdown_label.text = _parse_markdown(content)
	
	if page_label:
		page_label.text = "Page %d / %d" % [current_page + 1, pages.size()]
	
	if scroll_container:
		scroll_container.scroll_vertical = 0

func _parse_markdown(md: String) -> String:
	var text = md
	# 1. Code Blocks
	var block_code = RegEx.new()
	block_code.compile("```([^`]+)```")
	text = block_code.sub(text, "[font_size=28][color=#aaddff][code]$1[/code][/color][/font_size]", true)
	# 2. Headers
	var h3 = RegEx.new()
	h3.compile("(^|\\n)### (.*)")
	text = h3.sub(text, "$1[font_size=40][b]$2[/b][/font_size]", true)
	var h2 = RegEx.new()
	h2.compile("(^|\\n)## (.*)")
	text = h2.sub(text, "$1[font_size=48][b]$2[/b][/font_size]", true)
	var h1 = RegEx.new()
	h1.compile("(^|\\n)# (.*)")
	text = h1.sub(text, "$1[font_size=60][b]$2[/b][/font_size]", true)
	# 3. Bold
	var bold = RegEx.new()
	bold.compile("\\*\\*([^*]+)\\*\\*")
	text = bold.sub(text, "[b]$1[/b]", true)
	# 4. Italic
	var italic_simple = RegEx.new()
	italic_simple.compile("\\*([^*]+)\\*")
	text = italic_simple.sub(text, "[i]$1[/i]", true)
	# 5. Lists
	text = text.replace("\n- ", "\n• ")
	text = text.replace("\n* ", "\n• ")
	# 6. Inline Code
	var inline_code = RegEx.new()
	inline_code.compile("`([^`]+)`")
	text = inline_code.sub(text, "[color=#aaddff][code]$1[/code][/color]", true)
	# 7. HR
	var hr = RegEx.new()
	hr.compile("(?m)^---$")
	text = hr.sub(text, "\n[color=#ffffff44]________________________________________[/color]\n", true)
	return text

func next_page() -> void:
	if pages.size() <= 1: return
	current_page = (current_page + 1) % pages.size()
	_update_display()

func prev_page() -> void:
	if pages.size() <= 1: return
	current_page = (current_page - 1 + pages.size()) % pages.size()
	_update_display()

# --- MISSING FUNCTIONS RESTORED BELOW ---

func _find_ui_nodes() -> void:
	if not viewport_2d: return

	var ui_instance = null
	if viewport_2d.has_method("get_scene_instance"):
		ui_instance = viewport_2d.get_scene_instance()

	if not ui_instance:
		var viewport = viewport_2d.get_node_or_null("Viewport")
		if viewport and viewport.get_child_count() > 0:
			ui_instance = viewport.get_child(0)

	if not ui_instance:
		print("MapManual: UI instance not found")
		return

	title_label = ui_instance.get_node_or_null("TitleBar/Title")
	scroll_container = ui_instance.get_node_or_null("ScrollContainer")
	if scroll_container:
		markdown_label = scroll_container.get_node_or_null("MarkdownLabel")

	var page_bar = ui_instance.get_node_or_null("PageBar")
	if page_bar:
		page_label = page_bar.get_node_or_null("PageLabel")
		prev_button = page_bar.get_node_or_null("PrevButton")
		next_button = page_bar.get_node_or_null("NextButton")

		# Connect buttons
		if prev_button:
			if not prev_button.pressed.is_connected(prev_page):
				prev_button.pressed.connect(prev_page)
		if next_button:
			if not next_button.pressed.is_connected(next_page):
				next_button.pressed.connect(next_page)

	# Find tab menu
	tab_menu = ui_instance.get_node_or_null("TabMenu")
	if tab_menu:
		summary_tab = tab_menu.get_node_or_null("SummaryTab")
		technical_tab = tab_menu.get_node_or_null("TechnicalTab")
		critical_tab = tab_menu.get_node_or_null("CriticalTab")
		blurb_tab = tab_menu.get_node_or_null("BlurbTab")

		# Connect tab buttons
		if summary_tab and not summary_tab.pressed.is_connected(_on_tab_pressed):
			summary_tab.pressed.connect(_on_tab_pressed.bind("summary"))
		if technical_tab and not technical_tab.pressed.is_connected(_on_tab_pressed):
			technical_tab.pressed.connect(_on_tab_pressed.bind("technical"))
		if critical_tab and not critical_tab.pressed.is_connected(_on_tab_pressed):
			critical_tab.pressed.connect(_on_tab_pressed.bind("critical"))
		if blurb_tab and not blurb_tab.pressed.is_connected(_on_tab_pressed):
			blurb_tab.pressed.connect(_on_tab_pressed.bind("blurb"))

func _find_vr_controllers() -> void:
	# First try to find our parent XROrigin3D (since MapManual is a child of it)
	var xr_origin = get_parent()
	if not xr_origin or not xr_origin.name.contains("XROrigin"):
		xr_origin = get_tree().get_first_node_in_group("xr_origin")
	
	if xr_origin:
		# Try both naming conventions
		left_controller = xr_origin.find_child("LeftHandController", true, false)
		if not left_controller:
			left_controller = xr_origin.find_child("LeftController", true, false)
		
		right_controller = xr_origin.find_child("RightHandController", true, false)
		if not right_controller:
			right_controller = xr_origin.find_child("RightController", true, false)
		
		print("MapManual: Found controllers - Left: %s, Right: %s" % [left_controller != null, right_controller != null])
	
	# Fallback: search for any XRController3D nodes
	if not left_controller:
		var controllers = get_tree().get_nodes_in_group("xr_controllers")
		for controller in controllers:
			if controller is XRController3D:
				if not left_controller:
					left_controller = controller
				elif not right_controller:
					right_controller = controller
					break

func _connect_controller_signals() -> void:
	if left_controller:
		if not left_controller.button_pressed.is_connected(_on_controller_button_pressed):
			left_controller.button_pressed.connect(_on_controller_button_pressed.bind(left_controller))
	
	if right_controller:
		if not right_controller.button_pressed.is_connected(_on_controller_button_pressed):
			right_controller.button_pressed.connect(_on_controller_button_pressed.bind(right_controller))

func _on_controller_button_pressed(button: String, _controller: XRController3D) -> void:
	# Toggle on X button (ax_button)
	if button == "ax_button":
		toggle_manual()

func _input(event: InputEvent) -> void:
	# Desktop fallback: M key toggles manual
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			print("MapManual: M key pressed, toggling manual")
			toggle_manual()
		elif is_visible:
			if event.keycode == KEY_RIGHT or event.keycode == KEY_DOWN:
				next_page()
			elif event.keycode == KEY_LEFT or event.keycode == KEY_UP:
				prev_page()
			elif event.keycode == KEY_ESCAPE:
				hide_manual()
			elif event.keycode == KEY_PAGEDOWN:
				_scroll_by(200)
			elif event.keycode == KEY_PAGEUP:
				_scroll_by(-200)
	
	# Mouse wheel scrolling
	if is_visible and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_by(-50)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_by(50)

func _scroll_by(amount: int) -> void:
	"""Scroll the content by the given amount"""
	if scroll_container:
		scroll_container.scroll_vertical += amount

func _find_camera() -> Camera3D:
	"""Find any available camera in the scene"""
	var camera = get_viewport().get_camera_3d()
	if camera: return camera
	camera = get_tree().root.find_child("XRCamera3D", true, false)
	if camera: return camera
	var cameras = get_tree().get_nodes_in_group("cameras")
	if cameras.size() > 0: return cameras[0]
	camera = get_tree().root.find_child("Camera3D", true, false)
	if camera: return camera
	return null

func _find_node_by_class(node: Node, target_class_name: String) -> Node:
	if node == null: return null
	if node.get_script() and node.get_script().get_global_name() == target_class_name:
		return node
	for child in node.get_children():
		var result = _find_node_by_class(child, target_class_name)
		if result: return result
	return null

# --- TAB MENU FUNCTIONS ---

func _update_tab_visibility() -> void:
	"""Show/hide tabs based on which md files exist"""
	print("MapManual: _update_tab_visibility called, available_md_files: %s" % str(available_md_files.keys()))

	if not tab_menu:
		print("MapManual: Tab menu not found yet, trying to find UI nodes now...")
		_find_ui_nodes()
		
	if not tab_menu:
		print("MapManual: Tab menu STILL not found, skipping visibility update")
		return

	if summary_tab:
		summary_tab.visible = available_md_files.has("summary")
	if technical_tab:
		technical_tab.visible = available_md_files.has("technical")
	if critical_tab:
		critical_tab.visible = available_md_files.has("critical")
	if blurb_tab:
		blurb_tab.visible = available_md_files.has("blurb")

	# Show tab menu if any tab-able md files available (summary, technical, critical, blurb)
	var visible_count = 0
	if available_md_files.has("summary"): visible_count += 1
	if available_md_files.has("technical"): visible_count += 1
	if available_md_files.has("critical"): visible_count += 1
	if available_md_files.has("blurb"): visible_count += 1
	tab_menu.visible = visible_count >= 1
	print("MapManual: Tab menu visible: %s (tab count: %d)" % [tab_menu.visible, visible_count])

func _on_tab_pressed(tab_type: String) -> void:
	"""Handle tab button press"""
	_select_tab(tab_type)

func _select_tab(tab_type: String) -> void:
	"""Select and load a specific tab"""
	print("MapManual: _select_tab called with: %s" % tab_type)
	if not available_md_files.has(tab_type):
		print("MapManual: Tab type '%s' not in available_md_files" % tab_type)
		return

	current_md_type = tab_type
	pages.clear()

	# Update tab button states
	_update_tab_button_states()

	# Load the md file content
	var file_path = available_md_files[tab_type]
	print("MapManual: Loading content from: %s" % file_path)
	var file_content = _load_markdown_file(file_path)

	if not file_content.is_empty():
		print("MapManual: Loaded %d characters from %s" % [file_content.length(), tab_type])
		_split_and_add_pages(file_content)
	else:
		print("MapManual: File was empty for %s" % tab_type)
		pages.append("# %s\n\nNo content available." % tab_type.capitalize())
		current_page = 0
		_update_display()

func _update_tab_button_states() -> void:
	"""Update visual state of tab buttons"""
	if summary_tab:
		summary_tab.button_pressed = (current_md_type == "summary")
	if technical_tab:
		technical_tab.button_pressed = (current_md_type == "technical")
	if critical_tab:
		critical_tab.button_pressed = (current_md_type == "critical")
	if blurb_tab:
		blurb_tab.button_pressed = (current_md_type == "blurb")
