extends Node3D

# @identity
# essence: the canonical totem's DNA head — a thin root over the eight authored frustum parts of grammar_totem_pole_rainbow_taper.tscn, restating the same eight members under a different claim about whether they are one thing
# desire: to let the corpus's most-placed piece of scenery be met as what it is — a DISPLAY of eight primitives whose stacking is an argument, not a fact — so the fourteen rooms that say "totem" can also say what a totem stops being when it lies down
# critical_parameter: taxonomy — which order the display claims its eight members have; every mesh, every material, every radius and every rainbow hue is the authored scene's and is never written to
# triggers: _ready() reads taxonomy, returns immediately on the default, and otherwise re-sites Part0..Part7 from their index alone; apply_grid_config re-sites idempotently from stored base transforms
# emerges: the recognition that verticality was the totem's whole claim — the same eight blocks captioned in a row are a catalogue, piled at the base they are rubble, and neither one is a totem
# needs: the authored Part0..Part7 MeshInstance3D children [present]; their CylinderMesh bottom_radius values as the table's captions [read live, never transcribed]; a deterministic index hash for the heap [present, never randf]
# relationships: adopts `taxonomy` word for word from [[combine_sphere]] and [[combine_capsule]] — the same question asked of a parameter sweep is here asked of a composition; the `totem` registry token resolves to this scene via delegate_to, so canon-as-redirection and canon-as-stacking are the same file
# truth: a stack is the claim that many things are one thing described at many heights. Withdraw the claim and the members are still all present, still in their colours — and the totem is gone.

## AXIS — WHAT ORDER THE DISPLAY CLAIMS ITS EIGHT MEMBERS HAVE. The members never change:
## the same eight tapering frustums, the same spectrum red to pink, the same flat-shaded
## materials. What changes is whether the composition asserts that the family is ONE thing,
## and whose assertion that is. Adopted word for word from combine_sphere.gd and
## combine_capsule.gd, which already share it — one vocabulary, so a room holding a sweep
## and a totem cannot have one arguing taxonomy and the other arguing pile.
##
##   stack    one column, every member on the same footprint, in spectrum order. The
##            totem claim: these are not eight objects but ONE object described at eight
##            heights. THE SHIPPED LINEAGE, byte for byte — this branch touches nothing.
##   ladder   the column opened into one ascending file, each member a step aside and a
##            step higher. The claim that the family is a SEQUENCE with a direction —
##            wide to narrow — rather than a single body.
##   table    the members set out in a row on the ground, upright, each captioned with
##            the radius that made it. The catalogue claim: the order is in the objects
##            and the display merely reports it. The captions are the only text this
##            artifact can ever show, and they are what makes the table a table.
##   heap     coordinates abandoned: the members tipped over and piled at the base,
##            uncaptioned. The claim that the stacking was ours all along and the parts
##            never had it. The scatter is a HASH of the index, never randf() — a random
##            pile would photograph differently every boot and the sweep would measure
##            the noise instead of the axis.
@export_enum("stack", "ladder", "table", "heap") var taxonomy: String = "stack"
const TAXONOMIES: PackedStringArray = ["stack", "ladder", "table", "heap"]

## The authored members, in stacking order. Read live from the scene, never rebuilt.
const PART_COUNT: int = 8

var _parts: Array[MeshInstance3D] = []
var _base: Array[Transform3D] = []
var _captions: Array[Node] = []


func _ready() -> void:
	_read_dna_meta()
	var t: String = str(taxonomy).strip_edges().to_lower()
	taxonomy = t if TAXONOMIES.has(t) else "stack"

	# THE LEGACY PATH. "stack" is the scene exactly as authored — this script does not
	# read a child, does not store a transform, does not add a node. Nothing below runs.
	# That is the whole of the strictly-additive guarantee for the corpus's most-placed
	# piece of scenery.
	if taxonomy == "stack":
		return

	_collect_parts()
	_apply_taxonomy()


## The grid stamps `config_*` metadata BEFORE add_child, so this runs ahead of the
## re-siting. An unknown word keeps the default; no metadata, no change — which is all
## fourteen existing placements.
func _read_dna_meta() -> void:
	if has_meta("config_taxonomy"):
		var t: String = str(get_meta("config_taxonomy")).strip_edges().to_lower()
		taxonomy = t if TAXONOMIES.has(t) else taxonomy


## A late config call re-sites from the stored bases, so switching claims twice does not
## compound the offsets. Only the taxonomy key is honoured — every other key a map might
## send keeps its meaning elsewhere.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("taxonomy"):
		return
	var t: String = str(config_data["taxonomy"]).strip_edges().to_lower()
	if not TAXONOMIES.has(t) or t == taxonomy:
		return
	taxonomy = t
	if is_node_ready():
		_collect_parts()
		_apply_taxonomy()


## Find Part0..Part7 and remember where the author put them. Captured once — the base
## transforms are the truth every claim is computed from.
func _collect_parts() -> void:
	if not _parts.is_empty():
		return
	for i in range(PART_COUNT):
		var mi: MeshInstance3D = get_node_or_null("Part%d" % i) as MeshInstance3D
		if mi == null:
			continue
		_parts.append(mi)
		_base.append(mi.transform)


# ── TAXONOMY ─────────────────────────────────────────────────────────────────
# One axis, four claims about whether eight members are one thing. Appended LAST in the
# file and reached only off the default path: `stack` never arrives here. The other three
# discard the authored column and re-site each member from its index alone.

func _apply_taxonomy() -> void:
	for c in _captions:
		if is_instance_valid(c):
			c.queue_free()
	_captions.clear()

	for i in range(_parts.size()):
		var mi: MeshInstance3D = _parts[i]
		mi.transform = _base[i]
		match taxonomy:
			"ladder":
				# One ascending file: a step aside and a step up per member, wide end
				# first. The column's height budget is respent as a diagonal.
				mi.position = Vector3((float(i) - 3.5) * 0.36, 0.10 + float(i) * 0.11, 0.0)
			"table":
				# The catalogue: upright on the ground in a row, seated at natural half
				# height, captioned with the bottom radius that made the taper.
				mi.position = Vector3((float(i) - 3.5) * 0.55, 0.08, 0.0)
				_caption_for(mi, i)
			"heap":
				# The claim withdrawn: tipped over and piled at the base. Every number
				# is a hash of the index — same pile every boot, every machine.
				var a: float = _index_hash(i * 2 + 1) * TAU
				var r: float = 0.10 + 0.38 * sqrt(_index_hash(i * 2 + 2))
				mi.position = Vector3(cos(a) * r, 0.07 + _index_hash(i * 2 + 7) * 0.18, sin(a) * r)
				mi.rotation = Vector3(deg_to_rad(74.0 + _index_hash(i * 3 + 5) * 28.0), a * 1.7, 0.0)
			_:
				pass                              # "stack": the base restore above IS the claim


## The table's caption: the one parameter that made each member, read off its own mesh.
func _caption_for(mi: MeshInstance3D, i: int) -> void:
	var cyl: CylinderMesh = mi.mesh as CylinderMesh
	if cyl == null:
		return
	var l := Label3D.new()
	l.text = "r %.3f" % cyl.bottom_radius
	l.position = Vector3(mi.position.x, 0.42, mi.position.z)
	l.font_size = 20
	l.pixel_size = 0.002
	l.outline_size = 4
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(l)
	_captions.append(l)


## Deterministic 0..1 from an integer. Same value every boot, every frame, every machine.
func _index_hash(n: int) -> float:
	var s: float = sin(float(n) * 12.9898 + 78.233) * 43758.5453
	return s - floor(s)
