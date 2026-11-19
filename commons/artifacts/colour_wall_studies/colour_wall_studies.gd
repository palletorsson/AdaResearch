extends Node3D
## Original wall studies after Gillick: interval, layered crossing, open composition.
## When `gallery_bay` is true (Floor 35 Color_Walls), expands into a 9-work
## collection hung cleanly across all three architectural gallery walls fitted
## between the four West Bay concrete columns.
signal state_changed
const PALETTE: Array[Color] = [Color("e74889"),Color("efa72d"),Color("129681"),Color("7652a8"),Color("ee6932"),Color("344f85")]
var gallery_bay: bool = false
var intervals: Array[Node3D] = []
var louver_bars: Array[Node3D] = []
var h_intervals: Array[Node3D] = []
var uprights: Array[Node3D] = []
var depth_bars: Array[Dictionary] = []
var rails: Array[Node3D] = []
var omittables: Array[Node3D] = []
var materials: Array[StandardMaterial3D] = []
var spacing := 0.16
var projection := 0.18
var omitted := false
var colour_rule := 0
var roots: Array[Node3D] = []

func _ready() -> void:
	if gallery_bay:
		_build_three_wall_collection()
	else:
		_build_original_triptych()
	set_spacing(spacing)
	set_projection(projection)
	set_colour_rule(0)
	if gallery_bay:
		set_meta("em_visibility_bounds", AABB(Vector3(-7.1, 0.2, -3.1), Vector3(14.2, 4.8, 6.2)))
	else:
		set_meta("em_visibility_bounds", AABB(Vector3(-8.6, 0.8, -4.1), Vector3(17.2, 3.4, 1.1)))

func _build_original_triptych() -> void:
	for x in [-5.8,0.0,5.8]:
		var node := Node3D.new()
		node.position = Vector3(x,2.35,-3.85)
		add_child(node)
		roots.append(node)
	for i in 24:
		intervals.append(_bar(roots[0],Vector2(0,-1.30),Vector2(0,1.30),0.072,0.18,i))
	for i in 6:
		var a := (i-2.5)*0.46
		var upright := _bar(roots[1],Vector2(a,-1.30),Vector2(a,1.30),0.14,0.18,i)
		uprights.append(upright)
		var crossing := _bar(roots[1],Vector2(-1.30,a),Vector2(1.30,a),0.14,0.14,i+2)
		crossing.position.z = 0.02
	# Independent straight segments, intentionally an open composition rather than a network simulator.
	var ends := [
		[Vector2(-1.3,1.2),Vector2(-1.3,-1.15)],
		[Vector2(-1.3,-1.15),Vector2(-0.2,-1.15)],
		[Vector2(-0.2,-1.15),Vector2(-0.2,0.05)],
		[Vector2(-0.2,0.05),Vector2(0.85,0.05)],
		[Vector2(0.85,0.05),Vector2(0.85,1.2)],
		[Vector2(-1.3,1.2),Vector2(0.85,1.2)],
		[Vector2(-0.65,-0.50),Vector2(-0.65,0.60)],
		[Vector2(-0.65,0.60),Vector2(0.35,0.60)],
		[Vector2(0.35,0.60),Vector2(0.35,1.6)],
		[Vector2(1.4,-1.4),Vector2(1.4,0.6)],
		[Vector2(0.35,-0.55),Vector2(1.4,-0.55)],
		[Vector2(-1.7,-0.1),Vector2(-1.3,-0.1)]
	]
	for i in ends.size():
		var segment := _bar(roots[2],ends[i][0],ends[i][1],0.105,0.14,i,true)
		segment.position.z = 0.12
		rails.append(segment)
	omittables.append(rails[5])

func _add_work_root(label: String, pos: Vector3, yaw_deg: float) -> Node3D:
	var node := Node3D.new()
	node.name = label
	node.position = pos
	node.rotation_degrees.y = yaw_deg
	add_child(node)
	roots.append(node)
	return node

