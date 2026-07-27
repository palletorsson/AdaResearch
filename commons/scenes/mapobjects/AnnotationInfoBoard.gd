# AnnotationInfoBoard.gd
# Uses the existing info board structure to display map name and description
# Automatically loads info from the GridDataComponent JSON

extends Node3D
class_name AnnotationInfoBoard

# @identity
# essence: the room reading its own paperwork aloud — a 1.2 x 1.6 m panel standing on the floor with nothing holding it up, filled at runtime from the map's own map_data.json and blurb.md: a serial number, a sequence position, the title, the blurb, a hashed barcode, and the player's XP and health tacked underneath.
# desire: to make a space able to say what it is without an author having to write anything twice — the caption is the metadata, so the caption can never drift from the map.
# critical_parameter: voice — whose institution is speaking, and therefore who is allowed to write on it (system | directory | noticeboard | flap | taped); carriage — how much building the institution puts behind that sentence (none | easel | case | pylon).
# triggers: _ready dresses the board from voice/carriage, then defers to the GridSystem; map_loaded refills the text; apply_grid_config({voice, carriage}).
# emerges: the same sentence changes authority with its surface — pinned to cork it reads as provisional and amendable, milled into a lit monolith it reads as the building's official position, taped up crooked it reads as one person's stopgap.
# needs: a GridSystem with a GridDataComponent to read map_info from; MapProgressionManager for the sequence index; GameManager for the XP and health line.
# relationships: the scene behind the 'an' utility (415 placements) and the 'info_board' artifact (247 placements) — the same board twice; captioned successor is [[wall_placard]], which drops the XP/health chrome; sibling to [[exhibit_furniture]]'s 'infoboard' kind, which is the furniture without the text.
# truth: a building's signage is a claim about who gets to amend it — the cork board invites a hand, the lit monolith forbids one, and the sentence on both is identical.

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27). This artifact is the reason the "visible
# in a still" rule exists: it was swept across all five exports of its script and
# produced six identical tiles. The sweep was not wrong about the exports — it was
# reading the WRONG FILE. See the LATENT BUGS note at the foot of this block.
#
# What the board actually was: an unshaded 600x800 SubViewport sprite, charcoal
# (0.12) with a 3 px red hairline, standing on the floor, with an empty
# MeshInstance3D called "Board" where a body should be. No frame, no post, no
# mount, no housing — the engine's own HUD, hung in a room and asked to pass for
# architecture. That is a look, and a very specific one: it is a debug readout.
#
# So the family gets the two axes the object already argued for:
#
#   voice     WHO MAY WRITE ON IT   system · directory · noticeboard · flap · taped
#   carriage  HOW MUCH BUILDING     none · easel · case · pylon
#
# `voice` repaints the board's own face (the StyleBoxFlat behind the labels and
# every label colour) and adds the two or three pieces of face furniture that make
# the register unmistakable — an aluminium header and a light slot for the lobby
# directory, four brass drawing pins for the cork board, a header rail and two
# flap seams for the departure board, four tape tabs and a 2.5-degree list for the
# sheet somebody printed at their desk. The field goes from 0.12 charcoal to 0.93
# near-white (directory) or 0.035 black with amber ink (flap): the largest read in
# the family, and it lands on every pixel of the panel.
#
# `carriage` is mass. Nothing, then a leaning easel with a picture ledge, then a
# glazed case with hinges and a lock, then a 1.92 x 2.20 m monolith with the panel
# sunk into a reveal. Read as a ladder it is personal, institutional, civic — how
# expensive it is to contradict what the board says.
#
# voice=system and carriage=none are the legacy lineage. Both are hard-guarded to
# return before touching anything: no theme override is added, no node is created,
# the Sprite3D's authored transform is never assigned. All 662 live instances
# (247 artifact placements + 415 'an' utility placements) are byte-identical.
#
# Everything new lives under ONE container child, deliberately: the placer's
# _auto_ground_artifact() walks only DIRECT MeshInstance3D children, and today
# this scene has none with a mesh, so grounding is a no-op. Putting the new
# geometry one level down keeps it a no-op for every variant, which means no axis
# can shift the board vertically by even a millimetre.
#
# What it cost: the board's look is no longer legible from the .tscn — a reader
# has to come here for the palette. And `voice` overrides label colours at
# runtime, so any future theme work on info_board.tscn will be silently overruled
# for four of the five values.
#
# Deliberately NOT routed through either axis: the Area3D and its CollisionShape3D
# (a trigger volume is not a look), the text content itself, and the barcode hash.
#
# LATENT BUGS FOUND, NOT FIXED — reported upward:
#   1. commons/scenes/mapobjects/info_board.gd is ORPHANED. Nothing in the repo
#      loads it (uid://bo7fb2yiasu40 appears in zero .tscn files). info_board.tscn
#      runs THIS script. Its five duration exports were the ones swept.
#   2. info_board.tscn:236-237 connect Area3D.body_entered/body_exited to
#      _on_area_entered/_on_area_exited — methods that exist only in the orphaned
#      info_board.gd, not here. Any body on collision layer 2 entering the trigger
#      raises "nonexistent function" at emit time.
#   3. info_board.tscn:218 "Board" is a MeshInstance3D with no mesh — it draws
#      nothing. Left alone; the new carriage geometry does not reuse it.
#   4. @export animate_text (line ~21 below) is set true by the .tscn and read by
#      nothing. set_animation_enabled() writes it and nothing reads that either.
# ─────────────────────────────────────────────────────────────────────────────

# References to UI elements
@onready var level_number_label = $Viewport/InfoBoardUI/MainPanel/LevelNumber
@onready var level_id_label = $Viewport/InfoBoardUI/MainPanel/LevelID
@onready var title_label = $Viewport/InfoBoardUI/MainPanel/Title
@onready var summary_label = $Viewport/InfoBoardUI/MainPanel/Summary
@onready var barcode = $Viewport/InfoBoardUI/MainPanel/Barcode
@onready var xp_label = $Viewport/InfoBoardUI/MainPanel/XPLabel
@onready var health_label = $Viewport/InfoBoardUI/MainPanel/HealthLabel

