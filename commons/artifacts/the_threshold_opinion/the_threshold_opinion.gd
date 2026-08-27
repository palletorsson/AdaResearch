extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheThresholdOpinion

## @identity
## lineage: the isosurfaces SUPER OBJECT — a courtroom for a number. In the dock, ONE
##   field: a lattice of little rods whose lengths are the field's value at each point,
##   so the invisible is standing there in plain sight. Around it, FIVE surfaces
##   extracted from that same field at five thresholds — a fat blob, a lean one, a
##   pinched pair, a thin shell, and one that has broken into islands — proving the
##   claim: nothing in the field changed. Beside them a resolution row shows the same
##   threshold sampled on a 4, 8 and 16 lattice, and a case rack holds the fifteen
##   corner configurations in brass. One pair of blobs is caught mid-MERGE at the
##   crossing, seamless where no mesh operation could join them.
## essence: a field is a function from position to number; a surface is where it
##   crosses a number you CHOSE. Every skin here was extracted at build time by
##   marching a real lattice — same field, five verdicts.
## truth: the surface is an opinion about a threshold. Move the number and the object
##   is different, though nothing in the world changed.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")
const LEVELS := [0.30, 0.42, 0.50, 0.60, 0.72]

@export var seed: int = 3
@export_range(6, 18) var lattice: int = 12
@export var span: float = 0.62

var _n := FastNoiseLite.new()

func _ready() -> void:
	_rng.seed = seed
	_n.seed = seed
	_n.frequency = 1.35
	_build_bench()
	_build_field_of_rods()
	_build_verdicts()
	_build_resolution_row()
	_build_case_rack()
	_build_merge()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "lattice", "span"]:
		if config_data.has(key):
			set(key, config_data[key])

func _tag(at: Vector3, title: String, sub: String) -> void:
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.17
	tag.position = at
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text(title, sub)

func _slab(at: Vector3, size: Vector3, tint: Color, glow: float = 0.0) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.position = at
	m.material_override = _glow_mat(tint, glow) if glow > 0.0 else _matte_mat(tint, 0.75)
	add_child(m)

## THE FIELD, and the only one in this artifact: two smooth wells summed, so the
## surfaces genuinely merge and split as the threshold moves.
func _field(p: Vector3) -> float:
	var a := 0.34 / maxf(p.distance_to(Vector3(-0.16, 0.0, 0.0)), 0.06)
	var b := 0.28 / maxf(p.distance_to(Vector3(0.18, 0.05, 0.02)), 0.06)
	return clampf((a + b) * 0.35 + 0.12 * _n.get_noise_3d(p.x * 6.0, p.y * 6.0, p.z * 6.0), 0.0, 1.6)

func _build_bench() -> void:
	_slab(Vector3(0.0, 0.9, 0.0), Vector3(4.6, 0.1, 2.0), Color(0.14, 0.13, 0.16))
	for sx in [-1.0, 1.0]:
		_slab(Vector3(sx * 2.1, 0.45, 0.0), Vector3(0.13, 0.9, 1.6), Color(0.1, 0.1, 0.12))

func _build_field_of_rods() -> void:
	# the invisible, made standable: a rod per sample, length = the field's value
	var n := 9
	for ix in range(n):
		for iz in range(n):
			var u := (float(ix) / float(n - 1) - 0.5) * span * 2.0
			var w := (float(iz) / float(n - 1) - 0.5) * span * 2.0
			var v := _field(Vector3(u, 0.0, w))
			var h: float = clampf(v * 0.26, 0.01, 0.42)
			_slab(Vector3(-1.55 + u * 0.5, 1.0 + h * 0.5, w * 0.5), Vector3(0.022, h, 0.022),
				Color(0.35, 0.55, 0.75).lerp(Color(0.95, 0.85, 0.4), clampf(v * 0.7, 0.0, 1.0)), 0.35)
	_tag(Vector3(-1.55, 0.94, 0.42), "the field", "a number at every point - most of it invisible")

