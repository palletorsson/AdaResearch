extends Node3D

# @identity
# essence: grabbable board with paginated text/code content, proximity reveal shader, VR page-flip via trigger/grip
# desire: learner picks up a physical document and reads it in VR — code and theory delivered as held artifact
# critical_parameter: description_sets — the array of page strings; empty means no content, one means single-page
# triggers: picking up → shows page navigation hint; trigger/grip buttons flip pages; drop → awards XP/SP
# emerges: reading as an embodied act — you must hold the clipboard to read it, creating intentional engagement
# needs: [has grabbable GrabPlane [has], has VR trigger/grip page flip [has], has Label3D page number [has]]
# relationships: content loaded via apply_grid_config (tutorial ID or page keys); used in nearly every map
# truth: a text in VR is not passive — the learner must pick it up, hold it, and navigate it with their hands

const CodeSnippetLibrary := preload("res://commons/context/clipboard/code_snippet_library.gd")
const TutorialTextLibrary := preload("res://commons/context/clipboard/tutorial_text_library.gd")

@export var addxp: int = 20
@export var dessp: int = -2

@onready var code_display_node: Node = _first_existing_node([
	"GrabPlane/clipboard/ViewportDisplay/textFrame",
	"GrabPlane/clipboard/ViewportDisplay/UINoiseBlobControl"
])
@onready var title_node: Node = _first_existing_node([
	"GrabPlane/clipboard/ViewportDisplay/ContentViewport/ViewportRoot/MarginContainer/VBoxContainer/Title",
	"GrabPlane/clipboard/ViewportDisplay/ContentViewport/ViewportRoot/Title",
	"GrabPlane/clipboard/page/Title"
])
@onready var description_plain_label: Node = _first_existing_node([
	"GrabPlane/clipboard/page/Description"
])
@onready var description_rich_text: RichTextLabel = _first_existing_node([
	"GrabPlane/clipboard/ViewportDisplay/ContentViewport/ViewportRoot/MarginContainer/VBoxContainer/ScrollContainer/Description",
	"GrabPlane/clipboard/ViewportDisplay/ContentViewport/ViewportRoot/Description"
]) as RichTextLabel
@onready var scroll_container: ScrollContainer = _first_existing_node([
	"GrabPlane/clipboard/ViewportDisplay/ContentViewport/ViewportRoot/MarginContainer/VBoxContainer/ScrollContainer"
]) as ScrollContainer
@onready var grab_cube = $GrabPlane
@onready var label3D = $GrabPlane/clipboard/page/pagenumber
@onready var pagenumber = $GrabPlane/clipboard/page/pagenumber
@onready var grab_pos = grab_cube
@onready var _content_viewport: SubViewport = _first_existing_node([
	"GrabPlane/clipboard/ViewportDisplay/ContentViewport"
]) as SubViewport
@onready var _viewport_sprite: Sprite3D = _first_existing_node([
	"GrabPlane/clipboard/ViewportDisplay/ViewportSprite"
]) as Sprite3D

@export var title = ""
@export var description_sets: Array[String] = []
@export var fade_min_dist: float = 1.5 # Max opacity at this distance
@export var fade_max_dist: float = 2.0 # Zero opacity at this distance

var current_index: int = 0
var is_executed = false
var _snippet_library := CodeSnippetLibrary.new()
var _tutorial_library: TutorialTextLibrary

var init_position: Vector3
var _is_being_held: bool = false

func _process(_delta: float) -> void:
	# Proximity Reveal Logic (Smart Screen)
	var camera = get_viewport().get_camera_3d()
	if not camera: return
	
	var dist = global_position.distance_to(camera.global_position)
	var reveal = clamp(remap(dist, fade_min_dist, fade_max_dist, 1.0, 0.0), 0.0, 1.0)
	
	if _screen_material:
		_screen_material.set_shader_parameter("reveal_height", reveal)
		
	if _body_material:
		_body_material.set_shader_parameter("reveal_height", reveal)
		
	if _inner_material:
		_inner_material.set_shader_parameter("reveal_height", reveal)

	# Fallbacks for other elements (Title, Page Number)
	if pagenumber:
		pagenumber.modulate.a = reveal
		pagenumber.outline_modulate.a = reveal
		
	if title_node and title_node is Label3D:
		title_node.modulate.a = reveal
		title_node.outline_modulate.a = reveal

