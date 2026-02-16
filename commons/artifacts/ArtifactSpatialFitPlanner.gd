# ArtifactSpatialFitPlanner.gd
# Scores and ranks artifact placements using directional identity contracts.
# Also provides a simple greedy auto-layout pass for map prototyping workflows.
#
# Quick usage:
#   var planner := ArtifactSpatialFitPlanner.new()
#   planner.load_contracts()
#   var result := planner.suggest_auto_layout(
#   	["infokiosk", "code_display", "dark_sphere"],
#   	25,
#   	25,
#   	{"spawn_position_2d": [0, 0], "sequence_id": "tutorial"}
#   )
#   var interactables_layer := planner.placements_to_interactable_layer(result.placements, 25, 25)

class_name ArtifactSpatialFitPlanner
extends RefCounted

const DEFAULT_CONTRACTS_PATH := "res://commons/artifacts/artifact_spatial_contracts.json"
const CARDINAL_ROTATIONS := [0.0, 90.0, 180.0, 270.0]

var _contracts_path: String = DEFAULT_CONTRACTS_PATH
var _loaded: bool = false
var _raw_data: Dictionary = {}
var _contracts: Dictionary = {}
var _default_contract: Dictionary = {}
var _directional_profiles: Dictionary = {}


func load_contracts(path: String = DEFAULT_CONTRACTS_PATH) -> bool:
	_contracts_path = path
	_loaded = false
	_raw_data.clear()
	_contracts.clear()
	_default_contract.clear()
	_directional_profiles.clear()

	if not FileAccess.file_exists(path):
		push_error("ArtifactSpatialFitPlanner: Contracts file not found: %s" % path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("ArtifactSpatialFitPlanner: Failed to open contracts file: %s" % path)
		return false

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_text) != OK:
		push_error("ArtifactSpatialFitPlanner: Failed to parse contracts JSON: %s" % json.get_error_message())
		return false

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("ArtifactSpatialFitPlanner: Contracts root must be a Dictionary")
		return false

	_raw_data = json.data
	_contracts = _raw_data.get("artifact_contracts", {})
	_default_contract = _raw_data.get("default_contract", {})
	_directional_profiles = _raw_data.get("directional_profiles", {})
	_loaded = true
	return true


func clear_cache() -> void:
	_loaded = false
	_raw_data.clear()
	_contracts.clear()
	_default_contract.clear()
	_directional_profiles.clear()


func get_contract_path() -> String:
	return _contracts_path


func get_available_contract_names() -> Array[String]:
	if not _ensure_loaded():
		return []
	var names: Array[String] = []
	for key in _contracts.keys():
		names.append(str(key))
	names.sort()
	return names


func get_contract(lookup_name: String) -> Dictionary:
	if not _ensure_loaded():
		return {}
	var specific: Dictionary = _contracts.get(lookup_name, {})
	return _merge_contracts(_default_contract, specific)


func get_directional_profile(profile_id: String) -> Dictionary:
	if not _ensure_loaded():
		return {}
	return _directional_profiles.get(profile_id, {})


