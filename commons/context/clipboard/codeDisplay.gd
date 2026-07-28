# @identity
# essence: a 3D placard that pulls tutorial text from a library by ID — the in-world reader for code / explanation content
# desire: bring authored text into the scene without breaking immersion — readable, formatted, addressable by name
# critical_parameter: current_tutorial_id — picks which entry from tutorial_text.json is shown
# triggers: _ready() instantiates TutorialTextLibrary and waits a frame to locate the RichTextLabel inside the Viewport2Din3D
# emerges: a readable in-VR text panel that the map-author addresses by tt:<name> tokens
# needs: TutorialTextLibrary [present]; Viewport2Din3D child [scene-required]; rich text label resolution [present, deferred]
# relationships: clipboard/context companion to science_screen (in-world readout) and reader_table (extended reading); the placement-by-token side of the tutorial-content pipeline
# truth: A tutorial is a placement-of-words. The library holds the words, the placard holds the placement — separating them lets the same text appear in many maps.

extends Node3D

# Tutorial Text Display component
# Supports tt:name format to display tutorial text from tutorial_text.json

const HANGAR = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `support`
# ═══════════════════════════════════════════════════════════════════
#
# The identity line above says it plainly: *a tutorial is a placement-of-words.*
# The library holds the words; this placard holds the PLACEMENT. Until now only
# half of that was ever built. The whole script below is about WHICH text
# (current_tutorial_id) and not one line of it was about how the text stands —
# so across 30 placements, in every sequence, authored language hung in mid-air
# with no relationship to the room it was speaking in.
#
# `support` is the project's one word for "what apparatus holds this thing up".
# Same ladder, same meaning, same spelling as on exit_sign and science_screen:
# two panels, one question, one vocabulary. What varies is MASS and PRESENCE —
# nothing here is time-domain, and every value is legible in a single still.
#
#   none   the bare panel. No apparatus. What all 30 shipped placements are.
#   stand  a slender post to a disc foot — demountable, provisional furniture;
#          the room shows through beside it.
#   frame  a bezel and a back panel — the screen reads as a hung SIGN rather
#          than as floating light.
#   pylon  a pier of building, floor to over-head, with the panel sunk into a
#          reveal cut in its face — the building itself is speaking.
#
# The four make genuinely different claims about who is talking. That is the
# axis: not decoration, but the authority the words are delivered with.
const SUPPORTS: PackedStringArray = ["none", "stand", "frame", "pylon"]

## Default is `none` — the exact pre-promotion look, zero nodes added. Promotion
## is not permission to move 30 shipped placements.
@export_enum("none", "stand", "frame", "pylon") var support: String = "none"

# ── Panel geometry, read off codeDisplay.tscn ────────────────────────
# Viewport2Din3D: screen_size 1.0 x 1.2, sitting a few mm off local origin.
# Everything the axis builds is dimensioned from these so the apparatus stays
# registered to the face if the scene is ever re-seated.
const PANEL_W: float = 1.0
const PANEL_H: float = 1.2
const PANEL_CY: float = 0.0045     ## Viewport2Din3D's own y offset in the scene
const PANEL_CZ: float = -0.0013    ## ...and its z offset; the face looks down +Z

# ── stand ──
const STAND_POST: float = 0.05     ## square post section
const STAND_DROP: float = 1.10     ## panel bottom edge → floor
const STAND_BASE_R: float = 0.21   ## 0.42 m diameter disc
const STAND_BASE_T: float = 0.04

# ── frame ──
const BEZEL_W: float = 0.06        ## outer becomes 1.12 x 1.32
const BEZEL_D: float = 0.03
const BACK_T: float = 0.02

# ── pylon ──
const PIER_DEPTH: float = 0.30
const PIER_DROP: float = 1.10      ## panel bottom edge → floor
const PIER_RISE: float = 0.35      ## panel top edge → head of the pier
const PIER_REVEAL: float = 0.03    ## how far the panel is sunk behind the face
const PIER_JAMB: float = 0.15      ## face left standing either side of the opening

@onready var viewport_2d: Node = $Viewport2Din3D
var tutorial_library: TutorialTextLibrary
var current_tutorial_id: String = ""
var rich_text_label: RichTextLabel

## Nodes THIS script created. The teardown walks this list and nothing else —
## the grid adds label plates, packaging and tag markers as siblings, and a
## get_children() sweep would take them with it.
var _support_nodes: Array[Node3D] = []
var _built: bool = false

