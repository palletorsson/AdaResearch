## LibraryRack — Universal collection display wall.
## Reads any artifact registry JSON and builds a grid of cubes,
## each containing a scaled-down artifact scene or a shader cube.
##
## Config keys (via map JSON #hash syntax):
##   collection     – registry filename without .json (e.g. "shaders", "primitives")
##   filter         – substring to match in name, category, or tags
##   sort           – "alpha", "category", or "default" (registry order)
##   cols / columns – cubes across (default 6)
##   rows           – cubes high (default 4)
##   cube_size      – size of each slot (default 0.7)
##   gap            – spacing between slots (default 0.12)
##   title          – override display title
##   label_visible  – show labels (default true)
##   guard          – institutional apparatus around the collection (see below)

# @identity
# essence: library[i] = registry.artifacts[i].scene — a physical index of computational objects
# desire: stand before a wall of everything the system can make, organized and labeled
# critical_parameter: the collection key — one word selects which registry to display
# triggers: apply_grid_config reads collection, loads registry, builds wall of instanced scenes
# emerges: a periodic table for any domain — shaders, primitives, patterns, hazards, math objects
# truth: a library is not the objects — it is the act of organizing them so they can be found

extends Node3D
class_name LibraryRack


# Spine-corridor contract — the library rack instantiates an entire artifact
# registry as children (default 6x4 = 24 scenes), each a full artifact scene
# with its own init cost. ~14m tall, hundreds of nodes. Never fits a corridor.
func spine_hints() -> Dictionary:
	return {
		"role":         "primary",
		"footprint":    Vector2i(3, 4),
		"approach":     "south",
		"reading_dist": 2.0,
		"budget_ms":    8.0,
		"tags":         ["oversized", "corridor_incompatible", "gallery"],
	}


@export var columns: int = 6
@export var rows: int = 4
@export var cube_size: float = 1.0
@export var gap: float = 0.0
@export var label_visible: bool = true

# ── Stage-2 DNA axis: `guard` ────────────────────────────────────────
# How much apparatus the institution puts between a visitor and the collection.
# One ordered ladder, shared VERBATIM with exhibit_furniture and exhibit_vitrine —
# the same word must mean the same escalation wherever it appears, or the family
# stops being a family.
#
#   none     the open shelf; the objects meet the room on their own
#   label    a lectern in front of the wall — the collection is now titled by someone
#   fixture  a lighting housing over the wall — the institution pays to light it
#   hood     a glazed case over the whole wall — you may look, not reach
#   cordon   a rope line held off the wall — the distance itself is the rule
#
# WHY THIS IS THE AXIS. cols/rows/cube_size/gap already reach map tokens; they change
# how much is shelved, never by whose authority. Seventy placements have all said the
# same unexamined thing — a collection standing in raw air, which reads as a warehouse.
# The identical 24 objects behind glass read as a museum. That claim is what varies here.
#
# `frame` is omitted ON PURPOSE. On a case-less wall it would build the same posts and
# rims as `hood` minus the panes, and a downstream pixel critic would rightly call that
# pair inert. Better a declared gap than a knob connected to nothing.
const GUARDS: PackedStringArray = ["none", "label", "fixture", "hood", "cordon"]

## The apparatus standing between the visitor and the collection.
## Default `none` is the pre-promotion look, exactly: 70 shipped rooms keep the open shelf.
@export_enum("none", "label", "fixture", "hood", "cordon") var guard: String = "none"

# LAW 5 — every value below is sized to the WALL, not to a fixed number of centimetres.
# W = columns * (cube_size + gap), H = rows * (cube_size + gap). On the default 6 x 4 m
# rack the housing is 6 m long and the cordon spans 7.6 m; on a 3 m rack they shrink with it.
const LECTERN_STANDOFF: float = 1.6      ## metres the lectern stands in front of the slot faces
const LECTERN_CARD: Vector2 = Vector2(0.9, 0.6)
const LECTERN_TOP_Y: float = 1.15        ## height of the card's top edge above the floor
const LECTERN_RECLINE_DEG: float = 30.0
const LECTERN_POST: float = 0.12         ## square section of the canted post
const LECTERN_FOOT: Vector3 = Vector3(0.7, 0.05, 0.5)

