extends "res://tools/probes/transformation_encounters.gd"
const Route := preload("res://commons/hazards/biome_ladder/route.gd")

class StagingSpy extends Node:
	var destination := ""
	func load_scene(path: String) -> void: destination = path
	func return_to_main_menu() -> void: pass

func landing_checks() -> void:
	museum.flush_stamps()
	await create_timer(0.5).timeout
	var entry := hall.get_node_or_null("BiomeLadderEntry") as Node3D
	check("last hall has a biome entry", entry != null)
	if entry == null: return
	observations["entry_local"] = xyz(entry.position)
	check("entry is at reachable hand height", is_equal_approx(entry.get_child(0).position.y, 1.08))
	check("entry stands on the museum's actual floor", not floor_at(entry.global_position).is_empty())
	var step: Dictionary = Route.STAGES[Route.index_for_map(map_id)]
	var next: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/sequences/" + str(step.next) + ".json"))
	check("continue address matches next sequence's actual first map", next.sequences[step.next].maps[0] == step.first)
	await snapshot("biome-entry", entry.to_global(Vector3(0, 1.65, 1.5)), entry.to_global(Vector3(0, 1.3, 0)), 65)
	# Exercise the actual button/route contract without replacing the isolated
	# museum with a second live world. Full scene staging is checked separately.
	var staging := StagingSpy.new(); root.add_child(staging)
	museum.reparent(staging)
	entry.get_child(0).pressed.emit()
	check("museum button requests ladder through staging", staging.destination == Route.SCENE and Route.from_museum and Route.selected_stage == Route.index_for_map(map_id))
	Route.continue_museum(museum)
	var script: GDScript = load("res://commons/scenes/endless_museum.gd")
	check("continue requests actual next museum hall", staging.destination == "res://commons/scenes/endless_museum_staged.tscn" and script.menu_chapter == step.next and script.menu_map == step.first)
	observations["scope"] = "Real mounted button and route dispatch; scene loading checked by separate standalone roundtrip."
