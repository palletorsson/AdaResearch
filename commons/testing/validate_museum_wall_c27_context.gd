extends SceneTree

## Structural smoke for the occupied C27 evidence wrapper.
## It verifies that every wall family can be placed in the full one-metre-grid
## gallery without altering the production MuseumWallPiece API.

const SCENE := preload("res://commons/artifacts/museum/museum_wall_c27_occupied_gallery.tscn")
const CASES: Array[Dictionary] = [
	{"kind":"solid", "width_cells":4},
	{"kind":"feature", "width_cells":4},
	{"kind":"window", "width_cells":4},
	{"kind":"vitrine", "width_cells":4},
	{"kind":"service", "width_cells":4},
	{"kind":"portal", "width_cells":4},
	{"kind":"endcap", "width_cells":2},
]

var _checks := 0
var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for config in CASES:
		var gallery := SCENE.instantiate()
		gallery.set("kind", config.kind)
		gallery.set("width_cells", config.width_cells)
		gallery.set("detail_seed", 16000 + _checks)
		root.add_child(gallery)
		await process_frame
		var report: Dictionary = gallery.call("get_context_report")
		var piece_contracts := gallery.find_children("PieceContract", "Node3D", true, false)
		var rendered_meshes := gallery.find_children("*", "MeshInstance3D", true, false)
		_check(report.get("kind") == config.kind, "%s: family changed" % config.kind)
		_check(int(report.get("width_cells", 0)) == int(config.width_cells), "%s: width changed" % config.kind)
		_check(bool(report.get("central_module_unobscured", false)), "%s: hero is not unobscured" % config.kind)
		_check(int(report.get("central_module_count", 0)) == 1, "%s: hero count is not one" % config.kind)
		_check(int(report.get("adjacent_wall_bays", 0)) == 2, "%s: expected two production neighbours" % config.kind)
		_check(bool(report.get("continuous_floor", false)), "%s: floor is not continuous" % config.kind)
		_check(bool(report.get("continuous_ceiling", false)), "%s: ceiling is not continuous" % config.kind)
		_check(float(report.get("grid_m", 0.0)) == 1.0, "%s: grid is not one metre" % config.kind)
		_check(float(report.get("circulation_depth_m", 0.0)) >= 7.0, "%s: circulation is too shallow" % config.kind)
		_check(int(report.get("context_materials_used", 99)) <= int(report.get("context_material_limit", 0)), "%s: context material budget exceeded" % config.kind)
		_check(bool(report.get("no_per_frame_logic", false)), "%s: per-frame context logic declared" % config.kind)
		_check(piece_contracts.size() == 3, "%s: expected three compiled production PieceContract nodes, got %d" % [config.kind, piece_contracts.size()])
		_check(rendered_meshes.size() >= 24, "%s: rendered geometry is incomplete (%d meshes)" % [config.kind, rendered_meshes.size()])
		gallery.queue_free()
		await process_frame
	print("C27_CONTEXT_RESULT checks=%d failures=%d" % [_checks, _failures.size()])
	for failure in _failures:
		push_error("C27_CONTEXT: " + failure)
	quit(0 if _failures.is_empty() else 1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
