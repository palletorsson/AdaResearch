extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BounceArenaRoom

## @identity
## name: "Bounce & play"
## tier: large
## lineage: Soft-body bounce at room scale — trampolines (pinned-edge cloth) and jelly pillars
##   share one Verlet world. A ball drops onto a trampoline, the sheet stores the impact and
##   throws it back; the pillars wobble when grazed. Energy moves between bodies, never lost to a crack.
## essence: A room-scale bounce arena you walk into: two trampolines, soft pillars in the corners,
##   and a jelly ball hopping between them. The ball lands, the trampoline dips and flings it up;
##   it grazes a pillar and the pillar shivers. A whole space built so a body can bounce, not break.
## truth: "A BODY THAT BOUNCES INSTEAD OF BREAKING"
## applications: trampoline parks, crash arenas, soft playgrounds, landing pads — spaces that catch and return.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var stiffness: float = 0.86
@export var floor_col: Color = Color(0.11, 0.12, 0.16)
@export var tramp_col: Color = Color(0.30, 0.78, 0.62)
@export var pillar_col: Color = Color(0.86, 0.36, 0.50)
@export var ball_col: Color = Color(0.98, 0.80, 0.30)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _tramps: Array = []     # each: { sim, mi:MeshInstance3D, mesh:ArrayMesh, indices, origin:Vector3 }
var _pillars: Array = []    # each: { node, sim, mm:MultiMesh, base:Vector3 }
var _ball_sim = null
var _ball_mm: MultiMesh = null
var _ball_node: Node3D = null
var _tramp_centres: Array = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("stiffness"):
		stiffness = clampf(float(config["stiffness"]), 0.6, 0.96)
	if config.has("ball_col"):
		ball_col = _parse_color(config["ball_col"], ball_col)
	if config.has("tramp_col"):
		tramp_col = _parse_color(config["tramp_col"], tramp_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_tramps.clear()
	_pillars.clear()
	_tramp_centres.clear()
	_ball_sim = null
	_ball_mm = null
	_ball_node = null
	_build()


func _build() -> void:
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), _matte_mat(floor_col, 0.9)))

	# Two trampolines (pinned-edge cloth, lying flat at hip height).
	_add_trampoline(Vector3(-1.5, 0.55, 0.0))
	_add_trampoline(Vector3(1.5, 0.55, 0.0))

	# Soft pillars in the corners.
	for corner in [Vector3(-2.6, 0.0, -2.6), Vector3(2.6, 0.0, -2.6), Vector3(-2.6, 0.0, 2.6), Vector3(2.6, 0.0, 2.6)]:
		_add_pillar(corner)

	# The bouncing jelly ball — starts above the first trampoline.
	_add_ball(Vector3(-1.5, 1.6, 0.0))

	add_child(_billboard_label("A BODY THAT BOUNCES INSTEAD OF BREAKING", Vector3(0.0, 3.6, 0.0), 26, label_col))


func _add_trampoline(centre: Vector3) -> void:
	var cols: int = 9
	var rows: int = 9
	var cell: float = 0.16
	# Lay the cloth flat: build it vertically, then we read X/Z as the sheet plane by
	# rotating coordinates — simplest is to build a grid in XZ directly here.
	var sim = SBShapes.new() if false else _make_flat_sheet(cols, rows, cell, centre)
	sim.gravity = Vector3(0.0, -4.0, 0.0)
	sim.damping = 0.93
	sim.stiffness = stiffness
	sim.floor_y = 0.0
	for _i in 30:
		sim.step()

	# Frame ring + legs.
	var half: float = float(cols - 1) * cell * 0.5
	add_child(_box(centre + Vector3(0.0, 0.0, 0.0), Vector3(half * 2.0 + 0.1, 0.04, half * 2.0 + 0.1), _matte_mat(Color(0.2, 0.21, 0.25), 0.8)))
	for lx in [-half, half]:
		for lz in [-half, half]:
			add_child(_cylinder_between(centre + Vector3(lx, 0.0, lz), Vector3(centre.x + lx, 0.0, centre.z + lz), 0.03, _steel_mat(Color(0.4, 0.42, 0.46))))

	var indices := PackedInt32Array()
	for r in range(rows - 1):
		for c in range(cols - 1):
			var i0: int = r * cols + c
			var i1: int = r * cols + c + 1
			var i2: int = (r + 1) * cols + c + 1
			var i3: int = (r + 1) * cols + c
			indices.append_array([i0, i1, i2, i0, i2, i3])

	var mesh := ArrayMesh.new()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tramp_col
	mat.roughness = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = tramp_col
	mat.emission_energy_multiplier = 0.2 if emissive else 0.0
	mi.material_override = mat
	add_child(mi)

	var rec := { "sim": sim, "mi": mi, "mesh": mesh, "indices": indices, "cols": cols, "rows": rows }
	_tramps.append(rec)
	_tramp_centres.append(centre)
	_refresh_tramp(_tramps.size() - 1)