func score_candidate(lookup_name: String, candidate: Dictionary, context: Dictionary = {}) -> Dictionary:
	if not _ensure_loaded():
		return {
			"lookup_name": lookup_name,
			"score": 0.0,
			"raw_score": 0.0,
			"breakdown": {},
			"reasons": ["Contracts not loaded."],
			"warnings": ["Contracts not loaded."],
			"contract": {}
		}

	var contract := get_contract(lookup_name)
	var breakdown := {}
	var reasons: Array[String] = []
	var warnings: Array[String] = []

	var staging_eval := _score_staging(contract, candidate)
	breakdown["staging"] = staging_eval.get("score", 0.0)
	reasons.append(str(staging_eval.get("reason", "")))

	var enclosure_eval := _score_enclosure(contract, candidate)
	breakdown["enclosure"] = enclosure_eval.get("score", 0.0)
	reasons.append(str(enclosure_eval.get("reason", "")))

	var clearance_eval := _score_clearance(contract, candidate, context)
	breakdown["clearance"] = clearance_eval.get("score", 0.0)
	reasons.append(str(clearance_eval.get("reason", "")))
	if clearance_eval.has("warning"):
		warnings.append(str(clearance_eval.get("warning", "")))

	var view_eval := _score_view_distance(contract, candidate, context)
	breakdown["view_distance"] = view_eval.get("score", 0.0)
	reasons.append(str(view_eval.get("reason", "")))

	var direction_eval := _score_directionality(contract, candidate, context)
	breakdown["directionality"] = direction_eval.get("score", 0.0)
	reasons.append(str(direction_eval.get("reason", "")))
	if direction_eval.has("warning"):
		warnings.append(str(direction_eval.get("warning", "")))

	var sequence_eval := _score_sequence_affinity(contract, context)
	breakdown["sequence_bonus"] = sequence_eval.get("score", 0.0)
	if sequence_eval.get("score", 0.0) > 0.0:
		reasons.append(str(sequence_eval.get("reason", "")))

	var raw_score: float = 0.0
	for key in breakdown.keys():
		raw_score += float(breakdown.get(key, 0.0))

	var score := clamp(raw_score, 0.0, 100.0)
	_reasons_compact(reasons)
	_reasons_compact(warnings)

	return {
		"lookup_name": lookup_name,
		"score": score,
		"raw_score": raw_score,
		"breakdown": breakdown,
		"reasons": reasons,
		"warnings": warnings,
		"contract": contract
	}


func rank_candidates(lookup_name: String, candidates: Array, context: Dictionary = {}) -> Array:
	var scored: Array = []
	var index := 0
	for candidate_variant in candidates:
		if typeof(candidate_variant) != TYPE_DICTIONARY:
			index += 1
			continue
		var candidate: Dictionary = (candidate_variant as Dictionary).duplicate(true)
		var result := score_candidate(lookup_name, candidate, context)
		result["candidate"] = candidate
		result["candidate_index"] = index
		scored.append(result)
		index += 1

	scored.sort_custom(func(a, b): return float((a as Dictionary).get("score", 0.0)) > float((b as Dictionary).get("score", 0.0)))
	return scored


func generate_grid_candidates(map_width: int, map_depth: int, options: Dictionary = {}) -> Array:
	var candidates: Array = []
	if map_width <= 0 or map_depth <= 0:
		return candidates

	var margin := max(0, int(options.get("margin_cells", 1)))
	var stride := max(1, int(options.get("stride_cells", 1)))
	var default_staging := str(options.get("default_staging", "table")).strip_edges().to_lower()
	var default_enclosure := str(options.get("default_enclosure", "open")).strip_edges().to_lower()
	var default_clearance := float(options.get("default_clearance_radius_cells", 2.0))

	var default_spawn := Vector2(floor(float(map_width) * 0.5), floor(float(map_depth) * 0.5))
	var spawn_position := _extract_position_2d(options.get("spawn_position_2d", default_spawn), default_spawn)

	var x_start := min(max(0, margin), map_width - 1)
	var z_start := min(max(0, margin), map_depth - 1)
	var x_end := max(x_start + 1, map_width - margin)
	var z_end := max(z_start + 1, map_depth - margin)

	for z in range(z_start, z_end, stride):
		for x in range(x_start, x_end, stride):
			var pos := Vector2(x, z)
			candidates.append({
				"position_2d": [x, z],
				"rotation_y": 0.0,
				"staging": default_staging,
				"enclosure": default_enclosure,
				"clearance_radius_cells": default_clearance,
				"view_distance_m": pos.distance_to(spawn_position)
			})
	return candidates