const FIXTURE_SECTION: Vector2 = Vector2(0.30, 0.45)  ## housing height x forward projection
const FIXTURE_LIFT: float = 0.25         ## clearance above the top row
const FIXTURE_PITCH: float = 1.2         ## one downlight cone every this many metres

const HOOD_STANDOFF: float = 0.75        ## metres the glazing stands clear of the slot faces
const HOOD_MULLION: float = 0.09         ## square section of mullions and rims
const HOOD_OVERHEAD: float = 0.30        ## case reaches H + this above the floor
const HOOD_PANE_ALPHA: float = 0.18

const CORDON_POSTS: int = 8
const CORDON_STANDOFF: float = 1.4       ## metres the rope line stands out from the slot faces
const CORDON_POST_H: float = 0.95
const CORDON_DISC_R: float = 0.09
const CORDON_OVERHANG: float = 1.6       ## the line spans W + this
const CORDON_SAG: float = 0.12

var _collection_name: String = ""
var _filter: String = ""
var _sort_mode: String = "default"
var _title_override: String = ""
var _layout_file: String = ""  # Override layout filename (default: rack_layout.json)
var _entries: Array[Dictionary] = []  # [{name, lookup_name, category, scene, tags, description}]
var _slot_nodes: Array[Node3D] = []

## Only the nodes THIS script parented to self. Teardown walks this, never
## get_children() — the grid adds label plates, packaging and tag markers as our
## children after we build, and freeing those is how a rack loses its map furniture.
var _owned: Array[Node3D] = []
var _guard_root: Node3D = null

## True once a wall actually stands. Guards the no-op path below.
var _built: bool = false


func _ready() -> void:
	# DEVIATION FROM THE HOUSE SHAPE, deliberate: this artifact cannot build in
	# _ready() because it has nothing to build yet — the collection key arrives with
	# apply_grid_config, and building here would stand an empty 6x4 grid of blank
	# cubes titled " LIBRARY" in every room. So `_built` flips on the first real
	# build instead, and the no-op check below is written against it.
	pass


func apply_grid_config(config_data: Dictionary) -> void:
	# Snapshot EVERY key that changes what gets built. curation_station.gd:372 calls
	# this with {"emissive": false} one line after it has made the artifact inert and
	# darkened its labels; an unconditional rebuild there throws that framing away and
	# is never re-applied. Nothing changed -> touch nothing, say nothing.
	var before_collection: String = _collection_name
	var before_filter: String = _filter
	var before_sort: String = _sort_mode
	var before_title: String = _title_override
	var before_layout: String = _layout_file
	var before_columns: int = columns
	var before_rows: int = rows
	var before_cube: float = cube_size
	var before_gap: float = gap
	var before_labels: bool = label_visible
	var before_guard: String = guard

	if config_data.has("collection"):
		_collection_name = str(config_data["collection"]).strip_edges()
	if config_data.has("filter"):
		_filter = str(config_data["filter"]).strip_edges().to_lower()
	if config_data.has("sort"):
		_sort_mode = str(config_data["sort"]).strip_edges().to_lower()
	if config_data.has("title"):
		_title_override = str(config_data["title"]).strip_edges()
	if config_data.has("cols"):
		columns = clampi(int(config_data["cols"]), 1, 12)
	if config_data.has("columns"):
		columns = clampi(int(config_data["columns"]), 1, 12)
	if config_data.has("rows"):
		rows = clampi(int(config_data["rows"]), 1, 8)
	if config_data.has("cube_size"):
		cube_size = clampf(float(config_data["cube_size"]), 0.3, 2.0)
	if config_data.has("gap"):
		gap = clampf(float(config_data["gap"]), 0.0, 1.0)
	if config_data.has("label_visible"):
		label_visible = str(config_data["label_visible"]).to_lower() != "false"
	if config_data.has("layout"):
		_layout_file = str(config_data["layout"]).strip_edges()

	# Stage-2 DNA axis — #guard:hood
	if config_data.has("guard"):
		guard = _pick_axis(str(config_data["guard"]), GUARDS, guard)

	if _collection_name == "":
		print("[LibraryRack] No collection specified")
		return

	if not _built:
		_build_all()
		_built = true
		print("[LibraryRack] Config applied — %dx%d, collection=%s, guard=%s" % [
			columns, rows, _collection_name, guard])
		return

	if (_collection_name == before_collection
			and _filter == before_filter
			and _sort_mode == before_sort
			and _title_override == before_title
			and _layout_file == before_layout
			and columns == before_columns
			and rows == before_rows
			and is_equal_approx(cube_size, before_cube)
			and is_equal_approx(gap, before_gap)
			and label_visible == before_labels
			and guard == before_guard):
		return

	_rebuild_now()
	print("[LibraryRack] Config applied — %dx%d, collection=%s, guard=%s" % [
		columns, rows, _collection_name, guard])


