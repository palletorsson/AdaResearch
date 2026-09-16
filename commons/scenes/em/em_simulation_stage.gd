extends RefCounted
## A museum frame around an unmodified, full-scale GridSystem instance.
## Map layers stay in grid coordinates; only the instance's parent transform moves.

static func plan(doc: Dictionary) -> Dictionary:
	var info: Dictionary = doc.get("map_info", {})
	var sim: Dictionary = info.get("museum", {}).get("simulation", {})
	var rows: Array = doc.get("layers", {}).get("structure", [])
	if rows.is_empty():
		return {}
	var sw := 0
	for row in rows:
		sw = maxi(sw, row.size())
	var sd := rows.size()
	var margin := clampi(int(sim.get("margin", 2)), 2, 4)
	var moat := clampi(int(sim.get("padding", 2)), 1, 4)
	var apron := 1
	var pad := margin + moat + apron
	var w := sw + pad * 2
	var d := sd + pad * 2
	var tile: Array = []
	for z in range(d):
		var row: Array = []
		for x in range(w):
			row.append("1" if x < margin or x >= w - margin or z < margin or z >= d - margin else "0")
		tile.append(row)
	return {"map": str(info.get("lookup_name", "")), "source_w": sw, "source_d": sd,
		"w": w, "d": d, "pad": pad, "margin": margin, "moat": moat,
		"depth": clampf(float(sim.get("depth", 2.5)), 1.5, 8.0),
		"glass_height": maxf(3.0, float(info.get("dimensions", {}).get("max_height", 2)) + 0.5),
		"entry": _opening(rows[0], sw), "exit": _opening(rows[-1], sw), "tile": tile}

static func _opening(row: Array, width: int) -> Dictionary:
	# Use an existing floor opening. Never cut the copied map's walls.
	var runs: Array = []
	var start := -1
	for x in range(width + 1):
		var floor_here := x < row.size() and str(row[x]).strip_edges() == "1"
		if floor_here and start < 0:
			start = x
		if not floor_here and start >= 0:
			runs.append(Vector2i(start, x - start))
			start = -1
	var best := Vector2i(-1, 0)
	for run: Vector2i in runs:
		if run.y > best.y or (run.y == best.y and absf(run.x + run.y * 0.5 - width * 0.5) < absf(best.x + best.y * 0.5 - width * 0.5)):
			best = run
	if best.x < 0:
		return {"x": width / 2.0, "width": 0.0}
	return {"x": best.x + best.y * 0.5, "width": minf(2.0, best.y)}

static func build(parent: Node3D, p: Dictionary, z_offset: float) -> Dictionary:
	var frame := Node3D.new()
	frame.name = "SimulationFrame"
	parent.add_child(frame)
	frame.position.z = z_offset
	frame.set_meta("stage_plan", p)
	var solid := StaticBody3D.new()
	solid.name = "FrameCollision"
	frame.add_child(solid)
	var pad := float(p.pad)
	var sw := float(p.source_w)
	var sd := float(p.source_d)
	var w := float(p.w)
	var d := float(p.d)
	var margin := float(p.margin)
	var ax := pad - 1.0
	var az := pad - 1.0
	var aw := sw + 2.0
	var ad := sd + 2.0
	var height := float(p.glass_height)
	var floor_mat := _material(Color(0.25, 0.28, 0.30))
	var trim_mat := _material(Color(0.085, 0.10, 0.12))
	var orange := _material(Color(0.95, 0.43, 0.10))
	var glass := _material(Color(0.55, 0.79, 0.85, 0.085))
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.roughness = 0.15
	# One-metre apron flush with the source grid's floor; no slab across its holes.
	for rect: Rect2 in [Rect2(ax, az, aw, 1), Rect2(ax, az + ad - 1, aw, 1),
		Rect2(ax, az + 1, 1, sd), Rect2(ax + aw - 1, az + 1, 1, sd)]:
		_slab(frame, solid, rect, floor_mat, "Apron")
	# Long glass sides, open top, and thin frame. No transparent lid over the grid.
	for x in [ax, ax + aw]:
		_box(frame, solid, Vector3(x, height / 2, az + ad / 2), Vector3(0.045, height, ad), glass, "GlassSide")
		_box(frame, null, Vector3(x, height, az + ad / 2), Vector3(0.07, 0.07, ad), trim_mat, "UpperFrame")
	# End panes stop at the entry/exit; bridges meet original floor openings.
	var walk: Array = []
	for end in range(2):
		var opening: Dictionary = p.entry if end == 0 else p.exit
		var cx := pad + float(opening.x)
		var gate_w := float(opening.width)
		var z := az if end == 0 else az + ad
		for span: Vector2 in [Vector2(ax, cx - gate_w / 2), Vector2(cx + gate_w / 2, ax + aw)]:
			if span.y > span.x:
				_box(frame, solid, Vector3((span.x + span.y)/2, height/2, z), Vector3(span.y-span.x, height, 0.045), glass, "GlassEnd")
		if gate_w > 0:
			var bridge_z := margin if end == 0 else az + ad
			var bridge := Rect2(cx - gate_w / 2, bridge_z, gate_w, float(p.moat))
			_slab(frame, solid, bridge, floor_mat, "Bridge")
			for edge in [-1, 1]:
				_box(frame, solid, Vector3(cx + edge * (gate_w/2 + 0.04), 0.55, bridge_z + p.moat/2.0), Vector3(0.06, 1.1, p.moat), glass, "BridgeRail")
				_box(frame, null, Vector3(cx + edge * gate_w/2, 1.25, z), Vector3(0.07, 2.5, 0.09), orange, "DoorJamb")
			_box(frame, null, Vector3(cx, 2.5, z), Vector3(gate_w + 0.07, 0.09, 0.09), orange, "DoorHeader")
			var label := Label3D.new()
			label.text = "ENTER / " + str(p.map).trim_prefix("Trans_").to_upper() if end == 0 else "EXIT / MUSEUM"
			label.font_size = 48
			label.pixel_size = 0.003
			label.position = Vector3(cx, 2.8, z - 0.06 if end == 0 else z + 0.06)
			label.rotation.y = 0 if end == 0 else PI
			label.no_depth_test = false
			frame.add_child(label)
			for bz in range(int(bridge_z), int(bridge_z + p.moat)):
				for bx in range(int(ceil(cx-gate_w/2-0.5)), int(ceil(cx+gate_w/2-0.5))):
					walk.append(Vector2i(bx, bz))
		# Gallery rail at the pit edge, interrupted only by the bridge.
		var rail_z := margin if end == 0 else d-margin
		for span: Vector2 in [Vector2(margin, cx-gate_w/2), Vector2(cx+gate_w/2, w-margin)]:
			if span.y > span.x:
				_box(frame, solid, Vector3((span.x+span.y)/2,0.55,rail_z),Vector3(span.y-span.x,1.1,0.055),glass,"GalleryRail")
	for x in [margin, w-margin]:
		_box(frame, solid, Vector3(x,0.55,d/2),Vector3(0.055,1.1,d-margin*2),glass,"GalleryRail")
	for x in [ax,ax+aw]:
		for z in [az,az+ad]:
			_box(frame, null, Vector3(x,height/2,z),Vector3(0.07,height,0.07),trim_mat,"CornerPost")
	# Inner apron walkability, with no invented floor inside the source map.
	for z in range(int(az), int(az+ad)):
		for x in range(int(ax), int(ax+aw)):
			if x == int(ax) or x == int(ax+aw)-1 or z == int(az) or z == int(az+ad)-1:
				walk.append(Vector2i(x,z))
	return {"node": frame, "walk_cells": walk}

static func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	return mat

static func _slab(parent: Node3D, solid: StaticBody3D, r: Rect2, mat: Material, label: String) -> void:
	_box(parent, solid, Vector3(r.position.x+r.size.x/2,-0.1,r.position.y+r.size.y/2),Vector3(r.size.x,0.2,r.size.y),mat,label)

static func _box(parent: Node3D, solid: StaticBody3D, pos: Vector3, size: Vector3, mat: Material, label: String) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = label
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position = pos
	parent.add_child(mesh)
	if solid != null:
		var shape := CollisionShape3D.new()
		shape.name = label
		var collider := BoxShape3D.new()
		collider.size = size
		shape.shape = collider
		shape.position = pos
		solid.add_child(shape)