func _make_flat_sheet(cols: int, rows: int, cell: float, centre: Vector3):
	# A grid in the XZ plane with the four edges pinned — a trampoline membrane.
	var sim = load("res://commons/soft_body/soft_body_sim.gd").new()
	sim.topology = "cloth_grid"
	sim.grid_cols = cols
	sim.grid_rows = rows
	var ox: float = -float(cols - 1) * 0.5 * cell
	var oz: float = -float(rows - 1) * 0.5 * cell
	for r in range(rows):
		for c in range(cols):
			var pos: Vector3 = centre + Vector3(ox + float(c) * cell, 0.0, oz + float(r) * cell)
			var is_edge: bool = (c == 0 or c == cols - 1 or r == 0 or r == rows - 1)
			sim.add_particle(pos, is_edge)
	for r in range(rows):
		for c in range(cols):
			var idx: int = r * cols + c
			if c < cols - 1:
				sim.add_spring(idx, idx + 1)
			if r < rows - 1:
				sim.add_spring(idx, idx + cols)
	for r in range(rows - 1):
		for c in range(cols - 1):
			var idx2: int = r * cols + c
			sim.add_spring(idx2, idx2 + cols + 1)
			sim.add_spring(idx2 + 1, idx2 + cols)
	return sim


func _refresh_tramp(idx: int) -> void:
	var rec: Dictionary = _tramps[idx]
	var sim = rec["sim"]
	var mesh: ArrayMesh = rec["mesh"]
	var indices: PackedInt32Array = rec["indices"]
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	for i in sim.positions.size():
		verts.append(sim.positions[i])
		normals.append(Vector3.UP)
	_recompute_normals_local(verts, indices, normals)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _add_pillar(base: Vector3) -> void:
	var sim = SBShapes.make_jelly_box(0.6, stiffness)
	sim.floor_y = 0.0
	sim.gravity = Vector3(0.0, -2.4, 0.0)
	sim.damping = 0.92
	var start: int = sim.positions.size()
	var hs: float = 0.3
	for z in [-1, 1]:
		for y in [-1, 1]:
			for x in [-1, 1]:
				sim.add_particle(base + Vector3(x * hs, y * hs + 0.6 + 0.63, z * hs), false)
	for i in range(8):
		for j in range(i + 1, 8):
			sim.add_spring(start + i, start + j)
	for k in range(8):
		sim.add_spring(start - 8 + k, start + k)
	for _i in 40:
		sim.step()

	var node := Node3D.new()
	node.position = base
	add_child(node)
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	sm.radial_segments = 8
	sm.rings = 4
	mm.mesh = sm
	mm.instance_count = sim.positions.size()
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pillar_col
	mat.roughness = 0.4
	mat.emission_enabled = true
	mat.emission = pillar_col
	mat.emission_energy_multiplier = 0.35 if emissive else 0.0
	mmi.material_override = mat
	node.add_child(mmi)
	_pillars.append({ "node": node, "sim": sim, "mm": mm, "base": base })
	_refresh_pillar(_pillars.size() - 1)


func _refresh_pillar(idx: int) -> void:
	var pil: Dictionary = _pillars[idx]
	var sim = pil["sim"]
	var mm: MultiMesh = pil["mm"]
	var base: Vector3 = pil["base"]
	for i in sim.positions.size():
		var t := Transform3D.IDENTITY
		t.origin = sim.positions[i] - base
		mm.set_instance_transform(i, t)


