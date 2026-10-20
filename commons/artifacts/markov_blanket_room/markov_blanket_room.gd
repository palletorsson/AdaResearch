# MarkovBlanketRoom.gd — stand inside the boundary that makes you a thing
#
# @identity
# essence: a lattice shell you stand inside; internal cells, blanket cells, external cells, and a live search asking whether the inside is still an inside
# desire: learner stops treating a boundary as a drawn line and meets it as a claim that can fail — a separating set is only separating until you take a cell out of it
# critical_parameter: leak — how much of the blanket has been removed (sealed / pinhole / breach / dissolved); under it shell decides how the blanket was built at all
# triggers: none; the search re-runs whenever leak or shell changes, and the verdict plate reports what it found
# emerges: the recognition that "inside" is not a place but a result — it holds only while no path crosses, and the artifact shows the path the moment one does
# relationships: the walkable answer to [[puls_markov]], which shows that a blanket exists; this one asks whether it holds. The one-dimensional case is a bridge — see [[graphtheory]]
# truth: a Markov blanket is a bound on influence, and like every bound it is a claim that can be checked and can turn out false
extends Node3D
class_name MarkovBlanketRoom

## WHAT THIS IS, AND WHY IT COMPUTES INSTEAD OF DRAWING.
##
## Friston's free energy principle calls the states that separate a system's
## interior from its exterior a Markov blanket. It is what makes a thing a thing:
## no influence passes from outside to inside except through it. Ada's Q is the
## critical move on that principle — the partition is relational, plural, and
## somebody chose where to draw it.
##
## A picture of a membrane cannot argue with you. So this does not draw a shell
## and call it a blanket. It builds a lattice, classifies every cell as internal,
## blanket or external, and then runs a breadth-first search from the centre that
## is BLOCKED BY BLANKET CELLS ONLY. If the search reaches an external cell, the
## separation has failed, and the path that broke it is drawn in full.
##
## That makes the claim falsifiable in the room: at `leak = sealed` the search
## must fail to escape, and at `leak = dissolved` it must escape. Both halves
## matter. A version that only ever reported SEPARATED would look identical from
## the usual camera angle and would be arguing nothing.
##
## NO CAMERA, NO WorldEnvironment, NO LIGHT. The artifact this one is kin to,
## puls_markov, installs all three and sets `camera.current = true`, which is why
## it stands in no sequence: dropped into a map it takes the player's eyes. An
## artifact lights nothing but itself.

## How much of the blanket has been taken away. These are fractions of the
## blanket cells removed, chosen so the verdict flips inside the range rather
## than at its end — pinhole usually still separates, breach usually does not.
const LEAKS := {
	"sealed": 0.0,
	"pinhole": 0.02,
	"breach": 0.16,
	"dissolved": 0.55,
}

## How the blanket is built. Not decoration: each makes a different claim about
## what a boundary IS. `shell` is the textbook one cell-layer thick; `patchy` is
## the honest one, a boundary with gaps that still mostly works; `double` is two
## layers with a gap between, which is what an actual membrane looks like; `none`
## removes the blanket entirely so the lattice is one connected region and the
## word "inside" stops meaning anything.
const SHELLS := ["shell", "patchy", "double", "none"]

@export_enum("sealed", "pinhole", "breach", "dissolved") var leak: String = "sealed":
	set(v):
		leak = v
		if is_inside_tree():
			_rebuild()

@export_enum("shell", "patchy", "double", "none") var shell: String = "shell":
	set(v):
		shell = v
		if is_inside_tree():
			_rebuild()

## Cells across the half-width. 6 gives a 13-cell lattice, about 5.4 m at the
## default cell size, which leaves an internal volume a person can stand in.
@export_range(4, 10, 1) var extent: int = 6:
	set(v):
		extent = clampi(v, 4, 10)
		if is_inside_tree():
			_rebuild()

@export var cell_size: float = 0.45
## Where the internal region ends and the blanket begins, in cells.
@export var inner_cells: float = 3.0
## How thick the blanket is, in cells.
@export var blanket_cells: float = 1.4

## Seeded, so two placements of this token are the same room. Unseeded randf in
## an artifact means five variants are five different objects and every verdict
## about it is a fact about the dice.
@export var generation_seed: int = 20261013