# Configuration
@export var auto_update_on_map_load: bool = true
@export var show_level_number: bool = true
@export var show_metadata: bool = true
@export var animate_text: bool = false

## AXIS 1 — whose institution is speaking, and therefore who is allowed to write
## on the board. Repaints the panel field, every label colour, and adds the face
## furniture that names the register.
##   system      (legacy default) charcoal slab, red hairline, white text — the HUD
##   directory   near-white backlit field, aluminium header + light slot, dark ink
##   noticeboard cork-tan field, dark ink, four brass drawing pins
##   flap        black field, amber ink, header rail + two split-flap seams
##   taped       paper-white field, black ink, four tape tabs, listing 2.5 degrees
@export var voice: String = "system"

## AXIS 2 — how much building the institution puts behind the sentence.
##   none   (legacy default) the panel stands on the floor, nothing holds it
##   easel  the board leans back 11 degrees on splayed legs with a picture ledge
##   case   a glazed bezel with hinges, a lock and a weather pediment
##   pylon  a 1.92 x 2.20 m monolith with the panel sunk into a reveal
@export var carriage: String = "none"

# ── the two axes' data ───────────────────────────────────────────────────────

# Panel geometry, in ROOT-LOCAL units. The root's authored transform bakes in a
# 0.2 scale and a 180-degree yaw, so 1 local unit = 0.2 m of world. The Sprite3D
# is 600x800 px at the default pixel_size of 0.01 → 6.0 x 8.0 local = 1.2 x 1.6 m.
# Read from the .tscn; changing either there means changing them here.
const SPRITE_Y := 4.02246                  # authored Sprite3D local Y
const PANEL_HW := 3.0                      # half width
const PANEL_HH := 4.0                      # half height
const PANEL_BOT := SPRITE_Y - PANEL_HH     # 0.02246 — the board is already on the floor
const PANEL_TOP := SPRITE_Y + PANEL_HH
const DNA_NODE := "InfoBoardDNA"

# Every surface either axis can reach, keyed by voice. `field` and the ink colours
# dress the SubViewport UI; `body` / `trim` / `glass` dress the carriage. The
# "system" entry exists only so a carriage built under the legacy voice has
# somewhere to get its charcoal from — with carriage:none nothing reads it.
const VOICES := {
	# The legacy lineage. These numbers are lifted from info_board.tscn's
	# StyleBoxFlat_yc54e and the label defaults; they are never APPLIED (the
	# guard in _dress_face returns first) — they are here as the record of what
	# the board was, and as the palette for a carriage under the legacy voice.
	"system": {
		"field": Color(0.12, 0.12, 0.12), "border_w": 3, "border_c": Color(0.8, 0.0, 0.0),
		"ink": Color(1, 1, 1), "dim": Color(0.72, 0.72, 0.74),
		"accent": Color(0.9137757, 0.5173696, 1.0), "sep": Color(0.5, 0.5, 0.5),
		"body": {"c": Color(0.16, 0.16, 0.17), "r": 0.55},
		"trim": {"c": Color(0.55, 0.06, 0.06), "r": 0.45, "e": 0.7},
		"glass": {"c": Color(0.60, 0.75, 0.85, 0.14), "r": 0.05},
		"face": "",
	},
	# The lobby directory: a lit sheet of white behind a brushed frame. Nobody
	# writes on this without a work order. The field inverts 0.12 → 0.93, which
	# is the single loudest change in the family.
	"directory": {
		"field": Color(0.93, 0.94, 0.96), "border_w": 2, "border_c": Color(0.62, 0.65, 0.70),
		"ink": Color(0.07, 0.08, 0.10), "dim": Color(0.30, 0.32, 0.36),
		"accent": Color(0.03, 0.35, 0.62), "sep": Color(0.72, 0.74, 0.78),
		"body": {"c": Color(0.66, 0.68, 0.71), "r": 0.22, "m": 0.85},
		"trim": {"c": Color(0.88, 0.92, 0.97), "r": 0.15, "m": 0.5, "e": 0.9},
		"glass": {"c": Color(0.88, 0.94, 1.00, 0.10), "r": 0.02},
		"face": "header",
	},
	# The cork board by the lift. Anyone with a pin may add to it, and everyone
	# knows it, which is why nothing on it is ever quite current.
	"noticeboard": {
		"field": Color(0.62, 0.44, 0.26), "border_w": 0, "border_c": Color(0.36, 0.22, 0.11),
		"ink": Color(0.12, 0.09, 0.06), "dim": Color(0.27, 0.20, 0.14),
		"accent": Color(0.45, 0.11, 0.08), "sep": Color(0.44, 0.31, 0.18),
		"body": {"c": Color(0.36, 0.22, 0.11), "r": 0.72},
		"trim": {"c": Color(0.52, 0.34, 0.17), "r": 0.65},
		"glass": {"c": Color(0.82, 0.86, 0.80, 0.13), "r": 0.12},
		"face": "pins",
	},
	# The departure board. Only the timetable writes here, and it writes by
	# machinery. Static slats only — a flap that flips is invisible to a still.
	"flap": {
		"field": Color(0.035, 0.035, 0.045), "border_w": 0, "border_c": Color(0.07, 0.07, 0.08),
		"ink": Color(1.00, 0.72, 0.15), "dim": Color(0.84, 0.59, 0.12),
		"accent": Color(0.98, 0.80, 0.28), "sep": Color(0.22, 0.17, 0.06),
		"body": {"c": Color(0.07, 0.07, 0.08), "r": 0.45},
		"trim": {"c": Color(1.00, 0.68, 0.12), "r": 0.35, "e": 1.1},
		"glass": {"c": Color(0.20, 0.20, 0.22, 0.18), "r": 0.06},
		"face": "seams",
	},
	# A4, printed at somebody's desk, taped up crooked. The most amendable
	# surface in the set and the only one whose author is a person.
	"taped": {
		"field": Color(0.95, 0.94, 0.90), "border_w": 0, "border_c": Color(0.80, 0.79, 0.76),
		"ink": Color(0.06, 0.06, 0.07), "dim": Color(0.32, 0.32, 0.32),
		"accent": Color(0.55, 0.10, 0.10), "sep": Color(0.62, 0.61, 0.58),
		"body": {"c": Color(0.80, 0.79, 0.76), "r": 0.85},
		"trim": {"c": Color(0.92, 0.90, 0.84), "r": 0.60},
		"glass": {"c": Color(0.90, 0.90, 0.88, 0.10), "r": 0.30},
		"face": "tape",
	},
}

