extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheFrameYouWereGiven

## @identity
## lineage: change's cheat-code is that `_process(delta)` IS a Riemann sum, and that time
##   arrives pre-cut into frames somebody chose. So this is not an illustration of the
##   sum — it is the engine, drawn.
## essence: one curve, and the left-endpoint Riemann sum beneath it at five grains: one
##   slice, four, sixteen, sixty-four, two hundred and fifty-six. Each frame prints the
##   area it reports and the error it is carrying. The true area is computed once at very
##   high resolution and etched on the base, so every frame can be read against it.
## truth: the last frame looks smooth and is still wrong. There is no cut fine enough to
##   stop being a cut; there is only a cut fine enough that you stop noticing.
## critical_parameter: cut — the number of slices, and the only thing that varies. The
##   curve, the interval and the material are identical in all five frames.
## triggers: none. Computed once in _ready.
##
## NOTE ON THE EXPORT VALUES. They are words, not "1"/"4"/"16". A String export whose
## values parse as numbers gets numericised by the sweep's coercion and then REFUSED in
## silence by Object.set(), which is how tier_terrarium once published ten identical
## default tiles past four green gates. Words cannot be numericised.
##
## Built 2026-08-27 for change-dna, one of three sequences the DNA galleries had missed.

const BRASS := Color(0.77, 0.69, 0.48)
const BRASS_DARK := Color(0.44, 0.38, 0.25)
const STONE := Color(0.13, 0.13, 0.15)
const TRUE_CURVE := Color(1.0, 0.80, 0.45)

const SLICES := {"one": 1, "four": 4, "sixteen": 16, "sixty_four": 64, "two_five_six": 256}
const SPAN := 3.2          # metres of x the interval is drawn across
const RISE := 1.5          # metres of y at f = 1

@export var seed: int = 4
## How many slices the area is cut into. Words, not numerals — see the note above.
@export_enum("one", "four", "sixteen", "sixty_four", "two_five_six") var cut: String = "sixteen"
@export var show_true_curve: bool = true


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("cut"):
		cut = str(config_data["cut"])
	if config_data.has("show_true_curve"):
		show_true_curve = bool(config_data["show_true_curve"])
	if config_data.has("seed"):
		seed = int(config_data["seed"])
	for c in get_children():
		c.queue_free()
	_build()


## The curve being integrated. Chosen to have a hump and a tail, so a coarse cut is
## visibly wrong in two different directions at once rather than uniformly low.
func _f(x: float) -> float:
	return 0.55 + 0.42 * sin(x * PI * 1.35) + 0.22 * exp(-pow((x - 0.72) * 4.4, 2.0))


func _exact() -> float:
	var n: int = 20000
	var s: float = 0.0
	for i in range(n):
		s += _f((float(i) + 0.5) / float(n))
	return s / float(n)


func _build() -> void:
	_rng.seed = seed
	var n: int = int(SLICES.get(cut, 16))
	add_child(_box(Vector3(0, -0.04, 0), Vector3(SPAN + 0.5, 0.08, 0.9),
		_matte_mat(STONE, 0.9, 0.0)))

	# the bars: left-endpoint rule, which is what a frame-based clock actually does —
	# it samples the state it has and holds it until the next frame arrives.
	var bar := _steel_mat(BRASS_DARK)
	var w: float = SPAN / float(n)
	var area: float = 0.0
	for i in range(n):
		var x0: float = float(i) / float(n)
		var h: float = _f(x0)
		area += h / float(n)
		var cx: float = -SPAN * 0.5 + (float(i) + 0.5) * w
		# a hairline gap so 256 bars still read as bars and not as a solid block
		add_child(_box(Vector3(cx, h * RISE * 0.5, 0),
			Vector3(max(w - 0.004, w * 0.55), h * RISE, 0.34), bar))

	if show_true_curve:
		var line := _glow_mat(TRUE_CURVE, 2.2)
		var steps: int = 160
		var prev := Vector3(-SPAN * 0.5, _f(0.0) * RISE, 0.21)
		for i in range(1, steps + 1):
			var x: float = float(i) / float(steps)
			var p := Vector3(-SPAN * 0.5 + x * SPAN, _f(x) * RISE, 0.21)
			add_child(_cylinder_between(prev, p, 0.012, line))
			prev = p

	var exact: float = _exact()
	var err: float = absf(area - exact) / exact * 100.0
	add_child(_billboard_label("%d" % n, Vector3(-SPAN * 0.5 - 0.34, 0.30, 0.3), 48, BRASS))
	add_child(_billboard_label("%.4f" % area, Vector3(SPAN * 0.5 - 0.55, RISE * 1.18, 0.3), 30, BRASS))
	add_child(_billboard_label("%.2f%% off" % err,
		Vector3(SPAN * 0.5 - 0.55, RISE * 1.18 - 0.20, 0.3), 22, BRASS_DARK))
	# the true value, etched once on the sill so every frame is read against the same number
	var sill := _billboard_label("%.4f" % exact, Vector3(0, 0.09, 0.48), 20, BRASS_DARK)
	sill.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sill.rotation_degrees = Vector3(-90, 0, 0)
	add_child(sill)