@export var internal_color: Color = Color(0.22, 0.45, 0.85)
@export var blanket_color: Color = Color(0.92, 0.52, 0.20)
@export var external_color: Color = Color(0.16, 0.62, 0.34)
@export var path_color: Color = Color(1.0, 0.86, 0.15)

const INTERNAL := 0
const BLANKET := 1
const EXTERNAL := 2
const REMOVED := 3

var _rng := RandomNumberGenerator.new()
var _kind: Dictionary = {}          # Vector3i -> one of the four above
var _path: Array[Vector3i] = []     # the escape route, when there is one
var _separated: bool = true
var _reached: int = 0               # how many cells the search touched

var _root: Node3D
var _plate: Label3D


func _ready() -> void:
	_root = Node3D.new()
	_root.name = "Built"
	add_child(_root)
	_rebuild()


# ----------------------------------------------------------------- the lattice

func _classify() -> void:
	_kind.clear()
	_rng.seed = generation_seed
	var r_in := inner_cells
	var r_out := inner_cells + blanket_cells
	for x in range(-extent, extent + 1):
		for y in range(-extent, extent + 1):
			for z in range(-extent, extent + 1):
				var c := Vector3i(x, y, z)
				var d := Vector3(x, y, z).length()
				var k := EXTERNAL
				if d < r_in:
					k = INTERNAL
				elif d < r_out:
					k = BLANKET
				_kind[c] = k

	if shell == "none":
		for c in _kind.keys():
			if _kind[c] == BLANKET:
				_kind[c] = REMOVED
	elif shell == "patchy":
		# a third of the blanket never existed. The point of this value is that
		# the search usually STILL fails to escape: a boundary with holes in it
		# can separate, because separation is about paths and not about coverage.
		for c in _kind.keys():
			if _kind[c] == BLANKET and _rng.randf() < 0.34:
				_kind[c] = REMOVED
	elif shell == "double":
		# hollow the middle of the band, leaving two thinner layers
		var mid := inner_cells + blanket_cells * 0.5
		for c in _kind.keys():
			if _kind[c] != BLANKET:
				continue
			var d := Vector3(c).length()
			if absf(d - mid) < blanket_cells * 0.16:
				_kind[c] = REMOVED

	# then the leak, applied to whatever blanket is left
	var frac: float = LEAKS.get(leak, 0.0)
	if frac > 0.0:
		var blanket_cells_list: Array = []
		for c in _kind.keys():
			if _kind[c] == BLANKET:
				blanket_cells_list.append(c)
		blanket_cells_list.sort()                      # deterministic order
		var n := int(round(blanket_cells_list.size() * frac))
		# A pinhole is one PLACE, not n scattered cells. Scattering it would make
		# `pinhole` and `breach` differ only in degree; punching one hole is what
		# makes the pair a real question.
		if leak == "pinhole" and blanket_cells_list.size() > 0:
			var centre: Vector3i = blanket_cells_list[_rng.randi() % blanket_cells_list.size()]
			for c in blanket_cells_list:
				if Vector3(c - centre).length() <= 1.9:
					_kind[c] = REMOVED
		else:
			for i in range(n):
				var pick: int = _rng.randi() % blanket_cells_list.size()
				_kind[blanket_cells_list[pick]] = REMOVED


## Breadth-first from the centre, blocked by blanket cells only. Returns true
## when the interior is still sealed. This is the whole argument of the piece.
func _search() -> bool:
	_path.clear()
	_reached = 0
	var start := Vector3i.ZERO
	if not _kind.has(start) or _kind[start] == BLANKET:
		return true
	var came: Dictionary = {start: start}
	var queue: Array[Vector3i] = [start]
	var dirs := [Vector3i(1,0,0), Vector3i(-1,0,0), Vector3i(0,1,0),
				 Vector3i(0,-1,0), Vector3i(0,0,1), Vector3i(0,0,-1)]
	var escape := Vector3i.ZERO
	var escaped := false
	while not queue.is_empty():
		var cur: Vector3i = queue.pop_front()
		_reached += 1
		if _kind[cur] == EXTERNAL and Vector3(cur).length() >= float(extent) - 0.01:
			escape = cur
			escaped = true
			break
		for d in dirs:
			var nxt: Vector3i = cur + d
			if came.has(nxt) or not _kind.has(nxt):
				continue
			if _kind[nxt] == BLANKET:            # the blanket is the only wall
				continue
			came[nxt] = cur
			queue.append(nxt)
	if not escaped:
		return true
	var walk := escape
	while walk != start:
		_path.append(walk)
		walk = came[walk]
	_path.append(start)
	return false