# How far the sheet leans/lists per axis value. Both are 0.0 on the legacy path,
# so the Sprite3D's authored transform is never written.
const LEAN_DEG := {"easel": -11.0}
const LIST_DEG := {"taped": 2.5}

var _dressed_as: String = ""               # "<voice>|<carriage>" actually built

# Current map info
var current_map_name: String = ""
var current_lookup_name: String = ""
var current_map_id: String = ""
var current_description: String = ""
var current_metadata: Dictionary = {}

# Sequence parameter support
var sequence_name: String = ""
var sequence_data: Dictionary = {}

func _ready():
	# DNA first: the placer sets config_* metadata BEFORE add_child (see
	# GridInteractablesComponent._apply_artifact_config), so the axes are already
	# readable here. Done ahead of the GameManager hookups so a missing autoload
	# cannot skip the dressing.
	_read_dna_meta()
	_dress()

	print("----------------------------------------------------------------------")
	print("AnnotationInfoBoard: Initializing map info display board")

	# Connect to GameManager for XP updates if available
	if GameManager and GameManager.has_signal("score_updated"):
		GameManager.score_updated.connect(_update_xp_display)
		_update_xp_display(GameManager.get_score())
	
	# Connect to GameManager for Health updates if available
	if GameManager and GameManager.has_signal("health_updated"):
		GameManager.health_updated.connect(_on_health_updated_signal)

	
	# Delay initialization to allow utilities to be placed first
	call_deferred("_delayed_initialization")

func _delayed_initialization():
	"""Delayed initialization to ensure utilities are placed first"""
	# This runs via call_deferred from _ready, by which point the node may
	# already have been removed from the tree (e.g. a parent that rebuilds
	# its children, like lab_room's apply_grid_config). get_tree() is null on
	# a detached node, so bail out instead of crashing on .process_frame.
	if not is_inside_tree():
		return
	print("AnnotationInfoBoard: Starting delayed initialization...")

	# Wait additional frames to ensure grid utilities are fully loaded.
	# Re-check after each await — the node can be freed/detached mid-wait.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return

	# Check for sequence parameter from utility placement
	_check_for_sequence_parameter()
	
	# Connect to grid system for map data
	_connect_to_grid_system()

func _check_for_sequence_parameter():
	"""Check if a sequence parameter was provided via utility placement"""
	if "sequence_name" in self:
		sequence_name = self.sequence_name
		print("AnnotationInfoBoard: Using sequence from property: " + sequence_name)
	elif has_meta("sequence_name"):
		sequence_name = get_meta("sequence_name")
		print("AnnotationInfoBoard: Using sequence from metadata: " + sequence_name)
	
	if not sequence_name.is_empty():
		print("AnnotationInfoBoard: Will load sequence data for: " + sequence_name)
		_load_sequence_data()

func _load_sequence_data():
	"""Load sequence data from MapProgressionManager"""
	# Use the global manager if available
	if not MapProgressionManager:
		print("AnnotationInfoBoard: MapProgressionManager not found")
		return

	# Access sequences directly from manager
	var sequences = MapProgressionManager.sequences
	
	# Find the specific sequence
	if sequences.has(sequence_name):
		var sequence = sequences[sequence_name]
		sequence_data = sequence.duplicate(true)  # Deep copy to preserve array types
		sequence_data["sequence_name"] = sequence_name
		
		# Ensure maps array is properly typed and accessible
		if sequence.has("maps"):
			var maps_array = sequence["maps"]
			# Convert to Array[String] if needed to ensure type consistency
			var typed_maps: Array[String] = []
			for map_id in maps_array:
				typed_maps.append(str(map_id).strip_edges())  # Strip whitespace
			sequence_data["maps"] = typed_maps
			print("AnnotationInfoBoard: Loaded %d maps from sequence: %s" % [typed_maps.size(), typed_maps])
		else:
			sequence_data["maps"] = []
		
		# Map index will be calculated in _update_info_board based on current map
		sequence_data["map_index"] = 0 
		sequence_data["total_maps"] = sequence_data["maps"].size()
		print("AnnotationInfoBoard: ✅ Loaded sequence data for: " + sequence_name)
		
		# Also load current map info so we can display both sequence and map details
		_load_current_map_info_for_display()
		
		# Update the info board immediately with sequence data
		_update_info_board()
	else:
		print("AnnotationInfoBoard: ❌ Sequence '" + sequence_name + "' not found")
		print("AnnotationInfoBoard: Available sequences: " + str(sequences.keys()))

func _load_current_map_info_for_display():
	"""Load current map info for display purposes (without updating the board)"""
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if not grid_system:
		grid_system = _find_node_by_class(get_tree().current_scene, "GridSystem")

	if grid_system:
		var data_component = grid_system.get_data_component()
		if data_component:
			# Get map_info section directly from JSON
			if data_component.json_loader and data_component.json_loader.map_data:
				var map_info = data_component.json_loader.map_data.get("map_info", {})
				current_map_name = map_info.get("name", "Unknown Map")
				current_lookup_name = map_info.get("lookup_name", "")
				current_metadata = map_info.get("metadata", {})

				# Try to load blurb.md first, fall back to description
				current_description = _load_blurb_or_description(current_map_name, map_info.get("description", "No description available"))

				print("AnnotationInfoBoard: Loaded current map info for display - Name: '%s'" % current_map_name)
			else:
				# Fallback to metadata method
				var metadata = data_component.get_map_metadata()
				current_map_name = metadata.get("name", "Unknown Map")
				current_lookup_name = metadata.get("lookup_name", "")
				current_metadata = metadata

				# Try to load blurb.md first, fall back to description
				current_description = _load_blurb_or_description(current_map_name, metadata.get("description", "No description available"))
				print("AnnotationInfoBoard: Loaded current map info from metadata fallback")
		else:
			print("AnnotationInfoBoard: No data component found for map info display")