func suggest_auto_layout(artifact_lookup_names: Array, map_width: int, map_depth: int, context: Dictionary = {}) -> Dictionary:
	if not _ensure_loaded():
		return {
			"placements": [],
			"unplaced": artifact_lookup_names.duplicate(),
			"candidate_count": 0,
			"status": "contracts_not_loaded"
		}

	var candidate_pool: Array = []
	if context.has("candidates") and context.get("candidates") is Array:
		candidate_pool = (context.get("candidates") as Array).duplicate(true)
	else:
		var candidate_options := context.get("candidate_options", {})
		candidate_pool = generate_grid_candidates(map_width, map_depth, candidate_options)

	var placements: Array = []
	var unplaced: Array = []
	var global_min_spacing := float(context.get("min_inter_artifact_spacing_cells", 1.5))
	var default_spawn := Vector2(floor(float(map_width) * 0.5), floor(float(map_depth) * 0.5))
	var spawn_position := _extract_position_2d(context.get("spawn_position_2d", default_spawn), default_spawn)

	for lookup_variant in artifact_lookup_names:
		var lookup_name := str(lookup_variant).strip_edges()
		if lookup_name.is_empty():
			continue
		if candidate_pool.is_empty():
			unplaced.append(lookup_name)
			continue

		var contract := get_contract(lookup_name)
		var required_spacing := max(global_min_spacing, float(contract.get("clearance_radius_cells", global_min_spacing)))

		var viable_candidates: Array = []
		for candidate_variant in candidate_pool:
			if typeof(candidate_variant) != TYPE_DICTIONARY:
				continue
			var candidate: Dictionary = (candidate_variant as Dictionary).duplicate(true)
			var pos := _extract_position_2d(candidate.get("position_2d", Vector2.ZERO), Vector2.ZERO)
			if not _has_min_spacing(pos, placements, required_spacing):
				continue
			if not candidate.has("rotation_y"):
				candidate["rotation_y"] = _best_cardinal_rotation_for_contract(pos, spawn_position, contract)
			viable_candidates.append(candidate)

		if viable_candidates.is_empty():
			unplaced.append(lookup_name)
			continue

		var ranked := rank_candidates(lookup_name, viable_candidates, context)
		if ranked.is_empty():
			unplaced.append(lookup_name)
			continue

		var best: Dictionary = ranked[0]
		var best_candidate: Dictionary = (best.get("candidate", {}) as Dictionary).duplicate(true)
		var best_pos := _extract_position_2d(best_candidate.get("position_2d", Vector2.ZERO), Vector2.ZERO)
		var token := _build_interactable_token(lookup_name, best_candidate)

		placements.append({
			"lookup_name": lookup_name,
			"position_2d": [int(round(best_pos.x)), int(round(best_pos.y))],
			"rotation_y": float(best_candidate.get("rotation_y", 0.0)),
			"score": float(best.get("score", 0.0)),
			"breakdown": best.get("breakdown", {}),
			"token": token,
			"reasons": best.get("reasons", [])
		})

		candidate_pool = _remove_nearby_candidates(candidate_pool, best_pos, required_spacing)

	return {
		"placements": placements,
		"unplaced": unplaced,
		"candidate_count": candidate_pool.size(),
		"status": "ok"
	}


func placements_to_interactable_layer(placements: Array, width: int, depth: int) -> Array:
	var layer: Array = []
	for z in range(depth):
		var row: Array = []
		for _x in range(width):
			row.append(" ")
		layer.append(row)

	for placement_variant in placements:
		if typeof(placement_variant) != TYPE_DICTIONARY:
			continue
		var placement: Dictionary = placement_variant
		var pos := _extract_position_2d(placement.get("position_2d", Vector2.ZERO), Vector2.ZERO)
		var x := int(round(pos.x))
		var z := int(round(pos.y))
		if x < 0 or z < 0 or x >= width or z >= depth:
			continue

		var token := str(placement.get("token", "")).strip_edges()
		if token.is_empty():
			var lookup_name := str(placement.get("lookup_name", "")).strip_edges()
			if lookup_name.is_empty():
				continue
			token = _build_interactable_token(lookup_name, placement)
		layer[z][x] = token

	return layer


func _score_staging(contract: Dictionary, candidate: Dictionary) -> Dictionary:
	var preferred := _to_string_array(contract.get("staging_preference", []))
	var actual := str(candidate.get("staging", "")).strip_edges().to_lower()

	if preferred.is_empty():
		return {"score": 15.0, "reason": "No staging preference set in contract."}
	if actual.is_empty():
		return {"score": 10.0, "reason": "Candidate has no staging value; neutral score."}
	if preferred.has(actual):
		return {"score": 25.0, "reason": "Staging matches contract preference."}

	for desired in preferred:
		if _is_staging_compatible(desired, actual):
			return {"score": 16.0, "reason": "Staging is compatible with contract preference."}

	return {"score": 4.0, "reason": "Staging conflicts with contract preference."}


