extends RefCounted

# ─────────────────────────────────────────────────────────────────────────────
# THE GRADUATED RAIL — shared body of the `readout` axis on the two gameplay
# readouts (health_display, hits_reset_display), promoted 2026-08-05.
#
# WHY THIS FILE EXISTS RATHER THAN TWO COPIES. health_display.tscn and
# hits_reset_display.tscn are the same scene twice: same 1.0 x 0.2 x 0.1 frame,
# same subtracted well, same ValueLabel, same TitleLabel, different accent
# colour and different arithmetic. They are the corpus's clearest sibling pair,
# and a shared vocabulary is only honest if the siblings MEASURE ALIKE — which
# they cannot do if each grows its own rail out of its own constants. So the
# geometry is written once here and both scripts call it. This is the
# slot_machine / prng_crank_machine pattern: one ladder, one file, no drift.
#
# THE WORD IS NOT NEW EITHER. `readout` with the values
#
#     none  <  numeral (legacy default)  <  gradation  <  lattice
#
# is already canon in this corpus for "what does this apparatus tell you about
# the value it holds" — line_interface, xyz_slider_plate, xyz_coordinates,
# qfep_calibrator and qfep_reactor all declare it, and readout_name() below
# routes through the plate's alias table so `#readout: Rule` means the same rung
# on all seven. The ladder is monotone and strictly additive: each rung is
# everything below it plus one thing more, so `none` is the only rung that
# removes anything.
#
#   none       the panel, dark. The instrument is in the room and says nothing.
#   numeral    the number, colour-coded. What every existing placement renders.
#   gradation  the number, plus a public scale to check it against — a graduated
#              rail under the panel running the WHOLE range 0..max, minor teeth
#              every 5%, majors and a numeral every 25%, and a bright index
#              standing at the current value. The panel stops being a
#              self-reporting object and becomes a reading off a scale that
#              exists whether or not you are on it.
#   lattice    all of that, plus the privileged set drawn: a standing gate at
#              every value where the code changes its verdict about you, and a
#              collar painted across the interval each verdict owns. Both
#              scripts already carry those thresholds as bare literals in an
#              if/elif chain — a law you can only learn by being hurt down to
#              it. This puts it in the room, at its true position on the scale.
#
# ALL FOUR RUNGS ARE VISIBLE IN ONE STILL AT REST, which is the point: nothing
# here needs damage to happen, a timer to run or a player to be present. At full
# health the four frames are an empty well, a numeral, a numeral over a full
# scale, and a numeral over a scale with its danger stations built.
#
# Nothing in this file runs on the legacy path. `numeral` builds no rail.
# ─────────────────────────────────────────────────────────────────────────────

## The family's one alias table, so an author reaching for `#readout: ticks` on a
## health panel gets the same rung it means on a line. The plate owns the canon;
## this only forwards, exactly as line.gd does.
const Vocab = preload("res://commons/primitives/point/xyz_slider_plate.gd")

# Geometry. The rail hangs UNDER the panel: the frame's body sits at y 0.2..0.4
# (DisplayBody is offset 0.3 and the box is 0.2 tall) and the ValueLabel is a
# 48pt glyph on top of it, so anything drawn on the panel face would be read as
# a change to the numeral rather than an addition beside it. Everything below
# stays inside y 0.05..0.19 — clear of the glyph above and clear of y=0 below,
# because geometry under the origin would move the artifact when the grid
# auto-grounds it.
const SPAN: float = 0.96          # matches the subtracted well's width
const RAIL_Y: float = 0.085
const RAIL_Z: float = 0.0
const BLADE_T: float = 0.012
const BLADE_D: float = 0.030
const TOOTH_MINOR: float = 0.020
const TOOTH_MAJOR: float = 0.038
const TOOTH_W: float = 0.006
const GATE_H: float = 0.100
const INDEX_H: float = 0.036
const STEPS: int = 20             # a minor every 5% of the range
const MAJOR_EVERY: int = 5        # a numbered station every 25%

const STEEL := Color(0.72, 0.75, 0.80)
const HOT := Color(1.00, 0.36, 0.20)
const WARM := Color(1.00, 0.78, 0.18)
const INDEX_COLOR := Color(0.95, 0.98, 1.00)


## The pair's single reader for a readout token, forwarded to the vocabulary's
## owner so the two displays cannot drift from each other or from the five
## artifacts that already answer to this word.
static func readout_name(raw: String) -> String:
	return Vocab.readout_name(raw)


## Where a normalised value stands on the rail.
static func x_at(t: float) -> float:
	return -SPAN * 0.5 + clampf(t, 0.0, 1.0) * SPAN


## RUNG 2, and RUNG 3 when `stations` is true.
##
## `bands` is an Array of Dictionaries {from, to, hot} in VALUE units, one per
## interval the calling script's if/elif chain treats as its own verdict.
## `gates` is an Array of the boundary values themselves. Both are empty at rung
## 2, so the same builder makes both rungs and they cannot disagree about where
## the scale runs.
static func build(host: Node3D, max_value: float, bands: Array, gates: Array, stations: bool) -> Node3D:
	var mv: float = maxf(max_value, 0.001)
	var rail := Node3D.new()
	rail.name = "Rail"
	# the measured ground, not the interface — same standing the kin pair's rule
	# takes, so the cabinet grammar leaves it alone
	rail.set_meta("phenomenon", true)
	host.add_child(rail)

	var blade_mat: StandardMaterial3D = _mat(STEEL.darkened(0.45), 0.30)
	var mark_mat: StandardMaterial3D = _mat(STEEL, 0.85)
	var hot_mat: StandardMaterial3D = _mat(HOT, 2.2)
	var warm_mat: StandardMaterial3D = _mat(WARM, 1.6)

	_box(rail, Vector3(SPAN, BLADE_T, BLADE_D), Vector3(0.0, RAIL_Y, RAIL_Z), blade_mat)

	for i in range(STEPS + 1):
		var t: float = float(i) / float(STEPS)
		var major: bool = (int(i) % MAJOR_EVERY) == 0
		var h: float = TOOTH_MAJOR if major else TOOTH_MINOR
		_box(rail, Vector3(TOOTH_W, h, BLADE_D * 0.85),
				Vector3(x_at(t), RAIL_Y + BLADE_T * 0.5 + h * 0.5, RAIL_Z), mark_mat)
		if not major:
			continue
		var glyph := Label3D.new()
		glyph.text = "%d" % int(round(t * mv))
		glyph.modulate = Color(0.88, 0.91, 0.95)
		glyph.font_size = 40
		glyph.pixel_size = 0.0009
		glyph.outline_size = 6
		glyph.outline_modulate = Color(0.0, 0.0, 0.0, 0.9)
		glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		glyph.position = Vector3(x_at(t), RAIL_Y - 0.030, RAIL_Z)
		rail.add_child(glyph)

	if stations:
		for b in bands:
			var band: Dictionary = b
			var t0: float = clampf(float(band.get("from", 0.0)) / mv, 0.0, 1.0)
			var t1: float = clampf(float(band.get("to", 0.0)) / mv, 0.0, 1.0)
			# a verdict that owns a hairline of the scale still has to be seen to
			# be a verdict; below a floor it reads as a mark rather than a zone
			var w: float = maxf((t1 - t0) * SPAN, 0.014)
			var cx: float = (x_at(t0) + x_at(t1)) * 0.5
			var band_mat: StandardMaterial3D = hot_mat if bool(band.get("hot", true)) else warm_mat
			_box(rail, Vector3(w, BLADE_T * 1.7, BLADE_D * 1.4),
					Vector3(cx, RAIL_Y, RAIL_Z), band_mat)
		for g in gates:
			var gx: float = x_at(clampf(float(g) / mv, 0.0, 1.0))
			_box(rail, Vector3(TOOTH_W * 2.0, GATE_H, TOOTH_W * 2.0),
					Vector3(gx, RAIL_Y + GATE_H * 0.5, RAIL_Z), hot_mat)
			_box(rail, Vector3(0.024, 0.010, BLADE_D * 1.2),
					Vector3(gx, RAIL_Y + GATE_H, RAIL_Z), hot_mat)

	var index: MeshInstance3D = _box(rail, Vector3(0.011, INDEX_H, BLADE_D * 1.25),
			Vector3(0.0, RAIL_Y + INDEX_H * 0.5, RAIL_Z), _mat(INDEX_COLOR, 2.6))
	index.name = "Index"
	return rail


## Move the index to a normalised value. One transform, no geometry rebuilt.
static func set_value(rail: Node3D, t: float) -> void:
	if rail == null or not is_instance_valid(rail):
		return
	var index: Node = rail.get_node_or_null("Index")
	if index is Node3D:
		# written out rather than `(index as Node3D).position.x = ...`, which asks
		# GDScript to assign into a sub-member of a cast expression
		var node: Node3D = index
		var p: Vector3 = node.position
		p.x = x_at(t)
		node.position = p


static func _mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.metallic = 0.25
	m.emission_enabled = true
	m.emission = Color(c.r, c.g, c.b)
	m.emission_energy_multiplier = energy
	return m


static func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi
