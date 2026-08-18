extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name OccupancyCloud

## @identity
## name: Occupancy Cloud
## truth: how full a possibility space is, and where its states stand in it, are two
##        different questions — and one word in this corpus is used for each of them.
##
## SYNTHESIS of bifurcation_walkway (commons/interfaces/qfep/bifurcation_walkway.gd) and
## possibility_space_cloud (commons/artifacts/possibility_space_cloud/…). Both declare an
## axis called `occupancy` and the two value lists share nothing:
##
##   bifurcation_walkway   corridor | mural | inlay | vault   (:48)
##   possibility_space_cloud  breath | pinched | packed | unboxed | widened   (:46)
##
## They do not share a value because they moved DIFFERENT COORDINATES of one relation.
## Occupancy of a region by a set has two independent parts — EXTENT (how much of the
## region the set covers) and SITE (where in the region it sits) — and each artifact gave
## the shared name to whichever part it happened to vary. The cloud varies extent
## (`pinched` 0.05 m knot vs `packed` 0.322 m shell, possibility_space_cloud.gd:159-167).
## The walkway varies site (`_dot_position`, bifurcation_walkway.gd:247-270): the same
## 4800 dots, the same colours, the same r window, moved onto a different submanifold of
## the same corridor.
##
## The walkway DOES carry the extent coordinate. It calls it `regime` (:47, :152-158):
## cropping r to [2.5, 3.0] leaves a single attractor per column and the corridor's air is
## essentially empty, while [3.57, 4.0] fills it. So the two artifacts are about the same
## thing; the word `occupancy` is where they disagree, not the subject.
##
## This bench splits the word back into its two coordinates and crosses them, so the cell
## neither source can build — a nearly empty space seen from underneath, a full one pushed
## against the glass — stands in one frame with the measure printed above it.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# ═══════════════════════════════════════════════════════════════════
# THE TWO AXES
# ═══════════════════════════════════════════════════════════════════
#
# occupancy — HOW MUCH of the state interval the orbit set covers, counted in units of
# one drawn point. Four disjoint r windows of the logistic map, none of which contains
# another (no all-rungs value; the walkway's `regime` has one, `all` = 2.5..4.0, and it
# is that artifact's DEFAULT).
#   hairline  2.60..2.95  one attractor per column. A line. Nothing is happening.
#   forked    3.10..3.40  the period-2 orbit: the first moment the space has an interior.
#   frayed    3.45..3.57  period-4, -8, -16 and the onset of chaos — a widening comb.
#   flooded   3.90..4.00  a chaotic band across nearly the whole interval.
#
# site — WHERE the covered set stands relative to the box that measures it. The walkway's
# coordinate, named as a relation rather than as a building part, because `corridor`,
# `mural`, `inlay` and `vault` are that artifact's answers and this is the question.
#   suspended  on the box's mid-plane, in the air the measure is about.
#   pressed    flat against the far glass, out of the volume, still inside the box.
#   bedded     laid on the box floor with the state value read ACROSS the depth instead
#              of up the height — the mapping rotates, which is why `inlay` is the one
#              value of the walkway's four that is not a mounting.
#   lofted     above the box entirely. See the null below: this is where the axis dies.
const OCCUPANCIES: PackedStringArray = ["hairline", "forked", "frayed", "flooded"]
const SITES: PackedStringArray = ["suspended", "pressed", "bedded", "lofted"]

## Which window of the logistic map is on show. `forked` ships: `hairline` would make the
## default photograph of this artifact a single line, which reads as a broken build.
@export_enum("hairline", "forked", "frayed", "flooded") var occupancy: String = "forked"

## Where the set stands relative to the box. `suspended` ships — it is the relation both
## sources ship (the walkway's cloud hangs in the air you walk through, the cloud's cloud
## floats in the middle of its phase box).
@export_enum("suspended", "pressed", "bedded", "lofted") var site: String = "suspended"

## Disjoint r windows, one per occupancy value. Not a crop of one another.
const R_WINDOWS := {
	"hairline": [2.60, 2.95],
	"forked": [3.10, 3.40],
	"frayed": [3.45, 3.57],
	"flooded": [3.90, 4.00],
}

const COLUMNS: int = 88
const ITERATIONS: int = 100
const SKIP_TRANSIENT: int = 44

const BASE_R: float = 0.24
const BASE_H: float = 0.08
const COL_R: float = 0.045
const COL_H: float = 0.42