var _screen_mesh: MeshInstance3D
var _screen_material: ShaderMaterial
var _body_mesh: Node # Can be MeshInstance3D or CSGShape3D
var _body_material: ShaderMaterial
var _inner_mesh: Node
var _inner_material: ShaderMaterial

## The tutorial library, built on demand.
##
## _ready() used to be the only place it was created, but apply_grid_config can run
## BEFORE _ready — the museum stamps config on a root that is still outside the tree
## (endless_museum.gd:6581) — and all four fallback paths in this file dereferenced
## it blind. It is a plain object with no tree dependency, so there is no reason to
## make it wait for _ready.
func _library() -> TutorialTextLibrary:
	if _tutorial_library == null:
		_tutorial_library = TutorialTextLibrary.new()
	return _tutorial_library


func _ready() -> void:
	# Initialize tutorial library
	_library()
	
	# Setup Smart Screen Shader
	var viewport_2d = null
	if code_display_node:
		viewport_2d = code_display_node.get_node_or_null("Viewport2Din3D")
		if viewport_2d:
			_find_screen_mesh_recursive(viewport_2d)
			
	if _screen_mesh:
		var shader = load("res://commons/context/clipboard/smart_screen_reveal.gdshader")
		var mat = ShaderMaterial.new()
		mat.shader = shader
		# Get texture from existing material or viewport

		
		# Assuming standard godot-xr-tools viewport_2d setup which uses a "Screen" child
		# or apply to mesh override
		
		# We need the texture!
		# Viewport2Din3D typically sets material_override or surface_material_override
		var old_mat = _screen_mesh.get_active_material(0)
		if old_mat and old_mat is StandardMaterial3D:
			mat.set_shader_parameter("texture_albedo", old_mat.albedo_texture)
		elif viewport_2d:
			# Try to get viewport texture directly
			var sub_viewport = viewport_2d.get_node_or_null("Viewport")
			if sub_viewport:
				mat.set_shader_parameter("texture_albedo", sub_viewport.get_texture())
		
		_screen_material = mat
		_screen_mesh.material_override = mat

	# Setup Body Reveal Shader
	var grab_plane = get_node_or_null("GrabPlane")
	if grab_plane:
		# Check for CSG nodes first as seen in tscn analysis
		var collision_shape = grab_plane.get_node_or_null("CollisionShape3D")
		if collision_shape:
			var csg_box = collision_shape.get_node_or_null("CSGBox3D")
			if csg_box and csg_box is CSGShape3D:
				_body_mesh = csg_box
		
		# Fallback to MeshInstance3D if CSG structure is different or hidden
		if not _body_mesh:
			_body_mesh = grab_plane.get_node_or_null("MeshInstance3D")
			
	if _body_mesh:
		# Also look for the inner subtractor mesh (child CSG)
		# In grab_plane.tscn: CollisionShape3D -> CSGBox3D (body) -> CSGBox3D (subtractor)
		for child in _body_mesh.get_children():
			if child is CSGShape3D:
				_inner_mesh = child
				break
				
		var shader = load("res://commons/context/clipboard/smart_screen_reveal.gdshader")
		var mat = ShaderMaterial.new()
		mat.shader = shader
		
		# For body, we want the original color, not a texture usually
		# But key is to preserve ALBEDO
		# The shader expects a texture. Creating a simple color texture or modifying shader?
		# Existing shader uses texture_albedo. Let's create a small viewport texture or noise?
		# Or better: check if body has material and get texture. If not, use white or color.
		
		var old_mat = null
		if _body_mesh is MeshInstance3D:
			old_mat = _body_mesh.get_active_material(0)
		elif _body_mesh is CSGShape3D:
			old_mat = _body_mesh.material
			
		# Force Black texture for the clipboard body style
		var img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.05, 0.05, 0.05, 1)) # Dark Grey/Black
		var tex = ImageTexture.create_from_image(img)
		mat.set_shader_parameter("texture_albedo", tex)

		_body_material = mat
		if _body_mesh is CSGShape3D:
			_body_mesh.material = mat
		elif _body_mesh is MeshInstance3D:
			_body_mesh.material_override = mat

		# Apply to inner mesh if found
		if _inner_mesh:
			# Inner mesh usually needs a different color (darker for the hole?)
			# Or we can reuse _body_material if we want same reveal
			# But if we reuse, it shares uniform updates automatically!
			
			# Wait, if we use same material instance, set_shader_parameter updates both.
			# But inner mesh might need different texture (dark hole).
			
			var inner_mat = mat.duplicate()
			# Darker texture for inner hole
			var img_inner = Image.create(4, 4, false, Image.FORMAT_RGBA8)
			img_inner.fill(Color(0.1, 0.1, 0.1, 1)) # Dark grey for inside
			var tex_inner = ImageTexture.create_from_image(img_inner)
			inner_mat.set_shader_parameter("texture_albedo", tex_inner)
			
			_inner_material = inner_mat
			if _inner_mesh is CSGShape3D:
				_inner_mesh.material = inner_mat
			elif _inner_mesh is MeshInstance3D:
				_inner_mesh.material_override = inner_mat