# ------------------------------------------------------------------ the body

func _cube(size: float, col: Color, emit: float) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var box := BoxMesh.new()
	box.size = Vector3.ONE * size
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	if emit > 0.0:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = emit
	box.material = mat
	mm.mesh = box
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	return mi


func _fill(mi: MultiMeshInstance3D, cells: Array) -> void:
	mi.multimesh.instance_count = cells.size()
	for i in range(cells.size()):
		var c: Vector3i = cells[i]
		mi.multimesh.set_instance_transform(
			i, Transform3D(Basis.IDENTITY, Vector3(c) * cell_size))


func _rebuild() -> void:
	if _root == null:
		return
	for c in _root.get_children():
		c.queue_free()

	_classify()
	_separated = _search()

	var inner: Array = []
	var blank: Array = []
	var outer: Array = []
	for c in _kind.keys():
		match _kind[c]:
			INTERNAL: inner.append(c)
			BLANKET: blank.append(c)
			EXTERNAL:
				# THE OUTSIDE IS A SAMPLE, NOT A SOLID. The first build kept a
				# whole rim shell and it photographed as green fog with an
				# orange blob inside it -- the artifact's own furniture standing
				# in front of its marks. Every third cell on the rim is enough
				# to say "there is an outside" without hiding the argument.
				if Vector3(c).length() >= float(extent) - 0.6 \
						and (c.x + c.y + c.z) % 3 == 0:
					outer.append(c)

	# The blanket is drawn SMALL ENOUGH TO SEE THROUGH. A solid shell hides the
	# interior it is defining, which is the one thing a visitor needs to see.
	var a := _cube(cell_size * 0.34, internal_color, 0.9)
	_fill(a, inner); _root.add_child(a)
	var b := _cube(cell_size * 0.46, blanket_color, 0.35)
	_fill(b, blank); _root.add_child(b)
	var d := _cube(cell_size * 0.18, external_color, 0.5)
	_fill(d, outer); _root.add_child(d)

	if not _path.is_empty():
		var p := _cube(cell_size * 0.52, path_color, 1.6)
		_fill(p, _path); _root.add_child(p)

	# THE CAPTURE AABB COUNTS MeshInstance3D ONLY. Everything above is a
	# MultiMesh, so without this the artifact measures as a 1 m box and every
	# framing decision made about it is wrong.
	var span := float(extent) * 2.0 * cell_size
	var anchor := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * span
	anchor.mesh = bm
	anchor.layers = 0                     # measured, never drawn
	anchor.name = "ExtentAnchor"
	_root.add_child(anchor)

	_plate = Label3D.new()
	_plate.text = _verdict_text()
	_plate.font_size = 48
	_plate.pixel_size = 0.0032
	_plate.modulate = path_color if not _separated else external_color
	_plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_plate.position = Vector3(0, span * 0.5 + 0.35, 0)
	_root.add_child(_plate)


func _verdict_text() -> String:
	var n_blanket := 0
	for c in _kind.keys():
		if _kind[c] == BLANKET:
			n_blanket += 1
	if _separated:
		return "SEPARATED\n%d blanket cells hold\n%d cells reachable from inside" \
			% [n_blanket, _reached]
	return "REACHED\n%d blanket cells left\na path of %d crosses" \
		% [n_blanket, _path.size()]


# ------------------------------------------------------------- the map's hand

func apply_grid_config(config_data: Dictionary) -> void:
	var dirty := false
	if config_data.has("leak"):
		var want := str(config_data["leak"]).to_lower().strip_edges()
		if LEAKS.has(want):
			leak = want
			dirty = true
	if config_data.has("shell"):
		var want_s := str(config_data["shell"]).to_lower().strip_edges()
		if SHELLS.has(want_s):
			shell = want_s
			dirty = true
	if config_data.has("extent"):
		extent = clampi(int(config_data["extent"]), 4, 10)
		dirty = true
	if config_data.has("generation_seed"):
		generation_seed = int(config_data["generation_seed"])
		dirty = true
	if dirty and is_inside_tree():
		_rebuild()


## Readable by a probe, so the claim can be tested without reading pixels.
func is_separated() -> bool:
	return _separated


func escape_path_length() -> int:
	return _path.size()
