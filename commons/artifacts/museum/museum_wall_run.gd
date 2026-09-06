extends Node3D
class_name MuseumWallRun

## Exact-length composer for MuseumWallPiece. `run_spec` is deliberately compact:
## `service:2|feature:4|solid:2` is an eight-metre wall, readable in one line of JSON.

const PIECE_SCENE := preload("res://commons/artifacts/museum/museum_wall_piece.tscn")
const PHYSICS_CONTRACT := "res://commons/data/museum_wall_physics_contract.json"
const ALLOWED_KINDS := [&"solid", &"feature", &"window", &"vitrine", &"service", &"portal", &"endcap"]

@export var run_spec: String = "service:2|feature:4|solid:2"
@export_range(3.0, 6.0, 0.25) var height: float = 4.0
@export var finish: String = "uffizi_stone"
@export var enable_collision: bool = true
@export var alternate_flip: bool = true
@export var quality_tier: String = "aaa"
@export var detail_seed: int = 4067
@export_range(0, 2, 1) var lod_level: int = 0

var _built := false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for key in config_data:
		set_meta("config_%s" % str(key), config_data[key])
	_read_metadata_overrides()
	if _built:
		for child in get_children():
			child.queue_free()
		_built = false
	_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_run_spec"): run_spec = str(get_meta("config_run_spec"))
	if has_meta("config_height"): height = float(str(get_meta("config_height")))
	if has_meta("config_finish"): finish = str(get_meta("config_finish"))
	if has_meta("config_enable_collision"): enable_collision = _bool(get_meta("config_enable_collision"))
	if has_meta("config_alternate_flip"): alternate_flip = _bool(get_meta("config_alternate_flip"))
	if has_meta("config_quality_tier"): quality_tier = str(get_meta("config_quality_tier")).to_lower()
	if has_meta("config_detail_seed"): detail_seed = int(str(get_meta("config_detail_seed")))
	elif has_meta("config_seed"): detail_seed = int(str(get_meta("config_seed")))
	if has_meta("config_lod_level"): lod_level = clampi(int(str(get_meta("config_lod_level"))), 0, 2)


func _build() -> void:
	_built = true
	var segments := parse_run_spec(run_spec)
	if segments.is_empty():
		segments = [{"kind": "solid", "width_cells": 1}]
	var total_cells := 0
	for segment in segments:
		total_cells += int(segment["width_cells"])

	var contract := Node3D.new()
	contract.name = "WallRunContract"
	contract.set_meta("grid_m", 1.0)
	contract.set_meta("run_spec", normalized_spec(segments))
	contract.set_meta("width_cells", total_cells)
	contract.set_meta("segment_count", segments.size())
	contract.set_meta("socket", "museum_wall_flat_v1")
	contract.set_meta("quality_tier", quality_tier)
	contract.set_meta("detail_seed", detail_seed)
	contract.set_meta("lod_levels", 3)
	contract.set_meta("lod_level", lod_level)
	contract.set_meta("physics_contract", PHYSICS_CONTRACT)
	contract.set_meta("composition_valid", _endcaps_are_terminal(segments))
	add_child(contract)

	var cursor := -float(total_cells) * 0.5
	for index in range(segments.size()):
		var segment: Dictionary = segments[index]
		var cells := int(segment["width_cells"])
		var piece: Node3D = PIECE_SCENE.instantiate()
		piece.name = "%02d_%s_%dm" % [index, str(segment["kind"]).capitalize(), cells]
		piece.set("kind", str(segment["kind"]))
		piece.set("width_cells", cells)
		piece.set("height", height)
		piece.set("finish", finish)
		piece.set("enable_collision", enable_collision)
		var piece_flip := alternate_flip and index % 2 == 1
		if str(segment["kind"]) == "endcap":
			piece_flip = index == segments.size() - 1
		piece.set("flip", piece_flip)
		piece.set("quality_tier", quality_tier)
		piece.set("detail_seed", detail_seed + index * 7919)
		piece.set("lod_level", lod_level)
		piece.position.x = cursor + float(cells) * 0.5
		contract.add_child(piece)
		cursor += float(cells)

	_add_run_socket(contract, "SocketLeft", -float(total_cells) * 0.5, Vector3.LEFT)
	_add_run_socket(contract, "SocketRight", float(total_cells) * 0.5, Vector3.RIGHT)


static func parse_run_spec(spec: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_token in spec.split("|", false):
		var token := raw_token.strip_edges().to_lower()
		if token.is_empty():
			continue
		var parts := token.split(":", false, 1)
		var segment_kind := str(parts[0])
		if not ALLOWED_KINDS.has(StringName(segment_kind)):
			continue
		var cells := 1
		if parts.size() > 1 and str(parts[1]).is_valid_int():
			cells = clampi(int(parts[1]), 1, 4)
		if segment_kind == "portal":
			cells = maxi(cells, 2)
		result.append({"kind": segment_kind, "width_cells": cells})
	return result


static func normalized_spec(segments: Array[Dictionary]) -> String:
	var tokens: PackedStringArray = []
	for segment in segments:
		tokens.append("%s:%d" % [str(segment["kind"]), int(segment["width_cells"])])
	return "|".join(tokens)


static func _endcaps_are_terminal(segments: Array[Dictionary]) -> bool:
	for index in range(segments.size()):
		if str(segments[index].get("kind", "")) == "endcap" and index not in [0, segments.size() - 1]:
			return false
	return true


func _add_run_socket(parent: Node3D, socket_name: String, x: float, facing: Vector3) -> void:
	var marker := Marker3D.new()
	marker.name = socket_name
	marker.position = Vector3(x, 0, 0)
	marker.set_meta("port", "museum_wall_flat_v1")
	marker.set_meta("grid_m", 1.0)
	marker.set_meta("facing", facing)
	parent.add_child(marker)


func _bool(value: Variant) -> bool:
	return str(value).strip_edges().to_lower() in ["1", "true", "yes", "on"]
