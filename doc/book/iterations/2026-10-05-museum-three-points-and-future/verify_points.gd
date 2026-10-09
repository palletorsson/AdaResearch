extends SceneTree

var checks: Array[Dictionary] = []
var stations: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func record(label: String, passed: bool) -> void:
	checks.append({"check": label, "passed": passed})
	if not passed:
		push_error(label)

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	for i in range(4):
		var condition: String = ["absent", "visible", "solid", "pedestal"][i]
		var packed: PackedScene = load("res://commons/primitives/point/point_%s.tscn" % condition)
		var station: Node3D = packed.instantiate()
		station.position.x = i * 4.0
		world.add_child(station)
		stations[condition] = station
	await physics_frame
	await physics_frame
	for condition in ["absent", "visible", "solid"]:
		var station: Node3D = stations[condition]
		var plinth := station.get_node("PointPlinth") as MeshInstance3D
		record(condition + ": one plain box support", plinth.mesh is BoxMesh)
		record(condition + ": support reaches the point's lower edge", is_equal_approx(plinth.position.y + plinth.mesh.size.y / 2.0, 0.98))
		record(condition + ": off-white matte support", plinth.material_override.albedo_color.is_equal_approx(Color(0.90, 0.895, 0.875)) and plinth.material_override.roughness > 0.8)
		record(condition + ": single label on front face", station.find_children("PointOneLabel", "Label3D", true, false).size() == 1 and station.get_node("PointOneLabel").position.z > 0.41)
		var origin := station.global_position + Vector3(0, 1.12, 1)
		var ray := PhysicsRayQueryParameters3D.create(origin, origin - Vector3(0, 0, 2), 1)
		var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
		record(condition + ": only the solid point stops the ray above its support", hit.is_empty() if condition != "solid" else not hit.is_empty())
		if condition == "absent":
			record("absent: no hidden surface or sphere body", not station.has_node("VisiblePoint") and not station.has_node("PointCollision"))
		else:
			var surface := station.get_node("VisiblePoint") as MeshInstance3D
			record(condition + ": original .14m white point preserved", is_equal_approx(surface.mesh.radius, 0.14) and surface.material_override.albedo_color.is_equal_approx(Color(0.97, 0.97, 0.95)))
	var final_station: Node3D = stations.pedestal
	var future := final_station.get_node("VisiblePoint") as MeshInstance3D
	var finish := future.material_override as StandardMaterial3D
	record("future: original 1.3m diameter and 1.4m centre", is_equal_approx(future.mesh.radius, 0.65) and future.position.is_equal_approx(Vector3(0, 1.40, 0)))
	record("future: sphere still solid", final_station.has_node("PointCollision"))
	record("future: black polished material", finish.albedo_color.r < 0.01 and finish.roughness < 0.1 and finish.clearcoat_enabled)
	var base := final_station.get_node("Pedestal") as MeshInstance3D
	record("future: original support dimensions retained", base.mesh.size.is_equal_approx(Vector3(0.94, 0.75, 0.94)))
	record("future: lower edge meets its support", is_equal_approx(future.position.y - future.mesh.radius, base.position.y + base.mesh.size.y / 2.0))
	var passed := true
	for check in checks:
		passed = passed and check.passed
	var report := {"passed": passed, "checks": checks, "limits": ["Native scene geometry/material and physics ray checks only", "No headset or aesthetic acceptance test"]}
	var destination := "res://doc/book/iterations/2026-10-05-museum-three-points-and-future/points-checks.json"
	FileAccess.open(destination, FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("POINT_PODIUM_CHECKS=" + str(checks.size()) + " PASSED=" + str(passed))
	quit(0 if passed else 1)
