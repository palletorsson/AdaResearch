extends RefCounted
## THE THRESHOLD GATE — the first passage stands alone (2026-08-18).
##
## Palle, walking primitives: "Can we make the first passage of the room stand
## alone? There is a hand scanner in the first passage. Place that beside the
## door (station_door__sealed_biparting) to the first exhibition hall in the
## doorway, (move fire extinguisher) and add the closed door to open when the
## handscanner is activated. While we find our way to the scanner, lazy load
## the artifact in the next room."
##
## So the vestibule becomes a room of its own: a SEALED bi-parting door across
## the way into the first hall, a palm scanner on the jamb beside it, and the
## hall filling behind the door while the visitor crosses the vestibule and
## puts a hand on the glass. VR: the scanner's own `palm_scanned` (a tracked
## hand in its box). Desktop: click it (or look at it and click within reach).
##
## The gate NEVER blocks the walk map — the cells stay walkable, so the
## planner and the autopilot route through it exactly as before; what the door
## adds is a COLLIDER, removed when it opens. A gate that lied to the planner
## would be the one failure a walker cannot route around (the seal's own rule).
##
## The module owns geometry and state; the museum owns the segment, the input
## and the streaming. Stateless helpers, like every other em/ module.

const DOOR_SCENE := "res://commons/artifacts/station/station_door.tscn"
const SCANNER_SCENE := "res://commons/artifacts/palm_scanner/palm_scanner.tscn"
const OPEN_SECONDS := 1.6          # leaves part over this long
const GATE_DEPTH := 4              # rows into the hall: how much run-up the first passage gets
const SCAN_REACH_M := 3.2          # desktop: how close the click must be
const SCAN_CONE := 0.55            # desktop: radians off the crosshair


## Build the gate at the vestibule mouth of `seg`. Returns
## {door, scanner, colliders: [CollisionShape3D], open: false} or {} when the
## scenes are missing (the museum then behaves exactly as before).
static func build(seg: Node3D, solid: StaticBody3D, w: int, wall_col: Color,
		mat_wall: Material, layout: Dictionary = {}) -> Dictionary:
	if not ResourceLoader.exists(DOOR_SCENE) or not ResourceLoader.exists(SCANNER_SCENE):
		push_warning("[em-gate] door or scanner scene missing — no gate built")
		return {}
	# THE FIRST PASSAGE NEEDS ROOM (2026-08-18). The door stood at the
	# vestibule's mouth, 2 m from the spawn: the walker opened the museum
	# looking at a wall of door, with the scanner outside the field of view and
	# nothing else in sight. So it stands GATE_DEPTH into the hall instead —
	# the vestibule plus the hall's first rows are the passage, the door is a
	# threshold you walk toward, and the scanner is beside it in plain sight.
	# how deep the door stands is a NUMBER, not an eye's call:
	# commons/data/em_layout.json gate.depth_rows (fallback GATE_DEPTH)
	var depth: float = float(layout.get("depth_rows", GATE_DEPTH))
	var z: float = 4.0 + depth - 0.5
	var cols: Array = []
	# the door: bi-parting, sealed, sized to the corridor's clear width
	var door_ps: PackedScene = load(DOOR_SCENE)
	var door: Node3D = door_ps.instantiate() as Node3D
	door.set("width", minf(float(w) - 2.0, 6.0))
	door.set("height", 3.0)
	door.set("leaf_mode", "bi_parting")
	door.set("open_amount", 0.0)
	door.set("with_header", true)
	door.set("with_window", true)
	door.set("with_threshold_light", true)
	door.position = Vector3(w / 2.0, 0.0, z)
	door.name = "ThresholdDoor"
	seg.add_child(door)
	# the door's own collider: one slab across the opening while it is sealed.
	# It is on the segment's StaticBody so the walker meets it; removed on open.
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(minf(float(w) - 2.0, 6.0), 3.0, 0.12)
	cs.shape = bs
	cs.position = Vector3(w / 2.0, 1.5, z)
	solid.add_child(cs)
	cols.append(cs)
	# the jamb piers, so the door reads as an aperture in a wall and not a slab
	# standing in a hall. They leave the walk cells alone (0.5 m deep, at the edges).
	var clear: float = minf(float(w) - 2.0, 6.0)
	for side in [-1.0, 1.0]:
		var px: float = w / 2.0 + side * (clear * 0.5 + (w - clear) * 0.25)
		var pw: float = maxf((float(w) - clear) * 0.5, 0.4)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new(); bm.size = Vector3(pw, 3.2, 0.5)
		mi.mesh = bm; mi.material_override = mat_wall
		mi.position = Vector3(px, 1.6, z)
		seg.add_child(mi)
		var pc := CollisionShape3D.new()
		var pbs := BoxShape3D.new(); pbs.size = bm.size; pc.shape = pbs
		pc.position = mi.position
		solid.add_child(pc)
	# the scanner, on the right-hand jamb, at hand height, facing the visitor
	var sc_ps: PackedScene = load(SCANNER_SCENE)
	var scanner: Node3D = sc_ps.instantiate() as Node3D
	scanner.name = "ThresholdScanner"
	scanner.position = Vector3(w / 2.0 + clear * 0.5 + 0.35, 1.25, z - 0.35)
	scanner.rotation_degrees.y = 180.0            # face back into the vestibule
	seg.add_child(scanner)
	return {"door": door, "scanner": scanner, "colliders": cols, "open": false,
		"z": z, "clear": clear,
		"open_seconds": layout.get("open_seconds", OPEN_SECONDS),
		"click_reach_m": layout.get("click_reach_m", SCAN_REACH_M),
		"click_cone_rad": layout.get("click_cone_rad", SCAN_CONE)}


