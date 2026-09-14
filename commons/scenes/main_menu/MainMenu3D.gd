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

## PRELOAD, not class_name: endless_museum.gd declares no class_name, and this
## menu needs it only for the two static fields that carry a chapter across the
## staged load. Preloading the SCRIPT costs a parse the museum preload in
## vrStaging pays anyway; it does not instantiate a museum.
const MUSEUM = preload("res://commons/scenes/endless_museum.gd")
const MAP_BROWSER_SCENE = preload("res://commons/scenes/main_menu/components/MapBrowser3D.tscn")
const SEQUENCE_PICKER_SCENE = preload("res://commons/scenes/2din3dui/sequence_picker_3d.tscn")
var sequence_picker_instance: Node3D = null
const DESKTOP_MENU_PIXELS_PER_UNIT := 1800.0
const MOBILE_MENU_PIXELS_PER_UNIT := 1200.0
var map_browser_instance: Node3D = null

## THE WAY INTO THE STAGED PATH WITHOUT A HAND (2026-09-07).
##
## Palle: "the error is in the desktop when I die or respawn" — after a run that
## showed ZERO errors, because that run booted endless_museum.tscn directly and
## took the `no XRToolsStaging` fallback. The desktop APP boots through this menu
## into staging, which is a different branch and the one he is actually in.
##
## There was no way to reach it without clicking a 3D button, so a whole lane of
## the shipped game could not be exercised headless at all. One flag fixes that:
##
##   godot --path . --xr-mode off commons/scenes/vr_staging.tscn \
##       --em-autostart --em-die=12
##
## boots the app, enters the museum the way New Game does, dies, and runs the
## death scene and the return THROUGH STAGING. Debug-only and inert without the
## flag; it does not change a single frame of the shipped menu.
const AUTOSTART_DELAY := 2.5


func _ready():
	_configure_menu_rendering()

	for a in OS.get_cmdline_args():
		if String(a) == "--em-autostart":
			get_tree().create_timer(AUTOSTART_DELAY).timeout.connect(_on_new_game_clicked)
			break

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

# ── THE MUSEUM IS THE GAME NOW (2026-09-06) ─────────────────────────────────
# Palle: "since we are converting the game to the endless museum ... the new game
# means endless museum point one. Then all sequences are pointing to the endless
# museum version of the game."
#
# So this menu no longer has two destinations. New Game and every sequence card
# lead to the same building; what differs is only WHERE IN IT the walk opens.
const MUSEUM_SCENE := "res://commons/scenes/endless_museum_staged.tscn"
const MUSEUM_FALLBACK_SCENE := "res://commons/scenes/endless_museum.tscn"
## Point One's own chapter. It is the sequence field of its row in the plan, not
## a display name — endless_museum matches _first_chapter against exactly that.
const FIRST_CHAPTER := "primitives"
const FIRST_MAP := "Point_One"


## Open the museum at a chapter. `map` empty means that chapter's first pearl.
##
## The chapter is handed over BEFORE the load, through endless_museum.open_at:
## the staged scene ships start_chapter "primitives"/start_map "Point_One" in its
## own Inspector fields, so a sequence card that only loaded the scene would put
## every visitor in the lobby whatever they picked. See the note on menu_chapter
## for why this is a static and not the control file or staging's user_data.
func _enter_museum(chapter: String, map: String = "") -> void:
	MUSEUM.open_at(chapter, map)
	var staging := _find_staging()
	if staging == null:
		# The shipped loop always has one — the menu is instanced inside
		# vr_staging.tscn — so this is a dev boot of the menu on its own. Enter
		# the museum anyway rather than leaving a dead button: the plain scene
		# carries the same plan, and open_at outranks its Inspector fields too.
		push_warning("MainMenu: no XRToolsStaging ancestor — entering the museum without it")
		get_tree().change_scene_to_file(MUSEUM_FALLBACK_SCENE)
		return
	# the staging rig's pointers would fight the loaded scene's rig
	var left_pointer = find_child("FunctionPointerLeft", true, false)
	var right_pointer = find_child("FunctionPointerRight", true, false)
	if left_pointer: left_pointer.visible = false
	if right_pointer: right_pointer.visible = false
	staging.load_scene(MUSEUM_SCENE)


func _on_new_game_clicked():

	# Clear any existing checkpoints
	var checkpoint_manager = get_node_or_null("/root/CheckpointManager")
	if checkpoint_manager and checkpoint_manager.has_method("clear_checkpoints"):
		checkpoint_manager.clear_checkpoints()

	# Reset map progression
	var progression_manager = get_node_or_null("/root/MapProgressionManager")
	if progression_manager and progression_manager.has_method("reset_progress"):
		progression_manager.reset_progress()

	# start_game_requested is NOT emitted any more, and that is the whole change.
	# vrStaging._on_menu_start_game answers it by loading the LAB, so emitting it
	# and then entering the museum would be two scene loads racing each other for
	# the same staging slot. The signal is left declared — it is part of this
	# node's interface and capture_main_menu.gd and GameManager both name it —
	# but a new game is now one destination, not a request for whichever one the
	# staging happens to prefer.
	_enter_museum(FIRST_CHAPTER, FIRST_MAP)

func _on_load_game_clicked():
	# Load Game now opens the sequence picker — a 2D-in-3D panel listing
	# all spine sequences as info cards with Play buttons. Each card
	# loads that sequence's first map via SceneManager.start_sequence.
	# (The old behavior — resume from checkpoint OR start new game — was
	# broken when no checkpoint existed and gave the player no way to
	# pick a sequence. The picker fixes that.)
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

	# Close the picker
	if sequence_picker_instance:
		sequence_picker_instance.queue_free()
		sequence_picker_instance = null

	# The measurement corridor is a plain desktop scene (own camera, mouse
	# editing) — a straight scene change, not a staging load; F10 inside it
	# returns here. It is the ONE card that is not a room in the museum.
	if sequence_name == "prop_corridor":
		get_tree().change_scene_to_file("res://commons/scenes/prop_reference_wall.tscn")
		return

	# EVERY OTHER CARD IS A CHAPTER OF THE MUSEUM (2026-09-06). This used to fork:
	# "endless_museum" went to the building, and each spine sequence went to its
	# own first map through SceneManager.start_sequence — the grid lane, one map
	# at a time, returning to the lab at the end. Palle: "all sequences are
	# pointing to the endless museum version of the game."
	#
	# A sequence id IS a chapter: endless_museum matches _first_chapter against
	# the `sequence` field of the plan's rows, so the card's own name is already
	# the right word and nothing has to be translated. A card naming a sequence
	# the plan has no rows for is not an error here — the museum says so
	# ("first chapter X is not in the pool") and opens at its default.
	if sequence_name == "endless_museum":
		_enter_museum(FIRST_CHAPTER, FIRST_MAP)     # the card for the building itself
	else:
		_enter_museum(sequence_name)                 # ...at that chapter's first pearl

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
	quit_requested.emit()
	get_tree().quit()