func _ready() -> void:
	# Initialize tutorial library
	tutorial_library = TutorialTextLibrary.new()

	# Support geometry is built SYNCHRONOUSLY: children exist by the time the
	# first await below yields, which is what apply_grid_config (call_deferred,
	# ahead of grounding and label framing) and curation_station both count on.
	_build_all()
	_built = true

	# Wait a frame for Viewport2Din3D to set up its scene
	await get_tree().process_frame

	# Find the RichTextLabel in the Viewport2Din3D's scene
	_find_rich_text_label()


# ═══════════════════════════════════════════════════════════════════
# SUPPORT BUILD
# ═══════════════════════════════════════════════════════════════════

func _panel_bottom() -> float:
	return PANEL_CY - PANEL_H * 0.5

func _panel_top() -> float:
	return PANEL_CY + PANEL_H * 0.5

## Track and parent in one step so nothing this script makes can escape teardown.
func _add_support_node(n: Node3D) -> void:
	add_child(n)
	_support_nodes.append(n)

func _build_all() -> void:
	match support:
		"stand":
			_build_support_stand()
		"frame":
			_build_support_frame()
		"pylon":
			_build_support_pylon()
		_:
			pass  # "none" — the bare panel and its HandPoseArea. Zero nodes.


## A 0.05 m post from the centre of the panel's bottom edge down to a 0.42 m
## disc. Hardware you could carry in one hand: the words are visiting the room
## for the duration of a lesson, and the room shows through on both sides.
func _build_support_stand() -> void:
	var post_mat: StandardMaterial3D = HANGAR.painted_metal(Color(0.16, 0.16, 0.19), 0.18, 0.55, 0.34)
	var post_top: float = _panel_bottom()
	var post_bottom: float = post_top - STAND_DROP
	_add_support_node(HANGAR.box(
		Vector3(0.0, post_top - STAND_DROP * 0.5, PANEL_CZ),
		Vector3(STAND_POST, STAND_DROP, STAND_POST),
		post_mat))

	var base: MeshInstance3D = MeshInstance3D.new()
	var disc: CylinderMesh = CylinderMesh.new()
	disc.top_radius = STAND_BASE_R
	disc.bottom_radius = STAND_BASE_R
	disc.height = STAND_BASE_T
	disc.radial_segments = 28
	base.mesh = disc
	base.position = Vector3(0.0, post_bottom - STAND_BASE_T * 0.5, PANEL_CZ)
	base.material_override = HANGAR.worn_metal(Color(0.22, 0.22, 0.25))
	_add_support_node(base)


## A 0.06 m bezel around all four edges (outer 1.12 x 1.32) and a back panel
## behind the viewport. Nothing touches the floor — but the text stops being
## light in the air and becomes a hung sign, a made object with an edge and a
## back, fixed to something.
func _build_support_frame() -> void:
	var bezel_mat: StandardMaterial3D = HANGAR.painted_metal(Color(0.19, 0.20, 0.23), 0.14, 0.4, 0.5)
	var back_mat: StandardMaterial3D = HANGAR.painted_metal(Color(0.10, 0.10, 0.12), 0.2, 0.3, 0.7)

	var outer_w: float = PANEL_W + BEZEL_W * 2.0
	var outer_h: float = PANEL_H + BEZEL_W * 2.0
	var half_bez: float = BEZEL_W * 0.5

	# Head and sill run the full outer width; the stiles fill between them.
	_add_support_node(HANGAR.box(
		Vector3(0.0, _panel_top() + half_bez, PANEL_CZ),
		Vector3(outer_w, BEZEL_W, BEZEL_D), bezel_mat))
	_add_support_node(HANGAR.box(
		Vector3(0.0, _panel_bottom() - half_bez, PANEL_CZ),
		Vector3(outer_w, BEZEL_W, BEZEL_D), bezel_mat))
	for i in range(2):
		var s: float = -1.0 if i == 0 else 1.0
		_add_support_node(HANGAR.box(
			Vector3(s * (PANEL_W * 0.5 + half_bez), PANEL_CY, PANEL_CZ),
			Vector3(BEZEL_W, outer_h, BEZEL_D), bezel_mat))

	_add_support_node(HANGAR.box(
		Vector3(0.0, PANEL_CY, PANEL_CZ - BACK_T),
		Vector3(outer_w, outer_h, BACK_T), back_mat))


