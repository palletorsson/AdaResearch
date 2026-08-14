extends Node3D

signal start_game_requested
signal load_game_requested
signal quit_requested

@onready var new_game_button = $Buttons/NewGameButton
@onready var load_game_button = $Buttons/LoadGameButton
@onready var browse_button = $Buttons/BrowseButton
@onready var settings_button = $Buttons/SettingsButton
@onready var quit_button = $Buttons/QuitButton
@onready var about_display = $AboutDisplay

const MAP_BROWSER_SCENE = preload("res://commons/scenes/main_menu/components/MapBrowser3D.tscn")
const SEQUENCE_PICKER_SCENE = preload("res://commons/scenes/2din3dui/sequence_picker_3d.tscn")
var sequence_picker_instance: Node3D = null
const DESKTOP_MENU_PIXELS_PER_UNIT := 1800.0
const MOBILE_MENU_PIXELS_PER_UNIT := 1200.0
var map_browser_instance: Node3D = null

func _ready():
	_configure_menu_rendering()

	new_game_button.clicked.connect(_on_new_game_clicked)
	load_game_button.clicked.connect(_on_load_game_clicked)
	if browse_button:
		browse_button.clicked.connect(_on_browse_clicked)
	settings_button.clicked.connect(_on_settings_clicked)
	quit_button.clicked.connect(_on_quit_clicked)

	# Setup About text
	_setup_about_text()
	
	# Update Load Game button visibility based on save existence
	_update_load_button()

func _configure_menu_rendering() -> void:
	var root_viewport := get_viewport()
	if root_viewport:
		var target_msaa := Viewport.MSAA_2X if OS.has_feature("android") else Viewport.MSAA_4X
		if root_viewport.msaa_3d < target_msaa:
			root_viewport.msaa_3d = target_msaa
		if root_viewport.screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED:
			root_viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA

	_configure_embedded_viewport_quality(about_display)

func _configure_embedded_viewport_quality(root: Node) -> void:
	if not root:
		return

	var viewport_2d = root.get_node_or_null("Viewport2Din3D")
	if not viewport_2d:
		return

	var pixels_per_unit := MOBILE_MENU_PIXELS_PER_UNIT if OS.has_feature("android") else DESKTOP_MENU_PIXELS_PER_UNIT
	var screen_size: Vector2 = viewport_2d.screen_size
	viewport_2d.viewport_size = Vector2(
		max(1.0, round(screen_size.x * pixels_per_unit)),
		max(1.0, round(screen_size.y * pixels_per_unit))
	)

	var content_viewport: SubViewport = viewport_2d.get_node_or_null("Viewport")
	if content_viewport:
		content_viewport.msaa_2d = Viewport.MSAA_2X if OS.has_feature("android") else Viewport.MSAA_4X

func _setup_about_text():
	var about_text = """[center][font_size=48][b]THRESHOLD PROTOCOL[/b][/font_size][/center]

[font_size=36]The outside is no longer survivable; the lab and its simulations endure as a shrinking threshold, where the subject must reassemble [b]X[/b]—a queer energy principle—to make return possible.[/font_size]

[center][font_size=32][color=cyan][b]QFE = F − λE(S) + φΔE(S,t)[/b][/color][/font_size][/center]

[center][font_size=28][color=gray][i]"We can only see a short distance ahead, but we can see plenty there that needs to be done."[/i]
— Alan Turing[/color][/font_size][/center]
"""
	if about_display.has_method("set_tutorial_from_text"):
		about_display.set_tutorial_from_text(about_text)

func _update_load_button():
	# The Sequences button (formerly "Load Game") opens the picker and
	# does not depend on a saved checkpoint, so it stays at its scene
	# colour at all times. This function used to dim it when no save
	# existed — that behavior is obsolete now that the button always
	# does something useful regardless of save state.
	#
	# Kept as a no-op so external callers (and the existing _ready
	# hook) don't crash. Remove the call if/when the rest of the
	# checkpoint UX is rewired.
	return

