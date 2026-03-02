## Orchestrator: loads Panel Layout JSON + Data JSON,
## creates the appropriate data model, spawns VRPanelInstances in a row.
##
## Supports two page types:
##   "loom_simulator"  → DraftDataStore (binary matrices)
##   "pattern_maker"   → domain color data injected into color_grid metadata
##
## Attach this to a Node3D in your scene. Set the export paths
## to JSON files, then call load_panels() or let _ready() auto-load.
class_name PanelBridgeLoader
extends Node3D

# ── Configuration ───────────────────────────────────────────────

## Path to the Panel Layout JSON file (res:// or user://).
@export_file("*.json") var layout_json_path: String = ""

## Path to the Draft Data JSON file (res:// or user://).
@export_file("*.json") var data_json_path: String = ""

## Auto-load on ready?
@export var auto_load: bool = true

## Arc layout parameters
@export_group("Arc Layout")

## Distance from origin to panel center (meters).
@export var arc_radius: float = 0.65

## Height of the arc center (meters, from XR origin floor).
@export var arc_height: float = 1.4

## Gap between adjacent panels on the arc (meters).
@export var panel_gap: float = 0.02

# ── State ───────────────────────────────────────────────────────

var data_store: DraftDataStore
var panel_instances: Array[VRPanelInstance] = []

# ── Lifecycle ───────────────────────────────────────────────────

func _ready() -> void:
	if auto_load and layout_json_path != "":
		load_panels()


# ── Public API ──────────────────────────────────────────────────

## Load the Panel Layout JSON and (optionally) Data JSON,
## then build and position all VR panels.
func load_panels() -> void:
	# Clean up any existing panels
	_clear_panels()

	# Load layout JSON
	var layout := _load_json(layout_json_path)
	if layout.is_empty():
		push_error("PanelBridgeLoader: Failed to load layout JSON from '%s'" % layout_json_path)
		return

	# Load data JSON (optional, used differently per page type)
	var data := {}
	if data_json_path != "":
		data = _load_json(data_json_path)
		if data.is_empty():
			push_warning("PanelBridgeLoader: No data JSON loaded, using defaults")

	# Branch on page type
	var page_type: String = layout.get("page", "loom_simulator")

	match page_type:
		"pattern_maker":
			_load_pattern_maker(layout, data)
		_:
			_load_loom(layout, data)

	# Position panels in row layout
	_layout_arc()

	# Defer wiring: wait for VRPanelInstance content injection (which awaits 1 frame)
	_wire_operations.call_deferred()

	print("PanelBridgeLoader: Loaded %d panels (%s) from '%s'" % [
		panel_instances.size(), page_type, layout_json_path
	])


## Load panels for loom_simulator page — uses DraftDataStore.
func _load_loom(layout: Dictionary, data: Dictionary) -> void:
	data_store = DraftDataStore.new()

	if not data.is_empty():
		data_store.load_from_dict(data)
	else:
		# Try to infer dimensions from layout JSON loom info
		var loom_info: Dictionary = layout.get("loom", {})
		if loom_info.get("shafts", 0) > 0:
			data_store.resize(
				24, 24,
				int(loom_info.get("shafts", 4)),
				int(loom_info.get("treadles", 6))
			)

	var panels: Array = layout.get("panels", [])
	for panel_def in panels:
		_spawn_panel(panel_def, data_store)


## Load panels for pattern_maker page — injects domain data into color_grid metadata.
func _load_pattern_maker(layout: Dictionary, data: Dictionary) -> void:
	# Extract domain data from data JSON
	var domain_info: Dictionary = data.get("domain", {})
	var domain_data: Array = domain_info.get("data", [])
	var palette_info: Dictionary = data.get("palette", {})
	var palette_colors: Array = palette_info.get("colors", [])

	# Mutate the layout panels in-place: inject domain data into matching elements
	var panels: Array = layout.get("panels", [])
	for panel_def in panels:
		var elements: Array = panel_def.get("elements", [])
		for elem in elements:
			var elem_type: String = elem.get("type", "")
			var metadata: Dictionary = elem.get("metadata", {})

			if elem_type == "color_grid":
				# Inject domain data into the editable domain_editor element
				var data_path: String = metadata.get("data_path", "")
				if data_path == "domain" and not domain_data.is_empty():
					metadata["data"] = domain_data
				# Inject palette from data JSON if not already in metadata
				if palette_colors.size() > 0 and not metadata.has("palette_colors"):
					metadata["palette_colors"] = palette_colors

	# data_store stays null — pattern maker doesn't use DraftDataStore
	for panel_def in panels:
		_spawn_panel(panel_def, null)


