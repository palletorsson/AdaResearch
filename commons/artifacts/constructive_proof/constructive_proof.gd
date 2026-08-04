# constructive_proof.gd
# Demonstrates constructive vs classical proof
# Constructive: must exhibit the thing. Classical: can prove existence by contradiction.

extends Node3D
class_name ConstructiveProof

# @identity
# essence: ∃x P(x) requires exhibiting x — no proof by contradiction allowed
# desire: grasp the difference between "something exists" and "here it is"
# critical_parameter: the witness — without an explicit construction, the proof is rejected
# triggers: static display; the box IS the witness, the arrow insists you must BUILD it
# emerges: the gap between knowing something exists and being able to point at it
# needs: VR controls [missing] — could add interactive construction vs contradiction examples
# relationships: depends on excluded_middle_demo (rejecting LEM forces constructive proofs); contrasts godel_statement_plaque (true but unprovable)
# truth: existence without construction is an article of faith, not a proof

# ── STAGE-2 DNA — ONE AXIS: `specimen` ───────────────────────────────────────
#
# The shipped artifact stated the contrast in two label lines and then answered it
# in only one way: a solid blue cube, the witness, present. The caption named a
# classical proof the room was never shown. `specimen` puts the OTHER answers in
# the same 0.3 m slot, so the disagreement is in the geometry instead of the text.
#
#   built       one solid cube in the witness colour. Constructive: here is x.
#               The shipped picture, unchanged, and the default.
#   outline     the same cube as twelve edge bars in the unproduced grey. The
#               claim keeps its shape and has nothing inside it — ∃x proved, x
#               never produced.
#   candidates  twenty-seven small grey cubes filling the same volume, none of
#               them distinguished. Existence over a finite domain: it is one of
#               these and the proof will not say which.
#   absent      a thin grey plate lying where the witness would have stood, and
#               nothing above it. Reductio: the assumption of non-existence
#               failed and NOTHING was produced.
#
# Blue means produced; grey means claimed. Only `built` is blue, which is the
# whole argument in one colour rule.
#
# NOT AN AXIS: the caption. It states both positions and stays true at every
# value, so it is left alone — a measured bite here is a bite in the object and
# never in the text. The arrow line does switch with the value, because a legend
# insisting you must BUILD it, standing beside an empty plate, is the label
# contradicting the picture.

## What the proof puts forward in the place where x must be.
@export_enum("built", "outline", "candidates", "absent") var specimen: String = "built"

const SPECIMENS: PackedStringArray = ["built", "outline", "candidates", "absent"]

## The shipped cube: 0.3 m on a side, albedo (0.3, 0.6, 0.9).
const WITNESS_EXTENT: float = 0.3
const WITNESS_COLOR: Color = Color(0.3, 0.6, 0.9)
## Claimed but never constructed. Every value except `built` is drawn in it.
const UNPRODUCED_COLOR: Color = Color(0.45, 0.45, 0.5)

const ARROWS: Dictionary = {
	"built": "← Must BUILD it",
	"outline": "← Claimed, not built",
	"candidates": "← One of these",
	"absent": "← Nothing produced",
}

var _label: Label3D
var _arrow: Label3D
var _example_box: MeshInstance3D          # the solid witness; null away from `built`
var _specimen_root: Node3D
var _specimen_meshes: Array[MeshInstance3D] = []
var _extent: float = WITNESS_EXTENT
var _tint: Color = WITNESS_COLOR
var _tinted: bool = false                 # a map supplied an explicit colour
var _ready_done: bool = false

func _ready():
	_create_visual()
	_create_label()
	_ready_done = true

func _create_visual():
	_specimen_root = Node3D.new()
	_specimen_root.name = "Specimen"
	add_child(_specimen_root)
	_build_specimen()

	_arrow = Label3D.new()
	_arrow.text = _arrow_text()
	_arrow.pixel_size = 0.001
	_arrow.font_size = 12
	_arrow.position = Vector3(0.25, 0, 0)
	add_child(_arrow)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 11
	_label.text = "CONSTRUCTIVE PROOF\n\nClassical: \"∃x such that P(x)\"\n(existence by contradiction)\n\nConstructive: \"Here is x\"\n(must exhibit the witness)"
	_label.position = Vector3(0, -0.35, 0)
	add_child(_label)

