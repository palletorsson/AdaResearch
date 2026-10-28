extends SceneTree
## centrifuge_ring as shipped (radius 3.4, speed 0.62), headless: which way its two arrows point
## and how fast the pod laps. The arrows are built along the vector rig's local +Z (velocity) and
## -X (pull); the rig turns with the pod. Checked at eight phases against the tangent
## (-sin, 0, cos) and the inward unit -pos/r; the speed from two phases a known time apart.
## Writes ada_run/centrifuge_ring/arrows.json.


func _init() -> void:
	var ring: Node3D = load("res://commons/artifacts/centrifuge_ring/centrifuge_ring.tscn").instantiate()
	root.add_child(ring)
	for i in 3:
		await process_frame
	ring.set_process(false)
	var r: float = ring.get("radius")
	var omega: float = ring.get("_omega")
	var pod: Node3D = ring.get("_pod")
	var rig: Node3D = ring.get("_vectors")
	var out := {"radius": r, "omega": omega, "v": omega * r, "phases": [], "worst_tangent": 0.0, "worst_inward": 0.0}
	for k in 8:
		var th: float = TAU * k / 8.0 + 0.3
		ring.set("_phase", th)
		ring.call("_advance")
		var p: Vector3 = pod.global_position
		var vel_dir: Vector3 = (rig.global_basis * Vector3.BACK).normalized()
		var pull_dir: Vector3 = (rig.global_basis * Vector3.LEFT).normalized()
		var tangent := Vector3(-sin(th), 0, cos(th))
		var inward := -Vector3(p.x, 0, p.z).normalized()
		var dt := 0.01
		ring.set("_phase", th + omega * dt)
		ring.call("_advance")
		var speed: float = (pod.global_position - p).length() / dt
		out["phases"].append({"theta": th, "vel_dot_tangent": vel_dir.dot(tangent), "pull_dot_inward": pull_dir.dot(inward), "speed": speed})
		out["worst_tangent"] = maxf(out["worst_tangent"], 1.0 - vel_dir.dot(tangent))
		out["worst_inward"] = maxf(out["worst_inward"], 1.0 - pull_dir.dot(inward))
	var dir := ProjectSettings.globalize_path("res://ada_run/centrifuge_ring")
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir.path_join("arrows.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	quit(0)
