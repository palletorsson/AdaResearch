extends Node3D
class_name CubeScene

# @identity
# essence: the reference unit. A 1 m magenta-wireframe cube that stands in 155 rooms as the thing every other size, every other transformation, every other body is read against. It is the ruler, not the exhibit.
# desire: to be so plain that nothing about it competes for attention — and, now, to be able to say how finely it is made of parts without ever stopping being 1 m across
# critical_parameter: grain — from one unbroken body to twelve edges. The silhouette is constant; the number of pieces is not.
# triggers: _ready() builds the parts for the current grain; apply_grid_config rebuilds only when grain actually moves
# emerges: same 1 m envelope, five masses — a solid, a cut, an eight, a twenty-seven, a wireframe made of matter
# needs: the shipped CubeBaseMesh with its Grid.gdshader material_override [present]; the 1 m BoxShape3D collider, which every variant keeps [present]
# truth: a unit that has never been divided is not proven indivisible — only unasked. `grain` is the question 155 rooms forgot to put to their own ruler.

## Stage-2 DNA on the project's reference primitive.
##
## The shipped scene (cube_scene.tscn) is a single BoxMesh(1,1,1) under
## CubeBaseStaticBody3D carrying a Grid.gdshader ShaderMaterial — magenta
## wireframe, show_interior = true — plus a 1 m BoxShape3D collider and a
## hidden Label3D reading "1:1". This script adds ONE axis on top of it and
## changes nothing else.
##
## At the default (`grain = "solid"`) the script builds nothing, hides
## nothing, and touches no property: the 155 existing placements render
## exactly as they did before promotion. Every other value hides the shipped
## mesh and builds sibling meshes that reuse its material, so the family look
## is preserved while the MASS changes.


# ── Stage-2 DNA: grain ────────────────────────────────────────────────
#
# `grain` is the project's one word for HOW FINELY A BODY IS MADE OF PARTS.
# It is used here with exactly the meaning it carries on prism_block — the
# deliberate shared-vocabulary case, the opposite of the `rig` failure where
# one word came to select two different axes in two different families.
#
#   solid      one unbroken body — the shipped mesh, untouched
#   split      parted once through the horizontal mid-plane; two halves
#   quartered  a 2x2x2 lattice of eight sub-cubes
#   lattice    a 3x3x3 lattice of twenty-seven sub-cubes
#   shell      no faces at all — the twelve edges as struts, hollow inside
#
# All five are SHAPE/COUNT/MASS values, readable in a single still from any
# angle. None of them is time-domain and none of them is a no-op.
#
# Worth varying because this artifact's whole claim is "this is the unit" —
# and the hidden question inside that claim is whether the unit is ATOMIC.
# Nothing in 155 rooms has ever asked it. The description in the registry
# even says the cube is "the baseline form against which other changes read
# clearly", which is precisely the reason it has never once been changed.
@export_group("Grain")
## How finely the reference unit is made of parts. `solid` is the shipped
## look exactly — zero nodes added, nothing hidden. The four others hide the
## shipped mesh and build a differently-divided body inside the same 1 m
## envelope.
@export_enum("solid", "split", "quartered", "lattice", "shell") var grain: String = "solid"

## Allow-list for the axis. Anything outside it is a typo in a map token and
## falls back to the value already held, which for a fresh instance is the
## shipped look.
const GRAINS: PackedStringArray = ["solid", "split", "quartered", "lattice", "shell"]

const GRAIN_SOLID: String = "solid"
const GRAIN_SPLIT: String = "split"
const GRAIN_QUARTERED: String = "quartered"
const GRAIN_LATTICE: String = "lattice"
const GRAIN_SHELL: String = "shell"

# Part proportions, all in metres. Named so a reader can check them against
# the spec without counting literals inside the build.
const UNIT: float = 1.0                        ## the envelope this artifact IS

const SPLIT_HALF_H: float = 0.48               ## each half's height
const SPLIT_GAP: float = 0.04                  ## empty space at the mid-plane
const SPLIT_OFFSET: float = 0.26               ## half centre above/below y=0

const QUARTER_SIZE: float = 0.48               ## edge of each of the eight
const QUARTER_GAP: float = 0.04                ## gap on all three axes
const QUARTER_OFFSET: float = 0.26             ## sub-cube centre from origin

