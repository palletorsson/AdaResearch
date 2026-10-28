extends SceneTree
## force_pad as shipped (up 7, forward 6), headless: which way the three chevrons point, and where a
## walking body really leaves and lands against where the pad's own foresight draws it. A capsule of
## radius 0.2 (XR Tools' player_radius), origin at the feet, walks onto the pad at 1.4 m/s from
## behind, from the side and from in front; it falls the way the player body does (velocity += g dt,
## then move_and_slide). Writes ada_run/force_pad/flight.json.

const WALKER := """extends CharacterBody3D
var walk := Vector3.ZERO
var g := 9.8
var launched := false
var launch_at := Vector3.ZERO
var launch_v := Vector3.ZERO
var landed := false
var land_at := Vector3.ZERO
var ticks := 0
var air_ticks := 0
func _physics_process(delta: float) -> void:
	ticks += 1
	if not launched and velocity.y > 1.0:
		launched = true
		launch_at = global_position
		launch_v = velocity
	if not launched:
		velocity = Vector3(walk.x, velocity.y, walk.z)
	velocity.y -= g * delta
	move_and_slide()
	if launched and not landed:
		air_ticks += 1
		if air_ticks > 3 and is_on_floor():
			landed = true
			land_at = global_position
"""


func _init() -> void:
	var out := {"physics_hz": Engine.physics_ticks_per_second, "runs": []}
	var pad: Node3D = load("res://commons/artifacts/force_pad/force_pad.tscn").instantiate()
	root.add_child(pad)
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var slab := BoxShape3D.new()
	slab.size = Vector3(60, 1, 60)
	floor_shape.shape = slab
	floor_shape.position.y = -0.5
	floor_body.add_child(floor_shape)
	root.add_child(floor_body)
	for i in 3:
		await process_frame
	var chevrons := []
	for c in pad.get_children():
		if c is MeshInstance3D and c.mesh is CylinderMesh and is_zero_approx((c.mesh as CylinderMesh).top_radius) and is_equal_approx((c.mesh as CylinderMesh).bottom_radius, 0.16):
			var tip: Vector3 = (c as MeshInstance3D).global_basis * Vector3.UP
			chevrons.append({"z": c.position.z, "tip": [snappedf(tip.x, 0.001), snappedf(tip.y, 0.001), snappedf(tip.z, 0.001)]})
	out["chevrons"] = chevrons
	var v0: Vector3 = pad.call("_launch_velocity")
	var t_drawn: float = pad.call("_flight_time")
	out["launch_velocity"] = [v0.x, v0.y, v0.z]
	out["drawn"] = {"origin_y": 0.2, "flight_time": t_drawn, "landing_z": v0.z * t_drawn}
	var script := GDScript.new()
	script.source_code = WALKER
	script.reload()
	for approach in [["behind", Vector3(0, 0, -2.4), Vector3(0, 0, 1.4)], ["side", Vector3(-2.4, 0, 0), Vector3(1.4, 0, 0)], ["front", Vector3(0, 0, 2.4), Vector3(0, 0, -1.4)]]:
		var body := CharacterBody3D.new()
		body.set_script(script)
		body.collision_layer = 1 | 524288
		body.collision_mask = 1
		var shape := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.2
		cap.height = 1.8
		shape.shape = cap
		shape.position.y = 0.9
		body.add_child(shape)
		body.position = approach[1]
		root.add_child(body)
		body.set("walk", approach[2])
		var waited := 0
		while not bool(body.get("landed")) and waited < 600:
			await physics_frame
			waited += 1
		var la: Vector3 = body.get("launch_at")
		var ld: Vector3 = body.get("land_at")
		var lv: Vector3 = body.get("launch_v")
		out["runs"].append({"approach": approach[0], "launched": body.get("launched"), "landed": body.get("landed"),
			"launch_at": [snappedf(la.x, 0.0001), snappedf(la.y, 0.0001), snappedf(la.z, 0.0001)],
			"launch_v": [snappedf(lv.x, 0.0001), snappedf(lv.y, 0.0001), snappedf(lv.z, 0.0001)],
			"land_at": [snappedf(ld.x, 0.0001), snappedf(ld.y, 0.0001), snappedf(ld.z, 0.0001)],
			"air_ticks": body.get("air_ticks")})
		body.queue_free()
		for i in 70:
			await physics_frame   # the pad's 0.8 s cooldown
	var dir := ProjectSettings.globalize_path("res://ada_run/force_pad")
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir.path_join("flight.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	quit(0)