const BOX_W: float = 0.80
const BOX_H: float = 0.56
const BOX_D: float = 0.38
const BOX_FLOOR: float = 0.50            # BASE_H + COL_H
const FRAME_R: float = 0.011
const POINT_R: float = 0.010

## The box's own state axis. The measure is taken in THIS span whatever direction the
## site happens to draw the value in — which is what makes the readout site-invariant.
const USE_Y: float = BOX_H * 0.86
const PAD_Y: float = BOX_H * 0.07
## The same span drawn across the depth, at `bedded`. Shorter, because the box is.
const USE_Z: float = BOX_D * 0.86
const USE_X: float = BOX_W * 0.94        # the r axis, inset off the frame edges
const WALL_INSET: float = 0.018
const FLOOR_LIFT: float = 0.014
const LOFT_RISE: float = 0.16

const SCREEN_W: float = 0.46
## 0.46 * TextScreen.ASPECT(0.62) + 2 * TextScreen.BEZEL(0.018)
const SCREEN_H: float = 0.3212
const SCREEN_CLEAR: float = 0.05
const SCREEN_Y: float = BOX_FLOOR + BOX_H + LOFT_RISE + POINT_R + SCREEN_CLEAR + SCREEN_H * 0.5

@export var low_color: Color = Color(0.4, 0.55, 1.0)    # ordered / cold
@export var high_color: Color = Color(0.55, 0.95, 1.0)  # spread / bright cyan
@export var frame_color: Color = Color(0.6, 0.5, 0.95)  # purple instrument frame

var _mm: MultiMesh
var _mm_inst: MultiMeshInstance3D
var _screen = null                 # TextScreen (untyped: preload, not class_name)
var _built: bool = false
var _owned: Array[Node] = []
var _emissive_mats: Array[Dictionary] = []


func _ready() -> void:
	_build_all()
	_built = true


func apply_grid_config(config: Dictionary) -> void:
	var before_occupancy: String = occupancy
	var before_site: String = site
	if config.has("occupancy"):
		occupancy = _pick_axis(str(config["occupancy"]), OCCUPANCIES, occupancy)
	if config.has("site"):
		site = _pick_axis(str(config["site"]), SITES, site)

	# Applied in place, before any early return: dimming is a material property and never
	# needed a rebuild. possibility_space_cloud.gd:104-107 records what tearing the tree
	# down on curation_station's {"emissive": false} used to cost.
	if config.has("emissive"):
		emissive = bool(config["emissive"])
		_apply_emissive()

	if not _built:
		return
	if occupancy == before_occupancy and site == before_site:
		return
	_rebuild_now()
	print("[OccupancyCloud] Config applied — occupancy=%s site=%s" % [occupancy, site])


## Accept a value only if it names something this file actually builds. A typo has to
## fall back to the shipped look rather than strand a placement with an empty box.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _rebuild_now() -> void:
	# Only nodes THIS script created. get_children() would also take the plates the label
	# framer added and anything the grid parented onto us.
	for c: Node in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_emissive_mats.clear()
	_mm = null
	_mm_inst = null
	_screen = null
	_build_all()


func _own(n: Node) -> void:
	_owned.append(n)
	add_child(n)


# ═══════════════════════════════════════════════════════════════════
# THE MATHEMATICS — the walkway's, unchanged
# ═══════════════════════════════════════════════════════════════════

## x_{n+1} = r x_n (1 - x_n), one column per r, the transient dropped. Deterministic all
## the way down: no randf anywhere in this file, so a variant is the same object twice.
func _orbit_columns() -> Array:
	var win: Array = R_WINDOWS.get(occupancy, R_WINDOWS["forked"])
	var r_lo: float = float(win[0])
	var r_hi: float = float(win[1])
	var out: Array = []
	var i: int = 0
	while i < COLUMNS:
		var t: float = float(i) / float(COLUMNS - 1)
		var r: float = r_lo + t * (r_hi - r_lo)
		var x: float = 0.5
		var vals: PackedFloat32Array = PackedFloat32Array()
		var j: int = 0
		while j < ITERATIONS:
			x = r * x * (1.0 - x)
			if j >= SKIP_TRANSIENT:
				vals.append(x)
			j += 1
		out.append(vals)
		i += 1
	return out


## How many bins the state interval holds, at the resolution the drawing actually has.
## One bin is one drawn point across, so a period-1 attractor reads 1/N rather than zero:
## the number reports the PICTURE, not the ideal set behind it.
func _bin_count() -> int:
	return maxi(1, int(round(USE_Y / (POINT_R * 2.0))))


## Mean over columns of the fraction of bins the orbit occupies. Taken in the box's own
## state axis (USE_Y) at every site — the measure is a property of the set, not of the
## direction some site chose to draw it in. That is what makes the readout site-invariant,
## and the invariance is this bench's whole argument.
func _occupied_fraction(cols: Array) -> float:
	var bins: int = _bin_count()
	var total: float = 0.0
	for c in cols:
		var vals: PackedFloat32Array = c
		var hit: Dictionary = {}
		for v: float in vals:
			hit[clampi(int(v * float(bins)), 0, bins - 1)] = true
		total += float(hit.size()) / float(bins)
	return total / float(maxi(1, cols.size()))


## Where one point sits, given how far along the r axis its column is and what the orbit
## value is.
##
## THE `lofted` BRANCH DISCARDS `v` ON PURPOSE, and it is the designed null. Outside the
## box there is no state axis to be placed along, so the four occupancy values draw one
## line and the readout stops reporting a number. This is the walkway's `vault`
## (bifurcation_walkway.gd:264-267) and the cloud's `unboxed`
## (possibility_space_cloud.gd:163-164) turning out to be the same value under two names,
## in two coordinates — the one thing the two lists do share.
func _point_position(t: float, v: float) -> Vector3:
	var x: float = (t - 0.5) * USE_X
	match site:
		"pressed":
			return Vector3(x, BOX_FLOOR + PAD_Y + v * USE_Y, -BOX_D * 0.5 + WALL_INSET)
		"bedded":
			return Vector3(x, BOX_FLOOR + FLOOR_LIFT, (v - 0.5) * USE_Z)
		"lofted":
			return Vector3(x, BOX_FLOOR + BOX_H + LOFT_RISE, 0.0)
		_:
			return Vector3(x, BOX_FLOOR + PAD_Y + v * USE_Y, 0.0)


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	var box_center: Vector3 = Vector3(0.0, BOX_FLOOR + BOX_H * 0.5, 0.0)
	var box_size: Vector3 = Vector3(BOX_W, BOX_H, BOX_D)

	# --- the instrument. Identical in all sixteen cells; neither axis touches it. ---
	_own(_cylinder(Vector3(0.0, BASE_H * 0.5, 0.0), BASE_R, BASE_H,
		_steel_r(Color(0.16, 0.18, 0.28))))
	_own(_cylinder(Vector3(0.0, BASE_H + COL_H * 0.5, 0.0), COL_R, COL_H,
		_steel_r(frame_color * 0.7)))
	_own(_box(box_center, box_size, _glass_r(frame_color, 0.07)))
	_add_box_frame(box_center, box_size, FRAME_R, _glow_r(frame_color, 1.8))
	_build_floor_ticks(box_center, box_size)
	_build_state_ladder()

	# --- the set ---
	_build_cloud()

	# --- the measure ---
	_build_readout()

	_apply_emissive()


## Two crossed bars on the box floor, so the box reads as a state space rather than a
## vitrine. From possibility_space_cloud.gd:181-187.
func _build_floor_ticks(box_center: Vector3, box_size: Vector3) -> void:
	var tick_mat: StandardMaterial3D = _glow_r(low_color * 0.8, 0.8)
	var tick_t: float = 0.008
	var y: float = -box_size.y * 0.5 + 0.006
	_own(_box(box_center + Vector3(0.0, y, 0.0),
		Vector3(box_size.x * 0.9, tick_t, tick_t), tick_mat))
	_own(_box(box_center + Vector3(0.0, y, 0.0),
		Vector3(tick_t, tick_t, box_size.z * 0.9), tick_mat))


## Five marks up the inside of the left wall at 0, 25, 50, 75 and 100 percent of the
## state axis. The unit the occupancy number is counted in, made visible — and instrument,
## so it is the same five marks in every cell.
func _build_state_ladder() -> void:
	var mat: StandardMaterial3D = _glow_r(low_color * 0.7, 0.7)
	var k: int = 0
	while k < 5:
		var f: float = float(k) / 4.0
		var y: float = BOX_FLOOR + PAD_Y + f * USE_Y
		_own(_box(Vector3(-BOX_W * 0.5 + 0.030, y, 0.0),
			Vector3(0.050, 0.005, 0.005), mat))
		k += 1


## ONE MultiMesh, the cloud's own sphere and glow (possibility_space_cloud.gd:190-205).
## Colour is the STATE value, not r: a fuller span shows more of the ramp, so the colour
## change is a consequence of the occupancy axis rather than a second channel alongside it.
func _build_cloud() -> void:
	var cols: Array = _orbit_columns()
	var per: int = ITERATIONS - SKIP_TRANSIENT

	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	_mm.instance_count = COLUMNS * per
	var sph: SphereMesh = SphereMesh.new()
	sph.radius = POINT_R
	sph.height = POINT_R * 2.0
	sph.radial_segments = 6
	sph.rings = 3
	_mm.mesh = sph

	var idx: int = 0
	var i: int = 0
	while i < cols.size():
		var t: float = float(i) / float(COLUMNS - 1)
		var vals: PackedFloat32Array = cols[i]
		var j: int = 0
		while j < vals.size():
			if idx >= _mm.instance_count:
				break
			var v: float = vals[j]
			_mm.set_instance_transform(idx, Transform3D(Basis(), _point_position(t, v)))
			_mm.set_instance_color(idx, low_color.lerp(high_color, clampf(v, 0.0, 1.0)))
			idx += 1
			j += 1
		i += 1
	_mm.visible_instance_count = idx

	_mm_inst = MultiMeshInstance3D.new()
	_mm_inst.name = "StateSet"
	_mm_inst.multimesh = _mm
	_mm_inst.material_override = _glow_r(high_color, 2.2)
	_own(_mm_inst)

	# NO FRAME ANCHOR IS NEEDED and that is by construction, not by luck. The capture AABB
	# counts MeshInstance3D only, so this MultiMesh is invisible to it — the walkway had to
	# add a layers = 0 box at `vault` for exactly this reason (:336-348). Here the readout
	# board stands above the `lofted` line and the box frame stands outside every other
	# site, so the union AABB is the instrument in all sixteen cells and the fixed camera
	# frames every one of them identically.


func _build_readout() -> void:
	var line_title: String = "OCCUPIED  --"
	var line_body: String = "no box under it — the measure is undefined"
	if site != "lofted":
		var frac: float = _occupied_fraction(_orbit_columns())
		line_title = "OCCUPIED %2d%%" % [int(round(frac * 100.0))]
		line_body = "of the state interval, in units of one drawn point"

	# Configure BEFORE add_child — TextScreen's setters rebuild only when in-tree.
	_screen = TextScreenScript.new()
	_screen.name = "MeasureReadout"
	_screen.mode = 0                      # Mode.SCREEN — a framed board, no stand
	_screen.width_m = SCREEN_W
	_screen.title_color = high_color
	_screen.position = Vector3(0.0, SCREEN_Y, 0.0)
	_own(_screen)
	if _screen.has_method("set_text"):
		_screen.set_text(line_title, line_body)


func _add_box_frame(center: Vector3, size: Vector3, r: float, mat: Material) -> void:
	var hx: float = size.x * 0.5
	var hy: float = size.y * 0.5
	var hz: float = size.z * 0.5
	var corners: Array = [
		Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz),
		Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz),
		Vector3(-hx, hy, -hz), Vector3(hx, hy, -hz),
		Vector3(hx, hy, hz), Vector3(-hx, hy, hz)]
	var edges: Array = [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]]
	for e in edges:
		var pair: Array = e
		var a: Vector3 = center + corners[pair[0]]
		var b: Vector3 = center + corners[pair[1]]
		_own(_cylinder_between(a, b, r, mat))


# ═══════════════════════════════════════════════════════════════════
# EMISSIVE — registered materials, so `emissive` applies without a rebuild
# ═══════════════════════════════════════════════════════════════════

func _reg_mat(m: StandardMaterial3D, on_e: float, off_e: float) -> StandardMaterial3D:
	_emissive_mats.append({"mat": m, "on": on_e, "off": off_e})
	return m


func _glow_r(c: Color, energy: float) -> StandardMaterial3D:
	return _reg_mat(_glow_mat(c, energy), energy, energy * 0.3)


func _steel_r(c: Color) -> StandardMaterial3D:
	return _reg_mat(_steel_mat(c), 0.1, 0.0)


func _glass_r(c: Color, alpha: float) -> StandardMaterial3D:
	return _reg_mat(_glass_mat(c, alpha), 0.3, 0.0)


func _apply_emissive() -> void:
	for e: Dictionary in _emissive_mats:
		var m: StandardMaterial3D = e.get("mat") as StandardMaterial3D
		if m == null:
			continue
		m.emission_energy_multiplier = float(e["on"]) if emissive else float(e["off"])