const LATTICE_SIZE: float = 0.30               ## edge of each of the twenty-seven
const LATTICE_GAP: float = 0.02                ## gap on all three axes
const LATTICE_PITCH: float = 0.32              ## LATTICE_SIZE + LATTICE_GAP

const SHELL_SECTION: float = 0.05              ## square section of each edge strut
const SHELL_EDGE: float = 0.475                ## strut centre-line, so its outer face lands on ±0.5

## Where the shipped mesh lives in cube_scene.tscn. Resolved by name rather
## than @onready so the script survives being dropped on a bare Node3D.
const BASE_MESH_PATH: NodePath = ^"CubeBaseStaticBody3D/CubeBaseMesh"

## Fallback only — used if the shipped mesh or its material_override is
## missing. The parameters mirror cube_scene.tscn's ShaderMaterial exactly so
## a stray instance still reads as family.
const GRID_SHADER_PATH: String = "res://commons/resourses/shaders/Grid.gdshader"


# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false

## Every node THIS script added. Teardown walks this list and nothing else,
## so it never touches the shipped mesh, the collider, the Label3D, or the
## label plates / packaging / tag markers the grid adds as siblings.
var _owned: Array[Node3D] = []

## The shipped MeshInstance3D, cached per build so teardown can un-hide it.
var _base_mesh: MeshInstance3D = null

## The material every built part wears — taken from the shipped mesh so the
## look is literally the same resource, not a copy that drifts.
var _part_material: Material = null


# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_all()
	_built = true


## Grid config entry point.
##
## Called by GridInteractablesComponent via call_deferred (after _ready, first
## in the deferred queue), and by curation_station.gd immediately after it has
## made the instance inert and re-framed its labels — with a dict that carries
## NO axis key. An unconditional rebuild there would throw that framing away,
## so this returns without touching anything when nothing geometric moved.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_grain: String = grain

	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()

	if not _built:
		# Nothing exists yet; _ready() will build with the value just resolved.
		return

	if grain == before_grain:
		# curation_station's {"emissive": false} lands here. Touch nothing,
		# say nothing.
		return

	_rebuild_now()
	print("[CubeScene] Config applied — grain=%s" % [grain])


func _read_metadata_overrides() -> void:
	if has_meta("config_grain"):
		grain = _pick_axis(str(get_meta("config_grain")), GRAINS, grain)


## Accept an axis value only if it names something this artifact actually
## builds. Lower-cased and stripped first; anything unrecognised is a typo in
## a map token and keeps the value already held.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous teardown + rebuild. remove_child() first so the old parts leave
## the tree in THIS frame — a deferred rebuild would let the grid's
## _auto_ground_artifact measure an empty AABB, return early, and leave the
## cube ungrounded.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			if c.get_parent() == self:
				remove_child(c)
			c.queue_free()
	_owned.clear()

	# Un-hide the shipped mesh before the new grain decides what to do with it.
	# Without this, going back to `solid` would leave an invisible cube.
	var shipped: MeshInstance3D = _find_base_mesh()
	if shipped != null:
		shipped.visible = true

	_base_mesh = null
	_part_material = null
	_build_all()


# ── Build ─────────────────────────────────────────────────────────────

func _build_all() -> void:
	if grain == GRAIN_SOLID:
		# The pre-promotion look, to the byte. No child added, no property
		# written, no node hidden. 155 rooms must not notice this script.
		return

	_base_mesh = _find_base_mesh()
	_part_material = _resolve_part_material()

	# Every non-default grain replaces the single body, so the shipped mesh
	# steps aside. The collider and the Label3D stay exactly where they are.
	if _base_mesh != null:
		_base_mesh.visible = false

	match grain:
		GRAIN_SPLIT:
			_build_split()
		GRAIN_QUARTERED:
			_build_quartered()
		GRAIN_LATTICE:
			_build_lattice()
		GRAIN_SHELL:
			_build_shell()


## Parted once through the horizontal mid-plane. Two slabs of
## 1.0 x 0.48 x 1.0 at y = ±0.26, with 0.04 m of nothing between them. From
## the side the silhouette is still a 1 m square with one bright line through
## it; from above it is unchanged.
func _build_split() -> void:
	var size: Vector3 = Vector3(UNIT, SPLIT_HALF_H, UNIT)
	_add_box("GrainSplitUpper", size, Vector3(0.0, SPLIT_OFFSET, 0.0))
	_add_box("GrainSplitLower", size, Vector3(0.0, -SPLIT_OFFSET, 0.0))