func _build_three_wall_collection() -> void:
	# 9 curated Gillick-lineage anodized wall works across the 3 column-fitted gallery walls:
	# - WEST BACK WALL (local z = -2.84, x in [-6.55..+6.55], facing +Z): 5 works
	# - NORTH RETURN WALL (local x = +6.84, z in [-2.55..+2.55], facing -X -> yaw -90): 2 works
	# - SOUTH RETURN WALL (local x = -6.84, z in [-2.55..+2.55], facing +X -> yaw +90): 2 works
	var wz := -2.84
	var wy := 2.40

	# 1. West Wall [-4.95]: Vertical Interval Study (16 anodized fins)
	var w1 := _add_work_root("Work_01_Intervals", Vector3(-4.95, wy, wz), 0.0)
	for i in 16:
		intervals.append(_bar(w1, Vector2(0, -1.18), Vector2(0, 1.18), 0.068, 0.18, i))

	# 2. West Wall [-2.50]: Stepped Cantilever Register (9 staggered deep horizontal extrusions)
	var w2 := _add_work_root("Work_02_CantileverRegister", Vector3(-2.50, wy, wz), 0.0)
	var shelf_specs: Array = [
		[-0.95, 0.35, 1.05, 0.5], [-0.45, 0.95, 0.78, 0.9], [-0.95, 0.70, 0.50, 0.65],
		[-0.25, 0.95, 0.22, 1.0], [-0.95, 0.25, -0.06, 0.75], [-0.55, 0.95, -0.34, 0.85],
		[-0.95, 0.60, -0.62, 0.6], [-0.15, 0.95, -0.90, 0.95], [-0.95, 0.15, -1.15, 0.55],
	]
	for i in shelf_specs.size():
		var s: Array = shelf_specs[i]
		var bar := _bar(w2, Vector2(float(s[0]), float(s[2])), Vector2(float(s[1]), float(s[2])), 0.12, 0.22, i + 1, true)
		bar.position.z = 0.10
		depth_bars.append({"node": bar, "factor": float(s[3])})
		if i == 4:
			omittables.append(bar)

	# 3. West Wall [0.00]: Centerpiece Layered Crossing Grid (6x6 upright & horizontal beams)
	var w3 := _add_work_root("Work_03_LayeredCrossing", Vector3(0.0, wy, wz), 0.0)
	for i in 6:
		var a := (float(i) - 2.5) * 0.42
		var upright := _bar(w3, Vector2(a, -1.20), Vector2(a, 1.20), 0.13, 0.18, i)
		uprights.append(upright)
		var crossing := _bar(w3, Vector2(-1.20, a), Vector2(1.20, a), 0.13, 0.14, i + 2)
		crossing.position.z = 0.03
		if i == 2:
			omittables.append(crossing)

	# 4. West Wall [+2.50]: Rhythmic Louver Screen (12 fins + 3 horizontal datum rails)
	var w4 := _add_work_root("Work_04_LouverScreen", Vector3(2.50, wy, wz), 0.0)
	for i in 12:
		var fin := _bar(w4, Vector2(0, -1.08), Vector2(0, 1.08), 0.055, 0.26, i + 3)
		fin.position.z = 0.10
		louver_bars.append(fin)
		depth_bars.append({"node": fin, "factor": 0.45 + 0.35 * float(i % 2)})
	for k in 3:
		var ry := (float(k) - 1.0) * 0.84
		var rail := _bar(w4, Vector2(-0.98, ry), Vector2(0.98, ry), 0.085, 0.12, k + 1, true)
		rail.position.z = 0.02

	# 5. West Wall [+4.95]: Open Linear Composition (grooved straight segments)
	var w5 := _add_work_root("Work_05_OpenLinear", Vector3(4.95, wy, wz), 0.0)
	var ends: Array = [
		[Vector2(-0.95, 0.92), Vector2(-0.95, -0.92)],
		[Vector2(-0.95, -0.92), Vector2(-0.15, -0.92)],
		[Vector2(-0.15, -0.92), Vector2(-0.15, 0.04)],
		[Vector2(-0.15, 0.04), Vector2(0.66, 0.04)],
		[Vector2(0.66, 0.04), Vector2(0.66, 0.92)],
		[Vector2(-0.95, 0.92), Vector2(0.66, 0.92)],
		[Vector2(-0.48, -0.40), Vector2(-0.48, 0.48)],
		[Vector2(-0.48, 0.48), Vector2(0.28, 0.48)],
		[Vector2(0.28, 0.48), Vector2(0.28, 1.22)],
		[Vector2(1.02, -1.10), Vector2(1.02, 0.48)],
		[Vector2(0.28, -0.44), Vector2(1.02, -0.44)],
		[Vector2(-1.18, -0.08), Vector2(-0.95, -0.08)],
	]
	for i in ends.size():
		var seg := _bar(w5, ends[i][0], ends[i][1], 0.095, 0.15, i, true)
		seg.position.z = 0.11
		rails.append(seg)
	omittables.append(rails[5])

	# 6. North Return Wall [z = -1.25]: Nested Relief Frames (4 concentric stepped frames)
	var w6 := _add_work_root("Work_06_NestedFrames", Vector3(6.84, wy, -1.25), -90.0)
	var frame_sizes: Array[Vector2] = [Vector2(0.95, 1.15), Vector2(0.72, 0.88), Vector2(0.49, 0.62), Vector2(0.27, 0.36)]
	for f in frame_sizes.size():
		var hx := frame_sizes[f].x
		var hy := frame_sizes[f].y
		var z_off := 0.06 + float(f) * 0.07
		var frame_edges: Array = [
			[Vector2(-hx, hy), Vector2(hx, hy)],
			[Vector2(hx, hy), Vector2(hx, -hy)],
			[Vector2(hx, -hy), Vector2(-hx, -hy)],
			[Vector2(-hx, -hy), Vector2(-hx, hy)],
		]
		for e in frame_edges.size():
			var edge := _bar(w6, frame_edges[e][0], frame_edges[e][1], 0.09, 0.14, f * 2 + e, true)
			edge.position.z = z_off
			depth_bars.append({"node": edge, "factor": 0.25 + float(f) * 0.25})
			if f == 2 and e == 0:
				omittables.append(edge)

	# 7. North Return Wall [z = +1.25]: Horizontal Banded Partition (12 horizontal rails)
	var w7 := _add_work_root("Work_07_HorizontalRegister", Vector3(6.84, wy, 1.25), -90.0)
	for i in 12:
		var hbar := _bar(w7, Vector2(-0.98, 0.0), Vector2(0.98, 0.0), 0.078, 0.18, i + 2, true)
		hbar.position.z = 0.09
		h_intervals.append(hbar)

	# 8. South Return Wall [z = -1.25]: Shadow Comb Relief (10 deep vertical fins + 2 transoms)
	var w8 := _add_work_root("Work_08_ShadowComb", Vector3(-6.84, wy, -1.25), 90.0)
	for i in 10:
		var bx := (float(i) - 4.5) * 0.20
		var fin := _bar(w8, Vector2(bx, -1.12), Vector2(bx, 1.12), 0.062, 0.28, i + 4)
		fin.position.z = 0.12
		depth_bars.append({"node": fin, "factor": 0.55 + 0.45 * sin(float(i) * 0.7)})
	for t in [-0.55, 0.55]:
		var tr := _bar(w8, Vector2(-1.02, t), Vector2(1.02, t), 0.095, 0.12, 1 if t < 0 else 4, true)
		tr.position.z = 0.03
		if t > 0:
			omittables.append(tr)

	# 9. South Return Wall [z = +1.25]: Modular Colour Matrix (stepped extruded bar blocks)
	var w9 := _add_work_root("Work_09_ModularMatrix", Vector3(-6.84, wy, 1.25), 90.0)
	var idx := 0
	for row in range(5):
		for col in range(4):
			if (row == 1 and col == 2) or (row == 3 and col == 1):
				continue  # Deliberate architectural negative-space apertures
			var cx := (float(col) - 1.5) * 0.48
			var cy := (float(row) - 2.0) * 0.46
			var blk := _bar(w9, Vector2(cx - 0.19, cy), Vector2(cx + 0.19, cy), 0.28, 0.16 + float((row + col) % 3) * 0.06, idx, true)
			blk.position.z = 0.08 + float((row + col) % 3) * 0.03
			depth_bars.append({"node": blk, "factor": 0.3 + float((row + col) % 3) * 0.3})
			if row == 2 and col == 2:
				omittables.append(blk)
			idx += 1