## Load + build, synchronously. Children exist when this returns, so the deferred
## _auto_ground_artifact that runs after us measures a real AABB.
func _build_all() -> void:
	# Try a rack_layout.json from the current map directory first
	var layout_loaded: bool = _try_load_layout()
	if not layout_loaded:
		_load_collection()
	_build_wall()
	_build_guard()


## The apparatus the institution puts between a visitor and the collection.
##
## Every member is sized off the WALL (total_w / total_h), never off a fixed number of
## centimetres, so a 6x4 rack and a 12x8 rack are guarded at the same visual weight.
## `none` returns before adding anything: the 70 shipped placements are untouched.
func _build_guard() -> void:
	if guard == "none":
		return

	var step: float = cube_size + gap
	var total_w: float = float(columns) * step - gap
	var total_h: float = float(rows) * step - gap
	# The wall's own frame: slots are centred on x = 0.5 and rise from y = -0.5.
	var cx: float = 0.5
	var floor_y: float = -0.5
	var top_y: float = total_h - 0.5
	var z_face: float = 0.5 + cube_size * 0.5

	_guard_root = Node3D.new()
	_guard_root.name = "Guard_%s" % guard
	add_child(_guard_root)
	_owned.append(_guard_root)

	match guard:
		"label":
			_guard_lectern(cx, floor_y, z_face, total_w)
		"fixture":
			_guard_fixture(cx, top_y, z_face, total_w)
		"hood":
			_guard_hood(cx, floor_y, top_y, z_face, total_w, total_h)
		"cordon":
			_guard_cordon(cx, floor_y, z_face, total_w)