## A 2x2x2 lattice: eight 0.48 m sub-cubes on 0.52 m centres, 0.04 m gaps on
## all three axes. Outer faces still land on ±0.5, so the envelope is intact
## and only the count has changed.
func _build_quartered() -> void:
	var size: Vector3 = Vector3(QUARTER_SIZE, QUARTER_SIZE, QUARTER_SIZE)
	var signs: PackedFloat32Array = [-QUARTER_OFFSET, QUARTER_OFFSET]
	var n: int = 0
	for x in signs:
		for y in signs:
			for z in signs:
				_add_box("GrainQuarter%d" % n, size, Vector3(x, y, z))
				n += 1


## A 3x3x3 lattice: twenty-seven 0.30 m sub-cubes on a 0.32 m pitch, 0.02 m
## gaps. Total span 0.94 m — 3 cm shy of the envelope on each axis, which is
## the arithmetic of three parts and two seams and is left honest rather than
## stretched to hit 1.00.
func _build_lattice() -> void:
	var size: Vector3 = Vector3(LATTICE_SIZE, LATTICE_SIZE, LATTICE_SIZE)
	var n: int = 0
	for ix in range(-1, 2):
		for iy in range(-1, 2):
			for iz in range(-1, 2):
				var pos: Vector3 = Vector3(
					float(ix) * LATTICE_PITCH,
					float(iy) * LATTICE_PITCH,
					float(iz) * LATTICE_PITCH)
				_add_box("GrainLattice%d" % n, size, pos)
				n += 1


## No faces at all. Twelve struts of 0.05 x 0.05 section running the twelve
## edges of the 1 m cube — the wireframe the shader has always drawn, made of
## matter, with the interior visible straight through.
func _build_shell() -> void:
	var e: float = SHELL_EDGE
	var s: float = SHELL_SECTION
	var offsets: PackedFloat32Array = [-e, e]
	var n: int = 0

	# Four struts along X, at each (y, z) edge pair.
	var size_x: Vector3 = Vector3(UNIT, s, s)
	for y in offsets:
		for z in offsets:
			_add_box("GrainShellX%d" % n, size_x, Vector3(0.0, y, z))
			n += 1

	# Four struts along Y.
	var size_y: Vector3 = Vector3(s, UNIT, s)
	for x in offsets:
		for z in offsets:
			_add_box("GrainShellY%d" % n, size_y, Vector3(x, 0.0, z))
			n += 1

	# Four struts along Z.
	var size_z: Vector3 = Vector3(s, s, UNIT)
	for x in offsets:
		for y in offsets:
			_add_box("GrainShellZ%d" % n, size_z, Vector3(x, y, 0.0))
			n += 1


# ── Helpers ───────────────────────────────────────────────────────────

## One part. Everything built by this script goes through here, so every
## piece wears the same material and lands in `_owned`.
func _add_box(part_name: String, size: Vector3, pos: Vector3) -> void:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size

	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = mesh
	mi.position = pos
	if _part_material != null:
		mi.material_override = _part_material

	add_child(mi)
	_owned.append(mi)


func _find_base_mesh() -> MeshInstance3D:
	var n: Node = get_node_or_null(BASE_MESH_PATH)
	if n is MeshInstance3D:
		return n as MeshInstance3D
	return null


## Reuse the shipped mesh's material_override so the parts are the SAME
## resource as the body they replace — one shader, one look, no drift. Only
## if the scene has been stripped down do we rebuild an equivalent from the
## Grid shader with cube_scene.tscn's own parameter values.
func _resolve_part_material() -> Material:
	if _base_mesh != null and _base_mesh.material_override != null:
		return _base_mesh.material_override

	var shader: Shader = load(GRID_SHADER_PATH) as Shader
	if shader == null:
		return null

	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("modelColor", Color(0.0687982, 0.0687983, 0.0687982, 1.0))
	mat.set_shader_parameter("wireframeColor", Color(1.0, 0.0, 1.0, 1.0))
	mat.set_shader_parameter("emissionColor", Color(0.981557, 0.761247, 0.912913, 1.0))
	mat.set_shader_parameter("width", 3.713)
	mat.set_shader_parameter("blur", 0.581)
	mat.set_shader_parameter("emission_strength", 0.458)
	mat.set_shader_parameter("show_interior", true)
	return mat