func _find_screen_mesh_recursive(node: Node):
	if node is MeshInstance3D:
		_screen_mesh = node
		return
	for child in node.get_children():
		_find_screen_mesh_recursive(child)
		if _screen_mesh: return


	if _content_viewport and _viewport_sprite:
		_content_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_viewport_sprite.texture = _content_viewport.get_texture()

	if description_rich_text:
		description_rich_text.bbcode_enabled = true
		description_rich_text.fit_content = true
	else:
		_set_text(description_plain_label, "")

	var map_pages := _extract_pages_from_metadata()
	if map_pages.size() > 0:
		description_sets = map_pages

	if description_sets.size() == 0:
		_load_from_map_data()

	init_position = grab_pos.position

	if grab_cube.has_signal("item_dropped"):
		if not grab_cube.is_connected("item_dropped", Callable(self, "_on_item_dropped")):
			grab_cube.connect("item_dropped", Callable(self, "_on_item_dropped"))
		_set_text(label3D, "Grab me: " + str(init_position))
	else:
		print("GrabCube does not have 'item_dropped' signal!")
		if label3D:
			_set_text(label3D, "Error: 'item_dropped' signal missing!")

	# Connect to pickup signals for page navigation
	if grab_cube.has_signal("picked_up"):
		if not grab_cube.is_connected("picked_up", Callable(self, "_on_clipboard_picked_up")):
			grab_cube.connect("picked_up", Callable(self, "_on_clipboard_picked_up"))
	if grab_cube.has_signal("dropped"):
		if not grab_cube.is_connected("dropped", Callable(self, "_on_clipboard_dropped")):
			grab_cube.connect("dropped", Callable(self, "_on_clipboard_dropped"))

	if description_sets.size() > 0:
		_update_display()
	
	if title.is_empty():
		title = _get_title_from_map_data()
	_set_text(title_node, title)

func _on_item_dropped() -> void:
	if is_executed:
		_set_text(label3D, "Already read them")
		return

	is_executed = true
	var health = GameManager.get_health() + dessp
	GameManager.set_health(health)
	var xp = GameManager.get_xp() + addxp
	GameManager.set_xp(xp)
	_set_text(label3D, "XP/SP updated")

func _on_clipboard_picked_up(_pickable) -> void:
	_is_being_held = true
	# Update page display to show current page when picked up
	if description_sets.size() > 1:
		_set_text(label3D, "Arrows/Trigger=Next, Grip=Prev")

func _on_clipboard_dropped(_pickable) -> void:
	_is_being_held = false

func _next_page() -> void:
	if description_sets.is_empty():
		return
	current_index = (current_index + 1) % description_sets.size()
	_update_display()

func _prev_page() -> void:
	if description_sets.is_empty():
		return
	current_index = (current_index - 1 + description_sets.size()) % description_sets.size()
	_update_display()

func _input(event: InputEvent) -> void:
	# Only process input if clipboard has multiple pages
	if description_sets.size() <= 1:
		return

	# Keyboard navigation for testing (works anytime)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_RIGHT or event.keycode == KEY_DOWN:
			_next_page()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_LEFT or event.keycode == KEY_UP:
			_prev_page()
			get_viewport().set_input_as_handled()

	# VR controller button navigation (only when held)
	elif _is_being_held and event is InputEventAction and event.pressed:
		if event.action == "trigger" or event.action == "by_button":
			_next_page()
			get_viewport().set_input_as_handled()
		elif event.action == "grip" or event.action == "ax_button":
			_prev_page()
			get_viewport().set_input_as_handled()