func _connect_to_grid_system():
	"""Connect to grid system to get map data"""
	call_deferred("_find_grid_system")

func _find_grid_system():
	"""Find and connect to the grid system"""
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if not grid_system:
		grid_system = _find_node_by_class(get_tree().current_scene, "GridSystem")
	
	if grid_system:
		# Connect to map loaded signal
		if grid_system.has_signal("map_loaded") and not grid_system.map_loaded.is_connected(_on_map_loaded):
			grid_system.map_loaded.connect(_on_map_loaded)
			print("AnnotationInfoBoard: Connected to GridSystem.map_loaded")
		
		# Get current map info
		_load_current_map_info(grid_system)
	else:
		print("AnnotationInfoBoard: WARNING - Could not find GridSystem")

func _find_node_by_class(node: Node, target_class_name: String) -> Node:
	"""Find node by class name"""
	if node.get_script() and node.get_script().get_global_name() == target_class_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_class(child, target_class_name)
		if result:
			return result
	
	return null

func _on_map_loaded(map_name: String, format: String):
	"""Handle when a new map is loaded"""
	print("AnnotationInfoBoard: Map loaded - %s (%s)" % [map_name, format])
	
	# Find grid system to get data
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if grid_system:
		grid_system_ref = grid_system # Cache it
		_load_current_map_info(grid_system)

var grid_system_ref: Node # Cache for ID lookup

func _load_current_map_info(grid_system):
	"""Load map info from grid system data component"""
	var data_component = grid_system.get_data_component()
	if not data_component:
		print("AnnotationInfoBoard: No data component found")
		return

	# Get map_info section directly from JSON
	if data_component.json_loader and data_component.json_loader.map_data:
		var map_info = data_component.json_loader.map_data.get("map_info", {})
		current_map_name = map_info.get("name", "Unknown Map")
		current_lookup_name = map_info.get("lookup_name", "")
		current_metadata = map_info.get("metadata", {})

		# Try to load blurb.md first, fall back to description
		current_description = _load_blurb_or_description(current_map_name, map_info.get("description", "No description available"))

		print("AnnotationInfoBoard: Loaded from map_info - Name: '%s'" % current_map_name)
		print("AnnotationInfoBoard: Description: '%s'" % current_description)
	else:
		# Fallback to metadata method
		var metadata = data_component.get_map_metadata()
		current_map_name = metadata.get("name", "Unknown Map")
		current_lookup_name = metadata.get("lookup_name", "")
		current_metadata = metadata

		# Try to load blurb.md first, fall back to description
		current_description = _load_blurb_or_description(current_map_name, metadata.get("description", "No description available"))
		print("AnnotationInfoBoard: Loaded from metadata fallback")

	# Update the info board display
	_update_info_board()

func _update_info_board():
	"""Update the info board with current map information"""
	print("DEBUG INFOBOARD: Current Map: '%s'" % current_map_name)
	
	# ALWAYS try to determine the true Map ID (filename)
	var check_id = MapProgressionManager.current_map if MapProgressionManager else ""
	
	if check_id.is_empty() and grid_system_ref: 
		# Try to get from grid system if manager is empty (e.g. direct scene load)
		var gs_map_name = grid_system_ref.get("map_name")
		if gs_map_name:
			check_id = gs_map_name
			print("AnnotationInfoBoard: Got ID '%s' from GridSystem.map_name" % check_id)
		elif "current_map_name" in grid_system_ref:
			check_id = grid_system_ref.current_map_name
			print("AnnotationInfoBoard: Got ID '%s' from GridSystem.current_map_name" % check_id)
		
		# If GridSystem property failed, try DataComponent (MOST RELIABLE)
		if check_id.is_empty():
			var data_comp = grid_system_ref.get_data_component()
			if data_comp and data_comp.has_method("get_current_map_name"):
				var dc_name = data_comp.get_current_map_name()
				if not dc_name.is_empty():
					check_id = dc_name
					print("AnnotationInfoBoard: Got ID '%s' from GridDataComponent.get_current_map_name()" % check_id)
	
	# Fallback: Get from scene filename
	if check_id.is_empty():
		var scene_path = get_tree().current_scene.scene_file_path
		if not scene_path.is_empty():
			check_id = scene_path.get_file().get_basename()
			print("AnnotationInfoBoard: Extracted ID '%s' from scene path" % check_id)
			
	if not check_id.is_empty():
		current_map_id = str(check_id).strip_edges() # Store valid ID for index lookup (normalized)
		print("AnnotationInfoBoard: Stored normalized map ID: '%s'" % current_map_id)
	
	# 1. Primary Check: current_map_id
	var candidates = []
	if not current_map_id.is_empty():
		candidates.append(current_map_id)
		# candidates.append(str(current_map_id).strip_edges()) # Duplicate if normalized above

	# 2. Secondary Check: Lookup Name (Explicit Override)
	if not current_lookup_name.is_empty():
		candidates.append(current_lookup_name)
		print("AnnotationInfoBoard: Added lookup_name candidate: '%s'" % current_lookup_name)

	
	# 2. Secondary Check: Display Name -> ID conversion (Point Zero -> Point_Zero)
	if not current_map_name.is_empty():
		var underscores = current_map_name.replace(" ", "_")
		candidates.append(underscores)
		# Also try stripping edges from name
		candidates.append(current_map_name.strip_edges())

	if sequence_data.is_empty() and MapProgressionManager:
		for cand in candidates:
			if cand.is_empty(): continue
			
			for seq_id in MapProgressionManager.sequences:
				var seq = MapProgressionManager.sequences[seq_id]
				if seq.has("maps"):
					if cand in seq.maps:
						sequence_name = seq_id
						current_map_id = cand # Update to the working ID
						_load_sequence_data()
						break
			if not sequence_data.is_empty():
				break

	# Use sequence data if available, otherwise fall back to map data
	if not sequence_data.is_empty():
		_update_info_board_with_sequence_data()
	else:
		_update_info_board_with_map_data()