func _add_ball(pos: Vector3) -> void:
	var sim = SBShapes.make_jelly_box(0.42, 0.82, pos)
	sim.floor_y = 0.0
	sim.gravity = Vector3(0.0, -5.0, 0.0)
	sim.damping = 0.95
	_ball_sim = sim
	for _i in 10:
		sim.step()

	_ball_node = Node3D.new()
	add_child(_ball_node)
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	sm.radial_segments = 10
	sm.rings = 6
	mm.mesh = sm
	mm.instance_count = sim.positions.size()
	_ball_mm = mm
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ball_col
	mat.roughness = 0.35
	mat.emission_enabled = true
	mat.emission = ball_col
	mat.emission_energy_multiplier = 0.45 if emissive else 0.0
	mmi.material_override = mat
	_ball_node.add_child(mmi)
	_refresh_ball()


func _refresh_ball() -> void:
	if _ball_mm == null:
		return
	for i in _ball_sim.positions.size():
		var t := Transform3D.IDENTITY
		t.origin = _ball_sim.positions[i]
		_ball_mm.set_instance_transform(i, t)


func _ball_centre() -> Vector3:
	var c := Vector3.ZERO
	for i in _ball_sim.positions.size():
		c += _ball_sim.positions[i]
	return c / float(_ball_sim.positions.size())


func _recompute_normals_local(verts: PackedVector3Array, indices: PackedInt32Array, out_normals: PackedVector3Array) -> void:
	for i in out_normals.size():
		out_normals[i] = Vector3.ZERO
	var tri_count: int = indices.size() / 3
	for k in range(tri_count):
		var ia: int = indices[k * 3]
		var ib: int = indices[k * 3 + 1]
		var ic: int = indices[k * 3 + 2]
		var n: Vector3 = (verts[ib] - verts[ia]).cross(verts[ic] - verts[ia])
		if n.length_squared() > 1e-12:
			n = n.normalized()
		out_normals[ia] += n
		out_normals[ib] += n
		out_normals[ic] += n
	for i in out_normals.size():
		var nn: Vector3 = out_normals[i]
		out_normals[i] = nn.normalized() if nn.length_squared() > 1e-12 else Vector3.UP


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# Ball physics + a trampoline interaction: when the ball is low over a trampoline
	# centre, push the sheet down and bounce the ball back up.
	if _ball_sim != null:
		_ball_sim.step()
		var bc: Vector3 = _ball_centre()
		for ti in range(_tramps.size()):
			var centre: Vector3 = _tramp_centres[ti]
			var flat := Vector2(bc.x - centre.x, bc.z - centre.z)
			if flat.length() < 0.6 and bc.y < centre.y + 0.2 and bc.y > centre.y - 0.4:
				# Bounce: reflect downward velocity into an upward toss.
				for i in _ball_sim.positions.size():
					var vy: float = _ball_sim.positions[i].y - _ball_sim.prev_positions[i].y
					if vy < 0.0:
						_ball_sim.prev_positions[i].y = _ball_sim.positions[i].y + vy * 0.85
				# Dip the sheet under the ball.
				var sim = _tramps[ti]["sim"]
				for i in sim.positions.size():
					if not sim.pinned[i]:
						var d := Vector2(sim.positions[i].x - bc.x, sim.positions[i].z - bc.z).length()
						if d < 0.35:
							sim.positions[i].y -= 0.05 * (1.0 - d / 0.35)
		# Recycle: if the ball falls to the floor, toss it back over a trampoline.
		if bc.y < 0.25:
			var target: Vector3 = _tramp_centres[int(_t) % maxi(_tramp_centres.size(), 1)]
			var lift := Vector3(target.x - bc.x, 1.6, target.z - bc.z) - Vector3(bc.x, bc.y, bc.z) + Vector3(bc.x, 0, bc.z)
			for i in _ball_sim.positions.size():
				var local: Vector3 = _ball_sim.positions[i] - bc
				_ball_sim.positions[i] = Vector3(target.x, 1.6, target.z) + local
				_ball_sim.prev_positions[i] = _ball_sim.positions[i]
		_refresh_ball()

	# Settle trampolines back toward flat each frame, then refresh.
	for ti in range(_tramps.size()):
		_tramps[ti]["sim"].step()
		_refresh_tramp(ti)

	# Wobble the corner pillars gently.
	for pi in range(_pillars.size()):
		var sim2 = _pillars[pi]["sim"]
		var w: float = sin(_t * 1.2 + float(pi)) * 0.01
		for i in sim2.positions.size():
			if sim2.positions[i].y > 0.9:
				sim2.positions[i].x += w
		sim2.step()
		_refresh_pillar(pi)