func _score_enclosure(contract: Dictionary, candidate: Dictionary) -> Dictionary:
	var desired := str(contract.get("enclosure_need", "open")).strip_edges().to_lower()
	var actual := str(candidate.get("enclosure", "")).strip_edges().to_lower()

	if desired.is_empty():
		return {"score": 10.0, "reason": "No enclosure need set in contract."}
	if actual.is_empty():
		return {"score": 8.0, "reason": "Candidate has no enclosure value; neutral score."}
	if desired == actual:
		return {"score": 15.0, "reason": "Enclosure matches contract."}
	if _is_enclosure_compatible(desired, actual):
		return {"score": 10.0, "reason": "Enclosure partially compatible with contract."}
	return {"score": 2.0, "reason": "Enclosure conflicts with contract."}


func _score_clearance(contract: Dictionary, candidate: Dictionary, context: Dictionary) -> Dictionary:
	var required := float(contract.get("clearance_radius_cells", 1.5))
	var actual := _extract_clearance(candidate, context)

	if actual <= 0.0:
		return {
			"score": 10.0,
			"reason": "No explicit clearance provided; neutral score."
		}
	if actual >= required:
		return {"score": 20.0, "reason": "Clearance meets or exceeds requirement."}
	if actual >= required * 0.8:
		return {
			"score": 12.0,
			"reason": "Clearance is slightly under requirement.",
			"warning": "Candidate may feel cramped."
		}
	if actual >= required * 0.5:
		return {
			"score": 6.0,
			"reason": "Clearance is far under requirement.",
			"warning": "Interaction may be difficult at runtime."
		}
	return {
		"score": 1.0,
		"reason": "Clearance violates minimum spacing.",
		"warning": "Likely obstruction risk."
	}


func _score_view_distance(contract: Dictionary, candidate: Dictionary, context: Dictionary) -> Dictionary:
	var band := contract.get("preferred_view_distance_m", [1.5, 3.0])
	var min_distance := 1.5
	var max_distance := 3.0
	if band is Array and band.size() >= 2:
		min_distance = float(band[0])
		max_distance = float(band[1])
	if max_distance < min_distance:
		var tmp := min_distance
		min_distance = max_distance
		max_distance = tmp

	var distance := _extract_view_distance(candidate, context)
	if distance < 0.0:
		return {"score": 8.0, "reason": "No view-distance estimate available; neutral score."}
	if distance >= min_distance and distance <= max_distance:
		return {"score": 15.0, "reason": "View distance is in preferred band."}

	if distance < min_distance:
		var ratio := max(0.0, min(1.0, distance / max(min_distance, 0.001)))
		return {"score": 15.0 * ratio, "reason": "View distance is too close to artifact."}

	var over := distance - max_distance
	var tolerance := max(max_distance, 0.001)
	var penalty_ratio := max(0.0, min(1.0, over / tolerance))
	return {"score": 15.0 * (1.0 - penalty_ratio), "reason": "View distance is too far from artifact."}