func _update_info_board_with_sequence_data():
	"""Update info board using sequence data from MapProgressionManager"""
	var sequence_name = sequence_data.get("sequence_name", "Unknown")
	
	# Calculate correct map index based on current map ID
	var map_index = 0
	if sequence_data.has("maps"):
		var maps = sequence_data["maps"]
		var found = maps.find(current_map_id)
		
		# If exact ID not found, try the fallback candidates again within the known sequence
		if found == -1:
			var candidates = []
			if not current_lookup_name.is_empty():
				candidates.append(current_lookup_name)
			candidates.append(current_map_name.replace(" ", "_"))
			candidates.append(current_map_name)
			
			for cand in candidates:
				found = maps.find(cand)
				if found != -1:
					print("AnnotationInfoBoard: Found map ID '%s' at index %d via fallback search" % [cand, found])
					break
		
		if found != -1:
			map_index = found
			
	var total_maps = sequence_data.get("total_maps", 1)
	
	# Update level number (show progress in sequence)
	# Use 1-based indexing for human readability (01, 02, 03...)
	var display_index = map_index + 1
	if show_level_number:
		level_number_label.text = "%02d" % display_index
	else:
		level_number_label.text = str(display_index)

	# Update level ID (sequence/progress format + current map name)
	var level_id_text = "%s/%02d of %d" % [sequence_name, display_index, total_maps]
	if not current_map_name.is_empty():
		level_id_text += " - %s" % current_map_name
	level_id_label.text = level_id_text
	
	# Update title (use map name only)
	if not current_map_name.is_empty():
		title_label.text = current_map_name
	else:
		title_label.text = sequence_data.get("name", "Unknown Sequence")
	
	# Update summary (prioritize current map info, no prefixes)
	if not current_description.is_empty():
		summary_label.text = current_description
	else:
		# Fallback to sequence description only if map has no description
		summary_label.text = sequence_data.get("description", "No description available")
	
	# Update barcode (decorative) - use combination of sequence and map name
	var barcode_text = sequence_name
	if not current_map_name.is_empty():
		barcode_text += "_" + current_map_name
	barcode.text = _generate_barcode_pattern(barcode_text)
	
	# Update health to show completion status
	_update_completion_status()

func _update_info_board_with_map_data():
	"""Update info board using map data from map_data.json"""
	# Extract level number from map name if possible
	var level_number = _extract_level_number(current_map_name)
	
	# Update level number
	if show_level_number:
		level_number_label.text = "%02d" % level_number
	else:
		level_number_label.text = str(level_number)
	
	# Update level ID (category/name format)
	var category = _get_map_category(current_map_name)
	level_id_label.text = "%s/%s" % [category, current_map_name]
	
	# Update title (use map name)
	title_label.text = current_map_name
	
	# Update summary (use description + metadata if available)
	var summary_text = current_description
	if show_metadata and not current_metadata.is_empty():
		summary_text += _format_metadata_summary()
	
	summary_label.text = summary_text
	
	# Update barcode (decorative)
	barcode.text = _generate_barcode_pattern(current_map_name)
	
	# Update health to show completion status
	_update_completion_status()

func _extract_level_number(map_name: String) -> int:
	"""Extract level number from map name"""
	# Try to find numbers in the map name
	var regex = RegEx.new()
	regex.compile("\\d+")
	var result = regex.search(map_name)
	
	if result:
		return int(result.get_string())
	
	return -1

func _get_map_category(map_name: String) -> String:
	"""Get category based on map name"""
	if map_name.begins_with("Tutorial"):
		return "tutorial"
	elif map_name.begins_with("Lab"):
		return "lab"
	elif map_name.begins_with("Algorithm"):
		return "algorithm"
	else:
		return "map"

func _format_metadata_summary() -> String:
	"""Format metadata into readable summary"""
	var metadata_text = ""

	
	# User requested to hide difficulty, time, and objectives
	# Keeping function structure in case other metadata needs to be added later
	
	return metadata_text

func _generate_barcode_pattern(map_name: String) -> String:
	"""Generate decorative barcode based on map name"""
	var pattern = ""
	var hash_val = map_name.hash()
	
	for i in range(32):
		if (hash_val >> i) & 1:
			pattern += "█"
		else:
			pattern += "▌"
	
	return pattern

func _update_completion_status():
	"""Update health label to show completion status"""
	# Show actual health if available, or default to 100%
	var health_val = 100
	if is_instance_valid(GameManager) and "player_health" in GameManager:
		health_val = GameManager.player_health
	
	health_label.text = "Health: %d%%" % health_val

func _on_health_updated_signal(_new_health: float):
	"""Signal handler for health updates"""
	_update_completion_status()


func _update_xp_display(new_score: int):
	"""Update XP display from GameManager"""
	if xp_label:
		xp_label.text = "XP: %d" % new_score

func _load_blurb_or_description(map_name: String, fallback_description: String) -> String:
	"""Load blurb.md content if it exists, otherwise return the fallback description"""
	if map_name.is_empty():
		return fallback_description

	# Try multiple path candidates:
	# 1. lookup_name (folder name, e.g., "Point_One")
	# 2. map_name with spaces replaced by underscores
	# 3. map_name as-is (unlikely but try anyway)
	var path_candidates: Array[String] = []

	if not current_lookup_name.is_empty():
		path_candidates.append(current_lookup_name)

	var underscored_name = map_name.replace(" ", "_")
	if underscored_name != current_lookup_name:
		path_candidates.append(underscored_name)

	if map_name != underscored_name and map_name != current_lookup_name:
		path_candidates.append(map_name)

	for candidate in path_candidates:
		var blurb_path = "res://commons/maps/%s/blurb.md" % candidate
		print("AnnotationInfoBoard: Trying blurb path: %s" % blurb_path)
		if FileAccess.file_exists(blurb_path):
			var file = FileAccess.open(blurb_path, FileAccess.READ)
			if file:
				var content = file.get_as_text().strip_edges()
				file.close()
				if not content.is_empty():
					print("AnnotationInfoBoard: ✅ Loaded blurb.md from '%s'" % blurb_path)
					return content

	print("AnnotationInfoBoard: No blurb.md found, using JSON description")
	return fallback_description