func _update_display() -> void:
	if description_sets.is_empty() or current_index >= description_sets.size():
		return

	var raw_text := description_sets[current_index]
	if description_rich_text:
		description_rich_text.bbcode_text = _snippet_library.expand_text(raw_text, true)
	else:
		_set_text(description_plain_label, _snippet_library.expand_to_plain(raw_text))

	_set_text(pagenumber, "(Page: %d of %d pages)" % [current_index + 1, description_sets.size()])

	# Reset scroll to top when changing pages
	if scroll_container:
		scroll_container.scroll_vertical = 0

func _extract_pages_from_metadata() -> Array[String]:
	if has_meta("clipboard_pages") and typeof(get_meta("clipboard_pages")) == TYPE_ARRAY:
		var pages_meta = get_meta("clipboard_pages")
		var result: Array[String] = []
		for entry in pages_meta:
			result.append(str(entry))
		return result
	
	if description_sets.size() > 0:
		return description_sets
	
	return []

func _load_from_map_data() -> void:
	var map_manager = get_node_or_null("/root/GameManager")
	if not map_manager or not map_manager.has_method("get_current_map_data"):
		print("Warning: Cannot access current map data")
		return
	
	var map_data = map_manager.get_current_map_data()
	if not map_data:
		return
	
	if map_data.has("interactable_data") and map_data.interactable_data.has("clipboard"):
		var clipboard_data = map_data.interactable_data.clipboard
		
		if clipboard_data.has("pages") and typeof(clipboard_data.pages) == TYPE_ARRAY:
			description_sets = clipboard_data.pages
			print("Loaded %d pages from map data" % description_sets.size())
		
		if clipboard_data.has("title") and typeof(clipboard_data.title) == TYPE_STRING:
			title = clipboard_data.title

func _get_title_from_map_data() -> String:
	var map_manager = get_node_or_null("/root/GameManager")
	if not map_manager or not map_manager.has_method("get_current_map_data"):
		return "Code Snippets"
	
	var map_data = map_manager.get_current_map_data()
	if not map_data:
		return "Code Snippets"
	
	if map_data.has("interactable_data") and map_data.interactable_data.has("clipboard"):
		var clipboard_data = map_data.interactable_data.clipboard
		if clipboard_data.has("title"):
			return str(clipboard_data.title)
	
	return "Code Snippets"

func refresh_content() -> void:
	description_sets.clear()
	title = ""
	_load_from_map_data()
	if title.is_empty():
		title = _get_title_from_map_data()
	_set_text(title_node, title)
	current_index = 0
	if description_sets.size() > 0:
		_update_display()
	else:
		if description_rich_text:
			description_rich_text.bbcode_text = "[i]No content loaded[/i]"
		else:
			_set_text(description_plain_label, "No content loaded")