## A pier of building: 0.30 m deep, running 1.1 m below the panel to the floor
## and 0.35 m above its head, with the panel sunk 0.03 m into a reveal cut in
## the front face. Contradicting a stand costs a screwdriver; contradicting this
## costs money. Same words, entirely different authority.
func _build_support_pylon() -> void:
	var pier_mat: StandardMaterial3D = HANGAR.painted_metal(Color(0.17, 0.17, 0.20), 0.2, 0.26, 0.7)
	var reveal_mat: StandardMaterial3D = HANGAR.painted_metal(Color(0.07, 0.07, 0.08), 0.1, 0.2, 0.82)

	var pier_top: float = _panel_top() + PIER_RISE
	var pier_bottom: float = _panel_bottom() - PIER_DROP
	var pier_h: float = pier_top - pier_bottom
	var pier_cy: float = (pier_top + pier_bottom) * 0.5
	var pier_w: float = PANEL_W + PIER_JAMB * 2.0

	# Opening: the panel plus a hairline margin, so the face frames it rather
	# than clipping it.
	var open_w: float = PANEL_W + 0.04
	var open_h: float = PANEL_H + 0.04
	var open_top: float = PANEL_CY + open_h * 0.5
	var open_bottom: float = PANEL_CY - open_h * 0.5

	# Mass behind: front face lands exactly on the panel plane, so the panel is
	# seated against building rather than floating in a hole.
	var mass_d: float = PIER_DEPTH - PIER_REVEAL
	_add_support_node(HANGAR.box(
		Vector3(0.0, pier_cy, PANEL_CZ - mass_d * 0.5),
		Vector3(pier_w, pier_h, mass_d), pier_mat))

	# Front skin, PIER_REVEAL proud of the panel — the four returns that make
	# the recess read as a recess.
	var skin_cz: float = PANEL_CZ + PIER_REVEAL * 0.5
	for i in range(2):
		var s: float = -1.0 if i == 0 else 1.0
		_add_support_node(HANGAR.box(
			Vector3(s * (open_w + pier_w) * 0.25, pier_cy, skin_cz),
			Vector3((pier_w - open_w) * 0.5, pier_h, PIER_REVEAL), pier_mat))
	_add_support_node(HANGAR.box(
		Vector3(0.0, (pier_top + open_top) * 0.5, skin_cz),
		Vector3(open_w, pier_top - open_top, PIER_REVEAL), pier_mat))
	_add_support_node(HANGAR.box(
		Vector3(0.0, (open_bottom + pier_bottom) * 0.5, skin_cz),
		Vector3(open_w, open_bottom - pier_bottom, PIER_REVEAL), pier_mat))

	# A shadow rim on the reveal's inner return, so the depth survives flat light.
	_add_support_node(HANGAR.box(
		Vector3(0.0, PANEL_CY, PANEL_CZ + 0.004),
		Vector3(open_w + 0.012, open_h + 0.012, 0.008), reveal_mat))


## Accept an axis value only if it names something we actually build. A typo in
## a map token has to fall back to the shipped look, not strand a placement with
## half an apparatus.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Resolve the axis from a grid config and rebuild ONLY if it actually moved.
##
## curation_station calls apply_grid_config({"emissive": false}) on every artifact
## it curates — one line after it has un-billboarded, dimmed and back-plated the
## labels. An unconditional rebuild there throws that framing away and it is never
## re-applied. So: no support key, or the same value, means touch nothing and say
## nothing.
func _apply_support_config(config_data: Dictionary) -> void:
	var before_support: String = support
	if config_data.has("support"):
		support = _pick_axis(str(config_data["support"]), SUPPORTS, support)

	if not _built:
		return  # nothing built yet — _ready() will use the value we just resolved
	if support == before_support:
		return

	_rebuild_now()
	print("[CodeDisplay] Config applied — support=%s" % [support])


## Synchronous teardown + rebuild. remove_child() takes the old nodes out of the
## tree in this same frame (queue_free alone would leave them rendering), and
## nothing is deferred: a deferred rebuild would have the grid's auto-ground pass
## measure an empty AABB and skip grounding entirely.
func _rebuild_now() -> void:
	for c in _support_nodes:
		if is_instance_valid(c):
			if c.get_parent() == self:
				remove_child(c)
			c.queue_free()
	_support_nodes.clear()
	_build_all()