# Public API
func force_update():
	"""Force update the display"""
	_find_grid_system()

func set_animation_enabled(enabled: bool):
	"""Enable/disable text animation"""
	animate_text = enabled

func set_metadata_display(enabled: bool):
	"""Enable/disable metadata display"""
	show_metadata = enabled
	_update_info_board()

func get_current_info() -> Dictionary:
	"""Get current map information"""
	return {
		"name": current_map_name,
		"description": current_description,
		"metadata": current_metadata
	}

# ═════════════════════════════════════════════════════════════════════════════
# DNA — voice (who may write on it) x carriage (how much building behind it)
# ═════════════════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_dna_meta()
	_dress()

func _read_dna_meta() -> void:
	if has_meta("config_voice"):
		voice = str(get_meta("config_voice"))
	if has_meta("config_carriage"):
		carriage = str(get_meta("config_carriage"))

# THE LEGACY GUARD. voice=system + carriage=none returns before touching a single
# node: no theme override, no child, no transform write. That is the path all 662
# existing instances take.
func _dress() -> void:
	var want: String = "%s|%s" % [voice, carriage]
	if want == _dressed_as:
		return
	if voice == "system" and carriage == "none":
		_dressed_as = want
		return
	var old: Node = get_node_or_null(DNA_NODE)
	if old:
		old.free()
	var holder := Node3D.new()
	holder.name = DNA_NODE
	add_child(holder)
	# The sheet's plane: the easel's lean composed with the taped sheet's list.
	# Applied here rather than inside _dress_face so that carriage:easel leans the
	# board even under the legacy voice, which returns early from the face pass.
	var xf: Transform3D = _sheet_xform()
	if xf != Transform3D.IDENTITY:
		var sprite: Node = get_node_or_null("Sprite3D")
		if sprite and sprite is Node3D:
			(sprite as Node3D).transform = xf * Transform3D(Basis.IDENTITY, Vector3(0, SPRITE_Y, 0))
	var face := Node3D.new()
	face.name = "Face"
	face.transform = xf
	holder.add_child(face)
	_dress_face(face)
	_build_carriage(holder)
	_dressed_as = want

# ── the sheet's own plane ────────────────────────────────────────────────────

# Rotation about `pivot` — used so the lean tips the board about its bottom edge
# (which stays planted on the floor) rather than about the sprite's centre.
func _about(pivot: Vector3, b: Basis) -> Transform3D:
	return Transform3D(b, pivot - b * pivot)

# lean (easel) composed with list (taped). Identity on every other combination,
# and _dress_face/_build_carriage only assign the Sprite3D transform when this is
# NOT identity — so the authored transform survives untouched by default.
func _sheet_xform() -> Transform3D:
	var lean: float = float(LEAN_DEG.get(carriage, 0.0))
	var list: float = float(LIST_DEG.get(voice, 0.0))
	var t := Transform3D.IDENTITY
	if lean != 0.0:
		t = _about(Vector3(0, PANEL_BOT, 0), Basis(Vector3.RIGHT, deg_to_rad(lean)))
	if list != 0.0:
		t = t * _about(Vector3(0, SPRITE_Y, 0), Basis(Vector3.BACK, deg_to_rad(list)))
	return t

# ── voice: the face ──────────────────────────────────────────────────────────

func _pal() -> Dictionary:
	var p: Dictionary = VOICES.get(voice, VOICES["system"])
	return p

func _col(slot: String, fallback: Color) -> Color:
	var v: Variant = _pal().get(slot, fallback)
	if v is Color:
		var c: Color = v
		return c
	return fallback

func _label_color(path: String, c: Color) -> void:
	var n: Node = get_node_or_null(path)
	if n and n is Label:
		(n as Label).add_theme_color_override("font_color", c)

func _dress_face(face: Node3D) -> void:
	if voice == "system":
		return                                    # the legacy lineage keeps its charcoal

	# Repaint the field the labels sit on. A fresh StyleBoxFlat rather than an
	# edit of the .tscn's sub-resource: the sub-resource is shared by every
	# instance in the scene tree, so mutating it would leak across placements.
	var panel: Node = get_node_or_null("Viewport/InfoBoardUI/MainPanel")
	if panel and panel is Panel:
		var sb := StyleBoxFlat.new()
		sb.bg_color = _col("field", Color(0.12, 0.12, 0.12))
		var bw: int = int(_pal().get("border_w", 0))
		sb.border_width_left = bw
		sb.border_width_top = bw
		sb.border_width_right = bw
		sb.border_width_bottom = bw
		sb.border_color = _col("border_c", Color(0.8, 0, 0))
		sb.corner_radius_top_left = 2
		sb.corner_radius_top_right = 2
		sb.corner_radius_bottom_right = 2
		sb.corner_radius_bottom_left = 2
		(panel as Panel).add_theme_stylebox_override("panel", sb)

	var ink: Color = _col("ink", Color.WHITE)
	var dim: Color = _col("dim", Color(0.72, 0.72, 0.74))
	var base := "Viewport/InfoBoardUI/MainPanel/"
	_label_color(base + "LevelNumber", ink)
	_label_color(base + "Title", ink)
	_label_color(base + "Summary", ink)
	_label_color(base + "LevelID", dim)
	_label_color(base + "Barcode", dim)
	_label_color(base + "XPLabel", dim)
	_label_color(base + "HealthLabel", dim)
	_label_color(base + "Aperture", dim)
	_label_color(base + "ContextHint", _col("accent", Color(0.91, 0.52, 1.0)))
	var sep: Node = get_node_or_null(base + "Separator")
	if sep and sep is ColorRect:
		(sep as ColorRect).color = _col("sep", Color(0.5, 0.5, 0.5))

	# `face` already carries the sheet's plane (set in _dress), so the furniture
	# stays coplanar when the easel leans or the taped sheet lists.
	match str(_pal().get("face", "")):
		"header":
			_face_header(face)
		"pins":
			_face_pins(face)
		"seams":
			_face_seams(face)
		"tape":
			_face_tape(face)