## Spawn a single VRPanelInstance from a panel definition.
func _spawn_panel(panel_def: Dictionary, store = null) -> void:
	var instance := VRPanelInstance.new()
	instance.name = "Panel_" + str(panel_def.get("id", "unknown"))
	add_child(instance)
	panel_instances.append(instance)
	instance.build(panel_def, store)


## Reload panels from current paths.
func reload() -> void:
	load_panels()


## Get the data store (loom pages only; returns null for pattern_maker).
func get_data_store() -> DraftDataStore:
	return data_store


# ── Cross-panel wiring ───────────────────────────────────────────

## Wire OperationsBarWidgets to their targets across panels.
## For pattern_maker: connects to ColorGridWidget.
## For loom: connects to DraftDataStore.
## Called deferred after all panel content is injected.
func _wire_operations() -> void:
	# Wait one extra frame to ensure all VRPanelInstance awaits have completed
	await get_tree().process_frame

	var roots: Array = []
	for inst in panel_instances:
		if is_instance_valid(inst):
			var root := inst.get_panel_root()
			if root:
				roots.append(root)

	if roots.is_empty():
		return

	# Wire pattern maker targets (ColorGridWidget)
	PanelContentBuilder.wire_operations_to_target(roots)

	# Wire loom targets (DraftDataStore) — if we have a data_store
	if data_store:
		for root in roots:
			_wire_data_store_in_tree(root)
		print("PanelBridgeLoader: Wired operations bars to DraftDataStore across %d panels" % roots.size())
	else:
		print("PanelBridgeLoader: Wired operations bars across %d panels" % roots.size())


## Recursively find OperationsBarWidgets and set their data_store reference.
func _wire_data_store_in_tree(node: Node) -> void:
	if node is OperationsBarWidget:
		(node as OperationsBarWidget).data_store = data_store
	for child in node.get_children():
		_wire_data_store_in_tree(child)


# ── Arc layout ──────────────────────────────────────────────────

func _layout_arc() -> void:
	if panel_instances.is_empty():
		return

	# Build role → instance lookup
	var by_role := {}
	for inst in panel_instances:
		var role: String = inst.panel_def.get("role", "center")
		by_role[role] = inst

	# Center panel at X=0
	var center_inst = by_role.get("center", panel_instances[0])
	var center_w: float = center_inst.panel_def.get("width_m", 0.5)
	_place_panel(center_inst, 0.0)

	# Left panel: flush to the left of center with a gap
	if by_role.has("left"):
		var left_inst = by_role["left"]
		var left_w: float = left_inst.panel_def.get("width_m", 0.35)
		var x := -(center_w * 0.5 + panel_gap + left_w * 0.5)
		_place_panel(left_inst, x)

	# Right panel: flush to the right of center with a gap
	if by_role.has("right"):
		var right_inst = by_role["right"]
		var right_w: float = right_inst.panel_def.get("width_m", 0.40)
		var x := center_w * 0.5 + panel_gap + right_w * 0.5
		_place_panel(right_inst, x)


func _place_panel(inst: Node3D, x_offset: float) -> void:
	inst.position = Vector3(x_offset, arc_height, -arc_radius)
	inst.rotation = Vector3.ZERO


# ── JSON loading ────────────────────────────────────────────────

func _load_json(path: String) -> Dictionary:
	if path.is_empty():
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("PanelBridgeLoader: Cannot open file '%s' — error %d" % [path, FileAccess.get_open_error()])
		return {}

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_error("PanelBridgeLoader: JSON parse error in '%s' at line %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}

	if json.data is Dictionary:
		return json.data
	else:
		push_error("PanelBridgeLoader: Expected Dictionary at root of '%s'" % path)
		return {}


# ── Cleanup ─────────────────────────────────────────────────────

func _clear_panels() -> void:
	for instance in panel_instances:
		if is_instance_valid(instance):
			instance.queue_free()
	panel_instances.clear()
	data_store = null