func _score_directionality(contract: Dictionary, candidate: Dictionary, context: Dictionary) -> Dictionary:
	var profile_id := str(contract.get("directional_profile", "ambient")).strip_edges().to_lower()
	var profile: Dictionary = _directional_profiles.get(profile_id, {})
	var front_angle := float(profile.get("front_angle_degrees", 360.0))
	var rotation_sensitive := bool(profile.get("rotation_sensitive", false))

	if not rotation_sensitive or front_angle >= 359.0:
		return {"score": 25.0, "reason": "Omnidirectional profile; facing is not critical."}

	var approach_vector := _extract_approach_vector(candidate, context)
	if approach_vector.length() < 0.001:
		return {"score": 12.0, "reason": "No approach vector available; partial directionality score."}

	var rotation_y := float(candidate.get("rotation_y", 0.0))
	var forward := _rotation_to_forward_2d(rotation_y)
	var dot_value := clamp(forward.dot(approach_vector.normalized()), -1.0, 1.0)
	var angle := rad_to_deg(acos(dot_value))

	var directional_score := 0.0
	if angle <= front_angle * 0.5:
		directional_score = 25.0
	elif angle <= front_angle:
		directional_score = 18.0
	elif angle <= front_angle + 30.0:
		directional_score = 10.0
	else:
		directional_score = 2.0

	var reason := "Facing angle to approach vector: %.1f deg." % angle
	var warning := ""

	if bool(profile.get("requires_axis_alignment", false)):
		var axis_vector := _extract_axis_vector(candidate, context)
		if axis_vector.length() > 0.001:
			var axis_alignment := absf(forward.dot(axis_vector.normalized()))
			if axis_alignment >= 0.95:
				directional_score += 3.0
				reason += " Corridor axis alignment is strong."
			elif axis_alignment >= 0.8:
				directional_score += 1.0
				reason += " Corridor axis alignment is acceptable."
			else:
				directional_score -= 4.0
				reason += " Corridor axis alignment is weak."
				warning = "Corridor profile is misaligned with path axis."

	directional_score = clamp(directional_score, 0.0, 25.0)
	if warning.is_empty():
		return {"score": directional_score, "reason": reason}
	return {"score": directional_score, "reason": reason, "warning": warning}


func _score_sequence_affinity(contract: Dictionary, context: Dictionary) -> Dictionary:
	var tags := _to_string_array(contract.get("sequence_tags", []))
	if tags.is_empty():
		return {"score": 0.0, "reason": ""}
	if not context.has("sequence_id"):
		return {"score": 0.0, "reason": ""}

	var sequence_id := str(context.get("sequence_id", "")).strip_edges().to_lower()
	if sequence_id.is_empty():
		return {"score": 0.0, "reason": ""}

	if tags.has(sequence_id):
		return {"score": 5.0, "reason": "Sequence tag matches contract affinity."}
	return {"score": 0.0, "reason": ""}


func _extract_clearance(candidate: Dictionary, context: Dictionary) -> float:
	if candidate.has("clearance_radius_cells"):
		return float(candidate.get("clearance_radius_cells", 0.0))
	if candidate.has("nearest_obstacle_distance_cells"):
		return float(candidate.get("nearest_obstacle_distance_cells", 0.0))
	if context.has("default_clearance_radius_cells"):
		return float(context.get("default_clearance_radius_cells", 0.0))
	return 0.0


func _extract_view_distance(candidate: Dictionary, context: Dictionary) -> float:
	if candidate.has("view_distance_m"):
		return float(candidate.get("view_distance_m", -1.0))
	if candidate.has("distance_from_spawn_m"):
		return float(candidate.get("distance_from_spawn_m", -1.0))

	var has_viewpoint := context.has("player_position_2d") or context.has("spawn_position_2d")
	if not has_viewpoint:
		return -1.0

	var viewpoint := _extract_position_2d(context.get("player_position_2d", context.get("spawn_position_2d", Vector2.ZERO)), Vector2.ZERO)
	var candidate_position := _extract_position_2d(candidate.get("position_2d", Vector2.ZERO), Vector2.ZERO)
	return candidate_position.distance_to(viewpoint)


func _extract_approach_vector(candidate: Dictionary, context: Dictionary) -> Vector2:
	if candidate.has("approach_vector_2d"):
		var raw := _extract_position_2d(candidate.get("approach_vector_2d"), Vector2.ZERO)
		if raw.length() > 0.001:
			return raw.normalized()

	var candidate_pos := _extract_position_2d(candidate.get("position_2d", Vector2.ZERO), Vector2.ZERO)
	if candidate.has("approach_position_2d"):
		var approach_position := _extract_position_2d(candidate.get("approach_position_2d"), candidate_pos)
		var approach_vector := approach_position - candidate_pos
		if approach_vector.length() > 0.001:
			return approach_vector.normalized()

	if context.has("player_position_2d"):
		var player_pos := _extract_position_2d(context.get("player_position_2d"), candidate_pos)
		var player_vector := player_pos - candidate_pos
		if player_vector.length() > 0.001:
			return player_vector.normalized()

	if context.has("spawn_position_2d"):
		var spawn_pos := _extract_position_2d(context.get("spawn_position_2d"), candidate_pos)
		var spawn_vector := spawn_pos - candidate_pos
		if spawn_vector.length() > 0.001:
			return spawn_vector.normalized()

	return Vector2.ZERO