func _guard_part(size: Vector3, pos: Vector3, col: Color, metal: float = 0.4,
		alpha: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(col.r, col.g, col.b, alpha)
	mat.metallic = metal
	mat.roughness = 0.35
	if alpha < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.position = pos
	_guard_root.add_child(mi)
	return mi


## label — a lectern in front of the wall. The collection is now titled by someone.
func _guard_lectern(cx: float, floor_y: float, z_face: float, total_w: float) -> void:
	var desk_w: float = clampf(total_w * 0.28, 0.45, 1.30)
	var dark := Color(0.16, 0.17, 0.20)
	_guard_part(Vector3(0.09, 0.95, 0.09), Vector3(cx, floor_y + 0.475, z_face + 0.85), dark, 0.55)
	_guard_part(Vector3(desk_w * 0.7, 0.03, 0.24), Vector3(cx, floor_y + 0.03, z_face + 0.85), dark, 0.55)
	var top := _guard_part(Vector3(desk_w, 0.035, 0.34),
		Vector3(cx, floor_y + 1.00, z_face + 0.83), Color(0.82, 0.78, 0.70), 0.2)
	top.rotation.x = deg_to_rad(-22.0)


## fixture — a lighting housing over the wall. The institution pays to light it.
func _guard_fixture(cx: float, top_y: float, z_face: float, total_w: float) -> void:
	_guard_part(Vector3(total_w + 0.10, 0.17, 0.34),
		Vector3(cx, top_y + 0.30, z_face + 0.06), Color(0.13, 0.14, 0.16), 0.7)
	# Two stand-off arms back to the wall plane, so the housing is carried, not floating.
	for s in [-1.0, 1.0]:
		_guard_part(Vector3(0.05, 0.05, 0.30),
			Vector3(cx + s * total_w * 0.36, top_y + 0.30, z_face - 0.10),
			Color(0.13, 0.14, 0.16), 0.7)
	var lamp := _guard_part(Vector3(total_w * 0.96, 0.035, 0.20),
		Vector3(cx, top_y + 0.20, z_face + 0.10), Color(1.0, 0.94, 0.78), 0.0)
	var lm: StandardMaterial3D = lamp.material_override
	lm.emission_enabled = true
	lm.emission = Color(1.0, 0.94, 0.78)
	lm.emission_energy_multiplier = 2.4


## hood — a glazed case over the whole wall. You may look, not reach.
func _guard_hood(cx: float, floor_y: float, top_y: float, z_face: float,
		total_w: float, total_h: float) -> void:
	var w: float = total_w + 0.16
	var h: float = total_h + 0.16
	var cy: float = (floor_y + top_y) * 0.5
	var depth: float = 0.34
	var glass := Color(0.72, 0.85, 0.90)
	var rim := Color(0.10, 0.11, 0.13)
	# Front pane.
	_guard_part(Vector3(w, h, 0.02), Vector3(cx, cy, z_face + depth), glass, 0.1, 0.22)
	# Side returns.
	for s in [-1.0, 1.0]:
		_guard_part(Vector3(0.02, h, depth),
			Vector3(cx + s * w * 0.5, cy, z_face + depth * 0.5), glass, 0.1, 0.22)
	# Top cap and the dark rim that reads as cabinetwork at room distance.
	_guard_part(Vector3(w, 0.02, depth), Vector3(cx, cy + h * 0.5, z_face + depth * 0.5), glass, 0.1, 0.22)
	_guard_part(Vector3(w + 0.06, 0.07, depth + 0.06),
		Vector3(cx, cy + h * 0.5 + 0.05, z_face + depth * 0.5), rim, 0.6)
	_guard_part(Vector3(w + 0.06, 0.07, depth + 0.06),
		Vector3(cx, cy - h * 0.5 - 0.05, z_face + depth * 0.5), rim, 0.6)


## cordon — a rope line held off the wall. The distance itself is the rule.
func _guard_cordon(cx: float, floor_y: float, z_face: float, total_w: float) -> void:
	var reach: float = total_w * 0.5 + 0.30
	var post_h: float = 1.02
	var z_line: float = z_face + 1.15
	var brass := Color(0.72, 0.58, 0.28)
	for s in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.035
		cyl.bottom_radius = 0.035
		cyl.height = post_h
		post.mesh = cyl
		var pm := StandardMaterial3D.new()
		pm.albedo_color = brass
		pm.metallic = 0.85
		pm.roughness = 0.3
		post.material_override = pm
		post.position = Vector3(cx + s * reach, floor_y + post_h * 0.5, z_line)
		_guard_root.add_child(post)
		# A weighted base, so the posts read as free-standing rather than sunk.
		_guard_part(Vector3(0.22, 0.04, 0.22),
			Vector3(cx + s * reach, floor_y + 0.02, z_line), brass, 0.85)
	# The rope: one span between the post tops, slung slightly low.
	var rope := MeshInstance3D.new()
	var rc := CylinderMesh.new()
	rc.top_radius = 0.028
	rc.bottom_radius = 0.028
	rc.height = reach * 2.0
	rope.mesh = rc
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color(0.55, 0.10, 0.12)
	rm.roughness = 0.9
	rope.material_override = rm
	rope.rotation.z = deg_to_rad(90.0)
	rope.position = Vector3(cx, floor_y + post_h - 0.10, z_line)
	_guard_root.add_child(rope)


## NO call_deferred anywhere in this path. remove_child() takes the old wall out of
## the tree in this same frame; a deferred rebuild would leave a window in which the
## artifact has zero children and grounding silently gives up.
func _rebuild_now() -> void:
	for node in _owned:
		if is_instance_valid(node):
			if node.get_parent() == self:
				remove_child(node)
			node.queue_free()
	_owned.clear()
	_slot_nodes.clear()
	_guard_root = null
	_build_all()


## Accept an axis value only if it names something we actually build. A typo in a map
## token falls back to the value already in force — a half-recognised token must never
## strand a shipped room with apparatus nobody asked for.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


# ═══════════════════════════════════════════════════════════════════
# LOAD LAYOUT FILE (curated selection with nulls for holes)
# ═══════════════════════════════════════════════════════════════════

func _try_load_layout() -> bool:
	# Find the current map name from the GridSystem parent
	var map_name := ""
	var parent := get_parent()
	while parent:
		if parent.get("map_name") != null:
			map_name = str(parent.get("map_name"))
			break
		parent = parent.get_parent()
	if map_name == "":
		return false

	var layout_filename := _layout_file if _layout_file != "" else "rack_layout.json"
	var layout_path := "res://commons/maps/%s/%s" % [map_name, layout_filename]
	if not FileAccess.file_exists(layout_path):
		return false

	var file := FileAccess.open(layout_path, FileAccess.READ)
	if not file:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return false

	var data: Dictionary = json.data

	# Override config from layout
	if data.has("collection"):
		_collection_name = str(data["collection"])
	if data.has("cols"):
		columns = int(data["cols"])
	if data.has("rows"):
		rows = int(data["rows"])
	if data.has("title"):
		_title_override = str(data["title"])

	var slots: Array = data.get("slots", [])
	if slots.is_empty():
		return false

	# Load the full registry to resolve lookup names
	var all_artifacts: Dictionary = _load_registry_dict()

	# Build entries from layout — null = empty slot (hole)
	_entries.clear()
	for row_idx in range(slots.size()):
		var row: Array = slots[row_idx] if slots[row_idx] is Array else []
		for col_idx in range(row.size()):
			var val = row[col_idx]
			if val == null or val == "":
				_entries.append({"name": "", "lookup_name": "", "category": "", "scene": "", "description": "", "tags": [], "is_shader": false, "_empty": true})
			elif str(val).begins_with("res://") and str(val).ends_with(".gdshader"):
				# Direct shader path
				var shader_path := str(val)
				var shader_name := shader_path.get_file().get_basename()
				_entries.append({"name": shader_name, "lookup_name": shader_name, "category": "shader", "scene": shader_path, "description": "", "tags": [], "is_shader": true, "_empty": false, "_shader_path": shader_path})
			else:
				var lookup := str(val)
				if all_artifacts.has(lookup):
					var art: Dictionary = all_artifacts[lookup]
					_entries.append({
						"name": str(art.get("name", lookup)),
						"lookup_name": lookup,
						"category": str(art.get("category", "")),
						"scene": str(art.get("scene", "")),
						"description": str(art.get("description", "")),
						"tags": art.get("tags", []),
						"is_shader": _collection_name == "shaders" or str(art.get("scene", "")).ends_with(".gdshader"),
						"_empty": false,
					})
				else:
					# Lookup name not found — show as colored placeholder
					_entries.append({"name": lookup, "lookup_name": lookup, "category": "unknown", "scene": "", "description": "", "tags": [], "is_shader": false, "_empty": false})

	columns = int(data.get("cols", columns))
	rows = int(data.get("rows", rows))
	print("[LibraryRack] Layout loaded: %dx%d from %s (%d entries)" % [columns, rows, layout_path, _entries.size()])
	return true


func _load_registry_dict() -> Dictionary:
	var registry_path := "res://commons/artifacts/registry/%s.json" % _collection_name
	if not FileAccess.file_exists(registry_path):
		return {}
	var file := FileAccess.open(registry_path, FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	return json.data.get("artifacts", {})


# ═══════════════════════════════════════════════════════════════════
# LOAD REGISTRY (full collection, no layout file)
# ═══════════════════════════════════════════════════════════════════

func _load_collection() -> void:
	_entries.clear()

	var registry_path := "res://commons/artifacts/registry/%s.json" % _collection_name
	if not FileAccess.file_exists(registry_path):
		print("[LibraryRack] Registry not found: %s" % registry_path)
		return

	var file := FileAccess.open(registry_path, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		print("[LibraryRack] Failed to parse: %s" % registry_path)
		return

	var data: Dictionary = json.data
	var artifacts: Dictionary = data.get("artifacts", {})

	for key in artifacts:
		var art: Dictionary = artifacts[key]
		var entry: Dictionary = {
			"name": str(art.get("name", key)),
			"lookup_name": str(art.get("lookup_name", key)),
			"category": str(art.get("category", "")),
			"scene": str(art.get("scene", "")),
			"description": str(art.get("description", "")),
			"tags": art.get("tags", []),
			"is_shader": _collection_name == "shaders" or str(art.get("scene", "")).ends_with(".gdshader"),
		}

		# Apply filter
		if _filter != "":
			var found := false
			if _filter in entry["name"].to_lower(): found = true
			if _filter in entry["category"].to_lower(): found = true
			if _filter in entry["lookup_name"].to_lower(): found = true
			for tag in entry["tags"]:
				if _filter in str(tag).to_lower(): found = true
			if not found:
				continue

		_entries.append(entry)

	# Sort
	match _sort_mode:
		"alpha":
			_entries.sort_custom(func(a, b): return a["name"].to_lower() < b["name"].to_lower())
		"category":
			_entries.sort_custom(func(a, b): return a["category"] + a["name"] < b["category"] + b["name"])

	print("[LibraryRack] Loaded %d artifacts from %s (filter='%s')" % [_entries.size(), _collection_name, _filter])


# ═══════════════════════════════════════════════════════════════════
# BUILD WALL
# ═══════════════════════════════════════════════════════════════════

func _build_wall() -> void:
	# Teardown lives in _rebuild_now() and frees only what we own. This used to
	# queue_free() every child, which also took out grid-added label plates.
	var step := cube_size + gap
	var total_w := float(columns) * step - gap
	var x_offset := -total_w * 0.5 + cube_size * 0.5
	var max_slots := columns * rows

	for idx in range(max_slots):
		var col := idx % columns
		var row := idx / columns
		var x := x_offset + float(col) * step + 0.5
		var y := cube_size * 0.5 + float(row) * step - 0.5
		var z := 0.5

		var slot := Node3D.new()
		slot.name = "Slot_%d" % idx
		slot.position = Vector3(x, y, z)
		add_child(slot)
		_slot_nodes.append(slot)
		_owned.append(slot)

		if idx < _entries.size():
			var entry: Dictionary = _entries[idx]
			if entry.get("_empty", false):
				_build_empty_slot(slot)
			elif entry.get("_shader_path", "") != "":
				# Direct shader path — load .gdshader onto a 0.8 cube
				_build_shader_cube(slot, entry)
			else:
				_build_filled_slot(slot, entry)
		else:
			_build_empty_slot(slot)

	# Backplate
	_build_backplate()
	# Title
	_build_title()


func _build_filled_slot(slot: Node3D, entry: Dictionary) -> void:
	var scene_path: String = entry["scene"]
	var inner_size: float = cube_size * 0.8

	# For .tscn scenes — instantiate the actual artifact scaled down.
	# Only Node3D roots can live in a 3D shelf slot. Control/Node2D-rooted
	# artifacts (e.g. colorsheets.gd extends Control) would crash on the
	# Vector3 `scale` assignment, so they fall through to the placeholder cube.
	if scene_path.ends_with(".tscn") and ResourceLoader.exists(scene_path):
		var scene := load(scene_path) as PackedScene
		if scene:
			var instance := scene.instantiate()
			if instance is Node3D:
				instance.scale = Vector3.ONE * inner_size
				instance.name = "ArtifactInstance"
				slot.add_child(instance)
				return
			else:
				push_warning("[library_rack] '%s' root is %s, not Node3D — using placeholder cube" % [scene_path, instance.get_class()])
				instance.free()

	# For .gdshader — apply to a cube
	if scene_path.ends_with(".gdshader") and ResourceLoader.exists(scene_path):
		var cube := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3.ONE * inner_size
		cube.mesh = box
		cube.name = "ShaderCube"
		var shader := load(scene_path) as Shader
		if shader:
			var mat := ShaderMaterial.new()
			mat.shader = shader
			_try_set_param(mat, "emission_strength", 0.6)
			_try_set_param(mat, "u_resolution", Vector2(256, 256))
			cube.material_override = mat
		else:
			_apply_colored_cube(cube, entry)
		slot.add_child(cube)
		return

	# No scene — colored placeholder
	var cube := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * inner_size
	cube.mesh = box
	cube.name = "PlaceholderCube"
	_apply_colored_cube(cube, entry)
	slot.add_child(cube)

	# Collision on the slot itself
	var body := StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * cube_size
	col_shape.shape = shape
	body.add_child(col_shape)
	slot.add_child(body)

	# Labels
	if label_visible:
		var label := Label3D.new()
		label.text = entry["name"]
		label.font_size = 42
		label.pixel_size = 0.0018
		label.position = Vector3(0, -cube_size * 0.5 - 0.06, cube_size * 0.5 + 0.01)
		label.modulate = Color(0.85, 0.9, 0.85)
		label.outline_modulate = Color(0, 0, 0, 0.8)
		label.outline_size = 6
		slot.add_child(label)

		var cat_label := Label3D.new()
		cat_label.text = entry["category"]
		cat_label.font_size = 28
		cat_label.pixel_size = 0.0014
		cat_label.position = Vector3(0, -cube_size * 0.5 - 0.13, cube_size * 0.5 + 0.01)
		cat_label.modulate = Color(0.4, 0.7, 0.5, 0.6)
		cat_label.outline_modulate = Color(0, 0, 0, 0.5)
		cat_label.outline_size = 4
		slot.add_child(cat_label)


func _build_shader_cube(slot: Node3D, entry: Dictionary) -> void:
	# 0.8 BoxMesh cube with the .gdshader applied directly
	var inner_size: float = cube_size * 0.8
	var shader_path: String = entry.get("_shader_path", "")

	var cube := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * inner_size
	cube.mesh = box
	cube.name = "ShaderCube"

	if shader_path != "" and ResourceLoader.exists(shader_path):
		var shader := load(shader_path) as Shader
		if shader:
			var mat := ShaderMaterial.new()
			mat.shader = shader
			_try_set_param(mat, "emission_strength", 0.6)
			_try_set_param(mat, "u_resolution", Vector2(256, 256))
			cube.material_override = mat
			print("[LibraryRack] Shader cube: %s" % shader_path.get_file())
		else:
			_apply_colored_cube(cube, entry)
	else:
		_apply_colored_cube(cube, entry)

	slot.add_child(cube)

	# Label
	if label_visible:
		var label := Label3D.new()
		label.text = entry["name"]
		label.font_size = 42
		label.pixel_size = 0.0018
		label.position = Vector3(0, -cube_size * 0.5 - 0.06, cube_size * 0.5 + 0.01)
		label.modulate = Color(0.85, 0.9, 0.85)
		label.outline_modulate = Color(0, 0, 0, 0.8)
		label.outline_size = 6
		slot.add_child(label)


func _build_empty_slot(slot: Node3D) -> void:
	# Grid cube at full size (1.0) with the grid shader — matches the grid system
	var cube := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * cube_size  # 1.0 full cell
	cube.mesh = box
	cube.name = "GridCube"

	# Apply the grid shader
	var grid_shader := load("res://commons/resourses/shaders/SimpleGrid.gdshader") as Shader
	if grid_shader:
		var mat := ShaderMaterial.new()
		mat.shader = grid_shader
		mat.set_shader_parameter("modelColor", Color(0.0, 0.0, 0.0, 1.0))
		mat.set_shader_parameter("emissionColor", Color(0.9, 0.9, 0.85, 1.0))
		mat.set_shader_parameter("wireframeColor", Color(0.9, 0.9, 0.85, 1.0))
		mat.set_shader_parameter("emission_strength", 1.5)
		cube.material_override = mat
	else:
		# Fallback if shader not found
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.18, 0.18, 0.22)
		mat.roughness = 0.7
		cube.material_override = mat

	slot.add_child(cube)

	# Collision
	var body := StaticBody3D.new()
	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * cube_size
	col_shape.shape = shape
	body.add_child(col_shape)
	cube.add_child(body)


func _apply_colored_cube(mesh: MeshInstance3D, entry: Dictionary) -> void:
	# Generate a deterministic color from the artifact name
	var h := float(hash(entry["name"]) % 360) / 360.0
	var col := Color.from_hsv(h, 0.5, 0.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col * 0.5
	mat.emission_energy_multiplier = 0.4
	mat.roughness = 0.3
	mesh.material_override = mat


func _build_backplate() -> void:
	# No backplate — shelf is open from both sides
	pass


func _build_title() -> void:
	var step := cube_size + gap
	var total_h := float(rows) * step
	var display_title: String = _title_override if _title_override != "" else _collection_name.to_upper() + " LIBRARY"
	var title := Label3D.new()
	title.text = display_title
	title.font_size = 64
	title.pixel_size = 0.0028
	title.position = Vector3(0, total_h + 0.12, cube_size * 0.5 + 0.01)
	title.modulate = Color(0.4, 1.0, 0.6)
	title.outline_modulate = Color(0, 0, 0, 0.9)
	title.outline_size = 10
	title.name = "Title"
	add_child(title)

	# Subtitle: count
	var sub := Label3D.new()
	sub.text = "%d / %d slots" % [_entries.size(), columns * rows]
	sub.font_size = 36
	sub.pixel_size = 0.002
	sub.position = Vector3(0, total_h + 0.02, cube_size * 0.5 + 0.01)
	sub.modulate = Color(0.4, 0.6, 0.5, 0.6)
	sub.outline_modulate = Color(0, 0, 0, 0.5)
	sub.outline_size = 6
	sub.name = "Subtitle"
	add_child(sub)


func _try_set_param(mat: ShaderMaterial, param_name: String, value: Variant) -> void:
	if mat.shader:
		for uniform in mat.shader.get_shader_uniform_list():
			if uniform["name"] == param_name:
				mat.set_shader_parameter(param_name, value)
				return


## Extract the first ShaderMaterial from a scene tree
func _extract_shader_material(node: Node) -> Material:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.material_override is ShaderMaterial:
			return mi.material_override.duplicate()
		if mi.mesh and mi.mesh.get_surface_count() > 0:
			var surf_mat: Material = mi.mesh.surface_get_material(0)
			if surf_mat is ShaderMaterial:
				return surf_mat.duplicate()
	for child in node.get_children():
		var result := _extract_shader_material(child)
		if result:
			return result
	return null
