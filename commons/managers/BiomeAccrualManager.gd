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
# Phase 5: single population-budget chokepoint. Injected into every layer's
# ctx as "budget_scale"; each spawn layer multiplies its target count by it.
# <0 = unset (resolve to per-map override, else 1.0). The future
# performance_budget epic computes this from frame-time / draw-call headroom;
# for now it is a 1.0 stub + a manual knob (set_budget_scale / per-map override).
var _budget_scale: float = -1.0


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

	# ── Per-map overrides ─────────────────────────────────────────────
	# A map's settings.biome_overrides lets it ADD / REMOVE / CHANGE the
	# biome on top of its sequence default:
	#   { "stage_order": 12, "disable": ["paradox_zones"],
	#     "params": { "lsystem_trees": { "spawn_density": 0.2 } },
	#     "add": [ { "kind": "flora_spawn", "params": {...} } ] }
	# The sequence provides the default; the map overrides it. A debug
	# set_stage_override (the scrubber) still wins over stage_order.
	var overrides: Dictionary = context.get("biome_overrides", {})
	if not (overrides is Dictionary):
		overrides = {}
	var override_disable: Dictionary = {}
	for k in overrides.get("disable", []):
		override_disable[str(k)] = true
	var override_params: Dictionary = overrides.get("params", {}) if (overrides.get("params") is Dictionary) else {}

	# Phase 5: resolve the single population budget once. Every layer ctx gets
	# it as "budget_scale"; spawn layers multiply their target count by it.
	var budget_scale: float = _resolve_budget_scale(overrides)

	var target_order: int = _current_stage_order()
	if _stage_override < 0 and overrides.has("stage_order"):
		target_order = int(overrides["stage_order"])
	print("🌿 BiomeAccrual.apply() START — map=%s stage_order=%d contributions=%d overrides=%s" % [
		str(context.get("map_name", "?")), target_order, _contributions.size(),
		"yes" if not overrides.is_empty() else "no"
	])
	if target_order == 0:
		push_warning("BiomeAccrual: stage_order=0 — no layers will apply. Check EcosystemManager.sync_to_map for this map.")
	var applied: Array[String] = []
	var skipped: Array[String] = []

	# Lab-mode detection: if any reachable entry has "lab_only": true,
	# the stack is replaced rather than accrued. The biome_lab sequence
	# (order 99) uses this so Biome_Spine and Biome_Zoo show only the
	# painted-cell dispatcher's output, not all 19 spine layers stacked
	# on top. Without this, painting on a stage_order=99 map would
	# render every prior accrual layer as well, drowning the dispatcher.
	var lab_only_active: bool = false
	for entry in _contributions:
		var entry_order: int = int(entry.get("order", 0))
		if entry_order > target_order:
			break
		if bool(entry.get("lab_only", false)):
			lab_only_active = true
			break

	for entry in _contributions:
		var order: int = int(entry.get("order", 0))
		if order > target_order:
			break
		var kind: String = str(entry.get("kind", ""))
		# In lab mode, only apply the lab_only-flagged entries themselves —
		# EXCEPT layers flagged "always": true (e.g. ground_ring), which are
		# foundational and must render in every mode. Without this, the lab
		# maps (Biome_Spine / Biome_Zoo) would lose the surrounding ground +
		# fog the GridSystem ring used to draw unconditionally.
		if lab_only_active and not bool(entry.get("lab_only", false)) and not bool(entry.get("always", false)):
			skipped.append(kind + "(lab_only_active)")
			continue
		if _disabled_kinds.has(kind):
			skipped.append(kind + "(disabled)")
			continue
		if override_disable.has(kind):
			skipped.append(kind + "(map_override)")
			continue
		if not _layer_scripts.has(kind):
			skipped.append(kind + "(unimplemented)")
			continue

		var layer_node: Node3D = Node3D.new()
		layer_node.name = "Layer_%02d_%s" % [order, kind]
		layer_node.set_script(_layer_scripts[kind])
		accrual.add_child(layer_node)

		var layer_ctx := context.duplicate()
		# Merge per-map param overrides over the sequence-default params.
		var merged_params: Dictionary = (entry.get("params", {}) as Dictionary).duplicate(true)
		if override_params.has(kind) and override_params[kind] is Dictionary:
			merged_params.merge(override_params[kind], true)
		layer_ctx["params"] = merged_params
		layer_ctx["order"] = order
		layer_ctx["seq"] = entry.get("seq", "")
		layer_ctx["accrual_root"] = accrual  # Later layers can find/modify prior layers
		layer_ctx["budget_scale"] = budget_scale  # Phase 5 population budget
		if layer_node.has_method("apply"):
			layer_node.call("apply", layer_ctx)
		applied.append(kind)

	# ── Per-map ADD: extra layers beyond the sequence default ─────────
	for add_entry in overrides.get("add", []):
		if not (add_entry is Dictionary):
			continue
		var ak: String = str(add_entry.get("kind", ""))
		if ak == "" or not _layer_scripts.has(ak):
			skipped.append(str(ak) + "(add:unavailable)")
			continue
		var an: Node3D = Node3D.new()
		an.name = "Layer_ADD_%s" % ak
		an.set_script(_layer_scripts[ak])
		accrual.add_child(an)
		var actx := context.duplicate()
		actx["params"] = add_entry.get("params", {})
		actx["order"] = target_order
		actx["seq"] = "map_add"
		actx["accrual_root"] = accrual
		actx["budget_scale"] = budget_scale  # Phase 5 population budget
		if an.has_method("apply"):
			an.call("apply", actx)
		applied.append(ak + "(added)")

	print("BiomeAccrual: stage=%d budget=%.2f applied=%s skipped=%s" % [target_order, budget_scale, str(applied), str(skipped)])
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
# Population budget (Phase 5)
# ─────────────────────────────────────────────────────────────

## Debug / runtime knob for the scrubber and tests. >=0 forces that scale;
## <0 returns to "unset" (resolve from per-map override, else 1.0).
func set_budget_scale(s: float) -> void:
	_budget_scale = s

func get_budget_scale() -> float:
	return _budget_scale

## The single chokepoint. Phase 5 stub: 1.0 unless a debug override
## (set_budget_scale) or a per-map override (settings.biome_overrides.budget_scale)
## sets it. The future performance_budget epic replaces the body with a
## frame-time / draw-call headroom computation; every spawn layer already reads
## the result via ctx.budget_scale, so that epic touches only this function.
func _resolve_budget_scale(overrides: Dictionary) -> float:
	if _budget_scale >= 0.0:
		return _budget_scale
	if overrides.has("budget_scale"):
		return maxf(0.0, float(overrides["budget_scale"]))
	return 1.0

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