func _on_new_game_clicked():
	print("MainMenu: New Game clicked")
	
	# Clear any existing checkpoints
	var checkpoint_manager = get_node_or_null("/root/CheckpointManager")
	if checkpoint_manager and checkpoint_manager.has_method("clear_checkpoints"):
		checkpoint_manager.clear_checkpoints()
	
	# Reset map progression
	var progression_manager = get_node_or_null("/root/MapProgressionManager")
	if progression_manager and progression_manager.has_method("reset_progress"):
		progression_manager.reset_progress()
	
	start_game_requested.emit()

func _on_load_game_clicked():
	# Load Game now opens the sequence picker — a 2D-in-3D panel listing
	# all spine sequences as info cards with Play buttons. Each card
	# loads that sequence's first map via SceneManager.start_sequence.
	# (The old behavior — resume from checkpoint OR start new game — was
	# broken when no checkpoint existed and gave the player no way to
	# pick a sequence. The picker fixes that.)
	print("MainMenu: Load Game clicked — opening sequence picker")
	_open_sequence_picker()


func _open_sequence_picker():
	# Close other panels if open
	if settings_instance:
		settings_instance.queue_free()
		settings_instance = null
	if map_browser_instance:
		map_browser_instance.queue_free()
		map_browser_instance = null

	# Toggle: if already open, close it
	if sequence_picker_instance:
		sequence_picker_instance.queue_free()
		sequence_picker_instance = null
		if about_display:
			about_display.visible = true
		return

	# Instantiate the picker
	sequence_picker_instance = SEQUENCE_PICKER_SCENE.instantiate()
	add_child(sequence_picker_instance)

	# Connect signals
	sequence_picker_instance.sequence_play_requested.connect(_on_sequence_selected)
	sequence_picker_instance.back_requested.connect(_on_picker_back)

	# Position in the About Display slot
	if about_display:
		sequence_picker_instance.transform = about_display.transform
		about_display.visible = false
	else:
		sequence_picker_instance.position = Vector3(0.6, 0, 0)


func _on_picker_back():
	if sequence_picker_instance:
		sequence_picker_instance.queue_free()
		sequence_picker_instance = null
	if about_display:
		about_display.visible = true

const SETTINGS_SCENE = preload("res://commons/scenes/main_menu/objects/settings_ui.tscn")
var settings_instance: Node3D = null

func _on_browse_clicked():
	print("MainMenu: Browse clicked")

	# Close settings if open
	if settings_instance:
		settings_instance.queue_free()
		settings_instance = null

	# Toggle map browser
	if map_browser_instance:
		map_browser_instance.queue_free()
		map_browser_instance = null
		if about_display:
			about_display.visible = true
		return

	# Instantiate Map Browser
	map_browser_instance = MAP_BROWSER_SCENE.instantiate()
	add_child(map_browser_instance)

	# Connect signals
	map_browser_instance.sequence_selected.connect(_on_sequence_selected)
	map_browser_instance.map_selected.connect(_on_map_selected)
	map_browser_instance.back_requested.connect(_on_browser_back)

	# Position where About Display was
	if about_display:
		map_browser_instance.transform = about_display.transform
		about_display.visible = false
	else:
		map_browser_instance.position = Vector3(0.6, 0, 0)