func _extract_axis_vector(candidate: Dictionary, context: Dictionary) -> Vector2:
	if candidate.has("corridor_axis_2d"):
		var candidate_axis := _extract_position_2d(candidate.get("corridor_axis_2d"), Vector2.ZERO)
		if candidate_axis.length() > 0.001:
			return candidate_axis.normalized()
	if context.has("corridor_axis_2d"):
		var context_axis := _extract_position_2d(context.get("corridor_axis_2d"), Vector2.ZERO)
		if context_axis.length() > 0.001:
			return context_axis.normalized()
	if context.has("path_axis_2d"):
		var path_axis := _extract_position_2d(context.get("path_axis_2d"), Vector2.ZERO)
		if path_axis.length() > 0.001:
			return path_axis.normalized()
	return Vector2.ZERO


func _rotation_to_forward_2d(rotation_y: float) -> Vector2:
	var radians := deg_to_rad(_normalize_angle(rotation_y))
	# 0=south, 90=west, 180=north, 270=east
	var forward := Vector2(-sin(radians), cos(radians))
	if forward.length() < 0.001:
		return Vector2(0.0, 1.0)
	return forward.normalized()


func _best_cardinal_rotation_for_contract(position: Vector2, target: Vector2, contract: Dictionary) -> float:
	var profile_id := str(contract.get("directional_profile", "ambient")).strip_edges().to_lower()
	var profile := _directional_profiles.get(profile_id, {})
	if not bool(profile.get("rotation_sensitive", false)):
		return 0.0

	var direction := target - position
	if direction.length() < 0.001:
		return 0.0
	direction = direction.normalized()

	var best_rotation := 0.0
	var best_dot := -2.0
	for rotation in CARDINAL_ROTATIONS:
		var forward := _rotation_to_forward_2d(float(rotation))
		var alignment := forward.dot(direction)
		if alignment > best_dot:
			best_dot = alignment
			best_rotation = float(rotation)
	return best_rotation


func _build_interactable_token(lookup_name: String, candidate: Dictionary) -> String:
	var rotation_y := float(candidate.get("rotation_y", 0.0))
	var y_offset := float(candidate.get("y_offset", 0.0))
	var scale := float(candidate.get("scale", 1.0))

	var has_rotation := absf(rotation_y) > 0.001
	var has_y_offset := candidate.has("y_offset") and absf(y_offset) > 0.001
	var has_scale := candidate.has("scale") and absf(scale - 1.0) > 0.001

	if not has_rotation and not has_y_offset and not has_scale:
		return lookup_name

	var parts: Array[String] = [lookup_name, _format_number(rotation_y)]
	if has_y_offset or has_scale:
		parts.append(_format_number(y_offset))
	if has_scale:
		parts.append(_format_number(scale))
	return ":".join(parts)


func _format_number(value: float) -> String:
	var rounded := snapped(value, 0.001)
	if absf(rounded - round(rounded)) < 0.0001:
		return str(int(round(rounded)))
	return str(rounded)


func _remove_nearby_candidates(candidate_pool: Array, center: Vector2, spacing: float) -> Array:
	var filtered: Array = []
	for candidate_variant in candidate_pool:
		if typeof(candidate_variant) != TYPE_DICTIONARY:
			continue
		var candidate: Dictionary = candidate_variant
		var pos := _extract_position_2d(candidate.get("position_2d", Vector2.ZERO), Vector2.ZERO)
		if pos.distance_to(center) >= spacing:
			filtered.append(candidate)
	return filtered