func apply_grid_config(config_data: Dictionary) -> void:
	print("Clipboard: Applying grid configuration: %s" % config_data)
	var needs_refresh = false

	# Check if there's a direct tutorial ID as a key (shorthand syntax)
	# e.g., clipboard#point_zero:15:-0.3:1.1 â†’ {"point_zero": "15:-0.3:1.1"}
	for key in config_data.keys():
		var key_str = str(key).strip_edges()
		# Skip known parameter keys
		if key_str in ["pages", "title", "content"]:
			continue

		var value = config_data[key]

		# Check if this looks like a tutorial ID (either truthy or has transform params)
		var is_tutorial_key = false

		# Case 1: Simple boolean or "true" string
		if typeof(value) == TYPE_BOOL and value:
			is_tutorial_key = true
		elif typeof(value) == TYPE_STRING:
			if value == "true" or value.is_empty():
				is_tutorial_key = true
			# Case 2: String with transform parameters (rotation:height:scale)
			elif value.find(":") != -1:
				is_tutorial_key = true
			# Case 3: Single numeric value (just rotation, e.g., "180" or "-90")
			elif value.is_valid_float():
				is_tutorial_key = true

		if is_tutorial_key:
			# Try to use codeDisplay node if available
			if code_display_node and code_display_node.has_method("set_tutorial"):
				code_display_node.set_tutorial(key_str)
				print("  -> Loaded tutorial via codeDisplay: %s" % key_str)
				return  # Done - codeDisplay handles everything
			else:
				# Fallback to loading content directly
				var tutorial_content = _library().get_tutorial_content(key_str)
				if not tutorial_content.is_empty():
					description_sets = [tutorial_content]
					print("  -> Loaded tutorial from shorthand: %s" % key_str)
					needs_refresh = true
					break  # Use the first valid tutorial found

	if config_data.has("pages"):
		var pages_config = str(config_data.pages)
		description_sets.clear()

		# Handle comma-separated pages
		if pages_config.find(",") != -1:
			var page_keys = pages_config.split(",")
			for page_key in page_keys:
				var key = page_key.strip_edges()
				if key.is_empty():
					continue

				# Check if it's a tutorial reference
				if key.begins_with("tutorial:") or key.begins_with("#tutorial:"):
					var tutorial_id = key
					if tutorial_id.begins_with("#"):
						tutorial_id = tutorial_id.substr(1)
					if tutorial_id.begins_with("tutorial:"):
						tutorial_id = tutorial_id.substr(9)

					var tutorial_content = _library().get_tutorial_content(tutorial_id)
					if not tutorial_content.is_empty():
						description_sets.append(tutorial_content)
					else:
						description_sets.append("[color=red]Error: Tutorial '%s' not found[/color]" % tutorial_id)
				else:
					# Regular code snippet
					description_sets.append("code#%s" % key.to_lower())
			print("  -> Set pages from keys: %s" % str(page_keys))
		else:
			var single_key = pages_config.strip_edges()
			if not single_key.is_empty():
				# Check if it's a tutorial reference
				if single_key.begins_with("tutorial:") or single_key.begins_with("#tutorial:"):
					var tutorial_id = single_key
					if tutorial_id.begins_with("#"):
						tutorial_id = tutorial_id.substr(1)
					if tutorial_id.begins_with("tutorial:"):
						tutorial_id = tutorial_id.substr(9)

					var tutorial_content = _library().get_tutorial_content(tutorial_id)
					if not tutorial_content.is_empty():
						description_sets.append(tutorial_content)
					else:
						description_sets.append("[color=red]Error: Tutorial '%s' not found[/color]" % tutorial_id)
				else:
					# Regular code snippet
					description_sets.append("code#%s" % single_key.to_lower())
			print("  -> Set single page: %s" % pages_config)
		needs_refresh = true

	if config_data.has("title"):
		title = str(config_data.title)
		_set_text(title_node, title)
		print("  -> Set title: %s" % title)

	if config_data.has("content"):
		var content_config = str(config_data.content)

		# Check if it's a tutorial reference (#tutorial:name or tutorial:name)
		if content_config.begins_with("#tutorial:") or content_config.begins_with("tutorial:"):
			var tutorial_id = content_config
			if tutorial_id.begins_with("#"):
				tutorial_id = tutorial_id.substr(1)  # Remove leading #

			if tutorial_id.begins_with("tutorial:"):
				tutorial_id = tutorial_id.substr(9)  # Remove "tutorial:" prefix

			# Load tutorial content
			var tutorial_content = _library().get_tutorial_content(tutorial_id)
			if not tutorial_content.is_empty():
				description_sets = [tutorial_content]
				print("  -> Loaded tutorial: %s" % tutorial_id)
			else:
				print("  -> Warning: Tutorial '%s' not found" % tutorial_id)
				description_sets = ["[color=red]Error: Tutorial '%s' not found[/color]" % tutorial_id]
		# Handle multiple pages separated by |
		elif content_config.find("|") != -1:
			description_sets = content_config.split("|")
			for i in range(description_sets.size()):
				description_sets[i] = description_sets[i].strip_edges()
		else:
			description_sets = [content_config]
		print("  -> Set content pages: %d" % description_sets.size())
		needs_refresh = true

	if needs_refresh:
		current_index = 0
		if description_sets.size() > 0:
			_update_display()
		print("  -> Refreshed clipboard display")
func _first_existing_node(paths: Array[String]) -> Node:
	for path in paths:
		var node = get_node_or_null(path)
		if node:
			return node
	return null

func _set_text(target: Node, value: String) -> void:
	if target == null:
		return
	target.set("text", value)