func _find_rich_text_label() -> void:
	"""Find the RichTextLabel within the Viewport2Din3D's viewport scene"""
	print("CodeDisplay: _find_rich_text_label() called")

	if not viewport_2d:
		push_warning("CodeDisplay: Viewport2Din3D not found")
		return

	print("CodeDisplay: Waiting for scene to load...")
	# Wait for scene to load
	await get_tree().process_frame
	await get_tree().process_frame
	print("CodeDisplay: Scene load wait complete")

	# Try to find by path first (faster and more reliable)
	# Try TextUIControl.tscn path first (used by codeDisplay.tscn)
	var textui_path = "Viewport/Control/ScrollContainer/RichTextLabel"
	print("CodeDisplay: Trying TextUIControl path: %s" % textui_path)
	rich_text_label = viewport_2d.get_node_or_null(textui_path)
	if rich_text_label:
		print("CodeDisplay: ✅ Found RichTextLabel at path: %s" % textui_path)
		return

	# Fallback to tutorial_display_2d.tscn path
	var tutorial_path = "Viewport/TutorialDisplay2D/MarginContainer/ScrollContainer/TutorialContent"
	print("CodeDisplay: Trying TutorialDisplay2D path: %s" % tutorial_path)
	rich_text_label = viewport_2d.get_node_or_null(tutorial_path)
	if rich_text_label:
		print("CodeDisplay: ✅ Found RichTextLabel at path: %s" % tutorial_path)
		return
	else:
		print("CodeDisplay: ❌ Both direct paths failed")

	# Try to get the scene instance from Viewport2Din3D
	print("CodeDisplay: Checking if viewport_2d has get_scene_instance method...")
	if viewport_2d.has_method("get_scene_instance"):
		print("CodeDisplay: Method exists, calling it...")
		var scene_instance = viewport_2d.get_scene_instance()
		if scene_instance:
			print("CodeDisplay: Got scene instance: %s, searching recursively..." % scene_instance.name)
			rich_text_label = _find_rich_text_label_recursive(scene_instance)
			if rich_text_label:
				print("CodeDisplay: ✅ Found RichTextLabel via scene instance")
				return
			else:
				print("CodeDisplay: ❌ Recursive search in scene instance failed")
		else:
			print("CodeDisplay: ❌ get_scene_instance returned null")
	else:
		print("CodeDisplay: ❌ viewport_2d does not have get_scene_instance method")

	# Fallback: search in Viewport node
	print("CodeDisplay: Trying fallback - searching in Viewport node...")
	var viewport = viewport_2d.get_node_or_null("Viewport")
	if viewport:
		print("CodeDisplay: Found Viewport node, searching recursively...")
		rich_text_label = _find_rich_text_label_recursive(viewport)
		if rich_text_label:
			print("CodeDisplay: ✅ Found RichTextLabel in viewport")
		else:
			push_warning("CodeDisplay: ❌ Could not find RichTextLabel in viewport")
			print("CodeDisplay: Viewport children count: %d" % viewport.get_child_count())
			if viewport.get_child_count() > 0:
				print("CodeDisplay: First child: %s" % viewport.get_child(0).name)
	else:
		push_warning("CodeDisplay: ❌ Could not find Viewport node")
		var child_names = []
		for child in viewport_2d.get_children():
			child_names.append(child.name)
		print("CodeDisplay: Available children of viewport_2d: %s" % str(child_names))

func _find_rich_text_label_recursive(node: Node) -> RichTextLabel:
	"""Recursively search for RichTextLabel in the node tree"""
	if node is RichTextLabel:
		return node
	
	for child in node.get_children():
		var result = _find_rich_text_label_recursive(child)
		if result:
			return result
	
	return null

func set_tutorial(tutorial_id: String) -> void:
	"""Set the tutorial content by ID"""
	print("CodeDisplay: set_tutorial() called with ID: '%s'" % tutorial_id)

	if not tutorial_library:
		push_warning("CodeDisplay: Tutorial library not initialized")
		return

	current_tutorial_id = tutorial_id.to_lower()
	print("CodeDisplay: Loading tutorial: '%s'" % current_tutorial_id)

	var content = tutorial_library.get_tutorial_content(current_tutorial_id)

	if content.is_empty():
		push_warning("CodeDisplay: Tutorial '%s' not found or has no content" % tutorial_id)
		print("CodeDisplay: Available tutorials: %s" % str(tutorial_library.get_all_tutorial_ids()))
		return

	print("CodeDisplay: Got content (length: %d)" % content.length())
	await _display_content(content)

func set_tutorial_from_text(text: String) -> void:
	"""Parse tt:name format from text and display tutorial content"""
	if not tutorial_library:
		push_warning("CodeDisplay: Tutorial library not initialized")
		return

	# Check if text contains tt:name format
	var expanded_text = tutorial_library.expand_text(text)

	# If expansion occurred, display it
	if expanded_text != text:
		await _display_content(expanded_text)
	else:
		# No tt:name found, just display the text as-is
		await _display_content(text)