# ── the specimen ─────────────────────────────────────────────────────────────

func _arrow_text() -> String:
	return str(ARROWS.get(specimen, ARROWS["built"]))

## Grey unless a map asked for a colour, in which case the map wins everywhere.
func _claim_color() -> Color:
	return _tint if _tinted else UNPRODUCED_COLOR

func _build_specimen() -> void:
	for m in _specimen_meshes:
		if is_instance_valid(m):
			m.queue_free()
	_specimen_meshes.clear()
	_example_box = null

	match specimen:
		"outline":
			_build_outline()
		"candidates":
			_build_candidates()
		"absent":
			_build_absent()
		_:
			_build_solid()

## EXACTLY what _create_visual used to build inline: one BoxMesh of _extent on a
## side with a StandardMaterial3D at _tint, at the artifact's origin.
func _build_solid() -> void:
	_example_box = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(_extent, _extent, _extent)
	_example_box.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = _tint
	_example_box.material_override = mat
	_specimen_root.add_child(_example_box)
	_specimen_meshes.append(_example_box)

func _build_outline() -> void:
	var half: float = _extent * 0.5
	var t: float = _extent * 0.1
	var col: Color = _claim_color()
	for axis in 3:
		for corner in 4:
			var a: float = half if corner < 2 else -half
			var b: float = half if corner % 2 == 0 else -half
			var size := Vector3(t, t, t)
			var pos := Vector3.ZERO
			if axis == 0:
				size.x = _extent
				pos = Vector3(0.0, a, b)
			elif axis == 1:
				size.y = _extent
				pos = Vector3(a, 0.0, b)
			else:
				size.z = _extent
				pos = Vector3(a, b, 0.0)
			_add_block(size, pos, col)

func _build_candidates() -> void:
	var pitch: float = _extent / 3.0
	var s: float = pitch * 0.72
	var col: Color = _claim_color()
	for ix in 3:
		for iy in 3:
			for iz in 3:
				var pos := Vector3(
					(float(ix) - 1.0) * pitch,
					(float(iy) - 1.0) * pitch,
					(float(iz) - 1.0) * pitch)
				_add_block(Vector3(s, s, s), pos, col)

## The witness's footprint with the witness missing. Its top face sits exactly
## where the solid cube's underside was, so the slot is unmoved.
func _build_absent() -> void:
	var t: float = _extent * 0.04
	_add_block(Vector3(_extent, t, _extent),
		Vector3(0.0, -_extent * 0.5 + t * 0.5, 0.0), _claim_color())

func _add_block(size: Vector3, pos: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mi.material_override = mat
	mi.position = pos
	_specimen_root.add_child(mi)
	_specimen_meshes.append(mi)

# ── grid integration ─────────────────────────────────────────────────────────
#
# GUARDED. The three bare placements (Brouwer_Intuitionism, and the
# curation_station and exhibit_furniture mounts) pass no keys this reads, and a
# rebuild only ever fires when the specimen word actually changed. `color` and
# `size` keep their shipped in-place behaviour on the solid cube: no node is
# replaced, so nothing that registered against the mesh loses its handle.
func apply_grid_config(config_data: Dictionary) -> void:
	var rebuild: bool = false

	if config_data.has("specimen"):
		var w: String = str(config_data["specimen"]).to_lower()
		if SPECIMENS.has(w) and w != specimen:
			specimen = w
			rebuild = true

	if config_data.has("size"):
		var s: float = float(config_data["size"])
		if s > 0.0 and not is_equal_approx(s, _extent):
			_extent = s
			if not rebuild and _example_box != null and _example_box.mesh is BoxMesh:
				(_example_box.mesh as BoxMesh).size = Vector3(s, s, s)
			else:
				rebuild = true

	if config_data.has("color"):
		var c = config_data["color"]
		if c is Color:
			_tint = c
		elif c is String:
			_tint = Color(str(c))
		_tinted = true
		if not rebuild:
			for m in _specimen_meshes:
				if is_instance_valid(m) and m.material_override is StandardMaterial3D:
					(m.material_override as StandardMaterial3D).albedo_color = _tint

	# Before _ready the exports are simply recorded; _create_visual builds with them.
	if rebuild and _ready_done:
		_build_specimen()
		if _arrow != null:
			_arrow.text = _arrow_text()