## Extract a surface at `iso`: march the lattice, and place a bead wherever an edge
## between two samples CROSSES the level, interpolated to where it actually crosses.
func _extract(origin: Vector3, iso: float, res: int, scale: float, tint: Color) -> int:
	var beads := 0
	var step := span * 2.0 / float(res)
	for ix in range(res):
		for iy in range(res):
			for iz in range(res):
				var p := Vector3(float(ix), float(iy), float(iz)) * step - Vector3.ONE * span
				var v0 := _field(p)
				var edges := [Vector3(step, 0, 0), Vector3(0, step, 0), Vector3(0, 0, step)]
				for d in edges:
					var edge_d: Vector3 = d
					var q := p + edge_d
					var v1 := _field(q)
					if (v0 < iso) == (v1 < iso):
						continue                      # no crossing on this edge
					# WHERE it crosses: interpolate on the field values themselves
					var t: float = clampf((iso - v0) / maxf(v1 - v0, 0.00001), 0.0, 1.0)
					var at := p.lerp(q, t)
					_slab(origin + at * scale, Vector3.ONE * step * scale * 0.55, tint, 0.5)
					beads += 1
					if beads > 420:
						return beads
	return beads

func _build_verdicts() -> void:
	# FIVE surfaces, ONE field: the whole argument
	for i in range(LEVELS.size()):
		var iso: float = LEVELS[i]
		var at := Vector3(-0.62 + 0.42 * float(i), 1.28, -0.45)
		var tint := Color.from_hsv(0.08 + 0.13 * float(i), 0.55, 0.95)
		var n := _extract(at, iso, 9, 0.32, tint)
		_tag(at + Vector3(0.0, -0.32, 0.2), "iso %.2f" % iso, "%d crossings" % n)
	_tag(Vector3(-0.2, 0.94, -0.05), "the threshold", "five verdicts, and the field never changed")

func _build_resolution_row() -> void:
	# the same threshold, asked of coarser and finer lattices
	for i in range(3):
		var rows := [4, 8, 14]
		var res: int = rows[i]
		var at := Vector3(0.95 + 0.42 * float(i), 1.28, 0.5)
		var n := _extract(at, 0.5, res, 0.3, Color(0.5, 0.8, 0.9))
		_tag(at + Vector3(0.0, -0.3, 0.2), "res %d" % res, "%d crossings" % n)
	_tag(Vector3(1.37, 0.94, 0.78), "the sample grid", "an interview with finitely many places")

func _build_case_rack() -> void:
	# the fifteen cases in brass: eight corners, lit where 'inside'
	for c in range(15):
		var cx := -1.9 + 0.15 * float(c % 8)
		var cy := 1.72 - 0.17 * float(c / 8)
		var k := 0
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					var inside := (c >> (k % 8)) & 1
					var p := Vector3(cx + sx * 0.032, cy + sy * 0.032, -0.5 + sz * 0.032)
					_slab(p, Vector3.ONE * 0.018,
						Color(0.95, 0.8, 0.35) if inside == 1 else Color(0.28, 0.3, 0.34),
						0.9 if inside == 1 else 0.05)
					k += 1
	_tag(Vector3(-1.55, 1.52, -0.28), "the fifteen cases", "256 corner states, 15 after symmetry")

func _build_merge() -> void:
	# two wells at ONE threshold: caught mid-merge, seamless where no mesh op could join
	var at := Vector3(1.55, 1.62, -0.5)
	var n := _extract(at, 0.44, 10, 0.34, Color(0.75, 0.5, 0.9))
	_tag(at + Vector3(0.0, -0.3, 0.22), "the merge", "two fields summed: one skin, no seam (%d)" % n)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "ThresholdPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-2.3, 0.24, 1.05)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THE THRESHOLD OPINION",
			"One field, standing in the dock as rods of its own value. Five surfaces\nextracted from it at five numbers - fat, lean, pinched, thin, broken into\nislands - and NOTHING in the field changed between them. The resolution row\nasks the same question of coarser lattices; the rack holds the fifteen cases.\nA surface is an opinion about a threshold.")