func _display_content(content: String) -> void:
	"""Display content in the RichTextLabel"""
	print("CodeDisplay: _display_content() called, rich_text_label is: %s" % ("FOUND" if rich_text_label else "NULL"))

	if not rich_text_label:
		# Try to find it again if not set
		print("CodeDisplay: Searching for RichTextLabel...")
		await _find_rich_text_label()
		print("CodeDisplay: After search, rich_text_label is: %s" % ("FOUND" if rich_text_label else "NULL"))

		if not rich_text_label:
			push_warning("CodeDisplay: Cannot display content - RichTextLabel not found")
			return

	if rich_text_label:
		print("CodeDisplay: Setting content on RichTextLabel...")
		rich_text_label.clear()
		rich_text_label.text = ""
		if _should_render_plain_text(content):
			# Content often includes code-style indexing (e.g. foo[cell]) which is parsed as BBCode tags.
			rich_text_label.bbcode_enabled = false
			rich_text_label.text = content
		else:
			rich_text_label.bbcode_enabled = true
			rich_text_label.bbcode_text = content
		print("CodeDisplay: Content set successfully! Length: %d" % content.length())
	else:
		push_error("CodeDisplay: rich_text_label is still null after search!")

func _should_render_plain_text(content: String) -> bool:
	# Markdown code fences should be shown literally in this display.
	if content.find("```") != -1:
		return true
	
	# Array/dictionary indexing such as grid[cell] causes RichTextLabel to interpret [cell] as a BBCode table cell tag.
	var indexing_regex := RegEx.new()
	if indexing_regex.compile("[A-Za-z_][A-Za-z0-9_]*\\s*\\[[^\\]\\n]+\\]") == OK:
		if indexing_regex.search(content) != null:
			return true
	
	# Fallback: if bracket tags are present but not in our safe BBCode subset, render as plain text.
	var tag_regex := RegEx.new()
	if tag_regex.compile("\\[/?([A-Za-z_][A-Za-z0-9_]*)[^\\]]*\\]") == OK:
		var safe_tags := {
			"b": true,
			"i": true,
			"u": true,
			"s": true,
			"code": true,
			"color": true,
			"font_size": true,
			"url": true,
			"img": true,
			"center": true,
			"right": true,
			"left": true,
			"font": true,
			"hr": true,
			"indent": true,
			"ul": true,
			"ol": true,
			"li": true,
			"quote": true
		}
		for match in tag_regex.search_all(content):
			var tag_name := match.get_string(1).to_lower()
			if not safe_tags.has(tag_name):
				return true
	
	return false

func apply_grid_config(config_data: Dictionary) -> void:
	"""Apply configuration from grid system, similar to clipboard
	Supports both explicit and shorthand syntax:
	  - #tutorial:line_axioms  (explicit)
	  - #line_axioms           (shorthand - value used as tutorial key)
	"""
	print("CodeDisplay: apply_grid_config() called with: %s" % config_data)
	print("CodeDisplay: tutorial_library initialized? %s" % ("YES" if tutorial_library else "NO"))
	print("CodeDisplay: rich_text_label found? %s" % ("YES" if rich_text_label else "NO"))

	# Ensure we're ready before trying to set content
	if not is_node_ready():
		print("CodeDisplay: Node not ready yet, waiting...")
		await ready

	# Ensure RichTextLabel is found
	if not rich_text_label:
		print("CodeDisplay: RichTextLabel not found, searching...")
		await get_tree().process_frame
		_find_rich_text_label()

	# Check for explicit tutorial key first
	if config_data.has("tutorial"):
		var tutorial_key = str(config_data.tutorial).strip_edges()
		print("CodeDisplay: Found explicit 'tutorial' key: '%s'" % tutorial_key)
		if tutorial_key.begins_with("tt:"):
			# Extract tutorial ID from tt:name format
			var parts = tutorial_key.split(":")
			if parts.size() >= 2:
				set_tutorial(parts[1])
		else:
			# Direct tutorial ID
			set_tutorial(tutorial_key)

	elif config_data.has("content"):
		var content_config = str(config_data.content)
		print("CodeDisplay: Found 'content' key: '%s'" % content_config)
		set_tutorial_from_text(content_config)

	else:
		# Check for shorthand syntax (e.g., #line_axioms)
		# Parser stores these as { line_axioms: true }
		print("CodeDisplay: Checking for shorthand syntax...")
		for key in config_data.keys():
			print("CodeDisplay: Key '%s' = %s" % [key, config_data[key]])
			if config_data[key] == true:
				var tutorial_key = key.strip_edges()
				print("CodeDisplay: Using shorthand tutorial key: '%s'" % tutorial_key)
				set_tutorial(tutorial_key)
				break

func refresh_content() -> void:
	"""Reload tutorial library and refresh current content"""
	if tutorial_library:
		tutorial_library.reload_tutorials()
	
	if not current_tutorial_id.is_empty():
		set_tutorial(current_tutorial_id)