func _has_min_spacing(position: Vector2, placements: Array, min_spacing: float) -> bool:
	for placement_variant in placements:
		if typeof(placement_variant) != TYPE_DICTIONARY:
			continue
		var placement: Dictionary = placement_variant
		var placed_pos := _extract_position_2d(placement.get("position_2d", Vector2.ZERO), Vector2.ZERO)
		if placed_pos.distance_to(position) < min_spacing:
			return false
	return true


func _extract_position_2d(value: Variant, fallback: Vector2) -> Vector2:
	match typeof(value):
		TYPE_VECTOR2:
			return value
		TYPE_VECTOR2I:
			var v2i: Vector2i = value
			return Vector2(v2i.x, v2i.y)
		TYPE_VECTOR3:
			var v3: Vector3 = value
			return Vector2(v3.x, v3.z)
		TYPE_VECTOR3I:
			var v3i: Vector3i = value
			return Vector2(v3i.x, v3i.z)
		TYPE_ARRAY:
			var arr: Array = value
			if arr.size() >= 2:
				return Vector2(_to_float(arr[0], fallback.x), _to_float(arr[1], fallback.y))
		TYPE_DICTIONARY:
			var dict: Dictionary = value
			if dict.has("x") and (dict.has("z") or dict.has("y")):
				if dict.has("z"):
					return Vector2(_to_float(dict.get("x", 0.0), fallback.x), _to_float(dict.get("z", 0.0), fallback.y))
				return Vector2(_to_float(dict.get("x", 0.0), fallback.x), _to_float(dict.get("y", 0.0), fallback.y))
	return fallback


func _merge_contracts(base_contract: Dictionary, override_contract: Dictionary) -> Dictionary:
	var merged := base_contract.duplicate(true)
	for key in override_contract.keys():
		var value = override_contract[key]
		if typeof(value) == TYPE_DICTIONARY and typeof(merged.get(key, null)) == TYPE_DICTIONARY:
			merged[key] = _merge_contracts(merged[key], value)
		else:
			merged[key] = value
	return merged


func _to_string_array(value: Variant) -> Array[String]:
	var output: Array[String] = []
	if value is Array:
		for item in value:
			var text := str(item).strip_edges().to_lower()
			if not text.is_empty() and not output.has(text):
				output.append(text)
	elif typeof(value) == TYPE_STRING:
		var text_value := str(value).strip_edges().to_lower()
		if not text_value.is_empty():
			output.append(text_value)
	return output


func _is_staging_compatible(desired: String, actual: String) -> bool:
	var compatibility := {
		"table": ["plinth", "alcove"],
		"plinth": ["table", "pillar"],
		"pillar": ["plinth", "table"],
		"alcove": ["table", "room", "corridor"],
		"room": ["alcove", "corridor"],
		"corridor": ["room", "alcove"],
		"ambient": ["table", "plinth", "room"]
	}
	if compatibility.has(desired):
		return (compatibility[desired] as Array).has(actual)
	return false


func _is_enclosure_compatible(desired: String, actual: String) -> bool:
	if desired == actual:
		return true
	if desired == "open":
		return actual == "semi"
	if desired == "semi":
		return actual == "open" or actual == "enclosed"
	if desired == "enclosed":
		return actual == "semi"
	return false


func _normalize_angle(angle_degrees: float) -> float:
	return fposmod(angle_degrees, 360.0)


func _to_float(value: Variant, fallback: float = 0.0) -> float:
	match typeof(value):
		TYPE_FLOAT, TYPE_INT:
			return float(value)
		TYPE_STRING:
			var text := str(value).strip_edges()
			if text.is_valid_float() or text.is_valid_int():
				return float(text)
	return fallback


func _reasons_compact(lines: Array[String]) -> void:
	var compacted: Array[String] = []
	for line in lines:
		var trimmed := line.strip_edges()
		if trimmed.is_empty():
			continue
		if compacted.has(trimmed):
			continue
		compacted.append(trimmed)
	lines.clear()
	for item in compacted:
		lines.append(item)


func _ensure_loaded() -> bool:
	if _loaded:
		return true
	return load_contracts(_contracts_path)