func _bar(parent: Node3D,a: Vector2,b: Vector2,width: float,depth: float,index: int,groove := false) -> Node3D:
	var node := Node3D.new()
	var delta := b-a
	node.position = Vector3((a.x+b.x)/2,(a.y+b.y)/2,0)
	node.rotation.z = -atan2(delta.x,delta.y)
	node.set_meta("palette_index",index)
	parent.add_child(node)
	var mat := StandardMaterial3D.new()
	mat.metallic = 0.28
	mat.roughness = 0.38
	mat.set_meta("palette_index",index)
	materials.append(mat)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width,delta.length(),depth)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = mat
	node.add_child(visual)
	var body := StaticBody3D.new()
	body.name = "Solid"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collision.shape = shape
	body.add_child(collision)
	node.add_child(body)
	if groove:
		# A visible face groove recalls an extrusion; this is not its engineering profile.
		var dark := StandardMaterial3D.new()
		dark.albedo_color = Color("252930")
		dark.roughness = 0.5
		var slot := MeshInstance3D.new()
		var slot_mesh := BoxMesh.new()
		slot_mesh.size = Vector3(width*0.2,maxf(delta.length()-0.05,0.01),0.003)
		slot.mesh = slot_mesh
		slot.material_override = dark
		slot.position.z = depth/2+0.002
		node.add_child(slot)
	return node

func set_spacing(value: float) -> void:
	spacing = clampf(value,0.11,0.21)
	var n := intervals.size()
	var s := spacing * (0.78 if gallery_bay else 1.0)
	for i in n:
		intervals[i].position.x = (float(i) - float(n - 1) * 0.5) * s
	for i in louver_bars.size():
		louver_bars[i].position.x = (float(i) - float(louver_bars.size() - 1) * 0.5) * (s * 1.10)
	for i in h_intervals.size():
		h_intervals[i].position.y = (float(i) - float(h_intervals.size() - 1) * 0.5) * (s * 1.15)
	state_changed.emit()

func set_projection(value: float) -> void:
	projection = clampf(value,0.18,0.52)
	for bar in uprights: bar.position.z = projection
	for entry in depth_bars:
		var node: Node3D = entry["node"]
		var factor: float = float(entry["factor"])
		node.position.z = 0.06 + (projection - 0.10) * factor
	state_changed.emit()

func set_omitted(value: bool) -> void:
	omitted = value
	for target in omittables:
		target.visible = not omitted
		var solid := target.get_node_or_null("Solid") as StaticBody3D
		if solid != null:
			solid.collision_layer = 0 if omitted else 1
	state_changed.emit()

func set_colour_rule(value: int) -> void:
	colour_rule = clampi(value,0,2)
	for mat in materials:
		var index: int = mat.get_meta("palette_index")
		var choice := index%PALETTE.size()
		if colour_rule == 1: choice = floori(index/4.0)%PALETTE.size()
		if colour_rule == 2: choice = 0
		mat.albedo_color = PALETTE[choice]
	state_changed.emit()

func reset() -> void:
	set_spacing(0.16)
	set_projection(0.18)
	set_omitted(false)
	set_colour_rule(0)