# DIRECTORY. A brushed header capping the board, a lit slot under it, and two
# stiles standing just outside the panel edge. All of it clears the text: the
# header covers the top 0.47 local, where the .tscn leaves 60 px of dead margin.
func _face_header(face: Node3D) -> void:
	var alu: StandardMaterial3D = _vm("body")
	var lit: StandardMaterial3D = _vm("trim")
	_vbox(face, Vector3(6.9, 0.62, 0.36), Vector3(0, PANEL_TOP - 0.24, 0.18), alu)
	_vbox(face, Vector3(5.8, 0.10, 0.10), Vector3(0, PANEL_TOP - 0.60, 0.22), lit)
	for sx in [-1.0, 1.0]:
		_vbox(face, Vector3(0.30, PANEL_TOP + 0.10, 0.30),
				Vector3(sx * 3.15, (PANEL_TOP + 0.10) * 0.5, 0.10), alu)
	# No kick rail: the .tscn runs the ContextHint line to within 5 px of the
	# panel's bottom edge, so anything sitting proud down there eats "Press (X)
	# for Context". The stiles carry the frame instead.

# NOTICEBOARD. Four brass drawing pins at the corners of the cork, seated in the
# margins the .tscn leaves outside its 500 px label boxes. No paper slips: they
# would land on the blurb, and a caption you cannot read is not a variant.
func _face_pins(face: Node3D) -> void:
	var brass := _mat3(Color(0.78, 0.60, 0.24), 0.28, 0.0, 0.85)
	var shaft := _mat3(Color(0.55, 0.42, 0.18), 0.4, 0.0, 0.7)
	for sx in [-1.0, 1.0]:
		for py in [0.55, 7.50]:
			var head := SphereMesh.new()
			head.radius = 0.13
			head.height = 0.20
			var mi := MeshInstance3D.new()
			mi.mesh = head
			mi.material_override = brass
			mi.position = Vector3(sx * 2.62, py, 0.13)
			face.add_child(mi)
			_vbox(face, Vector3(0.07, 0.07, 0.13), Vector3(sx * 2.62, py, 0.05), shaft)

# FLAP. A header rail and two seams: one through the waist of the giant "01"
# (which is what a split-flap does to a glyph) and one on the separator row.
# Deliberately static — the flip is a per-second event and invisible to a still.
func _face_seams(face: Node3D) -> void:
	var black: StandardMaterial3D = _vm("body")
	var amber: StandardMaterial3D = _vm("trim")
	_vbox(face, Vector3(6.9, 0.62, 0.34), Vector3(0, PANEL_TOP - 0.29, 0.17), black)
	_vbox(face, Vector3(5.9, 0.09, 0.09), Vector3(0, PANEL_TOP - 0.66, 0.21), amber)
	for sy in [6.57, 5.31]:
		_vbox(face, Vector3(6.0, 0.05, 0.05), Vector3(0, sy, 0.05), black)
		_vbox(face, Vector3(6.0, 0.014, 0.055), Vector3(0, sy + 0.033, 0.055), amber)
	for sx in [-1.0, 1.0]:
		_vbox(face, Vector3(0.22, PANEL_TOP, 0.22), Vector3(sx * 3.11, PANEL_TOP * 0.5, 0.08), black)

# TAPED. Four tabs at 45 degrees over the sheet corners. The 2.5-degree list that
# sells it comes from _sheet_xform(), which has already been applied to `face`.
func _face_tape(face: Node3D) -> void:
	var tape := _mat3(Color(0.86, 0.85, 0.79, 0.72), 0.55, 0.0, 0.0)
	var i := 0
	for sx in [-1.0, 1.0]:
		for py in [0.45, 7.60]:
			var q := QuadMesh.new()
			q.size = Vector2(0.95, 0.36)
			var mi := MeshInstance3D.new()
			mi.mesh = q
			mi.material_override = tape
			mi.position = Vector3(sx * 2.78, py, 0.07)
			mi.rotation_degrees = Vector3(0, 0, 45.0 if i % 2 == 0 else -45.0)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			face.add_child(mi)
			i += 1

# ── carriage: the body ───────────────────────────────────────────────────────

func _build_carriage(holder: Node3D) -> void:
	match carriage:
		"easel":
			_carriage_easel(holder)
		"case":
			_carriage_case(holder)
		"pylon":
			_carriage_pylon(holder)
		_:
			pass                                  # "none" — the legacy lineage

# EASEL. The board leans back 11 degrees (applied in _dress_face via the shared
# sheet transform) onto two splayed legs and a rear strut, with a picture ledge
# under the front edge. The lean is what carries the read: a 1.2 x 1.6 m bright
# rectangle tipping 0.31 m back changes the silhouette everywhere.
func _carriage_easel(holder: Node3D) -> void:
	var wood: StandardMaterial3D = _vm("body")
	var trim: StandardMaterial3D = _vm("trim")
	var lean := Node3D.new()
	lean.name = "Lean"
	holder.add_child(lean)
	var lean_deg: float = float(LEAN_DEG.get("easel", -11.0))
	lean.transform = _about(Vector3(0, PANEL_BOT, 0), Basis(Vector3.RIGHT, deg_to_rad(lean_deg)))
	# Uprights running the panel plane, splayed out beyond the sheet. They stop
	# 0.30 short at the bottom: the 11-degree lean swings their rear corner down,
	# and starting them at 0 would sink them ~1.8 cm through the floor.
	for sx in [-1.0, 1.0]:
		var up := _vbox(lean, Vector3(0.34, 9.10, 0.34), Vector3(sx * 3.22, 4.85, -0.30), wood)
		up.rotation_degrees = Vector3(0, 0, sx * -3.0)
	_vbox(lean, Vector3(7.1, 0.30, 0.30), Vector3(0, 7.30, -0.30), wood)        # top rail
	# picture ledge — the shelf the sheet actually rests on
	_vbox(lean, Vector3(7.1, 0.34, 0.34), Vector3(0, 0.40, 0.02), wood)
	_vbox(lean, Vector3(7.1, 0.12, 0.62), Vector3(0, 0.55, 0.30), trim)
	# Rear strut + feet, in the UNLEANED frame so they meet the floor square. The
	# strut tips 11.6 degrees the OTHER way, so its foot lands 0.64 m behind the
	# sheet's own foot — the splay that stops an easel folding shut.
	_vbox(holder, Vector3(0.32, 0.30, 3.7), Vector3(0, 0.15, -1.65), wood)
	var strut := _vbox(holder, Vector3(0.30, 8.5, 0.30), Vector3(0, 4.20, -2.35), wood)
	strut.rotation_degrees = Vector3(11.6, 0, 0)
	for sx in [-1.0, 1.0]:
		_vbox(holder, Vector3(0.90, 0.26, 2.6), Vector3(sx * 3.05, 0.13, 0.20), trim)