func _on_sequence_selected(sequence_name: String):
	# Load the chosen sequence's FIRST MAP directly — bypassing the lab.
	#
	# The old flow stashed pending_sequence_request and loaded lab.tscn; the
	# lab then consumed it and fired the transition. But the lab SKIPS its
	# own default map load when a pending request exists, so if that hand-off
	# raced during the lab's _ready the player was stranded in an empty lab
	# scene (no lab map, no sequence map) — the "green void".
	#
	# start_sequence() goes through _load_scene_with_data → _get_vr_staging(),
	# i.e. the SAME staging-aware path a teleporter uses, so the VR rig is
	# preserved. Calling it from the stable menu context avoids the empty-lab
	# limbo entirely. When the sequence ends it still returns_to "lab".
	print("MainMenu: Sequence picker selected: %s" % sequence_name)

	# Close the picker
	if sequence_picker_instance:
		sequence_picker_instance.queue_free()
		sequence_picker_instance = null

	# The endless museum is not a spine sequence — it is the negotiated
	# building itself, and it loads through the SAME staging path every
	# other scene takes (XRToolsStaging.load_scene expects an
	# XRToolsSceneBase root; endless_museum_staged.tscn inherits base.tscn
	# for exactly that reason). SceneManager.start_sequence would look for
	# a sequence JSON that doesn't exist.
	if sequence_name == "endless_museum":
		var staging := _find_staging()
		if staging:
			# same pointer hand-off _on_menu_start_game does: the staging
			# rig's pointers would fight the loaded scene's rig
			var left_pointer = find_child("FunctionPointerLeft", true, false)
			var right_pointer = find_child("FunctionPointerRight", true, false)
			if left_pointer: left_pointer.visible = false
			if right_pointer: right_pointer.visible = false
			print("MainMenu: Loading the endless museum via staging")
			staging.load_scene("res://commons/scenes/endless_museum_staged.tscn")
		else:
			push_warning("MainMenu: no XRToolsStaging ancestor — cannot load endless museum")
		return

	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.has_method("start_sequence"):
		# Clear any stale pending request so a later lab load can't double-fire.
		if "pending_sequence_request" in scene_manager:
			scene_manager.pending_sequence_request = ""
		print("MainMenu: Starting sequence directly (bypassing lab): %s" % sequence_name)
		scene_manager.start_sequence(sequence_name)
	else:
		# Fallback (older builds): old pending + lab-hub path.
		push_warning("MainMenu: SceneManager.start_sequence unavailable — falling back to lab-hub path")
		if scene_manager and "pending_sequence_request" in scene_manager:
			scene_manager.pending_sequence_request = sequence_name
		start_game_requested.emit()

func _find_staging() -> XRToolsStaging:
	# The menu is instanced inside vr_staging.tscn, so the staging system is
	# always an ancestor in the shipped loop. Walking up (rather than a
	# hardcoded path) keeps this working if the menu is ever re-parented.
	var n: Node = get_parent()
	while n != null:
		if n is XRToolsStaging:
			return n
		n = n.get_parent()
	return null

func _on_map_selected(map_name: String):
	print("MainMenu: Loading map: %s" % map_name)
	# Use SceneManager to load the map directly
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager:
		scene_manager.load_map(map_name)
	else:
		push_error("MainMenu: SceneManager not found")

func _on_browser_back():
	if map_browser_instance:
		map_browser_instance.queue_free()
		map_browser_instance = null
	if about_display:
		about_display.visible = true

func _on_settings_clicked():
	print("MainMenu: Settings clicked")

	# Close map browser if open
	if map_browser_instance:
		map_browser_instance.queue_free()
		map_browser_instance = null

	# If already open, close it (toggle behavior)
	if settings_instance:
		settings_instance.queue_free()
		settings_instance = null
		if about_display:
			about_display.visible = true
		return

	# Instantiate Settings UI
	settings_instance = SETTINGS_SCENE.instantiate()
	add_child(settings_instance)
	_configure_embedded_viewport_quality(settings_instance)

	# Swap in position: Use exact transform of About Display
	if about_display:
		settings_instance.transform = about_display.transform
		about_display.visible = false
	else:
		# Fallback if About Display is missing
		settings_instance.position = Vector3(0.6, 0, 0)
		settings_instance.rotation_degrees.y = 0

func _on_quit_clicked():
	print("MainMenu: Quit clicked")
	quit_requested.emit()
	get_tree().quit()
