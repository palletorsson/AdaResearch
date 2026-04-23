# BiomeAccrualManager.gd
# Autoload. Replaces the "biome = foliage ring" model with an accrual stack.
#
# Each sequence contributes ONE layer to the biome (see commons/biome_layers/
# biome_contributions.json). Layers accrue in order: the biome at stage N is the
# sum of layers 1..N. Before seq 8 the biome is NOT a nature biome — it is
# abstract mathematical forms floating in void (Kusama).
#
# On map load, GridSystem calls apply(grid_root, context) and this manager:
#   1. Reads EcosystemManager.get_current_stage_order() to know how far to go.
#   2. Walks the contributions table, instantiating each layer's node in order.
#   3. Each layer reads `context` (grid_dims, grid_center, cube_size, rng seed)
#      and spawns or animates accordingly.
#
# Layer scripts live at commons/biome_layers/<kind>.gd. A layer is a Node3D
# with an apply(context: Dictionary) method. A layer not yet implemented is
# skipped silently so the stack can grow incrementally.
#
# Debug knobs:
#   BiomeAccrualManager.set_stage_override(order)   — snapshot at any stage
#   BiomeAccrualManager.enable_layer(kind, bool)    — toggle single layer
#   BiomeAccrualManager.reset_overrides()           — back to progression

extends Node

const CONTRIBUTIONS_FILE := "res://commons/biome_layers/biome_contributions.json"
const LAYERS_DIR := "res://commons/biome_layers/"

var _contributions: Array = []    # Array of Dictionary — ordered by .order
var _layer_scripts: Dictionary = {}  # kind -> loaded GDScript
var _stage_override: int = -1
var _disabled_kinds: Dictionary = {}


func _ready() -> void:
	_load_contributions()
	_preload_layer_scripts()
	print("BiomeAccrualManager: Loaded %d contributions, %d layer scripts available" % [
		_contributions.size(), _layer_scripts.size()
	])


# ─────────────────────────────────────────────────────────────
# Public API — applied by GridSystem
# ─────────────────────────────────────────────────────────────

## Apply all contributions up to the current stage order to grid_root.
## context: { grid_dims: Vector3i, grid_center: Vector3, cube_size: float,
##            rng_seed: int, map_name: String }
func apply(grid_root: Node, context: Dictionary) -> Node:
	# Remove any prior accrual node
	var existing = grid_root.get_node_or_null("BiomeAccrual")
	if existing:
		existing.queue_free()

	var accrual := Node3D.new()
	accrual.name = "BiomeAccrual"
	grid_root.add_child(accrual)

	var target_order: int = _current_stage_order()
	print("🌿 BiomeAccrual.apply() START — map=%s stage_order=%d contributions=%d" % [
		str(context.get("map_name", "?")), target_order, _contributions.size()
	])
	if target_order == 0:
		push_warning("BiomeAccrual: stage_order=0 — no layers will apply. Check EcosystemManager.sync_to_map for this map.")
	var applied: Array[String] = []
	var skipped: Array[String] = []

	for entry in _contributions:
		var order: int = int(entry.get("order", 0))
		if order > target_order:
			break
		var kind: String = str(entry.get("kind", ""))
		if _disabled_kinds.has(kind):
			skipped.append(kind + "(disabled)")
			continue
		if not _layer_scripts.has(kind):
			skipped.append(kind + "(unimplemented)")
			continue

		var layer_node: Node3D = Node3D.new()
		layer_node.name = "Layer_%02d_%s" % [order, kind]
		layer_node.set_script(_layer_scripts[kind])
		accrual.add_child(layer_node)

		var layer_ctx := context.duplicate()
		layer_ctx["params"] = entry.get("params", {})
		layer_ctx["order"] = order
		layer_ctx["seq"] = entry.get("seq", "")
		layer_ctx["accrual_root"] = accrual  # Later layers can find/modify prior layers
		if layer_node.has_method("apply"):
			layer_node.call("apply", layer_ctx)
		applied.append(kind)

	print("BiomeAccrual: stage=%d applied=%s skipped=%s" % [target_order, str(applied), str(skipped)])
	return accrual


## Force the stack to render at a specific stage order (ignoring progression).
## Pass -1 to restore progression-driven rendering.
func set_stage_override(order: int) -> void:
	_stage_override = order

func reset_overrides() -> void:
	_stage_override = -1
	_disabled_kinds.clear()

func enable_layer(kind: String, enabled: bool) -> void:
	if enabled:
		_disabled_kinds.erase(kind)
	else:
		_disabled_kinds[kind] = true


# ─────────────────────────────────────────────────────────────
# Introspection
# ─────────────────────────────────────────────────────────────

func get_contributions() -> Array:
	return _contributions

func get_active_kinds() -> Array[String]:
	var result: Array[String] = []
	var target: int = _current_stage_order()
	for entry in _contributions:
		if int(entry.get("order", 0)) > target:
			break
		result.append(str(entry.get("kind", "")))
	return result


# ─────────────────────────────────────────────────────────────
# Internal
# ─────────────────────────────────────────────────────────────

func _current_stage_order() -> int:
	if _stage_override >= 0:
		return _stage_override
	var eco = get_node_or_null("/root/EcosystemManager")
	if eco and eco.has_method("get_current_stage_order"):
		return int(eco.get_current_stage_order())
	return 0

func _load_contributions() -> void:
	if not FileAccess.file_exists(CONTRIBUTIONS_FILE):
		push_error("BiomeAccrualManager: Not found: " + CONTRIBUTIONS_FILE)
		return
	var file := FileAccess.open(CONTRIBUTIONS_FILE, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK or not json.data is Dictionary:
		push_error("BiomeAccrualManager: Parse error")
		return
	var raw: Array = json.data.get("sequences", [])
	_contributions = raw.duplicate()
	_contributions.sort_custom(func(a, b): return int(a.get("order", 0)) < int(b.get("order", 0)))

## Load one layer script per `kind` declared in biome_contributions.json.
## We explicitly `load(path)` each known kind instead of scanning the
## directory — DirAccess.list_dir_begin() over res:// returns nothing in
## exported VR builds (PCK-packed resources don't enumerate). With explicit
## paths the loads go through the ResourceLoader which resolves from the PCK.
func _preload_layer_scripts() -> void:
	_layer_scripts.clear()
	var seen: Dictionary = {}
	for entry in _contributions:
		var kind: String = str(entry.get("kind", ""))
		if kind == "" or seen.has(kind):
			continue
		seen[kind] = true
		var script_path: String = LAYERS_DIR + kind + ".gd"
		# ResourceLoader.exists is packaging-safe. load() with a non-existent
		# path prints a warning; exists() avoids that churn for unimplemented kinds.
		if not ResourceLoader.exists(script_path):
			continue
		var script = load(script_path)
		if script:
			_layer_scripts[kind] = script