## Is this desktop click on the scanner? Camera within reach and inside the cone.
static func clicked(cam: Camera3D, scanner: Node3D, reach: float = SCAN_REACH_M,
		cone: float = SCAN_CONE) -> bool:
	if cam == null or scanner == null or not is_instance_valid(scanner):
		return false
	var to: Vector3 = scanner.global_position - cam.global_position
	if to.length() > reach:
		return false
	return (-cam.global_transform.basis.z).angle_to(to.normalized()) < cone


## Step an opening gate. `t` is seconds since the grant; returns true while it
## is still moving. Removes the colliders on the first step, so the visitor may
## walk through as the leaves part rather than waiting for the animation.
static func step_open(gate: Dictionary, t: float) -> bool:
	# the same trap: a freed door cast to Node3D throws, and the throw lands in
	# the museum's _process, where it stops the streaming check below it
	var door_v: Variant = gate.get("door")
	if door_v == null or not is_instance_valid(door_v):
		return false
	var door: Node3D = door_v as Node3D
	if not bool(gate.get("cleared", false)):
		for c in gate.get("colliders", []):
			if is_instance_valid(c):
				(c as Node).queue_free()
		gate["cleared"] = true
	var u: float = clampf(t / float(gate.get("open_seconds", OPEN_SECONDS)), 0.0, 1.0)
	door.set("open_amount", u)
	if door.has_method("apply_grid_config"):
		door.call("apply_grid_config", {"open_amount": u})
	return u < 1.0


## Move any prop standing where the scanner goes (the fire extinguisher on that
## jamb, usually) along the wall, out of the visitor's reach for the glass.
## Returns how many were moved.
static func clear_props(seg: Node3D, scanner: Node3D, radius: float = 1.4) -> int:
	if scanner == null:
		return 0
	var moved: int = 0
	var stack: Array = [seg]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if not (n is Node3D) or n == scanner or n.is_ancestor_of(scanner):
			continue
		var n3: Node3D = n as Node3D
		if not n3.has_meta("artifact_lookup_name"):
			continue
		var tok := String(n3.get_meta("artifact_lookup_name"))
		if tok != "fire_extinguisher" and tok != "emergency_button" and tok != "exit_sign":
			continue
		if n3.global_position.distance_to(scanner.global_position) > radius:
			continue
		var away: float = 2.0 if n3.global_position.x < scanner.global_position.x else -2.0
		n3.global_position += Vector3(0.0, 0.0, away)   # along the vestibule, off the jamb
		moved += 1
	return moved