# CASE. A glazed bezel with two hinge barrels, a lock and a sloped pediment — the
# parish/university board you may read but not open. The bezel alone puts 0.56 m2
# of new solid outside the panel's silhouette.
func _carriage_case(holder: Node3D) -> void:
	var body: StandardMaterial3D = _vm("body")
	var trim: StandardMaterial3D = _vm("trim")
	var glass: StandardMaterial3D = _vm("glass")
	_vbox(holder, Vector3(7.1, 8.5, 0.35), Vector3(0, 4.25, -0.30), body)        # back slab
	for sx in [-1.0, 1.0]:
		_vbox(holder, Vector3(0.55, 8.5, 0.48), Vector3(sx * 3.28, 4.25, 0.14), body)
	_vbox(holder, Vector3(7.1, 0.55, 0.48), Vector3(0, 8.22, 0.14), body)        # head rail
	# The sill is the one place the case has to eat into the poster: the panel's
	# bottom edge is 4.5 mm off the floor, so there is nowhere below it to put a
	# rail. Held to 0.34 (UI rows 768+) and the hint line is lifted clear below.
	_vbox(holder, Vector3(7.1, 0.34, 0.48), Vector3(0, 0.17, 0.14), body)        # sill
	var hint: Node = get_node_or_null("Viewport/InfoBoardUI/MainPanel/ContextHint")
	if hint and hint is Label:
		var h := hint as Label
		h.offset_top = -88.0
		h.offset_bottom = -63.0
	var pane := _vbox(holder, Vector3(6.6, 7.8, 0.06), Vector3(0, 4.25, 0.30), glass)
	pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# hinges left, lock right — the asymmetry is the whole claim
	for hy in [2.30, 6.20]:
		_vcyl(holder, Vector3(-3.28, hy, 0.34), 0.13, 0.55, trim, Vector3(0, 0, 0))
	_vcyl(holder, Vector3(3.34, 4.25, 0.34), 0.20, 0.12, trim, Vector3(90, 0, 0))
	_vbox(holder, Vector3(0.09, 0.30, 0.10), Vector3(3.34, 4.05, 0.40), body)
	# pediment — a board that lives outdoors gets a roof
	var roof := _vbox(holder, Vector3(7.7, 0.24, 1.30), Vector3(0, 8.62, 0.28), trim)
	roof.rotation_degrees = Vector3(-14, 0, 0)

# PYLON. 1.92 x 2.20 m of monolith with the panel sunk into a reveal, on a stepped
# base with a capping course. Nearly 3x the object's projected area — the heaviest
# thing the family can say, and the point at which contradicting the board costs
# money.
func _carriage_pylon(holder: Node3D) -> void:
	var body: StandardMaterial3D = _vm("body")
	var trim: StandardMaterial3D = _vm("trim")
	_vbox(holder, Vector3(9.6, 11.0, 1.20), Vector3(0, 5.50, -0.66), body)       # slab
	# Base course and reveal both sit wholly BEHIND the panel plane (z < 0). Pushed
	# forward they would occlude the bottom two text rows and the whole sheet
	# respectively; they still read because they overhang the panel sideways.
	_vbox(holder, Vector3(10.6, 0.50, 2.00), Vector3(0, 0.25, -1.05), trim)      # base course
	_vbox(holder, Vector3(10.2, 0.38, 1.70), Vector3(0, 11.15, -0.55), trim)     # cap
	# the reveal: a darker recess ringing the panel so it reads as sunk, not stuck on
	var rec := _mat3(_col("field", Color(0.1, 0.1, 0.1)).darkened(0.55), 0.8, 0.0, 0.0)
	_vbox(holder, Vector3(6.9, 8.6, 0.30), Vector3(0, PANEL_BOT + 4.30, -0.20), rec)
	for sx in [-1.0, 1.0]:
		_vbox(holder, Vector3(0.26, 8.9, 0.26), Vector3(sx * 3.36, PANEL_BOT + 4.30, 0.02), trim)
	_vbox(holder, Vector3(7.4, 0.26, 0.26), Vector3(0, PANEL_BOT + 8.72, 0.02), trim)

# ── primitives ───────────────────────────────────────────────────────────────

func _mat3(c: Color, rough: float = 0.6, emit: float = 0.0, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if metal > 0.0:
		m.metallic = metal
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m

# A material from a voice palette slot. The fallbacks match _mat3's own defaults,
# so a half-specified voice degrades to plain matte rather than to nothing.
func _vm(slot: String) -> StandardMaterial3D:
	var d: Dictionary = _pal().get(slot, {})
	var c: Color = d.get("c", Color(0.8, 0.8, 0.8))
	var r: float = float(d.get("r", 0.6))
	var em: float = float(d.get("e", 0.0))
	var mt: float = float(d.get("m", 0.0))
	return _mat3(c, r, em, mt)

func _vbox(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

func _vcyl(parent: Node3D, pos: Vector3, radius: float, height: float,
		mat: StandardMaterial3D, rot: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi
