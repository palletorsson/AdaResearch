# entropy_ceiling.gd — A NUMBER STANDING IN FOR INFINITY.
#
# The QFEP-laboratory seam, and the thesis at its most self-aware. This whole
# lab measures order and disorder — entropy, information, the tilt of a system
# toward chaos. But the meters are quantized: a finite ladder of ticks, a needle
# that moves in steps. True maximum entropy is a limit, an ideal of perfect
# structurelessness the instrument can never reach. Push a system toward it and
# the needle climbs to the last tick and PINS — reading MAX, a finite number
# standing in for an infinity it cannot hold. Amber: the true value, off the top
# of the scale. Blue: what the meter can say. The lab that studies the limit is
# built out of the limit; the ruler cannot measure its own end.
#
# STAGE-2 DNA — the axis is about the INSTRUMENT, not the quantity.
# Because this is the sequence's seam, the thing worth varying is what the meter
# is allowed to claim. `pinned` is the shipped argument. `cropped` deletes the
# amber and lets the instrument's reading stand unchallenged — what a quantized
# meter looks like from the inside. `raised` builds the comfortable meter with
# headroom, the claim the artifact exists to deny, so a map can stage the claim
# and let the sequence answer it. `smooth` abolishes quantization itself: the
# ideal continuous instrument the quantized lab cannot actually build.
extends Node3D
class_name EntropyCeiling

## STAGE-2 DNA AXIS — how much of the true value the meter can hold, and whether
## the excess above the last tick is shown, hidden, or abolished.
##
##   pinned   the shipped look: 0.10 x 0.44 m ladder, 11 tick marks, blue fill
##            saturated to the top, needle across the last tick with its bead and
##            MAX tag, and the 0.12 m amber over-scale arrow rising off the top.
##   cropped  the amber arrow, its head strokes and its tag are NOT built. The
##            ladder still pins at MAX with nothing above it; the only warm colour
##            on the panel is gone and the reading stands unchallenged.
##   raised   the ladder is rebuilt over y -0.30..+0.30 (0.60 m) with 22 tick
##            marks, the blue fill stops at 45%, the needle sits on a mid tick and
##            the amber arrow is drawn INSIDE the scale at y 0.24. A meter with
##            headroom — the claim this artifact denies, made buildable.
##   smooth   no tick marks and no discrete fill bars; one continuous 0.08 x 0.44 m
##            gradient bar in their place, needle floating at 0.83 of the span with
##            no tick beneath it, captions reading "the meter reads / without ticks".
@export_enum("pinned", "cropped", "raised", "smooth") var headroom: String = "pinned"

## Divisions of the quantized ladder. 10 divisions -> 11 tick marks, the shipped
## look. LIVE as of the Stage-2 pass: it used to be read by apply_grid_config
## AFTER _ready() had already built every mesh, so a map that set it got no change
## at all — a declared knob with no builder behind it. It now drives the build and
## a change to it forces a rebuild.
##
## Honest scope: `ticks` shapes `pinned` and `cropped`. `raised` uses its own fixed
## RAISED_TICKS (the axis value IS a specific alternative instrument), and `smooth`
## has no ticks by definition — that is its whole point.
@export var ticks: int = 10
@export var color_meter: Color = Color(0.3, 0.7, 1.0)
@export var color_true: Color = Color(1.0, 0.62, 0.18)

## Allow-list for the axis. A value outside it is a typo in a map token and falls
## back to the legacy look rather than stranding a placement with a half-built meter.
const HEADROOMS: PackedStringArray = ["pinned", "cropped", "raised", "smooth"]

## `raised`: tick MARKS across the taller ladder, and where the blue fill stops.
const RAISED_TICKS: int = 22
const RAISED_Y0: float = -0.30
const RAISED_Y1: float = 0.30
const RAISED_FILL: float = 0.45

## `smooth`: where the needle floats on a scale that has nothing to land on.
const SMOOTH_NEEDLE: float = 0.83

## The title plate's height on the board.
##
## WAS 0.36, which put the 0.86 x 0.15 x 0.008 m opaque panel across y 0.285-0.435
## at z +0.004 — directly over the amber arrow (y 0.22-0.34 at x -0.06, z 0). The
## panel covered the top 0.055 m of the arrow including its tip and both head
## strokes, and clipped the "true max entropy" tag at y 0.31. The single mark that
## carries this artifact's whole thesis — the true value standing above what the
## meter can say — was hidden behind the artifact's own title plate in every
## placement. At 0.47 the panel spans 0.395-0.545: it clears the arrow tip by
## 0.055 m and the tag by 0.06 m, and clears the `raised` ladder top (0.30) and its
## interior arrow by the same 0.055 m.
const PLATE_Y: float = 0.47

## Every node THIS script adds, so a rebuild frees its own work and nothing else —
## grid-added plates and framed labels are not ours to destroy.
var _owned: Array[Node3D] = []
## Materials whose glow the `emissive` config key switches in place.
var _emissive_mats: Array[StandardMaterial3D] = []
var _emissive: bool = true
var _built: bool = false


func _ready() -> void:
	headroom = _pick_axis(headroom, HEADROOMS, "pinned")
	_build_all()
	_built = true


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])

	var before_headroom: String = headroom
	var before_ticks: int = ticks

	# Stage-2 DNA axis — #headroom:cropped
	if config_data.has("headroom"):
		headroom = _pick_axis(str(config_data["headroom"]), HEADROOMS, headroom)
	if config_data.has("ticks"):
		ticks = clampi(str(config_data["ticks"]).to_int(), 2, 40)

	# Applied IN PLACE, before any early return. curation_station.gd hands us
	# {"emissive": false} one line after framing our labels; a rebuild there would
	# discard that framing, and accepting the key without doing anything is the
	# silent regression this contract exists to stop.
	if config_data.has("emissive"):
		_emissive = _as_bool(config_data["emissive"], _emissive)
		_apply_emissive()

	if not _built:
		return
	if headroom == before_headroom and ticks == before_ticks:
		return
	_rebuild_now()
	print("[EntropyCeiling] Config applied — headroom=%s, ticks=%d" % [headroom, ticks])


## Accept an axis value only if it names something we actually build.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _as_bool(v: Variant, fallback: bool) -> bool:
	match typeof(v):
		TYPE_BOOL:
			return bool(v)
		TYPE_INT, TYPE_FLOAT:
			return float(v) != 0.0
		TYPE_STRING, TYPE_STRING_NAME:
			var s: String = str(v).to_lower().strip_edges()
			if s == "false" or s == "0" or s == "off" or s == "no":
				return false
			if s == "true" or s == "1" or s == "on" or s == "yes":
				return true
			return fallback
	return fallback


func _apply_emissive() -> void:
	for mat in _emissive_mats:
		mat.emission_enabled = _emissive


## Synchronous. No call_deferred anywhere in the build path — a deferred rebuild
## that removes children first makes auto-grounding measure a zero AABB and bail.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_emissive_mats.clear()
	_build_all()


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	_backing()
	match headroom:
		"cropped":
			_build_ladder(false)
		"raised":
			_build_raised()
		"smooth":
			_build_smooth()
		_:
			_build_ladder(true)
	_plate("QFEP LAB",
		"the lab measures order with quantized meters\ntrue maximum entropy is a limit the needle cannot reach\npast the last tick it pins — MAX, a number standing in for infinity",
		Vector3(0.0, PLATE_Y, 0.0), color_meter)


## `pinned` (show_amber = true) and `cropped` (false). Identical geometry apart
## from the over-scale arrow: same 0.44 m ladder, same fill saturated to the top,
## same needle pinned across the last tick. Cropped simply has nothing above it.
func _build_ladder(show_amber: bool) -> void:
	var gx: float = -0.06
	var y0: float = -0.24
	var y1: float = 0.20
	var h: float = y1 - y0
	var n: int = maxi(ticks, 2)
	_frame(gx, y0, y1)
	# quantized ticks
	for i in range(n + 1):
		var ty: float = y0 + h * float(i) / float(n)
		_seg(Vector2(gx - 0.05, ty), Vector2(gx - 0.028, ty), Color(0.45, 0.5, 0.56), 0.003)
	# blue fill pinned to the top tick (saturated)
	for i in range(n):
		var fy: float = y0 + h * (float(i) + 0.5) / float(n)
		_seg(Vector2(gx - 0.04, fy), Vector2(gx + 0.04, fy), color_meter, h / float(n) * 0.72)
	# needle pinned at MAX
	_seg(Vector2(gx - 0.06, y1), Vector2(gx + 0.06, y1), color_meter, 0.007)
	_dot(Vector2(gx + 0.06, y1), color_meter, 0.012)
	# ON the board beside the bead — the needle really is at MAX here.
	_tag("MAX", Vector2(gx + 0.14, y1), color_meter, 28)
	_tag("the meter reads", Vector2(gx, y0 - 0.05), color_meter, 22)
	_tag("in quantized ticks", Vector2(gx, y0 - 0.085), color_meter, 22)
	if show_amber:
		# amber true value — off the top of the scale
		_seg(Vector2(gx, y1 + 0.02), Vector2(gx, y1 + 0.14), color_true, 0.005)
		_seg(Vector2(gx, y1 + 0.14), Vector2(gx - 0.02, y1 + 0.11), color_true, 0.004)
		_seg(Vector2(gx, y1 + 0.14), Vector2(gx + 0.02, y1 + 0.11), color_true, 0.004)
		_tag("true max entropy ↑", Vector2(gx + 0.02, y1 + 0.11), color_true, 24)


## `raised` — the comfortable instrument. A 0.60 m ladder with 22 marks, the fill
## stopping at 45%, the needle on a mid tick, and the amber true value drawn INSIDE
## the scale: a meter that claims it can hold its own limit.
func _build_raised() -> void:
	var gx: float = -0.06
	var y0: float = RAISED_Y0
	var y1: float = RAISED_Y1
	var h: float = y1 - y0
	var n: int = RAISED_TICKS - 1
	_frame(gx, y0, y1)
	for i in range(RAISED_TICKS):
		var ty: float = y0 + h * float(i) / float(n)
		_seg(Vector2(gx - 0.05, ty), Vector2(gx - 0.028, ty), Color(0.45, 0.5, 0.56), 0.003)
	# blue fill stops well short of the top — there is room left on this scale
	var fill_top: float = y0 + h * RAISED_FILL
	for i in range(n):
		var fy: float = y0 + h * (float(i) + 0.5) / float(n)
		if fy > fill_top:
			break
		_seg(Vector2(gx - 0.04, fy), Vector2(gx + 0.04, fy), color_meter, h / float(n) * 0.72)
	# needle on a mid tick
	var nidx: int = roundi(RAISED_FILL * float(n))
	var ny: float = y0 + h * float(nidx) / float(n)
	_seg(Vector2(gx - 0.06, ny), Vector2(gx + 0.06, ny), color_meter, 0.007)
	_dot(Vector2(gx + 0.06, ny), color_meter, 0.012)
	# MAX now labels the TOP OF THE SCALE, not the needle — the needle is nowhere
	# near it, and putting MAX beside it would be a lie this artifact cannot afford.
	_tag("MAX", Vector2(gx + 0.14, y1), color_meter, 28)
	# The board's lower margin ends at y -0.33 and this ladder reaches -0.30, so the
	# captions move to the empty left field rather than hanging off the board.
	_tag("the meter reads", Vector2(gx - 0.24, -0.10), color_meter, 22)
	_tag("in quantized ticks", Vector2(gx - 0.24, -0.135), color_meter, 22)
	# amber true value — INSIDE the scale, a short 0.06 m stem topping out at 0.24
	_seg(Vector2(gx, 0.18), Vector2(gx, 0.24), color_true, 0.005)
	_seg(Vector2(gx, 0.24), Vector2(gx - 0.02, 0.21), color_true, 0.004)
	_seg(Vector2(gx, 0.24), Vector2(gx + 0.02, 0.21), color_true, 0.004)
	_tag("true max entropy ↑", Vector2(gx + 0.23, 0.235), color_true, 24)


## `smooth` — quantization abolished. No marks, no bars: one continuous gradient
## climbing the whole 0.44 m, and a needle with nothing underneath it to land on.
func _build_smooth() -> void:
	var gx: float = -0.06
	var y0: float = -0.24
	var y1: float = 0.20
	var h: float = y1 - y0
	_frame(gx, y0, y1)
	_gradient_bar(Vector2(gx, (y0 + y1) * 0.5), 0.08, h,
		Color(color_meter.r * 0.18, color_meter.g * 0.18, color_meter.b * 0.28), color_meter)
	# needle floating at 0.83 of the span — no tick beneath it
	var ny: float = y0 + h * SMOOTH_NEEDLE
	_seg(Vector2(gx - 0.06, ny), Vector2(gx + 0.06, ny), color_meter, 0.007)
	_dot(Vector2(gx + 0.06, ny), color_meter, 0.012)
	_tag("MAX", Vector2(gx + 0.14, y1), color_meter, 28)
	_tag("the meter reads", Vector2(gx, y0 - 0.05), color_meter, 22)
	_tag("without ticks", Vector2(gx, y0 - 0.085), color_meter, 22)
	# amber true value — still off the top of the scale
	_seg(Vector2(gx, y1 + 0.02), Vector2(gx, y1 + 0.14), color_true, 0.005)
	_seg(Vector2(gx, y1 + 0.14), Vector2(gx - 0.02, y1 + 0.11), color_true, 0.004)
	_seg(Vector2(gx, y1 + 0.14), Vector2(gx + 0.02, y1 + 0.11), color_true, 0.004)
	_tag("true max entropy ↑", Vector2(gx + 0.02, y1 + 0.11), color_true, 24)


func _frame(gx: float, y0: float, y1: float) -> void:
	_seg(Vector2(gx - 0.05, y0), Vector2(gx + 0.05, y0), Color(0.5, 0.55, 0.6), 0.004)
	_seg(Vector2(gx - 0.05, y1), Vector2(gx + 0.05, y1), Color(0.5, 0.55, 0.6), 0.004)
	_seg(Vector2(gx - 0.05, y0), Vector2(gx - 0.05, y1), Color(0.5, 0.55, 0.6), 0.003)
	_seg(Vector2(gx + 0.05, y0), Vector2(gx + 0.05, y1), Color(0.5, 0.55, 0.6), 0.003)


# ═══════════════════════════════════════════════════════════════════
# PIECES
# ═══════════════════════════════════════════════════════════════════

func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.86, 0.74, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.04, -0.014)
	_own(mi)


func _seg(a: Vector2, b: Vector2, color: Color, thick: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var d: float = a.distance_to(b)
	bm.size = Vector3(maxf(d, 0.001), thick, thick)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = _emissive
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 0.5
	_emissive_mats.append(mat)
	mi.material_override = mat
	mi.position = Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.0)
	mi.rotation = Vector3(0.0, 0.0, atan2(b.y - a.y, b.x - a.x))
	_own(mi)


func _dot(p: Vector2, color: Color, r: float) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = _emissive
	mat.emission = color
	_emissive_mats.append(mat)
	mi.material_override = mat
	mi.position = Vector3(p.x, p.y, 0.008)
	_own(mi)


## One continuous column, no divisions. The gradient is baked into a runtime
## GradientTexture2D on a quad, so it renders headless and has no seams a viewer
## could count — which is the whole difference between this and a stack of bars.
func _gradient_bar(center: Vector2, w: float, hgt: float, low: Color, high: Color) -> void:
	var grad := Gradient.new()
	grad.set_color(0, low)
	grad.set_color(1, high)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.width = 8
	tex.height = 128
	tex.fill_from = Vector2(0.0, 1.0)
	tex.fill_to = Vector2(0.0, 0.0)
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(w, hgt)
	mi.mesh = qm
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.roughness = 0.6
	mat.emission_enabled = _emissive
	mat.emission = Color(1.0, 1.0, 1.0)
	mat.emission_texture = tex
	mat.emission_energy_multiplier = 0.5
	_emissive_mats.append(mat)
	mi.material_override = mat
	mi.position = Vector3(center.x, center.y, 0.003)
	_own(mi)


## Every tag here sits 0.021 m in front of the backing board with billboard left
## at the Godot default (DISABLED) — text ON a body, already 2D-in-3D. LabelFramer
## skips these and must keep skipping them; a second framing mechanism would fight
## the one this artifact already is.
func _tag(text: String, pos: Vector2, color: Color, fs: int) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = fs
	t.pixel_size = 0.00044
	t.modulate = color
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector3(pos.x, pos.y, 0.01)
	_own(t)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.86, 0.15, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	_own(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.86, 0.01, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = _emissive
	smat.emission = accent
	_emissive_mats.append(smat)
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.083, 0.006)
	_own(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 30
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	_own(t)


func _own(n: Node3D) -> void:
	add_child(n)
	_owned.append(n)
