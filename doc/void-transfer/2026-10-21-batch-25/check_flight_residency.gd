extends SceneTree
## Regression for real museum flight lookup across Void residency transitions.
class Building:
	extends Node3D
	var spec := {"shafts": [], "shaft_width": 5.0, "shaft_depth": 6.0}

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var building := Building.new()
	root.add_child(building)
	var floor_root := Node3D.new()
	floor_root.position.y = -12.0
	building.add_child(floor_root)
	var flight_script = load("res://commons/movement/museum_flight_box.gd")
	var zone = flight_script.new()
	zone.edge_length = 6.0
	floor_root.add_child(zone)
	await process_frame
	var residency = load("res://commons/void/floor_residency.gd").new(floor_root, building)
	var inside := Vector3(0,-11,0)
	var passed: bool = flight_script.at_point(self, inside) == zone
	for mode in ["hidden", "preview", "live", "preview", "live"]:
		residency.set_mode(mode)
		var found: bool = flight_script.at_point(self, inside) == zone
		var expected: bool = mode == "live"
		passed = passed and found == expected
		print("FLIGHT_RESIDENCY ", mode, " lookup=", found, " expected=", expected)
		residency.needs_refresh = true
		residency.set_mode(mode)
		passed = passed and (flight_script.at_point(self, inside) == zone) == expected
	# Deleted procedural children must remain safe during restoration.
	residency.set_mode("hidden")
	zone.free()
	residency.set_mode("live")
	building.free()
	print("FLIGHT_RESIDENCY_RESULT ", passed)
	quit(0 if passed else 1)
